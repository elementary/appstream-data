#!/bin/sh
# Creates a folder full of pantheon appstream data ready for debian packaging
# Requires bzr, wget, and tar

TEMP="/tmp/appstream-package"
LAUNCH="~elementary-os/elementaryos/appstream-data-pantheon"

# TODO: switch url to https once we get certifications working
URL="http://packages.elementary.io/daily"
DIST="xenial"
SECT="main"
EXTR="extra"
ARCH="amd64" # All appstream data _should_ be the same, so this is just for looks
DATE=$(date -u +%Y%m%dT%H%M%S)

EXTR_FILES="$TEMP/package/pantheon-data/${EXTR}/data/*"

# Stop the build if we fail on something
set -e

# Make sure we have a clean workspace
mkdir -p "$TEMP"
rm -rf "${TEMP:?}/"*

# Grab the template
bzr branch "lp:$LAUNCH" "$TEMP/package"
# But remove any of the old data
rm -rf "$TEMP/package/pantheon-data/*"
# And the rest of the stuff we don't want packaged
rm -rf "$TEMP/package/.bzr"
rm -rf "$TEMP/package/README"
# Create the repository section folder to place all the data in
mkdir -p "$TEMP/package/pantheon-data/$SECT"
mkdir -p "$TEMP/package/pantheon-data/$SECT/icons/128x128"
mkdir -p "$TEMP/package/pantheon-data/$SECT/icons/64x64"

# Start download the data from elementary's mirrored repo
wget "$URL/dists/$DIST/$SECT/dep11/Components-amd64.yml.gz" -O "$TEMP/components.yml.gz"
wget "$URL/dists/$DIST/$SECT/dep11/icons-128x128.tar.gz" -O "$TEMP/icons-128.tar.gz"
wget "$URL/dists/$DIST/$SECT/dep11/icons-64x64.tar.gz" -O "$TEMP/icons-64.tar.gz"

# Unpack all the data and put it where it needs to go
mv "$TEMP/components.yml.gz" "$TEMP/package/pantheon-data/$SECT/pantheon_$DIST-${SECT}_${ARCH}.yml.gz"
tar -xf "$TEMP/icons-128.tar.gz" -C "$TEMP/package/pantheon-data/$SECT/icons/128x128"
tar -xf "$TEMP/icons-64.tar.gz" -C "$TEMP/package/pantheon-data/$SECT/icons/64x64"

# At this point we build the extra package
touch "$TEMP/pantheon_xenial-${EXTR}_${ARCH}.yml"

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
} > "$TEMP/pantheon_xenial-${EXTR}_${ARCH}.yml"

# Iterate all the files
for file in $EXTR_FILES; do
    echo "---" >> "$TEMP/pantheon_xenial-${EXTR}_${ARCH}.yml"
    cat "$file" >> "$TEMP/pantheon_xenial-${EXTR}_${ARCH}.yml"
done

# Compress the yml file to the expected gz file
gzip "$TEMP/pantheon_xenial-${EXTR}_${ARCH}.yml"
# And move it in place
mv "$TEMP/pantheon_xenial-${EXTR}_${ARCH}.yml.gz" "$TEMP/package/pantheon-data/$EXTR/pantheon_$DIST-${EXTR}_${ARCH}.yml.gz"
