# view/world/door.gd
# -------------------------------------------------------------
# DOOR — Puerta de transición entre rooms
# El jugador entra al Area2D para activarla.
# Cada puerta tiene un ID único y sabe a qué room lleva
# y por qué puerta de destino aparece el jugador.
# Bloquea el paso si el tutorial no está completo.
# -------------------------------------------------------------
extends Area2D

@export var door_id: String = "door_01"
@export var target_room: String = "room_02"
@export var target_door_id: String = "door_02"
@export var requiere_tutorial: bool = false

var player_inside: bool = false
var tutorial_done: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if requiere_tutorial:
		# Espera un frame para que el tutorial exista en escena
		await get_tree().process_frame
		var tm = get_tree().get_first_node_in_group("tutorial")
		if tm:
			tm.tutorial_completo.connect(func(): tutorial_done = true)
		else:
			tutorial_done = true  # Si no hay tutorial, no bloquea
	else:
		tutorial_done = true

func _process(_delta: float) -> void:
	if player_inside and tutorial_done:
		player_inside = false  # ← evita que dispare múltiples veces
		_transition()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = false

func _transition() -> void:
	print("[Door] Transicion a: ", target_room, " puerta: ", target_door_id)
	GameManager.change_room(target_room, target_door_id)
	
