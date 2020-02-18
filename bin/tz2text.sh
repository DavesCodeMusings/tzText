#!/bin/sh
#
# tz2text.sh - Create text files and JavaScript arrays containing the names
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

# Extract zone names (e.g. America/Chicago) and sort into tzAll.txt.
for FILE in $ZONEFILES; do grep '^Zone' $FILE | awk '{print $2'}; done | sort > tzAll.txt

# Extract just areas (e.g. the America in America/Chicago) into tzAreas.txt.
grep '/' tzAll.txt | awk -F/ '{print $1}' | uniq | sort > tzAreas.txt

# Extract locations (e.g. the Chicago in America/Chicago) into files named by
# the areas.  This is made more difficult by some timezones being named with
# subdirectories in their locations. (e.g. America/Argentina/Buenos_Aires)
for AREA in $(cat tzAreas.txt); do grep "^${AREA}/" tzAll.txt | awk -F/ '{ printf $2; for(i=3; i<=NF; i++) { printf "/%s", $i }; printf "\n" }' > tz${AREA}.txt; done

# Create HTML select lists from the text files.
echo "Converting text files to HTML <select> lists..."
for FILE in tz*.txt; do
  BASENAME=$(basename -s .txt $FILE)
  echo "<select id=\"$BASENAME\">" > ${BASENAME}.html
  sed -e 's/^/  <option>/' -e 's/$/<\/option>/' $FILE >> ${BASENAME}.html
  echo "</select>" >> ${BASENAME}.html
done

# Create JSON files and JavaScript arrays from the text files.  The arrays
# become part of a single file called tzNamesLib.js.
echo "Converting text files to JSON and JavaScript arrays..."
>tzNamesLib.js
for FILE in tz*.txt; do
  BASENAME=$(basename -s .txt $FILE)

  # Write to a JSON file named for the Area (continent or ocean) it covers.
  echo "[" > ${BASENAME}.json
  sed -e 's/^/  "/' -e 's/$/",/' -e '$s/,//' $FILE >> ${BASENAME}.json
  echo "]" >> ${BASENAME}.json

  # Append to the JavaScript library.
  echo "const $BASENAME = [" >> tzNamesLib.js
  sed -e 's/^/  "/' -e 's/$/",/' -e '$s/,//' $FILE >> tzNamesLib.js
  echo "];" >> tzNamesLib.js
done

# Append an associative array object to tzNamesLib.js that allows timezone
# location arrays to be accessed by name, like this: 'tzAreas[areaName]'.
# The sed script below essentially takes whatever's on the line and makes a
# key of it that points to an array with the same name, except with a 'tz'
# prepended.  So a line with 'Africa' turns into '"Africa": tzAfrica,'.  And
# tzAreas["Africa"] then references the array tzAfrica.
echo "const tzAreasAssoc = {" >> tzNamesLib.js
sed -e 's/\(.*\)/  "\1": tz\1,/' -e '$s/,//' tzAreas.txt >> tzNamesLib.js
echo "};" >> tzNamesLib.js

# Append a function to the contents of tzNamesLib.js to auto-populate HTML
# select lists.  With this, a single <script src='tzNamesLib.js'></script>
# element is the only requirement to use the timezone names in any
# HTML/JavaScript page.
cat << EOF >> tzNamesLib.js
/*
  Auto-fill locations select list based on the currently selected area.
  Simply pass the ids of the area element and the location element.
*/
function tzUpdateLocations(areasElementId, locationsElementId) {
  area = document.getElementById(areasElementId).value;
  var options = '';
  for (var i=0; i<tzAreasAssoc[area].length; i++) {
    options += '<option>' + tzAreasAssoc[area][i] + '</option>\n';
  } 
  document.getElementById(locationsElementId).innerHTML = options;
}
EOF
