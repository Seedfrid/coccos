## Espace famille — synchronisation par CODE FAMILLE (spec :
## DOCS/specs/spec-espace-famille.md). « Le même CoccOs partout » : réglages,
## classeur et voix voyagent entre les appareils via une archive déposée sur
## le serveur (nginx WebDAV, zéro code serveur).
##
## Le code famille (4 mots + un nombre, ex. « coccinelle-prairie-soleil-42 »)
## est LA clé : aucune donnée identifiante, le serveur ne voit passer que
## l'empreinte SHA-256 du code (jamais le code lui-même) et un blob ZIP.
##
## Ce qui voyage : user://config.cfg, user://classeur/**, user://lang/**.
## Ce qui ne voyage PAS : user://tele/ (les vidéos — pistes PeerTube en v2).
## Avant tout « Récupérer », l'état local est copié dans
## user://sauvegarde_avant_sync/ (rien n'est perdu). La récupération écrit et
## remplace, mais ne supprime rien (v1 prudente).
extends RefCounted

const PinConfig := preload("res://scripts/pin_config.gd")

## Base de l'espace en ligne — CONFIGURABLE dans les réglages ([famille] url) :
## n'importe quel serveur WebDAV convient (Nextcloud, NAS, serveur d'école…),
## coccos.fr n'est que le défaut de confort. Aucun serveur obligatoire.
## (url_base_test : surcharge des tests jetables)
const URL_BASE := "https://coccos.fr/espace/"
static var url_base_test := ""


## L'adresse effective de l'espace en ligne de cet appareil.
static func url_base() -> String:
	if url_base_test != "":
		return url_base_test
	var configuree := String(PinConfig.lire_option("famille", "url", URL_BASE)).strip_edges()
	if configuree == "":
		configuree = URL_BASE
	if not configuree.ends_with("/"):
		configuree += "/"
	return configuree


static func enregistrer_url(url: String) -> void:
	PinConfig.ecrire_option("famille", "url", url.strip_edges())

const ARCHIVE_TRAVAIL := "user://sync_travail.zip"
const DOSSIER_SAUVEGARDE := "user://sauvegarde_avant_sync"
const QUOTA_OCTETS := 50 * 1024 * 1024  # 50 Mo (quota v1, aligné serveur)

## Ce qui voyage (chemins relatifs à user://)
const FICHIERS_RACINE := ["config.cfg"]
const DOSSIERS := ["classeur", "lang"]

## Mots simples et sans accent (faciles à noter et à retaper) — 4 tirés au
## hasard + un nombre à deux chiffres font le code famille.
const MOTS := [
	"abeille", "arbre", "avion", "ballon", "banane", "bateau", "biscuit", "bleu",
	"bonbon", "bougie", "bouton", "branche", "brioche", "cabane", "cadeau", "camion",
	"canard", "carotte", "castor", "cerise", "chanson", "chapeau", "chaton", "cheval",
	"chien", "chocolat", "citron", "clown", "coeur", "colline", "confiture", "coquillage",
	"corde", "crayon", "cube", "dauphin", "domino", "douceur", "dragon", "echelle",
	"ecole", "escargot", "etoile", "famille", "fleur", "flocon", "foret", "fraise",
	"fromage", "fusee", "galet", "gant", "gateau", "girafe", "glace", "gouter",
	"grenouille", "guitare", "herbe", "hibou", "histoire", "hiver", "jardin", "jouet",
	"jour", "kiwi", "lapin", "lecture", "libellule", "lion", "livre", "losange",
	"lune", "lutin", "maison", "manege", "marmotte", "matin", "melodie", "menthe",
	"miel", "montagne", "mouette", "mouton", "musique", "nuage", "ocean", "oiseau",
	"ombre", "orange", "ourson", "papillon", "perle", "phare", "pinceau", "pirate",
	"piscine", "plage", "plume", "pomme", "poney", "prairie", "printemps", "puzzle",
	"radis", "raisin", "renard", "riviere", "robot", "rondelle", "rose", "ruban",
	"sable", "sapin", "savane", "soleil", "sourire", "souris", "sucre", "tambour",
	"tarte", "tortue", "toupie", "train", "tresor", "trompette", "tulipe", "vague",
	"vanille", "velo", "violette", "voilier", "volcan", "voyage", "wagon", "zebre",
]


# --- Le code famille ---------------------------------------------------------------

static func generer_code() -> String:
	var morceaux := PackedStringArray()
	for i in 4:
		morceaux.append(MOTS[randi() % MOTS.size()])
	morceaux.append(str(randi() % 90 + 10))  # 10-99
	return "-".join(morceaux)


## Le code enregistré sur cet appareil ("" si aucun).
static func code_local() -> String:
	return String(PinConfig.lire_option("famille", "code", ""))


static func enregistrer_code(code: String) -> void:
	PinConfig.ecrire_option("famille", "code", nettoyer_code(code))


## Tolère espaces, majuscules et espaces autour des tirets (code retapé à la main).
static func nettoyer_code(code: String) -> String:
	var propre := code.to_lower().strip_edges()
	propre = propre.replace(" ", "-")
	while propre.contains("--"):
		propre = propre.replace("--", "-")
	return propre


## L'adresse de l'espace de CE code — le serveur ne voit que l'empreinte.
static func url_espace(code: String) -> String:
	return url_base() + nettoyer_code(code).sha256_text() + ".zip"


# --- L'archive : ce qui voyage -------------------------------------------------------

## Construit l'archive de l'espace. Renvoie les octets, ou vide si trop gros.
static func construire_archive() -> PackedByteArray:
	var zip := ZIPPacker.new()
	if zip.open(ARCHIVE_TRAVAIL) != OK:
		return PackedByteArray()
	for fichier in _fichiers_a_synchroniser():
		var contenu := FileAccess.get_file_as_bytes("user://" + fichier)
		zip.start_file(fichier)
		zip.write_file(contenu)
		zip.close_file()
	zip.close()
	var octets := FileAccess.get_file_as_bytes(ARCHIVE_TRAVAIL)
	DirAccess.remove_absolute(ARCHIVE_TRAVAIL)
	if octets.size() > QUOTA_OCTETS:
		return PackedByteArray()
	return octets


## Applique une archive reçue : sauvegarde locale d'abord, puis écrit tout.
## Renvoie le nombre de fichiers écrits (0 = archive illisible).
static func appliquer_archive(octets: PackedByteArray) -> int:
	var f := FileAccess.open(ARCHIVE_TRAVAIL, FileAccess.WRITE)
	if f == null:
		return 0
	f.store_buffer(octets)
	f.close()
	var zip := ZIPReader.new()
	if zip.open(ARCHIVE_TRAVAIL) != OK:
		DirAccess.remove_absolute(ARCHIVE_TRAVAIL)
		return 0
	_sauvegarder_local()
	var ecrits := 0
	for chemin in zip.get_files():
		if chemin.ends_with("/") or not _chemin_admissible(chemin):
			continue
		var complet := "user://" + chemin
		DirAccess.make_dir_recursive_absolute(complet.get_base_dir())
		var sortie := FileAccess.open(complet, FileAccess.WRITE)
		if sortie != null:
			sortie.store_buffer(zip.read_file(chemin))
			sortie.close()
			ecrits += 1
	zip.close()
	DirAccess.remove_absolute(ARCHIVE_TRAVAIL)
	return ecrits


## Seuls les chemins du périmètre entrent (jamais de ../, jamais d'ailleurs).
static func _chemin_admissible(chemin: String) -> bool:
	if chemin.contains(".."):
		return false
	if chemin in FICHIERS_RACINE:
		return true
	for dossier in DOSSIERS:
		if chemin.begins_with(dossier + "/"):
			return true
	return false


static func _fichiers_a_synchroniser() -> Array:
	var liste := []
	for fichier in FICHIERS_RACINE:
		if FileAccess.file_exists("user://" + fichier):
			liste.append(fichier)
	for dossier in DOSSIERS:
		liste.append_array(_fichiers_du_dossier(dossier))
	return liste


static func _fichiers_du_dossier(relatif: String) -> Array:
	var liste := []
	var complet := "user://" + relatif
	if not DirAccess.dir_exists_absolute(complet):
		return liste
	for fichier in DirAccess.get_files_at(complet):
		liste.append(relatif + "/" + fichier)
	for sous_dossier in DirAccess.get_directories_at(complet):
		liste.append_array(_fichiers_du_dossier(relatif + "/" + sous_dossier))
	return liste


## Copie l'état local synchronisable dans user://sauvegarde_avant_sync/.
static func _sauvegarder_local() -> void:
	for fichier in _fichiers_a_synchroniser():
		var destination: String = DOSSIER_SAUVEGARDE + "/" + String(fichier)
		DirAccess.make_dir_recursive_absolute(destination.get_base_dir())
		DirAccess.copy_absolute("user://" + String(fichier), destination)
