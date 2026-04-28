# view/ui/hud.gd
# -------------------------------------------------------------
# HUD — Interfaz de usuario en juego
# Muestra HP del jugador y monedas actuales.
# Solo escucha señales del EventBus — nunca toca el Model.
# -------------------------------------------------------------
extends CanvasLayer

@onready var health_bar: ProgressBar = $HealthBar
@onready var moneda_label: Label = $MonedaContainer/Moneda_Label

func _ready() -> void:
	call_deferred("_connect_signals")

func _connect_signals() -> void:
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.player_healed.connect(_on_player_healed)
	EventBus.monedas_changed.connect(_on_monedas_changed)
	var player = get_tree().get_first_node_in_group("player")
	if player and player.get("data") != null:
		health_bar.max_value = player.data.hp_max
		health_bar.value = player.data.hp_current
		moneda_label.text = str(player.data.monedas)

func _on_player_damaged(_amount: int, hp_current: int) -> void:
	health_bar.value = hp_current

func _on_player_healed(_amount: int, hp_current: int) -> void:
	health_bar.value = hp_current

func _on_monedas_changed(total: int) -> void:
	moneda_label.text = str(total)
