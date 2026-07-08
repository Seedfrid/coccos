## Sous-écran réglages adulte — section Clavier.
## L'adulte gère la liste des « mots à apprendre » du jeu Les mots :
## ajout (champ + bouton), retrait (sélection + bouton). Mots en majuscules.
## Sauvegarde immédiate. (Choix de la voix de synthèse : à venir ici.)
extends Control

const PinConfig = preload("res://scripts/pin_config.gd")
const UIStyle = preload("res://scripts/ui_style.gd")
const Lang = preload("res://scripts/lang.gd")

const MOTS_DEFAUT := ["ISABELLA", "PAPA", "MAMAN"]

var _liste: ItemList
var _saisie: LineEdit


func _ready() -> void:
	var fond := ColorRect.new()
	fond.color = Color(0.12, 0.25, 0.22)
	fond.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fond)

	# Zone défilante : molette + barre de défilement si le contenu dépasse l'écran
	var defilement := ScrollContainer.new()
	defilement.set_anchors_preset(Control.PRESET_FULL_RECT)
	defilement.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	defilement.get_v_scroll_bar().custom_minimum_size = Vector2(14, 0)
	add_child(defilement)
	var centre := CenterContainer.new()
	centre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centre.size_flags_vertical = Control.SIZE_EXPAND_FILL
	defilement.add_child(centre)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	centre.add_child(vbox)

	var titre := Label.new()
	titre.text = Lang.t("clavier_titre")
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.add_theme_font_size_override("font_size", 48)
	titre.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(titre)

	var sous_titre := Label.new()
	sous_titre.text = Lang.t("clavier_mots_titre")
	sous_titre.add_theme_font_size_override("font_size", 24)
	sous_titre.add_theme_color_override("font_color", Color(0.78, 0.88, 0.82))
	vbox.add_child(sous_titre)

	# --- Liste des mots ---
	_liste = ItemList.new()
	_liste.custom_minimum_size = Vector2(460, 220)
	_liste.add_theme_font_size_override("font_size", 26)
	for mot in PinConfig.lire_option("clavier", "mots", PackedStringArray(MOTS_DEFAUT)):
		_liste.add_item(String(mot))
	vbox.add_child(_liste)

	# --- Ajout d'un mot ---
	var ligne_ajout := HBoxContainer.new()
	ligne_ajout.add_theme_constant_override("separation", 14)
	vbox.add_child(ligne_ajout)

	_saisie = LineEdit.new()
	_saisie.placeholder_text = Lang.t("clavier_mot_placeholder")
	_saisie.custom_minimum_size = Vector2(300, 52)
	_saisie.add_theme_font_size_override("font_size", 26)
	_saisie.text_submitted.connect(func(_texte: String) -> void: _ajouter())
	ligne_ajout.add_child(_saisie)

	var btn_ajouter := Button.new()
	btn_ajouter.text = Lang.t("clavier_ajouter")
	btn_ajouter.custom_minimum_size = Vector2(160, 52)
	btn_ajouter.add_theme_font_size_override("font_size", 24)
	UIStyle.styliser(btn_ajouter, Color(0.25, 0.60, 0.40), 12)
	btn_ajouter.pressed.connect(_ajouter)
	ligne_ajout.add_child(btn_ajouter)

	var btn_retirer := Button.new()
	btn_retirer.text = Lang.t("clavier_retirer")
	btn_retirer.custom_minimum_size = Vector2(160, 52)
	btn_retirer.add_theme_font_size_override("font_size", 24)
	UIStyle.styliser(btn_retirer, Color(0.65, 0.35, 0.25), 12)
	btn_retirer.pressed.connect(_retirer)
	ligne_ajout.add_child(btn_retirer)

	var note := Label.new()
	note.text = Lang.t("clavier_voix_note")
	note.add_theme_font_size_override("font_size", 20)
	note.add_theme_color_override("font_color", Color(0.65, 0.75, 0.70))
	vbox.add_child(note)

	# --- Bouton retour ---
	var btn_retour := Button.new()
	btn_retour.text = Lang.t("reglages_retour")
	btn_retour.custom_minimum_size = Vector2(420, 84)
	btn_retour.add_theme_font_size_override("font_size", 32)
	UIStyle.styliser(btn_retour, Color(0.20, 0.55, 0.45), 16)
	btn_retour.pressed.connect(_retour_reglages)
	vbox.add_child(btn_retour)

	_saisie.grab_focus()


## Échap = revenir aux réglages (réflexe universel).
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_retour_reglages()


func _ajouter() -> void:
	var mot := _saisie.text.strip_edges().to_upper()
	if mot == "":
		return
	for i in _liste.item_count:
		if _liste.get_item_text(i) == mot:
			_saisie.clear()
			return  # doublon ignoré en douceur
	_liste.add_item(mot)
	_saisie.clear()
	_sauver()


func _retirer() -> void:
	var selection := _liste.get_selected_items()
	if selection.is_empty():
		return
	_liste.remove_item(selection[0])
	_sauver()


func _sauver() -> void:
	var mots := PackedStringArray()
	for i in _liste.item_count:
		mots.append(_liste.get_item_text(i))
	PinConfig.ecrire_option("clavier", "mots", mots)


func _retour_reglages() -> void:
	get_tree().change_scene_to_file("res://scenes/adult_settings.tscn")
