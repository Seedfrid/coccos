## Écran de saisie du code PIN — protège l'accès aux réglages adulte,
## et (option) le bouton éteindre.
## Le PIN est lu/écrit dans user://config.cfg, section [adulte], clé "pin".
## Défaut : "1234" (créé automatiquement si absent).
## Lecture du PIN déléguée au helper centralisé PinConfig.
## Saisie au clavier physique acceptée : chiffres (rangée du haut et pavé
## numérique), retour arrière = effacer, Entrée = valider.
extends Control

# Helper centralisé pour la gestion du PIN
const PinConfig = preload("res://scripts/pin_config.gd")
const Lang = preload("res://scripts/lang.gd")

## Action exécutée après un code correct : "reglages" (défaut) ou "eteindre"
## (armée par le bureau quand le bouton éteindre est protégé par le PIN).
## Consommée à chaque passage — retombe toujours sur "reglages" en sortant.
static var action_apres := "reglages"

# Code saisi par l'utilisateur (chaîne de chiffres, max 4 caractères)
var _saisie: String = ""

# Label affichant les points masqués (● par chiffre saisi)
var _label_masque: Label

# Label d'erreur (affiché en rouge si mauvais code)
var _label_erreur: Label


func _ready() -> void:
	# --- Initialisation du fichier de configuration si nécessaire ---
	PinConfig.lire_pin()

	# --- Fond plein doux (bleu-gris foncé) ---
	var fond := ColorRect.new()
	fond.color = Color(0.18, 0.22, 0.35)
	fond.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fond)

	# --- Conteneur vertical principal centré ---
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centre)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 28)
	centre.add_child(vbox)

	# --- Titre (selon ce que le code protège) ---
	var titre := Label.new()
	match action_apres:
		"eteindre":
			titre.text = Lang.t("pin_titre_eteindre")
		"classeur":
			titre.text = Lang.t("pin_titre_classeur")
		_:
			titre.text = Lang.t("pin_titre_reglages")
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.add_theme_font_size_override("font_size", 42)
	titre.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(titre)

	# Aide au premier contact : tant que le code n'a pas été personnalisé,
	# l'écran dit lequel c'est. Dès qu'il est changé, plus un mot.
	if PinConfig.lire_pin() == "1234":
		var aide := Label.new()
		aide.text = Lang.t("pin_aide_defaut")
		aide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		aide.add_theme_font_size_override("font_size", 22)
		aide.add_theme_color_override("font_color", Color(0.75, 0.85, 0.80))
		vbox.add_child(aide)

	# --- Affichage du code masqué ---
	_label_masque = Label.new()
	_label_masque.text = ""
	_label_masque.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_masque.add_theme_font_size_override("font_size", 52)
	_label_masque.add_theme_color_override("font_color", Color(0.95, 0.85, 0.20))
	_label_masque.custom_minimum_size = Vector2(220, 70)
	vbox.add_child(_label_masque)

	# --- Label d'erreur (invisible par défaut) ---
	_label_erreur = Label.new()
	_label_erreur.text = Lang.t("pin_erreur")
	_label_erreur.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_erreur.add_theme_font_size_override("font_size", 30)
	_label_erreur.add_theme_color_override("font_color", Color(1.0, 0.30, 0.25))
	_label_erreur.visible = false
	vbox.add_child(_label_erreur)

	# --- Pavé numérique (GridContainer 3 colonnes) ---
	var grille := GridContainer.new()
	grille.columns = 3
	grille.add_theme_constant_override("h_separation", 12)
	grille.add_theme_constant_override("v_separation", 12)
	vbox.add_child(grille)

	# Chiffres 1-9 puis une ligne spéciale : Effacer / 0 / Valider
	var premier_btn: Button = null
	for i in range(1, 10):
		var btn := _creer_touche(str(i), Color(0.25, 0.45, 0.75))
		btn.pressed.connect(_saisir_chiffre.bind(str(i)))
		grille.add_child(btn)
		if i == 1:
			premier_btn = btn

	# Bouton Effacer
	var btn_eff := _creer_touche(Lang.t("pin_effacer"), Color(0.55, 0.30, 0.20))
	btn_eff.pressed.connect(_effacer_dernier)
	grille.add_child(btn_eff)

	# Bouton 0
	var btn_zero := _creer_touche("0", Color(0.25, 0.45, 0.75))
	btn_zero.pressed.connect(_saisir_chiffre.bind("0"))
	grille.add_child(btn_zero)

	# Bouton Valider
	var btn_val := _creer_touche(Lang.t("pin_valider"), Color(0.20, 0.60, 0.35))
	btn_val.pressed.connect(_valider)
	grille.add_child(btn_val)

	# --- Bouton retour ---
	var btn_retour := _creer_touche(Lang.t("pin_retour"), Color(0.40, 0.40, 0.45))
	btn_retour.custom_minimum_size = Vector2(300, 70)
	btn_retour.add_theme_font_size_override("font_size", 28)
	btn_retour.pressed.connect(_retour_tableau_de_bord)
	vbox.add_child(btn_retour)

	# --- Focus initial sur la touche « 1 » ---
	if premier_btn != null:
		premier_btn.grab_focus()


## Échap = revenir au bureau sans entrer dans les réglages (réflexe universel).
## Le clavier physique fonctionne aussi : chiffres (rangée du haut et pavé
## numérique), retour arrière = effacer, Entrée = valider. Les touches gérées
## sont consommées pour ne pas déclencher en plus le bouton qui a le focus.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_retour_tableau_de_bord()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		# Consommer AVANT d'agir : _valider() peut changer de scène (nœud hors
		# arbre → plus de viewport), et le bouton au focus ne doit pas réagir.
		var chiffre := _chiffre_de_touche(event)
		if chiffre != "":
			get_viewport().set_input_as_handled()
			_saisir_chiffre(chiffre)
		elif event.keycode == KEY_BACKSPACE:
			get_viewport().set_input_as_handled()
			_effacer_dernier()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			get_viewport().set_input_as_handled()
			_valider()


## Chiffre porté par la touche, ou "" si la touche n'en est pas un.
## La position physique prime : sur AZERTY, la rangée du haut donne le chiffre
## même sans Maj (comme un digicode). Pavé numérique reconnu avec ou sans
## verrouillage. Repli sur le caractère tapé (toute disposition exotique).
func _chiffre_de_touche(event: InputEventKey) -> String:
	for code in [event.physical_keycode, event.keycode]:
		if code >= KEY_0 and code <= KEY_9:
			return str(code - KEY_0)
		if code >= KEY_KP_0 and code <= KEY_KP_9:
			return str(code - KEY_KP_0)
	if event.unicode >= 48 and event.unicode <= 57:
		return str(event.unicode - 48)
	return ""


## Crée un bouton stylisé pour le pavé numérique.
func _creer_touche(libelle: String, couleur: Color) -> Button:
	var btn := Button.new()
	btn.text = libelle
	btn.custom_minimum_size = Vector2(90, 90)
	btn.add_theme_font_size_override("font_size", 36)

	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = couleur
	style_normal.corner_radius_top_left    = 12
	style_normal.corner_radius_top_right   = 12
	style_normal.corner_radius_bottom_left  = 12
	style_normal.corner_radius_bottom_right = 12
	btn.add_theme_stylebox_override("normal", style_normal)

	var style_hover := StyleBoxFlat.new()
	style_hover.bg_color = couleur.lightened(0.15)
	style_hover.corner_radius_top_left    = 12
	style_hover.corner_radius_top_right   = 12
	style_hover.corner_radius_bottom_left  = 12
	style_hover.corner_radius_bottom_right = 12
	btn.add_theme_stylebox_override("hover", style_hover)

	var style_focus := StyleBoxFlat.new()
	style_focus.bg_color = couleur.lightened(0.10)
	style_focus.border_width_top    = 4
	style_focus.border_width_bottom = 4
	style_focus.border_width_left   = 4
	style_focus.border_width_right  = 4
	style_focus.border_color = Color(1.0, 1.0, 0.2)
	style_focus.corner_radius_top_left    = 12
	style_focus.corner_radius_top_right   = 12
	style_focus.corner_radius_bottom_left  = 12
	style_focus.corner_radius_bottom_right = 12
	btn.add_theme_stylebox_override("focus", style_focus)

	var style_pressed := StyleBoxFlat.new()
	style_pressed.bg_color = couleur.darkened(0.15)
	style_pressed.corner_radius_top_left    = 12
	style_pressed.corner_radius_top_right   = 12
	style_pressed.corner_radius_bottom_left  = 12
	style_pressed.corner_radius_bottom_right = 12
	btn.add_theme_stylebox_override("pressed", style_pressed)

	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	btn.add_theme_color_override("font_focus_color", Color.WHITE)

	return btn


## Ajoute un chiffre à la saisie (max 4 caractères).
func _saisir_chiffre(chiffre: String) -> void:
	if _saisie.length() >= 4:
		return
	_saisie += chiffre
	_label_masque.text = "*".repeat(_saisie.length())
	_label_erreur.visible = false


## Efface le dernier chiffre saisi.
func _effacer_dernier() -> void:
	if _saisie.length() > 0:
		_saisie = _saisie.substr(0, _saisie.length() - 1)
		_label_masque.text = "*".repeat(_saisie.length())
	_label_erreur.visible = false


## Valide la saisie : navigue (ou éteint), sinon affiche une erreur.
func _valider() -> void:
	var pin_attendu := PinConfig.lire_pin()
	if _saisie == pin_attendu:
		var action := action_apres
		action_apres = "reglages"  # consommée : le prochain passage redevient normal
		if action == "eteindre":
			_eteindre()
		elif action == "classeur":
			# Déverrouille le mode édition du classeur et y retourne
			(load("res://scripts/classeur/classeur.gd") as GDScript).deverrouille = true
			get_tree().change_scene_to_file("res://scenes/classeur.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/adult_settings.tscn")
	else:
		_label_erreur.visible = true
		_saisie = ""
		_label_masque.text = ""


## Quitte l'OS (même comportement que le bureau : retour vitrine sur le web).
func _eteindre() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.location.href = '../';")
	else:
		get_tree().quit()


## Retourne d'où l'on vient sans entrer dans les réglages (ni éteindre) :
## le classeur si le code protégeait son cadenas, le bureau sinon.
func _retour_tableau_de_bord() -> void:
	var action := action_apres
	action_apres = "reglages"  # annulé : désarmer l'action en attente
	if action == "classeur":
		get_tree().change_scene_to_file("res://scenes/classeur.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/bureau.tscn")


