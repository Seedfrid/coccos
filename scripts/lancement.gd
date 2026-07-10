## Lancement direct d'une application — « coccos --app classeur » (spec logithèque,
## chantier icônes directes 2026-07-10). L'argument arrive dans les user args
## (après « -- » : le lanceur .deb et les raccourcis Windows l'y placent) ; repli
## sur la ligne de commande brute pour les lancements à la main.
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
			break
	return _cache
