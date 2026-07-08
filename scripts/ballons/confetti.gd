## Confetti : petit rectangle coloré projeté par l'éclatement d'un ballon.
## Vole, retombe (gravité), tournoie et s'estompe, puis se supprime tout seul.
extends Node2D

var couleur := Color.WHITE
var taille := 12.0
var vitesse := Vector2.ZERO
var duree_vie := 0.9

var _age := 0.0
var _rotation_vitesse := 0.0


func _ready() -> void:
	_rotation_vitesse = randf_range(-10.0, 10.0)
	rotation = randf() * TAU


func _process(delta: float) -> void:
	_age += delta
	if _age >= duree_vie:
		queue_free()
		return
	vitesse.y += 700.0 * delta
	position += vitesse * delta
	rotation += _rotation_vitesse * delta
	modulate.a = 1.0 - _age / duree_vie


func _draw() -> void:
	draw_rect(Rect2(-taille / 2.0, -taille / 4.0, taille, taille / 2.0), couleur)
