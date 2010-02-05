Remora
======

Remora is a Ruby implementation of the Grooveshark client protocol. The
most notable reason that it doesn't use the API is so that it can access
streams. Remora runs purely in a console and uses mplayer to play the
Grooveshark streams.

Because Remora pipes the stream directly into Mplayer via a stdin, it
has a chance of working under Windows, provided that you have installed
Ruby and MPlayer. This is also better than using a temporary file on the
hard disk because Remora will never store any song to disk.

Legal
-----
Unfortunately, the public API no longer provides stream access. Remora
reimplements the stream-capable API that the official Flash client uses.
The intended targets are users who can't run Flash for any reason. Since
Remora is designed to never store a byte of media to disk, streaming
with it is about equal to streaming with the official Flash client.

Either way, users of Remora should follow the official ToS (found
[here](http://www.grooveshark.com/terms) to the letter. I am not yet
sure to what degree of legality Remora is at, though it is not in
blatant violation of anything that I can find in the ToS. If there is
anything that I missed, be welcome to contact me. Please E-mail me at
remora@danopia.net or send me a message on GitHub if you have an
account already.

Finally, here is the uppercased paragraph that everyone was expecting.
Please note that I am not a lawyer, and I don't have any, so I wrote the
below attempt at legalese.

THIS APPLICATION DOES NOT COME WITH ANY WARRANT WHATSOEVER. This application IS NOT to be used for downloading copyrighted works. ANY CHANGES TO THE SOURCE CODE BY THE END-USER MAY CAUSE LEGAL VIOLATIONS! THIS APPLICATION IS STRICTLY MEANT TO PROVIDE AN ALTERNATIVE TO THE FLASH CLIENT. This application may be illegal in some countries. If you are unsure, please contact your lawyet for legal advice. NEITHER THE AUTHOR OR ANY OTHER PARTY RELATED TO THIS APPLICATION IS RESPONSIBLE FOR YOUR MISUSE AND/OR ILLEGAL USAGE! Remora is not associated with Grooveshark, EMG, Escape Media Group, Inc, any of their partners, SharkByte, GitHub, RIAA, or grooveshark.com in any way.

YOU EXPRESSLY ACKNOWLEDGE THAT YOU HAVE READ THIS AGREEMENT AND UNDERSTAND THE RIGHTS, OBLIGATIONS, TERMS AND CONDITIONS SET FORTH HEREIN. BY CONTINUING TO DOWNLOAD THIS SOFTWARE, YOU EXPRESSLY CONSENT TO BE BOUND BY ITS TERMS AND CONDITIONS.
