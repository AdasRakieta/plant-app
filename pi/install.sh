#!/usr/bin/env bash
# Run on the Raspberry Pi from the root of the plant-app checkout: sudo bash pi/install.sh
set -euo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo 'Uruchom: sudo bash pi/install.sh' >&2
  exit 2
fi
if [[ ! -f pi/fetch_ipa.py || ! -f pi/serve_ipa.py || ! -f pi/ai_server.py || ! -f pi/pedy-fetch.service || ! -f pi/pedy-fetch.timer || ! -f pi/pedy-serve.service || ! -f pi/pedy-ai.service || ! -f pi/site/index.html || ! -f pi/site/icon.png ]]; then
  echo 'Uruchom skrypt z głównego katalogu repozytorium plant-app.' >&2
  exit 2
fi
for command in python3 systemctl; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Brakuje programu: $command" >&2
    exit 2
  fi
done
python3 -c 'import PIL' || { echo 'Brakuje Pillow: sudo apt install python3-pil' >&2; exit 2; }

if ! id pedy >/dev/null 2>&1; then
  useradd --system --home-dir /nonexistent --shell /usr/sbin/nologin pedy
fi
install -d -o root -g root -m 0755 /opt/pedy
install -d -o pedy -g pedy -m 0755 /srv/pedy
install -o pedy -g pedy -m 0644 pi/site/index.html /srv/pedy/index.html
install -o pedy -g pedy -m 0644 pi/site/icon.png /srv/pedy/icon.png
install -d -o root -g root -m 0700 /etc/pedy
install -o root -g root -m 0755 pi/fetch_ipa.py /opt/pedy/fetch_ipa.py
install -o root -g root -m 0755 pi/serve_ipa.py /opt/pedy/serve_ipa.py
install -o root -g root -m 0755 pi/ai_server.py /opt/pedy/ai_server.py
install -o root -g root -m 0644 pi/shared_atlas.py /opt/pedy/shared_atlas.py
install -o root -g root -m 0644 pi/pedy-fetch.service /etc/systemd/system/pedy-fetch.service
install -o root -g root -m 0644 pi/pedy-fetch.timer /etc/systemd/system/pedy-fetch.timer
install -o root -g root -m 0644 pi/pedy-serve.service /etc/systemd/system/pedy-serve.service
install -o root -g root -m 0644 pi/pedy-ai.service /etc/systemd/system/pedy-ai.service

if [[ ! -s /etc/pedy/github.env ]]; then
  if [[ ! -t 0 ]]; then
    echo 'Uruchom instalator w interaktywnym terminalu, aby bezpiecznie wprowadzić token GitHub.' >&2
    exit 2
  fi
  echo 'Wklej fine-grained PAT GitHub: tylko repo AdasRakieta/plant-app, Actions: read.'
  read -r -s -p 'Token (nie będzie wyświetlany): ' gh_read_token
  echo
  if [[ ! "$gh_read_token" =~ ^[A-Za-z0-9_]+$ ]]; then
    echo 'Token jest pusty lub ma niepoprawny format.' >&2
    exit 2
  fi
  umask 077
  tmp_env=$(mktemp /etc/pedy/.github.env.XXXXXX)
  trap 'rm -f "$tmp_env"' EXIT
  printf 'PEDY_REPO=AdasRakieta/plant-app\nPEDY_SERVE_DIR=/srv/pedy\nGH_READ_TOKEN=%s\n' "$gh_read_token" > "$tmp_env"
  unset gh_read_token
  chown root:root "$tmp_env"
  chmod 0600 "$tmp_env"
  mv "$tmp_env" /etc/pedy/github.env
  trap - EXIT
else
  echo 'Zachowuję istniejący /etc/pedy/github.env.'
fi

systemctl daemon-reload
systemctl enable --now pedy-fetch.timer
systemctl start pedy-fetch.service
test -s /srv/pedy/Pedy.ipa
systemctl enable pedy-serve.service
systemctl restart pedy-serve.service
systemctl enable pedy-ai.service
systemctl restart pedy-ai.service
echo 'IPA pobrane do /srv/pedy/Pedy.ipa; sprawdź: systemctl status pedy-fetch.timer'
echo 'Sieć lokalna: http://<adres-IP-maliny>:8787/app/'
echo 'Lokalne AI: http://<adres-IP-maliny>:8788/health (tylko LAN/Tailscale)'

if ! command -v tailscale >/dev/null 2>&1; then
  echo 'Tailscale nie jest zainstalowany. Po instalacji i tailscale up uruchom: sudo tailscale serve --bg --set-path=/app /srv/pedy'
elif ! tailscale status >/dev/null 2>&1; then
  echo 'Tailscale nie jest połączony. Uruchom sudo tailscale up, a potem: sudo tailscale serve --bg --set-path=/app /srv/pedy'
else
  serve_status=$(tailscale serve status 2>&1 || true)
  if [[ "$serve_status" == *'/app'* ]]; then
    echo 'Ścieżka /app jest już skonfigurowana w Tailscale Serve:'
    tailscale serve status
  else
    tailscale serve --bg --set-path=/app /srv/pedy
    tailscale serve status
  fi
fi

echo 'Następny krok: na iPhonie pobierz Pedy.ipa przez Tailscale, a następnie zaimportuj do SideStore.'
