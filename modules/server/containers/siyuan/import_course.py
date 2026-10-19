import argparse
import hashlib
import html
import json
import mimetypes
import os
from pathlib import Path
import re
import sys
import uuid
from urllib.error import HTTPError, URLError
from urllib.parse import quote, unquote, urlsplit
from urllib.request import Request, urlopen


class ImportFailure(Exception):
    pass


def digest(data):
    return hashlib.sha256(data).hexdigest()


def file_digest(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def title_segment(value):
    return " ".join(value.replace("/", "／").replace("\\", "＼").split())


def clean_markdown(text):
    text = re.sub(r"(?i)<br\s*/?>", "\n\n", text)
    return html.unescape(text).strip()


def parse_lesson(path, extra_cards):
    text = path.read_text(encoding="utf-8")
    text = re.sub(r"\A---\s*\n.*?\n---\s*\n", "", text, count=1, flags=re.S)
    heading = re.search(r"^# (.+)$", text, re.M)
    title = heading.group(1).strip() if heading else path.stem
    if heading:
        text = text[:heading.start()] + text[heading.end():]
    prefix = re.match(r"^(\d+)[_ -]", path.stem)
    if prefix and not re.match(r"^\d+\s*[-–.]", title):
        title = prefix.group(1) + " - " + title
    cards = []
    card_section = re.search(r"^## Thẻ Anki\s*$", text, re.M)
    if card_section:
        body, card_text = text[:card_section.start()], text[card_section.end():]
        blocks = list(re.finditer(r"^START\s*\n(.*?)^END[ \t]*(?:\n|$)", card_text, re.M | re.S))
        remainder = card_text
        for block in reversed(blocks):
            remainder = remainder[:block.start()] + remainder[block.end():]
        remainder = re.sub(r"^TARGET DECK\s*\n[^\n]+", "", remainder, flags=re.M)
        remainder = re.sub(r"<!--ID:.*?-->", "", remainder, flags=re.S)
        if remainder.strip():
            raise ImportFailure(f"Unrecognized card content in {path.name}; refusing to omit it")
        for block in blocks:
            match = re.fullmatch(
                r"Basic\s*\nFront: (.*?)\nBack: (.*?)\nTags: [^\n]*(?:\n<!--ID:.*?-->)?\s*",
                block.group(1).strip(), re.S,
            )
            if not match:
                raise ImportFailure(f"Malformed card in {path.name}")
            cards.append({"question": clean_markdown(match.group(1)),
                          "answer": clean_markdown(match.group(2))})
    else:
        body = text
    cards.extend(extra_cards)
    for card in cards:
        if not isinstance(card, dict) or not all(isinstance(card.get(k), str) and card[k].strip()
                                               for k in ("question", "answer")):
            raise ImportFailure(f"Each card in {path.name} needs question and answer strings")
    body = re.sub(r"^## Phần \d+ · trang sách [^\n]+\n", "", body, flags=re.M)
    body = re.sub(r"^(#{3,6}) ", lambda match: match.group(1)[1:] + " ", body, flags=re.M)
    body = re.sub(r"^> \[!(info|warning|note|tip)\] ?([^\n]*)$", r"> **\2**", body, flags=re.M)
    return {"filename": path.name, "title": title_segment(title), "body": body.strip(),
            "cards": cards, "path": path}


class API:
    def __init__(self, base_url, token):
        parsed = urlsplit(base_url)
        if parsed.scheme != "https" and not (parsed.scheme == "http" and parsed.hostname in ("127.0.0.1", "localhost", "::1")):
            raise ImportFailure("Use HTTPS, or HTTP on localhost, to protect the API token")
        if parsed.username or parsed.password or parsed.query or parsed.fragment:
            raise ImportFailure("The SiYuan URL must not contain credentials, a query, or a fragment")
        self.base_url = base_url.rstrip("/")
        self.token = token

    def request(self, path, data, content_type="application/json", raw=False):
        request = Request(self.base_url + "/api/" + path, data=data,
                          headers={"Authorization": "Token " + self.token, "Content-Type": content_type})
        try:
            with urlopen(request, timeout=180) as response:
                result = response.read()
                if raw and response.status == 200:
                    return result
                parsed = json.loads(result)
        except (HTTPError, URLError, TimeoutError, ValueError) as error:
            raise ImportFailure(f"SiYuan request failed at {path}: {type(error).__name__}") from error
        if parsed.get("code") != 0:
            if raw and parsed.get("code") == 404:
                return None
            raise ImportFailure(f"SiYuan rejected {path}: {parsed.get('msg', 'unknown error')}")
        return parsed.get("data")

    def call(self, path, data=None):
        return self.request(path, json.dumps(data or {}, ensure_ascii=False).encode())

    def multipart(self, path, fields, filename, data, file_field="file"):
        boundary = uuid.uuid4().hex
        chunks = []
        for name, value in fields.items():
            chunks.append(f'--{boundary}\r\nContent-Disposition: form-data; name="{name}"\r\n\r\n{value}\r\n'.encode())
        safe_name = re.sub(r'[\r\n"\\]', "_", filename)
        content_type = mimetypes.guess_type(filename)[0] or "application/octet-stream"
        chunks.append((f'--{boundary}\r\nContent-Disposition: form-data; name="{file_field}"; filename="{safe_name}"\r\n'
                       f'Content-Type: {content_type}\r\n\r\n').encode())
        chunks.extend((data, f"\r\n--{boundary}--\r\n".encode()))
        return self.request(path, b"".join(chunks), "multipart/form-data; boundary=" + boundary)

    def flush(self):
        self.call("sqlite/flushTransaction")

    def sql(self, stmt):
        return self.call("query/sql", {"stmt": stmt}) or []


def sql_string(value):
    return "'" + value.replace("'", "''") + "'"


class CourseImport:
    def __init__(self, api, args):
        self.api = api
        self.args = args
        self.asset_paths = {}
        self.state_path = "/data/storage/course-imports/" + args.course_id + ".json"
        raw = api.request("file/getFile", json.dumps({"path": self.state_path}).encode(), raw=True)
        self.state = json.loads(raw) if raw is not None else {
            "version": 1, "course_id": args.course_id, "course_name": args.course_name,
            "notebook_name": args.notebook, "assets": {}, "documents": {},
        }
        if self.state["course_name"] != args.course_name or self.state["notebook_name"] != args.notebook:
            raise ImportFailure("This course ID already belongs to another course or notebook")

    def save(self):
        data = json.dumps(self.state, ensure_ascii=False, indent=2).encode()
        self.api.multipart("file/putFile", {"path": self.state_path, "isDir": "false"}, "state.json", data)

    def upload(self, path):
        path = path.resolve()
        if path in self.asset_paths:
            return self.asset_paths[path]
        sha = file_digest(path)
        if sha not in self.state["assets"]:
            result = self.api.multipart("asset/upload", {"assetsDirPath": "assets"}, path.name,
                                        path.read_bytes(), "file[]")
            if result.get("errFiles") or len(result.get("succMap", {})) != 1:
                raise ImportFailure(f"Asset upload failed: {path.name}")
            self.state["assets"][sha] = next(iter(result["succMap"].values()))
            self.save()
        self.asset_paths[path] = self.state["assets"][sha]
        return self.asset_paths[path]

    def rewrite_links(self, text, source_root):
        def target_url(target):
            target = html.unescape(target).strip().removesuffix("\\")
            parsed = urlsplit(target)
            if parsed.scheme or target.startswith("#"):
                return target
            path = (source_root / unquote(parsed.path)).resolve()
            if not path.is_relative_to(source_root.resolve()):
                raise ImportFailure("A source link leaves its document directory")
            if not path.is_file():
                raise ImportFailure(f"Missing linked file: {parsed.path}")
            if path.suffix.lower() == ".md":
                entry = self.state["documents"].get(path.name)
                if not entry:
                    raise ImportFailure(f"Linked note must be part of this course: {path.name}")
                if parsed.fragment:
                    raise ImportFailure(f"Heading links need manual conversion: {target}")
                return "siyuan://blocks/" + entry["id"]
            asset = self.upload(path)
            return quote(asset, safe="/:-._~") + ("#" + parsed.fragment if parsed.fragment else "")

        def wikilink(match):
            label = (match.group(2) or match.group(1).split("/")[-1]).replace("|", "\\|")
            return "[" + label + "](" + target_url(match.group(1)) + ")"

        text = re.sub(r"\[\[([^\]|]+?)(?:\\?\|([^\]]+))?\]\]", wikilink, text)

        def markdown_link(match):
            target = match.group(2)
            if target.startswith(("assets/", "siyuan://")):
                return match.group(0)
            return match.group(1) + "(" + target_url(target) + ")"

        return re.sub(r"(!?\[[^\]\n]*\])\(([^\s)]+)\)", markdown_link, text)

    def document(self, key, path, fingerprint):
        entry = self.state["documents"].get(key)
        if entry:
            if entry["fingerprint"] != fingerprint:
                raise ImportFailure(f"Source changed for {key}; edit in SiYuan or import with a new course ID")
            return entry
        existing = self.api.call("filetree/getIDsByHPath", {"notebook": self.state["notebook_id"], "path": path})
        if existing:
            raise ImportFailure(f"A document already exists at {path}; refusing to overwrite it")
        doc_id = self.api.call("filetree/createDocWithMd", {"notebook": self.state["notebook_id"],
                                                           "path": path, "markdown": ""})
        entry = {"id": doc_id, "fingerprint": fingerprint, "complete": False}
        self.state["documents"][key] = entry
        self.save()
        self.api.call("attr/setBlockAttrs", {"id": doc_id, "attrs": {"custom-course-id": self.args.course_id,
                          "custom-source-key": key, "custom-source-sha256": fingerprint}})
        return entry

    def populate(self, entry, markdown):
        if entry["complete"]:
            return
        children = self.api.call("block/getChildBlocks", {"id": entry["id"]}) or []
        if any(block.get("content", "").strip() for block in children):
            raise ImportFailure("An unfinished document contains content; inspect it in SiYuan before retrying")
        self.api.call("block/appendBlock", {"dataType": "markdown", "data": markdown, "parentID": entry["id"]})
        entry["complete"] = True
        self.save()

    def run(self, lessons, diagrams):
        notebooks = self.api.call("notebook/lsNotebooks")["notebooks"]
        notebook = next((n for n in notebooks if n["name"] == self.args.notebook), None)
        if notebook is None:
            notebook = self.api.call("notebook/createNotebook", {"name": self.args.notebook})["notebook"]
        if notebook.get("closed"):
            self.api.call("notebook/openNotebook", {"notebook": notebook["id"]})
        if self.state.get("notebook_id", notebook["id"]) != notebook["id"]:
            raise ImportFailure("The original notebook is missing; restore its backup before importing")
        self.state["notebook_id"] = notebook["id"]
        decks = self.api.call("riff/getRiffDecks")
        deck = next((d for d in decks if d["id"] == self.state.get("deck_id")), None)
        if self.state.get("deck_id") and deck is None:
            raise ImportFailure("The original flashcard deck is missing; restore it before importing")
        if deck is None:
            if any(d["name"] == self.args.course_name for d in decks):
                raise ImportFailure("A deck with this course name already exists; choose a distinct course name")
            deck = self.api.call("riff/createRiffDeck", {"name": self.args.course_name})
        self.state["deck_id"] = deck["id"]
        self.save()
        course_path = "/" + title_segment(self.args.course_name)
        course = self.document("@course", course_path, digest(self.args.course_id.encode()))
        for lesson in lessons:
            fingerprint = digest(json.dumps({k: v for k, v in lesson.items() if k != "path"},
                                            ensure_ascii=False, sort_keys=True).encode()
                                 + json.dumps(diagrams.get(lesson["filename"], []), sort_keys=True).encode())
            self.document(lesson["filename"], course_path + "/" + lesson["title"], fingerprint)
        for attachment in self.args.attach:
            self.upload(attachment)
        course_md = (f"Các bài học của môn **{self.args.course_name}** nằm dưới tài liệu này. "
                     "Đọc và sửa trực tiếp trong từng bài; ôn các câu hỏi bằng tính năng thẻ ghi nhớ.\n\n"
                     f"Mỗi môn có bộ thẻ riêng. Bạn có thể ôn một bài, một môn hoặc toàn bộ sổ tay {self.args.notebook}.\n")
        self.populate(course, course_md)
        expected_total = 0
        for lesson in lessons:
            entry = self.state["documents"][lesson["filename"]]
            source_root = lesson["path"].parent
            body = self.rewrite_links(lesson["body"], source_root)
            lesson_diagrams = diagrams.get(lesson["filename"], [])
            rendered_diagrams = []
            for diagram in lesson_diagrams:
                rendered_diagrams.append("### " + diagram["title"] + "\n\n```mermaid\n" + diagram["mermaid"].strip()
                                         + "\n```\n\n" + self.rewrite_links(diagram["source"], source_root))
            if rendered_diagrams:
                body += "\n\n## Sơ đồ giải thích\n\n" + "\n\n".join(rendered_diagrams)
            if lesson["cards"]:
                body += "\n\n## Ôn tập\n\n"
            for index, card in enumerate(lesson["cards"]):
                key = digest(f"{self.args.course_id}:{lesson['filename']}:{index}".encode())[:24]
                question = self.rewrite_links(card["question"], source_root)
                answer = self.rewrite_links(card["answer"], source_root)
                for diagram, rendered in zip(lesson_diagrams, rendered_diagrams):
                    if card["question"] in diagram.get("questions", []):
                        answer += "\n\n" + rendered
                content = "**" + question.replace("\n", " ") + "**\n\n" + answer
                body += "\n".join("> " + line if line else ">" for line in content.splitlines())
                body += '\n\n{: custom-course-card="' + key + '"}\n\n'
            self.populate(entry, body)
            self.api.flush()
            blocks = self.api.sql("SELECT id, ial FROM blocks WHERE root_id=" + sql_string(entry["id"])
                                  + " AND type='b' AND ial LIKE '%custom-course-card=%' ORDER BY id LIMIT 100000")
            if len(blocks) != len(lesson["cards"]):
                raise ImportFailure(f"Flashcard block count differs for {lesson['filename']}")
            if blocks:
                self.api.call("riff/addRiffCards", {"deckID": deck["id"], "blockIDs": [b["id"] for b in blocks]})
            expected_total += len(blocks)
            print(f"{lesson['title']}: {len(blocks)} cards", flush=True)
        self.api.flush()
        deck = next(d for d in self.api.call("riff/getRiffDecks") if d["id"] == deck["id"])
        if deck["size"] < expected_total:
            raise ImportFailure("The deck contains fewer cards than were imported")
        result = {"notebook": notebook["id"], "course": course["id"], "deck": deck["id"],
                  "lessons": len(lessons), "cards": expected_total, "assets": len(self.state["assets"])}
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return result


def main():
    parser = argparse.ArgumentParser(description="Import a course into SiYuan with native flashcards; existing notes are never overwritten.")
    parser.add_argument("--url", default="https://siyuan.home.phuchoang.sbs")
    parser.add_argument("--token-file", type=Path, default=Path.home() / ".config/siyuan/api-token")
    parser.add_argument("--notebook", default="Học tập")
    parser.add_argument("--course-id", required=True, help="Stable course identifier, e.g. duoc-ly or sinh-ly-2026")
    parser.add_argument("--course-name", required=True)
    parser.add_argument("--source", type=Path, required=True, help="Directory containing lesson Markdown files")
    parser.add_argument("--cards", type=Path, help="Optional JSON: filename -> list of question/answer objects")
    parser.add_argument("--diagrams", type=Path, help="Optional JSON: filename -> list of title/mermaid/source/questions objects")
    parser.add_argument("--attach", type=Path, action="append", default=[])
    parser.add_argument("--limit", type=int, help="Import the first N lessons for a pilot")
    parser.add_argument("--dry-run", action="store_true", help="Check source parsing without calling SiYuan")
    args = parser.parse_args()
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]*", args.course_id):
        parser.error("--course-id must contain only lowercase ASCII letters, digits and hyphens")
    if not title_segment(args.course_name) or not title_segment(args.notebook):
        parser.error("Course and notebook names must not be empty")
    if args.limit is not None and args.limit < 1:
        parser.error("--limit must be positive")
    extra_cards = json.loads(args.cards.read_text()) if args.cards else {}
    diagrams = json.loads(args.diagrams.read_text()) if args.diagrams else {}
    paths = sorted(args.source.glob("*.md"))
    if args.limit:
        paths = paths[:args.limit]
    if not paths:
        raise ImportFailure("No lesson Markdown files found")
    lessons = [parse_lesson(path, extra_cards.get(path.name, [])) for path in paths]
    if len({lesson["title"] for lesson in lessons}) != len(lessons):
        raise ImportFailure("Lesson titles must be unique within a course")
    if args.dry_run:
        print(json.dumps({"lessons": len(lessons), "cards": sum(len(l["cards"]) for l in lessons),
                          "diagrams": sum(len(diagrams.get(l["filename"], [])) for l in lessons)}, indent=2))
        return
    token = os.environ.get("SIYUAN_API_TOKEN") or args.token_file.read_text().strip()
    if not token:
        raise ImportFailure("API token is empty")
    CourseImport(API(args.url, token), args).run(lessons, diagrams)


if __name__ == "__main__":
    try:
        main()
    except (ImportFailure, OSError, ValueError, KeyError) as error:
        print("Import failed: " + str(error), file=sys.stderr)
        sys.exit(1)
