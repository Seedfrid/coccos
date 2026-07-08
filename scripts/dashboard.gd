## Tableau de bord enfant — écran principal GCompris 2
## Affiche des tuiles d'activités à grosses icônes, navigable au clavier.
extends Control

const Fond = preload("res://scripts/fond.gd")

# Définition des tuiles : libellé, couleur de fond, action déverrouillée (true = navigue)
const TUILES := [
	{"label": "Souris",   "couleur": Color(0.20, 0.60, 0.90), "actif": true},
	{"label": "Clavier",  "couleur": Color(0.25, 0.75, 0.50), "actif": false},
	{"label": "Maths",    "couleur": Color(0.95, 0.55, 0.15), "actif": false},
	{"label": "Lecture",  "couleur": Color(0.85, 0.25, 0.45), "actif": false},
	{"label": "Puzzles",  "couleur": Color(0.60, 0.35, 0.85), "actif": false},
	{"label": "Dessin",   "couleur": Color(0.20, 0.70, 0.65), "actif": false},
]

func _ready() -> void:
	# --- Fond d'écran partagé (image prairie + repli couleur) ---
	Fond.appliquer(self)

	# --- Conteneur vertical principal (centré) ---
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 24)
	add_child(vbox)

	# --- Titre ---
	var titre := Label.new()
	titre.text = "Mon tableau de bord"
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.add_theme_font_size_override("font_size", 48)
	titre.add_theme_color_override("font_color", Color.WHITE)
	# Contour sombre pour rester lisible par-dessus l'image de fond
	titre.add_theme_color_override("font_outline_color", Color(0.10, 0.12, 0.10))
	titre.add_theme_constant_override("outline_size", 8)
	# Marge haute
	titre.custom_minimum_size = Vector2(0, 80)
	vbox.add_child(titre)

	# --- Conteneur centré pour la grille ---
	var centre := CenterContainer.new()
	centre.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(centre)

	# --- Grille 3 colonnes ---
	var grille := GridContainer.new()
	grille.columns = 3
	grille.add_theme_constant_override("h_separation", 24)
	grille.add_theme_constant_override("v_separation", 24)
	centre.add_child(grille)

	# --- Création des tuiles ---
	var premier_bouton: Button = null

	for tuile in TUILES:
		var btn := _creer_tuile(tuile["label"], tuile["couleur"])
		grille.add_child(btn)

		if tuile["actif"]:
			# Tuile "Souris" : navigue vers le placeholder
			btn.pressed.connect(_aller_placeholder)
			premier_bouton = btn
		else:
			# Tuiles verrouillées : message console uniquement
			var nom_capture: String = tuile["label"]
			btn.pressed.connect(func(): print("(verrouillé / à venir) : " + nom_capture))

	# --- Focus clavier initial sur la première tuile ---
	if premier_bouton != null:
		premier_bouton.grab_focus()

	# --- Bouton roue crantée (réglages adulte) en haut à droite ---
	_creer_bouton_reglages()


## Crée un bouton-tuile carré avec couleur de fond et coins arrondis.
func _creer_tuile(libelle: String, couleur: Color) -> Button:
	var btn := Button.new()
	btn.text = libelle
	btn.custom_minimum_size = Vector2(220, 220)
	btn.add_theme_font_size_override("font_size", 32)

	# Style normal
	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = couleur
	style_normal.corner_radius_top_left    = 20
	style_normal.corner_radius_top_right   = 20
	style_normal.corner_radius_bottom_left  = 20
	style_normal.corner_radius_bottom_right = 20
	btn.add_theme_stylebox_override("normal", style_normal)

	# Style hover (légèrement plus clair)
	var style_hover := StyleBoxFlat.new()
	style_hover.bg_color = couleur.lightened(0.15)
	style_hover.corner_radius_top_left    = 20
	style_hover.corner_radius_top_right   = 20
	style_hover.corner_radius_bottom_left  = 20
	style_hover.corner_radius_bottom_right = 20
	btn.add_theme_stylebox_override("hover", style_hover)

	# Style focus (bordure visible pour accessibilité clavier)
	var style_focus := StyleBoxFlat.new()
	style_focus.bg_color = couleur.lightened(0.10)
	style_focus.border_width_top    = 4
	style_focus.border_width_bottom = 4
	style_focus.border_width_left   = 4
	style_focus.border_width_right  = 4
	style_focus.border_color = Color(1.0, 1.0, 0.2)  # jaune vif pour accessibilité
	style_focus.corner_radius_top_left    = 20
	style_focus.corner_radius_top_right   = 20
	style_focus.corner_radius_bottom_left  = 20
	style_focus.corner_radius_bottom_right = 20
	btn.add_theme_stylebox_override("focus", style_focus)

	# Style pressed (légèrement assombri)
	var style_pressed := StyleBoxFlat.new()
	style_pressed.bg_color = couleur.darkened(0.15)
	style_pressed.corner_radius_top_left    = 20
	style_pressed.corner_radius_top_right   = 20
	style_pressed.corner_radius_bottom_left  = 20
	style_pressed.corner_radius_bottom_right = 20
	btn.add_theme_stylebox_override("pressed", style_pressed)

	# Couleur du texte en blanc pour le contraste
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	btn.add_theme_color_override("font_focus_color", Color.WHITE)

	return btn


## Navigue vers l'écran placeholder de l'activité "Souris".
func _aller_placeholder() -> void:
	get_tree().change_scene_to_file("res://scenes/placeholder.tscn")


## Crée et positionne le bouton roue crantée (accès réglages adulte) en haut à droite.
func _creer_bouton_reglages() -> void:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(72, 72)
	btn.text = ""  # pas de texte, icône dessinée par code
	btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn.position = Vector2(-80, 8)  # décalage depuis le coin haut-droit

	# Style normal : cercle gris neutre
	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = Color(0.45, 0.45, 0.50)
	style_normal.corner_radius_top_left    = 36
	style_normal.corner_radius_top_right   = 36
	style_normal.corner_radius_bottom_left  = 36
	style_normal.corner_radius_bottom_right = 36
	btn.add_theme_stylebox_override("normal", style_normal)

	# Style hover
	var style_hover := StyleBoxFlat.new()
	style_hover.bg_color = Color(0.55, 0.55, 0.60)
	style_hover.corner_radius_top_left    = 36
	style_hover.corner_radius_top_right   = 36
	style_hover.corner_radius_bottom_left  = 36
	style_hover.corner_radius_bottom_right = 36
	btn.add_theme_stylebox_override("hover", style_hover)

	# Style focus (bordure jaune accessible)
	var style_focus := StyleBoxFlat.new()
	style_focus.bg_color = Color(0.50, 0.50, 0.55)
	style_focus.border_width_top    = 4
	style_focus.border_width_bottom = 4
	style_focus.border_width_left   = 4
	style_focus.border_width_right  = 4
	style_focus.border_color = Color(1.0, 1.0, 0.2)
	style_focus.corner_radius_top_left    = 36
	style_focus.corner_radius_top_right   = 36
	style_focus.corner_radius_bottom_left  = 36
	style_focus.corner_radius_bottom_right = 36
	btn.add_theme_stylebox_override("focus", style_focus)

	# Style pressed
	var style_pressed := StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.35, 0.35, 0.40)
	style_pressed.corner_radius_top_left    = 36
	style_pressed.corner_radius_top_right   = 36
	style_pressed.corner_radius_bottom_left  = 36
	style_pressed.corner_radius_bottom_right = 36
	btn.add_theme_stylebox_override("pressed", style_pressed)

	# Icône engrenage dessinée par code (Control enfant)
	var icone := _IcôneEngrenage.new()
	icone.set_anchors_preset(Control.PRESET_FULL_RECT)
	icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(icone)

	btn.pressed.connect(_aller_reglages)
	# Le bouton ne prend pas le focus au démarrage (focus_mode = FOCUS_ALL par défaut,
	# mais on ne l'appelle pas grab_focus → la tuile "Souris" garde le focus initial)
	add_child(btn)


## Navigue vers l'écran de saisie du code PIN.
func _aller_reglages() -> void:
	get_tree().change_scene_to_file("res://scenes/pin_gate.tscn")


## Nœud interne qui dessine l'icône d'engrenage en blanc dans _draw().
class _IcôneEngrenage extends Control:
	func _draw() -> void:
		var centre := size / 2.0
		var r_ext := minf(size.x, size.y) * 0.38   # rayon corps externe
		var r_int := r_ext * 0.55                   # trou central
		var nb_dents := 8
		var h_dent := r_ext * 0.32                  # hauteur d'une dent
		var w_dent := r_ext * 0.28                  # demi-largeur d'une dent

		# Corps principal de l'engrenage (cercle)
		draw_circle(centre, r_ext, Color.WHITE)

		# Dents rectangulaires autour du cercle
		for i in range(nb_dents):
			var angle := (2.0 * PI / nb_dents) * i
			var dir := Vector2(cos(angle), sin(angle))
			var perp := Vector2(-dir.y, dir.x)
			# Les quatre coins de la dent dans l'espace local
			var p1 := centre + dir * r_ext       - perp * w_dent
			var p2 := centre + dir * r_ext       + perp * w_dent
			var p3 := centre + dir * (r_ext + h_dent) + perp * w_dent
			var p4 := centre + dir * (r_ext + h_dent) - perp * w_dent
			draw_colored_polygon(PackedVector2Array([p1, p2, p3, p4]), Color.WHITE)

		# Trou central (fond du bouton = gris neutre)
		draw_circle(centre, r_int, Color(0.45, 0.45, 0.50))
