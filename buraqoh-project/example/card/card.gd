class_name Card
extends Control


@onready var color_rect: ColorRect = $ColorRect
@onready var label: Label = $Label
@onready var name_label: Label = %NameLabel
@onready var state_machine: CardStateMachine = $CardStateMachine
@onready var drop_point_detector: Area2D = $DropPointDetector
@onready var card_detector: Area2D = $CardsDetector
@onready var home_field: Field

#Sprites ---------------------------------------------------------
@onready var card_sprite: TextureRect = $CardSprite
const SPRITESHEET = preload("res://assets/cards_spritesheet.png") 
const JOKER = preload("res://assets/cards_coringa.png")

const CARD_WIDTH  = 96
const CARD_HEIGHT = 128

var is_wild: bool = false  # true para coringa e 2

const VALUE_NUM = {
	"A": 1, "2": 2, "3": 3, "4": 4, "5": 5, "6": 6,
	"7": 7, "8": 8, "9": 9, "10": 10, "J": 11, "Q": 12, "K": 13
}

# Ordem das linhas na sua spritesheet
const SUIT_ROW = {
	"Ouros":   0,
	"Espadas": 1,
	"Copas":   2,
	"Paus":    3,
}

# Ordem das colunas (Ás até Rei)
const VALUE_COL = {
	"A": 0, "2": 1, "3": 2,  "4": 3,  "5": 4,  "6": 5,
	"7": 6, "8": 7, "9": 8, "10": 9, "J": 10, "Q": 11, "K": 12,
}
#----------------------------------------------------------------------
var index: int = 0

var suit : String #Tipo da carta (paus, ouros, espadas, copas)
var value : String #Qual a carta
var effect : String

var is_joker: bool = false

#Seleção---------------------------------------------
var selected: bool = false

func toggle_select() -> void:
	selected = !selected
	# Feedback visual — troca a borda ou cor
	if selected:
		color_rect.color = Color.GOLD
	else:
		color_rect.color = Color.WEB_GREEN   # cor padrão idle
#----------------------------------------------------

func get_num_value() -> int:
	if is_joker or is_wild:
		return 0  # curingas não têm valor fixo
	return VALUE_NUM.get(value, 0)

func setup(card_value, card_suit, card_is_joker := false):
	is_joker = card_is_joker
	value = card_value
	suit = card_suit if card_suit != null else ""
	# 2 é considerado curinga no buraco
	is_wild = (value == "2" and not is_joker)
	if is_joker:
		card_sprite.texture = JOKER
	else:
		_apply_sprite(suit, value)

func _apply_sprite(card_suit: String, card_value: String) -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = SPRITESHEET
	atlas.region = Rect2(VALUE_COL[card_value] * CARD_WIDTH, SUIT_ROW[card_suit]* CARD_HEIGHT, CARD_WIDTH, CARD_HEIGHT)
	card_sprite.texture = atlas

func _ready():
	#name_label.text = name
	pass

func _input(event):
	state_machine.on_input(event)

func _on_gui_input(event):
	if can_interact():
		state_machine.on_gui_input(event)

func _on_mouse_entered():
	if can_interact():
		state_machine.on_mouse_entered()

func _on_mouse_exited():
	if can_interact():
		state_machine.on_mouse_exited()
	
func can_interact() -> bool:
	# Verifica se a carta está na mão do jogador atual
	if home_field is Field:
		# Se for uma mão de jogador
		var hand_index = -1
		if home_field == GameManager.hands[0]:
			hand_index = 0
		elif home_field == GameManager.hands[1]:
			hand_index = 1
		
		# Só permite interagir se for a mão do jogador atual
		return hand_index == GameManager.current_player and GameManager.phase == GameManager.Phase.PLAYING
	
	# Se não for mão (está na mesa), permite interação normal
	return true
