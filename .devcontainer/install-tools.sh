#!/usr/bin/env bash
# Installs the latest k6 and gcx release binaries into /usr/local/bin.
set -euo pipefail

arch="$(dpkg --print-architecture)" # amd64 or arm64
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

install_browser() {
  if [[ "$arch" != "amd64" ]]; then
    echo "Skipping Google Chrome: its Linux package is only available for amd64."
    return
  fi

  if ! command -v google-chrome-stable >/dev/null 2>&1; then
    sudo install -d -m 0755 /etc/apt/keyrings
    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
      | gpg --dearmor \
      | sudo tee /etc/apt/keyrings/google-chrome.gpg >/dev/null
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" \
      | sudo tee /etc/apt/sources.list.d/google-chrome.list >/dev/null
    sudo apt-get update
    sudo apt-get install -y google-chrome-stable
  fi

  google-chrome-stable --version
}

install_release() {
  local repo="$1" name="$2" suffix="$3"
  local url
  url="$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" \
    | grep -o "\"browser_download_url\": *\"[^\"]*${suffix}\"" \
    | head -n1 | cut -d'"' -f4)"
  curl -fsSL "$url" | tar -xz -C "$tmp"
  sudo install -m 0755 "$(find "$tmp" -type f -name "$name" | head -n1)" /usr/local/bin/"$name"
}

install_browser
install_release grafana/k6 k6 "linux-${arch}.tar.gz"
install_release grafana/gcx gcx "linux_${arch}.tar.gz"

k6 version
gcx --version
