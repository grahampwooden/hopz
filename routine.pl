#!/usr/bin/perl
#
# routine.pl
# hopz - 6/15/2002
# Graham Wooden
#
# I suspect this will be some sort of wrapper - called from maybe from cron? - something that triggers to 
# run through the endpoints and process the output.  
# Each endpoint can have their own interval, so far, the intervals are 1,5,10,15,30,60,120.
#
# Depending on how many endpoints will be loaded, we may want to have each node have a static "sleep". 
# 
# Here is the cron that I have been using to test
# * * * * * /var/www/html/hopz/bin/routine.pl > /dev/null 2>&1

use strict;
use warnings;
use DBI;

my ($sec,$min,$hour) = localtime();
print "$hour:$min\n";

my $database = "hopz";
my $host     = "localhost";
my $port     = "3306"; 
my $username = "xxxxxxxxx";
my $password = "xxxxxxxxx";

my $dsn = "DBI:mysql:database=$database;host=$host;port=$port";
my $dbh = DBI->connect($dsn, $username, $password) or die "Could not connect to database: $DBI::errstr";

my $sth = $dbh->prepare("SELECT id,host,host_type,host_type_port,host_interval FROM endpoints WHERE active=\"Y\"");
$sth->execute();

while (my @row = $sth->fetchrow_array()) {
	# lets take care of the nulls.  There maybe a better way than this map routine
	@row = map { $_ // '' } @row;

   	if (($row[4] eq "1") || ($row[4] eq '')) {
		# just in case nothing was passed through, assign it 1 min ... why not ...
		print "Running $row[0]:$row[1]\n";
		my $callout = `/var/www/html/hopz/bin/retrieve.pl $row[0] $row[1] $row[2] $row[3]`;

   	} elsif ($min % $row[4] == 0 ) {
		print "Running $row[0]:$row[1]\n";
		my $callout = `/var/www/html/hopz/bin/retrieve.pl $row[0] $row[1] $row[2] $row[3]`;
   	}  else {
		# doesn't match ...
		print "Not Running $row[0]:$row[1] - because it's not time for a $row[4] min\n";
	}
}

$sth->finish();

# Lets now go through and determine if anything has changed in the last NNN minutes.
#

$dbh->disconnect();
