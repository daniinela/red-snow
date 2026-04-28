# -------------------------------------------------------------
# ITEM DATA — Modelo de un item
# Define qué es el item, su tipo y qué efecto aplica.
# No contiene lógica de juego, solo datos.
# -------------------------------------------------------------
class_name ItemData
extends Resource

enum Type { RELIC, CONSUMABLE, LORE }

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var type: Type = Type.LORE
@export var icon: Texture2D

# Efectos para RELIC y CONSUMABLE
@export var hp_max_bonus: int = 0
@export var attack_bonus: int = 0
@export var stamina_max_bonus: float = 0.0
@export var move_speed_bonus: float = 0.0
@export var heal_amount: int = 0
