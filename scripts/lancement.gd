## Lancement direct d'une application (spec logithèque, chantier icônes directes).
## Deux canaux, selon la plateforme :
##   - desktop : « coccos --app classeur » — l'argument arrive dans les user args
##     (après « -- » : lanceur .deb et raccourcis Windows l'y placent), repli sur
##     la ligne de commande brute pour les lancements à la main ;
##   - Android : le raccourci épinglé porte un extra « coccos_app » dans son
##     intent — le gabarit Godot n'expose PAS les extras en ligne de commande
##     (vérifié sur appareil 2026-07-10), on lit l'intent par le pont Java.
## En mode direct, la croix des applis QUITTE CoccOs au lieu de revenir au bureau.
extends Object

static var _cache := ""
static var _lu := false


## L'id de l'appli demandée en lancement direct ("" = démarrage normal, bureau).
static func app_directe() -> String:
	if _lu:
		return _cache
	_lu = true
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		args = OS.get_cmdline_args()
	for i in args.size():
		if args[i] == "--app" and i + 1 < args.size():
			_cache = args[i + 1].strip_edges()
			return _cache
	# Android : l'extra « coccos_app » de l'intent (raccourci épinglé)
	if OS.has_feature("android") and Engine.has_singleton("AndroidRuntime"):
		var activite = Engine.get_singleton("AndroidRuntime").getActivity()
		if activite != null:
			var intention = activite.getIntent()
			if intention != null:
				var extra = intention.getStringExtra("coccos_app")
				if extra != null:
					_cache = str(extra).strip_edges()
	return _cache
