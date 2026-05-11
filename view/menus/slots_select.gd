# view/menus/slots_select.gd
# -------------------------------------------------------------
# SLOTS SELECT — Pantalla de selección de slots de guardado
# Muestra los 3 slots disponibles con su información.
# Permite crear nueva partida, continuar o borrar.
# -------------------------------------------------------------
extends CanvasLayer

@onready var slot1: Button = $VBoxContainer/HBoxContainer/Slot1
@onready var slot2: Button = $VBoxContainer/HBoxContainer2/Slot2
@onready var slot3: Button = $VBoxContainer/HBoxContainer3/Slot3
@onready var borrar1: Button = $VBoxContainer/HBoxContainer/Borrar1
@onready var borrar2: Button = $VBoxContainer/HBoxContainer2/Borrar2
@onready var borrar3: Button = $VBoxContainer/HBoxContainer3/Borrar3

func _ready() -> void:
	_actualizar_slots()
	slot1.pressed.connect(func(): _seleccionar_slot(1))
	slot2.pressed.connect(func(): _seleccionar_slot(2))
	slot3.pressed.connect(func(): _seleccionar_slot(3))
	borrar1.pressed.connect(func(): _borrar_slot(1))
	borrar2.pressed.connect(func(): _borrar_slot(2))
	borrar3.pressed.connect(func(): _borrar_slot(3))

func _actualizar_slots() -> void:
	_actualizar_boton(slot1, borrar1, 1)
	_actualizar_boton(slot2, borrar2, 2)
	_actualizar_boton(slot3, borrar3, 3)

func _actualizar_boton(boton: Button, borrar: Button, slot: int) -> void:
	var existe = SaveSystem.slot_exists(slot)
	if GameManager.nueva_partida_mode:
		if existe:
			boton.visible = false
			borrar.visible = false
		else:
			boton.visible = true
			boton.text = "[ VACÍO ]"
			borrar.visible = false
	else:
		if existe:
			var info = SaveSystem.get_slot_info(slot)
			var nombre = info.get("nombre", "Partida " + str(slot))
			var fecha = info.get("tiempo_guardado", "")
			boton.visible = true
			boton.text = nombre + "\n" + fecha
			borrar.visible = true
		else:
			boton.visible = false
			borrar.visible = false

func _seleccionar_slot(slot: int) -> void:
	GameManager.current_slot = slot
	if GameManager.nueva_partida_mode:
		_pedir_nombre(slot)
	else:
		_cargar_partida(slot)

func _pedir_nombre(slot: int) -> void:
	GameManager.current_slot = slot
	get_tree().change_scene_to_file("res://view/menus/nombre_partida.tscn")

func _cargar_partida(slot: int) -> void:
	var data = SaveSystem.load_slot(slot)
	GameManager.change_state(GameManager.GameState.PLAYING)
	get_tree().change_scene_to_file("res://view/world/game_world.tscn")

func _borrar_slot(slot: int) -> void:
	SaveSystem.delete_slot(slot)
	_actualizar_slots()
