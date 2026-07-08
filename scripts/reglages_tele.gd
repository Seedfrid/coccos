## Sous-écran réglages adulte — section Télé (spec : DOCS/specs/spec-tele.md).
## L'adulte remplit ici le MUR de « Ma télé » — la liste fermée :
##   - importer une vidéo : ffmpeg la convertit en .ogv 720p et extrait la
##     vignette (Linux : ffmpeg du système, installable graphiquement ;
##     Windows : ffmpeg.exe fourni par l'installeur ; Android : dépôt de .ogv
##     déjà convertis uniquement — message avec la marche à suivre)
##   - renommer (le nom fait le titre ET l'ordre alphabétique du mur)
##   - retirer (2 temps : le bouton devient « Confirmer ? »)
## Un .ogv est importé sans conversion (copie directe).
extends Control

const UIStyle = preload("res://scripts/ui_style.gd")
const Lang = preload("res://scripts/lang.gd")
const Videotheque = preload("res://scripts/tele/videotheque.gd")

const COULEUR_FOND := Color(0.12, 0.25, 0.22)

var _vbox: VBoxContainer
var _dialogue_fichier: FileDialog
var _statut: Label = null      # ligne d'état de l'import en cours
var _import_en_cours := false


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
	_vbox.add_theme_constant_override("separation", 20)
	centre.add_child(_vbox)

	_dialogue_fichier = FileDialog.new()
	_dialogue_fichier.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_dialogue_fichier.access = FileDialog.ACCESS_FILESYSTEM
	if OS.has_feature("android"):
		_dialogue_fichier.filters = ["*.ogv ; Vidéos converties"]
	else:
		_dialogue_fichier.filters = ["*.mp4, *.mkv, *.webm, *.avi, *.mov, *.ogv ; Vidéos"]
	_dialogue_fichier.use_native_dialog = true
	_dialogue_fichier.file_selected.connect(_video_choisie)
	add_child(_dialogue_fichier)

	_reconstruire()


func _reconstruire() -> void:
	for enfant in _vbox.get_children():
		enfant.free()
	_statut = null

	_ajouter_titre(Lang.t("reglages_tele"), 44)

	var info := Label.new()
	info.text = Lang.t("tele_info")
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size = Vector2(760, 0)
	info.add_theme_font_size_override("font_size", 20)
	info.add_theme_color_override("font_color", Color(0.78, 0.88, 0.82))
	_vbox.add_child(info)

	# --- Les vidéos du mur ---
	for video in Videotheque.lister():
		_vbox.add_child(_creer_ligne_video(video))

	# --- Import (selon la plateforme) ---
	if OS.has_feature("android"):
		var note := Label.new()
		note.text = Lang.t("tele_note_android")
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.custom_minimum_size = Vector2(760, 0)
		note.add_theme_font_size_override("font_size", 20)
		note.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
		_vbox.add_child(note)
		_vbox.add_child(_creer_bouton_import(Lang.t("tele_btn_deposer_ogv")))
	elif Videotheque.chemin_ffmpeg() != "":
		_vbox.add_child(_creer_bouton_import(Lang.t("tele_btn_importer")))
	else:
		# Le convertisseur manque : installation graphique (Linux) ou message (Windows)
		var absent := Label.new()
		absent.text = Lang.t("tele_ffmpeg_windows" if OS.has_feature("windows") else "tele_ffmpeg_absent")
		absent.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		absent.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		absent.custom_minimum_size = Vector2(760, 0)
		absent.add_theme_font_size_override("font_size", 20)
		absent.add_theme_color_override("font_color", Color(1.0, 0.6, 0.45))
		_vbox.add_child(absent)
		if not OS.has_feature("windows"):
			var btn_installer := Button.new()
			btn_installer.text = Lang.t("tele_btn_installer_ffmpeg")
			btn_installer.custom_minimum_size = Vector2(460, 58)
			btn_installer.add_theme_font_size_override("font_size", 24)
			UIStyle.styliser(btn_installer, Color(0.25, 0.45, 0.75), 14)
			btn_installer.pressed.connect(_installer_ffmpeg.bind(btn_installer))
			_vbox.add_child(btn_installer)

	# Ligne d'état (import/conversion en cours)
	_statut = Label.new()
	_statut.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_statut.add_theme_font_size_override("font_size", 22)
	_statut.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	_vbox.add_child(_statut)

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


func _creer_bouton_import(libelle: String) -> Button:
	var btn := Button.new()
	btn.text = libelle
	btn.custom_minimum_size = Vector2(460, 64)
	btn.add_theme_font_size_override("font_size", 26)
	UIStyle.styliser(btn, Color(0.55, 0.40, 0.65), 14)
	btn.pressed.connect(func() -> void:
		if not _import_en_cours:
			_dialogue_fichier.popup_centered(Vector2i(900, 600)))
	return btn


# --- Une ligne par vidéo : vignette + nom + renommer + retirer ---------------------

func _creer_ligne_video(video: Dictionary) -> Control:
	var ligne := HBoxContainer.new()
	ligne.alignment = BoxContainer.ALIGNMENT_CENTER
	ligne.add_theme_constant_override("separation", 14)

	var apercu := TextureRect.new()
	apercu.custom_minimum_size = Vector2(96, 54)
	apercu.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	apercu.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if video["vignette"] != null:
		apercu.texture = video["vignette"]
	ligne.add_child(apercu)

	# Le nom, éditable sur place : Entrée ou perte de focus = renommage
	var champ := LineEdit.new()
	champ.text = video["nom"]
	champ.custom_minimum_size = Vector2(380, 48)
	champ.add_theme_font_size_override("font_size", 22)
	var renommer := func() -> void:
		if champ.text.strip_edges() != video["nom"]:
			if Videotheque.renommer(video["nom"], champ.text):
				_reconstruire.call_deferred()
			else:
				champ.text = video["nom"]  # collision ou vide : on revient
	champ.text_submitted.connect(func(_t: String) -> void: renommer.call())
	champ.focus_exited.connect(renommer)
	ligne.add_child(champ)

	var btn_retirer := Button.new()
	btn_retirer.text = Lang.t("classeur_btn_supprimer")
	btn_retirer.custom_minimum_size = Vector2(160, 48)
	btn_retirer.add_theme_font_size_override("font_size", 20)
	UIStyle.styliser(btn_retirer, Color(0.60, 0.30, 0.30), 12)
	btn_retirer.pressed.connect(func() -> void:
		if btn_retirer.text == Lang.t("classeur_btn_confirmer"):
			Videotheque.retirer(video["nom"])
			_reconstruire.call_deferred()  # différé : le bouton émetteur vit dans _vbox
		else:
			btn_retirer.text = Lang.t("classeur_btn_confirmer")
			UIStyle.styliser(btn_retirer, Color(0.80, 0.25, 0.25), 12))
	ligne.add_child(btn_retirer)
	return ligne


# --- Import : conversion ffmpeg suivie, puis vignette -------------------------------

func _video_choisie(chemin: String) -> void:
	var nom: String = Videotheque.nom_propre(chemin.get_file().get_basename())
	if nom == "" or _import_en_cours:
		return
	_import_en_cours = true
	var pid: int = Videotheque.importer(chemin, nom)
	if pid == -1:
		# Copie directe (.ogv) ou échec : le fichier dit lequel
		_import_en_cours = false
		if Videotheque.fichier_pret(nom):
			_reconstruire.call_deferred()
		elif _statut != null:
			_statut.text = Lang.t("tele_import_echec")
		return
	_suivre_conversion(pid, nom)


## Surveillance douce de la conversion (comme l'installation d'applications).
func _suivre_conversion(pid: int, nom: String) -> void:
	if _statut != null:
		_statut.text = Lang.t("tele_conversion_en_cours") + " " + nom
	while OS.is_process_running(pid):
		await get_tree().create_timer(2.0).timeout
		if not is_inside_tree():
			return  # l'écran a été quitté pendant la conversion
	_import_en_cours = false
	if not Videotheque.fichier_pret(nom):
		if _statut != null:
			_statut.text = Lang.t("tele_import_echec")
		return
	# La vignette du mur, puis rafraîchir (sans bloquer sur son extraction)
	var pid_vignette: int = Videotheque.generer_vignette(nom)
	while pid_vignette != -1 and OS.is_process_running(pid_vignette):
		await get_tree().create_timer(1.0).timeout
		if not is_inside_tree():
			return
	_reconstruire.call_deferred()


## Installation graphique de ffmpeg (Linux) — patron des applications externes.
func _installer_ffmpeg(btn: Button) -> void:
	var sortie := []
	if OS.execute("which", ["pkexec"], sortie) != 0:
		OS.shell_open("apt://ffmpeg")
		return
	var pid := OS.create_process("pkexec", ["apt-get", "install", "-y", "ffmpeg"])
	if pid == -1:
		OS.shell_open("apt://ffmpeg")
		return
	btn.disabled = true
	if _statut != null:
		_statut.text = Lang.t("applis_statut_en_cours")
	while OS.is_process_running(pid):
		await get_tree().create_timer(2.0).timeout
		if not is_inside_tree():
			return
	_reconstruire.call_deferred()


# --- Sortie --------------------------------------------------------------------------

## Échap = revenir aux réglages (réflexe universel).
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_retour_reglages()


func _retour_reglages() -> void:
	get_tree().change_scene_to_file("res://scenes/adult_settings.tscn")
