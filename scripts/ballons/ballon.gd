## Ballon dessiné par code : monte du bas de l'écran vers le haut en se
## balançant doucement (sinusoïde), avec ficelle ondulée, nœud et reflet.
## Se gonfle à l'apparition, se supprime tout seul une fois sorti par le haut.
extends Node2D

var couleur := Color(0.95, 0.35, 0.35)
var rayon := 50.0        # demi-hauteur du corps
var vitesse := 90.0      # vitesse de montée (px/s)
var amplitude := 30.0    # balancement horizontal (px)
var frequence := 1.2     # vitesse du balancement

var _x_base := 0.0
var _temps := 0.0


func _ready() -> void:
	_x_base = position.x
	_temps = randf() * TAU  # phase de départ aléatoire : pas de ballons synchrones
	# Gonflage à l'apparition
	scale = Vector2.ONE * 0.3
	var animation := create_tween()
	animation.tween_property(self, "scale", Vector2.ONE, 0.4) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_temps += delta
	position.y -= vitesse * delta
	position.x = _x_base + sin(_temps * frequence) * amplitude
	# Sorti par le haut (ficelle comprise) → disparaît sans bruit, aucun échec
	if position.y < -rayon * 2.2 - 40.0:
		queue_free()


## Le point (coordonnées globales du calque) touche-t-il le ballon ?
## Marge généreuse (1.2) : adapté aux petites mains qui visent presque juste.
func contient(point: Vector2) -> bool:
	var local := point - position
	var dx := local.x / (rayon * 0.85)
	var dy := local.y / rayon
	return dx * dx + dy * dy <= 1.2


func _draw() -> void:
	# Ficelle ondulée sous le ballon
	var points := PackedVector2Array()
	for i in 13:
		var t := float(i) / 12.0
		points.append(Vector2(sin(t * TAU * 1.5) * rayon * 0.12, rayon * 1.05 + t * rayon * 1.1))
	draw_polyline(points, Color(1.0, 1.0, 1.0, 0.8), 3.0)
	# Nœud
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, rayon * 0.92),
		Vector2(-rayon * 0.14, rayon * 1.12),
		Vector2(rayon * 0.14, rayon * 1.12),
	]), couleur.darkened(0.15))
	# Corps : cercle étiré verticalement (forme de goutte douce)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.85, 1.0))
	draw_circle(Vector2.ZERO, rayon, couleur)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Reflet lumineux en haut à gauche
	draw_set_transform(Vector2(-rayon * 0.3, -rayon * 0.4), deg_to_rad(-20.0), Vector2(0.45, 0.75))
	draw_circle(Vector2.ZERO, rayon * 0.32, Color(1.0, 1.0, 1.0, 0.4))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
