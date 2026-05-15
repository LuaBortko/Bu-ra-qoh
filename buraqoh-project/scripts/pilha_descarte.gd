
extends Control

@onready var card_sprite: TextureRect = $CardSprite

var pile: Array[Card] = []   # topo = último elemento

signal top_card_clicked(card: Card)

func _ready() -> void:
	_refresh_display()
	# Clique no topo do descarte = comprar do descarte
	gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_empty():
			top_card_clicked.emit(pile.back())

func add_card(card: Card) -> void:
	## Move a carta física para esta pilha e atualiza o display.
	card.reparent(self)
	card.visible = false     # a carta fica "escondida" na pilha
	card.home_field = null   # não tem mais home_field
	pile.append(card)
	_refresh_display()

func take_top_card() -> Card:
	## Remove e retorna a carta do topo (para o jogador pegar).
	if is_empty():
		return null
	var card = pile.pop_back()
	card.visible = true
	_refresh_display()
	return card

func peek_top() -> Card:
	## Retorna a carta do topo sem remover.
	if is_empty():
		return null
	return pile.back()

func is_empty() -> bool:
	return pile.is_empty()

func size() -> int:
	return pile.size()

# ─────────────────────────────────────────────
#  DISPLAY
# ─────────────────────────────────────────────
func _refresh_display() -> void:
	var top = peek_top()
	if top == null:
		card_sprite.texture = null
		card_sprite.visible = false
	else:
		card_sprite.visible = true
		# Copia a textura da carta do topo para exibir
		if top.is_joker:
			card_sprite.texture = top.get_node("CardSprite").texture
		else:
			card_sprite.texture = top.get_node("CardSprite").texture
