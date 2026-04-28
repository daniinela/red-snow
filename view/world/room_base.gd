# -------------------------------------------------------------
# ROOM BASE — Script base de cada habitación
# Al cargar, posiciona al jugador en la puerta correcta
# según de dónde viene, o en el último checkpoint si
# está cargando una partida guardada.
# Escucha room_transition_requested para cambiar de escena.
# -------------------------------------------------------------
extends Node2D

@export var room_id: String = "room_01"

func _ready() -> void:
	EventBus.room_transition_requested.connect(_on_room_transition_requested)
	tree_exiting.connect(func(): 
		if EventBus.room_transition_requested.is_connected(_on_room_transition_requested):
			EventBus.room_transition_requested.disconnect(_on_room_transition_requested)
	)
	await get_tree().process_frame
	_posicionar_jugador()
	await get_tree().process_frame  # ← espera un frame más
	_setup_camera_limits()
	GameManager.world_state.visit_room(room_id)

func _setup_camera_limits() -> void:
	var cam = get_tree().get_first_node_in_group("camera")
	if not cam:
		return

	var tilemap = null
	var biggest_area := 0.0
	for tm in get_tree().get_nodes_in_group("tilemap"):
		var r = tm.get_used_rect()
		var area = r.size.x * r.size.y
		if area > biggest_area:
			biggest_area = area
			tilemap = tm

	if not tilemap:
		return

	var cell := Vector2i(tilemap.tile_set.tile_size)
	var rect: Rect2i = tilemap.get_used_rect()

	cam.limit_left   = rect.position.x * cell.x
	cam.limit_top    = rect.position.y * cell.y
	cam.limit_right  = rect.end.x      * cell.x
	cam.limit_bottom = rect.end.y      * cell.y

func _posicionar_jugador() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	var last_door = GameManager.world_state.last_door_used

	# Viene de una puerta: busca esa puerta en la escena y spawnea ahí
	if last_door != "":
		var doors = get_tree().get_nodes_in_group("door")
		for door in doors:
			if door.door_id == last_door:
				player.global_position = door.global_position
				player.set_meta("checkpoint_pos", door.global_position)
				GameManager.world_state.last_door_used = ""
				return

	# Carga desde save: usa el checkpoint guardado
	var slot = GameManager.current_slot
	if slot == 0:
		return
	var data = SaveSystem.load_slot(slot)
	if data.is_empty():
		return
	var pos_x = data.get("checkpoint_pos_x", 0.0)
	var pos_y = data.get("checkpoint_pos_y", 0.0)
	if pos_x != 0.0 or pos_y != 0.0:
		player.global_position = Vector2(pos_x, pos_y)
		player.set_meta("checkpoint_pos", Vector2(pos_x, pos_y))
		print("Jugador posicionado en checkpoint: ", Vector2(pos_x, pos_y))

func _on_room_transition_requested(target_room: String, _door_id: String) -> void:
	get_tree().change_scene_to_file.call_deferred("res://view/world/rooms/" + target_room + ".tscn")
