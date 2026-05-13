# view/menus/slots_select.gd
# -------------------------------------------------------------
# SLOTS SELECT — Pantalla de selección de slots de guardado
# Muestra los 3 slots disponibles con su información.
# Permite crear nueva partida, continuar o borrar.
# Navegación con arriba/abajo y E para seleccionar.
# -------------------------------------------------------------
extends CanvasLayer

@onready var slot1: Button = $VBoxContainer/HBoxContainer/Slot1
@onready var slot2: Button = $VBoxContainer/HBoxContainer2/Slot2
@onready var slot3: Button = $VBoxContainer/HBoxContainer3/Slot3
@onready var borrar1: Button = $VBoxContainer/HBoxContainer/Borrar1
@onready var borrar2: Button = $VBoxContainer/HBoxContainer2/Borrar2
@onready var borrar3: Button = $VBoxContainer/HBoxContainer3/Slot3

var slots_visibles: Array = []
var indice: int = 0

func _ready() -> void:
	_actualizar_slots()
	slot1.pressed.connect(func(): _seleccionar_slot(1))
	slot2.pressed.connect(func(): _seleccionar_slot(2))
	slot3.pressed.connect(func(): _seleccionar_slot(3))
	borrar1.pressed.connect(func(): _borrar_slot(1))
	borrar2.pressed.connect(func(): _borrar_slot(2))
	borrar3.pressed.connect(func(): _borrar_slot(3))
	_actualizar_foco()

func _actualizar_slots() -> void:
	slots_visibles.clear()
	_actualizar_boton(slot1, borrar1, 1)
	_actualizar_boton(slot2, borrar2, 2)
	_actualizar_boton(slot3, borrar3, 3)
	if slot1.visible:
		slots_visibles.append(slot1)
	if slot2.visible:
		slots_visibles.append(slot2)
	if slot3.visible:
		slots_visibles.append(slot3)
	indice = 0

func _actualizar_boton(boton: Button, borrar: Button, slot: int) -> void:
	var existe = SaveSystem.slot_exists(slot)
	if GameManager.nueva_partida_mode:
		if existe:
			boton.visible = false
			borrar.visible = false
		else:
			boton.visible = true
			boton.text = "PARTIDA " + str(slot)
			borrar.visible = false
	else:
		if existe:
			var info = SaveSystem.get_slot_info(slot)
			var nombre = info.get("nombre", "Partida " + str(slot))
			boton.visible = true
			boton.text = nombre
			borrar.visible = true
		else:
			boton.visible = false
			borrar.visible = false

func _actualizar_foco() -> void:
	if slots_visibles.is_empty():
		return
	slots_visibles[indice].grab_focus()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_down"):
		indice = (indice + 1) % slots_visibles.size()
		_actualizar_foco()
	if Input.is_action_just_pressed("ui_up"):
		indice = (indice - 1 + slots_visibles.size()) % slots_visibles.size()
		_actualizar_foco()
	if Input.is_action_just_pressed("interact"):
		if not slots_visibles.is_empty():
			slots_visibles[indice].emit_signal("pressed")

func _seleccionar_slot(slot: int) -> void:
	GameManager.current_slot = slot
	if GameManager.nueva_partida_mode:
		_nueva_partida(slot)
	else:
		_cargar_partida(slot)

func _nueva_partida(slot: int) -> void:
	SaveSystem.save_nuevo(slot, "Partida " + str(slot))
	GameManager.nueva_partida_mode = true
	GameManager.change_state(GameManager.GameState.PLAYING)
	GameManager.world_state.current_room = "Bosque/bosque02"
	get_tree().change_scene_to_file("res://view/world/game_world.tscn")

func _cargar_partida(slot: int) -> void:
	SaveSystem.load_slot(slot)
	GameManager.change_state(GameManager.GameState.PLAYING)
	get_tree().change_scene_to_file("res://view/world/game_world.tscn")

func _borrar_slot(slot: int) -> void:
	SaveSystem.delete_slot(slot)
	_actualizar_slots()
