# controller/enemy_ai.gd
# -------------------------------------------------------------
# ENEMY AI — Inteligencia artificial base para enemigos
# Máquina de estados: patrulla, persigue y ataca.
# Stats vienen del EnemyData (.tres) asignado en el inspector.
# -------------------------------------------------------------
class_name EnemyAI
extends CharacterBody2D

@export var data: EnemyData

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_zone: Area2D = $DetectionZone
@onready var hurt_box: Area2D = $HurtBox

const GRAVITY: float = 900.0

enum State { PATROL, CHASE, ATTACK, HURT, DEAD }
var current_state: State = State.PATROL
var hit_cooldown: bool = false

var patrol_direction: float = 1.0
var patrol_timer: float = 0.0
const PATROL_TIME: float = 2.0

var hp: int = 0
var player: Node2D = null
var can_attack: bool = true

func _ready() -> void:
	hp = data.hp
	detection_zone.body_entered.connect(_on_player_detected)
	detection_zone.body_exited.connect(_on_player_lost)

func _physics_process(delta: float) -> void:
	if not GameManager.is_playing():
		return
	_apply_gravity(delta)
	_check_hit()
	if player != null and player.get("is_dashing") == true:
		velocity.x = 0
		move_and_slide()
		return
	match current_state:
		State.PATROL:
			_patrol(delta)
		State.CHASE:
			_chase()
		State.ATTACK:
			_attack()
	move_and_slide()

func _check_hit() -> void:
	# Detecta si el hitbox del jugador está activo y en rango
	if not player or hit_cooldown:
		return
	var hitbox = player.get_node_or_null("AttackHitbox")
	if hitbox and hitbox.monitoring:
		var dist := global_position.distance_to(hitbox.global_position)
		if dist <= 80.0:
			hit_cooldown = true
			var damage: int = 25
			if player.get("data") != null:
				damage = player.data.attack_damage
			hp -= damage
			sprite.play("hit")
			if hp <= 0:
				_die()
			await get_tree().create_timer(0.5).timeout
			hit_cooldown = false

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

func _patrol(delta: float) -> void:
	# Camina de un lado al otro con timer
	patrol_timer += delta
	if patrol_timer >= PATROL_TIME:
		patrol_timer = 0.0
		patrol_direction *= -1.0
	velocity.x = data.velocidad * patrol_direction
	sprite.flip_h = patrol_direction < 0
	sprite.play("walk")

func _chase() -> void:
	# Persigue al jugador y ataca si está en rango
	if not player:
		current_state = State.PATROL
		return
	var dir: float = sign(player.global_position.x - global_position.x)
	velocity.x = data.velocidad * 1.5 * dir
	sprite.flip_h = dir < 0
	sprite.play("walk")
	var dist := global_position.distance_to(player.global_position)
	if dist <= data.rango_ataque:
		current_state = State.ATTACK

func _attack() -> void:
	velocity.x = 0
	if not can_attack:
		return
	can_attack = false
	sprite.play("attack")
	if player:
		print("enemigo ataca, dano: ", data.dano)
		player.data.take_damage(data.dano)
	await get_tree().create_timer(1.0).timeout
	can_attack = true
	current_state = State.CHASE

func _on_player_detected(body: Node2D) -> void:
	print("body detectado: ", body.name, " grupos: ", body.get_groups())
	if body.is_in_group("player"):
		player = body
		current_state = State.CHASE

func _on_player_lost(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = null
		current_state = State.PATROL

func _die() -> void:
	current_state = State.DEAD
	var player = get_tree().get_first_node_in_group("player")
	if player and player.get("data") != null and data.monedas > 0:
		player.data.agregar_monedas(data.monedas)
	EventBus.enemy_died.emit(name)
	queue_free()
