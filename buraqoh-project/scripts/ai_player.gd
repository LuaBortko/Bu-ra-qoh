extends Node

const TURN_DELAY := 1.5  # segundos entre ações da IA

var hand_field: Field
var table_field: Control
var ai_player_index: int = 1

func setup(hand: Field, table: Control, player_index: int) -> void:
	hand_field = hand
	table_field = table
	ai_player_index = player_index

func play_turn() -> void:
	await get_tree().create_timer(TURN_DELAY).timeout
	_comprar()
	await get_tree().create_timer(TURN_DELAY).timeout
	_tentar_baixar()
	await get_tree().create_timer(TURN_DELAY).timeout
	_descartar()

func _comprar() -> void:
	# IA sempre compra do deck
	GameManager.draw_from_deck()

func _tentar_baixar() -> void:
	var cartas = _get_hand_cards()
	# Tenta todas as combinações de 3+ cartas
	for tamanho in [7, 6, 5, 4, 3]:
		var combo = _achar_combo_valido(cartas, tamanho)
		if combo.size() >= 3:
			# Seleciona as cartas no GameManager
			for card in combo:
				card.selected = true
				GameManager.register_selection(card)
			# Baixa o grupo
			if GameManager.try_play_group():
				table_field.create_group(GameManager.selected_cards.duplicate())
			else:
				GameManager.clear_selection()
			return
	GameManager.clear_selection()

func _achar_combo_valido(cartas: Array, tamanho: int) -> Array:
	# Testa combinações simples — mesmo valor (coqueiro)
	var grupos = {}
	for c in cartas:
		var k = c.value
		if not grupos.has(k):
			grupos[k] = []
		grupos[k].append(c)
	for k in grupos:
		if grupos[k].size() >= tamanho:
			return grupos[k].slice(0, tamanho)

	# Testa sequências por naipe
	var por_naipe = {}
	for c in cartas:
		if c.is_joker or c.value == "2":
			continue
		var k = c.suit
		if not por_naipe.has(k):
			por_naipe[k] = []
		por_naipe[k].append(c)

	for naipe in por_naipe:
		var seq = por_naipe[naipe]
		seq.sort_custom(func(a, b): return a.get_num_value() < b.get_num_value())
		var resultado = _maior_sequencia(seq)
		if resultado.size() >= tamanho:
			return resultado.slice(0, tamanho)

	return []

func _maior_sequencia(cartas_ordenadas: Array) -> Array:
	if cartas_ordenadas.is_empty():
		return []
	var melhor: Array = [cartas_ordenadas[0]]
	var atual: Array  = [cartas_ordenadas[0]]
	for i in range(1, cartas_ordenadas.size()):
		var diff = cartas_ordenadas[i].get_num_value() - cartas_ordenadas[i-1].get_num_value()
		if diff == 1:
			atual.append(cartas_ordenadas[i])
			if atual.size() > melhor.size():
				melhor = atual.duplicate()
		else:
			atual = [cartas_ordenadas[i]]
	return melhor

func _descartar() -> void:
	var cartas = _get_hand_cards()
	if cartas.is_empty():
		return
	# Descarta uma carta aleatória
	var carta = cartas[randi() % cartas.size()]
	GameManager.discard_card(carta)

func _get_hand_cards() -> Array:
	return hand_field.get_node("ScrollContainer/CardsHolder").get_children()
