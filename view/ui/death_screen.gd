# view/ui/death_screen.gd
# -------------------------------------------------------------
# DEATH SCREEN — Pantalla de muerte
# Se muestra cuando el jugador muere.
# Espera unos segundos y reaparece en el último checkpoint.
# -------------------------------------------------------------
extends CanvasLayer

func _ready() -> void:
	EventBus.player_died.connect(_on_player_died)
	visible = false

func _on_player_died() -> void:
	visible = true
	GameManager.change_state(GameManager.GameState.DEAD)
	await get_tree().create_timer(2.0).timeout
	_respawn()

func _respawn() -> void:
	var data = SaveSystem.load_slot(GameManager.current_slot)
	if not data.is_empty():
		if data.has("world_state"):
			GameManager.world_state.from_dict(data["world_state"])
		SaveSystem.apply_save_to_player(data)
	GameManager.change_state(GameManager.GameState.PLAYING)
	visible = false
	get_tree().change_scene_to_file("res://view/world/game_world.tscn")
