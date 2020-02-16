#!/bin/sh
#
# tzdata_js.sh - Create text files and JavaScript arrays containing the names
# the world's timezones.  These can be used for select lists in HTML pages.
#
TZURL=https://data.iana.org/time-zones/releases
TZPKG="tzdata2019c.tar.gz"
TZDIR="tzdata"

# Download and unpack the timezone data if needed.
if ! [ -f $TZPKG ]; then
  echo "Downloading timezone database..."

  # BSD variants will have fetch, Linux will have wget.
  if command -v fetch >/dev/null 2>&1; then
    DOWNLOAD="fetch"
  elif command -v wget >/dev/null 2>&1; then
    DOWNLOAD="wget"
  else
    echo "No command-line downloader found. Please download manually and run again."
    echo "$TZURL/$TZPKG"
  fi
  $DOWNLOAD $TZURL/$TZPKG
fi

if ! [ -d $TZDIR ]; then
  echo "Extracting timezone database..."
  mkdir $TZDIR
  cd $TZDIR
  tar -zxf ../tzdata2019c.tar.gz
else
  cd $TZDIR
fi

# Begin the conversion with plain text.
echo "Creating plain text files..."

# Identify files having timezones by looking for lines beginning with 'Zone'.
ZONEFILES=$(grep -l '^Zone' * | tr '\n' ' ')

# Extract zone names (e.g. America/Chicago) and sort into tznames.txt.
for FILE in $ZONEFILES; do grep '^Zone' $FILE | awk '{print $2'}; done | sort > tzNames.txt

# Extract just areas (e.g. the America in America/Chicago) into tzAreas.txt.
grep '/' tzNames.txt | awk -F/ '{print $1}' | uniq | sort > tzAreas.txt

# Extract locations (e.g. the Chicago in America/Chicago) into files named by
# the areas.  This is made more difficult by some timezones being named with
# subdirectories in their locations. (e.g. America/Argentina/Buenos_Aires)
for AREA in $(cat tzAreas.txt); do grep $AREA tzNames.txt | awk -F/ '{ printf $2; for(i=3; i<=NF; i++) { printf "/%s", $i }; printf "\n" }' > tz${AREA}.txt; done

# Create JavaScript arrays from the text files.
echo "Converting text files to JavaScript arrays..."
for FILE in tz*.txt; do
  BASENAME=$(basename -s .txt $FILE)
  echo "$BASENAME = [" > ${BASENAME}.js
  sed -e 's/^/  "/' -e 's/$/",/' -e '$s/,//' $FILE >> ${BASENAME}.js
  echo "];" >> ${BASENAME}.js
done

# Create HTML select lists from the text files.
echo "Converting text files to HTML <select> lists..."
for FILE in tz*.txt; do
  BASENAME=$(basename -s .txt $FILE)
  echo "<select id=\"$BASENAME\">" > ${BASENAME}.html
  sed -e 's/^/  <option>/' -e 's/$/<\/option>/' $FILE >> ${BASENAME}.html
  echo "</select>" >> ${BASENAME}.html
done

