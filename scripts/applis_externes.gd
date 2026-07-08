## Catalogue des applications externes lançables depuis le bureau enfant.
## Philosophie : les meilleures applis libres (TuxPaint…) deviennent des icônes
## du bureau, avec nos règles — on ne les réinvente pas.
## L'adulte coche celles qu'il veut dans Réglages → Applications externes ;
## seules les applis cochées ET réellement installées apparaissent sur le bureau.
##
## Multi-plateforme (2026-07-07) :
##   - Linux : détection `which <executable>`, installation pkexec/apt,
##     lancement OS.create_process.
##   - Android : détection/lancement par nom de paquet (pont android.gd),
##     installation = fiche Play Store. Une appli sans "paquet_android"
##     (TuxMath) n'existe pas sur Android : elle n'y est pas proposée.
extends RefCounted

const PinConfig := preload("res://scripts/pin_config.gd")
const Lang = preload("res://scripts/lang.gd")
const Android := preload("res://scripts/android.gd")

const CATALOGUE := [
	{"id": "tuxpaint", "nom_cle": "bureau_app_dessin", "picto": "dessin", "couleur": Color(0.20, 0.70, 0.65),
		"executable": "tuxpaint", "paquet": "tuxpaint",
		"paquet_android": "org.tuxpaint.android", "description_cle": "applis_desc_tuxpaint"},
	{"id": "gcompris", "nom_cle": "bureau_app_gcompris", "picto": "puzzles", "couleur": Color(0.95, 0.55, 0.15),
		"executable": "gcompris-qt", "paquet": "gcompris-qt",
		"paquet_android": "net.gcompris.full", "description_cle": "applis_desc_gcompris"},
	{"id": "tuxmath", "nom_cle": "bureau_app_maths", "picto": "maths", "couleur": Color(0.60, 0.35, 0.85),
		"executable": "tuxmath", "paquet": "tuxmath", "description_cle": "applis_desc_tuxmath"},
]


## Les applications qui existent sur CETTE plateforme.
static func catalogue_plateforme() -> Array:
	if not OS.has_feature("android"):
		return CATALOGUE
	return CATALOGUE.filter(func(appli: Dictionary) -> bool:
		return appli.has("paquet_android"))


## L'application est-elle installée sur l'appareil ?
static func est_installee(appli: Dictionary) -> bool:
	if OS.has_feature("android"):
		return Android.paquet_installe(appli["paquet_android"])
	return chemin_executable(appli["executable"]) != ""


## Ouvre l'application externe. Retourne vrai si le lancement est parti.
static func lancer(appli: Dictionary) -> bool:
	if OS.has_feature("android"):
		return Android.lancer_paquet(appli["paquet_android"])
	var chemin := chemin_executable(appli["executable"])
	if chemin == "":
		return false
	return OS.create_process(chemin, []) != -1


## Lance l'installation graphique (jamais de terminal pour l'adulte).
## Linux : pkexec → dialogue de mot de passe du système, puis apt installe —
## retourne le PID à surveiller. Android : fiche Play Store. Repli Linux :
## logithèque (lien apt://). Retour -1 = l'installation se fait ailleurs
## (store/logithèque), l'adulte revient quand c'est fini.
static func installer(appli: Dictionary) -> int:
	if OS.has_feature("android"):
		Android.ouvrir_fiche(appli["paquet_android"])
		return -1
	if chemin_executable("pkexec") != "":
		var pid := OS.create_process("pkexec", ["apt-get", "install", "-y", appli["paquet"]])
		if pid != -1:
			return pid
	OS.shell_open("apt://" + String(appli["paquet"]))
	return -1


## Chemin complet de l'exécutable (Linux), ou "" s'il n'est pas installé.
static func chemin_executable(executable: String) -> String:
	var sortie := []
	if OS.execute("which", [executable], sortie) == 0 and sortie.size() > 0:
		return String(sortie[0]).strip_edges()
	return ""


## L'adulte a-t-il coché cette application ? (décochée par défaut)
static func est_active(id: String) -> bool:
	return PinConfig.lire_option("applis_externes", id, false)


## Applications à afficher sur le bureau : cochées ET installées
## (règle : aucune icône fantôme). L'entrée complète part au bureau,
## qui la lance via lancer().
static func applis_actives() -> Array:
	var liste := []
	for appli in catalogue_plateforme():
		if est_active(appli["id"]) and est_installee(appli):
			var entree: Dictionary = appli.duplicate()
			entree["externe"] = true
			liste.append(entree)
	return liste
