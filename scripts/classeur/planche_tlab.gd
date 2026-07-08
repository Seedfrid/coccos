## Parseur de planche TLAb — lit un export SVG de l'outil TLAb
## (https://techlab-handicap.org/apps/tlab/ — TechLab APF France handicap),
## le format des planches de communication réelles d'Isabella.
##
## Un SVG TLAb est AUTO-PORTEUR : viewBox A4 paysage (297×210), une cellule
## par groupe <g transform="translate(x,y)" data-index="n"> contenant :
##   <rect>   le cadre (taille, couleur de fond)
##   <image>  le pictogramme ARASAAC, PNG encodé en base64 (data-id = n° ARASAAC)
##   <text>   le libellé (parfois sur plusieurs nœuds → joints par une espace)
##
## charger(chemin) → { "nom": String, "page": Vector2, "cellules": [
##   { "position": Vector2, "taille": Vector2, "fond": Color,
##     "texture": ImageTexture|null, "libelle": String } ] }
## Renvoie {} si le fichier est illisible ou sans cellules.
## Positions/tailles dans le repère de la page (297×210) : l'écran applique
## son échelle — la planche numérique reste FIDÈLE à la planche papier.
extends RefCounted

const TAILLE_PAGE := Vector2(297.0, 210.0)


static func charger(chemin: String) -> Dictionary:
	var fichier := FileAccess.open(chemin, FileAccess.READ)
	if fichier == null:
		push_warning("Planche illisible : " + chemin)
		return {}
	var svg := fichier.get_as_text()
	fichier.close()

	var re_cellule := RegEx.create_from_string(
		"<g [^>]*transform=\"translate\\(([\\d.]+), ([\\d.]+)\\)\"[^>]*>(.*?)</g>")
	var re_rect := RegEx.create_from_string(
		"<rect [^>]*width=\"([\\d.]+)\" height=\"([\\d.]+)\" fill=\"([^\"]*)\"")
	var re_image := RegEx.create_from_string(
		"xlink:href=\"data:image/png;base64,([A-Za-z0-9+/=]+)\"")
	var re_texte := RegEx.create_from_string("<text[^>]*>([^<]*)</text>")

	var cellules := []
	for morceau in re_cellule.search_all(svg):
		var contenu := morceau.get_string(3)
		var cellule := {
			"position": Vector2(morceau.get_string(1).to_float(), morceau.get_string(2).to_float()),
			"taille": Vector2.ZERO,
			"fond": Color.WHITE,
			"texture": null,
			"libelle": "",
		}
		var rect := re_rect.search(contenu)
		if rect:
			cellule["taille"] = Vector2(rect.get_string(1).to_float(), rect.get_string(2).to_float())
			cellule["fond"] = Color.from_string(rect.get_string(3), Color.WHITE)
		var image := re_image.search(contenu)
		if image:
			cellule["texture"] = _texture_depuis_base64(image.get_string(1))
		var lignes := PackedStringArray()
		for texte in re_texte.search_all(contenu):
			var propre := texte.get_string(1).strip_edges()
			if propre != "":
				lignes.append(propre)
		cellule["libelle"] = " ".join(lignes)
		if cellule["taille"] != Vector2.ZERO:
			cellules.append(cellule)

	if cellules.is_empty():
		push_warning("Aucune cellule TLAb dans : " + chemin)
		return {}
	return {
		"nom": chemin.get_file().get_basename(),
		"page": TAILLE_PAGE,
		"cellules": cellules,
	}


## Les planches disponibles : embarquées (res://classeur/) + déposées
## (user://classeur/, prioritaires à nom égal — même principe que les voix).
## Renvoie { nom: chemin } trié par nom.
static func lister_planches() -> Dictionary:
	# Le dossier de dépôt est créé s'il manque : l'adulte le trouve tout prêt
	DirAccess.make_dir_recursive_absolute("user://classeur")
	var planches := {}
	for dossier in ["res://classeur", "user://classeur"]:
		for fichier in DirAccess.get_files_at(dossier):
			var extension := fichier.get_extension().to_lower()
			if extension == "tlab" or extension == "svg":
				planches[fichier.get_basename()] = dossier + "/" + fichier
	var tries := {}
	var noms := planches.keys()
	noms.sort()
	for nom in noms:
		tries[nom] = planches[nom]
	return tries


static func _texture_depuis_base64(donnees: String) -> ImageTexture:
	var image := Image.new()
	if image.load_png_from_buffer(Marshalls.base64_to_raw(donnees)) != OK:
		return null
	return ImageTexture.create_from_image(image)
