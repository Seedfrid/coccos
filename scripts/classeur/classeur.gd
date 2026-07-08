## Mon classeur 💬 — classeur de communication CAA numérique (spec :
## DOCS/specs/spec-classeur-communication.md — chantier prioritaire 2026-07-07).
## Le classeur physique à vignettes scratch d'Isabella, dans CoccOs : l'enfant
## touche une vignette → LA VOIX LA DIT (+ rebond doux). Une vignette à la
## fois (v1, décision Freddy) — la bande-phrase viendra en v2.
##
## Depuis l'évolution « créateur de plaquettes » (2026-07-07) : les données
## vivent dans la BANQUE (scripts/classeur/banque.gd — vignettes taguées par
## catégories, une catégorie = une plaquette 6×4 sans cases blanches). Les
## planches TLAb déposées s'importent automatiquement dans la banque.
##
## Deux vues dans le même écran :
##   - accueil : les catégories en grosses tuiles
##   - plaquette : la grille de vignettes (positions fidèles au papier école)
## Navigation : tuile → plaquette · flèche (haut gauche) → accueil ·
## maison (haut droit) → bureau · Échap = remonter d'un niveau.
##
## 🔒 CADENAS (bas gauche, sur une plaquette) : protégé par le code adulte
## (pin_gate, action « classeur »). Déverrouillé, les vignettes se DÉPLACENT
## à la souris/au doigt (dépôt = aimanté à l'emplacement le plus proche,
## échange si occupé) et ne parlent pas ; reverrouiller est libre.
##
## C'est un OUTIL DE COMMUNICATION, pas un jeu : aucun stimulus parasite
## (pas de traînée, pas d'effets de clic) — seul le curseur OS accompagne.
## Dépendances partagées : fond.gd, lang.gd, voix.gd, effets/curseur.gd, pin_gate.
extends Control

const Fond := preload("res://scripts/fond.gd")
const Lang := preload("res://scripts/lang.gd")
const Voix := preload("res://scripts/voix.gd")
const CurseurOS := preload("res://scripts/effets/curseur.gd")
const Banque := preload("res://scripts/classeur/banque.gd")
const PinGate := preload("res://scripts/pin_gate.gd")
const CHEMIN_BUREAU := "res://scenes/bureau.tscn"
const CHEMIN_PIN := "res://scenes/pin_gate.tscn"

const MARGE_HAUT := 100.0    # bande des boutons de navigation
const MARGE := 24.0
const COULEUR_BOUTON_QUITTER := Color(0.85, 0.35, 0.30)
const COULEUR_BOUTON_RETOUR := Color(0.40, 0.50, 0.65)
const COULEUR_CADENAS := Color(0.55, 0.45, 0.25)
const COULEUR_CADENAS_OUVERT := Color(0.85, 0.65, 0.15)
## Couleurs des tuiles de l'accueil (cycle doux)
const COULEURS_TUILES: Array[Color] = [
	Color(0.90, 0.40, 0.45), Color(0.95, 0.55, 0.15), Color(0.25, 0.65, 0.35),
	Color(0.20, 0.60, 0.90), Color(0.45, 0.40, 0.85), Color(0.20, 0.70, 0.65),
]

## Posés par pin_gate (code adulte correct) avant de revenir sur cette scène.
static var deverrouille := false
static var categorie_reprise := ""

var _banque: RefCounted
var _contenu: Control = null      # la vue courante (accueil ou plaquette)
var _btn_retour: Button = null    # flèche → accueil (visible sur une plaquette)
var _btn_cadenas: Button = null
var _icone_cadenas: Control = null
var _curseur: Node2D
var _categorie := ""              # catégorie affichée ("" = accueil)
var _edition := false             # cadenas déverrouillé : les vignettes se déplacent
var _echelle := 1.0
var _origine := Vector2.ZERO


func _ready() -> void:
	Fond.appliquer(self)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_creer_bouton_quitter()
	_creer_bouton_retour()
	_creer_bouton_cadenas()

	var couche_curseur := CanvasLayer.new()
	couche_curseur.layer = 10
	add_child(couche_curseur)
	_curseur = CurseurOS.new()
	couche_curseur.add_child(_curseur)
	_curseur.position = get_viewport().get_mouse_position()

	Voix.amorcer()
	_banque = Banque.charger()

	# Retour du code adulte : reprendre la plaquette quittée, déverrouillée
	_edition = deverrouille
	deverrouille = false
	var reprise := categorie_reprise
	categorie_reprise = ""
	if reprise != "" and reprise in _banque.categories():
		_montrer_planche(reprise)
	else:
		_edition = false
		_montrer_accueil()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _btn_retour.visible:
			_montrer_accueil()
		else:
			_quitter()
		return
	if event is InputEventMouseMotion:
		_curseur.position = event.position
	elif event is InputEventMouseButton and event.pressed:
		_curseur.pulser()


# --- Vue accueil : une tuile par catégorie -------------------------------------

func _montrer_accueil() -> void:
	_vider_contenu()
	_categorie = ""
	_edition = false
	_btn_retour.visible = false
	_btn_cadenas.visible = false

	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.offset_top = MARGE_HAUT
	# La vue est un simple support : elle ne doit JAMAIS avaler les clics
	# destinés aux boutons de navigation ajoutés avant elle dans l'arbre
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_contenu = centre
	add_child(centre)

	var colonne := VBoxContainer.new()
	colonne.alignment = BoxContainer.ALIGNMENT_CENTER
	colonne.add_theme_constant_override("separation", 30)
	centre.add_child(colonne)

	var titre := Label.new()
	titre.text = Lang.t("bureau_app_classeur")
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.add_theme_font_size_override("font_size", 52)
	titre.add_theme_color_override("font_color", Color.WHITE)
	titre.add_theme_constant_override("outline_size", 10)
	titre.add_theme_color_override("font_outline_color", Color(0.10, 0.20, 0.15, 0.85))
	colonne.add_child(titre)

	var grille := GridContainer.new()
	grille.columns = 3
	grille.add_theme_constant_override("h_separation", 26)
	grille.add_theme_constant_override("v_separation", 26)
	colonne.add_child(grille)

	var rang := 0
	for nom in _banque.categories():
		grille.add_child(_creer_tuile(nom, COULEURS_TUILES[rang % COULEURS_TUILES.size()]))
		rang += 1


## Grosse tuile d'accueil : le nom de la catégorie, en très lisible.
func _creer_tuile(nom: String, couleur: Color) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(320, 150)
	btn.focus_mode = Control.FOCUS_NONE
	btn.text = nom.capitalize()
	btn.add_theme_font_size_override("font_size", 38)
	for etat in ["font_color", "font_hover_color", "font_pressed_color"]:
		btn.add_theme_color_override(etat, Color.WHITE)
	for etat in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = couleur
		if etat == "hover":
			style.bg_color = couleur.lightened(0.12)
		elif etat == "pressed":
			style.bg_color = couleur.darkened(0.15)
		style.set_corner_radius_all(24)
		btn.add_theme_stylebox_override(etat, style)
	btn.pressed.connect(_montrer_planche.bind(nom))
	return btn


# --- Vue plaquette : la grille de vignettes --------------------------------------

func _montrer_planche(categorie: String) -> void:
	_vider_contenu()
	_categorie = categorie
	_btn_retour.visible = true
	_btn_cadenas.visible = true
	_icone_cadenas.queue_redraw()

	var zone := Control.new()
	zone.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Support de positionnement : transparent aux clics (les vignettes, elles,
	# sont des Buttons) — sinon la flèche retour et la maison seraient bloquées
	zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_contenu = zone
	add_child(zone)

	# Échelle de fidélité : la page A4 paysage remplit l'espace disponible
	var page := Vector2(297.0, 210.0)
	var disponible := get_viewport_rect().size - Vector2(MARGE * 2.0, MARGE_HAUT + MARGE)
	_echelle = minf(disponible.x / page.x, disponible.y / page.y)
	_origine = Vector2(
		(get_viewport_rect().size.x - page.x * _echelle) / 2.0,
		MARGE_HAUT + (disponible.y - page.y * _echelle) / 2.0)

	for entree in _banque.plaquette(categorie):
		var vignette := _Vignette.new()
		vignette.id = entree["id"]
		vignette.texture = entree["texture"]
		vignette.libelle = entree["mot"]
		vignette.edition = _edition
		vignette.position = _origine + Banque.position_emplacement(entree["index"]) * _echelle
		vignette.size = Banque.CELLULE * _echelle
		vignette.dite.connect(_dire)
		vignette.deposee.connect(_deposer)
		zone.add_child(vignette)


## Le cœur du module : la vignette touchée est DITE par la voix.
## Enregistrement user://lang/<code>/voix/phrases/<libellé>.wav s'il existe
## (la voix de papa/maman), synthèse vocale sinon.
func _dire(libelle: String) -> void:
	if libelle != "":
		Voix.dire(self, libelle, "phrases")


## Dépôt d'une vignette déplacée (mode édition) : aimantée à l'emplacement le
## plus proche — s'il est occupé, les deux vignettes s'échangent.
func _deposer(id: int, coin_global: Vector2) -> void:
	var point_page := (coin_global - _origine) / _echelle
	_banque.placer(id, _categorie, Banque.emplacement_proche(point_page))
	_montrer_planche(_categorie)  # re-pose tout le monde proprement


# --- Cadenas : verrouiller / déverrouiller le déplacement --------------------------

func _au_cadenas() -> void:
	if _edition:
		_edition = false
		_montrer_planche(_categorie)  # reverrouiller est libre
	else:
		# Le code adulte garde la porte — pin_gate reviendra ici, déverrouillé
		PinGate.action_apres = "classeur"
		categorie_reprise = _categorie
		Voix.arreter(self)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().change_scene_to_file(CHEMIN_PIN)


func _creer_bouton_cadenas() -> void:
	_btn_cadenas = Button.new()
	_btn_cadenas.custom_minimum_size = Vector2(72, 72)
	_btn_cadenas.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_btn_cadenas.position = Vector2(16, -88)
	_btn_cadenas.focus_mode = Control.FOCUS_NONE
	for etat in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = COULEUR_CADENAS
		if etat == "hover":
			style.bg_color = COULEUR_CADENAS.lightened(0.15)
		elif etat == "pressed":
			style.bg_color = COULEUR_CADENAS.darkened(0.15)
		style.set_corner_radius_all(36)
		_btn_cadenas.add_theme_stylebox_override(etat, style)
	_icone_cadenas = _IconeCadenas.new()
	_icone_cadenas.proprietaire = self
	_icone_cadenas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_icone_cadenas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_btn_cadenas.add_child(_icone_cadenas)
	_btn_cadenas.pressed.connect(_au_cadenas)
	_btn_cadenas.visible = false
	add_child(_btn_cadenas)


# --- Navigation ----------------------------------------------------------------

func _vider_contenu() -> void:
	if _contenu != null:
		_contenu.queue_free()
		_contenu = null


func _creer_bouton_retour() -> void:
	_btn_retour = Button.new()
	_btn_retour.custom_minimum_size = Vector2(72, 72)
	_btn_retour.position = Vector2(16, 16)
	_btn_retour.focus_mode = Control.FOCUS_NONE
	for etat in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = COULEUR_BOUTON_RETOUR
		if etat == "hover":
			style.bg_color = COULEUR_BOUTON_RETOUR.lightened(0.15)
		elif etat == "pressed":
			style.bg_color = COULEUR_BOUTON_RETOUR.darkened(0.15)
		style.set_corner_radius_all(36)
		_btn_retour.add_theme_stylebox_override(etat, style)
	var fleche := _IconeFleche.new()
	fleche.set_anchors_preset(Control.PRESET_FULL_RECT)
	fleche.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_btn_retour.add_child(fleche)
	_btn_retour.pressed.connect(_montrer_accueil)
	_btn_retour.visible = false
	add_child(_btn_retour)


func _creer_bouton_quitter() -> void:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(72, 72)
	btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn.position = Vector2(-88, 16)
	btn.focus_mode = Control.FOCUS_NONE
	for etat in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = COULEUR_BOUTON_QUITTER
		if etat == "hover":
			style.bg_color = COULEUR_BOUTON_QUITTER.lightened(0.15)
		elif etat == "pressed":
			style.bg_color = COULEUR_BOUTON_QUITTER.darkened(0.15)
		style.set_corner_radius_all(36)
		btn.add_theme_stylebox_override(etat, style)
	var icone := _IconeMaison.new()
	icone.set_anchors_preset(Control.PRESET_FULL_RECT)
	icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(icone)
	btn.pressed.connect(_quitter)
	add_child(btn)


func _quitter() -> void:
	Voix.arreter(self)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if ResourceLoader.exists(CHEMIN_BUREAU):
		get_tree().change_scene_to_file(CHEMIN_BUREAU)
	else:
		get_tree().quit()


# --- La vignette : carte blanche, pictogramme + mot, qui parle au tap ------------
# En mode édition elle ne parle pas : elle se DÉPLACE (glisser au doigt/souris).

class _Vignette extends Button:
	signal dite(libelle: String)
	signal deposee(id: int, coin_global: Vector2)

	var id := 0
	var texture: ImageTexture = null
	var libelle := ""
	var fond := Color.WHITE
	var edition := false

	var _en_glisse := false
	var _prise := Vector2.ZERO  # point de prise dans la vignette

	func _ready() -> void:
		focus_mode = Control.FOCUS_NONE
		for etat in ["normal", "hover", "pressed", "focus"]:
			var style := StyleBoxFlat.new()
			style.bg_color = fond if etat != "pressed" else Color(1.0, 0.95, 0.6)
			style.set_corner_radius_all(int(size.y * 0.09))
			style.set_border_width_all(maxi(2, int(size.y * 0.02)))
			# En édition, le cadre passe au jaune : « je peux bouger »
			style.border_color = Color(0.95, 0.72, 0.15) if edition \
					else (Color(0.25, 0.30, 0.38) if etat != "hover" else Color(0.95, 0.72, 0.15))
			add_theme_stylebox_override(etat, style)
		pivot_offset = size / 2.0

		# Pictogramme (haut, ~54 % de la hauteur) + mot en bas — la zone de
		# texte est taillée pour DEUX lignes (« laver les mains » ne se coupe plus)
		if texture != null:
			var picto := TextureRect.new()
			picto.texture = texture
			picto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			picto.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			picto.position = Vector2(size.x * 0.06, size.y * 0.04)
			picto.size = Vector2(size.x * 0.88, size.y * 0.54)
			picto.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(picto)
		var etiquette := Label.new()
		etiquette.text = libelle
		etiquette.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		etiquette.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		etiquette.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		etiquette.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		etiquette.clip_contents = true  # rien ne déborde du cadre de la carte
		etiquette.add_theme_font_size_override("font_size", maxi(11, int(size.y * 0.125)))
		etiquette.add_theme_color_override("font_color", Color(0.12, 0.16, 0.24))
		etiquette.position = Vector2(size.x * 0.03, size.y * 0.59)
		etiquette.size = Vector2(size.x * 0.94, size.y * 0.38)
		etiquette.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(etiquette)

		if not edition:
			pressed.connect(_au_tap)

	## Tap : la vignette parle + rebond doux (prévisible, jamais surprenant)
	func _au_tap() -> void:
		dite.emit(libelle)
		scale = Vector2.ONE * 0.88
		var animation := create_tween()
		animation.tween_property(self, "scale", Vector2.ONE, 0.25) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	## Mode édition : glisser-déposer (la vignette suit le doigt/la souris).
	func _gui_input(event: InputEvent) -> void:
		if not edition:
			return
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_en_glisse = true
				_prise = event.position
				move_to_front()  # la vignette portée passe au-dessus des autres
			elif _en_glisse:
				_en_glisse = false
				deposee.emit(id, global_position)
			accept_event()
		elif event is InputEventMouseMotion and _en_glisse:
			global_position = event.global_position - _prise
			accept_event()


## Cadenas du mode édition : fermé (verrouillé) ou ouvert (les vignettes bougent).
class _IconeCadenas extends Control:
	var proprietaire: Control = null

	func _draw() -> void:
		var centre := size / 2.0
		var u := minf(size.x, size.y) / 2.0
		var ouvert: bool = proprietaire != null and proprietaire._edition
		# Corps du cadenas
		var corps := StyleBoxFlat.new()
		corps.bg_color = Color.WHITE
		corps.set_corner_radius_all(int(u * 0.15))
		corps.draw(get_canvas_item(), Rect2(centre + Vector2(-u * 0.45, -u * 0.05), Vector2(u * 0.9, u * 0.75)))
		# Anse : centrée (cadenas fermé) ou basculée sur le côté (ouvert)
		var centre_anse := centre + Vector2(u * 0.35 if ouvert else 0.0, -u * 0.25)
		draw_arc(centre_anse, u * 0.32, PI, TAU, 20, Color.WHITE, u * 0.14)
		# Trou de serrure (couleur du bouton, par transparence visuelle)
		draw_circle(centre + Vector2(0.0, u * 0.28), u * 0.12, Color(0.55, 0.45, 0.25))


## Flèche vers la gauche (retour à l'accueil du classeur).
class _IconeFleche extends Control:
	func _draw() -> void:
		var centre := size / 2.0
		var u := minf(size.x, size.y) / 2.0
		draw_line(centre + Vector2(-u * 0.35, 0.0), centre + Vector2(u * 0.5, 0.0), Color.WHITE, 6.0)
		draw_colored_polygon(PackedVector2Array([
			centre + Vector2(-u * 0.55, 0.0),
			centre + Vector2(-u * 0.1, -u * 0.4),
			centre + Vector2(-u * 0.1, u * 0.4),
		]), Color.WHITE)


## Petite maison blanche du bouton Quitter (porte = couleur du bouton).
class _IconeMaison extends Control:
	func _draw() -> void:
		var centre := size / 2.0
		var u := minf(size.x, size.y) / 2.0
		draw_colored_polygon(PackedVector2Array([
			centre + Vector2(-u * 0.8, 0.05 * u),
			centre + Vector2(0.0, -u * 0.75),
			centre + Vector2(u * 0.8, 0.05 * u),
		]), Color.WHITE)
		draw_rect(Rect2(centre + Vector2(-u * 0.55, 0.05 * u), Vector2(u * 1.1, u * 0.7)), Color.WHITE)
		draw_rect(Rect2(centre + Vector2(-u * 0.15, u * 0.3), Vector2(u * 0.3, u * 0.45)), Color(0.85, 0.35, 0.30))
