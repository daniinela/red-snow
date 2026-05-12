# controller/natasha.gd
# -------------------------------------------------------------
# NATASHA — NPC guardiana del puente
# -------------------------------------------------------------
extends Area2D

@onready var indicador_e: Sprite2D = $IndicadorE
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var jugador_cerca: bool = false
var en_dialogo: bool = false
var dialogo: CanvasLayer = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	indicador_e.visible = false
	sprite.play("idle")
	await get_tree().process_frame
	dialogo = get_tree().get_first_node_in_group("dialogo_natasha")
	if dialogo:
		dialogo.visible = false


func _process(_delta: float) -> void:
	if not GameManager.is_playing():
		return
	if jugador_cerca and not en_dialogo:
		if Input.is_action_just_pressed("interact"):
			_iniciar_dialogo()


func _iniciar_dialogo() -> void:
	en_dialogo = true
	indicador_e.visible = false
	monitoring = false
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(false)
		player.velocity = Vector2.ZERO
	dialogo.visible = true
	dialogo.mostrar_presentacion()
	await dialogo.dialogo_cerrado
	en_dialogo = false
	indicador_e.visible = true
	monitoring = true
	if player:
		player.set_physics_process(true)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		jugador_cerca = true
		indicador_e.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		jugador_cerca = false
		indicador_e.visible = false
