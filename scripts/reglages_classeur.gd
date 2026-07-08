## Sous-écran réglages adulte — section Classeur de communication.
## L'adulte gère ici la banque du classeur (spec-classeur-communication.md,
## évolution « créateur de plaquettes » — Freddy 2026-07-07) :
##   - CATÉGORIES : créer / supprimer (une catégorie = une plaquette 6×4 ;
##     supprimer détague les vignettes, ne les détruit pas)
##   - VIGNETTES : la banque complète en grille ; toucher une vignette ouvre
##     son édition (mot, tags de catégories, suppression) ; « Nouvelle
##     vignette » importe une image (photo du vrai doudou possible) + un mot.
## Suppressions en 2 temps (le bouton devient « Confirmer ? ») — pas de dialogue.
## Le déplacement des vignettes SUR une plaquette se fait dans le classeur
## lui-même (cadenas 🔒). Sauvegarde immédiate à chaque geste.
extends Control

const UIStyle = preload("res://scripts/ui_style.gd")
const Lang = preload("res://scripts/lang.gd")
const Banque = preload("res://scripts/classeur/banque.gd")

const COULEUR_FOND := Color(0.12, 0.25, 0.22)
const TAILLE_MAX_IMPORT := 512  # côté max (px) d'une image importée

var _banque: RefCounted
var _vbox: VBoxContainer
var _dialogue_fichier: FileDialog
var _dialogue_plaquette: FileDialog
var _message_import := ""  # clé d'erreur du dernier import de plaquette ("" = rien)


func _ready() -> void:
	_banque = Banque.charger()

	var fond := ColorRect.new()
	fond.color = COULEUR_FOND
	fond.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fond)

	var defilement := ScrollContainer.new()
	defilement.set_anchors_preset(Control.PRESET_FULL_RECT)
	defilement.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	defilement.get_v_scroll_bar().custom_minimum_size = Vector2(14, 0)
	add_child(defilement)
	var centre := CenterContainer.new()
	centre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centre.size_flags_vertical = Control.SIZE_EXPAND_FILL
	defilement.add_child(centre)

	_vbox = VBoxContainer.new()
	_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_vbox.add_theme_constant_override("separation", 22)
	centre.add_child(_vbox)

	# Sélecteur de fichier (import d'image de vignette), prêt d'avance
	_dialogue_fichier = FileDialog.new()
	_dialogue_fichier.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_dialogue_fichier.access = FileDialog.ACCESS_FILESYSTEM
	_dialogue_fichier.filters = ["*.png, *.jpg, *.jpeg, *.webp ; Images"]
	_dialogue_fichier.use_native_dialog = true
	_dialogue_fichier.file_selected.connect(_image_choisie)
	add_child(_dialogue_fichier)

	# Sélecteur d'import de plaquette TLAb (le SVG exporté par l'outil TLAb)
	_dialogue_plaquette = FileDialog.new()
	_dialogue_plaquette.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_dialogue_plaquette.access = FileDialog.ACCESS_FILESYSTEM
	_dialogue_plaquette.filters = ["*.svg, *.tlab ; Plaquettes TLAb"]
	_dialogue_plaquette.use_native_dialog = true
	_dialogue_plaquette.file_selected.connect(_plaquette_choisie)
	add_child(_dialogue_plaquette)

	_reconstruire()


func _reconstruire() -> void:
	for enfant in _vbox.get_children():
		enfant.free()

	_ajouter_titre(Lang.t("reglages_classeur"), 44)

	# --- Catégories ---
	_ajouter_titre(Lang.t("classeur_categories"), 30)
	for nom in _banque.categories():
		_vbox.add_child(_creer_ligne_categorie(nom))
	_vbox.add_child(_creer_ligne_nouvelle_categorie())

	# Import direct d'une plaquette TLAb (le SVG de l'outil de la professeure)
	var btn_import := Button.new()
	btn_import.text = Lang.t("classeur_importer_plaquette")
	btn_import.custom_minimum_size = Vector2(420, 58)
	btn_import.add_theme_font_size_override("font_size", 24)
	UIStyle.styliser(btn_import, Color(0.55, 0.40, 0.65), 14)
	btn_import.pressed.connect(func() -> void: _dialogue_plaquette.popup_centered(Vector2i(900, 600)))
	_vbox.add_child(btn_import)
	if _message_import != "":
		var erreur := Label.new()
		erreur.text = Lang.t(_message_import)
		erreur.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		erreur.add_theme_font_size_override("font_size", 20)
		erreur.add_theme_color_override("font_color", Color(1.0, 0.6, 0.45))
		_vbox.add_child(erreur)
		_message_import = ""

	# --- Vignettes ---
	_ajouter_titre(Lang.t("classeur_vignettes"), 30)
	var info := Label.new()
	info.text = Lang.t("classeur_vignettes_info")
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 20)
	info.add_theme_color_override("font_color", Color(0.78, 0.88, 0.82))
	_vbox.add_child(info)

	var grille := GridContainer.new()
	grille.columns = 7
	grille.add_theme_constant_override("h_separation", 10)
	grille.add_theme_constant_override("v_separation", 10)
	_vbox.add_child(grille)
	for id in _banque.ids_vignettes():
		grille.add_child(_creer_carte_vignette(id))

	var btn_nouvelle := Button.new()
	btn_nouvelle.text = Lang.t("classeur_nouvelle_vignette")
	btn_nouvelle.custom_minimum_size = Vector2(420, 64)
	btn_nouvelle.add_theme_font_size_override("font_size", 26)
	UIStyle.styliser(btn_nouvelle, Color(0.25, 0.45, 0.75), 14)
	btn_nouvelle.pressed.connect(func() -> void: _dialogue_fichier.popup_centered(Vector2i(900, 600)))
	_vbox.add_child(btn_nouvelle)

	# --- Retour ---
	var btn_retour := Button.new()
	btn_retour.text = Lang.t("reglages_retour")
	btn_retour.custom_minimum_size = Vector2(420, 76)
	btn_retour.add_theme_font_size_override("font_size", 30)
	UIStyle.styliser(btn_retour, Color(0.20, 0.55, 0.45), 16)
	btn_retour.pressed.connect(_retour_reglages)
	_vbox.add_child(btn_retour)


func _ajouter_titre(texte: String, taille: int) -> void:
	var titre := Label.new()
	titre.text = texte
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.add_theme_font_size_override("font_size", taille)
	titre.add_theme_color_override("font_color", Color.WHITE)
	_vbox.add_child(titre)


# --- Catégories -----------------------------------------------------------------

func _creer_ligne_categorie(nom: String) -> Control:
	var ligne := HBoxContainer.new()
	ligne.alignment = BoxContainer.ALIGNMENT_CENTER
	ligne.add_theme_constant_override("separation", 16)

	var etiquette := Label.new()
	etiquette.text = nom.capitalize()
	etiquette.custom_minimum_size = Vector2(360, 0)
	etiquette.add_theme_font_size_override("font_size", 26)
	etiquette.add_theme_color_override("font_color", Color.WHITE)
	ligne.add_child(etiquette)

	# Suppression en 2 temps : le bouton devient « Confirmer ? » puis agit
	var btn := Button.new()
	btn.text = Lang.t("classeur_btn_supprimer")
	btn.custom_minimum_size = Vector2(170, 52)
	btn.add_theme_font_size_override("font_size", 22)
	UIStyle.styliser(btn, Color(0.60, 0.30, 0.30), 12)
	btn.pressed.connect(func() -> void:
		if btn.text == Lang.t("classeur_btn_confirmer"):
			_banque.supprimer_categorie(nom)
			# Différé : reconstruire PENDANT le signal du bouton libérerait
			# le bouton émetteur lui-même → plantage
			_reconstruire.call_deferred()
		else:
			btn.text = Lang.t("classeur_btn_confirmer")
			UIStyle.styliser(btn, Color(0.80, 0.25, 0.25), 12))
	ligne.add_child(btn)
	return ligne


func _creer_ligne_nouvelle_categorie() -> Control:
	var ligne := HBoxContainer.new()
	ligne.alignment = BoxContainer.ALIGNMENT_CENTER
	ligne.add_theme_constant_override("separation", 16)

	var champ := LineEdit.new()
	champ.placeholder_text = Lang.t("classeur_nouvelle_categorie")
	champ.custom_minimum_size = Vector2(360, 52)
	champ.add_theme_font_size_override("font_size", 24)
	ligne.add_child(champ)

	var btn := Button.new()
	btn.text = Lang.t("classeur_btn_creer")
	btn.custom_minimum_size = Vector2(170, 52)
	btn.add_theme_font_size_override("font_size", 22)
	UIStyle.styliser(btn, Color(0.25, 0.55, 0.35), 12)
	var creer := func() -> void:
		if _banque.creer_categorie(champ.text):
			_reconstruire.call_deferred()  # différé : le bouton émetteur vit dans _vbox
	btn.pressed.connect(creer)
	champ.text_submitted.connect(func(_t: String) -> void: creer.call())
	ligne.add_child(btn)
	return ligne


# --- Vignettes --------------------------------------------------------------------

## Petite carte de la banque : pictogramme + mot, tap = édition.
func _creer_carte_vignette(id: int) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(108, 118)
	btn.focus_mode = Control.FOCUS_NONE
	for etat in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.98, 0.97, 0.93) if etat != "hover" else Color.WHITE
		style.set_corner_radius_all(10)
		btn.add_theme_stylebox_override(etat, style)
	var texture: ImageTexture = _banque.texture(id)
	if texture != null:
		var picto := TextureRect.new()
		picto.texture = texture
		picto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picto.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picto.position = Vector2(8, 5)
		picto.size = Vector2(92, 62)
		picto.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(picto)
	# Deux lignes de texte possibles (mots composés : « laver les mains »)
	var etiquette := Label.new()
	etiquette.text = _banque.mot(id)
	etiquette.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiquette.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiquette.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiquette.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	etiquette.clip_contents = true  # rien ne déborde du cadre de la carte
	etiquette.add_theme_font_size_override("font_size", 14)
	etiquette.add_theme_color_override("font_color", Color(0.12, 0.16, 0.24))
	etiquette.position = Vector2(4, 70)
	etiquette.size = Vector2(100, 44)
	etiquette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(etiquette)
	btn.pressed.connect(_editer_vignette.bind(id))
	return btn


## Import d'une plaquette TLAb : copiée dans le dépôt puis convertie en
## catégorie (vignettes dédupliquées avec la banque). Erreur affichée sinon.
func _plaquette_choisie(chemin: String) -> void:
	_message_import = _banque.importer_fichier(chemin)
	_reconstruire.call_deferred()


## Import d'image : la nouvelle vignette s'ouvre directement en édition.
func _image_choisie(chemin: String) -> void:
	var image := Image.load_from_file(chemin)
	if image == null:
		return
	# Réduite si besoin : une photo de téléphone n'a pas besoin de 4000 px
	var cote := maxi(image.get_width(), image.get_height())
	if cote > TAILLE_MAX_IMPORT:
		var facteur := float(TAILLE_MAX_IMPORT) / float(cote)
		image.resize(int(image.get_width() * facteur), int(image.get_height() * facteur),
			Image.INTERPOLATE_LANCZOS)
	var id: int = _banque.creer_vignette("", image, [])
	_editer_vignette(id)


## Panneau d'édition d'une vignette : mot, tags de catégories, suppression.
func _editer_vignette(id: int) -> void:
	var voile := ColorRect.new()
	voile.color = Color(0.0, 0.0, 0.0, 0.55)
	voile.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(voile)

	var panneau := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.30, 0.27)
	style.set_corner_radius_all(20)
	style.set_border_width_all(3)
	style.border_color = Color(0.35, 0.55, 0.50)
	panneau.add_theme_stylebox_override("panel", style)
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	voile.add_child(centre)
	centre.add_child(panneau)

	var marge := MarginContainer.new()
	for cote in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		marge.add_theme_constant_override(cote, 28)
	panneau.add_child(marge)
	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 18)
	marge.add_child(colonne)

	# Aperçu du pictogramme
	var texture: ImageTexture = _banque.texture(id)
	if texture != null:
		var picto := TextureRect.new()
		picto.texture = texture
		picto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picto.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picto.custom_minimum_size = Vector2(160, 130)
		colonne.add_child(picto)

	# Le mot (dit par la voix)
	var champ_mot := LineEdit.new()
	champ_mot.text = _banque.mot(id)
	champ_mot.placeholder_text = Lang.t("classeur_mot")
	champ_mot.custom_minimum_size = Vector2(380, 54)
	champ_mot.add_theme_font_size_override("font_size", 26)
	champ_mot.alignment = HORIZONTAL_ALIGNMENT_CENTER
	colonne.add_child(champ_mot)

	# Les tags de catégories (la vignette peut servir plusieurs plaquettes)
	var cases := {}
	for nom in _banque.categories():
		var case_categorie := CheckBox.new()
		case_categorie.text = " " + String(nom).capitalize()
		case_categorie.add_theme_font_size_override("font_size", 22)
		for etat in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			case_categorie.add_theme_color_override(etat, Color.WHITE)
		case_categorie.button_pressed = nom in _banque.tags(id)
		cases[nom] = case_categorie
		colonne.add_child(case_categorie)

	# Enregistrer / Supprimer (2 temps) / Fermer
	var ligne_boutons := HBoxContainer.new()
	ligne_boutons.alignment = BoxContainer.ALIGNMENT_CENTER
	ligne_boutons.add_theme_constant_override("separation", 14)
	colonne.add_child(ligne_boutons)

	var btn_ok := Button.new()
	btn_ok.text = Lang.t("classeur_btn_enregistrer")
	btn_ok.custom_minimum_size = Vector2(170, 56)
	btn_ok.add_theme_font_size_override("font_size", 22)
	UIStyle.styliser(btn_ok, Color(0.25, 0.55, 0.35), 12)
	btn_ok.pressed.connect(func() -> void:
		_banque.renommer(id, champ_mot.text)
		var nouveaux := []
		for nom in cases:
			if cases[nom].button_pressed:
				nouveaux.append(nom)
		_banque.retaguer(id, nouveaux)
		voile.queue_free()
		_reconstruire.call_deferred())
	ligne_boutons.add_child(btn_ok)

	var btn_suppr := Button.new()
	btn_suppr.text = Lang.t("classeur_btn_supprimer")
	btn_suppr.custom_minimum_size = Vector2(170, 56)
	btn_suppr.add_theme_font_size_override("font_size", 22)
	UIStyle.styliser(btn_suppr, Color(0.60, 0.30, 0.30), 12)
	btn_suppr.pressed.connect(func() -> void:
		if btn_suppr.text == Lang.t("classeur_btn_confirmer"):
			_banque.supprimer_vignette(id)
			voile.queue_free()
			_reconstruire.call_deferred()
		else:
			btn_suppr.text = Lang.t("classeur_btn_confirmer")
			UIStyle.styliser(btn_suppr, Color(0.80, 0.25, 0.25), 12))
	ligne_boutons.add_child(btn_suppr)

	var btn_fermer := Button.new()
	btn_fermer.text = Lang.t("classeur_btn_fermer")
	btn_fermer.custom_minimum_size = Vector2(140, 56)
	btn_fermer.add_theme_font_size_override("font_size", 22)
	UIStyle.styliser(btn_fermer, Color(0.35, 0.40, 0.50), 12)
	btn_fermer.pressed.connect(func() -> void: voile.queue_free())
	ligne_boutons.add_child(btn_fermer)


# --- Sortie ------------------------------------------------------------------------

## Échap = revenir aux réglages (réflexe universel).
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_retour_reglages()


func _retour_reglages() -> void:
	get_tree().change_scene_to_file("res://scenes/adult_settings.tscn")
