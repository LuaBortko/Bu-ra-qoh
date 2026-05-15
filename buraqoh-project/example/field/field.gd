class_name Field
extends MarginContainer

@onready var card_drop_area_right: Area2D = $CardDropAreaRight
@onready var card_drop_area_left: Area2D = $CardDropAreaLeft
var cards_holder: HBoxContainer  # ← remove o @onready daqui

func _ready():
	if has_node("ScrollContainer/CardsHolder"):
		cards_holder = $ScrollContainer/CardsHolder
	else:
		cards_holder = $CardsHolder
	
	$Label.text = name
	for child in cards_holder.get_children():
		if child is Card:
			child.home_field = self


func return_card_starting_position(card: Card):
	var holder = _get_cards_holder()
	if holder == null:
		return
	card.reparent(holder)
	holder.move_child(card, card.index)
	
func card_reposition(card: Card):
	var holder = _get_cards_holder()
	if holder == null:
		push_error("cards_holder é null em " + name)
		return
	var field_areas = card.drop_point_detector.get_overlapping_areas()
	var cards_areas = card.card_detector.get_overlapping_areas()
	var index: int = 0
	
	if cards_areas.is_empty():
		if field_areas.has(card_drop_area_right):
			index = holder.get_children().size()
	elif cards_areas.size() == 1:
		if field_areas.has(card_drop_area_left):
			index = cards_areas[0].get_parent().get_index()
		else:
			index = cards_areas[0].get_parent().get_index() + 1
	else:
		index = cards_areas[0].get_parent().get_index()
		if index > cards_areas[1].get_parent().get_index():
			index = cards_areas[1].get_parent().get_index()
		index += 1

	card.reparent(holder)
	holder.move_child(card, index)

func set_new_card(card: Card):
	card_reposition(card)
	card.home_field = self
	
func _get_cards_holder() -> HBoxContainer:
	if cards_holder != null:
		return cards_holder
	if has_node("ScrollContainer/CardsHolder"):
		cards_holder = $ScrollContainer/CardsHolder
	elif has_node("CardsHolder"):
		cards_holder = $CardsHolder
	return cards_holder
