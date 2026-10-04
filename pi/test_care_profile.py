import unittest
from unittest.mock import patch
import ai_server


class CareProfileTests(unittest.TestCase):
    def test_text_only_and_uncertainty_label(self):
        with patch.object(ai_server, "ollama", return_value="Światło: rozproszone. Podłoże: brak danych.") as model:
            result = ai_server.care_profile({"speciesName": " Aglaonema ", "image": "must-not-be-sent"})
            self.assertIn("wymagają weryfikacji", result["requirements"])
            self.assertEqual(len(model.call_args.args), 1)
            self.assertIn('"Aglaonema"', model.call_args.args[0])
            self.assertNotIn("must-not-be-sent", model.call_args.args[0])

    def test_invalid_names_do_not_call_provider(self):
        with patch.object(ai_server, "ollama") as model:
            for value in [None, "", " ", "x", "a" * 121, 12, []]:
                with self.assertRaises(ValueError):
                    ai_server.care_profile({"speciesName": value})
            model.assert_not_called()

    def test_empty_output_is_error(self):
        with patch.object(ai_server, "ollama", return_value=""):
            with self.assertRaises(RuntimeError):
                ai_server.care_profile({"speciesName": "Monstera"})

    def test_provider_error_is_not_fake_success(self):
        with patch.object(ai_server, "ollama", side_effect=RuntimeError("Limit")):
            with self.assertRaisesRegex(RuntimeError, "Limit"):
                ai_server.care_profile({"speciesName": "Monstera"})
