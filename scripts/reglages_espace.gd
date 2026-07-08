## Sous-écran réglages adulte — section Espace famille (spec :
## DOCS/specs/spec-espace-famille.md). « Le même CoccOs partout » :
##   - Créer un espace famille → le CODE s'affiche en grand (à noter !)
##   - Rejoindre avec un code → champ de saisie
##   - Envoyer sur l'espace / Récupérer de l'espace — synchro MANUELLE (v1),
##     avec confirmation en 2 temps avant d'écraser (envoyer remplace l'espace,
##     récupérer remplace le local — une sauvegarde locale est faite avant).
## Le serveur ne voit jamais le code (empreinte seulement) ni aucune donnée
## identifiante. Voyage : réglages + classeur + voix. Pas les vidéos.
extends Control

const UIStyle = preload("res://scripts/ui_style.gd")
const Lang = preload("res://scripts/lang.gd")
const Espace = preload("res://scripts/espace_famille.gd")
const SyncWifi = preload("res://scripts/sync_wifi.gd")

const COULEUR_FOND := Color(0.12, 0.25, 0.22)

var _vbox: VBoxContainer
var _http: HTTPRequest
var _sync: Node
var _statut: Label
var _en_cours := false
var _wifi_en_cours := false


func _ready() -> void:
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

	_http = HTTPRequest.new()
	_http.timeout = 60.0
	add_child(_http)

	_sync = SyncWifi.new()
	_sync.termine.connect(func(cle: String) -> void:
		_wifi_en_cours = false
		_terminer(cle))
	add_child(_sync)

	_reconstruire()


func _reconstruire() -> void:
	for enfant in _vbox.get_children():
		enfant.free()

	_ajouter_titre(Lang.t("reglages_espace"), 44)

	var info := Label.new()
	info.text = Lang.t("espace_info")
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size = Vector2(760, 0)
	info.add_theme_font_size_override("font_size", 20)
	info.add_theme_color_override("font_color", Color(0.78, 0.88, 0.82))
	_vbox.add_child(info)

	var code := Espace.code_local()
	if code == "":
		# --- Pas encore d'espace : créer ou rejoindre ---
		var btn_creer := _grand_bouton(Lang.t("espace_btn_creer"), Color(0.25, 0.55, 0.35))
		btn_creer.pressed.connect(func() -> void:
			Espace.enregistrer_code(Espace.generer_code())
			_reconstruire.call_deferred())
		_vbox.add_child(btn_creer)

		var ligne := HBoxContainer.new()
		ligne.alignment = BoxContainer.ALIGNMENT_CENTER
		ligne.add_theme_constant_override("separation", 14)
		var champ := LineEdit.new()
		champ.placeholder_text = Lang.t("espace_champ_code")
		champ.custom_minimum_size = Vector2(460, 54)
		champ.add_theme_font_size_override("font_size", 24)
		ligne.add_child(champ)
		var btn_rejoindre := Button.new()
		btn_rejoindre.text = Lang.t("espace_btn_rejoindre")
		btn_rejoindre.custom_minimum_size = Vector2(190, 54)
		btn_rejoindre.add_theme_font_size_override("font_size", 22)
		UIStyle.styliser(btn_rejoindre, Color(0.25, 0.45, 0.75), 12)
		var rejoindre := func() -> void:
			if Espace.nettoyer_code(champ.text) != "":
				Espace.enregistrer_code(champ.text)
				_reconstruire.call_deferred()
		btn_rejoindre.pressed.connect(rejoindre)
		champ.text_submitted.connect(func(_t: String) -> void: rejoindre.call())
		ligne.add_child(btn_rejoindre)
		_vbox.add_child(ligne)
	else:
		# --- Le code de la famille, en GRAND (à noter quelque part) ---
		var cadre := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.16, 0.30, 0.27)
		style.set_corner_radius_all(16)
		style.set_border_width_all(3)
		style.border_color = Color(0.95, 0.72, 0.15)
		cadre.add_theme_stylebox_override("panel", style)
		var marge := MarginContainer.new()
		for cote in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
			marge.add_theme_constant_override(cote, 22)
		cadre.add_child(marge)
		var label_code := Label.new()
		label_code.text = code
		label_code.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label_code.add_theme_font_size_override("font_size", 34)
		label_code.add_theme_color_override("font_color", Color(0.95, 0.85, 0.20))
		marge.add_child(label_code)
		_vbox.add_child(cadre)

		var note := Label.new()
		note.text = Lang.t("espace_note_code")
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		note.add_theme_font_size_override("font_size", 20)
		note.add_theme_color_override("font_color", Color(0.78, 0.88, 0.82))
		_vbox.add_child(note)

		if _wifi_en_cours:
			# Une synchro wifi cherche l'autre appareil : juste Annuler
			var btn_annuler := _grand_bouton(Lang.t("wifi_annuler"), Color(0.60, 0.35, 0.30))
			btn_annuler.pressed.connect(func() -> void:
				_sync.arreter()
				_wifi_en_cours = false
				_en_cours = false
				_reconstruire.call_deferred())
			_vbox.add_child(btn_annuler)
		else:
			# --- Synchro WIFI locale (sans internet ni serveur — étage 2) ---
			var btn_wifi_envoyer := _grand_bouton(Lang.t("wifi_btn_envoyer"), Color(0.25, 0.55, 0.35))
			btn_wifi_envoyer.pressed.connect(_confirmer_puis.bind(btn_wifi_envoyer,
				_demarrer_wifi.bind("offre")))
			_vbox.add_child(btn_wifi_envoyer)

			var btn_wifi_recuperer := _grand_bouton(Lang.t("wifi_btn_recuperer"), Color(0.25, 0.45, 0.75))
			btn_wifi_recuperer.pressed.connect(_confirmer_puis.bind(btn_wifi_recuperer,
				_demarrer_wifi.bind("cherche")))
			_vbox.add_child(btn_wifi_recuperer)

			# --- Espace EN LIGNE (Envoyer / Récupérer, 2 temps chacun) ---
			var btn_envoyer := _grand_bouton(Lang.t("espace_btn_envoyer"), Color(0.30, 0.50, 0.35))
			btn_envoyer.pressed.connect(_confirmer_puis.bind(btn_envoyer, _envoyer))
			_vbox.add_child(btn_envoyer)

			var btn_recuperer := _grand_bouton(Lang.t("espace_btn_recuperer"), Color(0.30, 0.45, 0.65))
			btn_recuperer.pressed.connect(_confirmer_puis.bind(btn_recuperer, _recuperer))
			_vbox.add_child(btn_recuperer)

		var btn_oublier := Button.new()
		btn_oublier.text = Lang.t("espace_btn_oublier")
		btn_oublier.custom_minimum_size = Vector2(420, 52)
		btn_oublier.add_theme_font_size_override("font_size", 20)
		UIStyle.styliser(btn_oublier, Color(0.45, 0.40, 0.45), 12)
		btn_oublier.pressed.connect(func() -> void:
			if btn_oublier.text == Lang.t("classeur_btn_confirmer"):
				Espace.enregistrer_code("")
				_reconstruire.call_deferred()
			else:
				btn_oublier.text = Lang.t("classeur_btn_confirmer"))
		_vbox.add_child(btn_oublier)

	_statut = Label.new()
	_statut.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_statut.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_statut.custom_minimum_size = Vector2(700, 0)
	_statut.add_theme_font_size_override("font_size", 22)
	_statut.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	if _wifi_en_cours:
		_statut.text = Lang.t("wifi_en_cours")
	_vbox.add_child(_statut)

	# --- Adresse de l'espace en ligne : configurable (aucun serveur obligatoire,
	# n'importe quel WebDAV convient — Nextcloud, NAS, serveur d'école…) ---
	var ligne_url := HBoxContainer.new()
	ligne_url.alignment = BoxContainer.ALIGNMENT_CENTER
	ligne_url.add_theme_constant_override("separation", 12)
	var etiquette_url := Label.new()
	etiquette_url.text = Lang.t("espace_url_titre")
	etiquette_url.add_theme_font_size_override("font_size", 20)
	etiquette_url.add_theme_color_override("font_color", Color(0.78, 0.88, 0.82))
	ligne_url.add_child(etiquette_url)
	var champ_url := LineEdit.new()
	champ_url.text = Espace.url_base()
	champ_url.custom_minimum_size = Vector2(420, 44)
	champ_url.add_theme_font_size_override("font_size", 18)
	var garder_url := func() -> void:
		Espace.enregistrer_url(champ_url.text)
	champ_url.text_submitted.connect(func(_t: String) -> void: garder_url.call())
	champ_url.focus_exited.connect(garder_url)
	ligne_url.add_child(champ_url)
	_vbox.add_child(ligne_url)

	var btn_retour := Button.new()
	btn_retour.text = Lang.t("reglages_retour")
	btn_retour.custom_minimum_size = Vector2(420, 76)
	btn_retour.add_theme_font_size_override("font_size", 30)
	UIStyle.styliser(btn_retour, Color(0.20, 0.55, 0.45), 16)
	btn_retour.pressed.connect(_retour_reglages)
	_vbox.add_child(btn_retour)


## Confirmation en 2 temps : le bouton demande « Confirmer ? » puis agit.
func _confirmer_puis(btn: Button, action: Callable) -> void:
	if _en_cours:
		return
	if btn.text.ends_with(Lang.t("classeur_btn_confirmer")):
		action.call()
	else:
		btn.text = btn.text + "  —  " + Lang.t("classeur_btn_confirmer")


# --- Les gestes ------------------------------------------------------------------------

## Synchro wifi locale : l'un offre, l'autre cherche — ils se reconnaissent
## par l'empreinte du code famille sur le réseau du foyer.
func _demarrer_wifi(mode: String) -> void:
	_wifi_en_cours = true
	_en_cours = true
	if mode == "offre":
		_sync.offrir(Espace.code_local())
	else:
		_sync.chercher(Espace.code_local())
	_reconstruire.call_deferred()

func _envoyer() -> void:
	var octets := Espace.construire_archive()
	if octets.is_empty():
		_statut.text = Lang.t("espace_trop_gros")
		return
	_en_cours = true
	_statut.text = Lang.t("espace_envoi_en_cours")
	var erreur := _http.request_raw(Espace.url_espace(Espace.code_local()),
		["Content-Type: application/zip"], HTTPClient.METHOD_PUT, octets)
	if erreur != OK:
		_terminer("espace_echec_reseau")
		return
	var reponse: Array = await _http.request_completed
	var code_http: int = reponse[1]
	_terminer("espace_envoye" if code_http >= 200 and code_http < 300 else "espace_echec_reseau")


func _recuperer() -> void:
	_en_cours = true
	_statut.text = Lang.t("espace_recuperation_en_cours")
	var erreur := _http.request(Espace.url_espace(Espace.code_local()))
	if erreur != OK:
		_terminer("espace_echec_reseau")
		return
	var reponse: Array = await _http.request_completed
	var code_http: int = reponse[1]
	var corps: PackedByteArray = reponse[3]
	if code_http == 404:
		_terminer("espace_vide")
		return
	if code_http < 200 or code_http >= 300 or corps.is_empty():
		_terminer("espace_echec_reseau")
		return
	var ecrits := Espace.appliquer_archive(corps)
	_terminer("espace_recupere" if ecrits > 0 else "espace_echec_archive")


func _terminer(cle_message: String) -> void:
	_en_cours = false
	if is_instance_valid(_statut):
		_statut.text = Lang.t(cle_message)
	# Les boutons « Confirmer ? » reprennent leur libellé
	_reconstruire.call_deferred()
	await get_tree().process_frame
	if is_instance_valid(_statut):
		_statut.text = Lang.t(cle_message)


func _ajouter_titre(texte: String, taille: int) -> void:
	var titre := Label.new()
	titre.text = texte
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.add_theme_font_size_override("font_size", taille)
	titre.add_theme_color_override("font_color", Color.WHITE)
	_vbox.add_child(titre)


func _grand_bouton(libelle: String, couleur: Color) -> Button:
	var btn := Button.new()
	btn.text = libelle
	btn.custom_minimum_size = Vector2(560, 64)
	btn.add_theme_font_size_override("font_size", 26)
	UIStyle.styliser(btn, couleur, 14)
	return btn


## Échap = revenir aux réglages (réflexe universel).
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_retour_reglages()


func _retour_reglages() -> void:
	get_tree().change_scene_to_file("res://scenes/adult_settings.tscn")
