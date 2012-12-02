#!/mu/bin/perl -w

#D:\Perl\bin\perl

use strict;
use warnings;
use XML::Simple;
use Time::Local;
use Data::Dumper;
use CGI;
use LWP::Simple;

##########
#
#	Globals
#
##########

#EVE APIs
	my $vCode= "fm9UZdCrnM5x7C2x1v7zocPHSahscVMOVasV9AcJoUx1UojLxEWAD5EZi1Rl0mDK";#Lockefox -acct
	my $ID= 285;
 
	my $vCodeCorp= "";#AIDER -Locke -Full
	my $IDCorp;

#eve marketeer API	
	my $site="http://www.evemarketeer.com/api/info/";
	my $suffix="/xml";#search The Forge

	my %xmlhold;

	my $FILE="outfile.xml";
	my $TMP="PriceParse.xml";
	my $path=undef;
	
##########
#
#	EVEMARKETEER.COM Handles
#
##########
	
my %mineral=(
	11399, "Morphite",
	37, "Isogen",
	40, "Megacyte",
	36, "Mexallon",
	38, "Nocxium",
	35, "Pyerite",
	34, "Tritanium",
	39, "Zydrine",
);

my %PI=(
	3689, "Mechanical Parts",
	9842, "Miniature Electronics",
	9834, "Guidance System",
	9848, "Robotics",
	9830, "Rocket Fuel",
	9838, "Super Conductors",
	9840, "Transmitter",
	3828, "Construction Blocks",
	3685, "Hydrogen Batteries",
	3687, "Electronic Parts",
);

my %datacore=(
	20417, "Datacore - Electromagnetic Physics",
	20418, "Datacore - Electronic Engineering",
	20419, "Datacore - Graviton Physics",
	20411, "Datacore - High Energy Physics",
	20171, "Datacore - Hydromagnetic Physics",
	20413, "Datacore - Laser Physics",
	20424, "Datacore - Mechanical Engineering",
	20415, "Datacore - Molecular Engineering",
	20416, "Datacore - Nanite Engineering",
	20423, "Datacore - Nuclear Physics",
	20412, "Datacore - Plasma Physics",
	20414, "Datacore - Quantum Physics",
	20420, "Datacore - Rocket Science",
	20421, "Datacore - Amarrian Starship Engineering",
	25887, "Datacore - Caldari Starship Engineering",
	20410, "Datacore - Gallentean Starship Engineering",
	20172, "Datacore - Minmatar Starship Engineering",
);

my %component=(
	16670, "Crystalline Carbonite",
	17317, "Fermionic Condensates",
	16673, "Fernite Carbide",
	16683, "Ferrogel",
	16679, "Fullerides",
	16682, "Hypersynaptic Fibers",
	16681, "Nanotransisotrs",
	16680, "Phenolic Composits",
	16678, "Sylramic Fibers",
	16671, "Titanium Carbonite",
	16672, "Tungsten Carbonite",
);
	
##########
#
#	Main
#
##########
my $marketeer=1;
my $personal=0;
my $corp=0;

&ParseArgs();	#Reads line args
open (OUTFILE, ">", $FILE);
&Header();		#Constructs XML header

my $min_str=undef;
foreach my $key1 (keys %mineral){
	$min_str=$key1."_";
};

my $pi_str=undef;
foreach my $key2 (keys %PI){
	$pi_str=$key2."_";
};

my $comp_str=undef;
foreach my $key3 (keys %component){
	$comp_str=$key3."_";
};

my $dc_str=undef;
foreach my $key4 (keys %datacore){
	$dc_str=$key4."_";
};


if ($marketeer eq 1){	#Queries evemarketeer.com for current data
	print OUTFILE "\t<marketeer>\n";
	&Minerals();	#Adds Mineral data to XML
	&Components();	#Adds Component data to XML
	&PIs();			#Adds PI data to XML
	&Datacores();	#Adds Datacore data to XML
	print OUTFILE"\t</marketeer>\n";
};

if($personal eq 1){		#Queries personal api for current data
	
};

if($corp eq 1){			#Queries corp API for current data

};

##########
#
#	ParseArgs
#
##########

sub ParseArgs{
	
};

##########
#
#	Header
#
##########

sub Header{
	print OUTFILE "<root>\n";
	#my $test = getstore("http://www.evemarketeer.com/api/info/16670/xml/10000002", $TMP);
	#print $test;
	$path=`pwd`;
	my $sitename = $site."35".$suffix;
	my $sitetest = get($sitename);
	die $site." May be down.  Unable to access\n" unless defined $sitetest;
};

##########
#
#	Minerals
#
##########

sub Minerals{
	#open (XMLFILE, ">",$TMP);
	print OUTFILE "\t\t<minerals>\n";
	my $tmpurl = $site.$min_str.$suffix;
	
	my $tmpxml = new XML::Simple;
	
	my $data = $tmpxml->($holdxml);
	
	foreach my $mKey (keys %mineral){
		print OUTFILE "\t\t\t<".$mineral{$mKey}."\n";
		print OUTFILE "\t\t\t\t<buy_max>".$data->{row}->{buy_highest}."</buy_max>\n";

	}
	#foreach my $mKey (keys %mineral){
	#	print OUTFILE "\t\t\t<".$mineral{$mKey}.">\n";
	#	my $tmpurl = $site.$mKey.$suffix;
	#	
	#	my $tmpxml = new XML::Simple;
	#	
	#	my $holdxml = get($tmpurl);
	#	die "Could not access URL: ".$tmpurl."\n" unless defined $holdxml;
	#	
	#	my $data = $tmpxml->XMLin($holdxml);
	#	
	#	print OUTFILE "\t\t\t\t<buy_min>".$data->{row}->{buy_lowest}."</buy_min>\n
	#			\t\t\t\t<buy_max>".$data->{row}->{buy_highest}."</buy_max>\n
	#			\t\t\t\t<buy_avg>".$data->{row}->{buy_highest5}."</buy_avg>\n
	#			\t\t\t\t<sell_min>".$data->{row}->{sell_lowest}."</sell_min>\n
	#			\t\t\t\t<sell_max>".$data->{row}->{sell_highest}."</sell_max>\n
	#			\t\t\t\t<sell_avg>".$data->{row}->{sell_lowest5}."</sell_avg>\n
	#			\t\t\t\t<fresh>".$data->{row}->{datetime}."</fresh>\n";
	#	print OUTFILE "\t\t\t</".$mineral{$mKey}.">\n";
	#	
	#}
	print OUTFILE "\t\t</minerals>\n";
	#close (XMLFILE);
	#`rm $path/$TMP`;
};

##########
#
#	Components
#
##########

sub Components{
	print OUTFILE "\t\t<components>\n";
	foreach my $cKey (keys %component){
		print "\t\t\t<".$component{$cKey}.">\n";
		
		my $tmpurl = $site.$cKey.$suffix;
		
		my $tmpxml = new XML::Simple;
		
		my $holdxml = get($tmpurl);
		die "Could not access URL: ".$tmpurl."\n" unless defined $holdxml;
		
		my $data = $tmpxml->XMLin($holdxml);
		
		print OUTFILE "\t\t\t\t<buy_min>".$data->{row}->{buy_lowest}."</buy_min>\n
				\t\t\t\t<buy_max>".$data->{row}->{buy_highest}."</buy_max>\n
				\t\t\t\t<buy_avg>".$data->{row}->{buy_highest5}."</buy_avg>\n
				\t\t\t\t<sell_min>".$data->{row}->{sell_lowest}."</sell_min>\n
				\t\t\t\t<sell_max>".$data->{row}->{sell_highest}."</sell_max>\n
				\t\t\t\t<sell_avg>".$data->{row}->{sell_lowest5}."</sell_avg>\n
				\t\t\t\t<fresh>".$data->{row}->{datetime}."</fresh>\n";
		print OUTFILE "\t\t\t</".$component{$cKey}.">\n";
	}
	print OUTFILE "\t\t</components>\n";
};

##########
#
#	PIs
#
##########

sub PIs{
	print OUTFILE "\t\t<PI>\n";
	foreach my $pKey (keys %PI){
		print "\t\t\t<".$PI{$pKey}.">\n";
		
		my $tmpurl = $site.$pKey.$suffix;
		
		my $tmpxml = new XML::Simple;
		
		my $holdxml = get($tmpurl);
		die "Could not access URL: ".$tmpurl."\n" unless defined $holdxml;
		
		my $data = $tmpxml->XMLin($holdxml);
		
		print OUTFILE "\t\t\t\t<buy_min>".$data->{row}->{buy_lowest}."</buy_min>\n
				\t\t\t\t<buy_max>".$data->{row}->{buy_highest}."</buy_max>\n
				\t\t\t\t<buy_avg>".$data->{row}->{buy_highest5}."</buy_avg>\n
				\t\t\t\t<sell_min>".$data->{row}->{sell_lowest}."</sell_min>\n
				\t\t\t\t<sell_max>".$data->{row}->{sell_highest}."</sell_max>\n
				\t\t\t\t<sell_avg>".$data->{row}->{sell_lowest5}."</sell_avg>\n
				\t\t\t\t<fresh>".$data->{row}->{datetime}."</fresh>\n";
		print OUTFILE "\t\t\t</".$PI{$pKey}.">\n";
	}
	print OUTFILE "\t\t</PI>\n";
};

##########
#
#	Datacores
#
##########

sub Datacores{
	print OUTFILE "\t\t<datacores>\n";
	foreach my $dKey (keys %datacore){
		print "\t\t\t<".$datacore{$dKey}.">\n";
		
		my $tmpurl = $site.$dKey.$suffix;
		
		my $tmpxml = new XML::Simple;
		
		my $holdxml = get($tmpurl);
		die "Could not access URL: ".$tmpurl."\n" unless defined $holdxml;
		
		my $data = $tmpxml->XMLin($holdxml);
		
		print OUTFILE "\t\t\t\t<buy_min>".$data->{row}->{buy_lowest}."</buy_min>\n
				\t\t\t\t<buy_max>".$data->{row}->{buy_highest}."</buy_max>\n
				\t\t\t\t<buy_avg>".$data->{row}->{buy_highest5}."</buy_avg>\n
				\t\t\t\t<sell_min>".$data->{row}->{sell_lowest}."</sell_min>\n
				\t\t\t\t<sell_max>".$data->{row}->{sell_highest}."</sell_max>\n
				\t\t\t\t<sell_avg>".$data->{row}->{sell_lowest5}."</sell_avg>\n
				\t\t\t\t<fresh>".$data->{row}->{datetime}."</fresh>\n";
		print OUTFILE "\t\t\t</".$datacore{$dKey}.">\n";
	}
	print OUTFILE "\t\t</datacores>\n";
}