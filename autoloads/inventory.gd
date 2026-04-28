# -------------------------------------------------------------
# INVENTORY — Autoload que gestiona el inventario del jugador
# Reliquias: se recogen y se equipan en slots (max 3 activas)
# Lore: se recogen y se ven en inventario
# Consumibles: se manejan desde player_controller con tecla
# -------------------------------------------------------------
extends Node

const RELIC_SLOTS: int = 3

var relics: Array[String] = []
var lore: Array[String] = []
var equipped_relics: Array[String] = ["", "", ""]

var _catalog: Dictionary = {}

func _ready() -> void:
	_load_catalog()

func _load_catalog() -> void:
	var dir = DirAccess.open("res://data/items/")
	if not dir:
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres") or file_name.ends_with(".res"):
			var item = load("res://data/items/" + file_name) as ItemData
			if item:
				_catalog[item.id] = item
		file_name = dir.get_next()

func get_item(item_id: String) -> ItemData:
	return _catalog.get(item_id, null)

func has_item(item_id: String) -> bool:
	return item_id in relics or item_id in lore

func collect(item_id: String) -> void:
	var item = get_item(item_id)
	if not item:
		push_error("Item no encontrado en catálogo: " + item_id)
		return
	match item.type:
		ItemData.Type.RELIC:
			if item_id not in relics:
				relics.append(item_id)
		ItemData.Type.CONSUMABLE:
			var player = get_tree().get_first_node_in_group("player")
			if not player:
				return
			player.data.flask_max += 1
			player.data.flask_current = player.data.flask_max
			EventBus.player_flask_changed.emit(player.data.flask_current, player.data.flask_max)
		ItemData.Type.LORE:
			if item_id not in lore:
				lore.append(item_id)
	EventBus.item_collected.emit(item_id)
	EventBus.inventory_changed.emit()

func equip_relic(item_id: String, slot: int) -> void:
	if slot < 0 or slot >= RELIC_SLOTS:
		return
	if item_id not in relics:
		return
	# Desequipa lo que había en ese slot
	var old_id = equipped_relics[slot]
	if old_id != "":
		_remove_relic_effect(get_item(old_id))
	# Si la reliquia ya está equipada en otro slot, la quita de allí
	for i in RELIC_SLOTS:
		if equipped_relics[i] == item_id and i != slot:
			equipped_relics[i] = ""
			break
	equipped_relics[slot] = item_id
	_apply_relic_effect(get_item(item_id))
	EventBus.inventory_changed.emit()

func unequip_relic(slot: int) -> void:
	if slot < 0 or slot >= RELIC_SLOTS:
		return
	var item_id = equipped_relics[slot]
	if item_id == "":
		return
	_remove_relic_effect(get_item(item_id))
	equipped_relics[slot] = ""
	EventBus.inventory_changed.emit()

func is_relic_equipped(item_id: String) -> bool:
	return item_id in equipped_relics

func _apply_relic_effect(item: ItemData) -> void:
	if not item:
		return
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	player.data.hp_max += item.hp_max_bonus
	player.data.hp_current += item.hp_max_bonus
	player.data.attack_damage += item.attack_bonus
	player.data.stamina_max += item.stamina_max_bonus
	player.data.move_speed += item.move_speed_bonus

func _remove_relic_effect(item: ItemData) -> void:
	if not item:
		return
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	player.data.hp_max -= item.hp_max_bonus
	player.data.hp_current = min(player.data.hp_current, player.data.hp_max)
	player.data.attack_damage -= item.attack_bonus
	player.data.stamina_max -= item.stamina_max_bonus
	player.data.move_speed -= item.move_speed_bonus

func to_dict() -> Dictionary:
	return {
		"relics": relics,
		"lore": lore,
		"equipped_relics": equipped_relics
	}

func from_dict(d: Dictionary) -> void:
	relics.clear()
	lore.clear()
	for r in d.get("relics", []):
		relics.append(str(r))
	for l in d.get("lore", []):
		lore.append(str(l))
	equipped_relics = ["", "", ""]
	var eq = d.get("equipped_relics", [])
	for i in min(eq.size(), RELIC_SLOTS):
		equipped_relics[i] = str(eq[i])
	# Reaplicar efectos de reliquias equipadas al cargar
	for item_id in equipped_relics:
		if item_id != "":
			_apply_relic_effect(get_item(item_id))
