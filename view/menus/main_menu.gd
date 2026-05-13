extends CanvasLayer

@onready var nueva_partida: Button = $VBoxContainer/NuevaPartida
@onready var continuar: Button = $VBoxContainer/Continuar
@onready var salir: Button = $VBoxContainer/Salir

@onready var video_bg: VideoStreamPlayer = $VideoStreamPlayer

func _ready() -> void:
	video_bg.play()
	nueva_partida.pressed.connect(_on_nueva_partida)
	continuar.pressed.connect(_on_continuar)
	salir.pressed.connect(_on_salir)
	GameManager.change_state(GameManager.GameState.MENU)
	var hay_partida = SaveSystem.slot_exists(1) or SaveSystem.slot_exists(2) or SaveSystem.slot_exists(3)
	continuar.visible = hay_partida

func _on_nueva_partida() -> void:
	GameManager.nueva_partida_mode = true
	get_tree().change_scene_to_file("res://view/menus/slots_select.tscn")

func _on_continuar() -> void:
	GameManager.nueva_partida_mode = false
	get_tree().change_scene_to_file("res://view/menus/slots_select.tscn")

func _on_salir() -> void:
	get_tree().quit()
