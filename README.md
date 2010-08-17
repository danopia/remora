Remora
======

Remora is a Ruby implementation of the Grooveshark client protocol. The
most notable reason that it doesn't use the API is so that it can access
streams. Remora runs purely in a console and uses mplayer to play the
Grooveshark streams.

Because Remora uses a FIFO file to pipe the stream into Mplayer, it has
no chance of working under Windows. This is done instead of using a
temporary file on the hard disk because Remora will never store any
part of any song to disk.

Installation
------------

1. Clone the git repository

    $ git clone http://github.com/danopia/remora.git

    $ cd remora/

2. Check that your system has the required packages and gems

    $ ./check_dependencies.rb

    =>  Install dependencies if they are missing

3. Install bundled gem dependencies

    $ bundle install

4. Start remora

    $ ./remora

Usage
-----
Remora's Text UI is designed to be used like a normal GUI, including even mouse support (if using an xterm-compliant terminal emulator). When you run it, a connection to Grooveshark is acquired, which will impact the load time. The TUI is laid out in multiple panes: the left side is at a fixed width and includes the queue and a temporary thread list, while the right side is fluid and includes the main pane and the mplayer output. The main pane typically lists search results.

To find and queue a song, simply type in the search terms (i.e. song name) and hit enter. There are various ways to queue a song:

1. Click a song in the list and hit enter
2. Tab to the song list, use the arrow keys to select a song, and hit enter
3. Double-click a song (TODO: is this implemented?)
4. Type in the number of the result you want and hit enter

The song will automatically play. Don't forget to tab back to the search bar (or click it) before typing in another search!

If Remora hits the end of the queue before more songs are added, then it uses Grooveshark's radio feature and picks a new song based on the last 5 in the queue.

### More actions
When the list of results are being shown, use the `/info` command, followed by a number, to show a dialog with more info on a certain song.

To change songs, doubleclick the song you want to skip to in the queue. Note that this is currently not available without a mouse. You will need to click the main pane in order to use that again. (Soon tab will hopefully be able to cross between panes)

`/pause` toggles play/pause and `/stop` halts the queue. In order to resume playing after using `/stop`, you can either doubleclick a song in the queue, or when you don't have a mouse, queue a new song, and the queue will start over from the top.

`/login` displays a dialog allowing you to log in with your existing Grooveshark account. Doing so only has one advantage: after you log in, the search results will temporarily be replaced by your favorited songs.

`/player <command>` sends a raw line to the slave-mode mplayer instance. You can use this to get info out of the media stream (it will appear in the mplayer output pane) or to do strange and funky things, such as slow down the song's playback.
Legal
-----
Unfortunately, the public API no longer provides stream access. Remora
reimplements the stream-capable API that the official Flash client uses.
The intended targets are users who can't run Flash for any reason. Since
Remora is designed to never store a byte of media to disk, streaming
with it is about equal to streaming with the official Flash client.

Either way, users of Remora should follow the official ToS (found
[here](http://www.grooveshark.com/terms)) to the letter. I am not yet
sure to what degree of legality Remora is at, though it is not in
blatant violation of anything that I can find in the ToS. If there is
anything that I missed, be welcome to contact me. Please E-mail me at
remora@danopia.net or send me a message on GitHub if you have an
account already.

Finally, here is the uppercased paragraph that everyone was expecting.
Please note that I am not a lawyer, and I don't have any, so I wrote the
below attempt at legalese.

THIS APPLICATION DOES NOT COME WITH ANY WARRANT WHATSOEVER. This application IS NOT to be used for downloading copyrighted works. ANY CHANGES TO THE SOURCE CODE BY THE END-USER MAY CAUSE LEGAL VIOLATIONS! THIS APPLICATION IS STRICTLY MEANT TO PROVIDE AN ALTERNATIVE TO THE FLASH CLIENT. This application may be illegal in some countries. If you are unsure, please contact your lawyer for legal advice. NEITHER THE AUTHOR OR ANY OTHER PARTY RELATED TO THIS APPLICATION IS RESPONSIBLE FOR YOUR MISUSE AND/OR ILLEGAL USAGE! Remora is not associated with Grooveshark, EMG, Escape Media Group, Inc, any of their partners, SharkByte, GitHub, RIAA, or grooveshark.com in any way.

YOU EXPRESSLY ACKNOWLEDGE THAT YOU HAVE READ THIS AGREEMENT AND UNDERSTAND THE RIGHTS, OBLIGATIONS, TERMS AND CONDITIONS SET FORTH HEREIN. BY CONTINUING TO DOWNLOAD THIS SOFTWARE, YOU EXPRESSLY CONSENT TO BE BOUND BY ITS TERMS AND CONDITIONS.

