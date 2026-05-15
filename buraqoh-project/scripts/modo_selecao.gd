extends Control

@onready var btn_local: Button = $VBoxContainer/HBoxContainer/Local
@onready var btn_historia: Button = $VBoxContainer/Historia

func _ready() -> void:
	btn_local.pressed.connect(func():
		StoryManager.modo_historia = false
		get_tree().change_scene_to_file("res://scenes/personagens.tscn")
	)
	btn_historia.pressed.connect(func():
		StoryManager.modo_historia = true
		StoryManager.luta_index = 0
		# Vai direto para a primeira cutscene
		get_tree().change_scene_to_file("res://scenes/CutscenePreTutorial.tscn")
	)
