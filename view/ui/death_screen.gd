# view/ui/death_screen.gd
# -------------------------------------------------------------
# DEATH SCREEN — Pantalla de muerte
# Se muestra cuando el jugador muere.
# Espera unos segundos y reaparece en el último spawn.
# -------------------------------------------------------------
extends CanvasLayer

func _ready() -> void:
	# Escucha la señal de muerte del jugador
	EventBus.player_died.connect(_on_player_died)
	# Empieza invisible
	visible = false

func _on_player_died() -> void:
	visible = true
	GameManager.change_state(GameManager.GameState.DEAD)
	# Espera 2 segundos y respawnea
	await get_tree().create_timer(2.0).timeout
	_respawn()

func _respawn() -> void:
	var data = SaveSystem.load_slot(GameManager.current_slot)
	var target_room: String = ""
	if not data.is_empty():
		target_room = data.get("world_state", {}).get("current_room", "")
	if target_room == "":
		target_room = GameManager.world_state.current_room
	SaveSystem.apply_save_to_player(data)
	GameManager.change_state(GameManager.GameState.PLAYING)
	visible = false
	get_tree().change_scene_to_file("res://view/world/rooms/" + target_room + ".tscn")
