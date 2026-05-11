# controller/item_llave.gd
# -------------------------------------------------------------
# ITEM LLAVE — Objeto coleccionable del mundo
# El jugador presiona E cerca para recogerla.
# Se guarda en world_state para persistir entre sesiones.
# -------------------------------------------------------------
extends Area2D

@export var llave_id: String = "llave_militar"
@onready var sprite: Sprite2D = $Sprite2D
@onready var indicador_e: Sprite2D = $IndicadorE
@onready var sprite_sin_llave: Sprite2D = $SpriteSinLlave

var jugador_cerca: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	indicador_e.visible = false
	sprite_sin_llave.visible = false  # empieza oculto
	if GameManager.world_state.is_door_open(llave_id):
		queue_free()


func _process(_delta: float) -> void:
	if not GameManager.is_playing():
		return
	if jugador_cerca and Input.is_action_just_pressed("interact"):
		_recoger()


func _recoger() -> void:
	GameManager.world_state.open_door(llave_id)
	# NO llamar SaveSystem.save() aquí — solo actualizar world_state
	# El guardado real ocurre en el checkpoint
	
	var lugar = get_tree().get_first_node_in_group("lugar_sin_llave")
	if lugar:
		lugar.visible = true
	var tw := create_tween()
	tw.tween_property(sprite, "modulate:a", 0.0, 0.3)
	tw.tween_property(indicador_e, "modulate:a", 0.0, 0.2)
	await tw.finished
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		jugador_cerca = true
		indicador_e.visible = true
		print("jugador cerca de llave")


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		jugador_cerca = false
		indicador_e.visible = false
