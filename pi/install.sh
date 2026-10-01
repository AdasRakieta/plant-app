#!/usr/bin/env bash
# Run on the Raspberry Pi from the root of the plant-app checkout: sudo bash pi/install.sh
set -euo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo 'Uruchom: sudo bash pi/install.sh' >&2
  exit 2
fi
if [[ ! -f pi/fetch_ipa.py || ! -f pi/pedy-fetch.service || ! -f pi/pedy-fetch.timer ]]; then
  echo 'Uruchom skrypt z głównego katalogu repozytorium plant-app.' >&2
  exit 2
fi
for command in python3 systemctl; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Brakuje programu: $command" >&2
    exit 2
  fi
done

if ! id pedy >/dev/null 2>&1; then
  useradd --system --home-dir /nonexistent --shell /usr/sbin/nologin pedy
fi
install -d -o root -g root -m 0755 /opt/pedy
install -d -o pedy -g pedy -m 0755 /srv/pedy
install -d -o root -g root -m 0700 /etc/pedy
install -o root -g root -m 0755 pi/fetch_ipa.py /opt/pedy/fetch_ipa.py
install -o root -g root -m 0644 pi/pedy-fetch.service /etc/systemd/system/pedy-fetch.service
install -o root -g root -m 0644 pi/pedy-fetch.timer /etc/systemd/system/pedy-fetch.timer

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
echo 'IPA pobrane do /srv/pedy/Pedy.ipa; sprawdź: systemctl status pedy-fetch.timer'

if ! command -v tailscale >/dev/null 2>&1; then
  echo 'Tailscale nie jest zainstalowany. Zainstaluj go według oficjalnej instrukcji, uruchom tailscale up, a potem: sudo tailscale serve --bg /srv/pedy'
elif ! tailscale status >/dev/null 2>&1; then
  echo 'Tailscale nie jest połączony. Uruchom sudo tailscale up, a potem: sudo tailscale serve --bg /srv/pedy'
else
  serve_status=$(tailscale serve status 2>&1 || true)
  if [[ "$serve_status" == *'https://'* || "$serve_status" == *'http://'* ]]; then
    echo 'Na Pi działa już Tailscale Serve. Nie zmieniam istniejącej konfiguracji:'
    tailscale serve status
    echo 'Jeśli chcesz udostępnić Pędy, sprawdź tę konfigurację i dodaj /srv/pedy osobno.'
  else
    tailscale serve --bg /srv/pedy
    tailscale serve status
  fi
fi

echo 'Następny krok: na iPhonie pobierz Pedy.ipa przez Tailscale, a następnie zaimportuj do SideStore.'
