# controller/boss1_controller.gd
extends CharacterBody2D

@export var data: EnemyData
@onready var sprite_attack: AnimatedSprite2D = $AnimatedSprite2D
@onready var sprite_die_jump: AnimatedSprite2D = $AnimatedSprite2D2
@onready var sprite_idle_hit: AnimatedSprite2D = $AnimatedSprite2D3
@onready var hurt_box: Area2D = $HurtBox
@onready var particulas_sangre: CPUParticles2D = $ParticulasSangre

const RAIZ_ESCENA := preload("res://view/enemies/raiz.tscn")
const GRAVITY: float = 900.0

enum State { IDLE, ATTACK, HIT, DEAD }
var current_state: State = State.IDLE
var hp: int = 0
var player: Node2D = null
var hit_cooldown: bool = false
var tiempo_entre_ataques: float = 4.0
var timer_ataque: float = 0.0
var raices_por_ataque: int = 3
var rango_activacion: float = 600.0
var raices_lanzadas: bool = false
var muerte_iniciada: bool = false  # ← evita doble muerte


func _ready() -> void:
	if GameManager.world_state.is_enemy_defeated("boss1"):
		queue_free()
		return
	hp = data.hp
	player = get_tree().get_first_node_in_group("player")
	sprite_attack.animation_finished.connect(_on_animation_finished_attack)
	sprite_attack.frame_changed.connect(_on_frame_changed_attack)
	sprite_die_jump.animation_finished.connect(_on_animation_finished_die)
	sprite_idle_hit.animation_finished.connect(_on_animation_finished_idle_hit)
	_mostrar_solo("idle")


func _mostrar_solo(anim: String) -> void:
	sprite_attack.visible = false
	sprite_die_jump.visible = false
	sprite_idle_hit.visible = false
	match anim:
		"attack":
			sprite_attack.visible = true
			sprite_attack.play("attack")
		"die", "jump":
			sprite_die_jump.visible = true
			sprite_die_jump.play(anim)
		"idle", "hit":
			sprite_idle_hit.visible = true
			sprite_idle_hit.play(anim)


func _on_frame_changed_attack() -> void:
	if sprite_attack.animation == "attack":
		if (sprite_attack.frame == 10 or sprite_attack.frame == 11) and not raices_lanzadas:
			raices_lanzadas = true
			_lanzar_raices()


func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return
	if not GameManager.is_playing():
		return
	_apply_gravity(delta)
	move_and_slide()
	_check_hit()
	if current_state == State.IDLE:
		timer_ataque += delta
		if timer_ataque >= tiempo_entre_ataques:
			timer_ataque = 0.0
			if player and global_position.distance_to(player.global_position) <= rango_activacion:
				_iniciar_ataque()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0


func _iniciar_ataque() -> void:
	if current_state != State.IDLE:
		return
	current_state = State.ATTACK
	_mostrar_solo("attack")


func _lanzar_raices() -> void:
	if not player:
		return
	var piso_y := 248.0
	var pos_jugador_x := player.global_position.x
	for i in raices_por_ataque:
		var raiz = RAIZ_ESCENA.instantiate()
		get_parent().add_child(raiz)
		var offset := (i - 1) * 150.0
		raiz.global_position = Vector2(pos_jugador_x + offset, piso_y)
		raiz.dano = data.dano
		await get_tree().create_timer(0.4).timeout


func _check_hit() -> void:
	if hit_cooldown or current_state == State.DEAD or muerte_iniciada:
		return
	if not player:
		return
	var hitbox = player.get_node_or_null("AttackHitbox")
	if hitbox and hitbox.monitoring:
		var dist := global_position.distance_to(hitbox.global_position)
		if dist <= 350.0:
			hit_cooldown = true
			hp -= player.data.attack_damage

			# flash
			sprite_idle_hit.modulate = Color.WHITE * 3.0
			sprite_attack.modulate   = Color.WHITE * 3.0
			sprite_die_jump.modulate = Color.WHITE * 3.0

			# partículas
			var dir_golpe: float = sign(player.global_position.x - global_position.x)
			particulas_sangre.direction = Vector2(-dir_golpe, 0.0)
			particulas_sangre.emitting = true
			await get_tree().create_timer(0.2).timeout
			particulas_sangre.emitting = false
			await get_tree().create_timer(0.2).timeout

			# quitar flash
			sprite_idle_hit.modulate = Color.WHITE
			sprite_attack.modulate   = Color.WHITE
			sprite_die_jump.modulate = Color.WHITE

			# ← verificar de nuevo por si ya murió durante el await
			if muerte_iniciada:
				return

			if hp <= 0:
				_morir()
			else:
				if current_state != State.ATTACK:
					current_state = State.HIT
					_mostrar_solo("hit")
				await get_tree().create_timer(0.5).timeout
				hit_cooldown = false


func _morir() -> void:
	if muerte_iniciada:
		return
	muerte_iniciada = true
	current_state = State.DEAD
	hurt_box.monitoring = false
	hurt_box.monitorable = false
	hit_cooldown = true
	_efecto_muerte()



func _efecto_muerte() -> void:
	# Que este nodo ignore la pausa
	process_mode = Node.PROCESS_MODE_ALWAYS
	sprite_die_jump.process_mode = Node.PROCESS_MODE_ALWAYS
	particulas_sangre.process_mode = Node.PROCESS_MODE_ALWAYS

	# 1. Congelar player — solo input, física sigue para que caiga
	if player and is_instance_valid(player):
		player.set_process(false)
		player.velocity.x = 0.0

	# 2. Esperar 0.3s para que caiga al piso naturalmente
	await get_tree().create_timer(0.3).timeout

	# 3. Congelar física del player también
	if player and is_instance_valid(player):
		player.set_physics_process(false)
		player.velocity = Vector2.ZERO

	# 4. Flash blanco
	sprite_attack.visible = false
	sprite_idle_hit.visible = false
	sprite_die_jump.visible = true
	sprite_die_jump.modulate = Color.WHITE * 5.0
	sprite_die_jump.play("die")
	sprite_die_jump.pause()

	# 5. Freeze frame
	get_tree().paused = true
	await get_tree().create_timer(0.5, true).timeout
	get_tree().paused = false

	# 6. Color normal y animación die
	sprite_die_jump.modulate = Color.WHITE
	sprite_die_jump.play("die")

	# 7. Fade out con tween
	var tw := create_tween()
	tw.tween_property(sprite_die_jump, "modulate:a", 0.0, 0.8)
	particulas_sangre.emitting = true

	# 8. Esperar que terminen — usamos timer en vez de señal
	await get_tree().create_timer(1.2).timeout

	particulas_sangre.emitting = false

	# 9. Reactiva player
	if player and is_instance_valid(player):
		player.set_physics_process(true)
		player.set_process(true)

	_on_muerta()


func _esperar_piso_player() -> void:
	var tiempo := 0.0
	while is_instance_valid(player) and not player.is_on_floor() and tiempo < 1.0:
		await get_tree().process_frame
		tiempo += get_process_delta_time()


func _on_animation_finished_attack() -> void:
	if current_state == State.DEAD:
		return
	if sprite_attack.animation == "attack":
		raices_lanzadas = false
		current_state = State.IDLE
		_mostrar_solo("idle")


func _on_animation_finished_die() -> void:
	pass  # _efecto_muerte maneja el flujo


func _on_animation_finished_idle_hit() -> void:
	if current_state == State.DEAD:
		return
	if sprite_idle_hit.animation == "hit":
		current_state = State.IDLE
		_mostrar_solo("idle")



func _on_muerta() -> void:
	GameManager.world_state.defeat_enemy("boss1")
	var tarjeta = preload("res://view/menus/tarjeta_habilidad.tscn").instantiate()
	get_tree().root.add_child(tarjeta)
	tarjeta.set_textura("res://assets/sprites/environment/tarjeta, dash.png")
	GameManager.change_state(GameManager.GameState.PAUSED)
	await tarjeta.cerrada
	GameManager.change_state(GameManager.GameState.PLAYING)
	if player and is_instance_valid(player):
		player.dash_habilitado = true
	SaveSystem.save(GameManager.current_slot)
	queue_free()
