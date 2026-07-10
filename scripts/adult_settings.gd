## Écran réglages adulte — hub central : renvoie vers les sections de réglages.
## Accessible uniquement après saisie du code PIN correct.
## Les réglages eux-mêmes vivent dans des sous-écrans (souris, interface…) pour
## que cet écran reste léger et tienne toujours dans la fenêtre.
extends Control

const UIStyle = preload("res://scripts/ui_style.gd")
const Lang = preload("res://scripts/lang.gd")

## Sections du hub : [clé de libellé, couleur, méthode de navigation]
const SECTIONS := [
	["reglages_souris", Color(0.25, 0.45, 0.75), "_aller_reglages_souris"],
	["reglages_clavier", Color(0.25, 0.60, 0.40), "_aller_reglages_clavier"],
	["reglages_interface", Color(0.45, 0.35, 0.70), "_aller_reglages_interface"],
	["reglages_applis", Color(0.20, 0.60, 0.55), "_aller_reglages_applis"],
	["reglages_classeur", Color(0.75, 0.35, 0.40), "_aller_reglages_classeur"],
	["reglages_tele", Color(0.45, 0.40, 0.85), "_aller_reglages_tele"],
	["reglages_espace", Color(0.60, 0.45, 0.20), "_aller_reglages_espace"],
	["reglages_langue", Color(0.35, 0.55, 0.30), "_aller_reglages_langue"],
	["reglages_changer_pin", Color(0.55, 0.35, 0.10), "_changer_pin"],
]


func _ready() -> void:
	# --- Fond plein (vert-bleu foncé, atmosphère adulte/sérieuse) ---
	var fond := ColorRect.new()
	fond.color = Color(0.12, 0.25, 0.22)
	fond.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fond)

	# --- Zone défilante (molette + barre si le contenu dépasse) + centrage ---
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
	# Séparation compacte : le hub doit toujours tenir sous 720 px de haut
	vbox.add_theme_constant_override("separation", 18)
	centre.add_child(vbox)

	# --- Titre ---
	var titre := Label.new()
	titre.text = Lang.t("reglages_titre")
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.add_theme_font_size_override("font_size", 48)
	titre.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(titre)

	# --- Texte informatif (une ligne, discret) ---
	var info := Label.new()
	info.text = Lang.t("reglages_info")
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 22)
	info.add_theme_color_override("font_color", Color(0.78, 0.88, 0.82))
	vbox.add_child(info)

	# --- Boutons de sections ---
	var premier: Button = null
	for section in SECTIONS:
		var btn := _creer_bouton(Lang.t(section[0]), section[1])
		btn.pressed.connect(Callable(self, section[2]))
		vbox.add_child(btn)
		if premier == null:
			premier = btn

	# --- Bouton retour au bureau ---
	var btn_retour := _creer_bouton(Lang.t("reglages_retour"), Color(0.20, 0.55, 0.45))
	btn_retour.pressed.connect(_retour_tableau_de_bord)
	vbox.add_child(btn_retour)

	premier.grab_focus()


## Échap = revenir au bureau (réflexe universel).
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_retour_tableau_de_bord()


func _creer_bouton(libelle: String, couleur: Color) -> Button:
	var btn := Button.new()
	btn.text = libelle
	btn.custom_minimum_size = Vector2(460, 76)
	btn.add_theme_font_size_override("font_size", 28)
	UIStyle.styliser(btn, couleur, 16)
	return btn


## Navigue vers le sous-écran des applications externes.
func _aller_reglages_applis() -> void:
	get_tree().change_scene_to_file("res://scenes/reglages_applis.tscn")


## Navigue vers le sous-écran du classeur de communication.
func _aller_reglages_classeur() -> void:
	get_tree().change_scene_to_file("res://scenes/reglages_classeur.tscn")


## Navigue vers le sous-écran de la télé.
func _aller_reglages_tele() -> void:
	get_tree().change_scene_to_file("res://scenes/reglages_tele.tscn")


## Navigue vers le sous-écran de l'espace famille.
func _aller_reglages_espace() -> void:
	get_tree().change_scene_to_file("res://scenes/reglages_espace.tscn")


## Navigue vers le sous-écran de langue (sélecteur + éditeur de traduction).
func _aller_reglages_langue() -> void:
	get_tree().change_scene_to_file("res://scenes/reglages_langue.tscn")


## Navigue vers le sous-écran des réglages souris.
func _aller_reglages_souris() -> void:
	get_tree().change_scene_to_file("res://scenes/reglages_souris.tscn")


## Navigue vers le sous-écran des réglages clavier.
func _aller_reglages_clavier() -> void:
	get_tree().change_scene_to_file("res://scenes/reglages_clavier.tscn")


## Navigue vers le sous-écran des réglages d'interface.
func _aller_reglages_interface() -> void:
	get_tree().change_scene_to_file("res://scenes/reglages_interface.tscn")


## Navigue vers l'écran de changement du code PIN.
func _changer_pin() -> void:
	get_tree().change_scene_to_file("res://scenes/change_pin.tscn")


## Retourne au bureau de l'enfant.
func _retour_tableau_de_bord() -> void:
	get_tree().change_scene_to_file("res://scenes/bureau.tscn")
