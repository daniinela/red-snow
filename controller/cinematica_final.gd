# controller/cinematica_final.gd
# -------------------------------------------------------------
# CINEMATICA FINAL — Escena de decapitación del boss
# Una sola animación que muestra a Dimitri y el abuelo juntos.
# Blanco y negro, solo se puede presionar E.
# -------------------------------------------------------------
extends Node2D

@onready var animacion: AnimatedSprite2D = $CanvasLayer2/Animacion
@onready var indicador_e: Sprite2D = $CanvasLayer2/IndicadorE
@onready var fade: ColorRect = $CanvasLayer/ColorRect

var puede_interactuar: bool = false


func _ready() -> void:
	fade.color = Color(0, 0, 0, 1)
	indicador_e.modulate.a = 0.0
	# Blanco y negro
	animacion.modulate = Color(0.3, 0.3, 0.3)
	animacion.play("idle")
	await get_tree().create_timer(0.5).timeout
	# Fade de entrada
	var tw = create_tween()
	tw.tween_property(fade, "color", Color(0, 0, 0, 0), 1.5)
	await tw.finished
	# Aparece el indicador E poco a poco
	await get_tree().create_timer(1.0).timeout
	var tw2 = create_tween()
	tw2.tween_property(indicador_e, "modulate:a", 1.0, 1.5)
	await tw2.finished
	puede_interactuar = true


func _process(_delta: float) -> void:
	if puede_interactuar and Input.is_action_just_pressed("interact"):
		_decapitar()


func _decapitar() -> void:
	puede_interactuar = false
	indicador_e.visible = false
	animacion.play("decapitar")
	await animacion.animation_finished
	await get_tree().create_timer(0.5).timeout
	var tw = create_tween()
	tw.tween_property(fade, "color", Color(0, 0, 0, 1), 1.0)
	await tw.finished
	get_tree().change_scene_to_file("res://view/menus/creditos.tscn")
