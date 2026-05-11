# controller/flecha.gd
# -------------------------------------------------------------
# FLECHA — Proyectil disparado por el Angel
# Vuela hacia el jugador con leve seguimiento.
# Deja una estela de luz blanca. Se destruye al impactar
# o al salir de pantalla.
# -------------------------------------------------------------
extends Area2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var visible_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreen
@onready var estela: CPUParticles2D = $Estela

var direccion: Vector2 = Vector2.RIGHT
var velocidad: float = 600.0
var dano: int = 20
var player: Node2D = null
var seguimiento: float = 0.3


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	visible_notifier.screen_exited.connect(queue_free)
	player = get_tree().get_first_node_in_group("player")
	sprite.play("default")
	rotation = direccion.angle()
	_configurar_estela()


func _configurar_estela() -> void:
	estela.emitting = true
	estela.amount = 15
	estela.lifetime = 0.15
	estela.explosiveness = 0.0
	estela.one_shot = false
	estela.initial_velocity_min = 10.0
	estela.initial_velocity_max = 30.0
	estela.spread = 15.0
	estela.gravity = Vector2.ZERO
	estela.damping_min = 100.0
	estela.damping_max = 200.0
	estela.scale_amount_min = 1.5
	estela.scale_amount_max = 3.0
	estela.color = Color(0.9, 0.95, 1.0, 0.8)
	# La estela sale hacia atrás
	estela.direction = Vector2(-1, 0)


func iniciar(dir: Vector2, dano_cantidad: int) -> void:
	direccion = dir
	dano = dano_cantidad
	rotation = direccion.angle()


func _physics_process(delta: float) -> void:
	if player and is_instance_valid(player):
		var dir_jugador = (player.global_position - global_position).normalized()
		direccion = direccion.lerp(dir_jugador, seguimiento * delta)
		direccion = direccion.normalized()
		rotation = direccion.angle()
	global_position += direccion * velocidad * delta


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.get("data") != null:
			body.data.take_damage(dano)
		# Pequeño flash de impacto
		estela.emitting = false
		queue_free()
