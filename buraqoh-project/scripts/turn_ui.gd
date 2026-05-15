extends Control

@onready var turn_label:      Label  = $PanelContainer/VBoxContainer/TurnLabel
@onready var phase_label:     Label  = $PanelContainer/VBoxContainer/PhaseLabel
@onready var hp_label_j1:     Label  = $PanelContainer/VBoxContainer/ScoreJ1
@onready var hp_label_j2:     Label  = $PanelContainer/VBoxContainer/ScoreJ2
@onready var hand_count_j1:   Label  = $PanelContainer/VBoxContainer/HandPtsJ1
@onready var hand_count_j2:   Label  = $PanelContainer/VBoxContainer/HandPtsJ2
@onready var btn_descartar:   Button = $BtnDescartar
@onready var btn_buraco:      Button = $PanelContainer/VBoxContainer/BtnBuraco
@onready var btn_nova_rodada: Button = $PanelContainer/VBoxContainer/BtnNovaRodada
#@onready var opponent_count_label: Label = $PanelContainer/VBoxContainer/OpponentCount

var player_names: Array[String] = ["Jogador 1", "Jogador 2"]

func _ready() -> void:
	GameManager.turn_changed.connect(_on_turn_changed)
	GameManager.card_discarded.connect(_on_card_discarded)
	GameManager.buraco_cantado.connect(_on_buraco_cantado)
	GameManager.round_ended.connect(_on_round_ended)
	GameManager.game_ended.connect(_on_game_ended)
	GameManager.hp_changed.connect(_on_hp_changed)

	btn_descartar.pressed.connect(_on_descartar_pressed)
	btn_buraco.pressed.connect(_on_buraco_pressed)
	btn_nova_rodada.pressed.connect(_on_nova_rodada_pressed)

	btn_nova_rodada.visible = false
	_refresh_ui()

func _process(_delta: float) -> void:
	# Contagem de cartas na mão (atualiza em tempo real)
	hand_count_j1.text = "Mão %s: %d cartas" % [player_names[0], GameManager.get_hand_count(0)]
	hand_count_j2.text = "Mão %s: %d cartas" % [player_names[1], GameManager.get_hand_count(1)]

	btn_buraco.visible = GameManager.can_sing_buraco()

# ─────────────────────────────────────────────
#  ATUALIZAÇÃO VISUAL
# ─────────────────────────────────────────────
func _refresh_ui() -> void:
	var cp = GameManager.current_player
	turn_label.text  = "▶ Vez de: " + player_names[cp]
	phase_label.text = "Fase: " + GameManager.get_phase_name()
	_refresh_hp()
	btn_descartar.visible = GameManager.is_current_player_turn(GameManager.current_player)

func _refresh_hp() -> void:
	var hp0 = GameManager.get_hp(0)
	var hp1 = GameManager.get_hp(1)
	hp_label_j1.text = "%s: ❤ %d / %d" % [player_names[0], hp0, GameManager.MAX_HP]
	hp_label_j2.text = "%s: ❤ %d / %d" % [player_names[1], hp1, GameManager.MAX_HP]

# ─────────────────────────────────────────────
#  CALLBACKS DOS SINAIS
# ─────────────────────────────────────────────
func _on_turn_changed(_player_index: int) -> void:
	_refresh_ui()
	var tween = create_tween()
	tween.tween_property(turn_label, "modulate", Color.YELLOW, 0.15)
	tween.tween_property(turn_label, "modulate", Color.WHITE, 0.15)

func _on_card_discarded(_card: Card) -> void:
	_refresh_ui()

func _on_hp_changed(_player_index: int, _new_hp: int) -> void:
	_refresh_hp()

func _on_buraco_cantado(player_index: int) -> void:
	turn_label.text = "🎉 BURACO! " + player_names[player_index]
	_refresh_ui()

func _on_round_ended(winner_index: int) -> void:
	phase_label.text = "Fim de mão!"
	turn_label.text  = "🏆 " + player_names[winner_index] + " venceu a mão!"
	_refresh_hp()
	btn_nova_rodada.visible = true
	btn_descartar.visible   = false
	btn_buraco.visible      = false

func _on_game_ended(winner_index: int) -> void:
	turn_label.text  = "🏆 " + player_names[winner_index] + " VENCEU O JOGO!"
	phase_label.text = "Fim de jogo!"
	_refresh_hp()
	btn_nova_rodada.text    = "Novo Jogo"
	btn_nova_rodada.visible = true
	btn_descartar.visible   = false
	btn_buraco.visible      = false

# ─────────────────────────────────────────────
#  BOTÕES
# ─────────────────────────────────────────────
func _on_descartar_pressed() -> void:
	var sel = GameManager.selected_cards
	if sel.size() != 1:
		_flash_error("Selecione exatamente 1 carta para descartar!")
		return
	var ok = GameManager.discard_card(sel[0])
	if not ok:
		_flash_error("Não é possível descartar agora.")

func _on_buraco_pressed() -> void:
	var sel = GameManager.selected_cards
	if sel.size() != 1:
		if GameManager.hands.size() > GameManager.current_player:
			var hand = GameManager.hands[GameManager.current_player]
			var children = hand.get_node("CardsHolder").get_children()
			if children.size() == 1:
				GameManager.sing_buraco(children[0])
				return
		_flash_error("Selecione a carta para cantar buraco!")
		return
	GameManager.sing_buraco(sel[0])

func _on_nova_rodada_pressed() -> void:
	btn_nova_rodada.visible = false
	btn_descartar.visible   = true
	get_tree().reload_current_scene()

func _flash_error(msg: String) -> void:
	phase_label.text = "⚠ " + msg
	var tween = create_tween()
	tween.tween_property(phase_label, "modulate", Color.RED, 0.1)
	tween.tween_property(phase_label, "modulate", Color.WHITE, 0.4)
	await tween.finished
	_refresh_ui()
