#!/mu/bin/perl -w

use strict;
use warnings;
use HTTP::Request::Common qw(POST);
use XML::Simple;
use Time::Local;
use Data::Dumper;
use LWP::Simple;
use CGI;
use XML::Writer;
use POSIX qw(floor);
use IO;
use lib "/lib";

my %exsiting;#takes in existing results file
##$existing{type}{item id}{pricekey}=price

my %names; 	#uses name= attrib to save id names
## $names{id}=name

#####Site Handles
my $evesite="http://api.eveonline.com/";
my $evecentral="http://api.eve-central.com/api/marketstat?";
my $marketeer="http://www.evemarketeer.com/api/info/";

my $station=60003760;	#Jita IV - Moon 4 CNAP
my $region=10000002;	#The Forge
my $system=30000142;	#Jita

my $switch = 0;
my $sitepre;
my $sitepost;
my @timedata = localtime(time);
my $outfile= "results_W".($timedata[7]/7+1).".xml"; #REPLACE WITH DYNAMIC SWITCH

my %marketeerKeys=(
	
);

my %centralKeys=(

);

my $inXML = new XML::Simple;
my $infile = $inXML->XMLin($outfile);

sub loadXML{
	foreach my $type (keys %{$infile}){
		foreach my $itemID (keys %{$infile->{$type}}){
			$names{$itemID}=$infile->{$type}->{$itemID}->{name};
			foreach my $prices (keys %{$infile->{$type}->{$itemID}}){
				$existing{$type}{$itemID}{$prices};
			}
		}
	}
};

sub fetchprices{

	
};