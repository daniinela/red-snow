# controller/player_controller.gd
# -------------------------------------------------------------
# PLAYER CONTROLLER — Lógica del jugador
# Lee input, aplica física, maneja estados.
# Le pertenece al nodo CharacterBody2D del jugador.
# Referencia al PlayerData para leer y modificar stats.
# -------------------------------------------------------------
class_name PlayerController
extends CharacterBody2D

@export var data: PlayerData
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var dash_timer: Timer = $DashTimer
@onready var combat: CombatSystem = $CombatSystem
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var particulas_sangre: GPUParticles2D = $ParticulasSangre
@onready var sombra: Polygon2D = $Sombra
@onready var raycast_sombra: RayCast2D = $RaycastSombra
@onready var sprite_start: AnimatedSprite2D = $AnimatedSprite2D2

const GRAVITY: float = 900.0
const SOMBRA_Y_OFFSET := 5.0
const SOMBRA_ESCALA_MAX := 1.0
const SOMBRA_ESCALA_MIN := 0.3
const SOMBRA_ALPHA_MAX := 0.5
const SOMBRA_ALPHA_MIN := 0.1
const ALTURA_MAX := 400.0

enum State { IDLE, RUN, JUMP, FALL, DASH, ATTACK, HURT, DEAD }
var current_state: State = State.IDLE
var is_dashing: bool = false
var is_attacking: bool = false
var can_dash: bool = true
var facing_right: bool = true
var coyote_active: bool = false
var is_hurt: bool = false
var dash_cooldown: bool = false
var was_on_floor: bool = false
var ataque_habilitado: bool = true
var dash_habilitado: bool = true

func _ready() -> void:
	EventBus.player_damaged.connect(_on_damaged)
	attack_hitbox.body_entered.connect(combat.on_hit)
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.frame_changed.connect(_on_frame_changed)
	sombra.top_level = true
	sombra.polygon = PackedVector2Array([
		Vector2(-40, 148),
		Vector2(-25, 142),
		Vector2(0, 140),
		Vector2(25, 142),
		Vector2(40, 148),
		Vector2(25, 154),
		Vector2(0, 156),
		Vector2(-25, 154)
	])
	sprite_start.animation_finished.connect(_on_start_finished)
	if GameManager.nueva_partida_mode:
		sprite.visible = false
		sprite_start.visible = true
		if sprite_start.sprite_frames and sprite_start.sprite_frames.has_animation("Start"):
			sprite_start.play("Start")
		else:
			sprite_start.visible = false
			sprite.visible = true
			sprite.play("idle")
	else:
		sprite_start.visible = false
		sprite.visible = true
		sprite.play("idle")

func _on_start_finished() -> void:
	if sprite_start.animation == "Start":
		sprite_start.visible = false
		sprite.visible = true
		sprite.play("idle")
		GameManager.nueva_partida_mode = false

func _physics_process(delta: float) -> void:
	if not GameManager.is_playing():
		return
	if sprite_start.visible:
		return
	_apply_gravity(delta)
	_handle_movement()
	_handle_jump()
	_handle_dash()
	_handle_attack()
	_regen_stamina(delta)
	move_and_slide()
	_update_animation()
	_handle_flask()
	_update_sombra()

func _update_sombra() -> void:
	if not raycast_sombra.is_colliding():
		sombra.visible = false
		return
	sombra.visible = true
	var piso_y := raycast_sombra.get_collision_point().y
	var altura := piso_y - global_position.y
	var t: float = clamp(altura / ALTURA_MAX, 0.0, 1.0)
	var escala: float = lerp(SOMBRA_ESCALA_MAX, SOMBRA_ESCALA_MIN, t)
	var alpha: float = lerp(SOMBRA_ALPHA_MAX, SOMBRA_ALPHA_MIN, t)
	sombra.global_position = Vector2(global_position.x, piso_y)
	sombra.scale = Vector2(escala, 0.3)
	sombra.color = Color(0, 0, 0, alpha)

func _handle_flask() -> void:
	if Input.is_action_just_pressed("use_flask") and data.flask_current > 0:
		data.flask_current -= 1
		data.heal(data.flask_heal_amount)
		EventBus.player_flask_changed.emit(data.flask_current, data.flask_max)

func _handle_attack() -> void:
	if not ataque_habilitado:
		return
	if Input.is_action_just_pressed("attack") and not is_attacking and not is_hurt:
		is_attacking = true
		attack_hitbox.position.x = 80.0 if facing_right else -80.0
		attack_hitbox.monitoring = false
		sprite.play("attack")

func _apply_gravity(delta: float) -> void:
	if is_dashing:
		return
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		was_on_floor = false
	else:
		velocity.y = 0
		if not was_on_floor:
			can_dash = true
			dash_cooldown = false
			coyote_active = true
			was_on_floor = true

func _handle_movement() -> void:
	if is_dashing or is_attacking or is_hurt:
		return
	var dir := Input.get_axis("move_left", "move_right")
	var speed := data.run_speed if Input.is_action_pressed("run") else data.move_speed
	velocity.x = dir * speed
	if dir != 0:
		facing_right = dir > 0
		sprite.flip_h = not facing_right

func _handle_jump() -> void:
	if is_dashing:
		return
	if Input.is_action_just_pressed("jump") and (is_on_floor() or coyote_active):
		velocity.y = data.jump_force
		coyote_active = false
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5

func _handle_dash() -> void:
	if not dash_habilitado:
		return
	if Input.is_action_just_pressed("dash") and can_dash and not is_dashing and not dash_cooldown:
		is_dashing = true
		can_dash = false
		dash_cooldown = true
		data.stamina_current -= 25.0
		velocity.x = data.dash_force * (1.0 if facing_right else -1.0) * 1.5
		velocity.y = 0
		set_collision_mask_value(4, false)
		var anim_duration = sprite.sprite_frames.get_frame_count("dash") / sprite.sprite_frames.get_animation_speed("dash")
		dash_timer.start(anim_duration)

func _regen_stamina(delta: float) -> void:
	if data.stamina_current < data.stamina_max:
		data.stamina_current += data.stamina_regen * delta
		data.stamina_current = min(data.stamina_current, data.stamina_max)
		EventBus.player_stamina_changed.emit(data.stamina_current)

func _update_animation() -> void:
	if is_attacking:
		return
	if is_hurt:
		return
	if is_dashing:
		sprite.play("dash")
		return
	if not is_on_floor():
		sprite.play("jump" if velocity.y < 0 else "fall")
		return
	if abs(velocity.x) > 10:
		sprite.play("run" if Input.is_action_pressed("run") else "walk")
	else:
		sprite.play("idle")

func _on_animation_finished() -> void:
	if sprite.animation == "attack":
		is_attacking = false
		attack_hitbox.monitoring = false
	if sprite.animation == "hit":
		is_attacking = false
	if sprite.animation == "dash":
		is_dashing = false
		set_collision_mask_value(4, true)

func _on_frame_changed() -> void:
	if sprite.animation == "attack":
		if sprite.frame == 3 or sprite.frame == 4:
			attack_hitbox.monitoring = true
			combat.attack(attack_hitbox)
		else:
			attack_hitbox.monitoring = false

func _on_damaged(_amount: int, _hp_current: int) -> void:
	if is_hurt:
		return
	is_hurt = true
	is_attacking = false
	sprite.play("hit")
	velocity.x = -300.0 if facing_right else 300.0
	velocity.y = -150.0
	sprite.modulate = Color.WHITE * 3.0
	particulas_sangre.restart()
	particulas_sangre.emitting = true
	await get_tree().create_timer(0.4).timeout
	sprite.modulate = Color.WHITE
	await get_tree().create_timer(0.6).timeout
	is_hurt = false

func _on_dash_timer_timeout() -> void:
	velocity.x = 0
	is_dashing = false
	set_collision_mask_value(4, true)

func _on_coyote_timer_timeout() -> void:
	coyote_active = false
