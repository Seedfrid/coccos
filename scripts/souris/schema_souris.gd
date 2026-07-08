## Schéma de souris affiché dans un coin de l'écran.
## Le bouton réellement pressé s'illumine de la couleur de son animation :
## l'enfant relie le geste physique (doigt) à l'effet à l'écran.
## Zones : "gauche", "droit", "molette".
extends Node2D

const DEMI_LARGEUR := 46.0   # demi-axe horizontal de l'ellipse (corps)
const DEMI_HAUTEUR := 62.0   # demi-axe vertical
const Y_SEPARATION := -10.0  # ligne séparant les boutons du corps

const COULEUR_CORPS := Color(0.98, 0.97, 0.92, 0.92)
const COULEUR_TRAIT := Color(0.25, 0.25, 0.3)

var _intensites := {"gauche": 0.0, "droit": 0.0, "molette": 0.0}
var _couleurs := {
	"gauche": Color(1.0, 0.8, 0.2),
	"droit": Color(1.0, 0.4, 0.7),
	"molette": Color(0.3, 0.9, 1.0),
}


## Illumine une zone (intensité pleine, puis extinction progressive).
func allumer(zone: String, couleur: Color) -> void:
	_couleurs[zone] = couleur
	_intensites[zone] = 1.0
	queue_redraw()


func _process(delta: float) -> void:
	for zone in _intensites:
		if _intensites[zone] > 0.0:
			_intensites[zone] = maxf(_intensites[zone] - delta * 2.2, 0.0)
			queue_redraw()


func _draw() -> void:
	# Fil de la souris (petite courbe au-dessus, pour le charme)
	draw_arc(Vector2(0.0, -DEMI_HAUTEUR - 14.0), 14.0, PI * 0.15, PI * 0.85, 16, COULEUR_TRAIT, 3.0)

	# Corps : ellipse pleine (cercle mis à l'échelle horizontalement)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(DEMI_LARGEUR / DEMI_HAUTEUR, 1.0))
	draw_circle(Vector2.ZERO, DEMI_HAUTEUR, COULEUR_CORPS)
	draw_arc(Vector2.ZERO, DEMI_HAUTEUR, 0.0, TAU, 64, COULEUR_TRAIT, 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Illumination des boutons pressés
	if _intensites["gauche"] > 0.0:
		draw_colored_polygon(_zone_bouton(true),
			Color(_couleurs["gauche"], _intensites["gauche"] * 0.85))
	if _intensites["droit"] > 0.0:
		draw_colored_polygon(_zone_bouton(false),
			Color(_couleurs["droit"], _intensites["droit"] * 0.85))

	# Séparations boutons / corps et gauche / droite
	var x_separation := DEMI_LARGEUR * sqrt(1.0 - pow(Y_SEPARATION / DEMI_HAUTEUR, 2.0))
	draw_line(Vector2(-x_separation, Y_SEPARATION), Vector2(x_separation, Y_SEPARATION), COULEUR_TRAIT, 3.0)
	draw_line(Vector2(0.0, -DEMI_HAUTEUR), Vector2(0.0, Y_SEPARATION), COULEUR_TRAIT, 3.0)

	# Molette au centre, par-dessus la séparation verticale
	var rect_molette := Rect2(-6.0, -52.0, 12.0, 26.0)
	if _intensites["molette"] > 0.0:
		draw_rect(rect_molette.grow(3.0),
			Color(_couleurs["molette"], _intensites["molette"] * 0.9))
	draw_rect(rect_molette, Color(0.75, 0.75, 0.8))
	draw_rect(rect_molette, COULEUR_TRAIT, false, 2.5)


## Contour de la zone d'un bouton : arc d'ellipse + retour par la ligne médiane.
func _zone_bouton(gauche: bool) -> PackedVector2Array:
	var points := PackedVector2Array()
	var angle_debut := PI + asin(-Y_SEPARATION / DEMI_HAUTEUR)  # sur l'ellipse, à y = Y_SEPARATION
	var angle_fin := PI * 1.5                                    # sommet de l'ellipse
	for i in 13:
		var angle := lerpf(angle_debut, angle_fin, float(i) / 12.0)
		points.append(Vector2(DEMI_LARGEUR * cos(angle), DEMI_HAUTEUR * sin(angle)))
	points.append(Vector2(0.0, Y_SEPARATION))
	if not gauche:
		for i in points.size():
			points[i] = Vector2(-points[i].x, points[i].y)
	return points
