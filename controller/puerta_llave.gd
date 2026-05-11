# controller/puerta_llave.gd
# -------------------------------------------------------------
# PUERTA CON LLAVE — Solo se abre si el jugador tiene la llave
# Muestra indicador E cuando está cerca.
# Si no tiene la llave muestra feedback visual de bloqueada.
# -------------------------------------------------------------
extends Area2D

@export var llave_id: String = "llave_militar"
@export var target_room: String = ""
@export var door_id: String = ""
@onready var indicador_e: Sprite2D = $IndicadorE
@onready var sprite_puerta: Sprite2D = $SpritePuerta

var jugador_cerca: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	indicador_e.visible = false


func _process(_delta: float) -> void:
	if not GameManager.is_playing():
		return
	if jugador_cerca and Input.is_action_just_pressed("interact"):
		_intentar_abrir()


func _intentar_abrir() -> void:
	if not GameManager.world_state.is_door_open(llave_id):
		# No tiene la llave — feedback de bloqueada
		_shake_bloqueada()
		return
	# Tiene la llave — abrir con fade normal
	indicador_e.visible = false
	GameManager.world_state.last_door_used = door_id
	EventBus.room_transition_requested.emit(target_room, door_id)


func _shake_bloqueada() -> void:
	# Pequeño shake para indicar que está bloqueada
	var pos_original := sprite_puerta.position
	var tw := create_tween()
	tw.tween_property(sprite_puerta, "position", pos_original + Vector2(5, 0), 0.05)
	tw.tween_property(sprite_puerta, "position", pos_original + Vector2(-5, 0), 0.05)
	tw.tween_property(sprite_puerta, "position", pos_original + Vector2(3, 0), 0.05)
	tw.tween_property(sprite_puerta, "position", pos_original, 0.05)
	# Flash rojo suave
	sprite_puerta.modulate = Color(1.0, 0.3, 0.3)
	await tw.finished
	var tw2 := create_tween()
	tw2.tween_property(sprite_puerta, "modulate", Color.WHITE, 0.2)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		jugador_cerca = true
		indicador_e.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		jugador_cerca = false
		indicador_e.visible = false
