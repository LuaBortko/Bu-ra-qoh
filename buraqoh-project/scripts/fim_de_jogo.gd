extends Control

@onready var resultado_label: Label = $CenterContainer/VBoxContainer/ResultadoLabel
@onready var vidas_label: Label = $CenterContainer/VBoxContainer/VidasLabel
@onready var btn_menu: Button = $CenterContainer/VBoxContainer/BtnMenu

# Recebe o índice do vencedor (0 ou 1)
func setup(winner_index: int, hp: Array) -> void:
	resultado_label.text = "🏆 Jogador %d Venceu!" % (winner_index + 1)
	vidas_label.text = "❤ J1: %d    ❤ J2: %d" % [hp[0], hp[1]]
	btn_menu.pressed.connect(_on_menu_pressed)

func _on_menu_pressed() -> void:
	# Reseta o HP antes de voltar ao menu
	GameManager.reset()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
