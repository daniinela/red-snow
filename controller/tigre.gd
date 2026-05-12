# controller/tigre.gd
# -------------------------------------------------------------
# TIGRE — NPC interactuable de la sala del tigre
# El jugador presiona E para activar la cutscene.
# Primera vez: muestra video y lleva al Castillo.
# Si ya fue usado: devuelve a Militar_room01.
# -------------------------------------------------------------
extends Area2D

const TIGRE_ID := "tigre_usado"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var indicador_e: Sprite2D = $IndicadorE
var video: VideoStreamPlayer = null
@export var en_castillo: bool = false

var jugador_cerca: bool = false
var en_cutscene: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	indicador_e.visible = false
	sprite.play("idle")
	if not en_castillo:
		video = get_node_or_null("../CanvasLayer/VideoStreamPlayer")


func _process(_delta: float) -> void:
	if not GameManager.is_playing():
		return
	if jugador_cerca and not en_cutscene:
		if Input.is_action_just_pressed("interact"):
			if en_castillo:
				_devolver_a_tigre()
			elif GameManager.world_state.is_door_open(TIGRE_ID):
				_devolver_a_militar()
			else:
				_activar_cutscene()
func _devolver_a_tigre() -> void:
	en_cutscene = true
	indicador_e.visible = false
	GameManager.world_state.last_door_used = "door_tigre"
	EventBus.room_transition_requested.emit("tigre/tigre_room", "door_tigre")

func _activar_cutscene() -> void:
	en_cutscene = true
	indicador_e.visible = false
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.ataque_habilitado = false
		player.dash_habilitado = false
		player.velocity = Vector2.ZERO
	video.visible = true
	video.play()
	await video.finished
	video.visible = false
	GameManager.world_state.open_door(TIGRE_ID)
	GameManager.change_state(GameManager.GameState.PLAYING)
	if player:
		player.ataque_habilitado = true
		player.dash_habilitado = true
	EventBus.room_transition_requested.emit("Castillo/Castillo_Boss", "")


func _devolver_a_militar() -> void:
	en_cutscene = true
	indicador_e.visible = false
	GameManager.world_state.last_door_used = "door_llave_militar"
	EventBus.room_transition_requested.emit("CuartelesMilitares/Militar_room01", "door_llave_militar")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		jugador_cerca = true
		indicador_e.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		jugador_cerca = false
		indicador_e.visible = false
