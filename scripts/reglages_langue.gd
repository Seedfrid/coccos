## Sous-écran réglages adulte — LANGUE (note Freddy 2026-07-07 : créer une langue
## DIRECTEMENT dans l'appli — papa parle français, maman anglais au quotidien).
## Deux étages :
##   1. Choix de la langue de l'interface (embarquées res://lang/ + créées
##      user://lang/) — s'applique au prochain lancement.
##   2. Éditeur : un code (ex. « en ») ouvre la liste des ~110 textes, le
##      français en référence, un champ par clé ; Enregistrer écrit
##      user://lang/<code>/textes.xml — champ vide = le français est conservé
##      (repli clé par clé de lang.gd : une traduction partielle vit déjà).
## Les voix enregistrées suivent le même code (user://lang/<code>/voix/).
extends Control

const PinConfig = preload("res://scripts/pin_config.gd")
const UIStyle = preload("res://scripts/ui_style.gd")
const Lang = preload("res://scripts/lang.gd")

var _vbox: VBoxContainer
var _selecteur: OptionButton
var _champ_code: LineEdit
var _zone_editeur: VBoxContainer = null
var _champs := {}  # cle → LineEdit de l'éditeur
var _message: Label


func _ready() -> void:
	var fond := ColorRect.new()
	fond.color = Color(0.12, 0.25, 0.22)
	fond.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fond)

	var defilement := ScrollContainer.new()
	defilement.set_anchors_preset(Control.PRESET_FULL_RECT)
	defilement.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	defilement.get_v_scroll_bar().custom_minimum_size = Vector2(14, 0)
	add_child(defilement)

	var centre := CenterContainer.new()
	centre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	defilement.add_child(centre)

	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 18)
	_vbox.custom_minimum_size = Vector2(760, 0)
	centre.add_child(_vbox)

	var titre := Label.new()
	titre.text = Lang.t("langue_titre")
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.add_theme_font_size_override("font_size", 40)
	titre.add_theme_color_override("font_color", Color.WHITE)
	_vbox.add_child(titre)

	_vbox.add_child(_creer_info(Lang.t("langue_info")))

	# --- 1. Langue de l'interface ---
	var ligne_choix := HBoxContainer.new()
	ligne_choix.alignment = BoxContainer.ALIGNMENT_CENTER
	ligne_choix.add_theme_constant_override("separation", 16)
	var etiquette := Label.new()
	etiquette.text = Lang.t("langue_active")
	etiquette.add_theme_font_size_override("font_size", 26)
	etiquette.add_theme_color_override("font_color", Color.WHITE)
	ligne_choix.add_child(etiquette)
	_selecteur = OptionButton.new()
	_selecteur.add_theme_font_size_override("font_size", 26)
	_selecteur.custom_minimum_size = Vector2(180, 56)
	_remplir_selecteur()
	_selecteur.item_selected.connect(func(index: int) -> void:
		PinConfig.ecrire_option("langue", "code", _selecteur.get_item_text(index))
		_dire(Lang.t("langue_note_relance")))
	ligne_choix.add_child(_selecteur)
	_vbox.add_child(ligne_choix)

	# --- 2. Créer / modifier une langue ---
	var ligne_creer := HBoxContainer.new()
	ligne_creer.alignment = BoxContainer.ALIGNMENT_CENTER
	ligne_creer.add_theme_constant_override("separation", 16)
	_champ_code = LineEdit.new()
	_champ_code.placeholder_text = Lang.t("langue_code_placeholder")
	_champ_code.add_theme_font_size_override("font_size", 26)
	_champ_code.custom_minimum_size = Vector2(320, 56)
	_champ_code.max_length = 5
	ligne_creer.add_child(_champ_code)
	var btn_editer := Button.new()
	btn_editer.text = Lang.t("langue_btn_editer")
	btn_editer.add_theme_font_size_override("font_size", 24)
	UIStyle.styliser(btn_editer, Color(0.35, 0.55, 0.30), 14)
	btn_editer.pressed.connect(_ouvrir_editeur)
	ligne_creer.add_child(btn_editer)
	_vbox.add_child(ligne_creer)

	_message = Label.new()
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.add_theme_font_size_override("font_size", 22)
	_message.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	_vbox.add_child(_message)

	# --- Retour ---
	var btn_retour := Button.new()
	btn_retour.text = Lang.t("reglages_retour")
	btn_retour.custom_minimum_size = Vector2(420, 84)
	btn_retour.add_theme_font_size_override("font_size", 32)
	UIStyle.styliser(btn_retour, Color(0.20, 0.55, 0.45), 16)
	btn_retour.pressed.connect(_retour_reglages)
	_vbox.add_child(btn_retour)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_retour_reglages()


func _retour_reglages() -> void:
	get_tree().change_scene_to_file("res://scenes/adult_settings.tscn")


func _dire(texte: String) -> void:
	_message.text = texte


# --- L'éditeur de traduction -------------------------------------------------------

func _ouvrir_editeur() -> void:
	var code := _champ_code.text.strip_edges().to_lower()
	var valide := code.length() >= 2 and code.length() <= 5
	for lettre in code:
		if not (lettre >= "a" and lettre <= "z"):
			valide = false
	if not valide:
		_dire(Lang.t("langue_msg_code_invalide"))
		return
	_champs.clear()
	if _zone_editeur != null:
		_zone_editeur.queue_free()
	_zone_editeur = VBoxContainer.new()
	_zone_editeur.add_theme_constant_override("separation", 10)
	_vbox.add_child(_zone_editeur)
	_vbox.move_child(_zone_editeur, _vbox.get_child_count() - 2)  # avant Retour

	_zone_editeur.add_child(_creer_info(Lang.t("langue_editeur_info")))

	var existant := _lire_xml("user://lang/%s/textes.xml" % code)
	if existant.is_empty():
		existant = _lire_xml("res://lang/%s/textes.xml" % code)
	for entree in _lire_xml_ordonne("res://lang/fr/textes.xml"):
		var rangee := VBoxContainer.new()
		rangee.add_theme_constant_override("separation", 2)
		var reference := Label.new()
		reference.text = entree["texte"]
		reference.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		reference.add_theme_font_size_override("font_size", 18)
		reference.add_theme_color_override("font_color", Color(0.75, 0.85, 0.80))
		rangee.add_child(reference)
		var champ := LineEdit.new()
		champ.text = existant.get(entree["cle"], "")
		champ.placeholder_text = entree["texte"]
		champ.add_theme_font_size_override("font_size", 22)
		rangee.add_child(champ)
		_champs[entree["cle"]] = champ
		_zone_editeur.add_child(rangee)

	var btn_enregistrer := Button.new()
	btn_enregistrer.text = Lang.t("langue_btn_enregistrer")
	btn_enregistrer.custom_minimum_size = Vector2(420, 76)
	btn_enregistrer.add_theme_font_size_override("font_size", 28)
	UIStyle.styliser(btn_enregistrer, Color(0.70, 0.45, 0.15), 16)
	btn_enregistrer.pressed.connect(func() -> void: _enregistrer(code))
	_zone_editeur.add_child(btn_enregistrer)


## Écrit user://lang/<code>/textes.xml — seules les clés traduites sont posées
## (le repli de lang.gd complète avec le français).
func _enregistrer(code: String) -> void:
	DirAccess.make_dir_recursive_absolute("user://lang/%s/voix" % code)
	var fichier := FileAccess.open("user://lang/%s/textes.xml" % code, FileAccess.WRITE)
	if fichier == null:
		_dire(Lang.t("langue_msg_echec"))
		return
	fichier.store_line('<?xml version="1.0" encoding="UTF-8"?>')
	fichier.store_line('<!-- Langue créée dans CoccOs (Réglages → Langue). -->')
	fichier.store_line('<langue code="%s">' % code)
	var traduites := 0
	for cle in _champs:
		var valeur: String = _champs[cle].text.strip_edges()
		if valeur != "":
			fichier.store_line('\t<texte cle="%s">%s</texte>' % [cle, valeur.xml_escape()])
			traduites += 1
	fichier.store_line('</langue>')
	fichier.close()
	_remplir_selecteur()
	_dire(Lang.t("langue_msg_enregistree") % traduites)


# --- Outils ------------------------------------------------------------------------

func _remplir_selecteur() -> void:
	_selecteur.clear()
	var actif: String = PinConfig.lire_option("langue", "code", "fr")
	var codes := {}
	for base in ["res://lang", "user://lang"]:
		var dossier := DirAccess.open(base)
		if dossier != null:
			for sous in dossier.get_directories():
				if FileAccess.file_exists("%s/%s/textes.xml" % [base, sous]):
					codes[sous] = true
	var liste := codes.keys()
	liste.sort()
	for i in liste.size():
		_selecteur.add_item(liste[i])
		if liste[i] == actif:
			_selecteur.select(i)


func _creer_info(texte: String) -> Label:
	var info := Label.new()
	info.text = texte
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 22)
	info.add_theme_color_override("font_color", Color(0.85, 0.92, 0.88))
	return info


func _lire_xml(chemin: String) -> Dictionary:
	var resultat := {}
	for entree in _lire_xml_ordonne(chemin):
		resultat[entree["cle"]] = entree["texte"]
	return resultat


func _lire_xml_ordonne(chemin: String) -> Array:
	var entrees := []
	if not FileAccess.file_exists(chemin):
		return entrees
	var xml := XMLParser.new()
	if xml.open(chemin) != OK:
		return entrees
	var cle_courante := ""
	while xml.read() == OK:
		match xml.get_node_type():
			XMLParser.NODE_ELEMENT:
				cle_courante = xml.get_named_attribute_value_safe("cle") \
						if xml.get_node_name() == "texte" else ""
			XMLParser.NODE_TEXT:
				if cle_courante != "":
					var valeur := xml.get_node_data().strip_edges()
					if valeur != "":
						entrees.append({"cle": cle_courante, "texte": valeur})
			_:
				cle_courante = ""
	return entrees
