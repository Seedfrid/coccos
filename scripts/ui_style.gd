## Helper de style partagé pour les boutons du bureau enfant.
## Reprend la charte des tuiles du dashboard : coins arrondis, éclaircissement
## au survol, assombrissement à l'appui, bordure jaune de focus (accessibilité).
## Usage : UIStyle.styliser(bouton, couleur, rayon)
extends RefCounted
## (Pas de class_name : preload explicite chez les consommateurs — règle projet.)

const COULEUR_FOCUS := Color(1.0, 1.0, 0.2)  # jaune vif accessibilité


## Crée un StyleBoxFlat arrondi d'une couleur donnée.
static func creer_style(couleur: Color, rayon: int, bordure_focus := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = couleur
	style.set_corner_radius_all(rayon)
	if bordure_focus:
		style.set_border_width_all(4)
		style.border_color = COULEUR_FOCUS
	return style


## Applique les 4 états (normal/hover/focus/pressed) + texte blanc à un bouton.
static func styliser(btn: Button, couleur: Color, rayon := 16) -> void:
	btn.add_theme_stylebox_override("normal", creer_style(couleur, rayon))
	btn.add_theme_stylebox_override("hover", creer_style(couleur.lightened(0.15), rayon))
	btn.add_theme_stylebox_override("focus", creer_style(couleur.lightened(0.10), rayon, true))
	btn.add_theme_stylebox_override("pressed", creer_style(couleur.darkened(0.15), rayon))
	for etat in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		btn.add_theme_color_override(etat, Color.WHITE)
