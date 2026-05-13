# view/world/room_base.gd
# -------------------------------------------------------------
# ROOM BASE — Script base heredado por cada habitación
# Posiciona al jugador al entrar, ya sea por puerta o
# checkpoint. Configura los límites de la cámara según
# el TileMap más grande de la escena.
# -------------------------------------------------------------
extends Node2D
@export var limite_izquierda: int = 0
@export var limite_derecha: int = 1920
@export var limite_arriba: int = 0
@export var limite_abajo: int = 1080
@export var room_id: String = "room_01"

var _posicionado: bool = false

func _ready() -> void:
	print("ROOM BASE READY: ", room_id)
	await get_tree().process_frame
	await get_tree().process_frame
	if not _posicionado:
		_posicionado = true
		_posicionar_jugador()
	await get_tree().process_frame
	_setup_camera_limits()
	await get_tree().process_frame
	await get_tree().process_frame
	print("[RoomBase] room_id actual: ", room_id)
	print("[RoomBase] visited_rooms: ", GameManager.world_state.visited_rooms)
	if not GameManager.world_state.visited_rooms.has(room_id):
		print("[RoomBase] Emitiendo lore para: ", room_id)
		EventBus.lore_requested.emit(room_id)
	GameManager.world_state.visit_room(room_id)


func _setup_camera_limits() -> void:
	var cam = get_tree().get_first_node_in_group("camera")
	print("Camara encontrada: ", cam)
	if not cam:
		return
	print("Poniendo limites: ", limite_izquierda, limite_derecha, limite_arriba, limite_abajo)
	cam.limit_left = limite_izquierda
	cam.limit_right = limite_derecha
	cam.limit_top = limite_arriba
	cam.limit_bottom = limite_abajo


func _posicionar_jugador() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var last_door = GameManager.world_state.last_door_used
	if last_door != "":
		for door in get_tree().get_nodes_in_group("door"):
			if door.door_id == last_door:
				var spawn = door.get_node_or_null("SpawnPoint")
				var pos = spawn.global_position if spawn else door.global_position
				player.global_position = pos
				player.velocity = Vector2.ZERO
				player.set_meta("checkpoint_pos", pos)
				GameManager.world_state.last_door_used = ""
				print("[RoomBase] Spawn en puerta: ", door.door_id, " -> ", pos)
				return
	if player.has_meta("checkpoint_pos"):
		var pos = player.get_meta("checkpoint_pos")
		player.global_position = pos
		player.velocity = Vector2.ZERO
		print("[RoomBase] Spawn en checkpoint meta: ", pos)
		return
	# Partida cargada — lee checkpoint del save sin tocar world_state
	var slot = GameManager.current_slot
	if slot == 0:
		return
	var path = SaveSystem.get_save_path(slot)
	if not FileAccess.file_exists(path):
		return
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return
	var json = JSON.new()
	json.parse(file.get_as_text())
	file.close()
	var data = json.get_data()
	var pos_x = data.get("checkpoint_pos_x", 0.0)
	var pos_y = data.get("checkpoint_pos_y", 0.0)
	if pos_x != 0.0 or pos_y != 0.0:
		player.global_position = Vector2(pos_x, pos_y)
		player.velocity = Vector2.ZERO
		player.set_meta("checkpoint_pos", Vector2(pos_x, pos_y))
		print("[RoomBase] Spawn en checkpoint save: ", Vector2(pos_x, pos_y))
