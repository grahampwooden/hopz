# hopz - such a Gen-X name from 2002 ....

Pulled from a 2002 cvs archive that I totally forgot I made. I discovered it on an older SCSI disk that I had. I resurrected a dual P3 i686 machine and started to go through various disks that I had.  What a time capsule ... 

A simple set of tools to capture IP path metrics (hop count, latency) - either by ICMP or tcp/port.  I developed this during my LeasedMinds days.
I don't remember if it was for a client or just messing around.  This was about 24 years ago now ...

There are three file main scripts.  I presumed I was going to have a web-front end to manage this, but never got around to it.
Designed to be a simple LAMPP app (Linux, Apache, MySQL, PHP, Perl) - but just the backend and SQL stuff got done.

###########

routine.pl - the main script to run through the configured endpoints, set by their interval.  Endpoints can be either icmp a tcp port.
I set this to be by cron, run every minute.  Again, each point has their own interval and its checked against the minute.

###########

retrieve.pl - this gets called by routine.pl, to perform and capture the output from the mtr raw output.

###########

process.pl - This can run independently - but you will want to run it as soon as retrieve is done. So you are not processing a bunch of now outdated.

###########

hopz.sql - this is the MySQL table structures.  I have added a few hosts in the endpoints, as the ones I had back in 2002 were no longer valid.  Ha!

###########

NOTE - nothing has really changed from 2002. I exported out of my cvs, quickly ran on this new Debian system and publish here.  I believe this was put together on a RH or Fedora system back then.  It's been 24+ years.  I remember stuff generally working but there is lots of room for improvement here. I suspect it should work out of the gate.
