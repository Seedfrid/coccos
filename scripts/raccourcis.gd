## Icônes directes sur l'appareil — « Mon classeur » sans passer par le bureau
## (chantier 2026-07-10, motivation : inciter Isabella à lancer sa voix d'un geste).
## v1 : Linux (entrée de menu ~/.local/share/applications, standard freedesktop).
## Windows : le raccourci « Mon classeur » est posé par l'installeur NSIS.
## Android (raccourci épinglé) : session dédiée avec téléphone — pas de code aveugle.
extends Object

const Lang = preload("res://scripts/lang.gd")


## L'appareil sait-il créer des icônes directes depuis les réglages ?
static func possible() -> bool:
	return OS.get_name() == "Linux"


## Crée l'icône directe de l'appli — renvoie la clé du message à afficher.
static func creer(id: String, nom: String) -> String:
	if not possible():
		return "logitheque_raccourci_impossible"
	var domicile := OS.get_environment("HOME")
	if domicile == "":
		return "logitheque_raccourci_echec"

	# Icône : le PNG de l'appli exporté vers le thème d'icônes de l'utilisateur
	var nom_icone := "coccos-" + id
	var dossier_icones := domicile + "/.local/share/icons/hicolor/256x256/apps"
	DirAccess.make_dir_recursive_absolute(dossier_icones)
	var texture: Texture2D = load("res://assets/icones/%s.png" % id)
	if texture != null:
		texture.get_image().save_png(dossier_icones + "/" + nom_icone + ".png")
	else:
		nom_icone = "coccos"  # repli : la coccinelle du paquet

	# La ligne de commande : paquet installé si présent, sinon le binaire courant
	var commande := ""
	if FileAccess.file_exists("/usr/bin/coccos"):
		commande = "/usr/bin/coccos --app " + id
	else:
		commande = "%s --path %s -- --app %s" % [
			OS.get_executable_path(), ProjectSettings.globalize_path("res://").rstrip("/"), id]

	var dossier_apps := domicile + "/.local/share/applications"
	DirAccess.make_dir_recursive_absolute(dossier_apps)
	var fichier := FileAccess.open("%s/coccos-%s.desktop" % [dossier_apps, id],
		FileAccess.WRITE)
	if fichier == null:
		return "logitheque_raccourci_echec"
	fichier.store_string("""[Desktop Entry]
Type=Application
Name=%s
Exec=%s
Icon=%s
Terminal=false
Categories=Education;KidsGame;
""" % [nom, commande, nom_icone])
	fichier.close()
	return "logitheque_raccourci_cree"
