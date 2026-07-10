## Textes de l'interface — internationalisation par dossier de langue.
## Charge lang/<code>/textes.xml UNE fois (cache statique) : <texte cle="...">Valeur</texte>.
## Langue active : user://config.cfg [langue] code, défaut "fr" ; repli "fr" si
## le fichier de la langue demandée n'existe pas.
## Usage : const Lang = preload("res://scripts/lang.gd") ; Lang.t("bureau_menu")
## Repli de t() : la clé elle-même — un texte manquant se voit à l'écran au lieu
## de planter, et se repère d'un coup d'œil.
## Traduire = dupliquer le dossier lang/fr/ et traduire les valeurs (spec-lang.md).
extends Object

const CHEMIN_CONFIG := "user://config.cfg"

static var _textes := {}
static var _code := ""


## Code de la langue active ("fr", "en"…).
static func code() -> String:
	if _code == "":
		_charger()
	return _code


## Texte de l'interface pour cette clé (repli : la clé elle-même).
static func t(cle: String) -> String:
	if _code == "":
		_charger()
	return _textes.get(cle, cle)


static func _charger() -> void:
	_code = "fr"
	var cfg := ConfigFile.new()
	if cfg.load(CHEMIN_CONFIG) == OK:
		_code = str(cfg.get_value("langue", "code", "fr"))
	# Base = français (repli clé par clé : une traduction PARTIELLE reste utilisable),
	# puis la langue choisie par-dessus — embarquée (res://) ou créée dans
	# l'éditeur de langue (user://lang/<code>/textes.xml, prioritaire).
	_lire_fichier("res://lang/fr/textes.xml")
	if _code == "fr":
		return
	var chemin := "user://lang/%s/textes.xml" % _code
	if not FileAccess.file_exists(chemin):
		chemin = "res://lang/%s/textes.xml" % _code
	if not FileAccess.file_exists(chemin):
		_code = "fr"
		return
	_lire_fichier(chemin)


static func _lire_fichier(chemin: String) -> void:
	var xml := XMLParser.new()
	if xml.open(chemin) != OK:
		push_warning("Lang : impossible d'ouvrir " + chemin)
		return
	var cle_courante := ""
	while xml.read() == OK:
		match xml.get_node_type():
			XMLParser.NODE_ELEMENT:
				cle_courante = xml.get_named_attribute_value_safe("cle") \
						if xml.get_node_name() == "texte" else ""
			XMLParser.NODE_TEXT:
				if cle_courante != "":
					var valeur := xml.get_node_data().strip_edges()
					if valeur != "":
						_textes[cle_courante] = valeur
			_:
				cle_courante = ""
