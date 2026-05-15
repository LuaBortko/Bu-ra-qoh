extends Control

@onready var sprite: Sprite2D      = $Destaque
@onready var texto: Label          = $Bloco_Descricao/Texto/Descricao
@onready var classe: Label         = $Bloco_Descricao/Texto/Classe
@onready var btn_confirmar: Button = $Confirmar

const PERSONAGENS: Dictionary = {
	"fatima":  { "sprite": "res://assets/antigosSprites/fatima.png",   "classe": "Berserker",          "descricao": "Mais dano nas jogadas, mas começa com menos vida.",             "hp_mult": 0.80, "damage_mult": 1.20 },
	"sueli":   { "sprite": "res://assets/antigosSprites/sueli.png",    "classe": "Berserker",          "descricao": "Mais dano nas jogadas, mas começa com menos vida.",             "hp_mult": 0.80, "damage_mult": 1.20 },
	"pc":      { "sprite": "res://assets/antigosSprites/pc.png",       "classe": "Equilibrado",        "descricao": "Atributos balanceados entre dano e vida.",                      "hp_mult": 1.00, "damage_mult": 1.00 },
	"lucilene":{ "sprite": "res://assets/antigosSprites/lucilene.png", "classe": "Equilibrado",        "descricao": "Atributos balanceados entre dano e vida.",                      "hp_mult": 1.00, "damage_mult": 1.00 },
	"jorge":   { "sprite": "res://assets/antigosSprites/jorge.png",    "classe": "Tanque",             "descricao": "Muita vida, pouco dano. Difícil de abater.",                    "hp_mult": 1.20, "damage_mult": 0.80 },
	"armane":  { "sprite": "res://assets/antigosSprites/armani.png",   "classe": "Tanque",             "descricao": "Muita vida, pouco dano. Difícil de abater.",                    "hp_mult": 1.20, "damage_mult": 0.80 },
	"tijolo":  { "sprite": "res://assets/antigosSprites/tijolo.png",   "classe": "Resistência",        "descricao": "Perde menos vida por rodada ao segurar cartas na mão.",         "hp_mult": 1.00, "damage_mult": 1.00 },
	"djalma":  { "sprite": "res://assets/antigosSprites/djalma.png",   "classe": "Resistência",        "descricao": "Perde menos vida por rodada ao segurar cartas na mão.",         "hp_mult": 1.00, "damage_mult": 1.00 },
	"chalita": { "sprite": "res://assets/antigosSprites/chalita.png",  "classe": "Coração das Cartas", "descricao": "Pode comprar uma carta específica do baralho periodicamente.",   "hp_mult": 1.00, "damage_mult": 1.00 },
	"bia":     { "sprite": "res://assets/antigosSprites/bia.png",      "classe": "Mestre de Paus",     "descricao": "Começa com um Valete de Paus na mão.",                          "hp_mult": 1.00, "damage_mult": 1.00 },
	"flavinha":{ "sprite": "res://assets/antigosSprites/flavinha.png", "classe": "Mestre da Canastra", "descricao": "Canastras limpas causam dano massivo ao adversário.",            "hp_mult": 1.00, "damage_mult": 1.00 },
	"santo":   { "sprite": "res://assets/antigosSprites/santo.png",    "classe": "Mestre da Canastra", "descricao": "Canastras limpas causam dano massivo ao adversário.",            "hp_mult": 1.00, "damage_mult": 1.00 },
	"tavares": { "sprite": "res://assets/antigosSprites/tavares.png",  "classe": "Sobrevivente",       "descricao": "Sobrevive com 1 HP ao receber dano fatal uma vez por partida.", "hp_mult": 1.00, "damage_mult": 1.00 },
	"jurandir":{ "sprite": "res://assets/antigosSprites/jurandir.png", "classe": "Sobrevivente",       "descricao": "Sobrevive com 1 HP ao receber dano fatal uma vez por partida.", "hp_mult": 1.00, "damage_mult": 1.00 },
}

var selecting_player: int = 0
var selected_name: String = ""

func _ready() -> void:
	# Configura os labels — sem clip_text para não cortar o texto
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	classe.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	for botao in get_tree().get_nodes_in_group("buttons"):
		botao.pressed.connect(botao_pressionado.bind(botao))

	btn_confirmar.pressed.connect(_on_confirmar)

	classe.text = ""
	texto.text  = "Selecione um personagem"
	sprite.texture = null

func botao_pressionado(botao: Button) -> void:
	var nome = botao.name.to_lower()
	if not PERSONAGENS.has(nome):
		return

	selected_name = nome
	var dados = PERSONAGENS[nome]
	sprite.texture = load(dados["sprite"])
	classe.text    = dados["classe"]
	texto.text     = dados["descricao"]

func _on_confirmar() -> void:
	if selected_name == "":
		texto.text = "Escolha um personagem antes de confirmar!"
		return

	GameManager.set_character(selecting_player, selected_name, PERSONAGENS[selected_name])

	if selecting_player == 0:
		selecting_player = 1
		selected_name    = ""
		sprite.texture   = null
		classe.text      = ""
		texto.text       = "Selecione um personagem"
		_show_handoff_screen()
	else:
		get_tree().change_scene_to_file("res://scenes/mesa.tscn")

func _show_handoff_screen() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)

	# Fundo escuro cobrindo tudo
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.97)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(bg)

	# Centra o conteúdo
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_child(center)

	# Container com largura limitada para o texto não ficar espremido
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 0)
	center.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 30)
	vbox.custom_minimum_size = Vector2(460, 0)
	panel.add_child(vbox)

	var lbl = Label.new()
	lbl.text = "Jogador 1 confirmou sua escolha!\n\nPasse o dispositivo ao Jogador 2."
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(lbl)

	var btn = Button.new()
	btn.text = "Continuar"
	btn.add_theme_font_size_override("font_size", 24)
	btn.custom_minimum_size = Vector2(200, 50)
	btn.pressed.connect(func():
		canvas.queue_free()
	)
	vbox.add_child(btn)
