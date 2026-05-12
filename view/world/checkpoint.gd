# view/world/checkpoint.gd
# -------------------------------------------------------------
# CHECKPOINT — Campana de respawn
# El jugador presiona E para activarla.
# Se puede usar múltiples veces — siempre cura al 100%.
# -------------------------------------------------------------
extends Area2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var indicador_e: Sprite2D = $IndicadorE
@onready var sonido: AudioStreamPlayer2D = $SonidoCampana  # 👈 nodo de audio

var player_nearby: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	sprite.play("idle")
	indicador_e.visible = false

func _process(_delta: float) -> void:
	if player_nearby and Input.is_action_just_pressed("interact"):
		_activar()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		indicador_e.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		indicador_e.visible = false

func _activar() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	player.set_meta("checkpoint_pos", global_position)
	player.data.hp_current = player.data.hp_max
	EventBus.player_healed.emit(player.data.hp_max, player.data.hp_max)
	player.data.flask_current = player.data.flask_max
	EventBus.player_flask_changed.emit(player.data.flask_current, player.data.flask_max)
	var room = get_tree().get_first_node_in_group("room")
	if room and room.get("room_id"):
		GameManager.world_state.current_room = room.room_id
	SaveSystem.save(GameManager.current_slot)
	EventBus.checkpoint_activado.emit()
	sonido.play()
	sprite.play("activar")
	await sprite.animation_finished
	sprite.play("idle")
