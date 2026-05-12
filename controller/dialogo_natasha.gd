# controller/dialogo_natasha.gd
# -------------------------------------------------------------
# DIALOGO NATASHA — UI del cuadro de diálogo inferior
# Navegación con flechas arriba/abajo y E para confirmar.
# -------------------------------------------------------------
extends CanvasLayer

signal dialogo_cerrado

@onready var texto: RichTextLabel = $Panel/Texto
@onready var opciones: VBoxContainer = $Panel/Opciones

var lineas: Array = []
var indice: int = 0
var en_opciones: bool = false
var activo: bool = false
var opcion_seleccionada: int = 0


func _ready() -> void:
	opciones.visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func mostrar_presentacion() -> void:
	activo = true
	en_opciones = false
	opcion_seleccionada = 0
	lineas = [
		"Me llaman Natasha. Llevo aquí desde 1905.",
		"Soy la guardiana de este umbral. Decido quién entiende y quién vaga perdido.",
		"¿Qué quieres saber?"
	]
	indice = 0
	texto.text = lineas[indice]
	opciones.visible = false


func _process(_delta: float) -> void:
	if not activo:
		return

	if not en_opciones:
		if Input.is_action_just_pressed("interact"):
			indice += 1
			if indice >= lineas.size():
				_mostrar_opciones()
			else:
				texto.text = lineas[indice]
		return

	if Input.is_action_just_pressed("ui_down"):
		opcion_seleccionada = (opcion_seleccionada + 1) % 4
		_actualizar_seleccion()
	if Input.is_action_just_pressed("ui_up"):
		opcion_seleccionada = (opcion_seleccionada - 1 + 4) % 4
		_actualizar_seleccion()
	if Input.is_action_just_pressed("interact"):
		_confirmar_opcion()


func _actualizar_seleccion() -> void:
	var botones = [
		$Panel/Opciones/Btn1,
		$Panel/Opciones/Btn2,
		$Panel/Opciones/Btn3,
		$Panel/Opciones/Btn4
	]
	for i in range(botones.size()):
		if i == opcion_seleccionada:
			botones[i].modulate = Color(1.0, 0.85, 0.3)
		else:
			botones[i].modulate = Color.WHITE


func _confirmar_opcion() -> void:
	match opcion_seleccionada:
		0: _on_btn1_pressed()
		1: _on_btn2_pressed()
		2: _on_btn3_pressed()
		3: _on_btn4_pressed()


func _mostrar_opciones() -> void:
	en_opciones = true
	opcion_seleccionada = 0
	texto.text = ""
	opciones.visible = true
	_actualizar_seleccion()


func responder(nuevas_lineas: Array) -> void:
	en_opciones = false
	opciones.visible = false
	lineas = nuevas_lineas
	indice = 0
	texto.text = lineas[indice]


func cerrar() -> void:
	activo = false
	visible = false
	dialogo_cerrado.emit()


func _on_btn1_pressed() -> void:
	responder([
		"En el purgatorio de San Petersburgo.",
		"El tiempo aquí está congelado en el 9 de enero de 1905.",
		"Ese día el Imperio zarista ordenó disparar sobre miles de civiles.",
		"Murieron cientos. Nadie quiso contarlos.",
		"Ese día nunca terminó aquí. Y no terminará hasta que alguien lo enfrente."
	])


func _on_btn2_pressed() -> void:
	responder([
		"Eso no te concierne.",
		"Guardiana. Es suficiente con eso."
	])


func _on_btn3_pressed() -> void:
	responder([
		"Porque llevas el apellido Volkov.",
		"Tu abuelo fue uno de los oficiales que dio la orden de disparar ese día.",
		"Tú naciste después. Viviste de esa fortuna sin preguntar.",
		"La ignorancia no es inocencia, Dimitri.",
		"Si lo enfrentas, puedes descansar. Si no, te quedas como los demás."
	])


func _on_btn4_pressed() -> void:
	en_opciones = false
	opciones.visible = false
	texto.text = "Entonces avanza, Volkov. El purgatorio te está esperando."
	await get_tree().create_timer(2.5).timeout
	cerrar()
