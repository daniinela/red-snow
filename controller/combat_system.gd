# controller/combat_system.gd
# -------------------------------------------------------------
# COMBAT SYSTEM — Sistema de combate
# Maneja el ataque del jugador, hitboxes y daño a enemigos.
# El PlayerController lo llama cuando detecta input de ataque.
# -------------------------------------------------------------
class_name CombatSystem
extends Node

@export var data: PlayerData

var can_attack: bool = true
var combo_count: int = 0
var combo_timer: float = 0.0
const COMBO_WINDOW: float = 0.6

var sonido_acierto: AudioStreamPlayer2D  # 👈 agregado
var sonido_fallo: AudioStreamPlayer2D    # 👈 agregado

func _ready() -> void:  # 👈 agregado
	sonido_acierto = get_parent().get_node_or_null("SonidoGolpeAcierto")
	sonido_fallo = get_parent().get_node_or_null("SonidoGolpeFallo")
	print("Acierto: ", sonido_acierto)
	print("Fallo: ", sonido_fallo)

func _process(delta: float) -> void:
	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			combo_count = 0

func attack(hitbox: Area2D) -> void:
	if not can_attack:
		return
	can_attack = false
	combo_count = min(combo_count + 1, 2)
	combo_timer = COMBO_WINDOW
	hitbox.monitoring = true
	if sonido_fallo:
		sonido_fallo.play()  # 👈 agregado
	await get_tree().create_timer(data.attack_cooldown).timeout
	hitbox.monitoring = false
	can_attack = true

func on_hit(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(data.attack_damage)
		EventBus.enemy_damaged.emit(body.name, data.attack_damage)
		if sonido_fallo:
			sonido_fallo.stop()    # 👈 agregado
		if sonido_acierto:
			sonido_acierto.play()  # 👈 agregado
