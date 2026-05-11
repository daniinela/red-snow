# controller/raiz.gd
# -------------------------------------------------------------
# RAIZ — Proyectil de la Boss1
# Aparece en el piso y daña al jugador desde frame 4.
# Se destruye al terminar la animación.
# -------------------------------------------------------------
extends Area2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var dano: int = 20
var puede_dañar: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	monitoring = false
	sprite.play("idle")
	sprite.frame_changed.connect(_on_frame_changed)
	sprite.animation_finished.connect(_on_animation_finished)

func _on_frame_changed() -> void:
	if sprite.frame >= 4 and not puede_dañar:
		puede_dañar = true
		monitoring = true

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.data.take_damage(dano)

func _on_animation_finished() -> void:
	queue_free()
