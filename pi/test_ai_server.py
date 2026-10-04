import tempfile
import unittest
from concurrent.futures import ThreadPoolExecutor
from unittest.mock import patch
import ai_server as ai


class Responses(unittest.TestCase):
    def test_exhausted_thinking_budget_is_not_unknown_plant(self):
        with self.assertRaisesRegex(RuntimeError, "limit długości"):
            ai.response_text({"candidates": [{"content": {}, "finishReason": "MAX_TOKENS"}]})

    def test_reads_all_answer_parts_not_thoughts(self):
        value = ai.response_text({"candidates": [{"content": {"parts": [
            {"text": "hidden", "thought": True}, {"text": "Aglaonema"}, {"text": "uncertain cultivar"}
        ]}, "finishReason": "STOP"}]})
        self.assertEqual(value, "Aglaonema\nuncertain cultivar")
        self.assertEqual(ai.catalog_match(value)["speciesID"], "aglaonema")

    def test_empty_and_blocked_responses(self):
        for response in ({}, {"candidates": [{"content": {}}]}):
            with self.assertRaises(RuntimeError):
                ai.response_text(response)

    def test_non_catalog_candidate_is_kept_for_manual_confirmation(self):
        candidate = ai.identification_candidate("COMMON: Figowiec tępy Ginseng\nLATIN: Ficus microcarpa\nSUMMARY: Bonsai.\nLIGHT: Jasne.\nWATERING: Po przeschnięciu.")
        self.assertIsNone(candidate["speciesID"])
        self.assertEqual(candidate["commonName"], "Figowiec tępy Ginseng")
        self.assertEqual(candidate["latinName"], "Ficus microcarpa")
        self.assertIn("Światło: Jasne.", candidate["requirements"])
        self.assertIsNone(ai.identification_candidate("UNKNOWN"))

    def test_daily_quota_survives_connections_and_concurrency(self):
        with tempfile.TemporaryDirectory() as directory, patch.object(ai, "QUOTA_DB", directory + "/quota.db"):
            ai.reserve_request()
            def attempt(_):
                try:
                    ai.reserve_request()
                    return True
                except RuntimeError:
                    return False
            with ThreadPoolExecutor(max_workers=4) as pool:
                self.assertEqual(sum(pool.map(attempt, range(15))), 9)
            with self.assertRaisesRegex(RuntimeError, "10 analiz"):
                ai.reserve_request()


if __name__ == '__main__':
    unittest.main()
