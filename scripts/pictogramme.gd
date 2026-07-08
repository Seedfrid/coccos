## Pictogrammes dessinés par code pour les icônes du bureau et le menu.
## Un Control qui dessine, centré dans sa taille, le symbole demandé par `id` :
## souris, clavier, maths, lecture, puzzles, dessin, etoile, engrenage.
## Le dessin principal est blanc ; `couleur_creux` sert aux détails « en creux »
## (touches du clavier, pages du livre…) — donner la couleur du fond du bouton.
extends Control

var id := ""
var couleur := Color.WHITE
var couleur_creux := Color(0.0, 0.0, 0.0, 0.30)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var c := size / 2.0
	var u := minf(size.x, size.y) / 2.0
	match id:
		"souris":
			_dessiner_souris(c, u)
		"pointeur":
			_dessiner_pointeur(c, u)
		"ballons":
			_dessiner_ballons(c, u)
		"clavier":
			_dessiner_clavier(c, u)
		"lettres":
			_dessiner_lettres(c, u)
		"mots":
			_dessiner_mots(c, u)
		"chasse":
			_dessiner_chasse(c, u)
		"maths":
			_dessiner_maths(c, u)
		"lecture":
			_dessiner_lecture(c, u)
		"puzzles":
			_dessiner_puzzles(c, u)
		"dessin":
			_dessiner_dessin(c, u)
		"classeur":
			_dessiner_classeur(c, u)
		"tele":
			_dessiner_tele(c, u)
		"etoile":
			_dessiner_etoile(c, u)
		"engrenage":
			_dessiner_engrenage(c, u)
		"eteindre":
			_dessiner_eteindre(c, u)


func _dessiner_souris(c: Vector2, u: float) -> void:
	# Corps : ellipse (cercle étiré), boutons et molette « en creux »
	draw_set_transform(c, 0.0, Vector2(0.72, 1.0))
	draw_circle(Vector2.ZERO, u * 0.85, couleur)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var y_sep := c.y - u * 0.12
	var x_demi := u * 0.72 * 0.85 * sqrt(1.0 - pow(0.12 / 0.85, 2.0))
	draw_line(Vector2(c.x - x_demi, y_sep), Vector2(c.x + x_demi, y_sep), couleur_creux, u * 0.08)
	draw_line(Vector2(c.x, c.y - u * 0.85), Vector2(c.x, y_sep), couleur_creux, u * 0.08)
	draw_rect(Rect2(c.x - u * 0.08, c.y - u * 0.68, u * 0.16, u * 0.34), couleur_creux)


func _dessiner_pointeur(c: Vector2, u: float) -> void:
	# Flèche du curseur (même silhouette que le gros curseur du jeu),
	# entourée d'une étoile et d'une fleur — l'icône du jeu « Découverte »
	var silhouette: Array[Vector2] = [
		Vector2(0, 0), Vector2(0, 52), Vector2(12, 40), Vector2(20, 58),
		Vector2(29, 54), Vector2(21, 37), Vector2(38, 37),
	]
	var echelle := u * 1.5 / 58.0
	var origine := c + Vector2(-u * 0.7, -u * 0.75)
	var points := PackedVector2Array()
	for p in silhouette:
		points.append(origine + p * echelle)
	draw_colored_polygon(points, couleur)
	# Étoile en haut à droite
	var etoile := PackedVector2Array()
	var centre_etoile := c + Vector2(u * 0.45, -u * 0.45)
	for i in 10:
		var r := u * 0.38 if i % 2 == 0 else u * 0.17
		var angle := -PI / 2.0 + TAU * float(i) / 10.0
		etoile.append(centre_etoile + Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(etoile, couleur)
	# Fleur en bas à droite
	var centre_fleur := c + Vector2(u * 0.45, u * 0.45)
	for i in 6:
		var angle := TAU * float(i) / 6.0
		draw_circle(centre_fleur + Vector2(cos(angle), sin(angle)) * u * 0.18, u * 0.14, couleur)
	draw_circle(centre_fleur, u * 0.11, couleur_creux)


func _dessiner_ballons(c: Vector2, u: float) -> void:
	# Ballon : corps ovale + nœud + ficelle
	var centre_ballon := c + Vector2(0.0, -u * 0.25)
	draw_set_transform(centre_ballon, 0.0, Vector2(0.85, 1.0))
	draw_circle(Vector2.ZERO, u * 0.55, couleur)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_colored_polygon(PackedVector2Array([
		centre_ballon + Vector2(0.0, u * 0.5),
		centre_ballon + Vector2(-u * 0.1, u * 0.66),
		centre_ballon + Vector2(u * 0.1, u * 0.66),
	]), couleur)
	var points := PackedVector2Array()
	for i in 9:
		var t := float(i) / 8.0
		points.append(centre_ballon + Vector2(sin(t * TAU) * u * 0.08, u * 0.66 + t * u * 0.55))
	draw_polyline(points, couleur, u * 0.07)


func _dessiner_clavier(c: Vector2, u: float) -> void:
	draw_rect(Rect2(c - Vector2(u * 0.95, u * 0.6), Vector2(u * 1.9, u * 1.2)), couleur)
	# 2 rangées de touches + barre d'espace, « en creux »
	for rangee in 2:
		for colonne in 5:
			draw_rect(Rect2(
				c + Vector2(-u * 0.8 + colonne * u * 0.34, -u * 0.45 + rangee * u * 0.34),
				Vector2(u * 0.24, u * 0.24)), couleur_creux)
	draw_rect(Rect2(c + Vector2(-u * 0.5, u * 0.22), Vector2(u * 1.0, u * 0.2)), couleur_creux)


func _dessiner_lettres(c: Vector2, u: float) -> void:
	# La bulle carrée du jeu avec un grand « A » — icône du jeu des lettres
	var bulle := StyleBoxFlat.new()
	bulle.bg_color = couleur
	bulle.set_corner_radius_all(int(u * 0.3))
	bulle.draw(get_canvas_item(), Rect2(c - Vector2(u * 0.8, u * 0.8), Vector2(u * 1.6, u * 1.6)))
	var police := ThemeDB.fallback_font
	var taille := int(u * 1.3)
	var hauteur := police.get_ascent(taille) - police.get_descent(taille)
	draw_string(police, Vector2(c.x - u * 0.8, c.y + hauteur / 2.0), "A",
		HORIZONTAL_ALIGNMENT_CENTER, u * 1.6, taille, couleur_creux)


func _dessiner_mots(c: Vector2, u: float) -> void:
	# Deux tuiles côte à côte avec « A B » — icône du jeu des mots
	var police := ThemeDB.fallback_font
	var taille := int(u * 0.85)
	var hauteur := police.get_ascent(taille) - police.get_descent(taille)
	for i in 2:
		var x := c.x - u * 0.92 + float(i) * u * 1.0
		var tuile := StyleBoxFlat.new()
		tuile.bg_color = couleur
		tuile.set_corner_radius_all(int(u * 0.18))
		tuile.draw(get_canvas_item(), Rect2(x, c.y - u * 0.55, u * 0.84, u * 1.1))
		draw_string(police, Vector2(x, c.y + hauteur / 2.0), ["A", "B"][i],
			HORIZONTAL_ALIGNMENT_CENTER, u * 0.84, taille, couleur_creux)


func _dessiner_chasse(c: Vector2, u: float) -> void:
	# Bulle-lettre flottante avec une étoile — icône de la chasse aux lettres
	var centre_bulle := c + Vector2(-u * 0.12, u * 0.1)
	draw_circle(centre_bulle, u * 0.72, couleur)
	draw_circle(centre_bulle, u * 0.58, couleur_creux)
	var police := ThemeDB.fallback_font
	var taille := int(u * 0.75)
	var hauteur := police.get_ascent(taille) - police.get_descent(taille)
	draw_string(police, Vector2(centre_bulle.x - u * 0.58, centre_bulle.y + hauteur / 2.0), "A",
		HORIZONTAL_ALIGNMENT_CENTER, u * 1.16, taille, couleur)
	# Petite étoile en haut à droite
	var etoile := PackedVector2Array()
	var centre_etoile := c + Vector2(u * 0.62, -u * 0.6)
	for i in 10:
		var r := u * 0.3 if i % 2 == 0 else u * 0.13
		var angle := -PI / 2.0 + TAU * float(i) / 10.0
		etoile.append(centre_etoile + Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(etoile, couleur)


func _dessiner_maths(c: Vector2, u: float) -> void:
	# Grand « + »
	draw_rect(Rect2(c - Vector2(u * 0.14, u * 0.75), Vector2(u * 0.28, u * 1.5)), couleur)
	draw_rect(Rect2(c - Vector2(u * 0.75, u * 0.14), Vector2(u * 1.5, u * 0.28)), couleur)


func _dessiner_lecture(c: Vector2, u: float) -> void:
	# Livre ouvert : deux pages en quadrilatères + reliure
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-u * 0.9, -u * 0.45), c + Vector2(0.0, -u * 0.2),
		c + Vector2(0.0, u * 0.65), c + Vector2(-u * 0.9, u * 0.4),
	]), couleur)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(u * 0.9, -u * 0.45), c + Vector2(0.0, -u * 0.2),
		c + Vector2(0.0, u * 0.65), c + Vector2(u * 0.9, u * 0.4),
	]), couleur)
	draw_line(c + Vector2(0.0, -u * 0.2), c + Vector2(0.0, u * 0.65), couleur_creux, u * 0.08)


func _dessiner_puzzles(c: Vector2, u: float) -> void:
	# Pièce de puzzle : carré + deux bosses rondes
	draw_rect(Rect2(c - Vector2(u * 0.55, u * 0.55), Vector2(u * 1.1, u * 1.1)), couleur)
	draw_circle(c + Vector2(0.0, -u * 0.55), u * 0.28, couleur)
	draw_circle(c + Vector2(u * 0.55, 0.0), u * 0.28, couleur)


func _dessiner_dessin(c: Vector2, u: float) -> void:
	# Crayon en diagonale : corps + pointe
	var axe := Vector2(1, -1).normalized()
	var perp := Vector2(1, 1).normalized() * u * 0.22
	var queue := c - axe * u * 0.75
	var epaule := c + axe * u * 0.35
	var pointe := c + axe * u * 0.8
	draw_colored_polygon(PackedVector2Array([
		queue - perp, epaule - perp, epaule + perp, queue + perp,
	]), couleur)
	draw_colored_polygon(PackedVector2Array([epaule - perp, pointe, epaule + perp]), couleur)
	draw_line(epaule - perp, epaule + perp, couleur_creux, u * 0.08)


func _dessiner_classeur(c: Vector2, u: float) -> void:
	# Bulle de parole contenant 3 vignettes « en creux » — icône du classeur
	# de communication (l'enfant touche une vignette, la bulle parle)
	var bulle := StyleBoxFlat.new()
	bulle.bg_color = couleur
	bulle.set_corner_radius_all(int(u * 0.35))
	bulle.draw(get_canvas_item(), Rect2(c - Vector2(u * 0.9, u * 0.8), Vector2(u * 1.8, u * 1.25)))
	# Queue de la bulle
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-u * 0.35, u * 0.4),
		c + Vector2(-u * 0.1, u * 0.85),
		c + Vector2(u * 0.15, u * 0.4),
	]), couleur)
	# 3 vignettes en creux dans la bulle
	for i in 3:
		draw_rect(Rect2(
			c + Vector2(-u * 0.68 + float(i) * u * 0.5, -u * 0.4),
			Vector2(u * 0.36, u * 0.5)), couleur_creux)


func _dessiner_tele(c: Vector2, u: float) -> void:
	# Petit poste de télé : écran arrondi + pieds + triangle lecture en creux
	var ecran := StyleBoxFlat.new()
	ecran.bg_color = couleur
	ecran.set_corner_radius_all(int(u * 0.18))
	ecran.draw(get_canvas_item(), Rect2(c + Vector2(-u * 0.95, -u * 0.72), Vector2(u * 1.9, u * 1.3)))
	# Pieds
	draw_line(c + Vector2(-u * 0.45, u * 0.58), c + Vector2(-u * 0.65, u * 0.9), couleur, u * 0.12)
	draw_line(c + Vector2(u * 0.45, u * 0.58), c + Vector2(u * 0.65, u * 0.9), couleur, u * 0.12)
	# Triangle « lecture » en creux
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-u * 0.22, -u * 0.38), c + Vector2(u * 0.35, -u * 0.07),
		c + Vector2(-u * 0.22, u * 0.24),
	]), couleur_creux)


func _dessiner_etoile(c: Vector2, u: float) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var r := u * 0.9 if i % 2 == 0 else u * 0.4
		var angle := -PI / 2.0 + TAU * float(i) / 10.0
		points.append(c + Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(points, couleur)


func _dessiner_eteindre(c: Vector2, u: float) -> void:
	# Symbole marche/arrêt universel : cercle ouvert en haut + trait vertical
	draw_arc(c, u * 0.62, deg_to_rad(-55.0), deg_to_rad(235.0), 32, couleur, u * 0.16)
	draw_line(c + Vector2(0.0, -u * 0.85), c + Vector2(0.0, -u * 0.1), couleur, u * 0.16)


func _dessiner_engrenage(c: Vector2, u: float) -> void:
	var r_ext := u * 0.6
	draw_circle(c, r_ext, couleur)
	for i in 8:
		var angle := TAU / 8.0 * float(i)
		var direction := Vector2(cos(angle), sin(angle))
		var perp := Vector2(-direction.y, direction.x)
		draw_colored_polygon(PackedVector2Array([
			c + direction * r_ext - perp * r_ext * 0.28,
			c + direction * r_ext + perp * r_ext * 0.28,
			c + direction * (r_ext * 1.32) + perp * r_ext * 0.28,
			c + direction * (r_ext * 1.32) - perp * r_ext * 0.28,
		]), couleur)
	draw_circle(c, r_ext * 0.5, couleur_creux)
