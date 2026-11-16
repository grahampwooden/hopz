# hopz
Pulled from a 2002 cvs archive that I totally forgot I made.
A simple set of tools to capture IP path metrics (hop count, latency) - either by ICMP or tcp/port.

routine.pl - the main script to run through the configured endpoints, set by their interval.  Endpoints can be either icmp a tcp port.
I set this to be by cron, run every minute.  Again, each point has their own interval and its checked against the minute.

retrieve.pl - this gets called by routine.pl, to perform and capture the output from the mtr raw output.

process.pl - This can run independently - but you will want to run it as soon as retrieve is done. So you are not processing a bunch of now outdated.

NOTE - nothing has really changed from 2002. I exported out of my cvs, quickly ran on this new Debian system and publish here.  I believe this was put together on a RH or Fedora system back then.  It's been 24+ years.  I remember stuff generally working but there is lots of room for improvement here.
