#!/bin/sh
# Installe le relevé SMART pour l'extension Jellyfin « Monitoring serveur ».
# À lancer une fois sur le serveur :  sudo sh installer-releve-smart.sh
# Une tâche système (root) lit la santé des disques toutes les 15 minutes et l'écrit dans
# /var/lib/jellyfin-monitoring/smart ; Jellyfin se contente de lire ces fichiers.
set -e
[ "$(id -u)" -eq 0 ] || { echo "À lancer avec sudo." >&2; exit 1; }
command -v smartctl >/dev/null 2>&1 || apt-get install -y smartmontools

cat > /usr/local/sbin/jellyfin-smart-report <<'EOF'
#!/bin/sh
# Relevé SMART (lecture seule) pour l'extension Jellyfin « Monitoring serveur ».
PATH=/usr/sbin:/usr/bin:/sbin:/bin
DIR=/var/lib/jellyfin-monitoring/smart
mkdir -p "$DIR" && chmod 755 /var/lib/jellyfin-monitoring "$DIR"
for sys in /sys/block/*; do
  name=$(basename "$sys")
  case "$name" in loop*|ram*|zram*|dm-*|md*|sr*) continue ;; esac
  [ -e "$sys/device" ] || continue
  # -n standby : ne réveille pas un disque dur en veille.
  out=$(smartctl --json=c -n standby -H -A "/dev/$name" 2>/dev/null) || true
  [ -n "$out" ] || continue
  case "$out" in
    *'"smart_status"'*) ;;
    *) [ -e "$DIR/$name.json" ] && continue ;;
  esac
  printf '%s\n' "$out" > "$DIR/$name.json.tmp"
  chmod 644 "$DIR/$name.json.tmp"
  mv -f "$DIR/$name.json.tmp" "$DIR/$name.json"
done
EOF
chmod 755 /usr/local/sbin/jellyfin-smart-report

cat > /etc/systemd/system/jellyfin-smart-report.service <<'EOF'
[Unit]
Description=Relevé SMART pour Jellyfin (Monitoring serveur)

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/jellyfin-smart-report
EOF

cat > /etc/systemd/system/jellyfin-smart-report.timer <<'EOF'
[Unit]
Description=Relevé SMART pour Jellyfin toutes les 15 minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=15min

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now jellyfin-smart-report.timer
systemctl start jellyfin-smart-report.service
echo "Relevé SMART installé. Fichiers :"
ls -l /var/lib/jellyfin-monitoring/smart
