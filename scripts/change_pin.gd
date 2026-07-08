## Écran de changement du code PIN adulte.
## Deux phases : saisie du nouveau code → confirmation → enregistrement.
## Accessible depuis les réglages adulte.
## Saisie au clavier physique acceptée : chiffres (rangée du haut et pavé
## numérique), retour arrière = effacer, Entrée = valider.
extends Control

# Helper centralisé pour la gestion du PIN
const PinConfig = preload("res://scripts/pin_config.gd")
const Lang = preload("res://scripts/lang.gd")

# Saisie courante (chaîne de chiffres, max 4)
var _saisie: String = ""

# Code mémorisé en phase 1
var _code_phase1: String = ""

# Phase courante : 1 = saisir nouveau code, 2 = confirmer
var _phase: int = 1

# Références aux nœuds dynamiques
var _label_masque: Label
var _label_titre: Label
var _label_message: Label


func _ready() -> void:
	# --- Fond sobre (bleu-ardoise foncé, atmosphère adulte) ---
	var fond := ColorRect.new()
	fond.color = Color(0.14, 0.18, 0.30)
	fond.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fond)

	# --- Conteneur vertical centré ---
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centre)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	centre.add_child(vbox)

	# --- Titre dynamique (change selon la phase) ---
	_label_titre = Label.new()
	_label_titre.text = Lang.t("chpin_titre_nouveau")
	_label_titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_titre.add_theme_font_size_override("font_size", 40)
	_label_titre.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(_label_titre)

	# --- Affichage masqué du code saisi (● par chiffre) ---
	_label_masque = Label.new()
	_label_masque.text = ""
	_label_masque.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_masque.add_theme_font_size_override("font_size", 52)
	_label_masque.add_theme_color_override("font_color", Color(0.95, 0.85, 0.20))
	_label_masque.custom_minimum_size = Vector2(220, 70)
	vbox.add_child(_label_masque)

	# --- Label message (erreur en rouge, succès en vert) ---
	_label_message = Label.new()
	_label_message.text = ""
	_label_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_message.add_theme_font_size_override("font_size", 28)
	_label_message.add_theme_color_override("font_color", Color(1.0, 0.30, 0.25))
	_label_message.visible = false
	vbox.add_child(_label_message)

	# --- Pavé numérique (GridContainer 3 colonnes) ---
	var grille := GridContainer.new()
	grille.columns = 3
	grille.add_theme_constant_override("h_separation", 12)
	grille.add_theme_constant_override("v_separation", 12)
	vbox.add_child(grille)

	# Chiffres 1-9 puis ligne spéciale : Effacer / 0 / Valider
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

	# --- Bouton Annuler (accessible à tout moment) ---
	var btn_annuler := _creer_touche(Lang.t("chpin_annuler"), Color(0.40, 0.40, 0.45))
	btn_annuler.custom_minimum_size = Vector2(300, 70)
	btn_annuler.add_theme_font_size_override("font_size", 28)
	btn_annuler.pressed.connect(_annuler)
	vbox.add_child(btn_annuler)

	# --- Focus clavier initial sur la touche « 1 » ---
	if premier_btn != null:
		premier_btn.grab_focus()


## Crée un bouton stylisé pour le pavé numérique (même style que pin_gate).
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


## Ajoute un chiffre à la saisie courante (max 4 caractères).
func _saisir_chiffre(chiffre: String) -> void:
	if _saisie.length() >= 4:
		return
	_saisie += chiffre
	_label_masque.text = "*".repeat(_saisie.length())
	_label_message.visible = false


## Efface le dernier chiffre saisi.
func _effacer_dernier() -> void:
	if _saisie.length() > 0:
		_saisie = _saisie.substr(0, _saisie.length() - 1)
		_label_masque.text = "*".repeat(_saisie.length())
	_label_message.visible = false


## Valide la saisie de la phase courante.
func _valider() -> void:
	# Vérification : exactement 4 chiffres requis
	if _saisie.length() != 4:
		_afficher_message(Lang.t("chpin_erreur_4_chiffres"), false)
		return

	if _phase == 1:
		# Phase 1 : mémoriser le code et passer en phase 2
		_code_phase1 = _saisie
		_saisie = ""
		_label_masque.text = ""
		_phase = 2
		_label_titre.text = Lang.t("chpin_titre_confirme")
		_label_message.visible = false
	else:
		# Phase 2 : comparer avec le code de la phase 1
		if _saisie == _code_phase1:
			# Codes identiques → enregistrer
			PinConfig.ecrire_pin(_saisie)
			_afficher_message(Lang.t("chpin_succes"), true)
			# Retour automatique aux réglages après un bref délai
			var timer := get_tree().create_timer(1.8)
			timer.timeout.connect(_retour_reglages)
		else:
			# Codes différents → recommencer depuis la phase 1
			_afficher_message(Lang.t("chpin_erreur_differents"), false)
			_reinitialiser()


## Affiche un message de retour (succès en vert, erreur en rouge).
func _afficher_message(texte: String, succes: bool) -> void:
	_label_message.text = texte
	if succes:
		_label_message.add_theme_color_override("font_color", Color(0.20, 0.85, 0.40))
	else:
		_label_message.add_theme_color_override("font_color", Color(1.0, 0.30, 0.25))
	_label_message.visible = true


## Réinitialise complètement la saisie et revient à la phase 1.
func _reinitialiser() -> void:
	_saisie = ""
	_code_phase1 = ""
	_phase = 1
	_label_masque.text = ""
	_label_titre.text = Lang.t("chpin_titre_nouveau")


## Échap = annuler et revenir aux réglages (réflexe universel).
## Le clavier physique fonctionne aussi : chiffres (rangée du haut et pavé
## numérique), retour arrière = effacer, Entrée = valider. Les touches gérées
## sont consommées pour ne pas déclencher en plus le bouton qui a le focus.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_annuler()
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


## Retourne aux réglages adulte sans modifier le PIN.
func _annuler() -> void:
	get_tree().change_scene_to_file("res://scenes/adult_settings.tscn")


## Retourne aux réglages adulte après succès.
func _retour_reglages() -> void:
	get_tree().change_scene_to_file("res://scenes/adult_settings.tscn")
