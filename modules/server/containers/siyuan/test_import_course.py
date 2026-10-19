import importlib.util
from pathlib import Path
import tempfile
import unittest


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


if __name__ == "__main__":
    unittest.main()
