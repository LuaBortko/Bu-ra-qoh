extends Node2D
@onready var anim_player = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	DialogueManager.show_dialogue_balloon(load("res://Dialogo/FlavinhaMarquise2.dialogue"),"start")
	DialogueManager.dialogue_ended.connect(_on_cutscene_finished)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func audioCorna() -> void:
	$AudioStreamPlayer2D.play()

func suicidio() -> void:
	anim_player.play("FlavinhaSeJogando")
	await anim_player.animation_finished

func _on_cutscene_finished(_resource) -> void:
	if DialogueManager.dialogue_ended.is_connected(_on_cutscene_finished):
		DialogueManager.dialogue_ended.disconnect(_on_cutscene_finished)
	get_tree().change_scene_to_file("res://scenes/vitoria_final.tscn")
