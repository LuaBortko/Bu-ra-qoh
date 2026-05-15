extends Control

@onready var groups_container = $ScrollContainer/GridContainer
@export var owner_player: int = 0

const DAMAGE_PER_CARD: int = 10
const DAMAGE_CANASTRA_SUJA: int = 100
const DAMAGE_CANASTRA_LIMPA: int = 150
const CANASTRA_MIN_CARDS: int = 7

func create_group(cards: Array[Card]) -> void:
	if GameManager.current_player != owner_player:
		for card in cards:
			card.home_field.return_card_starting_position(card)
		GameManager.clear_selection()
		return

	var free_group = _get_free_group()
	if free_group == null:
		for card in cards:
			card.home_field.return_card_starting_position(card)
		GameManager.clear_selection()
		return

	var normals = cards.filter(func(c): return not c.is_joker and not c.is_wild)
	var wilds   = cards.filter(func(c): return c.is_joker or c.is_wild)
	normals.sort_custom(func(a, b): return a.get_num_value() > b.get_num_value())
	var ordered = normals + wilds

	for card in ordered:
		card.reparent(free_group.get_node("CardsHolder"))
		card.home_field = free_group

	free_group.occupy()

	# ← Verifica efeitos especiais ANTES de calcular dano
	GameManager.check_special_cards(ordered, GameManager.current_player)

	var damage = GameManager.calcular_dano_grupo(ordered)
	var opponent = 1 - GameManager.current_player
	GameManager.apply_damage(opponent, damage)
	GameManager.confirm_play_group()

func _get_free_group() -> GroupField:
	for group in groups_container.get_children():
		if group is GroupField and not group.is_occupied:
			return group
	return null

func _calculate_damage(cards: Array) -> int:
	var total = cards.size()
	if total >= CANASTRA_MIN_CARDS:
		var has_wild = cards.any(func(c): return c.is_joker or c.is_wild)
		if has_wild:
			return DAMAGE_CANASTRA_SUJA
		else:
			return DAMAGE_CANASTRA_LIMPA
	return total * DAMAGE_PER_CARD

func get_group_at(position: Vector2) -> GroupField:
	for group in groups_container.get_children():
		# Só retorna grupos ocupados — vazios são invisíveis para o drop
		if group is GroupField and group.is_occupied:
			if group.get_global_rect().has_point(position):
				return group
	return null

func can_interact() -> bool:
	return GameManager.current_player == owner_player and GameManager.phase == GameManager.Phase.PLAYING
