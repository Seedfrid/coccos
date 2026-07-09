## Sous-écran réglages adulte — LA LOGITHÈQUE (spec : spec-logitheque.md).
## Deux sections :
##   1. Applications CoccOs — chaque activité intégrée avec sa description et
##      sa CASE D'ACTIVATION : décochée = absente du bureau de l'enfant
##      (ouverture progressive du bureau, au rythme de l'enfant).
##   2. Applications externes — TuxPaint, GCompris, TuxMath… installables
##      graphiquement (pkexec/apt sur Linux, fiche Play Store sur Android),
##      jamais de terminal. Seules les applis de la plateforme sont listées.
## Sauvegarde immédiate à chaque bascule.
extends Control

const PinConfig = preload("res://scripts/pin_config.gd")
const UIStyle = preload("res://scripts/ui_style.gd")
const AppliExternes = preload("res://scripts/applis_externes.gd")
const Registre = preload("res://scripts/registre_jeux.gd")
const Lang = preload("res://scripts/lang.gd")


func _ready() -> void:
	# --- Fond plein (même atmosphère sobre que les écrans adulte) ---
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
	vbox.add_theme_constant_override("separation", 24)
	centre.add_child(vbox)

	# --- Titre + explication ---
	var titre := Label.new()
	titre.text = Lang.t("applis_titre")
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.add_theme_font_size_override("font_size", 44)
	titre.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(titre)

	var info := Label.new()
	info.text = Lang.t("applis_info")
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 22)
	info.add_theme_color_override("font_color", Color(0.78, 0.88, 0.82))
	vbox.add_child(info)

	# --- 1. Les applications CoccOs : activer/désactiver sur le bureau ---
	var titre_coccos := Label.new()
	titre_coccos.text = Lang.t("logitheque_titre_coccos")
	titre_coccos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre_coccos.add_theme_font_size_override("font_size", 30)
	titre_coccos.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(titre_coccos)
	for appli in Registre.APPLIS:
		if Registre.existe_ici(appli):
			vbox.add_child(_creer_ligne_coccos(appli))

	# --- 2. Les applications externes (catalogue de cette plateforme) ---
	var titre_externes := Label.new()
	titre_externes.text = Lang.t("logitheque_titre_externes")
	titre_externes.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre_externes.add_theme_font_size_override("font_size", 30)
	titre_externes.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(titre_externes)
	for appli in AppliExternes.catalogue_plateforme():
		vbox.add_child(_creer_ligne(appli))

	# --- Bouton retour vers les réglages ---
	var btn_retour := Button.new()
	btn_retour.text = Lang.t("reglages_retour")
	btn_retour.custom_minimum_size = Vector2(420, 84)
	btn_retour.add_theme_font_size_override("font_size", 32)
	UIStyle.styliser(btn_retour, Color(0.20, 0.55, 0.45), 16)
	btn_retour.pressed.connect(_retour_reglages)
	vbox.add_child(btn_retour)

	btn_retour.grab_focus()


## Échap = revenir aux réglages (réflexe universel).
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_retour_reglages()


## Au retour du Play Store (Android), l'écran se reconstruit : le statut de
## l'appli fraîchement installée passe à « installée » sans quitter l'écran.
func _notification(quoi: int) -> void:
	if quoi == NOTIFICATION_APPLICATION_FOCUS_IN and OS.has_feature("android"):
		get_tree().reload_current_scene.call_deferred()


## Ligne d'une application CoccOs : case d'activation + description.
## Décochée = l'icône disparaît du bureau de l'enfant (rien n'est désinstallé).
func _creer_ligne_coccos(appli: Dictionary) -> Control:
	var ligne := HBoxContainer.new()
	ligne.alignment = BoxContainer.ALIGNMENT_CENTER
	ligne.add_theme_constant_override("separation", 18)

	var pastille := ColorRect.new()
	pastille.color = appli["couleur"]
	pastille.custom_minimum_size = Vector2(20, 20)
	ligne.add_child(pastille)

	var case_appli := CheckBox.new()
	case_appli.text = " " + Lang.t(appli["description_cle"])
	case_appli.add_theme_font_size_override("font_size", 26)
	for etat in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		case_appli.add_theme_color_override(etat, Color.WHITE)
	case_appli.button_pressed = Registre.est_active(appli["id"])
	var id: String = appli["id"]
	case_appli.toggled.connect(func(actif: bool) -> void:
		Registre.activer(id, actif))
	ligne.add_child(case_appli)
	return ligne


func _creer_ligne(appli: Dictionary) -> Control:
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 18)
	ligne.alignment = BoxContainer.ALIGNMENT_CENTER

	var installee: bool = AppliExternes.est_installee(appli)

	var case_appli := CheckBox.new()
	case_appli.text = " " + Lang.t(appli["description_cle"])
	case_appli.add_theme_font_size_override("font_size", 27)
	for etat in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		case_appli.add_theme_color_override(etat, Color.WHITE)
	case_appli.button_pressed = AppliExternes.est_active(appli["id"])
	case_appli.disabled = not installee
	var id: String = appli["id"]
	case_appli.toggled.connect(func(actif: bool) -> void:
		PinConfig.ecrire_option("applis_externes", id, actif))
	ligne.add_child(case_appli)

	var statut := Label.new()
	statut.add_theme_font_size_override("font_size", 22)
	ligne.add_child(statut)

	if installee:
		statut.text = Lang.t("applis_statut_installee")
		statut.add_theme_color_override("font_color", Color(0.55, 0.95, 0.60))
	else:
		statut.text = Lang.t("applis_statut_non_installee")
		statut.add_theme_color_override("font_color", Color(1.0, 0.6, 0.45))
		# Bouton Installer : dialogue de mot de passe graphique, jamais de terminal
		var btn_installer := Button.new()
		btn_installer.text = Lang.t("applis_btn_installer")
		btn_installer.custom_minimum_size = Vector2(170, 52)
		btn_installer.add_theme_font_size_override("font_size", 24)
		UIStyle.styliser(btn_installer, Color(0.25, 0.45, 0.75), 12)
		btn_installer.pressed.connect(
			_installer.bind(appli, case_appli, statut, btn_installer))
		ligne.add_child(btn_installer)

	return ligne


## Lance l'installation et surveille sa fin pour mettre la ligne à jour.
func _installer(appli: Dictionary, case_appli: CheckBox, statut: Label, btn: Button) -> void:
	var pid: int = AppliExternes.installer(appli)
	if pid == -1:
		# L'installation se fait ailleurs (fiche Play Store sur Android,
		# logithèque sur Linux) — l'adulte installe là-bas puis revient
		statut.text = Lang.t("applis_statut_play_store" if OS.has_feature("android")
			else "applis_statut_logitheque")
		statut.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
		return
	btn.disabled = true
	statut.text = Lang.t("applis_statut_en_cours")
	statut.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	# Surveillance douce toutes les 2 s jusqu'à la fin du processus
	while OS.is_process_running(pid):
		await get_tree().create_timer(2.0).timeout
		if not is_instance_valid(statut):
			return  # l'écran a été quitté pendant l'installation
	if AppliExternes.est_installee(appli):
		statut.text = Lang.t("applis_statut_installee")
		statut.add_theme_color_override("font_color", Color(0.55, 0.95, 0.60))
		case_appli.disabled = false
		btn.visible = false
	else:
		# Annulée (mot de passe refusé) ou échec — on peut réessayer
		statut.text = Lang.t("applis_statut_echec")
		statut.add_theme_color_override("font_color", Color(1.0, 0.6, 0.45))
		btn.disabled = false


func _retour_reglages() -> void:
	get_tree().change_scene_to_file("res://scenes/adult_settings.tscn")
