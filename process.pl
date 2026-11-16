#!/usr/bin/perl
#
# process.pl
# hopz - 06/15/2002
# Graham Wooden
#
# This is meant to run independently. One option is for this to called when routine.pl is done, so that way its all timed well.
#
# This will go through the non-processed events, and evaluated the respective feed output from the events.
# Its meant to call out a difference in hops (like a path change) as well as if there was a latency increase from the previous event.
#
# This is a work in progress.  This will need to revamped and expanded as it gets used.

use strict;
use warnings;
use DBI;

my ($sec,$min,$hour) = localtime();

my $database = "hopz";
my $host     = "localhost";
my $port     = "3306"; 
my $username = "xxxxxx";
my $password = "xxxxxx";

my $dsn = "DBI:mysql:database=$database;host=$host;port=$port";
my $dbh = DBI->connect($dsn, $username, $password) or die "Could not connect to database: $DBI::errstr";

my $sth = $dbh->prepare("SELECT id,endpoint_id,event,epoch,timestamp FROM events WHERE processed=\"N\"");
$sth->execute();

while (my @eventRow = $sth->fetchrow_array()) {
	my $sth2 = $dbh->prepare("SELECT host,host_interval FROM endpoints WHERE id=\"$eventRow[1]\"");
	$sth2->execute();
	my @endpointRow = $sth2->fetchrow_array();	
	my $previousTime = (($eventRow[3] - ($endpointRow[1] * 60)) - 10);

	# lets find the previous event in these time constraints, so we can start to compare
	my $sql = "SELECT id,event,epoch,timestamp FROM events WHERE endpoint_id=\"$eventRow[1]\" AND epoch >= $previousTime AND epoch < $eventRow[3]";

	#print "sql is $sql\n";
	my $sth3 = $dbh->prepare($sql);
	$sth3->execute();
	my @previousEvent = $sth3->fetchrow_array();	
	if ($previousEvent[0]) {
		print "$endpointRow[0] -> Evaluating event @ $eventRow[4] w/ Previous event @ $previousEvent[3]\n";

		# we have our current event, and the previous one - lets compare the feeds.
		# Start with the previous one.
	
		my $sth4 = $dbh->prepare("SELECT hop,hop_name,ms FROM feed WHERE events_id=\"$previousEvent[0]\"");
		$sth4->execute();

		while (my @previousFeedRow = $sth4->fetchrow_array()) {
			#print "$previousFeedRow[0] $previousFeedRow[1] $previousFeedRow[2]\n";

			my $sth5 = $dbh->prepare("SELECT hop,hop_name,ms FROM feed WHERE events_id=\"$eventRow[0]\" AND hop=\"$previousFeedRow[0]\"");
			# we already know the hop value, but including it back in the select to help align the result with the previous event.
			#
			$sth5->execute();
			my @feedRow = $sth5->fetchrow_array();

			# I am not sure if this is the best way to calc a tolerance threashold.
			# That is because as we get further out, the natural latency increases and it's not really
			# comparable to earlier hosts in the route.  This may need some re-thought later.
			#my $increaseLimit = (($previousFeedRow[2] * 0.75) / $previousFeedRow[0]);
			my $increaseLimit = 5;

			my $alarm1;
			if ($previousFeedRow[0] != "9999") {

				if ($feedRow[1] ne $previousFeedRow[1]) {
					$alarm1 = "hop $feedRow[0] - Possible Route Change";
				}
				if (($feedRow[2] - $previousFeedRow[2]) > $increaseLimit) {
					my $increaseAmount = sprintf("%.3f",($feedRow[2] - $previousFeedRow[2]));
					$alarm1 = "hop $feedRow[0] - Latency diff increased by ${increaseAmount}ms";
				}		

				print "
hop $previousFeedRow[0] -->
   Previous IP:\t$previousFeedRow[1]\t@\t$previousFeedRow[2]ms
    Current IP:\t$feedRow[1]\t@\t$feedRow[2]ms\n";
				if ($alarm1) {
					print "---> $alarm1 <---\n";
					my $sth8 = $dbh->prepare("INSERT INTO alarms(events_id,timestamp,details) VALUES (\"$eventRow[0]\",NOW(),\"$alarm1\")");
					$sth8->execute();
					$sth8->finish();
				}
			} else {
				# reached 9999 - final
				print "
!!! Final for $endpointRow[0] !!!
   Previous IP:\t$previousFeedRow[1]\t@\t$previousFeedRow[2]ms
    Current IP:\t$feedRow[1]\t@\t$feedRow[2]ms\n\n";
			}
			$sth5->finish();
		}


		my $sth7 = $dbh->prepare("UPDATE events SET processed=\"Y\" WHERE id=\"$previousEvent[0]\" OR id=\"$eventRow[0]\"");
		$sth7->execute();
		$sth7->finish();
		$sth4->finish();

	} else {
		# There isn't a previous event to measure against. So we'll have to use the next one, and then use that to check
		# against this one. Nothing to do for now.  Maybe in the future?

	}

	$sth2->finish();
	$sth3->finish();
}

$sth->finish();
$dbh->disconnect();
