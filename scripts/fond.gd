## Helper de fond d'écran partagé pour les écrans enfant.
## Applique l'image de prairie en plein écran (mode « couvrir »),
## avec un repli sur une couleur unie si l'image est absente.
## Usage dans _ready() d'un écran : Fond.appliquer(self)
extends RefCounted
## (Pas de class_name : les écrans font un preload explicite pour fiabiliser
##  le chargement même quand le cache de classes globales n'est pas encore construit.)

const CHEMIN_IMAGE := "res://assets/backgrounds/fond_prairie.png"
const COULEUR_REPLI := Color(0.90, 0.94, 0.86)  # vert très pâle (repli)


## Ajoute le fond comme tout premier enfant de l'écran (donc derrière le reste).
static func appliquer(ecran: Control) -> void:
	# Repli couleur unie (toujours présent, garantit un fond même sans image)
	var base := ColorRect.new()
	base.color = COULEUR_REPLI
	base.set_anchors_preset(Control.PRESET_FULL_RECT)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ecran.add_child(base)

	# Image, si elle est disponible
	if ResourceLoader.exists(CHEMIN_IMAGE):
		var texture: Texture2D = load(CHEMIN_IMAGE)
		if texture != null:
			var tr := TextureRect.new()
			tr.texture = texture
			tr.set_anchors_preset(Control.PRESET_FULL_RECT)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ecran.add_child(tr)
