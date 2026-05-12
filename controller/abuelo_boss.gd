# controller/abuelo_boss.gd
# -------------------------------------------------------------
# ABUELO — Boss final del Castillo
# No ataca directamente — invoca ángeles cada 5 segundos.
# Cinemática de introducción al detectar al jugador.
# Al morir, fade a negro y créditos.
# -------------------------------------------------------------
extends CharacterBody2D

@export var data: EnemyData

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurt_box: Area2D = $HurtBox
@onready var detection_zone: Area2D = $DetectionZone
@onready var particulas_golpe: CPUParticles2D = $ParticulasGolpe
@onready var particulas_muerte: CPUParticles2D = $ParticulasMuerte

const ANGEL_ESCENA := preload("res://view/enemies/angel.tscn")

enum State { ESPERANDO, CINEMATICA, ACTIVO, HIT, MURIENDO, MUERTO }
var current_state: State = State.ESPERANDO

var player: Node2D = null
var hp: int = 20
var hit_cooldown: bool = false

# Control de invocación
var timer_invocar: float = 0.0
var intervalo_invocar: float = 5.0
var invocaciones_realizadas: int = 0
var max_invocaciones_por_ronda: int = 3
var en_invocacion: bool = false
var angeles_activos: Array = []

func _ready() -> void:
	detection_zone.body_entered.connect(_on_player_detected)
	sprite.play("idle")
	hurt_box.monitoring = false
	hurt_box.monitorable = false
	_configurar_particulas()
	EventBus.enemy_died.connect(_on_enemy_died)


func _configurar_particulas() -> void:
	particulas_golpe.emitting = false
	particulas_golpe.one_shot = true
	particulas_golpe.explosiveness = 0.9
	particulas_golpe.amount = 20
	particulas_golpe.lifetime = 0.3
	particulas_golpe.initial_velocity_min = 150.0
	particulas_golpe.initial_velocity_max = 280.0
	particulas_golpe.spread = 60.0
	particulas_golpe.gravity = Vector2(0, 150)
	particulas_golpe.damping_min = 200.0
	particulas_golpe.damping_max = 350.0
	particulas_golpe.scale_amount_min = 2.0
	particulas_golpe.scale_amount_max = 4.0
	particulas_golpe.color = Color(0.9, 0.85, 0.75, 1.0)

	particulas_muerte.emitting = false
	particulas_muerte.one_shot = true
	particulas_muerte.explosiveness = 1.0
	particulas_muerte.amount = 70
	particulas_muerte.lifetime = 1.0
	particulas_muerte.initial_velocity_min = 80.0
	particulas_muerte.initial_velocity_max = 350.0
	particulas_muerte.spread = 180.0
	particulas_muerte.gravity = Vector2(0, 60)
	particulas_muerte.damping_min = 80.0
	particulas_muerte.damping_max = 150.0
	particulas_muerte.scale_amount_min = 3.0
	particulas_muerte.scale_amount_max = 7.0
	particulas_muerte.color = Color(0.9, 0.85, 0.75, 1.0)


func _physics_process(delta: float) -> void:
	if not GameManager.is_playing():
		return
	if current_state == State.MUERTO or current_state == State.MURIENDO:
		return
	if current_state == State.ESPERANDO or current_state == State.CINEMATICA:
		return

	# Orientar hacia jugador
	if player:
		sprite.flip_h = player.global_position.x > global_position.x

	# Ciclo de invocación
	if current_state == State.ACTIVO and not en_invocacion:
		timer_invocar += delta
		if timer_invocar >= intervalo_invocar:
			timer_invocar = 0.0
			_iniciar_ronda_invocacion()

	_check_hit()
	move_and_slide()


func _on_player_detected(body: Node2D) -> void:
	if body.is_in_group("player") and current_state == State.ESPERANDO:
		player = body
		_iniciar_cinematica()


func _iniciar_cinematica() -> void:
	current_state = State.CINEMATICA

	# Pausa todo — solo el boss y la UI siguen
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	sprite.process_mode = Node.PROCESS_MODE_ALWAYS

	# Congela 3 segundos — efecto cinematográfico
	await get_tree().create_timer(3.0, true).timeout

	get_tree().paused = false

	# Activa combate
	hurt_box.monitoring = true
	hurt_box.monitorable = true
	current_state = State.ACTIVO

	# Primera invocación inmediata
	await get_tree().create_timer(1.0).timeout
	_iniciar_ronda_invocacion()


func _iniciar_ronda_invocacion() -> void:
	if current_state != State.ACTIVO:
		return
	en_invocacion = true

	for i in range(max_invocaciones_por_ronda):
		if current_state != State.ACTIVO:
			break
		await _invocar_angeles()
		# Espera a que los 2 ángeles mueran antes de invocar más
		await _esperar_muerte_angeles()

	en_invocacion = false

func _esperar_muerte_angeles() -> void:
	# Espera hasta que no queden ángeles en la escena
	while true:
		await get_tree().create_timer(1.0).timeout
		var angeles = get_tree().get_nodes_in_group("angel")
		if angeles.is_empty():
			break


func _invocar_angeles() -> void:
	sprite.play("invocar")
	await sprite.animation_finished
	sprite.play("idle")
	var piso_y = player.global_position.y if player else global_position.y
	for i in range(2):
		var angel = ANGEL_ESCENA.instantiate()
		get_parent().add_child(angel)
		var offset_x = -400.0 if i == 0 else -700.0
		angel.iniciar_posicion(Vector2(global_position.x + offset_x, piso_y - 80.0))
		angeles_activos.append(angel)

func _on_enemy_died(enemy_name: String) -> void:
	if current_state == State.MUERTO or current_state == State.MURIENDO:
		return
	for angel in angeles_activos:
		if angel.name == enemy_name:
			angeles_activos.erase(angel)
			hp -= 3
			sprite.modulate = Color(0.15, 0.15, 0.2)
			var tw = create_tween()
			tw.tween_property(sprite, "modulate", Color.WHITE, 0.2)
			particulas_golpe.emitting = true
			if hp <= 0:
				_morir()
			return


func _check_hit() -> void:
	if hit_cooldown or current_state == State.MUERTO:
		return
	if not player:
		return
	var hitbox = player.get_node_or_null("AttackHitbox")
	if hitbox and hitbox.monitoring:
		var dist := global_position.distance_to(hitbox.global_position)
		if dist <= 130.0:
			hit_cooldown = true
			hp -= 1

			# Partículas y flash
			var dir_golpe = sign(player.global_position.x - global_position.x)
			particulas_golpe.direction = Vector2(-dir_golpe, -0.4)
			particulas_golpe.emitting = true

			# Flash de daño — tono cálido sobre sprite claro
			sprite.modulate = Color(0.15, 0.15, 0.2)
			var tw = create_tween()
			tw.tween_property(sprite, "modulate", Color.WHITE, 0.12)

			if hp <= 0:
				_morir()
				return

			current_state = State.HIT
			sprite.play("hit")
			await sprite.animation_finished
			sprite.play("idle")
			current_state = State.ACTIVO

			await get_tree().create_timer(0.35).timeout
			hit_cooldown = false


func _morir() -> void:
	current_state = State.MURIENDO
	hurt_box.monitoring = false
	hurt_box.monitorable = false
	en_invocacion = false

	sprite.play("hit")
	velocity = Vector2.ZERO

	process_mode = Node.PROCESS_MODE_ALWAYS
	particulas_muerte.process_mode = Node.PROCESS_MODE_ALWAYS
	sprite.modulate = Color(0.15, 0.15, 0.2) * 3.0
	get_tree().paused = true
	await get_tree().create_timer(0.5, true).timeout
	get_tree().paused = false

	sprite.modulate = Color.WHITE
	particulas_muerte.emitting = true

	if player:
		player.ataque_habilitado = false
		player.dash_habilitado = false

	await get_tree().create_timer(1.5).timeout
	current_state = State.MUERTO
	EventBus.enemy_died.emit(name)
	SaveSystem.delete_slot(GameManager.current_slot)
	get_tree().change_scene_to_file("res://view/menus/cinematica_final.tscn")
