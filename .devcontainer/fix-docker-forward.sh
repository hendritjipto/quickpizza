#!/usr/bin/env bash
# Docker-in-Docker can leave a legacy iptables FORWARD DROP policy that blocks compose bridge traffic.
set -euo pipefail

if command -v iptables-legacy >/dev/null 2>&1; then
  sudo iptables-legacy -P FORWARD ACCEPT || true
fi