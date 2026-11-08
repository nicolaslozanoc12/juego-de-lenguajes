import json
from pathlib import Path
import unittest

from backend.formal.grammar.parser import validar_secuencia
from backend.formal.turing.turing import MultiTapeTuringMachine
from backend.game.combat import CombatController
from backend.network.protocol import error_response, process_request


class ParserTests(unittest.TestCase):
    def test_accepts_all_documented_golpes(self):
        cases = {
            "TDDTF": ("Golpe de Gaban", "A"),
            "MSDMF": ("Golpe de Pajarillo", "A"),
            "TSDTF": ("Seis por Derecho", "D"),
            "SDSDF": ("Zumbe y Zumbe", "D"),
            "TMSTF": ("Tonada de Sabana", "C"),
            "TDSDTF": ("Contrapunteo Libre", "A"),
            "TDSDTSDTF": ("Contrapunteo Libre", "A"),
        }
        for sequence, expected in cases.items():
            result = validar_secuencia(sequence)
            self.assertTrue(result.valido, sequence)
            self.assertEqual((result.golpe, result.accion), expected)

    def test_rejects_invalid_sequences(self):
        for sequence in ("TTDF", "TDDT", "TDSDF", "TDSDT", "TDDTFF", "TDDTFM"):
            result = validar_secuencia(sequence)
            self.assertFalse(result.valido, sequence)
            self.assertEqual(result.accion, "E")

    def test_ignores_whitespace_like_the_grammar(self):
        self.assertTrue(validar_secuencia("T D D T F").valido)


class TuringTests(unittest.TestCase):
    def test_tracks_three_tapes_and_head_positions(self):
        machine = MultiTapeTuringMachine()
        step = machine.step("A")
        self.assertEqual(step.cintas, {"cinta1": ["A"], "cinta2": ["1", "1"], "cinta3": ["ATAQUE_RAPIDO"]})
        self.assertEqual(step.cabezales, {"L": 0, "R": 0, "S": 0})

    def test_repeated_action_is_punished(self):
        machine = MultiTapeTuringMachine()
        machine.step("A")
        machine.step("A")
        step = machine.step("A")
        self.assertEqual(step.decision, "CASTIGO")
        self.assertEqual(step.cintas["cinta2"][1], "3")


class CombatTests(unittest.TestCase):
    def test_invalid_input_reaches_enemy_as_error(self):
        response = CombatController().process("TTDF")
        self.assertFalse(response["valido"])
        self.assertEqual(response["cintas"]["cinta1"], ["E"])
        self.assertEqual(response["enemigo_accion"], "CASTIGO")
        self.assertEqual(response["dano_jugador"], 35)

    def test_protocol_processes_json(self):
        response = process_request(json.dumps({"secuencia": "TDDTF"}), CombatController())
        self.assertTrue(response["valido"])
        self.assertEqual(response["dano_enemigo"], 15)

    def test_protocol_error_response(self):
        response = error_response("JSON invalido")
        self.assertEqual(response, {
            "valido": False,
            "error": "JSON invalido",
        })


if __name__ == "__main__":
    unittest.main()
