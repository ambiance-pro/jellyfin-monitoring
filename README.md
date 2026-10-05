# Monitoring serveur pour Jellyfin

Extension Jellyfin (12.x, serveur Linux) qui ajoute une page « Monitoring serveur » au tableau de bord :
processeur, mémoire, températures, disques, réseau, NAS, qBittorrent, VPN et lectures en cours,
avec un historique sur 24 heures. Page réservée aux administrateurs, en lecture seule.

## Installation

Dans Jellyfin : Tableau de bord → Extensions → Dépôts → ajouter le dépôt

    https://raw.githubusercontent.com/ambiance-pro/jellyfin-monitoring/main/manifest.json

puis installer « Monitoring serveur » depuis le catalogue et redémarrer Jellyfin.

## Santé des disques (SMART)

Facultatif. Sur le serveur, une fois :

    wget https://raw.githubusercontent.com/ambiance-pro/jellyfin-monitoring/main/installer-releve-smart.sh
    sudo sh installer-releve-smart.sh

Une tâche système lit alors la santé des disques toutes les 15 minutes et dépose son relevé dans
`/var/lib/jellyfin-monitoring/smart`, que l'extension se contente de lire.
