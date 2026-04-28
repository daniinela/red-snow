# view/world/checkpoint.gd
# -------------------------------------------------------------
# CHECKPOINT — Estatua de respawn
# El jugador presiona E para activarla.
# Se puede usar múltiples veces — siempre cura al 100%.
# -------------------------------------------------------------
extends Area2D

var player_nearby: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if player_nearby and Input.is_action_just_pressed("interact"):
		_activar()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = false

func _activar() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	player.set_meta("checkpoint_pos", global_position)
	var hp_max = player.data.hp_max
	player.data.hp_current = hp_max
	EventBus.player_healed.emit(hp_max, hp_max)
	# Guarda la room actual en WorldState antes de guardar
	var room = get_tree().get_first_node_in_group("room")
	if room and room.get("room_id"):
		GameManager.world_state.current_room = room.room_id
	print("Guardando room: ", GameManager.world_state.current_room)
	print("Guardando pos: ", global_position)
	player.data.flask_current = player.data.flask_max
	EventBus.player_flask_changed.emit(player.data.flask_current, player.data.flask_max)
	SaveSystem.save(GameManager.current_slot)
	print("Checkpoint activado — vida restaurada y partida guardada")
