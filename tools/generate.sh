#!/usr/bin/env bash
#
# Generates a signed, static apt repository under /site, ready to publish on
# GitHub Pages. Runs INSIDE the tools container.
#
# Mounts (provided by build.sh):
#   /debs   -> directory containing the .deb files to publish
#   /site   -> output: the static apt repo (push this to GitHub Pages)
#   /keys   -> persistent GPG key material (private.asc)
#
# Env:
#   ARCH       Debian arch (default amd64)
#   KEY_NAME   GPG uid real name (default "PAIRS Lab APT")
#   KEY_EMAIL  GPG uid email     (default "canhthanh@vnu.edu.vn")
#
# Debs are routed to a suite by the distro token in their filename:
#   *focal* -> noetic   *noble* -> jazzy
#
set -euo pipefail

ARCH="${ARCH:-amd64}"
KEY_NAME="${KEY_NAME:-PAIRS Lab APT}"
KEY_EMAIL="${KEY_EMAIL:-canhthanh@vnu.edu.vn}"

export GNUPGHOME=/root/.gnupg
mkdir -p "$GNUPGHOME" /site /keys
chmod 700 "$GNUPGHOME"

# --- obtain a signing key (reuse if present, else create + export) ----------
if [ -f /keys/private.asc ]; then
  echo ">> importing existing signing key"
  gpg --batch --import /keys/private.asc
else
  echo ">> generating new signing key ($KEY_NAME <$KEY_EMAIL>)"
  cat >/tmp/key.conf <<EOF
%no-protection
Key-Type: RSA
Key-Length: 4096
Name-Real: ${KEY_NAME}
Name-Email: ${KEY_EMAIL}
Expire-Date: 0
%commit
EOF
  gpg --batch --gen-key /tmp/key.conf
  gpg --batch --armor --export-secret-keys "$KEY_EMAIL" > /keys/private.asc
  echo ">> NEW PRIVATE KEY written to keys/private.asc — keep it secret!"
fi

gpg --batch --armor --export "$KEY_EMAIL" > /site/KEY.gpg
KEYID="$(gpg --list-keys --with-colons "$KEY_EMAIL" | awk -F: '/^pub:/{print $5; exit}')"
echo ">> signing key id: $KEYID"

route_suite() {  # map a .deb filename -> suite
  case "$1" in
    *focal*) echo noetic ;;
    *noble*) echo jazzy ;;
    *)       echo "" ;;
  esac
}

cd /site
SUITES=""
for deb in /debs/*.deb; do
  [ -e "$deb" ] || { echo "No .deb files in /debs"; exit 1; }
  suite="$(route_suite "$(basename "$deb")")"
  [ -z "$suite" ] && { echo "WARN: cannot route $(basename "$deb") to a suite, skipping"; continue; }
  mkdir -p "pool/${suite}/main"
  cp -v "$deb" "pool/${suite}/main/"
  case " $SUITES " in *" $suite "*) ;; *) SUITES="$SUITES $suite" ;; esac
done

for SUITE in $SUITES; do
  comp_dir="dists/${SUITE}/main/binary-${ARCH}"
  mkdir -p "$comp_dir"

  # Packages index (Filename is relative to repo root -> pool/<suite>/main/..)
  dpkg-scanpackages --arch "$ARCH" "pool/${SUITE}/main" /dev/null > "$comp_dir/Packages"
  gzip -9c "$comp_dir/Packages" > "$comp_dir/Packages.gz"

  cat > /tmp/release.conf <<EOF
APT::FTPArchive::Release::Origin "pairs-lab";
APT::FTPArchive::Release::Label "PAIRS Lab";
APT::FTPArchive::Release::Suite "${SUITE}";
APT::FTPArchive::Release::Codename "${SUITE}";
APT::FTPArchive::Release::Architectures "${ARCH}";
APT::FTPArchive::Release::Components "main";
APT::FTPArchive::Release::Description "PAIRS Lab ROS packages (${SUITE})";
EOF
  apt-ftparchive -c /tmp/release.conf release "dists/${SUITE}" > "dists/${SUITE}/Release"
  gpg --batch --yes --default-key "$KEYID" -abs -o "dists/${SUITE}/Release.gpg" "dists/${SUITE}/Release"
  gpg --batch --yes --default-key "$KEYID" --clearsign -o "dists/${SUITE}/InRelease" "dists/${SUITE}/Release"
  echo ">> built + signed dists/${SUITE}"
done

touch /site/.nojekyll   # GitHub Pages: serve files verbatim, no Jekyll

echo "=================================================================="
echo " apt repo generated under /site:"
( cd /site && find . -type f | sort )
echo "=================================================================="
