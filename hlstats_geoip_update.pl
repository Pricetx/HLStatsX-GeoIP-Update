#!/usr/bin/env perl

use Encode;
use DBI;
use Geo::IP::PurePerl;

# EDIT THE BELOW DETAILS TO MATCH YOUR SETUP

$dbname = "ENTER_DB_NAME";
$dbhost = "localhost";
$dbuser = "ENTER_DB_USER";
$dbpass = "ENTER_DB_PASS";
$geoip_path = "GeoLiteCity.dat"


# DO NOT EDIT BELOW THIS POINT

$maxid = 0;

my $dbh = DBI->connect("DBI:mysql:database=$dbname;host=$dbhost","$dbuser","$dbpass",{'RaiseError' => 1});

# now retrieve data from the table.
my $sth = $dbh->prepare("SELECT * FROM hlstats_Players ORDER BY playerID DESC LIMIT 1");
$sth->execute();
while (my $ref = $sth->fetchrow_hashref()) {
  $maxid = $ref->{'playerId'};
}
$sth->finish();

print "Highest ID: $maxid\n";

for( $i = 0; $i < $maxid; $i++) {

	$ip = "";
	my $sth = $dbh->prepare("SELECT * FROM hlstats_Players WHERE playerID = $i");
	$sth->execute();
	while (my $ref = $sth->fetchrow_hashref()) {
		$ip = $ref->{'lastAddress'};	
	}

	if ($ip ne "") {	

    	$gi = Geo::IP::PurePerl->open($geoip_path, GEOIP_STANDARD);	

		my ($country_code,
			$country_code3,
			$country_name,
			$region,
			$city,
			$postal_code,
			$lat,
			$lng,
			$metro_code,
			$area_code) = $gi->get_city_record($ip);

		$city = ((defined($city))?encode("utf8",$city):"");
		$state = ((defined($region))?encode("utf8",$region):"");
		$country = ((defined($country_name))?encode("utf8",$country_name):"");
		$flag = ((defined($country_code))?encode("utf8",$country_code):"");
		$lat = (($lat eq "")?undef:$lat);
		$lng = (($lng eq "")?undef:$lng);
		

		print "ID: $i | Country Code: $country_code | Region: $region\n";

		my $query = "UPDATE hlstats_Players SET city=?,state=?,country=?,flag=?,lat=?,lng=? WHERE playerId = ?";
		if(!defined($lat)) {
				$lat = "NULL";
		}
		if(!defined($lng)) {
			$lng = "NULL";
		}

		$sth = $dbh->prepare($query);
		$sth->execute($city, $state, $country, $flag, $lat, $lng, $i);

	}
}

$dbh->disconnect();
