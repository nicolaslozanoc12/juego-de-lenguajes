import json
import socket
import threading
import unittest

from backend.formal.grammar.parser import validar_secuencia
from backend.formal.turing.turing import MultiTapeTuringMachine, TuringStep
from backend.game.combat import CombatController, CombatState
from backend.network.protocol import encode_response, error_response, process_request
from backend.network.server import GameServer


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

    def test_reports_error_sintactico_for_lexical_and_syntax_errors(self):
        for sequence in ("TXDDTF", "TTDF", "", "   "):
            with self.subTest(sequence=sequence):
                result = validar_secuencia(sequence)
                self.assertFalse(result.valido)
                self.assertEqual(result.accion, "E")
                self.assertIsNotNone(result.error)
                self.assertTrue(result.error.startswith("ERROR_SINTACTICO"))

    def test_recursive_contrapunteo_accepts_multiple_cycles(self):
        result = validar_secuencia("TDSDTSDTSDTF")
        self.assertTrue(result.valido)
        self.assertEqual((result.golpe, result.accion), ("Contrapunteo Libre", "A"))


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

    def test_explicit_states_and_transitions_across_actions(self):
        machine = MultiTapeTuringMachine()
        self.assertEqual(machine.estado, "qObservacion")

        self.assertEqual(machine.step("A").decision, "ATAQUE_RAPIDO")
        self.assertEqual(machine.estado, "qAtaqueRapido")

        self.assertEqual(machine.step("A").decision, "ATAQUE_PESADO")
        self.assertEqual(machine.estado, "qAtaquePesado")
        self.assertEqual(machine.furia, 2)

        self.assertEqual(machine.step("D").decision, "BLOQUEO")
        self.assertEqual(machine.estado, "qBloqueo")
        self.assertEqual(machine.furia, 1)

        self.assertEqual(machine.step("C").decision, "ATAQUE_RAPIDO")
        self.assertEqual(machine.furia, 0)

        self.assertEqual(machine.step("E").decision, "CASTIGO")
        self.assertEqual(machine.estado, "qCastigo")
        self.assertEqual(machine.furia, 2)

    def test_rejects_invalid_action_symbol(self):
        machine = MultiTapeTuringMachine()
        with self.assertRaises(ValueError):
            machine.step("X")

    def test_format_trace_shows_delta_and_head_markers(self):
        machine = MultiTapeTuringMachine()
        machine.step("A")
        trace = machine.format_trace()
        self.assertIn("δ(qObservacion", trace)
        self.assertIn("qAtaqueRapido", trace)
        self.assertIn("Cinta 1 [cab L=0]: [A]", trace)
        self.assertIn("Cinta 2 [cab R=0]: [1] 1", trace)
        self.assertIn("Cinta 3 [cab S=0]: [ATAQUE_RAPIDO]", trace)


class CombatTests(unittest.TestCase):
    def test_invalid_input_reaches_enemy_as_error_without_damage(self):
        response = CombatController().process("TTDF")
        self.assertFalse(response["valido"])
        self.assertEqual(response["cintas"]["cinta1"], ["E"])
        self.assertEqual(response["enemigo_accion"], "CASTIGO")
        self.assertEqual(response["dano_jugador"], 0)
        self.assertEqual(response["vida_jugador"], 100)

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

    def test_syntax_error_causes_no_hp_damage(self):
        for decision in ("ATAQUE_RAPIDO", "ATAQUE_PESADO", "CASTIGO"):
            with self.subTest(decision=decision):
                step = TuringStep({}, {}, decision)
                self.assertEqual(CombatController._dano_del_enemigo(step, "E"), 0)

    def test_response_is_json_serializable_and_reports_victory(self):
        controller = CombatController()
        controller.state.vida_enemigo = 15

        response = controller.process("TDDTF")

        self.assertEqual(response["estado"], "VICTORIA")
        self.assertEqual(response["vida_enemigo"], 0)
        self.assertEqual(response["dano_jugador"], 0)
        self.assertEqual(json.loads(json.dumps(response)), response)

    def test_repeated_attack_castigo_damage_reports_defeat(self):
        controller = CombatController()
        controller.state = CombatState(vida_jugador=20, vida_enemigo=100)
        controller.turing.step("A")
        controller.turing.step("A")

        response = controller.process("TDDTF")

        self.assertEqual(response["enemigo_accion"], "CASTIGO")
        self.assertEqual(response["dano_jugador"], 35)
        self.assertEqual(response["estado"], "DERROTA")
        self.assertEqual(response["vida_jugador"], 0)

    def test_protocol_error_response(self):
        response = error_response("JSON invalido")
        self.assertEqual(response, {
            "valido": False,
            "error": "JSON invalido",
        })


class ServerTests(unittest.TestCase):
    def setUp(self) -> None:
        self.server = GameServer("127.0.0.1", 0)
        self.port = self.server.server_address[1]
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()

    def tearDown(self) -> None:
        self.server.shutdown()
        self.server.server_close()
        self.thread.join(timeout=2)

    def test_tcp_server_processes_turns_and_preserves_turing_state(self):
        with socket.create_connection(("127.0.0.1", self.port), timeout=2) as sock:
            reader = sock.makefile("r", encoding="utf-8")

            sock.sendall((json.dumps({"secuencia": "TDDTF"}) + "\n").encode("utf-8"))
            first = json.loads(reader.readline())
            self.assertTrue(first["valido"])
            self.assertEqual(first["golpe"], "Golpe de Gaban")
            self.assertEqual(first["cintas"]["cinta1"], ["A"])

            sock.sendall((json.dumps({"secuencia": "TTDF"}) + "\n").encode("utf-8"))
            second = json.loads(reader.readline())
            self.assertFalse(second["valido"])
            self.assertEqual(second["cintas"]["cinta1"], ["A", "E"])
            self.assertEqual(second["enemigo_accion"], "CASTIGO")

    def test_tcp_server_handles_invalid_utf8_and_malformed_json(self):
        with socket.create_connection(("127.0.0.1", self.port), timeout=2) as sock:
            reader = sock.makefile("r", encoding="utf-8")

            with self.assertLogs("backend.network.server", level="WARNING"):
                sock.sendall(b"\xff\xfe\n")
                utf8_err = json.loads(reader.readline())
                self.assertFalse(utf8_err["valido"])
                self.assertTrue(utf8_err["error"])

                sock.sendall(b"{malformed\n")
                json_err = json.loads(reader.readline())
                self.assertFalse(json_err["valido"])
                self.assertEqual(json_err["error"], "JSON inválido")


if __name__ == "__main__":
    unittest.main()
