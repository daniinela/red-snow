# autoloads/game_manager.gd
# -------------------------------------------------------------
# GAME MANAGER — Estado global del juego
# Controla en qué estado está el juego y las transiciones
# entre escenas. Accesible desde cualquier script con
# GameManager.change_state(...)
# -------------------------------------------------------------
extends Node

enum GameState { MENU, PLAYING, PAUSED, DEAD }

#var current_state: GameState = GameState.MENU
var current_state: GameState = GameState.PLAYING
var current_slot: int = 0
var nueva_partida_mode: bool = false
var world_state: WorldState = WorldState.new()

func _ready() -> void:
	# Escucha cuando el jugador muere para cambiar estado
	EventBus.player_died.connect(_on_player_died)

func change_state(new_state: GameState) -> void:
	current_state = new_state
	print("[GameManager] Estado: ", GameState.keys()[new_state])

func _on_player_died() -> void:
	change_state(GameState.DEAD)

func is_playing() -> bool:
	# Útil para saber si procesar input o física
	return current_state == GameState.PLAYING

func change_room(target_room: String, door_id: String) -> void:
	world_state.last_door_used = door_id
	world_state.visit_room(target_room)
	EventBus.room_transition_requested.emit(target_room, door_id)
