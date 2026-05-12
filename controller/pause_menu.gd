# controller/pause_menu.gd
# -------------------------------------------------------------
# PAUSE MENU — Menú de pausa con dos opciones
# ESC para abrir/cerrar. Flechas para navegar, E para confirmar.
# -------------------------------------------------------------
extends CanvasLayer

@onready var btn_continuar: TextureButton = $BtnContinuar
@onready var btn_menu_principal: TextureButton = $BtnMenuPrincipal

var opcion_seleccionada: int = 0


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	btn_continuar.pressed.connect(_continuar)
	btn_menu_principal.pressed.connect(_ir_menu_principal)
	_actualizar_seleccion()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		_toggle()
		return
	if not visible:
		return
	if Input.is_action_just_pressed("ui_down"):
		opcion_seleccionada = (opcion_seleccionada + 1) % 2
		_actualizar_seleccion()
	if Input.is_action_just_pressed("ui_up"):
		opcion_seleccionada = (opcion_seleccionada - 1 + 2) % 2
		_actualizar_seleccion()
	if Input.is_action_just_pressed("interact"):
		if opcion_seleccionada == 0:
			_continuar()
		else:
			_ir_menu_principal()


func _toggle() -> void:
	visible = not visible
	if visible:
		get_tree().paused = true
		opcion_seleccionada = 0
		_actualizar_seleccion()
	else:
		get_tree().paused = false


func _actualizar_seleccion() -> void:
	btn_continuar.modulate = Color(1.0, 0.85, 0.3) if opcion_seleccionada == 0 else Color.WHITE
	btn_menu_principal.modulate = Color(1.0, 0.85, 0.3) if opcion_seleccionada == 1 else Color.WHITE


func _continuar() -> void:
	get_tree().paused = false
	visible = false


func _ir_menu_principal() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://view/menus/main_menu.tscn")
