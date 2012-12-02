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

my %existing;#takes in existing results file
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
#open (FILE, ">", $outfile);
my %marketeerKeys=(
	
);
my %centralKeys=(	#need to cycle buy->%keys and sell->%keys
	"buy"=>{
		"max", 0,
		"avg", 0,
		"median", 0,
	},
	"sell"=>{
		"min", 0,
		"avg", 0,
		"median", 0,
	},
);

my %skip=(
	"sc",0,
	"titan",0,
	"dread",0,
	"carrier",0,
);
my $inXML = new XML::Simple;
my $infile = $inXML->XMLin($outfile);

&loadXML();

&fetchprices();
&printer();



sub loadXML{
	foreach my $type (keys %{$infile}){
		foreach my $itemID (keys %{$infile->{$type}}){
			foreach my $prices (keys %{$infile->{$type}->{$itemID}}){
				if ($prices eq "name"){
					$names{$itemID}=$infile->{$type}->{$itemID}->{name};
				}
				$existing{$type}{$itemID}{$prices}=$infile->{$type}->{$itemID}->{$prices};
			}
		}
	}
	
};

sub fetchprices{
	my $id;
	my $tmpxml = new XML::Simple;
	my $url;
	
	if ($switch eq 0){
		$sitepre=$evecentral;
		$sitepost="usesystem=".$system;
		my $query="";
		foreach my $itemtype (keys %existing){
			if (exists $skip{$itemtype}){
				next;
			}
			foreach my $itemid (keys %{$existing{$itemtype}}){
				(undef, $id) = split ('i', $itemid);
				$query= $query."typeid=".$id."&";
			}
			$url = $sitepre.$query.$sitepost;
			#print $url."\n";
			my $data = $tmpxml->XMLin(get($url));
			
			foreach my $itemids (keys %{$existing{$itemtype}}){
				(undef, $id) = split ('i', $itemids);
				foreach my $queries (keys %centralKeys){
					#print $queries;
					foreach my $keytype (keys %{$centralKeys{$queries}}){
						my $writekey = $queries."_".$keytype."-central";
						#print $writekey.":";
						$existing{$itemtype}{$itemids}{$writekey}=$data->{marketstat}->{type}->{$id}->{$queries}->{$keytype};
						#print "\n";
					}
					#print "\n";
				}
			}
		}
		#print Dumper(%existing);
	}
	elsif ($switch eq 1){
		$sitepre=$marketeer;
		$sitepost="";
	}
	
	

};

sub printer{
	my $writeout = new IO::File (">$outfile");
	
	my $writer = new XML::Writer ( DATA_MODE => 'true', DATA_INDENT => 2, OUTPUT => $writeout);
	
	$writer->xmlDecl( 'UTF-8' );
	
	$writer->startTag('root');
	
	foreach my $typekey(keys %existing){
		$writer->startTag($typekey);
		foreach my $prodkey (keys %{$existing{$typekey}}){
			$writer->startTag($prodkey, 'name'=>$names{$prodkey});
			foreach my $keytype (keys %{$existing{$typekey}{$prodkey}}){
				if ($keytype eq "name"){
					next;
				}
				$writer->startTag($keytype);
				$writer->characters($existing{$typekey}{$prodkey}{$keytype});
				$writer->endTag();
			}
			$writer->endTag();
		}
		$writer->endTag();
	}
	$writer->endTag();
	$writer->end();
	
}