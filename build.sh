#!/bin/bash

set -e

DIST="$1"
CHANNEL="$2"

apt-get update
apt-get install -y elementary-icon-theme appstream-generator apt-mirror

# Configure apt-mirror and use it to mirror the needed series from the PPA
cat <<EOF > /etc/apt/mirror.list
set nthreads     20
set _tilde 0

deb http://ppa.launchpad.net/elementary-os/${CHANNEL}/ubuntu ${DIST} main
EOF

apt-mirror

APPSTREAM_DIR=/workdir
mkdir ${APPSTREAM_DIR}
pushd ${APPSTREAM_DIR}

cat <<EOF > asgen-config.json
{
"ProjectName": "elementary-${CHANNEL}",
"ArchiveRoot": "/var/spool/apt-mirror/mirror/ppa.launchpad.net/elementary-os/${CHANNEL}/ubuntu",
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

popd

# Clear out the old data
rm -rf pantheon-data/main/*
rm -f debian/appstream-data-pantheon-icons-hidpi.install
rm -f debian/appstream-data-pantheon-icons.install
touch debian/appstream-data-pantheon-icons-hidpi.install
touch debian/appstream-data-pantheon-icons.install

# Copy in the new
cp ${APPSTREAM_DIR}/export/data/${DIST}/main/Components-amd64.yml.gz pantheon-data/main/pantheon_${DIST}-main_amd64.yml.gz
for f in ${APPSTREAM_DIR}/export/data/${DIST}/main/icons-*; do

  # Ignore icon archives with no icons
  FILECOUNT=$(tar -tzvvf ${f} | grep -c ^-) || true
  [[ $FILECOUNT -gt 0 ]] || continue

  # Strip a path like export/data/bionic/main/icons-128x128@2.tar.gz down to 128x128@2
  OUTDIR=`basename ${f} .tar.gz | cut -d- -f2`
  mkdir -p pantheon-data/main/icons/${OUTDIR}
  tar -C pantheon-data/main/icons/${OUTDIR} -xf ${f}

  # Add the extracted directory path to the debian install scripts (either HiDPI or not)
  if [[ $OUTDIR == *"@2" ]]; then
    echo "pantheon-data/main/icons/${OUTDIR}/* usr/share/app-info/icons/elementary-${CHANNEL}-${DIST}-main/$OUTDIR/" >> debian/appstream-data-pantheon-icons-hidpi.install
  else
    echo "pantheon-data/main/icons/${OUTDIR}/* usr/share/app-info/icons/elementary-${CHANNEL}-${DIST}-main/$OUTDIR/" >> debian/appstream-data-pantheon-icons.install
  fi
done

# Change the ownership to the current user
chown -R $(id -u):$(id -g) pantheon-data
chown -R $(id -u):$(id -g) debian
