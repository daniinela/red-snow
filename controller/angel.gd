# controller/angel.gd
# -------------------------------------------------------------
# ANGEL — Enemigo volador del puente
# Flota en el aire, dispara flechas hacia el jugador.
# Al recibir 2 golpes se teletransporta detrás del jugador.
# Muere al tercer golpe con efecto espectacular.
# Incluye shader de descarga eléctrica al recibir daño.
# -------------------------------------------------------------
extends CharacterBody2D

@export var data: EnemyData
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurt_box: Area2D = $HurtBox
@onready var detection_zone: Area2D = $DetectionZone
@onready var particulas_golpe: CPUParticles2D = $ParticulasGolpe
@onready var particulas_teleport: CPUParticles2D = $ParticulasTeleport
@onready var particulas_muerte: CPUParticles2D = $ParticulasMuerte

const FLECHA_ESCENA := preload("res://view/enemies/flecha.tscn")

enum State { IDLE, ATACANDO, HIT, DEAD }
var current_state: State = State.IDLE
var player: Node2D = null
var hp: int = 3
var golpes_recibidos: int = 0
var hit_cooldown: bool = false
var puede_atacar: bool = true
var tiempo_entre_ataques: float = 2.5
var timer_ataque: float = 0.0

var float_offset: float = 0.0
var float_speed: float = 2.0
var float_amplitude: float = 15.0
var posicion_base_y: float = 0.0

# Material compartido para el shader de descarga
var _hit_material: ShaderMaterial = null


func _ready() -> void:
	posicion_base_y = global_position.y
	detection_zone.body_entered.connect(_on_player_detected)
	detection_zone.body_exited.connect(_on_player_lost)
	sprite.play("idle")
	_configurar_particulas()
	_configurar_shader()
	add_to_group("angel")

func iniciar_posicion(pos: Vector2) -> void:
	global_position = pos
	posicion_base_y = pos.y

func _configurar_shader() -> void:
	# Crea el material con el shader de descarga una sola vez
	_hit_material = ShaderMaterial.new()
	_hit_material.set_shader_parameter("flash_progress", 0.0)
	_hit_material.set_shader_parameter("band_width", 0.18)
	_hit_material.set_shader_parameter("flash_color", Color(1.0, 1.0, 1.0, 1.0))


func _configurar_particulas() -> void:
	# Partículas de golpe — chispas blancas que salen en abanico
	particulas_golpe.emitting = false
	particulas_golpe.one_shot = true
	particulas_golpe.explosiveness = 0.95
	particulas_golpe.amount = 20
	particulas_golpe.lifetime = 0.25
	particulas_golpe.speed_scale = 1.0
	particulas_golpe.initial_velocity_min = 200.0
	particulas_golpe.initial_velocity_max = 350.0
	particulas_golpe.spread = 50.0
	particulas_golpe.gravity = Vector2.ZERO
	particulas_golpe.damping_min = 300.0
	particulas_golpe.damping_max = 500.0
	particulas_golpe.scale_amount_min = 2.0
	particulas_golpe.scale_amount_max = 5.0
	particulas_golpe.color = Color.WHITE

	# Partículas de teletransporte — explotan y se contraen
	particulas_teleport.emitting = false
	particulas_teleport.one_shot = true
	particulas_teleport.explosiveness = 1.0
	particulas_teleport.amount = 40
	particulas_teleport.lifetime = 0.4
	particulas_teleport.initial_velocity_min = 150.0
	particulas_teleport.initial_velocity_max = 300.0
	particulas_teleport.spread = 180.0
	particulas_teleport.gravity = Vector2.ZERO
	particulas_teleport.damping_min = 400.0
	particulas_teleport.damping_max = 600.0
	particulas_teleport.scale_amount_min = 2.0
	particulas_teleport.scale_amount_max = 5.0
	particulas_teleport.color = Color(0.9, 0.95, 1.0, 1.0)

	# Partículas de muerte — explosión grande de plumas
	particulas_muerte.emitting = false
	particulas_muerte.one_shot = true
	particulas_muerte.explosiveness = 1.0
	particulas_muerte.amount = 60
	particulas_muerte.lifetime = 0.8
	particulas_muerte.initial_velocity_min = 100.0
	particulas_muerte.initial_velocity_max = 400.0
	particulas_muerte.spread = 180.0
	particulas_muerte.gravity = Vector2(0, 80)
	particulas_muerte.damping_min = 100.0
	particulas_muerte.damping_max = 200.0
	particulas_muerte.scale_amount_min = 5.0
	particulas_muerte.scale_amount_max = 7.0
	particulas_muerte.color = Color.WHITE


func _physics_process(delta: float) -> void:
	if not GameManager.is_playing():
		return
	if current_state == State.DEAD:
		return
	_flotar(delta)
	if player and current_state == State.IDLE:
		_orientar_hacia_jugador()
		timer_ataque += delta
		if timer_ataque >= tiempo_entre_ataques:
			timer_ataque = 0.0
			_atacar()
	_check_hit()
	move_and_slide()


func _flotar(delta: float) -> void:
	float_offset += delta * float_speed
	global_position.y = posicion_base_y + sin(float_offset) * float_amplitude
	velocity = Vector2.ZERO


func _orientar_hacia_jugador() -> void:
	if not player:
		return
	sprite.flip_h = player.global_position.x > global_position.x


func _atacar() -> void:
	if not player or not puede_atacar:
		return
	current_state = State.ATACANDO
	puede_atacar = false
	sprite.play("attack")
	# Flash blanco al atacar
	sprite.modulate = Color.WHITE * 2.0
	var tw = create_tween()
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.2)
	await sprite.animation_finished
	_disparar_flecha()
	sprite.play("idle")
	current_state = State.IDLE
	await get_tree().create_timer(tiempo_entre_ataques).timeout
	puede_atacar = true


func _disparar_flecha() -> void:
	if not player:
		return
	var flecha = FLECHA_ESCENA.instantiate()
	get_parent().add_child(flecha)
	flecha.global_position = global_position
	var dir = (player.global_position - global_position).normalized()
	flecha.iniciar(dir, data.dano)


func _reproducir_descarga_electrica() -> void:
	# Parpadeo de impacto — oscurece el sprite brevemente como contracción de dolor
	# Funciona sobre sprites blancos donde el flash blanco no se vería
	var secuencia := [
		[Color(0.15, 0.15, 0.2),   0.04],  # oscuro azulado — impacto
		[Color(0.9, 0.9, 1.0),     0.03],  # casi blanco — rebote
		[Color(0.1, 0.1, 0.15),    0.04],  # oscuro de nuevo — eco
		[Color(0.7, 0.75, 0.85),   0.05],  # gris azulado — disipando
		[Color.WHITE,              0.12],  # restaura suave
	]
	for par in secuencia:
		sprite.modulate = par[0]
		await get_tree().create_timer(par[1]).timeout
	sprite.modulate = Color.WHITE


func _check_hit() -> void:
	if hit_cooldown or current_state == State.DEAD:
		return
	if not player:
		return
	var hitbox = player.get_node_or_null("AttackHitbox")
	if hitbox and hitbox.monitoring:
		var dist := global_position.distance_to(hitbox.global_position)
		if dist <= 120.0:
			hit_cooldown = true
			golpes_recibidos += 1
			hp -= 1

			# Partículas de golpe en dirección opuesta al jugador
			var dir_golpe = sign(player.global_position.x - global_position.x)
			particulas_golpe.direction = Vector2(-dir_golpe, -0.3)
			particulas_golpe.emitting = true

			# Flash blanco intenso + descarga eléctrica simultáneos
			_reproducir_descarga_electrica()  # No awaited: corre en paralelo

			if hp <= 0:
				_morir()
				return

			if golpes_recibidos % 2 == 0:
				await get_tree().create_timer(0.1).timeout
				_teletransportar()
			else:
				current_state = State.HIT
				sprite.play("hit")
				await sprite.animation_finished
				sprite.play("idle")
				current_state = State.IDLE

			await get_tree().create_timer(0.4).timeout
			hit_cooldown = false


func _teletransportar() -> void:
	if not player:
		return

	# Partículas de desaparición
	particulas_teleport.emitting = true

	# Fade out rápido
	var tw_out = create_tween()
	tw_out.tween_property(sprite, "modulate:a", 0.0, 0.15)
	await tw_out.finished

	# Moverse detrás del jugador
	var detras: float = 200.0
	var offset_x = -detras if player.get("facing_right") == true else detras
	global_position = Vector2(
		player.global_position.x + offset_x,
		player.global_position.y - 50.0
	)
	posicion_base_y = global_position.y

	# Partículas de aparición
	particulas_teleport.emitting = true

	# Fade in con flash
	sprite.modulate = Color(2.0, 2.0, 2.0, 0.0)
	var tw_in = create_tween()
	tw_in.tween_property(sprite, "modulate", Color.WHITE, 0.3)
	await tw_in.finished

	hit_cooldown = false


func _morir() -> void:
	current_state = State.DEAD
	hurt_box.monitoring = false
	hurt_box.monitorable = false

	# Freeze frame
	process_mode = Node.PROCESS_MODE_ALWAYS
	particulas_muerte.process_mode = Node.PROCESS_MODE_ALWAYS
	sprite.modulate = Color.WHITE * 5.0
	get_tree().paused = true
	await get_tree().create_timer(0.3, true).timeout
	get_tree().paused = false

	# Explosión de plumas
	sprite.modulate = Color.WHITE
	sprite.play("die")
	particulas_muerte.emitting = true

	# Fade out mientras muere
	var tw = create_tween()
	tw.tween_property(sprite, "modulate:a", 0.0, 0.6)

	await get_tree().create_timer(0.8).timeout

	if player and is_instance_valid(player):
		if player.get("data") != null and data.monedas > 0:
			player.data.agregar_monedas(data.monedas)
	EventBus.enemy_died.emit(name)
	queue_free()


func _on_player_detected(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body


func _on_player_lost(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = null
