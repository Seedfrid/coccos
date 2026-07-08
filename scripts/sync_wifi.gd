## Synchro wifi locale — l'espace famille voyage d'un appareil à l'autre
## DIRECTEMENT, sans internet ni serveur (spec : spec-espace-famille.md,
## étage 2 — priorité Freddy 2026-07-08). Le téléphone de l'enfant devient le
## cartable numérique : il se synchronise chez papa, puis chez maman.
##
## Le geste reste celui de l'espace en ligne :
##   - l'appareil qui A les données fait « Envoyer en wifi »   → offrir(code)
##   - l'appareil qui les VEUT fait « Récupérer en wifi »      → chercher(code)
## L'offreur s'annonce en UDP (diffusion sur le réseau local) avec l'EMPREINTE
## du code famille — seuls les appareils de la même famille se reconnaissent,
## le code ne circule jamais. Le chercheur se connecte en TCP et reçoit
## l'archive (taille + octets). Limite assumée v1 : transfert en clair sur le
## wifi du foyer.
##
## Usage : var sync := SyncWifi.new() ; add_child(sync) — puis offrir()/chercher()
## Signaux : termine(message_cle) — succès ou échec, arreter() pour annuler.
extends Node

signal termine(message_cle: String)

const Espace := preload("res://scripts/espace_famille.gd")

const PORT_ANNONCE := 42270    # UDP : « une famille offre son espace »
const PORT_TRANSFERT := 42271  # TCP : le transfert lui-même
const PREFIXE := "COCCOS_ESPACE:"
const DELAI_MAX := 90.0        # au-delà, on abandonne proprement

var _mode := ""                # "" | "offre" | "cherche"
var _empreinte := ""
var _archive := PackedByteArray()
var _chrono := 0.0

var _udp: PacketPeerUDP
var _serveur: TCPServer
var _connexion: StreamPeerTCP
var _envoye := 0
var _taille_attendue := -1
var _recu := PackedByteArray()


## Côté « Envoyer en wifi » : construit l'archive et s'annonce au réseau.
func offrir(code: String) -> void:
	_archive = Espace.construire_archive()
	if _archive.is_empty():
		termine.emit("espace_trop_gros")
		return
	_empreinte = Espace.nettoyer_code(code).sha256_text()
	_serveur = TCPServer.new()
	if _serveur.listen(PORT_TRANSFERT) != OK:
		termine.emit("wifi_port_occupe")
		return
	_udp = PacketPeerUDP.new()
	_udp.set_broadcast_enabled(true)
	_mode = "offre"
	_chrono = 0.0
	set_process(true)


## Côté « Récupérer en wifi » : écoute les annonces de SA famille.
func chercher(code: String) -> void:
	_empreinte = Espace.nettoyer_code(code).sha256_text()
	_udp = PacketPeerUDP.new()
	if _udp.bind(PORT_ANNONCE) != OK:
		termine.emit("wifi_port_occupe")
		return
	_mode = "cherche"
	_chrono = 0.0
	set_process(true)


func arreter() -> void:
	_mode = ""
	set_process(false)
	if _udp != null:
		_udp.close()
	if _serveur != null:
		_serveur.stop()
	if _connexion != null:
		_connexion.disconnect_from_host()
	_archive = PackedByteArray()
	_recu = PackedByteArray()
	_taille_attendue = -1
	_envoye = 0


func _process(delta: float) -> void:
	_chrono += delta
	if _chrono > DELAI_MAX:
		arreter()
		termine.emit("wifi_personne")
		return
	match _mode:
		"offre":
			_faire_offre(delta)
		"cherche":
			_faire_recherche()


# --- Côté offreur -------------------------------------------------------------------

var _depuis_annonce := 1.0

func _faire_offre(delta: float) -> void:
	# S'annoncer chaque seconde (diffusion + boucle locale pour les tests)
	_depuis_annonce += delta
	if _depuis_annonce >= 1.0 and _connexion == null:
		_depuis_annonce = 0.0
		var annonce := (PREFIXE + _empreinte).to_utf8_buffer()
		_udp.set_dest_address("255.255.255.255", PORT_ANNONCE)
		_udp.put_packet(annonce)
		_udp.set_dest_address("127.0.0.1", PORT_ANNONCE)
		_udp.put_packet(annonce)

	if _connexion == null and _serveur.is_connection_available():
		_connexion = _serveur.take_connection()
		_envoye = 0
		# En-tête : taille de l'archive sur 8 octets
		_connexion.put_u64(_archive.size())

	if _connexion != null:
		_connexion.poll()
		if _connexion.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			arreter()
			termine.emit("wifi_interrompu")
			return
		# Envoi par morceaux, sans bloquer l'interface
		var morceau: int = mini(65536, _archive.size() - _envoye)
		if morceau > 0:
			var resultat: Array = _connexion.put_partial_data(_archive.slice(_envoye, _envoye + morceau))
			if resultat[0] != OK:
				arreter()
				termine.emit("wifi_interrompu")
				return
			_envoye += int(resultat[1])
		if _envoye >= _archive.size():
			arreter()
			termine.emit("wifi_envoye")


# --- Côté chercheur -----------------------------------------------------------------

func _faire_recherche() -> void:
	# 1) Attendre l'annonce de la famille
	if _connexion == null:
		while _udp.get_available_packet_count() > 0:
			var paquet := _udp.get_packet().get_string_from_utf8()
			if paquet == PREFIXE + _empreinte:
				_connexion = StreamPeerTCP.new()
				if _connexion.connect_to_host(_udp.get_packet_ip(), PORT_TRANSFERT) != OK:
					_connexion = null
				break
		return

	# 2) Recevoir l'archive (taille en tête, puis les octets)
	_connexion.poll()
	var statut := _connexion.get_status()
	if statut == StreamPeerTCP.STATUS_CONNECTING:
		return
	if statut != StreamPeerTCP.STATUS_CONNECTED:
		# Connexion close : soit fini, soit interrompu — la taille tranche
		_finir_reception()
		return
	if _taille_attendue < 0:
		if _connexion.get_available_bytes() >= 8:
			_taille_attendue = _connexion.get_u64()
		return
	var disponibles := _connexion.get_available_bytes()
	if disponibles > 0:
		var lecture: Array = _connexion.get_partial_data(disponibles)
		if lecture[0] == OK:
			_recu.append_array(lecture[1])
	if _recu.size() >= _taille_attendue:
		_finir_reception()


func _finir_reception() -> void:
	var complets := _taille_attendue >= 0 and _recu.size() >= _taille_attendue
	var octets := _recu
	arreter()
	if not complets:
		termine.emit("wifi_interrompu")
		return
	var ecrits: int = Espace.appliquer_archive(octets)
	termine.emit("espace_recupere" if ecrits > 0 else "espace_echec_archive")
