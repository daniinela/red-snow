
# Emite el HP actual — la View solo escucha, no busca# model/player_data.gd
# -------------------------------------------------------------
# PLAYER DATA — Datos del jugador
# Resource que contiene todos los stats del jugador.
# Se serializa completo al guardar la partida.
# No contiene lógica de juego, solo datos y señales de cambio.
# -------------------------------------------------------------
class_name PlayerData
extends Resource

@export var flask_max: int = 1
@export var flask_current: int = 1
@export var flask_heal_amount: int = 30
@export var hp_max: int = 100
@export var hp_current: int = 100
@export var stamina_max: float = 100.0
@export var stamina_current: float = 100.0
@export var stamina_regen: float = 15.0
@export var move_speed: float = 180.0
@export var run_speed: float = 300.0
@export var jump_force: float = -420.0
@export var dash_force: float = 500.0
@export var dash_duration: float = 0.2
@export var attack_damage: int = 25
@export var attack_cooldown: float = 0.4
@export var relics: Array[String] = []
@export var monedas: int = 0

func is_alive() -> bool:
	return hp_current > 0

func take_damage(amount: int) -> void:
	hp_current = max(0, hp_current - amount)
	print("jugador hp: ", hp_current)
	EventBus.player_damaged.emit(amount, hp_current)
	if not is_alive():
		EventBus.player_died.emit()

func heal(amount: int) -> void:
	hp_current = min(hp_max, hp_current + amount)
	EventBus.player_healed.emit(amount, hp_current)

func agregar_monedas(cantidad: int) -> void:
	monedas += cantidad
	EventBus.monedas_changed.emit(monedas)

func gastar_monedas(cantidad: int) -> bool:
	if monedas < cantidad:
		return false
	monedas -= cantidad
	EventBus.monedas_changed.emit(monedas)
	return true
