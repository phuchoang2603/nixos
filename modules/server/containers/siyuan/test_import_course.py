import importlib.util
import json
import os
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from urllib.parse import urlsplit
import uuid


spec = importlib.util.spec_from_file_location("import_course", Path(__file__).with_name("import_course.py"))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class CourseImportTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)

    def lesson(self, text):
        path = self.root / "01_Co_Che.md"
        path.write_text(text)
        return module.parse_lesson(path, [])

    def test_preserves_source_warning_while_removing_ocr_page_groups(self):
        lesson = self.lesson("---\nbai: 1\n---\n# Cơ chế\n\n> [!warning] Thiếu nguồn\n> Không được tái dựng.\n\n## Phần 1 · trang sách 301, 302\n\n### Receptor\nNội dung.")
        self.assertEqual(lesson["title"], "01 - Cơ chế")
        self.assertIn("**Thiếu nguồn**", lesson["body"])
        self.assertIn("Không được tái dựng.", lesson["body"])
        self.assertIn("## Receptor", lesson["body"])
        self.assertNotIn("Phần 1", lesson["body"])

    def test_migrates_card_without_dropping_equations_or_citations(self):
        lesson = self.lesson("# Bài\nNội dung.\n\n## Thẻ Anki\n\nTARGET DECK\nDược lý học\n\nSTART\nBasic\nFront: Tác dụng?\nBack: Ái lực &gt; 0.<br><br>[[_Nguon/sach.pdf#page=77|Nguồn]]\nTags: bai_01\nEND\n")
        self.assertEqual(len(lesson["cards"]), 1)
        self.assertIn("Ái lực > 0.", lesson["cards"][0]["answer"])
        self.assertIn("sach.pdf#page=77", lesson["cards"][0]["answer"])
        self.assertNotIn("START", lesson["body"])

    def test_refuses_unrecognized_card_content(self):
        with self.assertRaises(module.ImportFailure):
            self.lesson("# Bài\n## Thẻ Anki\nSTART\nBasic\nFront: Câu hỏi\nBack: Câu trả lời\n")

    def importer(self):
        importer = object.__new__(module.CourseImport)
        importer.state = {"documents": {"02.md": {"id": "20261019000000-abcdefg"}}}
        importer.upload = lambda path: "assets/sach-20261019000000-abcdefg.pdf"
        return importer

    def test_rewrites_pdf_links_in_tables_and_ordinary_markdown(self):
        (self.root / "sach.pdf").write_bytes(b"PDF")
        text = "| [[sach.pdf#page=77\\|tr. 76]] |\n[Trang](sach.pdf#page=77)"
        result = self.importer().rewrite_links(text, self.root)
        self.assertEqual(result.count("assets/sach-20261019000000-abcdefg.pdf#page=77"), 2)
        self.assertNotIn("[[", result)

    def test_rewrites_note_links_to_native_block_links(self):
        (self.root / "02.md").write_text("# Bài 2")
        result = self.importer().rewrite_links("[Bài 2](02.md)", self.root)
        self.assertEqual(result, "[Bài 2](siyuan://blocks/20261019000000-abcdefg)")

    def test_refuses_source_links_that_escape_the_course_directory(self):
        with self.assertRaises(module.ImportFailure):
            self.importer().rewrite_links("[Private](../private.pdf)", self.root)

    def test_title_does_not_accidentally_create_nested_documents(self):
        self.assertEqual(module.title_segment("  Sinh lý / Giải phẫu  "), "Sinh lý ／ Giải phẫu")


@unittest.skipUnless(os.environ.get("SIYUAN_TEST_URL"), "requires an isolated SiYuan instance")
class NativeReviewTests(unittest.TestCase):
    def test_multiple_courses_share_one_schedule_without_losing_edits(self):
        url = os.environ["SIYUAN_TEST_URL"]
        self.assertIn(urlsplit(url).hostname, ("127.0.0.1", "localhost", "::1"))
        token = Path(os.environ["SIYUAN_TEST_TOKEN_FILE"]).read_text().strip()
        api = module.API(url, token)
        suffix = uuid.uuid4().hex
        notebook_name = "Import test " + suffix
        course_ids = []
        try:
            with tempfile.TemporaryDirectory() as directory:
                source = Path(directory) / "01.md"
                source.write_text("# Bài mẫu\n\nNội dung cần giữ.")
                lesson = module.parse_lesson(source, [{"question": "Câu hỏi?", "answer": "Đáp án."}])
                before = api.call("riff/getRiffDueCards", {"deckID": ""})["unreviewedCount"]
                imports = []
                for index in range(2):
                    args = SimpleNamespace(course_id=f"test-{suffix}-{index}", course_name=f"Môn {index} {suffix}",
                                           notebook=notebook_name, attach=[])
                    course_ids.append(args.course_id)
                    importer = module.CourseImport(api, args)
                    result = importer.run([lesson], {})
                    imports.append((args, result, importer))
                    self.assertEqual(api.call("riff/getTreeRiffCards", {"id": result["course"], "page": 1})["total"], 1)
                self.assertEqual(api.call("riff/getRiffDueCards", {"deckID": ""})["unreviewedCount"], before + 2)
                args, result, importer = imports[0]
                due = api.call("riff/getTreeRiffDueCards", {"rootID": result["course"]})
                card = due["cards"][0]
                api.call("riff/reviewRiffCard", {"deckID": card["deckID"], "cardID": card["cardID"], "rating": 4})
                document = importer.state["documents"][source.name]["id"]
                api.call("block/appendBlock", {"parentID": document, "dataType": "markdown", "data": "Ghi chú riêng."})
                module.CourseImport(api, args).run([lesson], {})
                self.assertEqual(api.call("riff/getTreeRiffDueCards", {"rootID": result["course"]})["unreviewedCount"], 0)
                self.assertEqual(api.call("riff/getRiffDueCards", {"deckID": ""})["unreviewedCount"], before + 1)
                self.assertIn("Ghi chú riêng.", api.call("export/exportMdContent", {"id": document})["content"])
                source.write_text("# Bài mẫu\n\nNguồn thay đổi.")
                with self.assertRaises(module.ImportFailure):
                    module.CourseImport(api, args).run([module.parse_lesson(source, [])], {})
        finally:
            for course_id in course_ids:
                api.call("file/removeFile", {"path": "/data/storage/course-imports/" + course_id + ".json"})
            notebooks = api.call("notebook/lsNotebooks")["notebooks"]
            for notebook in notebooks:
                if notebook["name"] == notebook_name:
                    api.call("notebook/removeNotebook", {"notebook": notebook["id"]})


if __name__ == "__main__":
    unittest.main()
