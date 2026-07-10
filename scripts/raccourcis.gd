## Icônes directes sur l'appareil — « Mon classeur » sans passer par le bureau
## (chantier 2026-07-10, motivation : inciter Isabella à lancer sa voix d'un geste).
## - Linux : entrée de menu ~/.local/share/applications (standard freedesktop).
## - Android : RACCOURCI ÉPINGLÉ sur l'écran d'accueil, par le pont Java —
##   chemin validé pas à pas sur appareil (Galaxy S22, Android 16, 2026-07-10) :
##   constructeurs via JavaClassWrapper (classe imbriquée = .call("Classe$Imbriquée")),
##   icône = NOTRE png décodé en Bitmap (les champs Java sont inaccessibles,
##   les PackedByteArray passent en byte[]), intent porteur de l'extra
##   « coccos_app » (lu par lancement.gd — le gabarit Godot ignore command_line).
## - Windows : le raccourci « Mon classeur » est posé par l'installeur NSIS.
extends Object

const Lang = preload("res://scripts/lang.gd")


## L'appareil sait-il créer des icônes directes depuis les réglages ?
static func possible() -> bool:
	return OS.get_name() == "Linux" \
		or (OS.has_feature("android") and Engine.has_singleton("AndroidRuntime"))


## Crée l'icône directe de l'appli — renvoie la clé du message à afficher.
static func creer(id: String, nom: String) -> String:
	if OS.has_feature("android"):
		return _creer_android(id, nom)
	if OS.get_name() == "Linux":
		return _creer_linux(id, nom)
	return "logitheque_raccourci_impossible"


# --- Android : raccourci épinglé (écran d'accueil) --------------------------------

static func _creer_android(id: String, nom: String) -> String:
	var runtime = Engine.get_singleton("AndroidRuntime")
	if runtime == null:
		return "logitheque_raccourci_impossible"
	var activite = runtime.getActivity()
	if activite == null:
		return "logitheque_raccourci_echec"
	var gestionnaire = activite.getSystemService("shortcut")
	if gestionnaire == null or not gestionnaire.isRequestPinShortcutSupported():
		return "logitheque_raccourci_impossible"

	# L'intent du raccourci : relance CoccOs avec notre extra « coccos_app »
	var ClasseIntent = JavaClassWrapper.wrap("android.content.Intent")
	var intention = ClasseIntent.Intent()
	if intention == null:
		return "logitheque_raccourci_echec"
	intention.setAction("android.intent.action.MAIN")
	intention.setClassName(activite, activite.getClass().getName())
	intention.putExtra("coccos_app", id)

	# L'icône : le PNG de l'appli (livrée coccinelle) décodé en Bitmap Android
	var icone = null
	var ClasseIcone = JavaClassWrapper.wrap("android.graphics.drawable.Icon")
	var texture: Texture2D = load("res://assets/icones/%s.png" % id)
	if texture != null and ClasseIcone != null:
		var octets := texture.get_image().save_png_to_buffer()
		var Fabrique = JavaClassWrapper.wrap("android.graphics.BitmapFactory")
		var bitmap = Fabrique.decodeByteArray(octets, 0, octets.size()) \
			if Fabrique != null else null
		if bitmap != null:
			icone = ClasseIcone.createWithBitmap(bitmap)

	var ClasseBuilder = JavaClassWrapper.wrap("android.content.pm.ShortcutInfo$Builder")
	if ClasseBuilder == null:
		return "logitheque_raccourci_echec"
	var batisseur = ClasseBuilder.call("ShortcutInfo$Builder", activite, "coccos-" + id)
	if batisseur == null:
		return "logitheque_raccourci_echec"
	batisseur.setShortLabel(nom)
	if icone != null:
		batisseur.setIcon(icone)
	batisseur.setIntent(intention)
	var fiche = batisseur.build()
	if fiche == null or not gestionnaire.requestPinShortcut(fiche, null):
		return "logitheque_raccourci_echec"
	return "logitheque_raccourci_android"  # Android affiche sa confirmation à l'écran


# --- Linux : entrée de menu freedesktop --------------------------------------------

static func _creer_linux(id: String, nom: String) -> String:
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
