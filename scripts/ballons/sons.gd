## Sons synthétisés du jeu des ballons — aucun asset audio nécessaire.
## Même approche que le jeu souris : AudioStreamWAV 16 bits générés en mémoire.
extends RefCounted

const TAUX_ECHANTILLONNAGE := 22050


## Éclatement d'un ballon : « plop » percussif descendant.
static func pop_ballon() -> AudioStreamWAV:
	return _plop(420.0, 90.0, 0.14, 0.6)


## Clic dans le vide : petit scintillement discret (jamais punitif).
static func petit_clic() -> AudioStreamWAV:
	return _plop(950.0, 700.0, 0.06, 0.22)


## Note glissée à l'enveloppe percussive (attaque très courte, extinction rapide).
static func _plop(freq_debut: float, freq_fin: float, duree: float, volume: float) -> AudioStreamWAV:
	var nb_echantillons := int(duree * TAUX_ECHANTILLONNAGE)
	var donnees := PackedByteArray()
	donnees.resize(nb_echantillons * 2)
	var phase := 0.0
	for i in nb_echantillons:
		var t := float(i) / float(nb_echantillons)
		var frequence := lerpf(freq_debut, freq_fin, t)
		phase += TAU * frequence / TAUX_ECHANTILLONNAGE
		var enveloppe := minf(t / 0.01, 1.0) * pow(1.0 - t, 3.0)
		var echantillon := (sin(phase) + 0.5 * sin(phase * 2.0) + 0.2 * sin(phase * 3.0)) \
			* enveloppe * volume
		donnees.encode_s16(i * 2, int(clampf(echantillon, -1.0, 1.0) * 32767.0))
	var flux := AudioStreamWAV.new()
	flux.format = AudioStreamWAV.FORMAT_16_BITS
	flux.mix_rate = TAUX_ECHANTILLONNAGE
	flux.stereo = false
	flux.data = donnees
	return flux
