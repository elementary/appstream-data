#!/bin/sh
# Creates a folder full of pantheon appstream data ready for debian packaging
# Requires wget, and tar
set -ex

# TODO: switch url to https once we get certifications working
URL="http://packages.elementary.io/daily"
DIST="xenial"
SECT="main"
EXTR="extra"
ARCH="amd64" # All appstream data _should_ be the same, so this is just for looks
DATE=$(date -u +%Y%m%dT%H%M%S)

EXTR_FILES="$PWD/pantheon-data/${EXTR}/data/*"

# Create the repository section folder to place all the data in
mkdir -p "$PWD/pantheon-data/$SECT"
mkdir -p "$PWD/pantheon-data/$SECT/icons/128x128"
mkdir -p "$PWD/pantheon-data/$SECT/icons/64x64"

# Start download the data from elementary's mirrored repo
wget "$URL/dists/$DIST/$SECT/dep11/Components-amd64.yml.gz" -O "$PWD/components.yml.gz"
wget "$URL/dists/$DIST/$SECT/dep11/icons-128x128.tar.gz" -O "$PWD/icons-128.tar.gz"
wget "$URL/dists/$DIST/$SECT/dep11/icons-64x64.tar.gz" -O "$PWD/icons-64.tar.gz"

# Unpack all the data and put it where it needs to go
mv "$PWD/components.yml.gz" "$PWD/pantheon-data/$SECT/pantheon_$DIST-${SECT}_${ARCH}.yml.gz"
tar -xf "$PWD/icons-128.tar.gz" -C "$PWD/pantheon-data/$SECT/icons/128x128"
tar -xf "$PWD/icons-64.tar.gz" -C "$PWD/pantheon-data/$SECT/icons/64x64"

# At this point we build the extra package
touch "$PWD/pantheon_$DIST-${EXTR}_${ARCH}.yml"

# Construct the header
{
    echo "---"
    echo "File: DEP-11"
    echo "Version: '0.8'"
    echo "Origin: elementary-${DIST}-${EXTR}"
    echo "File: DEP-11"
    echo "MediaBaseUrl: https://appstream.elementary.io/daily/media/pool"
    echo "Priority: 13"
    echo "Time: $DATE"
} > "$PWD/pantheon_$DIST-${EXTR}_${ARCH}.yml"

# Iterate all the files
for file in $EXTR_FILES; do
    echo "---" >> "$PWD/pantheon_$DIST-${EXTR}_${ARCH}.yml"
    cat "$file" >> "$PWD/pantheon_$DIST-${EXTR}_${ARCH}.yml"
done

# Compress the yml file to the expected gz file
gzip "$PWD/pantheon_$DIST-${EXTR}_${ARCH}.yml"
# And move it in place
mv "$PWD/pantheon_$DIST-${EXTR}_${ARCH}.yml.gz" "$PWD/pantheon-data/$EXTR/pantheon_$DIST-${EXTR}_${ARCH}.yml.gz"

rm "$PWD"/*.gz "$PWD"/*.yml
