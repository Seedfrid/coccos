## Registre des applications CoccOs — la carte d'identité de chaque activité
## (spec : DOCS/specs/spec-logitheque.md, phase A). Le bureau se construit en
## le lisant : les catégories naissent des jeux présents ET ACTIFS, plus de
## liste en dur. L'adulte active/désactive chaque application dans la
## logithèque (Réglages) — ouverture progressive du bureau à l'enfant.
##
## Activation : user://config.cfg, section [logitheque], clé = id (défaut vrai).
## Phase C à venir : manifestes par dossier pour les mini-jeux .pck externes —
## ce registre central restera la source des applications intégrées.
extends RefCounted

const PinConfig := preload("res://scripts/pin_config.gd")

## Les catégories (dossiers du bureau) — visibles seulement si ≥ 1 jeu actif.
const CATEGORIES := {
	"souris": {"nom_cle": "bureau_categorie_souris", "couleur": Color(0.20, 0.60, 0.90)},
	"clavier": {"nom_cle": "bureau_categorie_clavier", "couleur": Color(0.25, 0.75, 0.50)},
}

## Les applications intégrées. "categorie" = dossier du bureau ("" = icône
## directe). "web" = false : absente de l'export navigateur (icône fantôme interdite).
const APPLIS := [
	{"id": "pointeur", "nom_cle": "bureau_jeu_decouverte", "description_cle": "logitheque_desc_pointeur",
		"couleur": Color(0.20, 0.60, 0.90), "scene": "res://scenes/souris.tscn", "categorie": "souris"},
	{"id": "ballons", "nom_cle": "bureau_jeu_ballons", "description_cle": "logitheque_desc_ballons",
		"couleur": Color(0.90, 0.30, 0.40), "scene": "res://scenes/ballons.tscn", "categorie": "souris"},
	{"id": "lettres", "nom_cle": "bureau_jeu_lettres", "description_cle": "logitheque_desc_lettres",
		"couleur": Color(0.25, 0.75, 0.50), "scene": "res://scenes/lettres.tscn", "categorie": "clavier"},
	{"id": "mots", "nom_cle": "bureau_jeu_mots", "description_cle": "logitheque_desc_mots",
		"couleur": Color(0.95, 0.55, 0.15), "scene": "res://scenes/mots.tscn", "categorie": "clavier"},
	{"id": "chasse", "nom_cle": "bureau_jeu_chasse", "description_cle": "logitheque_desc_chasse",
		"couleur": Color(0.75, 0.35, 0.75), "scene": "res://scenes/chasse.tscn", "categorie": "clavier"},
	{"id": "pousse", "nom_cle": "bureau_jeu_pousse", "description_cle": "logitheque_desc_pousse",
		"couleur": Color(0.60, 0.45, 0.25), "scene": "res://scenes/pousse_pollen.tscn", "categorie": "clavier"},
	{"id": "classeur", "nom_cle": "bureau_app_classeur", "description_cle": "logitheque_desc_classeur",
		"couleur": Color(0.90, 0.40, 0.45), "scene": "res://scenes/classeur.tscn", "categorie": ""},
	{"id": "tele", "nom_cle": "bureau_app_tele", "description_cle": "logitheque_desc_tele",
		"couleur": Color(0.45, 0.40, 0.85), "scene": "res://scenes/tele.tscn", "categorie": "", "web": false},
]


## L'application est-elle activée par l'adulte ? (activée par défaut)
static func est_active(id: String) -> bool:
	return bool(PinConfig.lire_option("logitheque", id, true))


static func activer(id: String, actif: bool) -> void:
	PinConfig.ecrire_option("logitheque", id, actif)


## Existe-t-elle sur CETTE plateforme ? (la télé n'existe pas sur le web)
static func existe_ici(appli: Dictionary) -> bool:
	if OS.has_feature("web") and not appli.get("web", true):
		return false
	return true


## Les applications à icône directe sur le bureau (actives, de cette plateforme).
static func actives_directes() -> Array:
	return APPLIS.filter(func(appli: Dictionary) -> bool:
		return appli["categorie"] == "" and existe_ici(appli) and est_active(appli["id"]))


## Les jeux actifs d'une catégorie (le contenu de sa fenêtre).
static func jeux_de(categorie: String) -> Array:
	return APPLIS.filter(func(appli: Dictionary) -> bool:
		return appli["categorie"] == categorie and existe_ici(appli) and est_active(appli["id"]))


## Les catégories du bureau : seulement celles qui ont au moins un jeu actif.
static func categories_visibles() -> Array:
	var liste := []
	for id in CATEGORIES:
		if not jeux_de(id).is_empty():
			var categorie: Dictionary = CATEGORIES[id].duplicate()
			categorie["id"] = id
			liste.append(categorie)
	return liste


## L'application portant cet id (vide si inconnue).
static func appli(id: String) -> Dictionary:
	for entree in APPLIS:
		if entree["id"] == id:
			return entree
	return {}
