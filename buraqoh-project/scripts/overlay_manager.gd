extends Node

var overlay_scene: PackedScene = preload("res://scenes/overlay.tscn")
var current_overlay: ColorRect = null

func show_overlay(title: String, message: String, on_click: Callable = Callable()) -> void:
	# Remove overlay existente se houver
	if current_overlay and is_instance_valid(current_overlay):
		current_overlay.queue_free()
	
	# Cria novo overlay
	current_overlay = overlay_scene.instantiate()
	current_overlay.setup(title, message, on_click)
	get_tree().root.add_child(current_overlay)
	
	# Garante que fique em cima de tudo
	current_overlay.z_index = 100

func hide_overlay() -> void:
	if current_overlay and is_instance_valid(current_overlay):
		current_overlay.queue_free()
		current_overlay = null
