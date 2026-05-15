extends CardState

func _enter():
	if not card.selected:
		card.color_rect.color = Color.BLUE
	card.label.text = "DRAG"
	card.index = card.get_index()

	var canvas_layer := get_tree().get_first_node_in_group("fields")
	if canvas_layer:
		card.reparent(canvas_layer)
		# Manda as outras cartas selecionadas pro CanvasLayer também
		for other in GameManager.selected_cards:
			if other != card:
				other.index = other.get_index()
				other.reparent(canvas_layer)

func on_input(event: InputEvent):
	var mouse_motion := event is InputEventMouseMotion
	var confirm = event.is_action_released("mouse_left")

	if mouse_motion:
		card.global_position = card.get_global_mouse_position() - card.pivot_offset
		# Move as outras cartas selecionadas em fila ao lado
		var others = GameManager.selected_cards.filter(func(c): return c != card)
		for i in others.size():
			others[i].global_position = card.global_position + Vector2((i + 1) * (card.size.x + 8), 0)

	if confirm:
		get_viewport().set_input_as_handled()
		# Dispara Release em todas as selecionadas
		for other in GameManager.selected_cards:
			if other != card:
				other.home_field.return_card_starting_position(other)
		transitioned.emit("Release")
