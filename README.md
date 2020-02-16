# tzText
The world's timezones in plain text, JavaScript arrays, and HTML select lists.

BSD and Linux variants have timezone information for the entire world stored
in /usr/share/zoneinfo.  It is organized by directories of "areas" (named for
continents or oceans) and in each directory are "locations" (named for cities
or other population centers.)  For example, /usr/share/zoneinfo/Africa/Cairo
is a file descibing the timezone rules for Cairo, Egypt and the surrounding
area.

JavaScript has only two timezones: UTC and whatever the local browser is in.
I found myself needing to offer a list of timezone selections on a web page
and quickly bumped up against this limitation.  I was not using JQuery or
any other such frameworks, nor a PHP backend, just plain HTML.  A quick
internet search turned up nothing that fit my needs, so I wrote my own.

This project contains a script that starts with the same timezone database
used with BSD and Linux, and creates plain text files, JavaScript arrays,
and HTML select lists containing the standard timezone names.  This project
does not attempt to capture the timezone rules, only the names.  The goal is
simply to make it easier to select timezone names with an html form.

What you will find here:
/bin/tz2text.sh		The script used to do the conversion.
/tzdata/tz*.html	HTML select lists of areas and locations.
/tzdata/tz*.js		Javascript arrays of areas and locations.
/tzdata/tz*.txt		Plain text areas and locations.


I am offering the fruits of my labor to the public domain with no warranty
or support of any kind, nor any guaranty of fitness for a particular purpose.