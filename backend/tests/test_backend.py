import json
from pathlib import Path
import unittest

from backend.formal.grammar.parser import validar_secuencia
from backend.formal.turing.turing import MultiTapeTuringMachine, TuringStep
from backend.game.combat import CombatController, CombatState
from backend.network.protocol import encode_response, error_response, process_request


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
        self.assertEqual(response["vida_jugador"], 65)

    def test_protocol_processes_json(self):
        response = process_request(json.dumps({"secuencia": "TDDTF"}), CombatController())
        self.assertTrue(response["valido"])
        self.assertEqual(response["dano_enemigo"], 15)

    def test_controller_returns_godot_json_snapshot(self):
        response = CombatController().process("TDDTF")
        expected_fields = {
            "valido",
            "golpe",
            "accion",
            "error",
            "dano_enemigo",
            "dano_jugador",
            "enemigo_accion",
            "vida_jugador",
            "vida_enemigo",
            "estado",
            "cintas",
            "cabezales",
        }

        self.assertIsInstance(response, dict)
        self.assertEqual(set(response), expected_fields)
        self.assertEqual(json.loads(encode_response(response)), response)

    def test_defense_parries_every_enemy_attack(self):
        for decision in ("ATAQUE_RAPIDO", "ATAQUE_PESADO", "CASTIGO"):
            with self.subTest(decision=decision):
                step = TuringStep({}, {}, decision)
                self.assertEqual(CombatController._dano_del_enemigo(step, "D"), 0)

    def test_syntax_error_always_causes_critical_damage(self):
        step = TuringStep({}, {}, "ATAQUE_RAPIDO")
        self.assertEqual(CombatController._dano_del_enemigo(step, "E"), 35)

    def test_response_is_json_serializable_and_reports_victory(self):
        controller = CombatController()
        controller.state.vida_enemigo = 15

        response = controller.process("TDDTF")

        self.assertEqual(response["estado"], "VICTORIA")
        self.assertEqual(response["vida_enemigo"], 0)
        self.assertEqual(response["dano_jugador"], 0)
        self.assertEqual(json.loads(json.dumps(response)), response)

    def test_critical_damage_reports_defeat(self):
        controller = CombatController()
        controller.state = CombatState(vida_jugador=20)

        response = controller.process("TTDF")

        self.assertEqual(response["estado"], "DERROTA")
        self.assertEqual(response["vida_jugador"], 0)

    def test_protocol_error_response(self):
        response = error_response("JSON invalido")
        self.assertEqual(response, {
            "valido": False,
            "error": "JSON invalido",
        })


if __name__ == "__main__":
    unittest.main()
