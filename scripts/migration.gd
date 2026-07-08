## Migration des données utilisateur après le renommage de l'application
## (« GCompris 2 » → « CoccOs », décision Freddy 2026-07-07).
## Le dossier user:// dérive du nom du projet (config/name) : au premier
## lancement sous le nouveau nom, on rapatrie les données existantes — PIN,
## réglages, mots à apprendre, fond d'écran importé, voix déposées (lang/).
## Idempotent : ne fait rien si la config existe déjà sous le nouveau nom
## ou si l'ancien dossier n'existe pas (première installation).
## Appelée en toute première ligne du _ready du bureau (scène principale),
## AVANT toute lecture de configuration.
extends Object

const ANCIEN_NOM := "GCompris 2"
## Caches recréés par le moteur : inutiles à migrer.
const DOSSIERS_IGNORES := ["logs", "shader_cache", "vulkan"]


static func migrer() -> void:
	if FileAccess.file_exists("user://config.cfg"):
		return  # données déjà présentes sous le nouveau nom
	var actuel := OS.get_user_data_dir()
	var ancien := actuel.get_base_dir().path_join(ANCIEN_NOM)
	if not DirAccess.dir_exists_absolute(ancien):
		return  # première installation : rien à rapatrier
	_copier_dossier(ancien, actuel)
	print("CoccOs : données utilisateur migrées depuis « ", ANCIEN_NOM, " ».")


static func _copier_dossier(source: String, destination: String) -> void:
	DirAccess.make_dir_recursive_absolute(destination)
	var dossier := DirAccess.open(source)
	if dossier == null:
		return
	dossier.list_dir_begin()
	var nom := dossier.get_next()
	while nom != "":
		if nom != "." and nom != "..":
			if dossier.current_is_dir():
				if not DOSSIERS_IGNORES.has(nom):
					_copier_dossier(source.path_join(nom), destination.path_join(nom))
			else:
				dossier.copy(source.path_join(nom), destination.path_join(nom))
		nom = dossier.get_next()
	dossier.list_dir_end()
