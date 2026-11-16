#!/usr/bin/perl
#
# retrieve.pl
# 2002-06-15 - Written by Graham Wooden
#
# this meant to be called via another process with args passed in.
# Go perform and store

use strict;
use warnings;
use DBI;

my $epoch = time;

my $database = "hopz";
my $host     = "localhost";
my $port     = "3306"; 
my $username = "xxxxxxx";
my $password = "xxxxxxx";

my $dsn = "DBI:mysql:database=$database;host=$host;port=$port";
my $dbh = DBI->connect($dsn, $username, $password) or die "Could not connect to database: $DBI::errstr";
my $sub = "";

######
my ($endpoint_id,$destination,$checkType,$checkPort) = @ARGV;
######

if (($checkType)||($checkPort)) {
	if ($checkType eq "tcp") {
		$sub = "--tcp -P $checkPort";
	} elsif ($checkType eq "udp") {
		$sub = "--udp -P $checkPort";
	}
}

# Maybe there is a better way to get this performed. Maybe a Perl library/routine,
# so we don't have the TTY/system overhead.  Should we really be worried at this stage?
my $command = "/usr/bin/mtr -l -c 1 $sub $destination";

my $hopIP;
my $prevIP = "0.0.0.0";
my $swapIP;
my $enteredHop = "N";
my $finalH = "N";
my $hopSeqNow = "0";
my $hopSeqPrev = "9999";

my @event = map {sprintf "%X", rand(16)} 1..18;
my $eventID = join('', @event);

#### EVENTS SQL
my $insert_sql = "INSERT INTO events(endpoint_id,event,timestamp,epoch,command_issued) VALUES (\"$endpoint_id\", \"$eventID\",NOW(),\"$epoch\",\"$command\")";
my $insert_sth = $dbh->prepare($insert_sql);
$insert_sth->execute();
my $eventSQLID = $dbh->last_insert_id();
$insert_sth->finish();

# print "$eventSQLID:$eventID\n";

#### PERFORM LINUX MTR COMMAND AND GRAB OUTPUT
my @mtrOutput = `$command`;

foreach my $rawLine (@mtrOutput) {
    chomp($rawLine);
    my @line = split (" ", $rawLine);

	if ($line[0] eq "x") {
		#print "x line\n";
		# entered hop
		$hopSeqPrev = $hopSeqNow;
		#$hopSeqNow = $line[1];
		$hopSeqNow++;

		if ($enteredHop eq "Y") {
			# this is a carry over ... previous hop didnt respond.
			# So we need to insert something for the previous hop before we continue.
			#
			#print "HOP TTL #$hopSeqPrev didn't respond - noting and moving on\n";
			#
			$insert_sql = "INSERT INTO feed(events_id,hop) VALUES (\"$eventSQLID\",\"$hopSeqPrev\")";
			$insert_sth = $dbh->prepare($insert_sql);
			$insert_sth->execute();
			$insert_sth->finish();

		} else {
			$enteredHop = "Y";
			#print "Starting hop --> hopSeqNow:$hopSeqNow\n";
		}

	} elsif ($line[0] eq "h") {

		if ($line[2] ne $prevIP) {
			# new hop IP
			$hopIP = $line[2];
			#print "h-->New IP:$hopIP, prevIP:$prevIP\n";
			$swapIP = "Y";
			$prevIP = $hopIP;

		} else {

			if ($swapIP ne "Y") {
				if ($finalH eq "N") {
					# we have the same IP and at a new HOP - this is the actual TCP handshake or echo-reply.
					# this is the final metric we need to capture and insert
					#print "2: h-->hopSeqNow:$hopSeqNow, hopSeqPrev:$hopSeqPrev\n";
					$finalH = "Y";
				}

			} else {

				if ($hopSeqNow ne $hopSeqPrev) {
					# this is the 2nd reply in our same hop #. Ignore as we just want to use the first TTL
					# metric.
					#print "1: h-->hopSeqNow:$hopSeqNow, hopSeqPrev:$hopSeqPrev\n";

				} else {
					# seemed like we'll need this ... but we'll see.
					#print "3: h-->hopSeqNow:$hopSeqNow, hopSeqPrev:$hopSeqPrev\n";

				}
			}
		}

	} elsif ($line[0] eq "p") {
		# reached the end of the hop - capture ms and reset
		#
		my $hopMS = sprintf ("%.3f", $line[2] / 1024);
		#
		if ($finalH eq "Y") {
			# this is the non-TTL reply metric
			#
			#print "FINAL RECEIPT for $destination is $hopMS\n";
			#
			$insert_sql = "INSERT INTO feed(events_id,hop,hop_name,ms) VALUES (\"$eventSQLID\",\"9999\",\"$destination\",\"$hopMS\")";

		} else {
			# this is the TTL reply metric
			#
			# print "HOP TTL #$hopSeqNow at $hopIP is $hopMS\n";
			#
			$enteredHop = "N";
			$swapIP = "N";
			$prevIP = $hopIP;
			$insert_sql = "INSERT INTO feed(events_id,hop,hop_name,ms) VALUES (\"$eventSQLID\",\"$hopSeqNow\",\"$hopIP\",\"$hopMS\")";
		}
		$insert_sth = $dbh->prepare($insert_sql);
		$insert_sth->execute();
		$insert_sth->finish();
	} 
    # Process the line here
    #print "Line: $line[0]\n";
}

$dbh->disconnect();
