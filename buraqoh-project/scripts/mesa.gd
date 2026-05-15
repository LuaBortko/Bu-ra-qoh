
extends Control

# Referências da UI
@onready var mao_j1: Field = $CanvasLayer/MaoJ1
@onready var mao_j2: Field = $CanvasLayer/MaoJ2
@onready var deck_node: Node = $CanvasLayer/Deck
@onready var pilha_descarte: Control = $CanvasLayer/pilha_descarte
@onready var field_mesa_j1: Control = $CanvasLayer/field_mesa_j1
@onready var field_mesa_j2: Control = $CanvasLayer/field_mesa_j2
@onready var effect_indicator = $CanvasLayer/SpecialEffectIndicator
# Carrega a cena do overlay
var overlay_scene = preload("res://scenes/overlay.tscn")
var current_overlay: ColorRect = null

@onready var ai_player_node: Node = $AIPlayer

func _ready() -> void:
	#GameManager.reset()
	GameManager.setup(
		[mao_j1, mao_j2],
		deck_node,
		pilha_descarte,
		[field_mesa_j1, field_mesa_j2]
	)

	# ← define personagens PRIMEIRO, antes de qualquer outra coisa
	if StoryManager.modo_historia:
		_setup_historia()
	else:
		_setup_vs()

	pilha_descarte.top_card_clicked.connect(_on_discard_top_clicked)
	GameManager.turn_changed.connect(_on_turn_changed)
	GameManager.game_ended.connect(_on_game_ended)
	GameManager.game_ended.connect(_on_game_ended_historia)

	_deal_initial_hand()
	
	if StoryManager.modo_historia:
		# Sem overlay — inicia direto
		_on_welcome_closed()
	else:
		_show_overlay("", "", _on_welcome_closed)
		
	_criar_labels_personagens()
	_criar_botao_coracao()
	effect_indicator.visible = false
	GameManager.special_effect_triggered.connect(
		func(name, desc): effect_indicator.show_effect(name, desc)
	)

func _setup_historia() -> void:
	var luta = StoryManager.get_luta_atual()
	var pag = preload("res://scripts/pag_personagens.gd")
	var personagens = pag.PERSONAGENS

	# Define personagem do jogador
	GameManager.set_character(0, luta.player_char, personagens[luta.player_char])
	# Define personagem da IA
	GameManager.set_character(1, luta.ai_char, personagens[luta.ai_char])

	# Setup da IA
	ai_player_node.setup(mao_j2, field_mesa_j2, 1)
	GameManager.turn_changed.connect(_on_turn_changed_historia)

func _setup_vs() -> void:
	# Fluxo normal do modo vs — abre tela de seleção de personagem
	pass

func _on_turn_changed_historia(player_index: int) -> void:
	_update_visibility()
	if player_index == 1:
		# Vez da IA
		await get_tree().create_timer(0.5).timeout
		ai_player_node.play_turn()

func _on_game_ended_historia(winner: int) -> void:
	if not StoryManager.modo_historia:
		return

	var canvas = CanvasLayer.new()
	canvas.layer = 200
	add_child(canvas)

	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12, 0.97)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(bg)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_child(center)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	center.add_child(vbox)

	var resultado = Label.new()
	if winner == 0:
		resultado.text = "Vitória!"
		resultado.add_theme_color_override("font_color", Color.YELLOW)
	else:
		resultado.text = "Derrota..."
		resultado.add_theme_color_override("font_color", Color.RED)
	resultado.add_theme_font_size_override("font_size", 64)
	resultado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(resultado)

	# Nome do personagem vencedor
	var vencedor_data = GameManager.player_characters[winner]
	var sub = Label.new()
	sub.text = "%s venceu a batalha!" % vencedor_data.get("nome", "?").capitalize()
	sub.add_theme_font_size_override("font_size", 28)
	sub.add_theme_color_override("font_color", Color.WHITE)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub)

	var btn = Button.new()
	btn.text = "Continuar"
	btn.add_theme_font_size_override("font_size", 28)
	btn.custom_minimum_size = Vector2(200, 50)
	btn.pressed.connect(func():
		canvas.queue_free()
		if winner == 0:
			StoryManager.on_player_won()
		else:
			StoryManager.on_player_lost()
	)
	vbox.add_child(btn)
	
func _criar_botao_coracao() -> void:
	# Só aparece se algum dos jogadores for Coração das Cartas
	var j0 = GameManager.get_classe(0) == "Coração das Cartas"
	var j1 = GameManager.get_classe(1) == "Coração das Cartas"
	if not j0 and not j1:
		return

	var btn = Button.new()
	btn.text = "Carta Especial"
	btn.add_theme_font_size_override("font_size", 16)
	btn.custom_minimum_size = Vector2(160, 40)

	# Canto inferior direito
	btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)

	btn.offset_left   = -170
	btn.offset_top    = -50
	btn.offset_right  = -10
	btn.offset_bottom = -10

	btn.pressed.connect(_on_coracao_pressed)

	$CanvasLayer.add_child(btn)
	set_meta("btn_coracao", btn)

func _on_coracao_pressed() -> void:
	if not GameManager.pode_usar_coracao():
		return
	_show_picker_coracao()

func _show_picker_coracao() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 120
	add_child(canvas)

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.9)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(bg)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_child(center)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.custom_minimum_size = Vector2(400, 0)
	center.add_child(vbox)

	var titulo = Label.new()
	titulo.text = "Escolha uma carta para comprar"
	titulo.add_theme_font_size_override("font_size", 24)
	titulo.add_theme_color_override("font_color", Color.YELLOW)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(titulo)

	# Seletor de valor
	var lbl_valor = Label.new()
	lbl_valor.text = "Valor:"
	lbl_valor.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(lbl_valor)

	var valores = ["A","2","3","4","5","6","7","8","9","10","J","Q","K"]
	var opt_valor = OptionButton.new()
	for v in valores:
		opt_valor.add_item(v)
	vbox.add_child(opt_valor)

	# Seletor de naipe
	var lbl_naipe = Label.new()
	lbl_naipe.text = "Naipe:"
	lbl_naipe.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(lbl_naipe)

	var naipes = ["Copas","Espadas","Ouros","Paus"]
	var opt_naipe = OptionButton.new()
	for n in naipes:
		opt_naipe.add_item(n)
	vbox.add_child(opt_naipe)

	# Botões de ação
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(hbox)

	var btn_confirmar = Button.new()
	btn_confirmar.text = "Confirmar"
	btn_confirmar.add_theme_font_size_override("font_size", 20)
	btn_confirmar.custom_minimum_size = Vector2(140, 44)
	btn_confirmar.pressed.connect(func():
		var valor = valores[opt_valor.selected]
		var naipe = naipes[opt_naipe.selected]
		GameManager.usar_coracao(valor, naipe)
		canvas.queue_free()
	)
	hbox.add_child(btn_confirmar)

	var btn_cancelar = Button.new()
	btn_cancelar.text = "Cancelar"
	btn_cancelar.add_theme_font_size_override("font_size", 20)
	btn_cancelar.custom_minimum_size = Vector2(140, 44)
	btn_cancelar.pressed.connect(func():
		canvas.queue_free()
	)
	hbox.add_child(btn_cancelar)
	
func _criar_labels_personagens() -> void:
	var canvas = $CanvasLayer

	# Cria um container no canto superior direito
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	vbox.offset_left  = -220
	vbox.offset_top   = 10
	vbox.offset_right = -10
	vbox.offset_bottom = 80
	vbox.add_theme_constant_override("separation", 4)
	canvas.add_child(vbox)

	# Para cada jogador, monta o texto "J1 • NomePersonagem (Classe)"
	for i in range(2):
		var char_data = GameManager.player_characters[i]
		var label = Label.new()

		if char_data.is_empty():
			label.text = "J%d • Sem personagem" % (i + 1)
		else:
			label.text = "J%d • %s  [%s]" % [
				i + 1,
				char_data.get("nome", "?").capitalize(),
				char_data.get("classe", "?")
			]

		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color",
			Color.CYAN if i == 0 else Color.YELLOW
		)
		vbox.add_child(label)

func _on_game_ended(winner_index: int) -> void:
	# Fundo escuro
	var canvas = CanvasLayer.new()
	canvas.layer = 200
	add_child(canvas)

	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12, 0.97)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(bg)

	# Container central
	var center = CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	bg.add_child(center)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 30)
	center.add_child(vbox)

	# Label de resultado
	var resultado = Label.new()
	resultado.text = "🏆 Jogador %d Venceu!" % (winner_index + 1)
	resultado.add_theme_font_size_override("font_size", 64)
	resultado.add_theme_color_override("font_color", Color.YELLOW)
	resultado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(resultado)

	# Label de vidas
	var vidas = Label.new()
	vidas.text = "❤ J1: %d    ❤ J2: %d" % [GameManager.player_hp[0], GameManager.player_hp[1]]
	vidas.add_theme_font_size_override("font_size", 32)
	vidas.add_theme_color_override("font_color", Color.WHITE)
	vidas.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(vidas)

	# Botão de menu
	var btn = Button.new()
	btn.text = "Voltar ao Menu"
	btn.add_theme_font_size_override("font_size", 28)
	btn.pressed.connect(func():
		GameManager.reset()
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
	)
	vbox.add_child(btn)

func _deal_initial_hand() -> void:
	for i in range(11):
		deck_node.draw_card_for(0)
	for i in range(11):
		deck_node.draw_card_for(1)
	GameManager.aplicar_bonus_inicial()  # Mestre de Paus ganha J♣
	_update_visibility()

func _update_visibility() -> void:
	if StoryManager.modo_historia:
		mao_j1.visible = true   # jogador sempre visível
		mao_j2.visible = false  # IA nunca visível
	else:
		mao_j1.visible = (GameManager.current_player == 0)
		mao_j2.visible = (GameManager.current_player == 1)

func _show_overlay(title: String, message: String, callback: Callable = Callable()) -> void:
	# Remove overlay anterior
	if current_overlay:
		current_overlay.queue_free()
	
	# Cria o overlay programaticamente
	current_overlay = ColorRect.new()
	current_overlay.color = Color(0, 0, 0, 0.99)
	current_overlay.anchor_right = 1.0
	current_overlay.anchor_bottom = 1.0
	current_overlay.size = Vector2.ZERO
	current_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# CRIA UM CANVASLAYER PARA O OVERLAY FICAR ACIMA
	var canvas = CanvasLayer.new()
	canvas.layer = 100  # Número alto para ficar acima de tudo
	canvas.add_child(current_overlay)
	add_child(canvas)
	
	# Guarda referência do canvas para remover depois
	current_overlay.set_meta("canvas", canvas)
	
	# Cria o conteúdo (mesmo código de antes)
	var center = CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	current_overlay.add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)
	
	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", Color.YELLOW)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)
	
	var msg_label = Label.new()
	msg_label.text = message
	msg_label.add_theme_font_size_override("font_size", 32)
	msg_label.add_theme_color_override("font_color", Color.WHITE)
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(msg_label)
	
	var click_label = Label.new()
	click_label.text = "Clique para continuar"
	click_label.add_theme_font_size_override("font_size", 24)
	click_label.add_theme_color_override("font_color", Color.GRAY)
	click_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(click_label)
	
	# Conecta o clique
	current_overlay.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			if callback.is_valid():
				callback.call()
			# Remove o canvas também
			var canvas_parent = current_overlay.get_meta("canvas", null)
			if canvas_parent:
				canvas_parent.queue_free()
			else:
				current_overlay.queue_free()
			current_overlay = null
	)

func _on_welcome_closed() -> void:
	# Inicia o jogo após fechar o overlay de boas-vindas
	GameManager.start_round(0)
	_update_visibility()

func _on_turn_changed(player_index: int) -> void:
	_update_visibility()
	# No modo história não mostra overlay de turno
	if StoryManager.modo_historia:
		return
	_show_overlay(
		"VEZ DO JOGADOR %d" % (player_index + 1),
		"Clique para começar seu turno",
		func(): pass
	)

# Botão de descarte
func _on_discard_top_clicked(_card) -> void:
	if GameManager.is_current_player_turn(GameManager.current_player):
		GameManager.draw_from_discard()


#PAUSE
var pause_canvas: CanvasLayer = null

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if pause_canvas != null:
			_fechar_pause()
		else:
			_abrir_pause()

	# Cheat de teste — só funciona no editor
	if OS.is_debug_build() and event is InputEventKey:
		if event.pressed and event.keycode == KEY_G:
			print("[CHEAT] Vitória instantânea ativada!")
			_on_game_ended_historia(0)

func _abrir_pause() -> void:
	get_tree().paused = true

	pause_canvas = CanvasLayer.new()
	pause_canvas.layer = 150
	pause_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pause_canvas)

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_canvas.add_child(bg)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.process_mode = Node.PROCESS_MODE_ALWAYS
	bg.add_child(center)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.custom_minimum_size = Vector2(300, 0)
	center.add_child(vbox)

	var titulo = Label.new()
	titulo.text = "— PAUSE —"
	titulo.add_theme_font_size_override("font_size", 48)
	titulo.add_theme_color_override("font_color", Color.WHITE)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(titulo)

	var btn_voltar = Button.new()
	btn_voltar.text = "Voltar ao Jogo"
	btn_voltar.add_theme_font_size_override("font_size", 24)
	btn_voltar.custom_minimum_size = Vector2(300, 50)
	btn_voltar.process_mode = Node.PROCESS_MODE_ALWAYS
	btn_voltar.pressed.connect(_fechar_pause)
	vbox.add_child(btn_voltar)

	var btn_menu = Button.new()
	btn_menu.text = "Voltar ao Menu"
	btn_menu.add_theme_font_size_override("font_size", 24)
	btn_menu.custom_minimum_size = Vector2(300, 50)
	btn_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	btn_menu.pressed.connect(func():
		get_tree().paused = false
		StoryManager.modo_historia = false 
		GameManager.reset()
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
	)
	vbox.add_child(btn_menu)

func _fechar_pause() -> void:
	get_tree().paused = false
	if pause_canvas != null:
		pause_canvas.queue_free()
		pause_canvas = null
