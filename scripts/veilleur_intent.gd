## Veilleur des intents Android (mode bureau/launcher) — AUTOLOAD.
## GodotApp.java horodate chaque nouvel intent reçu par l'activité déjà ouverte
## (onNewIntent → extra « coccos_intent_ts » + setIntent). Ce nœud surveille
## l'horodatage et traduit le geste en navigation :
##   - appui Accueil (rond) → retour au bureau CoccOs, où qu'on soit ;
##   - tap sur un raccourci épinglé pendant que CoccOs tourne → saut direct
##     dans l'appli demandée (extra « coccos_app »).
## Inerte hors Android.
extends Node

const Registre := preload("res://scripts/registre_jeux.gd")
const CHEMIN_BUREAU := "res://scenes/bureau.tscn"

var _dernier_ts := 0


func _ready() -> void:
	if not (OS.has_feature("android") and Engine.has_singleton("AndroidRuntime")):
		return
	var minuterie := Timer.new()
	minuterie.wait_time = 0.5
	minuterie.timeout.connect(_verifier)
	add_child(minuterie)
	minuterie.start()


func _verifier() -> void:
	var activite = Engine.get_singleton("AndroidRuntime").getActivity()
	if activite == null:
		return
	var intention = activite.getIntent()
	if intention == null:
		return
	var ts: int = intention.getLongExtra("coccos_intent_ts", 0)
	if ts == 0 or ts == _dernier_ts:
		return
	_dernier_ts = ts
	# Cible : l'appli du raccourci s'il y en a une, le bureau sinon (Accueil)
	var cible := CHEMIN_BUREAU
	var app = intention.getStringExtra("coccos_app")
	if app != null:
		var fiche: Dictionary = Registre.appli(str(app))
		if not fiche.is_empty() and ResourceLoader.exists(fiche.get("scene", "")):
			cible = fiche["scene"]
	var scene_courante := ""
	if get_tree().current_scene != null:
		scene_courante = get_tree().current_scene.scene_file_path
	if scene_courante == cible:
		return
	DisplayServer.tts_stop()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(cible)
