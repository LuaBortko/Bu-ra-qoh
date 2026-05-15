extends Node2D

@export var card_scene: PackedScene
# Arraste o Field da mão do jogador aqui no inspetor
@export var player_hand: Field

var deck: Array = []
var suits = ["Copas", "Espadas", "Ouros", "Paus"]
var values = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
var baralhos = 2

func _ready() -> void:
	create_deck()
	shuffle_deck()

func create_deck() -> void:
	for i in range(baralhos):
		for suit in suits:
			for value in values:
				var card_data = {"value": value, "suit": suit, "is_joker": false}
				deck.append(card_data)
	# Coringas: 2 por baralho = 4 no total
	for i in range(baralhos * 2):
		deck.append({"value": "Joker", "suit": null, "is_joker": true})

func shuffle_deck() -> void:
	deck.shuffle()

func draw_card() -> void:
	if deck.is_empty():
		push_warning("Monte vazio!")
		return
	var card_data = deck.pop_back()
	# Instancia a carta e envia para a mão do jogador
	var card = card_scene.instantiate()
	player_hand.get_node("CardsHolder").add_child(card)
	card.setup(card_data["value"], card_data["suit"], card_data["is_joker"])
	print(card_data["value"], " de ", card_data["suit"])
	# Define o home_field da carta como a mão do jogador
	card.home_field = player_hand
	
#------------Para teste-----------------------------------------------------
func maoTeste():
	setarCarta("7","Espadas",false)
	setarCarta("8","Espadas",false)
	setarCarta("9","Espadas",false)
	setarCarta("10","Espadas",false)
	setarCarta("5","Paus",false)
	setarCarta("5","Espadas",false)
	setarCarta("5","Espadas",false)
	setarCarta("J","Ouros",false)
	setarCarta("K","Ouros",false)
	setarCarta("","",true)
	setarCarta("","",true)

func setarCarta(value,suit,is_joker):
	var card = card_scene.instantiate()
	player_hand.get_node("CardsHolder").add_child(card)
	card.setup(value,suit,is_joker)
	card.home_field = player_hand
#----------------------------------------------------------------------

func draw_card_for(player_index: int) -> void:
	if deck.is_empty():
		push_warning("Monte vazio!")
		return
	var card_data = deck.pop_back()
	var card = card_scene.instantiate()
	var hand = GameManager.hands[player_index]
	hand.get_node("ScrollContainer/CardsHolder").add_child(card)
	card.setup(card_data["value"], card_data["suit"], card_data["is_joker"])
	card.home_field = hand
	
func draw_specific_card_for(player_index: int, valor: String, naipe: String) -> void:
	# Procura a carta específica no baralho
	for i in range(deck.size()):
		if deck[i]["value"] == valor and deck[i]["suit"] == naipe:
			var card_data = deck[i]
			deck.remove_at(i)
			var card = card_scene.instantiate()
			var hand = GameManager.hands[player_index]
			hand.get_node("ScrollContainer/CardsHolder").add_child(card)
			card.setup(card_data["value"], card_data["suit"], card_data["is_joker"])
			card.home_field = hand
			return
	# Se não encontrou (carta já saiu do baralho), compra uma aleatória
	draw_card_for(player_index)
