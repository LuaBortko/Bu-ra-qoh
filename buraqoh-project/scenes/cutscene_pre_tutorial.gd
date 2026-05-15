extends Node2D

@onready var anim_player = $AnimationPlayer

func _ready() -> void:
	# Conecta o sinal de fim do diálogo
	DialogueManager.dialogue_ended.connect(_on_cutscene_finished)
	DialogueManager.show_dialogue_balloon(load("res://Dialogo/CutsceneTutorial.dialogue"), "start")
	anim_player.play("TesteEntrada")

func _on_cutscene_finished(_resource) -> void:
	# Desconecta para não disparar de novo
	if DialogueManager.dialogue_ended.is_connected(_on_cutscene_finished):
		DialogueManager.dialogue_ended.disconnect(_on_cutscene_finished)
	if StoryManager.modo_historia:
		get_tree().change_scene_to_file("res://scenes/mesa.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
