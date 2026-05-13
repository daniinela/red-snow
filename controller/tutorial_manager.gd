# controller/tutorial_manager.gd
# -------------------------------------------------------------
# TUTORIAL MANAGER — Muestra teclas con fade.
# Ataque bloqueado hasta checkpoint. Dash se da tras boss 1.
# -------------------------------------------------------------
extends CanvasLayer

signal tutorial_completo

@onready var tecla_a: TextureRect = $TeclaA
@onready var tecla_d: TextureRect = $TeclaD
@onready var tecla_espacio: TextureRect = $TeclaEspacio
@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer

var player: Node2D = null
var paso: int = 0
var hecho_izq: bool = false
var hecho_der: bool = false
var hecho_salto: bool = false
var intro_done: bool = false


func _ready() -> void:
	add_to_group("tutorial")
	if GameManager.world_state.is_enemy_defeated("boss1"):
		var p = get_tree().get_first_node_in_group("player")
		if p:
			p.ataque_habilitado = true
			p.dash_habilitado = true
		queue_free()
		return

	EventBus.checkpoint_activado.connect(_on_checkpoint_activado)
	tecla_a.modulate.a = 0
	tecla_d.modulate.a = 0
	tecla_espacio.modulate.a = 0
	tecla_a.visible = true
	tecla_d.visible = true
	tecla_espacio.visible = true
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if player:
		player.ataque_habilitado = false
		player.dash_habilitado = false

	#if GameManager.nueva_partida_mode:
		#await _play_video()

	_play_intro()


func _play_video() -> void:
	GameManager.change_state(GameManager.GameState.PAUSED)
	video_player.visible = true
	video_player.play()
	await video_player.finished
	video_player.visible = false
	video_player.stop()
	GameManager.change_state(GameManager.GameState.PLAYING)


func _play_intro() -> void:
	if not player:
		intro_done = true
		_fade_in([tecla_a, tecla_d, tecla_espacio])
		return
	if GameManager.nueva_partida_mode:
		player.sprite_start.visible = true
		player.sprite.visible = false
		player.sprite_start.play("Start")
		await player.sprite_start.animation_finished
	intro_done = true
	_fade_in([tecla_a, tecla_d, tecla_espacio])


func _fade_in(nodos: Array) -> void:
	var tw := create_tween()
	for n in nodos:
		n.visible = true
		tw.parallel().tween_property(n, "modulate:a", 1.0, 0.6)


func _fade_out(nodos: Array) -> void:
	var tw := create_tween()
	for n in nodos:
		tw.parallel().tween_property(n, "modulate:a", 0.0, 0.4)
	await tw.finished
	for n in nodos:
		n.visible = false


func _process(_delta: float) -> void:
	if not intro_done:
		return
	match paso:
		0:
			if Input.is_action_just_pressed("move_left"):
				hecho_izq = true
			if Input.is_action_just_pressed("move_right"):
				hecho_der = true
			if Input.is_action_just_pressed("jump"):
				hecho_salto = true
			if hecho_izq and hecho_der and hecho_salto:
				paso = 1
				_fade_out([tecla_a, tecla_d, tecla_espacio])
		1:
			pass
		2:
			if Input.is_action_just_pressed("attack"):
				await get_tree().create_timer(0.3).timeout
				tutorial_completo.emit()
				queue_free()


func _on_checkpoint_activado() -> void:
	if paso == 1:
		paso = 2
		GameManager.change_state(GameManager.GameState.PAUSED)
		var tarjeta = preload("res://view/menus/tarjeta_habilidad.tscn").instantiate()
		get_tree().root.add_child(tarjeta)
		tarjeta.set_textura("res://assets/sprites/environment/tarjeta,ataque.png")
		await tarjeta.cerrada
		GameManager.change_state(GameManager.GameState.PLAYING)
		if player:
			player.ataque_habilitado = true
