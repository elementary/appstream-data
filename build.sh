#!/bin/bash

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
"ProjectName": "elementary-${CHANNEL}",
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
rm -f /repo/pantheon-data/extra/*.gz
rm -f /repo/debian/appstream-data-pantheon-icons-hidpi.install
rm -f /repo/debian/appstream-data-pantheon-icons.install
touch /repo/debian/appstream-data-pantheon-icons-hidpi.install
touch /repo/debian/appstream-data-pantheon-icons.install

# Copy in the new
cp export/data/${DIST}/main/Components-amd64.yml.gz /repo/pantheon-data/main/pantheon_${DIST}-main_amd64.yml.gz
for f in export/data/${DIST}/main/icons-*; do

  # Ignore icon archives with no icons
  FILECOUNT=$(tar -tzvvf ${f} | grep -c ^-) || true
  [[ $FILECOUNT -gt 0 ]] || continue

  # Strip a path like export/data/bionic/main/icons-128x128@2.tar.gz down to 128x128@2
  OUTDIR=`basename ${f} .tar.gz | cut -d- -f2`
  mkdir -p /repo/pantheon-data/main/icons/${OUTDIR}
  tar -C /repo/pantheon-data/main/icons/${OUTDIR} -xf ${f}

  # Add the extracted directory path to the debian install scripts (either HiDPI or not)
  if [[ $OUTDIR == *"@2" ]]; then
    echo "pantheon-data/main/icons/${OUTDIR}/* usr/share/app-info/icons/elementary-${CHANNEL}-${DIST}-main/$OUTDIR/" >> /repo/debian/appstream-data-pantheon-icons-hidpi.install
  else
    echo "pantheon-data/main/icons/${OUTDIR}/* usr/share/app-info/icons/elementary-${CHANNEL}-${DIST}-main/$OUTDIR/" >> /repo/debian/appstream-data-pantheon-icons.install
  fi
done

echo "pantheon-data/extra/icons/64x64/* usr/share/app-info/icons/elementary-${DIST}-extra/64x64/" >> /repo/debian/appstream-data-pantheon-icons.install
echo "pantheon-data/extra/icons/128x128/* usr/share/app-info/icons/elementary-${DIST}-extra/128x128/" >> /repo/debian/appstream-data-pantheon-icons.install

EXTR_FILES="/repo/pantheon-data/extra/data/*"
DATE=$(date -u +%Y%m%dT%H%M%S)

# At this point we build the extra package
touch "/repo/pantheon-data/extra/pantheon_${DIST}-extra_amd64.yml"

# Construct the header
cat <<EOF > /repo/pantheon-data/extra/pantheon_${DIST}-extra_amd64.yml
---
File: DEP-11
Version: '0.8'
Origin: elementary-${DIST}-extra
File: DEP-11
MediaBaseUrl: https://appstream.elementary.io/daily/media/pool
Priority: 13
Time: ${DATE}
EOF

# Iterate all the files
for file in $EXTR_FILES; do
    echo "---" >> /repo/pantheon-data/extra/pantheon_${DIST}-extra_amd64.yml
    cat "$file" >> /repo/pantheon-data/extra/pantheon_${DIST}-extra_amd64.yml
done

# Compress the yml file to the expected gz file
gzip /repo/pantheon-data/extra/pantheon_${DIST}-extra_amd64.yml
