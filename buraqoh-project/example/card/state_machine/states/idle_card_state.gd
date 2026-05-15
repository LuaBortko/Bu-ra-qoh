extends CardState


func _enter():
	# Só muda a cor se a carta não estiver selecionada
	if not card.selected:
		card.color_rect.color = Color.WEB_GREEN
	card.label.text = "Idle"
	card.pivot_offset = Vector2.ZERO

func on_mouse_entered():
	transitioned.emit("hover")

func on_gui_input(event: InputEvent):
	if event.is_action_pressed("mouse_left"):
		card.pivot_offset = card.get_global_mouse_position() - card.global_position
		transitioned.emit("Click")

# Clique rápido sem mover → seleciona
func on_mouse_exited():
	transitioned.emit("Idle")
