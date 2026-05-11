# autoloads/save_system.gd
# -------------------------------------------------------------
# SAVE SYSTEM — Sistema de guardado con 3 slots
# Cada slot es un archivo independiente en disco.
# Guarda HP, posición, habitación actual y tiempo jugado.
# -------------------------------------------------------------
extends Node

const SAVE_DIR := "user://saves/"
const SLOT_COUNT := 3

func _ready() -> void:
	DirAccess.make_dir_absolute(SAVE_DIR)

func get_save_path(slot: int) -> String:
	return SAVE_DIR + "slot_" + str(slot) + ".json"

func save(slot: int) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player or not player.get("data"):
		return
	var nombre = "Partida " + str(slot)
	if slot_exists(slot):
		var path = get_save_path(slot)
		var file_read = FileAccess.open(path, FileAccess.READ)
		if file_read:
			var content = file_read.get_as_text()
			file_read.close()
			var json = JSON.new()
			json.parse(content)
			var data_existente = json.get_data()
			nombre = data_existente.get("nombre", nombre)
	var data := {
		"nombre": nombre,
		"hp_current": player.data.hp_current,
		"hp_max": player.data.hp_max,
		"checkpoint_pos_x": 0.0,
		"checkpoint_pos_y": 0.0,
		"tiempo_guardado": Time.get_datetime_string_from_system(),
		"world_state": GameManager.world_state.to_dict(),
		"inventory": Inventory.to_dict(),
		"flask_max": player.data.flask_max,
		"flask_current": player.data.flask_max,
		"monedas": player.data.monedas,
		"ataque_habilitado": player.ataque_habilitado,
		"dash_habilitado": player.dash_habilitado,
	}
	if player.has_meta("checkpoint_pos"):
		var pos = player.get_meta("checkpoint_pos")
		data["checkpoint_pos_x"] = pos.x
		data["checkpoint_pos_y"] = pos.y
	var file = FileAccess.open(get_save_path(slot), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
		print("[SaveSystem] Slot ", slot, " guardado.")

func _read_slot_raw(slot: int) -> Dictionary:
	# Lee el archivo sin tocar el GameManager ni el Inventory
	var path = get_save_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var content = file.get_as_text()
	file.close()
	var json = JSON.new()
	json.parse(content)
	return json.get_data()

func load_slot(slot: int) -> Dictionary:
	var data = _read_slot_raw(slot)
	if data.is_empty():
		return {}
	if data.has("world_state"):
		GameManager.world_state.from_dict(data["world_state"])
	if data.has("inventory"):
		Inventory.from_dict(data["inventory"])
	return data

func apply_save_to_player(data: Dictionary) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	if data.has("hp_current"):
		player.data.hp_current = int(data["hp_current"])
		player.data.hp_max = int(data.get("hp_max", player.data.hp_max))
		EventBus.player_healed.emit(player.data.hp_current, player.data.hp_current)
	if data.has("flask_max"):
		player.data.flask_max = int(data["flask_max"])
		player.data.flask_current = int(data.get("flask_current", data["flask_max"]))
		EventBus.player_flask_changed.emit(player.data.flask_current, player.data.flask_max)
	if data.has("monedas"):
		player.data.monedas = int(data["monedas"])
		EventBus.monedas_changed.emit(player.data.monedas)
	if data.has("ataque_habilitado"):
		player.ataque_habilitado = data["ataque_habilitado"]
	if data.has("dash_habilitado"):
		player.dash_habilitado = data["dash_habilitado"]

func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(get_save_path(slot))

func delete_slot(slot: int) -> void:
	var path = get_save_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		print("[SaveSystem] Slot ", slot, " eliminado.")

func get_slot_info(slot: int) -> Dictionary:
	if not slot_exists(slot):
		return {"vacio": true}
	# Usa _read_slot_raw para NO contaminar el GameManager
	var data = _read_slot_raw(slot)
	data["vacio"] = false
	return data

func save_nuevo(slot: int, nombre: String) -> void:
	var data := {
		"nombre": nombre,
		"hp_current": 100,
		"hp_max": 100,
		"checkpoint_pos_x": 0.0,
		"checkpoint_pos_y": 0.0,
		"tiempo_guardado": Time.get_datetime_string_from_system()
	}
	var file = FileAccess.open(get_save_path(slot), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
		print("[SaveSystem] Nueva partida en slot ", slot, " con nombre: ", nombre)
