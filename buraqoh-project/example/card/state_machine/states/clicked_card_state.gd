extends CardState

func _enter():
	card.color_rect.color = Color.ORANGE
	card.label.text = "CLICKED"

func on_input(event: InputEvent):
	# Release detectado globalmente — funciona mesmo se mouse saiu da carta
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			card.toggle_select()
			GameManager.register_selection(card)
			transitioned.emit("Idle")

func on_gui_input(event: InputEvent):
	# Movimento detectado apenas dentro da carta
	if event is InputEventMouseMotion:
		if event.relative.length() > 3.0:
			transitioned.emit("Drag")
