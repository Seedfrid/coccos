## Icône du bureau enfant : bouton carré arrondi coloré avec pictogramme,
## et libellé blanc en dessous — comme une icône de vrai bureau d'ordinateur.
## Les catégories (`est_dossier`) prennent une forme de dossier à onglet,
## avec le pictogramme posé sur le corps du dossier.
## Un simple clic lance l'application (adapté aux enfants : pas de double-clic).
extends VBoxContainer

signal lancee(id: String)

const UIStyle := preload("res://scripts/ui_style.gd")
const Pictogramme := preload("res://scripts/pictogramme.gd")

var id := ""
var nom := ""
var couleur := Color(0.3, 0.5, 0.8)
var est_dossier := false  # true = catégorie : dessinée comme un dossier à onglet
var picto := ""  # pictogramme à dessiner si différent de l'id (applis externes)

var _btn: Button


func _ready() -> void:
	custom_minimum_size = Vector2(150, 0)
	add_theme_constant_override("separation", 6)

	# Bouton carré centré (le pictogramme est un enfant plein cadre avec marge)
	var centre := CenterContainer.new()
	add_child(centre)
	_btn = Button.new()
	_btn.custom_minimum_size = Vector2(104, 104)
	centre.add_child(_btn)

	var picto_ctrl: Control = Pictogramme.new()
	picto_ctrl.id = picto if picto != "" else id
	picto_ctrl.couleur_creux = couleur.darkened(0.25)
	picto_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)

	if est_dossier:
		# Bouton transparent (le dossier fait le visuel), focus = bordure seule
		var vide := StyleBoxEmpty.new()
		for etat in ["normal", "hover", "pressed"]:
			_btn.add_theme_stylebox_override(etat, vide)
		var focus := UIStyle.creer_style(Color(0, 0, 0, 0), 24, true)
		focus.draw_center = false
		_btn.add_theme_stylebox_override("focus", focus)

		var dossier := _IconeDossier.new()
		dossier.couleur = couleur
		dossier.set_anchors_preset(Control.PRESET_FULL_RECT)
		dossier.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_btn.add_child(dossier)
		# Survol : le dossier s'éclaircit (retour visuel du bouton transparent)
		_btn.mouse_entered.connect(func() -> void:
			dossier.couleur = couleur.lightened(0.15)
			dossier.queue_redraw())
		_btn.mouse_exited.connect(func() -> void:
			dossier.couleur = couleur
			dossier.queue_redraw())

		# Pictogramme plus petit, posé sur le corps du dossier
		picto_ctrl.offset_left = 26
		picto_ctrl.offset_top = 38
		picto_ctrl.offset_right = -26
		picto_ctrl.offset_bottom = -12
	else:
		UIStyle.styliser(_btn, couleur, 24)
		picto_ctrl.offset_left = 16
		picto_ctrl.offset_top = 16
		picto_ctrl.offset_right = -16
		picto_ctrl.offset_bottom = -16
	_btn.add_child(picto_ctrl)

	# Libellé sous l'icône, blanc à contour sombre (lisible sur la prairie)
	var libelle := Label.new()
	libelle.text = nom
	libelle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	libelle.add_theme_font_size_override("font_size", 24)
	libelle.add_theme_color_override("font_color", Color.WHITE)
	libelle.add_theme_color_override("font_outline_color", Color(0.10, 0.12, 0.10))
	libelle.add_theme_constant_override("outline_size", 6)
	add_child(libelle)

	_btn.pressed.connect(func() -> void: lancee.emit(id))


## Donne le focus clavier au bouton de l'icône (accessibilité).
func focus() -> void:
	_btn.grab_focus()


## Dossier à onglet dessiné par code (couleur de la catégorie).
class _IconeDossier extends Control:
	var couleur := Color(0.3, 0.5, 0.8)

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var ci := get_canvas_item()
		# Onglet (haut gauche, un peu plus sombre)
		var onglet := StyleBoxFlat.new()
		onglet.bg_color = couleur.darkened(0.18)
		onglet.corner_radius_top_left = 10
		onglet.corner_radius_top_right = 10
		onglet.draw(ci, Rect2(w * 0.05, h * 0.03, w * 0.44, h * 0.22))
		# Corps du dossier
		var corps := StyleBoxFlat.new()
		corps.bg_color = couleur
		corps.set_corner_radius_all(12)
		corps.draw(ci, Rect2(0.0, h * 0.16, w, h * 0.84))
		# Liseré supérieur du corps (donne le relief du rabat)
		var rabat := StyleBoxFlat.new()
		rabat.bg_color = couleur.lightened(0.12)
		rabat.corner_radius_top_left = 12
		rabat.corner_radius_top_right = 12
		rabat.draw(ci, Rect2(0.0, h * 0.16, w, h * 0.12))
