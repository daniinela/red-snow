# controller/game_world_controller.gd
# -------------------------------------------------------------
# GAME WORLD CONTROLLER — Controlador principal del mundo
# Mantiene al jugador persistente entre habitaciones.
# Carga y descarga rooms dinámicamente con fade de transición.
# -------------------------------------------------------------
extends Node

@onready var room_container: Node = $RoomContainer
@onready var fade: ColorRect = $CanvasLayer/Fade

var current_room_node: Node = null

func _ready() -> void:
	EventBus.room_transition_requested.connect(_on_transition_requested)
	fade.color = Color(0, 0, 0, 1)
	await get_tree().process_frame
	_load_initial_room()

func _load_initial_room() -> void:
	var room_id = GameManager.world_state.current_room
	print("[GameWorld] Cargando sala inicial: ", room_id)
	var room_path = _get_room_path(room_id)
	_load_room(room_path)
	await get_tree().process_frame
	await get_tree().process_frame
	# Nueva partida — posiciona en StartPoint
	if GameManager.nueva_partida_mode:
		var start = current_room_node.get_node_or_null("StartPoint")
		if start:
			var player = get_tree().get_first_node_in_group("player")
			if player:
				player.global_position = start.global_position
				player.velocity = Vector2.ZERO
	await _fade_to_clear()

func _on_transition_requested(target_room: String, _door_id: String) -> void:
	print("[GameWorld] Transicion solicitada a: ", target_room)
	await _fade_to_black()
	_load_room(_get_room_path(target_room))
	await get_tree().process_frame
	await get_tree().process_frame
	await _fade_to_clear()


func _load_room(path: String) -> void:
	if current_room_node:
		current_room_node.queue_free()
		await get_tree().process_frame
	var packed = load(path)
	if not packed:
		push_error("[GameWorld] No se pudo cargar: " + path)
		return
	current_room_node = packed.instantiate()
	room_container.add_child(current_room_node)

func _get_room_path(room_id: String) -> String:
	var map := {
		"Bosque/bosque02": "res://view/world/rooms/Bosque/bosque02.tscn",
		"Puente/PuenteSanPetersburgo": "res://view/world/rooms/Puente/PuenteSanPetersburgo.tscn",
		"Castillo/Castillo_Boss": "res://view/world/rooms/Castillo/Castillo_Boss.tscn",
		"CuartelesMilitares/Militar_room01": "res://view/world/rooms/CuartelesMilitares/Militar_room01.tscn",
		"puerta/Puerta01": "res://view/world/rooms/puerta/Puerta01.tscn",
		"room_01": "res://view/world/rooms/room_01.tscn",
		"room_02": "res://view/world/rooms/room_02.tscn",
	}
	if not map.has(room_id):
		push_error("[GameWorld] room_id no encontrado en mapa: " + room_id)
	return map.get(room_id, "res://view/world/rooms/Bosque/bosque02.tscn")

func _fade_to_black() -> void:
	var tw = create_tween()
	tw.tween_property(fade, "color", Color(0, 0, 0, 1), 0.3)
	await tw.finished

func _fade_to_clear() -> void:
	var tw = create_tween()
	tw.tween_property(fade, "color", Color(0, 0, 0, 0), 0.3)
	await tw.finished
