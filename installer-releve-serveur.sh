#!/bin/sh
# Installe le relevé système pour l'extension Jellyfin « Monitoring serveur ».
# À lancer une fois sur le serveur :  sudo sh installer-releve-serveur.sh
# Une tâche système (root) relève toutes les 5 minutes ce que Jellyfin n'a pas le droit de lire :
# santé SMART des disques, conteneurs Docker, paquets à mettre à jour, dernier passage de maj-serveur.
# Elle écrit dans /var/lib/jellyfin-monitoring ; Jellyfin se contente de lire ces fichiers.
# Remplace l'ancien « relevé SMART » (jellyfin-smart-report), qui est retiré.
set -e
[ "$(id -u)" -eq 0 ] || { echo "À lancer avec sudo." >&2; exit 1; }
command -v smartctl >/dev/null 2>&1 || apt-get install -y smartmontools

cat > /usr/local/sbin/jellyfin-monitoring-report <<'EOF'
#!/bin/sh
# Relevé système (lecture seule) pour l'extension Jellyfin « Monitoring serveur ».
PATH=/usr/sbin:/usr/bin:/sbin:/bin
DIR=/var/lib/jellyfin-monitoring
mkdir -p "$DIR/smart" && chmod 755 "$DIR" "$DIR/smart"

ecrire() { # ecrire <fichier> : copie l'entrée standard dans le fichier, d'un seul coup
  cat > "$DIR/$1.tmp" && chmod 644 "$DIR/$1.tmp" && mv -f "$DIR/$1.tmp" "$DIR/$1"
}

# 1. Santé SMART des disques (-n standby : ne réveille pas un disque dur en veille)
for sys in /sys/block/*; do
  name=$(basename "$sys")
  case "$name" in loop*|ram*|zram*|dm-*|md*|sr*) continue ;; esac
  [ -e "$sys/device" ] || continue
  out=$(smartctl --json=c -n standby -H -A "/dev/$name" 2>/dev/null) || true
  [ -n "$out" ] || continue
  case "$out" in
    *'"smart_status"'*) ;;
    *) [ -e "$DIR/smart/$name.json" ] && continue ;;
  esac
  printf '%s\n' "$out" | ecrire "smart/$name.json"
done

# 2. Conteneurs Docker
if command -v docker >/dev/null 2>&1; then
  docker ps -a --format '{{json .}}' 2>/dev/null | ecrire docker.jsonl || true
fi

# 3. Paquets à mettre à jour (liste du cache actuel, sans le rafraîchir)
apt list --upgradable 2>/dev/null | ecrire paquets.txt || true

# 4. Dernier passage de maj-serveur
if [ -r /var/log/maj-serveur.log ]; then
  awk '/^===== /{buf=""} {buf=buf $0 "\n"} END{printf "%s", buf}' /var/log/maj-serveur.log | ecrire maj.txt
fi

date +%s | ecrire releve-date
EOF
chmod 755 /usr/local/sbin/jellyfin-monitoring-report

cat > /etc/systemd/system/jellyfin-monitoring-report.service <<'EOF'
[Unit]
Description=Relevé système pour Jellyfin (Monitoring serveur)

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/jellyfin-monitoring-report
Nice=10
EOF

cat > /etc/systemd/system/jellyfin-monitoring-report.timer <<'EOF'
[Unit]
Description=Relevé système pour Jellyfin toutes les 5 minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
EOF

# Retrait de l'ancien relevé SMART, remplacé par celui-ci
if [ -e /etc/systemd/system/jellyfin-smart-report.timer ]; then
  systemctl disable --now jellyfin-smart-report.timer 2>/dev/null || true
  rm -f /etc/systemd/system/jellyfin-smart-report.timer /etc/systemd/system/jellyfin-smart-report.service /usr/local/sbin/jellyfin-smart-report
fi

systemctl daemon-reload
systemctl enable --now jellyfin-monitoring-report.timer
systemctl start jellyfin-monitoring-report.service
echo "Relevé système installé. Fichiers :"
ls -l /var/lib/jellyfin-monitoring /var/lib/jellyfin-monitoring/smart
