 # README

 OSX shell script to get currently playing iTunes track information and write it to a file for an OBS overlay.

 This modifies a previous script ``iTunesNowPlaying.sh`` to use Headless Chrome to render the HTML directly to a PNG and remove the requirement for browser source windows in OBS. Sometimes the html would flicker when it was rendering in OBS. OBS also auto-refreshes images without intervention so the requirement for meta-refresh is removed.  

# Screenshot 
![Screenshot](screenshot.png)

# Caveat

 This relies on osascript so likely isn't useful on systems other than OSX. I wrote this for myself for my streaming setup so it probably doesn't work out of the box the right way for you.  I use iTunes playing on a Mac from a local library (not Apple Music), and the actual streaming machine running OBS Studio is Windows 7. Files are transferred via a directory shared on the streaming computer and mounted on OSX. As they say "your mileage may vary."

 I wrote and run this under OSX 10.13.6 (High Sierra), it doesn't rely on any external dependencies other than Headless Chrome on OSX X (a normal google chrome installation is sufficient to run Headless Chrome). 

# Usage
After editing the script to match your setup, in an OSX terminal window, invoke the script with ``./iTunesNowPlayingPNG.sh``

 Edit ``outputDir`` to say where your OBS Image source files will go. Do not use the same directory as the script directory. This works across a mounted network share as long as the remote directory is already mounted, which is how I use it.  

 Needs a file called ``noart.jpg`` to use when no album art is present.  Otherwise it will try to use album art (``.png`` or ``.jpg``) associated with the playing track.

Use ``nowplaying.css`` to customize your colours and styles and layout of the HTML file. 
 
 The script tries to write a file only when the track changes to cut down on file writing traffic. 

 To use in OBS, use a Browser Source pointing to the local file ``nowplaying.png`` in the ``outputDir`` directory. 

 By default I make it generate a 800x150 pixel image. The album art is scaled via the html file to 128px for display.  The artwork files themselves are not resized so you can probably use sizes other than 128px just by editing the css/html parts. 

 Use ``ctrl-c`` to stop the script, and it will copy the ``blank.png`` into position on exit. 

 # Files Used
``blank.png``: an all-transparent PNG that is used when iTunes is paused.  You could make this something else if you wanted to default show something when nothing is playing. 

``noart.jpg``: the image used in the render when iTunes can't get album art for the track

``nowplaying.css``: styling for the HTML file generated. Edit this to customize colours. 

``Headless Chrome``: change the path in runHeadlessChrome() if your google chrome is installed in a different directory than ``/Applications``x

Thanks to http://hints.macworld.com/article.php?story=20011108211802830 for how to use osascript with iTunes, and https://stackoverflow.com/questions/16995273/getting-artwork-from-current-track-in-applescript for how to get the playing artwork via osascript.  
Headless Chrome: https://developers.google.com/web/updates/2017/04/headless-chrome