
extends ColorRect

@onready var title_label: Label = $CenterContainer/VBoxContainer/TitleLabel
@onready var message_label: Label = $CenterContainer/VBoxContainer/MessageLabel

var click_callback: Callable

func _ready():
	# Debug: verifica se encontrou os labels
	print("Overlay _ready - title_label: ", title_label)
	print("Overlay _ready - message_label: ", message_label)
	
	# Se não encontrou, tenta encontrar de outra forma
	if not title_label:
		print("Tentando encontrar TitleLabel alternativamente...")
		title_label = get_node_or_null("CenterContainer/VBoxContainer/TitleLabel")
		if not title_label:
			title_label = get_node_or_null("CenterContainer/TitleLabel")
			if not title_label:
				title_label = get_node_or_null("TitleLabel")
	
	if not message_label:
		print("Tentando encontrar MessageLabel alternativamente...")
		message_label = get_node_or_null("CenterContainer/VBoxContainer/MessageLabel")
		if not message_label:
			message_label = get_node_or_null("CenterContainer/MessageLabel")
			if not message_label:
				message_label = get_node_or_null("MessageLabel")

func setup(title: String, message: String, callback: Callable = Callable()) -> void:
	print("Setup chamado - Título: ", title)
	
	if title_label:
		title_label.text = title
		print("Título definido")
	else:
		print("ERRO: title_label é null - criando label manualmente")
		_create_labels_manually()
		if title_label:
			title_label.text = title
	
	if message_label:
		message_label.text = message
		print("Mensagem definida")
	else:
		print("ERRO: message_label é null")
	
	click_callback = callback

func _create_labels_manually():
	print("Criando labels manualmente")
	
	# Remove filhos existentes
	for child in get_children():
		child.queue_free()
	
	# Cria estrutura manualmente
	var center = CenterContainer.new()
	center.name = "CenterContainer"
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)
	
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", Color.YELLOW)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)
	
	message_label = Label.new()
	message_label.name = "MessageLabel"
	message_label.add_theme_font_size_override("font_size", 32)
	message_label.add_theme_color_override("font_color", Color.WHITE)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(message_label)
	
	var click_label = Label.new()
	click_label.name = "ClickLabel"
	click_label.text = "Clique para continuar"
	click_label.add_theme_font_size_override("font_size", 24)
	click_label.add_theme_color_override("font_color", Color.GRAY)
	click_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(click_label)
	
	print("Labels criadas manualmente")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Clique no overlay")
		if click_callback.is_valid():
			click_callback.call()
		queue_free()
