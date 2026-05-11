# view/menus/tarjeta_habilidad.gd
# -------------------------------------------------------------
# TARJETA HABILIDAD — Muestra tarjeta de habilidad desbloqueada
# Se cierra con Espacio o click. Emite señal al cerrarse.
# -------------------------------------------------------------
extends CanvasLayer

signal cerrada

@onready var fondo: ColorRect = $ColorRect
@onready var tarjeta: TextureRect = $TextureRect

var puede_cerrar: bool = false

func _ready() -> void:
	fondo.modulate.a = 0
	tarjeta.modulate.a = 0
	tarjeta.pivot_offset = tarjeta.size / 2
	_animar_entrada()

func _animar_entrada() -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(fondo, "modulate:a", 0.7, 0.4)
	tw.tween_property(tarjeta, "modulate:a", 1.0, 0.5)
	await tw.finished
	await get_tree().create_timer(0.3).timeout
	puede_cerrar = true

func _input(event: InputEvent) -> void:
	if not puede_cerrar:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_cerrar()
	elif event is InputEventMouseButton and event.pressed:
		_cerrar()

func _cerrar() -> void:
	puede_cerrar = false
	var tw := create_tween().set_parallel(true)
	tw.tween_property(fondo, "modulate:a", 0.0, 0.3)
	tw.tween_property(tarjeta, "modulate:a", 0.0, 0.3)
	tw.tween_property(tarjeta, "scale", Vector2(1.1, 1.1), 0.3)
	await tw.finished
	cerrada.emit()
	queue_free()

func set_textura(ruta: String) -> void:
	tarjeta.texture = load(ruta)
