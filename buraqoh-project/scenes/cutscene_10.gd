extends Node2D

func _ready() -> void:
	# Connect ANTES do show — evita o erro de timing
	DialogueManager.show_dialogue_balloon(load("res://Dialogo/SueliFatimaeDjalmaDjalmaNoivas2.dialogue"), "start")

	
func carregarMarquise() -> void:
	get_tree().change_scene_to_file("res://scenes/cutscene11.tscn")
