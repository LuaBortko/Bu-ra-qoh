extends Node

signal battle_ready(luta: Dictionary)
signal story_finished

const LUTAS: Array[Dictionary] = [
	{ "cutscene": "res://scenes/CutscenePreTutorial.tscn", "player_char": "lucilene", "ai_char": "pc"       },
	{ "cutscene": "res://scenes/Cutscene2.tscn",           "player_char": "sueli",    "ai_char": "jurandir" },
	{ "cutscene": "res://scenes/Cutscene3.tscn",           "player_char": "djalma",   "ai_char": "chalita"  },
	{ "cutscene": "res://scenes/Cutscene4.tscn",           "player_char": "armane",   "ai_char": "lucilene" },
	{ "cutscene": "res://scenes/Cutscene5.tscn",           "player_char": "tavares",  "ai_char": "jorge"    },
	{ "cutscene": "res://scenes/Cutscene6.tscn",           "player_char": "fatima",   "ai_char": "armane"   },
	{ "cutscene": "res://scenes/Cutscene1.tscn",           "player_char": "djalma",   "ai_char": "tavares"  },
	{ "cutscene": "res://scenes/Cutscene9.tscn",           "player_char": "fatima",   "ai_char": "djalma"   },
	{ "cutscene": "res://scenes/cutscene10.tscn",          "player_char": "sueli",    "ai_char": "flavinha" },
]

var luta_index: int = 0
var modo_historia: bool = false

func start_historia() -> void:
	modo_historia = true
	luta_index = 0
	_ir_para_cutscene()

func _ir_para_cutscene() -> void:
	if luta_index >= LUTAS.size():
		story_finished.emit()
		get_tree().change_scene_to_file("res://scenes/cutscene12.tscn")
		return
	get_tree().change_scene_to_file(LUTAS[luta_index].cutscene)

func get_luta_atual() -> Dictionary:
	return LUTAS[luta_index]

func on_player_won() -> void:
	luta_index += 1
	_ir_para_cutscene()

func on_player_lost() -> void:
	get_tree().change_scene_to_file(LUTAS[luta_index].cutscene)
