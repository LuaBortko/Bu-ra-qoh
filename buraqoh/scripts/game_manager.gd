extends Node
@export var deck: PackedScene


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	deck.create_deck()
	deck.shuffle_deck()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
