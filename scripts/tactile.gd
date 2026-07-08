## Aide tactile — pont entre l'écran tactile et la grammaire souris de CoccOs.
## Le tap émule déjà le clic gauche (Godot) ; cette brique ajoute le reste :
## - signal appui_long(position) : le doigt reste ~0,6 s quasi immobile
##   → l'équivalent du CLIC DROIT (fleurs). Ne s'émet qu'en mode tactile.
## Le clavier des jeux de lettres est désormais DESSINÉ par CoccOs
## (scripts/clavier/clavier_virtuel.gd) — le clavier virtuel du système,
## qui masquait la moitié de l'écran, n'est plus invoqué.
## Mode tactile : réglage [interface] mode_tactile (case Réglages → Interface),
## coché PAR DÉFAUT sur Android, décoché sur PC — activable sur PC-tablette.
## Usage :
##   var tactile := Tactile.new()
##   add_child(tactile)
##   tactile.appui_long.connect(_clic_droit)
extends Node

signal appui_long(position: Vector2)

const CHEMIN_CONFIG := "user://config.cfg"
const DUREE_APPUI := 0.6      # secondes d'appui pour valoir un clic droit
const TOLERANCE := 26.0       # dérive tolérée du doigt (px) — petites mains

var _actif := false
var _suivi := false
var _origine := Vector2.ZERO
var _chrono := 0.0
var _declenche := false


## Valeur par défaut du mode : vrai sur Android (natif ou web), faux ailleurs.
static func par_defaut() -> bool:
	return OS.has_feature("android") or OS.has_feature("web_android")


## Le mode tactile est-il actif ? (réglage adulte, défaut selon la plateforme)
static func actif() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(CHEMIN_CONFIG) == OK:
		return bool(cfg.get_value("interface", "mode_tactile", par_defaut()))
	return par_defaut()


func _ready() -> void:
	_actif = actif()
	set_process(_actif)


func _input(event: InputEvent) -> void:
	if not _actif:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_suivi = true
			_origine = event.position
			_chrono = 0.0
			_declenche = false
		else:
			_suivi = false
	elif event is InputEventMouseMotion and _suivi:
		# Le doigt s'échappe → ce n'est pas un appui, c'est un glisser
		if event.position.distance_to(_origine) > TOLERANCE:
			_suivi = false


func _process(delta: float) -> void:
	if not _suivi or _declenche:
		return
	_chrono += delta
	if _chrono >= DUREE_APPUI:
		_declenche = true
		appui_long.emit(_origine)
