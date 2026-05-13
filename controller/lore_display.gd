# -------------------------------------------------------------
# LORE DISPLAY — Muestra imagen de lore la primera vez
# que el jugador entra a una habitación.
# -------------------------------------------------------------
extends CanvasLayer

@onready var textura: TextureRect = $ColorRect/TextureRect

var lore_map := {
	"Castillo/Castillo_Boss": "res://assets/sprites/environment/TextoCastillo.png",
	"tigre/tigre_room": "res://assets/sprites/environment/Textotigre.png",
	"CuartelesMilitares/Militar_room01": "res://assets/sprites/environment/Textomilitarroom.png",
	"Puente/PuenteSanPetersburgo": "res://assets/sprites/environment/TextoPuente.png",
}

func _ready() -> void:
	visible = false
	EventBus.lore_requested.connect(_on_lore_requested)

func _on_lore_requested(room_id: String) -> void:
	if not lore_map.has(room_id):
		print("[Lore] No hay lore para: ", room_id)
		return
	var path = lore_map[room_id]
	if not ResourceLoader.exists(path):
		print("[Lore] No existe el archivo: ", path)
		return
	textura.texture = load(path)
	print("[Lore] Mostrando lore para: ", room_id)
	print("[Lore] Textura cargada: ", textura.texture)
	visible = true
	GameManager.change_state(GameManager.GameState.PAUSED)
	await get_tree().create_timer(9.0).timeout
	visible = false
	GameManager.change_state(GameManager.GameState.PLAYING)
