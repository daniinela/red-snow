# -------------------------------------------------------------
# DOOR — Puerta de transición entre rooms
# El jugador entra al Area2D para activarla.
# Cada puerta tiene un ID único y sabe a qué room lleva
# y por qué puerta de destino aparece el jugador.
# -------------------------------------------------------------
extends Area2D

@export var door_id: String = "door_01"
@export var target_room: String = "room_02"
@export var target_door_id: String = "door_02"

var player_inside: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if player_inside and Input.is_action_just_pressed("interact"):
		_transition()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = false

func _transition() -> void:
	GameManager.change_room(target_room, target_door_id)
