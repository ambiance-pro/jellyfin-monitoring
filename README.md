# Monitoring serveur pour Jellyfin

Extension Jellyfin (12.x, serveur Linux) qui ajoute une page « Monitoring serveur » au tableau de bord :
processeur, mémoire, températures, disques, réseau, NAS, qBittorrent, VPN et lectures en cours,
avec un historique sur 24 heures et des statistiques d'écoute (qui regarde quoi, quand, sur quel appareil,
films jamais regardés). Les alertes peuvent aussi être envoyées sur le téléphone par ntfy.
Page réservée aux administrateurs, en lecture seule.

## Installation

Dans Jellyfin : Tableau de bord → Extensions → Dépôts → ajouter le dépôt

    https://raw.githubusercontent.com/ambiance-pro/jellyfin-monitoring/main/manifest.json

puis installer « Monitoring serveur » depuis le catalogue et redémarrer Jellyfin.

## Relevé système (santé des disques, conteneurs, mises à jour)

Facultatif. Sur le serveur, une fois :

    wget https://raw.githubusercontent.com/ambiance-pro/jellyfin-monitoring/main/installer-releve-serveur.sh
    sudo sh installer-releve-serveur.sh

Une tâche système relève alors toutes les 5 minutes la santé des disques, les conteneurs Docker, les paquets
à mettre à jour et le dernier passage de maj-serveur, et dépose ces relevés dans `/var/lib/jellyfin-monitoring`,
que l'extension se contente de lire. Elle remplace l'ancien relevé SMART (installer-releve-smart.sh).

---

# Demandes

Deuxième extension du même dépôt : une page ouverte à tous les comptes Jellyfin, à l'adresse
`https://ton-serveur/Demandes`, pour chercher un film ou une série (base TMDb) et le demander.

- Chacun voit ce qui est déjà dans Jellyfin, déjà demandé, accepté ou disponible, et peut dire « moi aussi ».
- L'administrateur reçoit une notification ntfy à chaque demande et répond depuis
  Tableau de bord → Extensions → Demandes (accepter, refuser avec un message, marquer disponible).
- La famille peut être prévenue sur son propre sujet ntfy. Un titre arrivé dans la bibliothèque passe tout seul en « Disponible ».
- Il faut une clé d'API TMDb gratuite (themoviedb.org → Paramètres → API).

- Pour les séries, on peut demander toute la série ou seulement certaines saisons.
- Chacun peut activer ses propres notifications ntfy depuis la page.
- Chaque dimanche, les nouveautés de la semaine peuvent être envoyées à la famille.

L'extension ne télécharge rien : elle tient seulement la liste des demandes.
