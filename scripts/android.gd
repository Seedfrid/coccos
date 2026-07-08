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
