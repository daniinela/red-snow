# controller/ascensor.gd
# -------------------------------------------------------------
# ASCENSOR — Plataforma móvil activada por el jugador
# Guarda posiciones absolutas en _ready para evitar drift.
# Presiona E para alternar entre PuntoA y PuntoB.
# -------------------------------------------------------------
extends AnimatableBody2D

@onready var zona_encima: Area2D = $ZonaEncima
@onready var punto_a: Marker2D = $PuntoA
@onready var punto_b: Marker2D = $PuntoB
@onready var letra_e: Sprite2D = $LetraE
@export var velocidad: float = 120.0

var jugador_cerca: bool = false
var en_movimiento: bool = false
var en_punto_a: bool = true

# Posiciones absolutas guardadas una sola vez
var pos_a: Vector2
var pos_b: Vector2


func _ready() -> void:
	sync_to_physics = true
	pos_a = punto_a.global_position
	pos_b = punto_b.global_position
	# PuntoA es arriba, PuntoB es abajo — siempre empieza abajo
	global_position = pos_b
	en_punto_a = false
	zona_encima.body_entered.connect(_on_body_entered)
	zona_encima.body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if not GameManager.is_playing():
		return
	if jugador_cerca and not en_movimiento:
		if Input.is_action_just_pressed("interact"):
			_activar()


func _activar() -> void:
	en_movimiento = true
	var destino := pos_b if en_punto_a else pos_a
	en_punto_a = not en_punto_a
	var duracion := global_position.distance_to(destino) / velocidad
	var tw := create_tween()
	tw.tween_property(self, "global_position", destino, duracion) \
		.set_ease(Tween.EASE_IN_OUT) \
		.set_trans(Tween.TRANS_SINE)
	await tw.finished
	en_movimiento = false


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		jugador_cerca = true
		letra_e.visible = true  


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		jugador_cerca = false
		letra_e.visible = false
