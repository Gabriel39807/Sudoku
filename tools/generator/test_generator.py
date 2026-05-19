import unittest

from validator_final import validate_board


class GeneratorValidationTest(unittest.TestCase):
    def test_validator_rejects_preloaded_error(self):
        puzzle = "100000000" + "0" * 72
        solution = "2" + "1" * 80
        result = validate_board(puzzle, solution, "easy")
        self.assertFalse(result["valid"])
        self.assertTrue(any("preloaded value mismatch" in error for error in result["errors"]))

    def test_validator_rejects_row_conflict(self):
        puzzle = "110000000" + "0" * 72
        result = validate_board(puzzle)
        self.assertFalse(result["valid"])
        self.assertTrue(any("row 0" in error for error in result["errors"]))


if __name__ == "__main__":
    unittest.main()
