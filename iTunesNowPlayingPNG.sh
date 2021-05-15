#!/bin/sh
#
# OSX shell script to get current itunes track information and write to a file for OBS. 
# Thanks to http://hints.macworld.com/article.php?story=20011108211802830 
# This relies on osascript so likely isn't useful on systems other than OSX.  
#
# Edit "outputDir" to say where your OBS image source files will go.
# (not the same as the script directory). This works across a network share as long
#   as the remote directory is already mounted, which is how I use it.  
#
# Needs a file called "noart.jpg" to use when no album art is present. 
# Uses a file called "blank.png" which is an all-tranparent image to show when 
# nothing is playing.  
# 
# Customize your colours and styles for the HTML in the nowplaying.css. 
#
# Tries to write a file only when the track changes to cut down on file writing traffic. 
#
# This uses Headless Chrome (set path in runHeadlessChrome() ) to render the HTML as 
# a PNG. https://developers.google.com/web/updates/2017/04/headless-chrome
#
# To use in OBS, use a image Source pointing to the local file "nowplaying.png." It should
# update in OBS when the image in the file changes. 
#
# Use ctrl-c to stop the script, and have it clean up the image on exit. 
#
# November 2020 - May 2021


# Clean up in the event we ctrl-c out of the program, clear the file so old 
# info isn't on screen
function trap_ctrlc()
{
	echo "\nctrl-c, cleaning up file"
	cp "$currentDir/blank.png" "$outputDir/$outputFile"
	exit 
}

# Headless Chrome does all the work of rendering the HTML file to a PNG. 
# Headless chrome spits out a lot of superfluous output and thus the "2>/dev/null"
# which will also not show you errors, so if you're having trouble remove that part
# to see what's going on. 
runHeadlessChrome() {
	/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --headless \
	--disable-gpu --window-size=800,150 --default-background-color=0 \
	--screenshot="$outputFile" "$htmlFile" 2>/dev/null
}

# this sets up the ctrl-c trap
trap "trap_ctrlc" 2

# Output directory and file.  This can be a network share as long as it's mounted in OSX. 
outputDir="/Volumes/Users/Steven Cogswell/Desktop";
htmlFile="nowplaying.htm";
outputFile="nowplaying.png";

# Use this variable as a watchdog to see if the track has changed since the last iteration
lastOutput="";  

# loop forever until you ctrl-c the program
while :
do

# Get the full path to the directory the script is in, surprisingly complicated on OSX
# https://serverfault.com/questions/40144/how-can-i-retrieve-the-absolute-filename-in-a-shell-script-on-mac-os-x
currentDir="$(cd "$(dirname "$0")" && pwd -P)"

# Check if the output directory exists
if [ ! -d "$outputDir" ]; then
	echo "Output directory not found ($outputDir)";
	exit;
fi

state=`osascript -e 'tell application "iTunes" to player state as string'`;
printf "\r\033[0KiTunes is currently [$state]";  # uses weird control sequence to overprint the current line
if [ $state = "playing" ]; then
	artist=`osascript -e 'tell application "iTunes" to artist of current track as string'`;
	track=`osascript -e 'tell application "iTunes" to name of current track as string'`;
	album=`osascript -e 'tell application "iTunes" to album of current track as string'`;
	thisOutput="$artist$track$album"  # Track changes in tracks 
	
	if [ ! "$thisOutput" = "$lastOutput" ]; then
		printf "\nTRACK CHANGE\n";   
		printf "$track by $artist ($album)\n"; 
		lastOutput=$thisOutput;  
		
		# clean up previous album art
		if [ -f "$currentDir/albumart.jpg" ]; then
			rm "$currentDir/albumart.jpg"
		fi

		if [ -f "$currentDir/albumart.png" ]; then
			rm "$currentDir/albumart.png"
		fi
		 
		# Run osascript with a heredoc so we don't have to put the script in a separate file.
		# Note this script works with POSIX paths so we can use local script variables
		osascript <<EOD
-- adapted from https://stackoverflow.com/questions/16995273/getting-artwork-from-current-track-in-applescript
-- get the raw bytes of the artwork into a var
try 
tell application "iTunes" to tell artwork 1 of current track
    set srcBytes to raw data
    -- figure out the proper file extension
    if format is «class PNG » then
        set ext to ".png"
    else
        set ext to ".jpg"
    end if
end tell
on error the errorMessage number the errorNumber
	return
end try 

-- get the filename, using POSIX paths since we're working inside a sh script
set thisDirectory to "$currentDir"
set filePath to ((Posix path of thisDirectory) & "/")
set fileName to ( filePath & "albumart" & ext)
-- write to file
set outFile to open for access POSIX file fileName with write permission
-- truncate the file
set eof outFile to 0
-- write the image bytes to the file
write srcBytes to outFile
close access outFile	
EOD
		# If the album art came out as png, let's convert it to jpeg. 
		if [ -f "$currentDir/albumart.png" ]; then
			SIPS=`sips -s format jpeg albumart.png --out albumart.jpg`;
			rm "$currentDir/albumart.png";
		fi
	
		if [ ! -f "$currentDir/albumart.jpg" ]; then    # Failsafe in case no album art file shows up
			echo "Can't find $currentDir/albumart.jpg using $currentDir/noart.jpg"; 
			cp "$currentDir/noart.jpg" "$currentDir/albumart.jpg";
		fi
		
		if [ ! -f "$currentDir/nowplaying.css" ]; then  # Check for stylesheet in this directory
			echo "Can't find style sheet ""$currentDir/nowplaying.css";
		fi
		
		# Write a little browser-source html file with the information in it.  Uses nowplaying.css in the same folder
		# as where you write the file. 
		echo "<head><link rel=\"stylesheet\" href=\"nowplaying.css\"></head>
	      	<table>
	      	<td><img src=\"albumart.jpg\" width=\"128\"></td>
	      	<td>
	      	<div class=\"infobox\">
	      	<div class=\"track\">\"$track\"</div>
		  	<div class=\"artist\">$artist</div>
		  	<div class=\"album\">$album</div>
		  	</div>
		  	</td>" > $currentDir/$htmlFile;
		# Run Headless Chrome to generate a PNG from the html file.  
		runHeadlessChrome
		cp "$currentDir/$outputFile" "$outputDir/$outputFile";
	fi
else
	# Nothing is playing, blank output
	lastOutput=""; 
	cp "$currentDir/blank.png" "$outputDir/$outputFile";
fi

# Wait to check again
sleep 2

done   # While wait forever 
