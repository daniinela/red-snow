# -------------------------------------------------------------
# ITEM PICKUP — Objeto recogible en el mundo
# El jugador presiona interact cerca para recogerlo.
# Se destruye al ser recogido y se persiste en WorldState
# para no volver a aparecer.
# -------------------------------------------------------------
extends Area2D

@export var item_id: String = ""

var player_nearby: bool = false

func _ready() -> void:
	# Si ya fue recogido, no aparece
	if Inventory.has_item(item_id):
		queue_free()
		return
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if player_nearby and Input.is_action_just_pressed("interact"):
		_recoger()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = false

func _recoger() -> void:
	Inventory.collect(item_id)
	queue_free()
