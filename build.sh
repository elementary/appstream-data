#!/bin/sh

set -e

DIST="$1"
CHANNEL="$2"

apt-get update
apt-get install -y wget elementary-icon-theme appstream-generator
mkdir -p /ppa_mirror

# Recursively get anything that's not index.html* from the PPA
wget -N -r -np -R "index.html*" -P/ppa_mirror http://ppa.launchpad.net/elementary-os/${CHANNEL}/ubuntu/

mkdir /workdir
cd /workdir

cat <<EOF > asgen-config.json
{
"ProjectName": "${CHANNEL}",
"ArchiveRoot": "/ppa_mirror/ppa.launchpad.net/elementary-os/${CHANNEL}/ubuntu",
"Backend": "debian",
"Suites":
  {
    "${DIST}":
      {
        "sections": ["main"],
        "architectures": ["amd64"],
        "useIconTheme": "elementary"
      }
  }
}
EOF

appstream-generator process ${DIST}

# Clear out the old data
rm -rf /repo/pantheon-data/main/*

# Copy in the new
cp export/data/${DIST}/main/Components-amd64.yml.gz /repo/pantheon-data/main/pantheon_${DIST}-main_amd64.yml.gz
for f in export/data/${DIST}/main/icons-*; do
  # Strip a path like export/data/bionic/main/icons-128x128@2.tar.gz down to 128x128@2
  OUTDIR=`basename ${f} .tar.gz | cut -d- -f2`
  mkdir -p /repo/pantheon-data/main/icons/${OUTDIR}
  tar -C /repo/pantheon-data/main/icons/${OUTDIR} -xf ${f}
done


