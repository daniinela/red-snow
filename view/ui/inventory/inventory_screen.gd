# -------------------------------------------------------------
# INVENTORY SCREEN — Pantalla de inventario
# Muestra reliquias recogidas, slots de equipamiento y lore.
# Se abre con ESC y pausa el juego.
# -------------------------------------------------------------
extends CanvasLayer

@onready var relic_list: VBoxContainer = $Panel/HBox/Left/RelicList
@onready var lore_list: VBoxContainer = $Panel/HBox/Right/LoreList
@onready var slot1: Button = $Panel/HBox/Left/Slots/Slot1
@onready var slot2: Button = $Panel/HBox/Left/Slots/Slot2
@onready var slot3: Button = $Panel/HBox/Left/Slots/Slot3
@onready var description_label: Label = $Panel/HBox/Right/Description

var selected_relic: String = ""
var slot_buttons: Array = []

func _ready() -> void:
	slot_buttons = [slot1, slot2, slot3]
	slot1.pressed.connect(func(): _on_slot_pressed(0))
	slot2.pressed.connect(func(): _on_slot_pressed(1))
	slot3.pressed.connect(func(): _on_slot_pressed(2))
	EventBus.inventory_changed.connect(_refresh)
	visible = false

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		_toggle()

func _toggle() -> void:
	visible = not visible
	if visible:
		GameManager.change_state(GameManager.GameState.PAUSED)
		_refresh()
	else:
		GameManager.change_state(GameManager.GameState.PLAYING)

func _refresh() -> void:
	_refresh_relics()
	_refresh_slots()
	_refresh_lore()

func _refresh_relics() -> void:
	for child in relic_list.get_children():
		child.queue_free()
	for item_id in Inventory.relics:
		var item = Inventory.get_item(item_id)
		if not item:
			continue
		var btn = Button.new()
		var equipped = Inventory.is_relic_equipped(item_id)
		btn.text = item.name + (" [E]" if equipped else "")
		btn.pressed.connect(func(): _on_relic_selected(item_id))
		relic_list.add_child(btn)

func _refresh_slots() -> void:
	for i in Inventory.RELIC_SLOTS:
		var item_id = Inventory.equipped_relics[i]
		if item_id != "":
			var item = Inventory.get_item(item_id)
			slot_buttons[i].text = item.name if item else "?"
		else:
			slot_buttons[i].text = "[ vacío ]"

func _refresh_lore() -> void:
	for child in lore_list.get_children():
		child.queue_free()
	for item_id in Inventory.lore:
		var item = Inventory.get_item(item_id)
		if not item:
			continue
		var lbl = Label.new()
		lbl.text = item.name
		lbl.mouse_filter = Control.MOUSE_FILTER_STOP
		lbl.gui_input.connect(func(event): 
			if event is InputEventMouseButton and event.pressed:
				description_label.text = item.description
		)
		lore_list.add_child(lbl)

func _on_relic_selected(item_id: String) -> void:
	selected_relic = item_id
	var item = Inventory.get_item(item_id)
	if item:
		description_label.text = item.description
	# Si ya está equipada, la desequipa
	if Inventory.is_relic_equipped(item_id):
		for i in Inventory.RELIC_SLOTS:
			if Inventory.equipped_relics[i] == item_id:
				Inventory.unequip_relic(i)
				return
	# Si no, busca slot vacío
	for i in Inventory.RELIC_SLOTS:
		if Inventory.equipped_relics[i] == "":
			Inventory.equip_relic(item_id, i)
			return

func _on_slot_pressed(slot: int) -> void:
	Inventory.unequip_relic(slot)
