import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
from pathlib import Path


ROOT = Path(os.environ.get("RESUME_KIT", Path.home() / "resume-kit"))
SOURCE_PATHS = ["resumes/swe-devops.tex", "resumes/data-engineering.tex",
                "resumes/ai-engineer.tex", "shared/technical-preamble.tex",
                "shared/technical-background.tex"]
SIGNALS = {
    "swe-devops": {
        "backend": 3, "distributed systems": 4, "grpc": 3, "microservices": 3,
        "platform": 2, "infrastructure": 2, "devops": 3, "sre": 3,
        "golang": 2, "go": 1, "terraform": 2, "kubernetes": 1,
        "full stack": 2, "full-stack": 2, "typescript": 1, "javascript": 1,
    },
    "data-engineering": {
        "data engineer": 5, "data engineering": 5, "data pipeline": 4,
        "spark": 4, "flink": 4, "iceberg": 4, "lakehouse": 4, "etl": 3,
        "feature engineering": 3, "feast": 3, "clickhouse": 3, "sql": 1,
    },
    "ai-engineer": {
        "ai engineer": 5, "ai engineering": 5, "llm": 4, "generative ai": 4,
        "rag": 4, "retrieval-augmented": 4, "agents": 3, "mcp": 3,
        "inference": 3, "model serving": 3, "vllm": 4, "kserve": 3,
        "ml engineer": 2, "machine learning engineer": 2,
    },
}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def save(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n")


def prefix(source):
    return source.split("\\section{Projects}", 1)[0]


def sync_sources(args):
    snapshot = json.loads(args.snapshot_file.read_text())
    if snapshot.get("status") == "waiting_for_build":
        print(json.dumps({"status": "waiting_for_build", "sha": snapshot.get("sha")}))
        return
    if (snapshot.get("status") != "ready"
            or snapshot.get("repository") != "phuchoang2603/resume"
            or snapshot.get("branch") != "main"
            or not re.fullmatch(r"[a-f0-9]{40}", snapshot.get("sha", ""))):
        raise ValueError("Expected a source snapshot from phuchoang2603/resume main.")
    files = snapshot.get("files", [])
    if sorted(file["path"] for file in files) != sorted(SOURCE_PATHS):
        raise ValueError("Source snapshot must contain exactly the three bases and both shared files.")
    hashes = {}
    for file in files:
        data = file["content"].encode("utf-8")
        if len(data) > 200000 or hashlib.sha256(data).hexdigest() != file["sha256"]:
            raise ValueError(f"Invalid source content or checksum: {file['path']}")
        hashes[file["path"]] = file["sha256"]
    state_path = ROOT / ".source-version.json"
    for file in files:
        target = ROOT / file["path"]
        target.parent.mkdir(parents=True, exist_ok=True)
        temporary = target.with_suffix(".tex.sync")
        temporary.write_text(file["content"])
        temporary.replace(target)
    save(state_path, {"sha": snapshot["sha"], "runId": snapshot.get("runId"),
                      "runUrl": snapshot.get("runUrl"), "installedFiles": hashes})
    print(json.dumps({"status": "synced", "sha": snapshot["sha"]}))


def check_bullet_lines(text):
    lines = [line for line in text.splitlines() if line.strip()]
    bullets = 0
    for index, line in enumerate(lines):
        if not line.lstrip().startswith("•"):
            continue
        bullets += 1
        indent = len(line) - len(line.lstrip())
        count = 1
        for following in lines[index + 1:]:
            if len(following) - len(following.lstrip()) <= indent:
                break
            count += 1
        if count > 2:
            raise ValueError(f"A bullet spans {count} lines; shorten it to one or two: {line.strip()}")
    if not bullets:
        raise ValueError("No readable bullets found in the extracted PDF text.")


def prepare(args):
    state_path = ROOT / ".source-version.json"
    version = json.loads(state_path.read_text()) if state_path.exists() else {}
    for name, expected in version.get("installedFiles", {}).items():
        if digest(ROOT / name) != expected:
            raise ValueError("Installed sources changed outside sync; run sync again.")
    jd = args.jd_file.read_text().strip()
    if len(jd) < 100:
        raise ValueError("Provide the full employer job description, not only its title.")
    matches = {
        base: {term: weight for term, weight in terms.items()
               if re.search(r"(?<!\w)" + re.escape(term) + r"(?!\w)", jd.lower())}
        for base, terms in SIGNALS.items()
    }
    scores = {base: sum(terms.values()) for base, terms in matches.items()}
    base = args.base or max(scores, key=scores.get)
    source = ROOT / "resumes" / f"{base}.tex"
    shared_hashes = {path.name: digest(path) for path in sorted((ROOT / "shared").glob("*.tex"))}
    identity = "-".join([args.company, args.job_id])
    slug = re.sub(r"[^a-z0-9]+", "-", identity.lower()).strip("-")[:100] or "application"
    fingerprint = hashlib.sha256((jd + digest(source) + json.dumps(shared_hashes)).encode()).hexdigest()[:12]
    directory = args.output_root / f"{slug}-{base}-{fingerprint}"
    if directory.exists():
        print(json.dumps({"directory": str(directory), "base": base, "reused": True}))
        return
    directory.mkdir(parents=True)
    shutil.copytree(ROOT / "shared", directory / "shared")
    shutil.copyfile(source, directory / "base.tex")
    shutil.copyfile(source, directory / "draft.tex")
    (directory / "jd.txt").write_text(jd + "\n")
    save(directory / "job.json", {
        "company": args.company, "job_id": args.job_id, "base": base,
        "base_sha256": digest(source), "jd_sha256": digest(directory / "jd.txt"),
        "shared_sha256": shared_hashes, "scores": scores, "matched_signals": matches,
        "source_version": version,
    })
    save(directory / "tailoring.json", {
        "summary": "", "changes": [], "unmatched_requirements": [],
    })
    print(json.dumps({"directory": str(directory), "base": base, "scores": scores}))


def build(args):
    from pypdf import PdfReader

    directory = args.directory.resolve()
    pdf = directory / "resume.pdf"
    validation = directory / "validation.json"
    pdf.unlink(missing_ok=True)
    validation.unlink(missing_ok=True)
    job = json.loads((directory / "job.json").read_text())
    if digest(directory / "base.tex") != job["base_sha256"]:
        raise ValueError("The base snapshot was changed; prepare a fresh application directory.")
    if digest(directory / "jd.txt") != job["jd_sha256"]:
        raise ValueError("The job description changed; prepare a fresh application directory.")
    for name, expected in job["shared_sha256"].items():
        if digest(directory / "shared" / name) != expected:
            raise ValueError("Keep the shared template unchanged; tailor the draft content instead.")
    if prefix((directory / "base.tex").read_text()) != prefix((directory / "draft.tex").read_text()):
        raise ValueError("Keep identity, education, and internship experience unchanged.")
    review = json.loads((directory / "tailoring.json").read_text())
    if not review.get("summary") or not isinstance(review.get("changes"), list):
        raise ValueError("Record the tailoring summary and evidence in tailoring.json before building.")
    if digest(directory / "draft.tex") != digest(directory / "base.tex") and not review["changes"]:
        raise ValueError("Record evidence for the draft's changes before building.")
    for change in review["changes"]:
        if not change.get("change") or not change.get("evidence"):
            raise ValueError("Each tailoring change needs an evidence reference.")
    compiler = shutil.which("tectonic")
    output = directory / ".compile"
    output.mkdir(exist_ok=True)
    result = subprocess.run(
        [compiler, "--keep-logs", "--outdir", str(output), "draft.tex"],
        cwd=directory, capture_output=True, text=True, timeout=240,
    )
    log = result.stdout + result.stderr
    (directory / "build.log").write_text(log)
    if result.returncode:
        raise ValueError(f"LaTeX compilation failed; inspect {directory / 'build.log'}")
    tex_log = output / "draft.log"
    if tex_log.exists():
        log += tex_log.read_text(errors="replace")
    if re.search(r"Overfull \\[hv]box", log):
        raise ValueError("LaTeX reports overflowing content; shorten the draft and rebuild.")
    candidate = output / "draft.pdf"
    reader = PdfReader(candidate)
    if len(reader.pages) != 1:
        raise ValueError(f"Expected one page, got {len(reader.pages)}; shorten the draft and rebuild.")
    text = reader.pages[0].extract_text(extraction_mode="layout")
    if not all(section in text for section in ["Education", "Experience", "Projects", "Skills"]):
        raise ValueError("The PDF is missing required searchable text sections.")
    check_bullet_lines(text)
    (directory / "resume.txt").write_text(text)
    shutil.copyfile(candidate, pdf)
    save(validation, {
        "pages": 1, "pdf_sha256": digest(pdf), "draft_sha256": digest(directory / "draft.tex"),
        "base": job["base"], "base_sha256": job["base_sha256"],
        "jd_sha256": job["jd_sha256"], "tailoring_sha256": digest(directory / "tailoring.json"),
        "compiler": compiler, "checks": ["unchanged_identity_education_experience",
        "searchable_sections", "one_page", "one_or_two_line_bullets", "no_overfull_boxes"],
    })
    print(json.dumps({"pdf": str(pdf), "text": str(directory / "resume.txt"), "pages": 1}))


def main():
    parser = argparse.ArgumentParser(description="Prepare and validate per-job LaTeX resumes.")
    commands = parser.add_subparsers(dest="command", required=True)
    sync = commands.add_parser("sync")
    sync.add_argument("--snapshot-file", type=Path, required=True)
    sync.set_defaults(run=sync_sources)
    prep = commands.add_parser("prepare")
    prep.add_argument("--jd-file", type=Path, required=True)
    prep.add_argument("--company", required=True)
    prep.add_argument("--job-id", required=True)
    prep.add_argument("--base", choices=SIGNALS)
    prep.add_argument("--output-root", type=Path, default=ROOT / "tailored")
    prep.set_defaults(run=prepare)
    compile_parser = commands.add_parser("build")
    compile_parser.add_argument("directory", type=Path)
    compile_parser.set_defaults(run=build)
    args = parser.parse_args()
    try:
        args.run(args)
    except (ValueError, OSError, subprocess.TimeoutExpired) as error:
        parser.exit(1, f"{error}\n")


if __name__ == "__main__":
    main()
