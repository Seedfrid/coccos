## Pont Android — les trois gestes dont la logithèque a besoin sur Android,
## via le pont Java de Godot (singleton AndroidRuntime, Godot 4.4+) :
##   - paquet_installe("org.tuxpaint.android") → l'appli est-elle sur l'appareil ?
##   - lancer_paquet("org.tuxpaint.android")   → l'ouvrir (intent de lancement)
##   - ouvrir_fiche("org.tuxpaint.android")    → sa fiche Play Store (market://,
##     repli navigateur) — l'installation graphique, jamais de terminal.
## Hors Android (PC, web), tout est inerte et sans erreur : disponible() = false.
##
## ⚠️ Android 11+ filtre la « visibilité des paquets » : sans déclaration
## <queries> dans le manifeste, la détection peut renvoyer faux pour une appli
## pourtant installée. À vérifier sur appareil réel ; le remède est un build
## gradle avec <queries> (les paquets du catalogue) — pas un changement de code.
extends RefCounted

const PinConfig = preload("res://scripts/pin_config.gd")


## Le pont Java est-il là ? (vrai seulement dans un export Android)
static func disponible() -> bool:
	return OS.has_feature("android") and Engine.has_singleton("AndroidRuntime")


static func _activite() -> Object:
	if not disponible():
		return null
	return Engine.get_singleton("AndroidRuntime").getActivity()


## L'appli est-elle installée ? (via son intent de lancement)
static func paquet_installe(paquet: String) -> bool:
	var activite := _activite()
	if activite == null:
		return false
	var intent = activite.getPackageManager().getLaunchIntentForPackage(paquet)
	return intent != null


## Ouvre l'appli. Retourne faux si elle est introuvable (rien ne se passe alors).
static func lancer_paquet(paquet: String) -> bool:
	var activite := _activite()
	if activite == null:
		return false
	var intent = activite.getPackageManager().getLaunchIntentForPackage(paquet)
	if intent == null:
		push_warning("Appli Android introuvable : " + paquet)
		return false
	activite.startActivity(intent)
	return true


## Fiche de l'appli dans le Play Store (repli : la page web du store).
static func ouvrir_fiche(paquet: String) -> void:
	if OS.shell_open("market://details?id=" + paquet) != OK:
		OS.shell_open("https://play.google.com/store/apps/details?id=" + paquet)


# --- Les applications du téléphone sur le bureau (logithèque phase B) --------------
#     Pont validé pas à pas sur appareil (Galaxy S22, Android 16, 2026-07-10) :
#     champs Java fermés au pont → RÉFLEXION (getClass().getField().get()) ;
#     icône système = Drawable → Bitmap (Canvas) → PNG (byte[] ↔ PackedByteArray).

const DOSSIER_ICONES := "user://icones_android"


## Les applications lançables du téléphone : [{paquet, nom}], triées par nom.
static func applis_lancables() -> Array:
	var resultat := []
	var activite := _activite()
	if activite == null:
		return resultat
	var pm = activite.getPackageManager()
	var ClasseIntent = JavaClassWrapper.wrap("android.content.Intent")
	var intention = ClasseIntent.Intent()
	intention.setAction("android.intent.action.MAIN")
	intention.addCategory("android.intent.category.LAUNCHER")
	var liste = pm.queryIntentActivities(intention, 0)
	if liste == null:
		return resultat
	var moi := str(activite.getPackageName())
	for i in liste.size():
		var info = liste.get(i)
		var paquet := _paquet_de(info)
		if paquet == "" or paquet == moi:
			continue
		resultat.append({"paquet": paquet, "nom": str(info.loadLabel(pm))})
	resultat.sort_custom(func(a, b): return String(a["nom"]).naturalnocasecmp_to(b["nom"]) < 0)
	return resultat


## Nom de paquet d'un ResolveInfo — champs publics lus par réflexion.
static func _paquet_de(info) -> String:
	var champ_ai = info.getClass().getField("activityInfo")
	if champ_ai == null:
		return ""
	var infos_activite = champ_ai.get(info)
	if infos_activite == null:
		return ""
	var champ_pkg = infos_activite.getClass().getField("packageName")
	if champ_pkg == null:
		return ""
	var paquet = champ_pkg.get(infos_activite)
	# Field.get() rend un OBJET Java même pour une String — str() n'en donnerait
	# que la représentation « <JavaObject:…> » ; toString() est, lui, converti.
	return str(paquet.toString()) if paquet != null else ""


## L'icône de l'appli, dessinée par Android puis compressée en PNG (96×96).
static func icone_appli_png(paquet: String) -> PackedByteArray:
	var vide := PackedByteArray()
	var activite := _activite()
	if activite == null:
		return vide
	var dessin = activite.getPackageManager().getApplicationIcon(paquet)
	if dessin == null:
		return vide
	var ClasseBitmap = JavaClassWrapper.wrap("android.graphics.Bitmap")
	var config = JavaClassWrapper.wrap("android.graphics.Bitmap$Config").valueOf("ARGB_8888")
	var bitmap = ClasseBitmap.createBitmap(96, 96, config)
	var toile = JavaClassWrapper.wrap("android.graphics.Canvas").Canvas(bitmap)
	if bitmap == null or toile == null:
		return vide
	dessin.setBounds(0, 0, 96, 96)
	dessin.draw(toile)
	var flux = JavaClassWrapper.wrap("java.io.ByteArrayOutputStream").ByteArrayOutputStream()
	var format_png = JavaClassWrapper.wrap("android.graphics.Bitmap$CompressFormat").valueOf("PNG")
	if flux == null or not bitmap.compress(format_png, 100, flux):
		return vide
	var octets = flux.toByteArray()
	return octets if octets is PackedByteArray else vide


## Les applis du téléphone choisies pour le bureau : { paquet: nom }.
static func choisies() -> Dictionary:
	var choix: Dictionary = PinConfig.lire_option("logitheque", "android_bureau", {})
	# Assainissement : purge d'éventuelles clés « <JavaObject:… » (bug de dev
	# corrigé le 2026-07-10 avant diffusion — champ lu sans toString)
	var sales := []
	for cle in choix:
		if String(cle).begins_with("<JavaObject"):
			sales.append(cle)
	if not sales.is_empty():
		for cle in sales:
			choix.erase(cle)
		PinConfig.ecrire_option("logitheque", "android_bureau", choix)
	return choix


## Coche/décoche une appli du téléphone — l'icône système est déposée (ou ôtée)
## dans user://icones_android/ pour que le bureau l'affiche telle quelle.
static func choisir(paquet: String, nom: String, actif: bool) -> void:
	var choix := choisies()
	if actif:
		choix[paquet] = nom
		var octets := icone_appli_png(paquet)
		if not octets.is_empty():
			DirAccess.make_dir_recursive_absolute(DOSSIER_ICONES)
			var fichier := FileAccess.open(chemin_icone(paquet), FileAccess.WRITE)
			if fichier != null:
				fichier.store_buffer(octets)
				fichier.close()
	else:
		choix.erase(paquet)
		DirAccess.remove_absolute(chemin_icone(paquet))
	PinConfig.ecrire_option("logitheque", "android_bureau", choix)


static func chemin_icone(paquet: String) -> String:
	return "%s/%s.png" % [DOSSIER_ICONES, paquet]


# --- Mode bureau (launcher) ---------------------------------------------------------

## Ouvre le réglage Android « Écran d'accueil » — la sortie du mode bureau :
## le parent y rebascule sur le lanceur d'origine (et pourra remettre CoccOs
## par le même chemin). Lancer directement l'autre lanceur ne marche pas
## partout : sur MIUI, le lanceur Xiaomi non-défaut ne sait afficher que
## l'écran des applis récentes (constaté le 2026-07-10).
static func ouvrir_reglage_bureau() -> bool:
	var activite := _activite()
	if activite == null:
		return false
	var ClasseIntent = JavaClassWrapper.wrap("android.content.Intent")
	var intention = ClasseIntent.Intent()
	intention.setAction("android.settings.HOME_SETTINGS")
	intention.addFlags(268435456)  # FLAG_ACTIVITY_NEW_TASK
	activite.startActivity(intention)
	return true
