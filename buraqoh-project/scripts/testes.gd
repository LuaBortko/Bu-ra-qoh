extends Control
@export var deck: Node  # arraste o nó Deck aqui no inspetor

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	deck.maoTeste()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
