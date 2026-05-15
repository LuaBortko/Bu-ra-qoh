extends CardState

func _enter():
	var drop_pos = card.get_global_mouse_position()
	var current_table = GameManager.get_current_table_field()
	var handled = false

	# ── Soltou na mesa ──────────────────────────────────
	if current_table and current_table.get_global_rect().has_point(drop_pos):
		var group = current_table.get_group_at(drop_pos)
		if group:
			if group.can_add_card(card):
				group.set_new_card(card)
				handled = true
			else:
				card.home_field.return_card_starting_position(card)
		else:
			if GameManager.try_play_group():
				current_table.create_group(GameManager.selected_cards.duplicate())
				handled = not GameManager.selected_cards.has(card)
			else:
				card.home_field.return_card_starting_position(card)

	# ── Soltou dentro da própria mão = reposiciona ──────
	elif card.home_field and card.home_field.get_global_rect().has_point(drop_pos):
		card.home_field.card_reposition(card)
		for other in GameManager.selected_cards:
			if other != card:
				other.home_field.return_card_starting_position(other)
		GameManager.clear_selection()
		handled = true

	# ── Soltou fora de tudo = volta pra casa ────────────
	else:
		card.home_field.return_card_starting_position(card)

	# Se não foi tratado corretamente, devolve tudo
	if not handled:
		for other in GameManager.selected_cards:
			if other != card:
				other.home_field.return_card_starting_position(other)

	transitioned.emit("Idle")
