## Vidéothèque de « Ma télé » — la liste fermée de vidéos choisies par l'adulte
## (spec : DOCS/specs/spec-tele.md). Tout est fichier, dans user://tele/ :
##   <titre>.ogv   la vidéo (Ogg Theora — seul format natif de Godot)
##   <titre>.png   la vignette du mur (image extraite de la vidéo)
## Le titre affiché = le nom du fichier ; l'ordre du mur = l'ordre alphabétique
## (préfixer « 01 », « 02 »… pour ordonner). Déposer un .ogv à la main marche
## aussi (vignette générique tant que le .png manque).
##
## Conversion à l'import (Réglages → Télé) : ffmpeg → .ogv 720p + vignette.
##   - Linux   : ffmpeg du système (installation graphique pkexec sinon)
##   - Windows : ffmpeg.exe fourni à côté de coccos.exe (embarqué à l'installeur)
##   - Android : pas de conversion — dépôt de .ogv déjà convertis uniquement
extends RefCounted

const DOSSIER := "user://tele"


## Les vidéos du mur : [{ "nom", "chemin", "vignette": ImageTexture|null }],
## triées par nom (l'ordre alphabétique fait l'ordre du mur).
static func lister() -> Array:
	DirAccess.make_dir_recursive_absolute(DOSSIER)
	var liste := []
	var noms := []
	for fichier in DirAccess.get_files_at(DOSSIER):
		if fichier.get_extension().to_lower() == "ogv":
			noms.append(fichier.get_basename())
	noms.sort()
	for nom in noms:
		liste.append({
			"nom": nom,
			"chemin": DOSSIER + "/" + nom + ".ogv",
			"vignette": _charger_vignette(nom),
		})
	return liste


## Le convertisseur est-il là ? Chemin de ffmpeg, ou "" (selon la plateforme).
static func chemin_ffmpeg() -> String:
	if OS.has_feature("android") or OS.has_feature("web"):
		return ""
	if OS.has_feature("windows"):
		var local := OS.get_executable_path().get_base_dir().path_join("ffmpeg.exe")
		return local if FileAccess.file_exists(local) else ""
	var sortie := []
	if OS.execute("which", ["ffmpeg"], sortie) == 0 and sortie.size() > 0:
		return String(sortie[0]).strip_edges()
	return ""


## Lance la CONVERSION d'une vidéo vers la vidéothèque (non bloquant).
## Renvoie le PID à surveiller (OS.is_process_running), ou -1 si impossible.
## Un fichier déjà en .ogv est simplement copié (pas de conversion, PID -1 mais
## succès immédiat — tester le retour de fichier_pret()).
static func importer(source: String, nom: String) -> int:
	DirAccess.make_dir_recursive_absolute(DOSSIER)
	nom = nom_propre(nom)
	if source.get_extension().to_lower() == "ogv":
		DirAccess.copy_absolute(source, DOSSIER + "/" + nom + ".ogv")
		return -1
	var ffmpeg := chemin_ffmpeg()
	if ffmpeg == "":
		return -1
	return OS.create_process(ffmpeg, [
		"-y", "-i", source,
		"-c:v", "libtheora", "-q:v", "6", "-vf", "scale=-2:720",
		"-c:a", "libvorbis", "-q:a", "4",
		ProjectSettings.globalize_path(DOSSIER + "/" + nom + ".ogv"),
	])


## Extrait la vignette du mur depuis la vidéo convertie. Le filtre `thumbnail`
## choisit une image représentative — fonctionne quelle que soit la durée
## (un `-ss` fixe échouerait sur une vidéo plus courte que le décalage).
## Non bloquant — renvoie le PID, ou -1 sans ffmpeg.
static func generer_vignette(nom: String) -> int:
	var ffmpeg := chemin_ffmpeg()
	if ffmpeg == "":
		return -1
	return OS.create_process(ffmpeg, [
		"-y", "-i",
		ProjectSettings.globalize_path(DOSSIER + "/" + nom + ".ogv"),
		"-vf", "thumbnail,scale=480:-2", "-frames:v", "1",
		ProjectSettings.globalize_path(DOSSIER + "/" + nom + ".png"),
	])


## La vidéo est-elle bien arrivée dans la vidéothèque ?
static func fichier_pret(nom: String) -> bool:
	return FileAccess.file_exists(DOSSIER + "/" + nom_propre(nom) + ".ogv")


static func renommer(ancien: String, nouveau: String) -> bool:
	nouveau = nom_propre(nouveau)
	if nouveau == "" or nouveau == ancien:
		return false
	if FileAccess.file_exists(DOSSIER + "/" + nouveau + ".ogv"):
		return false  # collision : on ne remplace jamais sans le dire
	DirAccess.rename_absolute(DOSSIER + "/" + ancien + ".ogv", DOSSIER + "/" + nouveau + ".ogv")
	if FileAccess.file_exists(DOSSIER + "/" + ancien + ".png"):
		DirAccess.rename_absolute(DOSSIER + "/" + ancien + ".png", DOSSIER + "/" + nouveau + ".png")
	return true


static func retirer(nom: String) -> void:
	DirAccess.remove_absolute(DOSSIER + "/" + nom + ".ogv")
	if FileAccess.file_exists(DOSSIER + "/" + nom + ".png"):
		DirAccess.remove_absolute(DOSSIER + "/" + nom + ".png")


## Nom de fichier sûr : sans séparateurs ni caractères interdits.
static func nom_propre(nom: String) -> String:
	var propre := nom.strip_edges()
	for interdit in ["/", "\\", ":", "*", "?", "\"", "<", ">", "|"]:
		propre = propre.replace(interdit, " ")
	return propre.strip_edges()


static func _charger_vignette(nom: String) -> ImageTexture:
	var chemin := DOSSIER + "/" + nom + ".png"
	if not FileAccess.file_exists(chemin):
		return null
	var image := Image.new()
	if image.load(chemin) != OK:
		return null
	return ImageTexture.create_from_image(image)
