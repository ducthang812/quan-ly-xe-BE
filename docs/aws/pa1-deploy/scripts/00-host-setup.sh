#!/usr/bin/env bash
# Chuan bi may EC2 cho 1 site. Chay 1 lan tren moi may:
#   sudo bash scripts/00-host-setup.sh hn     (hoac dn / hcm)
set -euo pipefail

SITE_ARG="${1:-}"
if [[ ! "$SITE_ARG" =~ ^(hn|dn|hcm)$ ]]; then
  echo "Cach dung: sudo bash scripts/00-host-setup.sh <hn|dn|hcm>" >&2; exit 1
fi
if [[ $EUID -ne 0 ]]; then echo "Can chay voi sudo" >&2; exit 1; fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
OWNER="${SUDO_USER:-ubuntu}"

echo "==> Tao file .env cho site $SITE_ARG"
cat "env/$SITE_ARG.env" env/secrets.env > .env
chown "$OWNER": .env; chmod 600 .env
set -a; source .env; set +a

echo "==> Gan 3 IP phu (${NET}.11, .12, .20) vao card mang"
IFACE="$(ip -o -4 route show to default | awk '{print $5}' | head -1)"
cat > /etc/netplan/60-pa1-secondary-ips.yaml <<EOF
network:
  version: 2
  ethernets:
    ${IFACE}:
      addresses:
        - ${NET}.11/24
        - ${NET}.12/24
        - ${NET}.20/24
EOF
chmod 600 /etc/netplan/60-pa1-secondary-ips.yaml
netplan apply
sleep 3
ip -br -4 addr show "$IFACE"

echo "==> Them ten cac node vao /etc/hosts"
if ! grep -q "# pa1-begin" /etc/hosts; then
  cat >> /etc/hosts <<'EOF'
# pa1-begin
10.10.1.11 sql-hn-1
10.10.1.12 sql-hn-2
10.10.1.20 lsn-hn
10.10.2.11 sql-dn-1
10.10.2.12 sql-dn-2
10.10.2.20 lsn-dn
10.10.3.11 sql-hcm-1
10.10.3.12 sql-hcm-2
10.10.3.20 lsn-hcm
# pa1-end
EOF
fi

echo "==> Tao swap 2 GB (du phong khi het RAM)"
if ! swapon --show | grep -q /swapfile; then
  fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
  grep -q '/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

echo "==> Cho apt ranh (may moi bat thuong tu chay unattended-upgrades vai phut)"
for i in $(seq 1 90); do
  if ! fuser /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/lib/apt/lists/lock >/dev/null 2>&1; then break; fi
  echo "   apt dang ban, cho 10 giay... ($i)"; sleep 10
done

echo "==> Cai Docker"
if ! command -v docker >/dev/null; then
  curl -fsSL https://get.docker.com | sh
fi
usermod -aG docker "$OWNER"

echo "==> Cai sqlcmd (go-sqlcmd)"
if ! command -v sqlcmd >/dev/null; then
  apt-get update -y && apt-get install -y curl gpg bzip2
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor --yes -o /usr/share/keyrings/microsoft-prod.gpg
  . /etc/os-release
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/${VERSION_ID}/prod ${VERSION_CODENAME} main" \
    > /etc/apt/sources.list.d/microsoft-prod.list
  apt-get update -y
  if ! apt-get install -y sqlcmd; then
    echo "   Khong cai duoc tu apt, tai ban phat hanh tren GitHub"
    curl -fsSL -o /tmp/sqlcmd.tar.bz2 https://github.com/microsoft/go-sqlcmd/releases/latest/download/sqlcmd-linux-amd64.tar.bz2
    tar -xjf /tmp/sqlcmd.tar.bz2 -C /usr/local/bin sqlcmd
    chmod +x /usr/local/bin/sqlcmd
  fi
fi
sqlcmd --version || true

echo "==> Thu muc dung chung giua 2 container (chua chung chi AG)"
mkdir -p shared haproxy
chown -R 10001:0 shared && chmod 770 shared
chown -R "$OWNER": haproxy scripts sql app env docker-compose.yml 2>/dev/null || true

echo "==> Cau hinh listener tro toi node 1"
sudo -u "$OWNER" bash scripts/set-listener.sh 1 --no-restart

echo
echo "XONG. Dang xuat roi SSH vao lai (de nhom docker co hieu luc), sau do chay:"
echo "  bash scripts/10-up.sh"
