# model/enemy_data.gd
# -------------------------------------------------------------
# ENEMY DATA — Stats de enemigos
# Plantilla base para todos los tipos de enemigo.
# Cada tipo tiene su propio .tres con valores distintos.
# Agregar un enemigo nuevo = crear un .tres, no tocar código.
# -------------------------------------------------------------
class_name EnemyData
extends Resource

@export var nombre: String = ""
@export var hp: int = 60
@export var dano: int = 15
@export var velocidad: float = 80.0
@export var rango_deteccion: float = 200.0
@export var rango_ataque: float = 50.0
@export var knockback_fuerza: float = 150.0
@export var monedas: int = 10
