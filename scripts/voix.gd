## Fait parler CoccOs — enregistrements d'abord, synthèse vocale sinon.
## Voix.dire(noeud, terme, categorie) cherche « <terme>.wav|ogg|mp3 » dans :
##   1) user://lang/<code>/voix/<categorie>/   (déposé par l'adulte, sans rebuild —
##      la voix de papa/maman peut remplacer la synthèse)
##   2) res://lang/<code>/voix/<categorie>/    (embarqué dans l'application)
##   3) à défaut : synthèse vocale du système/navigateur.
## Catégories : chiffres, lettres, mots, phrases (spec-lang.md).
## Le lecteur audio est créé à la volée (enfant "_VoixLecteur" de la scène appelante).
## La voix de synthèse est résolue paresseusement : sur le web les voix du
## navigateur arrivent en asynchrone (liste vide au démarrage) — on réessaie à
## chaque prononciation tant qu'aucune n'est trouvée, puis on la garde.
extends Object

const Lang = preload("res://scripts/lang.gd")
const NOM_LECTEUR := "_VoixLecteur"
const EXTENSIONS := ["wav", "ogg", "mp3"]

static var _voix_id := ""


## Dit le terme : fichier enregistré si présent, synthèse vocale sinon.
static func dire(noeud: Node, terme: String, categorie: String) -> void:
	DisplayServer.tts_stop()
	var flux := _flux_enregistre(terme, categorie)
	if flux != null:
		_jouer(noeud, flux)
		return
	_arreter_lecteur(noeud)
	var voix := _voix_tts()
	if voix == "":
		return
	DisplayServer.tts_speak(terme, voix)


## Amorce la résolution de la voix de synthèse (à appeler en _ready).
static func amorcer() -> void:
	_voix_tts()


## Coupe toute parole en cours (synthèse ET enregistrement) — à la sortie d'un jeu.
static func arreter(noeud: Node) -> void:
	DisplayServer.tts_stop()
	_arreter_lecteur(noeud)


# --- Recherche et lecture des enregistrements -----------------------------------

static func _flux_enregistre(terme: String, categorie: String) -> AudioStream:
	var code := Lang.code()
	# 1) Dépôt utilisateur (chargement direct depuis le disque)
	for ext in EXTENSIONS:
		var chemin := "user://lang/%s/voix/%s/%s.%s" % [code, categorie, terme, ext]
		if FileAccess.file_exists(chemin):
			match ext:
				"wav":
					return AudioStreamWAV.load_from_file(chemin)
				"ogg":
					return AudioStreamOggVorbis.load_from_file(chemin)
				"mp3":
					return AudioStreamMP3.load_from_file(chemin)
	# 2) Voix embarquées (ressources importées par l'éditeur)
	for ext in EXTENSIONS:
		var chemin := "res://lang/%s/voix/%s/%s.%s" % [code, categorie, terme, ext]
		if ResourceLoader.exists(chemin):
			return load(chemin)
	return null


static func _jouer(noeud: Node, flux: AudioStream) -> void:
	var lecteur: AudioStreamPlayer = noeud.get_node_or_null(NOM_LECTEUR)
	if lecteur == null:
		lecteur = AudioStreamPlayer.new()
		lecteur.name = NOM_LECTEUR
		noeud.add_child(lecteur)
	lecteur.stop()
	lecteur.stream = flux
	lecteur.play()


static func _arreter_lecteur(noeud: Node) -> void:
	var lecteur: AudioStreamPlayer = noeud.get_node_or_null(NOM_LECTEUR)
	if lecteur != null:
		lecteur.stop()


# --- Synthèse vocale (repli) ------------------------------------------------------

static func _voix_tts() -> String:
	if _voix_id != "":
		return _voix_id
	var langue := Lang.code()
	var voix := DisplayServer.tts_get_voices_for_language(langue)
	if voix.size() > 0:
		_voix_id = voix[0]
	else:
		var toutes := DisplayServer.tts_get_voices()
		if toutes.size() > 0:
			_voix_id = String(toutes[0].get("id", ""))
	return _voix_id
