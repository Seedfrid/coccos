## Étoile à 5 branches dessinée par code — particule des animations.
## Se déplace (vitesse + gravité), tourne, rétrécit et s'estompe,
## puis se supprime toute seule en fin de vie.
extends Node2D

var couleur := Color(1.0, 0.85, 0.3)
var rayon := 10.0
var vitesse := Vector2.ZERO
var gravite := 0.0
var rotation_vitesse := 0.0
var duree_vie := 0.8

var _age := 0.0


func _process(delta: float) -> void:
	_age += delta
	if _age >= duree_vie:
		queue_free()
		return
	vitesse.y += gravite * delta
	position += vitesse * delta
	rotation += rotation_vitesse * delta
	var t := _age / duree_vie
	modulate.a = 1.0 - t
	scale = Vector2.ONE * (1.0 - 0.4 * t)


func _draw() -> void:
	# Polygone à 10 sommets : rayon plein / rayon creux en alternance
	var points := PackedVector2Array()
	for i in 10:
		var r := rayon if i % 2 == 0 else rayon * 0.45
		var angle := -PI / 2.0 + TAU * float(i) / 10.0
		points.append(Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(points, couleur)
	# Petit cœur blanc pour l'effet « scintillant »
	draw_circle(Vector2.ZERO, rayon * 0.2, Color(1, 1, 1, 0.9))
