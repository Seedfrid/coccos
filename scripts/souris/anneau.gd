## Anneau qui s'agrandit et s'estompe — ponctuation des clics
## (halo doré au clic gauche, cercles arc-en-ciel au clic molette).
extends Node2D

var couleur := Color.WHITE
var rayon_max := 90.0
var epaisseur := 7.0
var duree_vie := 0.6
var delai := 0.0

var _age := 0.0


func _process(delta: float) -> void:
	if delai > 0.0:
		delai -= delta
		return
	_age += delta
	if _age >= duree_vie:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	if delai > 0.0:
		return
	var t := _age / duree_vie
	var rayon := rayon_max * (1.0 - pow(1.0 - t, 2.0))  # départ rapide, arrivée douce
	var alpha := 1.0 - t
	draw_arc(Vector2.ZERO, rayon, 0.0, TAU, 48,
		Color(couleur, alpha), epaisseur * (1.0 - 0.5 * t))
