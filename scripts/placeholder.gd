## Écran placeholder — affiché en attente de l'activité réelle.
## Contient un message et un bouton retour vers le tableau de bord.
extends Control

const Fond = preload("res://scripts/fond.gd")
const Lang = preload("res://scripts/lang.gd")

func _ready() -> void:
	# --- Fond d'écran partagé (image prairie + repli couleur) ---
	Fond.appliquer(self)

	# --- Conteneur vertical centré ---
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centre)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 48)
	centre.add_child(vbox)

	# --- Grand label ---
	var label := Label.new()
	label.text = Lang.t("placeholder_message")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 52)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color(0.10, 0.12, 0.10))
	label.add_theme_constant_override("outline_size", 8)
	vbox.add_child(label)

	# --- Bouton retour ---
	var btn_retour := Button.new()
	btn_retour.text = Lang.t("placeholder_retour")
	btn_retour.custom_minimum_size = Vector2(300, 90)
	btn_retour.add_theme_font_size_override("font_size", 36)

	# Style du bouton retour
	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = Color(0.20, 0.55, 0.85)
	style_normal.corner_radius_top_left    = 16
	style_normal.corner_radius_top_right   = 16
	style_normal.corner_radius_bottom_left  = 16
	style_normal.corner_radius_bottom_right = 16
	btn_retour.add_theme_stylebox_override("normal", style_normal)

	var style_hover := StyleBoxFlat.new()
	style_hover.bg_color = Color(0.30, 0.65, 0.95)
	style_hover.corner_radius_top_left    = 16
	style_hover.corner_radius_top_right   = 16
	style_hover.corner_radius_bottom_left  = 16
	style_hover.corner_radius_bottom_right = 16
	btn_retour.add_theme_stylebox_override("hover", style_hover)

	var style_focus := StyleBoxFlat.new()
	style_focus.bg_color = Color(0.25, 0.60, 0.90)
	style_focus.border_width_top    = 4
	style_focus.border_width_bottom = 4
	style_focus.border_width_left   = 4
	style_focus.border_width_right  = 4
	style_focus.border_color = Color(1.0, 1.0, 0.2)
	style_focus.corner_radius_top_left    = 16
	style_focus.corner_radius_top_right   = 16
	style_focus.corner_radius_bottom_left  = 16
	style_focus.corner_radius_bottom_right = 16
	btn_retour.add_theme_stylebox_override("focus", style_focus)

	btn_retour.add_theme_color_override("font_color", Color.WHITE)
	btn_retour.add_theme_color_override("font_hover_color", Color.WHITE)
	btn_retour.add_theme_color_override("font_focus_color", Color.WHITE)

	vbox.add_child(btn_retour)

	# Connecte le bouton retour
	btn_retour.pressed.connect(_retour_tableau_de_bord)

	# --- Focus clavier initial ---
	btn_retour.grab_focus()


## Retourne au bureau de l'enfant.
func _retour_tableau_de_bord() -> void:
	get_tree().change_scene_to_file("res://scenes/bureau.tscn")
