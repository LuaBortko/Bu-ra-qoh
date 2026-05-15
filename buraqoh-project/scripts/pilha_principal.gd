extends TextureButton

@export var deck: Node  # arraste o nó Deck aqui no inspetor
@onready var count_label: Label = $CountLabel

func _ready() -> void:
	count_label.text = str(deck.deck.size())

func _pressed() -> void:
	var ok = GameManager.draw_from_deck()
	if ok:
		count_label.text = str(deck.deck.size())
		if deck.deck.is_empty():
			disabled = true
