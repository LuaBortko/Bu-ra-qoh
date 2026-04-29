extends Node2D
@export var card_scene : PackedScene

var deck : Array = []
var suits = ["Copas","Espadas","Ouros","Paus"]
var values = ["A","2","3","4","5","6","7","8","9","10","J","Q","K"]
var baralhos = 2;

func create_deck():
	for i in range(baralhos): # 2 baralhos
		for suit in suits:
			for value in values:
				for copy in range(1):
					var card = card_scene.instantiate()
					card.setup(value, suit)
					deck.append(card)
					add_child(card)
	#Adição dos coringas do baralho
	for i in range(baralhos):
		for j in range(2):
			var card = card_scene.instantiate()
			var value = "Joker"
			var suit = null
			card.setup(value, suit)
			deck.append(card)
			add_child(card)

func shuffle_deck():
	deck.shuffle()

func draw_card():
	if deck.is_empty():
		return null
	return deck.pop_back()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
