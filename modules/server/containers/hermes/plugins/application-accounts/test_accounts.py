"""Run with Hermes' Python environment; no real sites or user vault are touched."""

import importlib.util
import json
from contextlib import nullcontext
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from agent.vault_store import VaultStore
from tools import browser_vault_tool as vault

spec = importlib.util.spec_from_file_location("application_accounts", Path(__file__).with_name("__init__.py"))
accounts = importlib.util.module_from_spec(spec)
spec.loader.exec_module(accounts)


class AccountsTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.store = VaultStore(Path(self.tmp.name) / "vault")
        self.origin = "https://employer.example"
        self.args = {"origin": self.origin, "identifier": "applicant@example.test", "mode": "create"}
        self.controls = [{"type": "password", "index": i, "formIndex": 0,
                          "autocomplete": "new-password", "maxLength": 20} for i in range(2)]
        self.patches = [
            patch("agent.vault_store.get_vault_store", return_value=self.store),
            patch.object(accounts, "_account_lock", side_effect=nullcontext),
            patch.object(vault, "_focus_bound_origin", return_value=self.origin),
            patch.object(vault, "_current_page_origin", return_value=self.origin),
            patch.object(vault, "_eval_js", side_effect=lambda *a: {"success": True, "result": self.controls}),
            patch.object(vault, "_eval_js_secret", return_value={"success": True, "result": '{"filled":2}'}),
        ]
        self.mocks = [p.start() for p in self.patches]
        for p in self.patches:
            self.addCleanup(p.stop)

    def call(self, **changes):
        return json.loads(accounts._account(self.args | changes, "test-only"))

    def test_registration_fills_both_and_persists_without_exposing_secret(self):
        result = self.call()
        self.assertTrue(result["success"])
        self.assertEqual(result["filled_fields"], 2)
        password = self.store.resolve_secret(result["handle"])["password"]
        self.assertEqual(len(password), 20)  # Respects the page's maxlength.
        self.assertTrue(all(any(c in group for c in password) for group in
                            ("ABCDEFGHIJKLMNOPQRSTUVWXYZ", "abcdefghijklmnopqrstuvwxyz", "0123456789", "!@#$%*-_")))
        self.assertNotIn(password, json.dumps(result))
        self.assertNotIn(password.encode(), self.store._vault_path.read_bytes())
        # The upstream injection script receives each password target, including confirmation.
        expression = self.mocks[-1].call_args.args[1]
        self.assertIn('"index": 0', expression)
        self.assertIn('"index": 1', expression)
        reopened = VaultStore(self.store._base)
        self.assertEqual(reopened.resolve_secret(result["handle"])["password"], password)

    def test_retry_reuses_credential_and_later_login(self):
        first = self.call()
        second = self.call()
        self.assertEqual(first["handle"], second["handle"])
        self.assertFalse(second["credential_created"])
        self.assertEqual(len(self.store.list_items()), 1)
        self.controls[:] = [{"type": "password", "index": 1, "formIndex": 0,
                             "autocomplete": "current-password"}]
        self.mocks[-1].return_value = {"success": True, "result": '{"filled":1}'}
        self.assertEqual(self.call(mode="login")["handle"], first["handle"])

    def test_login_never_generates_credentials(self):
        self.controls[:] = [self.controls[0] | {"autocomplete": "current-password"}]
        self.assertFalse(self.call(mode="login")["success"])
        self.assertEqual(self.store.list_items(), [])

    def test_wrong_origin_and_multiple_forms_write_nothing(self):
        self.mocks[3].return_value = "https://other.example"
        self.assertFalse(self.call()["success"])
        self.mocks[3].return_value = self.origin
        self.controls[1]["formIndex"] = 1
        self.assertFalse(self.call()["success"])
        self.assertEqual(self.store.list_items(), [])
        self.mocks[-1].assert_not_called()

    def test_navigation_and_partial_fill_are_not_success(self):
        self.mocks[-1].return_value = {"success": True, "result": '{"refused":"origin_changed"}'}
        first = self.call()
        self.assertFalse(first["success"])
        self.mocks[-1].return_value = {"success": True, "result": '{"filled":1}'}
        second = self.call()
        self.assertFalse(second["success"])
        self.assertEqual(first["handle"], second["handle"])
        self.assertEqual(len(self.store.list_items()), 1)

    def test_secret_bearing_exception_is_not_returned(self):
        first = self.call()
        password = self.store.resolve_secret(first["handle"])["password"]
        self.mocks[-1].side_effect = RuntimeError("CDP failed " + password)
        result = self.call()
        self.assertFalse(result["success"])
        self.assertNotIn(password, json.dumps(result))
        self.assertEqual(result["handle"], first["handle"])


if __name__ == "__main__":
    unittest.main()
