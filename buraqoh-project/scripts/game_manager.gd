extends Node
# ─────────────────────────────────────────────
#  SINAIS
# ─────────────────────────────────────────────
signal turn_changed(player_index: int)
signal card_discarded(card: Card)
signal buraco_cantado(player_index: int)
signal round_ended(winner_index: int)
signal game_ended(winner_index: int)
signal hp_changed(player_index: int, new_hp: int)

# ─────────────────────────────────────────────
#  ESTADO GERAL
# ─────────────────────────────────────────────
enum Phase { WAITING, DRAWING, PLAYING, DISCARDING, ROUND_OVER }

var current_player: int = 0
var phase: Phase = Phase.WAITING
var has_drawn_this_turn: bool = false
var has_played_this_turn: bool = false
var drew_from_discard: bool = false

var hands: Array = []
var deck_node: Node = null
var discard_pile: Node = null
var table_fields: Array = []
var selected_cards: Array[Card] = []

# ─────────────────────────────────────────────
#  VIDA
# ─────────────────────────────────────────────
const MAX_HP: int = 500
var player_hp: Array[int] = [MAX_HP, MAX_HP]

# ─────────────────────────────────────────────
#  PERSONAGENS
# ─────────────────────────────────────────────
var player_characters: Array[Dictionary] = [{}, {}]

# Controle de habilidades únicas (usam só uma vez por jogo)
var sobrevivente_usado: Array[bool] = [false, false]

func set_character(player_index: int, nome: String, dados: Dictionary) -> void:
	player_characters[player_index] = {
		"nome":        nome,
		"classe":      dados.get("classe", ""),
		"sprite":      dados.get("sprite", ""),
		"hp_mult":     dados.get("hp_mult", 1.0),
		"damage_mult": dados.get("damage_mult", 1.0),
	}

func get_classe(player_index: int) -> String:
	return player_characters[player_index].get("classe", "")

# ─────────────────────────────────────────────
#  DANO (com modificadores de classe)
# ─────────────────────────────────────────────
func apply_damage(target_player: int, amount: int) -> void:
	# Bloqueio do Valete de Paus
	if damage_blocked_this_turn:
		return

	var attacker = 1 - target_player
	var mult = player_characters[attacker].get("damage_mult", 1.0)
	
	# Dano dobrado do Rei de Espadas
	if damage_doubled_this_turn:
		mult *= 2.0

	amount = int(amount * mult)

	var new_hp = max(0, player_hp[target_player] - amount)
	if new_hp <= 0 and get_classe(target_player) == "Sobrevivente" and not sobrevivente_usado[target_player]:
		new_hp = 1
		sobrevivente_usado[target_player] = true

	player_hp[target_player] = new_hp
	hp_changed.emit(target_player, player_hp[target_player])

	if player_hp[target_player] <= 0:
		phase = Phase.ROUND_OVER
		game_ended.emit(1 - target_player)

func get_hp(player_index: int) -> int:
	return player_hp[player_index]

# ─────────────────────────────────────────────
#  DANO POR CARTAS NA MÃO (fim de turno)
# ─────────────────────────────────────────────
func _calcular_dano_mao(player_index: int) -> int:
	var count = get_hand_count(player_index)
	if count == 0:
		return 0
	var dano = count * 10
	if get_classe(player_index) == "Resistência":
		dano = int(dano * 0.70)  # 30% de redução (era 0.5 = 50%)
	return dano
# ─────────────────────────────────────────────
#  DANO DE CANASTRA (com modificador Mestre da Canastra)
# ─────────────────────────────────────────────
const DAMAGE_PER_CARD:      int = 10
const DAMAGE_CANASTRA_SUJA: int = 100
const DAMAGE_CANASTRA_LIMPA: int = 150

func calcular_dano_grupo(cards: Array) -> int:
	var total = cards.size()
	var attacker = current_player
	if total >= 7:
		var has_wild = cards.any(func(c): return c.is_joker or c.value == "2")
		if has_wild:
			return DAMAGE_CANASTRA_SUJA
		else:
			# Mestre da Canastra: canastra limpa causa dano extra
			var base = DAMAGE_CANASTRA_LIMPA
			if get_classe(attacker) == "Mestre da Canastra":
				base += 100
			return base
	return total * DAMAGE_PER_CARD

# ─────────────────────────────────────────────
#  HABILIDADE: CORAÇÃO DAS CARTAS
# ─────────────────────────────────────────────
var coracao_turno_ultimo_uso: Array[int] = [-99, -99]
const CORACAO_COOLDOWN_TURNOS: int = 4  # a cada 4 turnos do próprio jogador

var turno_count: Array[int] = [0, 0]  # conta turnos de cada jogador

func pode_usar_coracao() -> bool:
	if get_classe(current_player) != "Coração das Cartas":
		return false
	var ultimo = coracao_turno_ultimo_uso[current_player]
	return turno_count[current_player] - ultimo >= CORACAO_COOLDOWN_TURNOS

func usar_coracao(valor: String, naipe: String) -> bool:
	if not pode_usar_coracao():
		return false
	if deck_node == null:
		return false
	coracao_turno_ultimo_uso[current_player] = turno_count[current_player]
	deck_node.draw_specific_card_for(current_player, valor, naipe)
	return true

# ─────────────────────────────────────────────
#  INICIALIZAÇÃO DE RODADA
# ─────────────────────────────────────────────
func start_round(starting_player: int = 0) -> void:
	current_player = starting_player
	phase = Phase.DRAWING
	has_drawn_this_turn = false
	has_played_this_turn = false
	drew_from_discard = false
	selected_cards.clear()
	turno_count = [0, 0]

	# HP baseado no multiplicador da classe
	for i in range(2):
		var mult = player_characters[i].get("hp_mult", 1.0)
		player_hp[i] = int(MAX_HP * mult)

	hp_changed.emit(0, player_hp[0])
	hp_changed.emit(1, player_hp[1])
	turn_changed.emit(current_player)

# ─────────────────────────────────────────────
#  MESTRE DE PAUS: carta extra no início
# ─────────────────────────────────────────────
func aplicar_bonus_inicial() -> void:
	for i in range(2):
		if get_classe(i) == "Mestre de Paus":
			deck_node.draw_specific_card_for(i, "J", "Paus")

# ─────────────────────────────────────────────
#  COMPRA DE CARTA
# ─────────────────────────────────────────────
func draw_from_deck() -> bool:
	if phase != Phase.DRAWING:
		return false
	if has_drawn_this_turn:
		return false
	if deck_node == null:
		return false
	deck_node.draw_card_for(current_player)
	has_drawn_this_turn = true
	drew_from_discard = false
	phase = Phase.PLAYING
	return true

func draw_from_discard() -> bool:
	if phase != Phase.DRAWING:
		return false
	if has_drawn_this_turn:
		return false
	if discard_pile == null or discard_pile.is_empty():
		return false
	var hand = hands[current_player]
	while not discard_pile.is_empty():
		var card = discard_pile.take_top_card()
		if card == null:
			break
		card.reparent(hand.get_node("ScrollContainer/CardsHolder"))
		card.home_field = hand
	has_drawn_this_turn = true
	drew_from_discard = true
	phase = Phase.PLAYING
	return true

# ─────────────────────────────────────────────
#  SELEÇÃO DE CARTAS
# ─────────────────────────────────────────────
func register_selection(card: Card) -> void:
	if not _card_belongs_to_current_player(card):
		card.selected = false
		card.color_rect.color = Color.WEB_GREEN
		return
	if card.selected:
		selected_cards.append(card)
	else:
		selected_cards.erase(card)

func _card_belongs_to_current_player(card: Card) -> bool:
	if hands.is_empty():
		return true
	return card.home_field == hands[current_player]

func clear_selection() -> void:
	for card in selected_cards:
		card.selected = false
		card.color_rect.color = Color.WEB_GREEN
	selected_cards.clear()

# ─────────────────────────────────────────────
#  BAIXAR GRUPO NA MESA
# ─────────────────────────────────────────────
func try_play_group() -> bool:
	if phase != Phase.PLAYING:
		return false
	if selected_cards.size() < 3:
		return false
	if not _is_valid_group(selected_cards):
		return false
	return true

func confirm_play_group() -> void:
	has_played_this_turn = true
	clear_selection()

func get_current_table_field() -> Control:
	if table_fields.is_empty():
		return null
	return table_fields[current_player]

# ─────────────────────────────────────────────
#  DESCARTE
# ─────────────────────────────────────────────
func discard_card(card: Card) -> bool:
	if phase != Phase.PLAYING and phase != Phase.DISCARDING:
		return false
	if not _card_belongs_to_current_player(card):
		return false
	discard_pile.add_card(card)
	card_discarded.emit(card)
	clear_selection()
	var hand = hands[current_player]
	if hand.get_node("ScrollContainer/CardsHolder").get_child_count() == 0:
		_player_went_out()
		return true
	_end_turn()
	return true

# ─────────────────────────────────────────────
#  CANTAR BURACO
# ─────────────────────────────────────────────
func can_sing_buraco() -> bool:
	if phase != Phase.PLAYING:
		return false
	return hands[current_player].get_node("ScrollContainer/CardsHolder").get_child_count() == 1

func sing_buraco(card: Card) -> void:
	discard_pile.add_card(card)
	buraco_cantado.emit(current_player)
	_player_went_out()

# ─────────────────────────────────────────────
#  VALIDAÇÃO DE GRUPOS
# ─────────────────────────────────────────────
func _is_valid_group(cards: Array) -> bool:
	if cards.size() < 3:
		return false
	var wilds = cards.filter(func(c): return c.is_joker or c.value == "2")
	var fixed = cards.filter(func(c): return not c.is_joker and c.value != "2")
	if fixed.is_empty() or wilds.size() > 1:
		return false
	var base_value = fixed[0].value
	if fixed.all(func(c): return c.value == base_value):
		return true
	return _is_valid_sequence(fixed, wilds, false) or _is_valid_sequence(fixed, wilds, true)

func _is_valid_sequence(fixed: Array, jokers: Array, ace_high: bool) -> bool:
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

# ─────────────────────────────────────────────
#  FIM DE TURNO
# ─────────────────────────────────────────────
func _end_turn() -> void:
	var dano = _calcular_dano_mao(current_player)
	if dano > 0:
		apply_damage(current_player, dano)

	if phase == Phase.ROUND_OVER:
		return

	# Reseta efeitos especiais do turno
	damage_blocked_this_turn = false
	damage_doubled_this_turn = false

	turno_count[current_player] += 1
	has_drawn_this_turn = false
	has_played_this_turn = false
	drew_from_discard = false
	phase = Phase.DRAWING
	current_player = 1 - current_player
	clear_selection()
	turn_changed.emit(current_player)

# ─────────────────────────────────────────────
#  FIM DE MÃO
# ─────────────────────────────────────────────
func _player_went_out(_is_pure_buraco: bool = false) -> void:
	phase = Phase.ROUND_OVER
	round_ended.emit(current_player)

# ─────────────────────────────────────────────
#  HELPERS PÚBLICOS
# ─────────────────────────────────────────────
func get_phase_name() -> String:
	match phase:
		Phase.WAITING:    return "Aguardando"
		Phase.DRAWING:    return "Comprar"
		Phase.PLAYING:    return "Jogar"
		Phase.DISCARDING: return "Descartar"
		Phase.ROUND_OVER: return "Fim de mão"
	return "?"

func is_current_player_turn(player_index: int) -> bool:
	return player_index == current_player and phase != Phase.WAITING

func get_hand_count(player_index: int) -> int:
	if hands.is_empty() or hands.size() <= player_index:
		return 0
	return hands[player_index].get_node("ScrollContainer/CardsHolder").get_child_count()

func setup(p_hands: Array, p_deck: Node, p_discard: Node, p_tables: Array) -> void:
	hands       = p_hands
	deck_node   = p_deck
	discard_pile = p_discard
	table_fields = p_tables

func reset() -> void:
	player_hp              = [MAX_HP, MAX_HP]
	player_characters      = [{}, {}]
	sobrevivente_usado     = [false, false]
	coracao_turno_ultimo_uso = [-99, -99]
	turno_count            = [0, 0]
	current_player         = 0
	phase                  = Phase.WAITING
	has_drawn_this_turn    = false
	has_played_this_turn   = false
	drew_from_discard      = false
	selected_cards.clear()
	hands.clear()
	table_fields.clear()
	deck_node    = null
	discard_pile = null
	
# ─────────────────────────────────────────────
#  EFEITOS ESPECIAIS DE CARTAS
# ─────────────────────────────────────────────
signal special_effect_triggered(effect_name: String, description: String)

var damage_blocked_this_turn: bool = false
var damage_doubled_this_turn: bool = false

func check_special_cards(cards: Array, attacker: int) -> void:
	var opponent = 1 - attacker

	for card in cards:
		if card.value == "J" and card.suit == "Paus":
			_apply_block(attacker)
		elif card.value == "K" and card.suit == "Espadas":
			_apply_double_damage(attacker)
		elif card.value == "Q" and card.suit == "Copas":
			_apply_heal(attacker)
		elif card.value == "A" and card.suit == "Ouros":
			_apply_steal(attacker, opponent)

func _apply_block(player: int) -> void:
	damage_blocked_this_turn = true
	special_effect_triggered.emit(
		"Valete de Paus",
        "⚔ Dano bloqueado nesta rodada!"
	)

func _apply_double_damage(player: int) -> void:
	damage_doubled_this_turn = true
	special_effect_triggered.emit(
		"Rei de Espadas",
        "⚔ Dano dobrado nesta rodada!"
	)

func _apply_heal(player: int) -> void:
	var max_hp = int(MAX_HP * player_characters[player].get("hp_mult", 1.0))
	var heal = int(max_hp * 0.25)
	player_hp[player] = min(max_hp, player_hp[player] + heal)
	hp_changed.emit(player, player_hp[player])
	special_effect_triggered.emit(
		"Dama de Copas",
		"💚 Curou %d de vida!" % heal
	)

func _apply_steal(attacker: int, opponent: int) -> void:
	var opp_hand = hands[opponent].get_node("ScrollContainer/CardsHolder")
	var opp_cards = opp_hand.get_children()
	if opp_cards.is_empty():
		special_effect_triggered.emit(
			"Ás de Ouros",
            "🃏 Adversário sem cartas para roubar!"
		)
		return
	var stolen: Card = opp_cards[randi() % opp_cards.size()]
	var my_hand = hands[attacker].get_node("ScrollContainer/CardsHolder")
	stolen.reparent(my_hand)
	stolen.home_field = hands[attacker]
	special_effect_triggered.emit(
		"Ás de Ouros",
        "🃏 Roubou uma carta do adversário!"
	)
