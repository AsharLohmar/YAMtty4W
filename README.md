# YAMtty4W - Yet another Mintty 4 WSL

Yeah, so, as the name says here's to you "Yet another Mintty 4 WSL".

* Why's that ?  
'cause I'd rather `git clone` something than use an installer that scatters the stuff all over the place and does not give much space for customization. Oh ... and 'cause I could. 

* What's "Mintty" and "WSL" ?  
If you got here you either already know what they are, and thus you don't need an explanation, or you don't, in which case ... "these aren't the droids you're looking for".

* So what is it?
A bunch of scripts (haven't decided on the names just yet)    
 - settings.sh : holds a few configuration parameters
 - script1.sh : downloads the Cygwin packages and copies the necessary files to the destination folder; let's call it the installer
 - script2.sh : creates shortcuts for mintty in various locations for all the WSL distributions it can find installed
 - script3.sh: (idea) checks for updates, maybe
