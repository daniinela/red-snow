# autoloads/event_bus.gd
# -------------------------------------------------------------
# EVENT BUS — Sistema de señales globales
# Todos los sistemas se comunican aquí.
# Nadie necesita referencia directa a otro nodo.
# -------------------------------------------------------------
extends Node

# -- JUGADOR --
# Ahora incluyen hp_current para que la View no toque el Model
signal player_damaged(amount: int, hp_current: int)
signal player_died
signal player_healed(amount: int, hp_current: int)
signal player_stamina_changed(amount: float)
signal monedas_changed(total: int)
signal player_flask_changed(current: int, max_count: int)

# -- MUNDO --
signal room_changed(room_id: String)
signal door_opened(door_id: String)
signal checkpoint_activado
signal lore_requested(room_id: String)
# -- COMBATE --
signal enemy_damaged(enemy_id: String, amount: int)
signal enemy_died(enemy_id: String)

# -- UI --
signal pause_toggled(is_paused: bool)

# -- TRANSICIONES --
signal room_transition_requested(target_room: String, door_id: String)

# -- INVENTARIO --
signal item_collected(item_id: String)
signal inventory_changed
