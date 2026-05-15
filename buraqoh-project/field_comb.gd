class_name GroupField
extends Field

const CANASTRA_MIN_CARDS: int = 7

# ─────────────────────────────────────────────
#  ESTADO DO FIELD
# ─────────────────────────────────────────────
var is_occupied: bool = false

func _ready() -> void:
	if cards_holder == null:
		cards_holder = $CardsHolder
	$Overlay/DeleteButton.visible = false
	$Overlay/DeleteButton.pressed.connect(_on_delete_pressed)

func occupy() -> void:
	is_occupied = true
	$Overlay/DeleteButton.visible = true

func clear_group() -> void:
	for card in get_cards():
		card.queue_free()
	is_occupied = false
	$Overlay/DeleteButton.visible = false

func _on_delete_pressed() -> void:
	clear_group()

# ─────────────────────────────────────────────
#  CANASTRA
# ─────────────────────────────────────────────
func is_canastra() -> bool:
	return get_cards().size() >= CANASTRA_MIN_CARDS

func is_clean_canastra() -> bool:
	if not is_canastra():
		return false
	return get_cards().all(func(c): return not c.is_joker and not c.is_wild)

# ─────────────────────────────────────────────
#  CURINGAS
# ─────────────────────────────────────────────
func _get_base_value(non_joker_cards: Array) -> String:
	var non_two = non_joker_cards.filter(func(c): return c.value != "2")
	if non_two.is_empty():
		return "2"
	return non_two[0].value

func _get_base_suit(fixed: Array) -> String:
	var non_two = fixed.filter(func(c): return c.value != "2")
	if non_two.is_empty():
		return fixed[0].suit if not fixed.is_empty() else ""
	return non_two[0].suit

# ─────────────────────────────────────────────
#  PODE ADICIONAR CARTA?
# ─────────────────────────────────────────────
func can_add_card(card: Card) -> bool:
	var cards_here = get_cards()
	if cards_here.is_empty():
		return true
	var all_cards = cards_here + [card]
	return _fits_as_set(all_cards) or _fits_as_sequence(all_cards)

func _fits_as_set(cards: Array) -> bool:
	var jokers = cards.filter(func(c): return c.is_joker)
	var fixed = cards.filter(func(c): return not c.is_joker)
	if fixed.is_empty():
		return false
	var non_two = fixed.filter(func(c): return c.value != "2")
	var base_value = non_two[0].value if not non_two.is_empty() else "2"
	for c in fixed:
		if c.value != base_value and not (c.value == "2" and base_value != "2"):
			return false
	var wild_count = jokers.size()
	wild_count += fixed.filter(func(c): return c.value == "2" and base_value != "2").size()
	return wild_count <= 1

func _fits_as_sequence(cards: Array) -> bool:
	# O 2 é sempre curinga numa sequência, independente do naipe
	var jokers = cards.filter(func(c): return c.is_joker or c.value == "2")
	var fixed  = cards.filter(func(c): return not c.is_joker and c.value != "2")
	if fixed.is_empty():
		return false
	return _try_sequence(fixed, jokers, false) or _try_sequence(fixed, jokers, true)

func _try_sequence(fixed: Array, jokers: Array, ace_high: bool) -> bool:
	var non_two = fixed.filter(func(c): return c.value != "2")
	if non_two.is_empty():
		return false
	var base_suit = non_two[0].suit
	if not non_two.all(func(c): return c.suit == base_suit):
		return false
	var avail_wilds = jokers.size()
	if avail_wilds > 1:
		return false
	var seq = fixed.filter(func(c): return c.suit == base_suit)
	seq.sort_custom(func(a, b): return _get_num_flexible(a, ace_high) < _get_num_flexible(b, ace_high))
	for i in range(1, seq.size()):
		var diff = _get_num_flexible(seq[i], ace_high) - _get_num_flexible(seq[i-1], ace_high)
		if diff == 1:
			continue
		elif diff >= 2 and avail_wilds >= diff - 1:
			avail_wilds -= diff - 1
		else:
			return false
	return true

func _get_num_flexible(card: Card, ace_high: bool) -> int:
	if card.value == "A":
		return 14 if ace_high else 1
	return card.get_num_value()

func _sequence_is_valid(sorted_cards: Array, wilds: int) -> bool:
	if sorted_cards.is_empty():
		return false
	for i in range(1, sorted_cards.size()):
		var diff = sorted_cards[i].get_num_value() - sorted_cards[i-1].get_num_value()
		if diff == 1:
			continue
		elif diff >= 2 and wilds >= diff - 1:
			wilds -= diff - 1
		else:
			return false
	return true

# ─────────────────────────────────────────────
#  REORDENAÇÃO
# ─────────────────────────────────────────────
func set_new_card(card: Card) -> void:
	var was_occupied = is_occupied
	super.set_new_card(card)
	if not is_occupied:
		occupy()
	_reorder_cards()
	card.selected = false
	card.color_rect.color = Color.WEB_GREEN

	# Adição a grupo existente: aplica dano por carta
	if was_occupied:
		var opponent = 1 - GameManager.current_player
		GameManager.apply_damage(opponent, 10)

func _reorder_cards() -> void:
	var cards   = get_cards()
	var jokers  = cards.filter(func(c): return c.is_joker)
	var normals = cards.filter(func(c): return not c.is_joker)
	var non_two = normals.filter(func(c): return c.value != "2")

	var ordered: Array = []

	# Trio / Quadra (set)
	var base_val = non_two[0].value if not non_two.is_empty() else "2"
	var is_set   = normals.all(func(c): return c.value == base_val or (c.value == "2" and base_val != "2"))

	if is_set:
		ordered = non_two + jokers
	else:
		# Sequência — o 2 é sempre curinga
		var has_king  = normals.any(func(c): return c.value == "K")
		var ace_high  = has_king
		var base_suit = _get_base_suit(non_two)
		var all_wilds = jokers + normals.filter(func(c): return c.value == "2")

		var seq_cards = non_two
		seq_cards.sort_custom(func(a, b):
			return _get_num_flexible(a, ace_high) > _get_num_flexible(b, ace_high)
		)

		if all_wilds.is_empty() or seq_cards.size() < 2:
			ordered = seq_cards + all_wilds
		else:
			var best_gap_index = -1
			var best_gap_size  = 0
			for i in range(1, seq_cards.size()):
				var diff = _get_num_flexible(seq_cards[i-1], ace_high) - _get_num_flexible(seq_cards[i], ace_high)
				if diff >= 2 and diff > best_gap_size:
					best_gap_size  = diff
					best_gap_index = i

			if best_gap_index == -1:
				var min_val = _get_num_flexible(seq_cards.back(), ace_high)
				if min_val > 1:
					ordered = seq_cards + all_wilds
				else:
					ordered = all_wilds + seq_cards
			else:
				for i in range(seq_cards.size()):
					if i == best_gap_index:
						ordered.append_array(all_wilds)
					ordered.append(seq_cards[i])

	# move-to-end: única forma confiável no Godot para reordenar filhos
	for card in ordered:
		cards_holder.move_child(card, cards_holder.get_child_count() - 1)

func card_reposition(card: Card) -> void:
	if not card.is_joker and not card.is_wild:
		return_card_starting_position(card)
		return
	super.card_reposition(card)

func get_cards() -> Array:
	return $CardsHolder.get_children()
