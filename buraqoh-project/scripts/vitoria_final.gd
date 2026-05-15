
extends Control

func _ready() -> void:
	# Fundo escuro
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.10, 1.0)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	var center = CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	add_child(center)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 32)
	vbox.custom_minimum_size = Vector2(500, 0)
	center.add_child(vbox)

	# Título
	var titulo = Label.new()
	titulo.text = "🏆 FIM DE JOGO 🏆"
	titulo.add_theme_font_size_override("font_size", 64)
	titulo.add_theme_color_override("font_color", Color.YELLOW)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(titulo)

	# Subtítulo
	var sub = Label.new()
	sub.text = "Você completou o Modo História!\nParabéns, campeã do Elegance Queen!"
	sub.add_theme_font_size_override("font_size", 28)
	sub.add_theme_color_override("font_color", Color.WHITE)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(sub)

	# Separador
	vbox.add_child(HSeparator.new())

	# Botão — voltar ao menu
	var btn_menu = Button.new()
	btn_menu.text = "Voltar ao Menu"
	btn_menu.add_theme_font_size_override("font_size", 28)
	btn_menu.custom_minimum_size = Vector2(300, 55)
	btn_menu.pressed.connect(_on_menu_pressed)
	vbox.add_child(btn_menu)

	# Botão — jogar novamente (reinicia modo história)
	var btn_replay = Button.new()
	btn_replay.text = "Jogar Novamente"
	btn_replay.add_theme_font_size_override("font_size", 22)
	btn_replay.custom_minimum_size = Vector2(300, 50)
	btn_replay.add_theme_color_override("font_color", Color.CYAN)
	btn_replay.pressed.connect(_on_replay_pressed)
	vbox.add_child(btn_replay)

func _on_menu_pressed() -> void:
	GameManager.reset()
	StoryManager.luta_index = 0
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_replay_pressed() -> void:
	GameManager.reset()
	StoryManager.start_historia()   # reinicia do zero
