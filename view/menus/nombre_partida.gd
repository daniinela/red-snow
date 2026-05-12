# view/menus/nombre_partida.gd
# -------------------------------------------------------------
# NOMBRE PARTIDA — Pantalla para nombrar una nueva partida
# El jugador escribe el nombre antes de empezar.
# -------------------------------------------------------------
extends CanvasLayer

@onready var nombre_input: LineEdit = $PanelContainer/VBoxContainer/NombreInput
@onready var confirmar: Button = $PanelContainer/VBoxContainer/HBoxContainer/Confirmar
@onready var cancelar: Button = $PanelContainer/VBoxContainer/HBoxContainer/Cancelar

var slot: int = 0

func _ready() -> void:
	# Lee el slot desde GameManager
	slot = GameManager.current_slot
	confirmar.pressed.connect(_on_confirmar)
	cancelar.pressed.connect(_on_cancelar)
	nombre_input.grab_focus()

func set_slot(s: int) -> void:
	slot = s

func _on_confirmar() -> void:
	var nombre = nombre_input.text.strip_edges()
	if nombre == "":
		nombre = "Partida " + str(slot)
	SaveSystem.save_nuevo(slot, nombre)
	GameManager.nueva_partida_mode = true
	GameManager.change_state(GameManager.GameState.PLAYING)
	GameManager.world_state.current_room = "Bosque/bosque02"
	get_tree().change_scene_to_file("res://view/world/game_world.tscn")

func _on_cancelar() -> void:
	get_tree().change_scene_to_file("res://view/menus/slots_select.tscn")
