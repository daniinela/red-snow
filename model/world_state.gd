# -------------------------------------------------------------
# WORLD STATE — Estado persistente del mundo
# Guarda rooms visitadas, puertas abiertas y enemigos
# derrotados permanentemente (bosses e items).
# Los enemigos normales NO se guardan aquí — respawnean solos.
# -------------------------------------------------------------
class_name WorldState
extends Resource

@export var current_room: String = "room_01"
@export var last_door_used: String = ""
@export var visited_rooms: Array[String] = []
@export var opened_doors: Array[String] = []
@export var defeated_enemies: Array[String] = []

func visit_room(room_id: String) -> void:
	if room_id not in visited_rooms:
		visited_rooms.append(room_id)
	current_room = room_id

func open_door(door_id: String) -> void:
	if door_id not in opened_doors:
		opened_doors.append(door_id)
		EventBus.door_opened.emit(door_id)

func is_door_open(door_id: String) -> bool:
	return door_id in opened_doors

func defeat_enemy(enemy_id: String) -> void:
	if enemy_id not in defeated_enemies:
		defeated_enemies.append(enemy_id)

func is_enemy_defeated(enemy_id: String) -> bool:
	return enemy_id in defeated_enemies

func to_dict() -> Dictionary:
	return {
		"current_room": current_room,
		"last_door_used": last_door_used,
		"visited_rooms": visited_rooms,
		"opened_doors": opened_doors,
		"defeated_enemies": defeated_enemies
	}

func from_dict(d: Dictionary) -> void:
	current_room = d.get("current_room", "room_01")
	last_door_used = d.get("last_door_used", "")
	visited_rooms.clear()
	for r in d.get("visited_rooms", []):
		visited_rooms.append(str(r))
	opened_doors.clear()
	for o in d.get("opened_doors", []):
		opened_doors.append(str(o))
	defeated_enemies.clear()
	for e in d.get("defeated_enemies", []):
		defeated_enemies.append(str(e))
