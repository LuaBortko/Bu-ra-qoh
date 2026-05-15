extends Control

@onready var btn_jogar: Button = $botoes/Jogar
@onready var btn_sair: Button = $botoes/Sair

func _ready() -> void:
	btn_jogar.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/modo_selecao.tscn")
	)
	btn_sair.pressed.connect(func():
		get_tree().quit()
	)
