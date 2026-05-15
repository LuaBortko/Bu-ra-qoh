extends PanelContainer

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var desc_label: Label  = $VBoxContainer/DescLabel

const SHOW_DURATION := 3.0

func show_effect(effect_name: String, description: String) -> void:
	title_label.text = effect_name
	desc_label.text  = description
	visible = true
	# Esconde automaticamente após 3 segundos
	await get_tree().create_timer(SHOW_DURATION).timeout
	visible = false
