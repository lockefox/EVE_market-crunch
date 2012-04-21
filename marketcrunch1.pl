#!D:\Perl\bin\perl
use strict;
use warnings;
use HTTP::Request::Common qw(POST);
use XML::Simple;
use Time::Local;
use Data::Dumper;
use LWP::Simple;
use CGI;

##################################################
#
#	GLOBALS
#
##################################################

#####API's
my $char_ID = 285; #Locke's account key
my $char_VCODE = "fm9UZdCrnM5x7C2x1v7zocPHSahscVMOVasV9AcJoUx1UojLxEWAD5EZi1Rl0mDK";
my $charid = 628592330;	#Lockefox

my $corp_ID = 579145;
my $corp_VCODE = "VRLLgjaTD4TASFdmrTsx9szx3ymiAHo0hJprwym7oKjQOWBjVDa86qPrBBw7nVpw";
my $corpid = 1894214152;

#####EVE API Handles
#	keyID
#	vCode
#	itemID
#	
#####

#####Site Handles
my $evesite="http://api.eveonline.com/";
my $evecentral="http://api.eve-central.com/api/marketstat?";
my $marketeer="http://www.evemarketeer.com/api/info/";

my $station=60003760;	#Jita IV - Moon 4 CNAP
my $region=10000002;	#The Forge
my $system=30000142;	#Jita

#####Item Hashes
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
	
##################################################
#
#	MAIN
#
##################################################

my $switch = 1;
my $sitepre;
my $sitepost;
my $outfile="price.xml";
#Use eve-central by default

&parseArgs();
open (FILE, ">",$outfile);

&header();

&minerals();

&components();

&datacores();

print FILE "</root>\n";
close FILE;
##################################################
#
#	parseArgs
#
##################################################
sub parseArgs{

};

##################################################
#
#	header
#
##################################################
sub header{
	print FILE "<root>\n";
	
	if($switch eq 0){
		$sitepre= $evecentral;
		$sitepost="usesystem=".$system;
	}
	elsif($switch eq 1){
		$sitepre= $marketeer;
		$sitepost="/xml/".$region;
	}
	
	print FILE "\t<source site=\"".$sitepre."\"></source>\n";
	my @curTime = localtime(time);
	my $day=$curTime[3];
	my $month=$curTime[4]+1;
	my $hr=$curTime[2];
	my $min=$curTime[1];
	print FILE "\t<fresh time=\"".$day."/".$month." ".$hr.":".$min."\"></fresh>\n";
	
};

##################################################
#
#	header
#
##################################################
sub minerals{
	print FILE "\t<mineral>\n";
	my $stuffstring;
	
	if ($switch eq 0){
		##Default case (EVE-CENTRAL)
		$stuffstring="";
		foreach my $m1Key (keys %mineral){
			$stuffstring= $stuffstring."typeid=".$m1Key."&";
		}
		
	}
		
	elsif ($switch eq 1){##Case for marketeer
		$stuffstring="";
		foreach my $m2Key (keys %mineral){
			$stuffstring= $stuffstring.$m2Key."_";
		}
		chop $stuffstring;
	}
	#else die "How did you end up here.  Invalid SWITCH\n";
		
	#print $stuffstring."\n";
	
	my $tmpxml = new XML::Simple;
	my $url = $sitepre.$stuffstring.$sitepost;

	my $data = $tmpxml->XMLin(get($url));
	
	if ($switch eq 0){
		foreach my $m3Key (keys %mineral){
			print FILE "\t\t<".$m3Key." name=\"".$mineral{$m3Key}."\">\n";
			print FILE "\t\t\t<sell_min>".$data->{marketstat}->{type}->{$m3Key}->{sell}->{min}."</sell_min>\n";
			print FILE "\t\t\t<sell_avg>".$data->{marketstat}->{type}->{$m3Key}->{sell}->{avg}."</sell_avg>\n";
			print FILE "\t\t\t<sell_med>".$data->{marketstat}->{type}->{$m3Key}->{sell}->{median}."</sell_med>\n";
			print FILE "\t\t\t<buy_max>".$data->{marketstat}->{type}->{$m3Key}->{buy}->{max}."</buy_max>\n";
			print FILE "\t\t\t<buy_avg>".$data->{marketstat}->{type}->{$m3Key}->{buy}->{avg}."</buy_avg>\n";
			print FILE "\t\t\t<buy_med>".$data->{marketstat}->{type}->{$m3Key}->{buy}->{median}."</buy_med>\n";
			print FILE "\t\t</".$m3Key.">\n";
			#print $mineral{$m3Key}." min ".$data->{marketstat}->{type}->{$m3Key}->{sell}->{min}."\n";
		}
	}
	elsif($switch eq 1){
		foreach my $m4Key (keys %mineral){
			print FILE "\t\t<".$m4Key." name=\"".$mineral{$m4Key}."\">\n";
			my $data2 = $tmpxml->XMLin(get($sitepre.$m4Key.$sitepost));
			print FILE "\t\t\t<buy_max>".$data2->{row}->{buy_highest}."</buy_min>\n";
			print FILE "\t\t\t<buy_avg>".$data2->{row}->{buy_avg}."</buy_avg>\n";
			print FILE "\t\t\t<buy_med>".$data2->{row}->{buy_highest5}."</buy_med>\n";
			print FILE "\t\t\t<sell_min>".$data2->{row}->{sell_lowest}."</sell_min>\n";
			print FILE "\t\t\t<sell_avg>".$data2->{row}->{sell_avg}."</sell_avg>\n";
			print FILE "\t\t\t<sell_med>".$data2->{row}->{sell_lowest5}."</sell_med>\n";
			print FILE"\t\t</".$m4Key.">\n";
		}
	}
	#else die "Really?  You had to cheat to get here.  Invalid SWITCH again\n";
	print FILE "\t</mineral>\n";
};

##################################################
#
#	components
#
##################################################
sub components{
	print FILE "\t<component>\n";
	my $stuffstring;
	
	if ($switch eq 0){
		##Default case (EVE-CENTRAL)
		$stuffstring="";
		foreach my $c1Key (keys %component){
			$stuffstring= $stuffstring."typeid=".$c1Key."&";
		}
		
	}
		
	elsif ($switch eq 1){##Case for marketeer
		$stuffstring="";
		foreach my $c2Key (keys %component){
			$stuffstring= $stuffstring.$c2Key."_";
		}
		chop $stuffstring;
	}
	#else die "How did you end up here.  Invalid SWITCH\n";
		
	#print $stuffstring."\n";
	
	my $tmpxml = new XML::Simple;
	my $url = $sitepre.$stuffstring.$sitepost;

	my $data = $tmpxml->XMLin(get($url));
	

	
	if ($switch eq 0){
		foreach my $c3Key (keys %component){
			print FILE "\t\t<".$c3Key." name=\"".$component{$c3Key}."\">\n";
			print FILE "\t\t\t<sell_min>".$data->{marketstat}->{type}->{$c3Key}->{sell}->{min}."</sell_min>\n";
			print FILE "\t\t\t<sell_avg>".$data->{marketstat}->{type}->{$c3Key}->{sell}->{avg}."</sell_avg>\n";
			print FILE "\t\t\t<sell_med>".$data->{marketstat}->{type}->{$c3Key}->{sell}->{median}."</sell_med>\n";
			print FILE "\t\t\t<buy_max>".$data->{marketstat}->{type}->{$c3Key}->{buy}->{max}."</buy_max>\n";
			print FILE "\t\t\t<buy_avg>".$data->{marketstat}->{type}->{$c3Key}->{buy}->{avg}."</buy_avg>\n";
			print FILE "\t\t\t<buy_med>".$data->{marketstat}->{type}->{$c3Key}->{buy}->{median}."</buy_med>\n";
			print FILE "\t\t</".$c3Key.">\n";
			#print $mineral{$m3Key}." min ".$data->{marketstat}->{type}->{$m3Key}->{sell}->{min}."\n";
		}
	}
	elsif($switch eq 1){
		foreach my $c4Key (keys %component){
			print FILE "\t\t<".$c4Key." name=\"".$component{$c4Key}."\">\n";
			my $data2 = $tmpxml->XMLin(get($sitepre.$c4Key.$sitepost));
			print FILE "\t\t\t<buy_max>".$data2->{row}->{buy_highest}."</buy_max>\n";
			print FILE "\t\t\t<buy_avg>".$data2->{row}->{buy_avg}."</buy_avg>\n";
			print FILE "\t\t\t<buy_med>".$data2->{row}->{buy_highest5}."</buy_med>\n";
			print FILE "\t\t\t<sell_min>".$data2->{row}->{sell_lowest}."</sell_min>\n";
			print FILE "\t\t\t<sell_avg>".$data2->{row}->{sell_avg}."</sell_avg>\n";
			print FILE "\t\t\t<sell_med>".$data2->{row}->{sell_lowest5}."</sell_med>\n";
			print FILE"\t\t</".$c4Key.">\n";
		}
	}
	#else die "Really?  You had to cheat to get here.  Invalid SWITCH again\n";
	print FILE "\t</component>\n";
};

##################################################
#
#	datacores
#
##################################################
sub datacores{
	print FILE "\t<datacore>\n";
	my $stuffstring;
	
	if ($switch eq 0){
		##Default case (EVE-CENTRAL)
		$stuffstring="";
		foreach my $d1Key (keys %datacore){
			$stuffstring= $stuffstring."typeid=".$d1Key."&";
		}
		
	}
		
	elsif ($switch eq 1){##Case for marketeer
		$stuffstring="";
		foreach my $d2Key (keys %datacore){
			$stuffstring= $stuffstring.$d2Key."_";
		}
		chop $stuffstring;
	}
	#else die "How did you end up here.  Invalid SWITCH\n";
		
	#print $stuffstring."\n";
	
	my $tmpxml = new XML::Simple;
	my $url = $sitepre.$stuffstring.$sitepost;

	my $data = $tmpxml->XMLin(get($url));
	

	
	if ($switch eq 0){
		foreach my $d3Key (keys %datacore){
			print FILE "\t\t<".$d3Key." name=\"".$datacore{$d3Key}."\">\n";
			print FILE "\t\t\t<sell_min>".$data->{marketstat}->{type}->{$d3Key}->{sell}->{min}."</sell_min>\n";
			print FILE "\t\t\t<sell_avg>".$data->{marketstat}->{type}->{$d3Key}->{sell}->{avg}."</sell_avg>\n";
			print FILE "\t\t\t<sell_med>".$data->{marketstat}->{type}->{$d3Key}->{sell}->{median}."</sell_med>\n";
			print FILE "\t\t\t<buy_max>".$data->{marketstat}->{type}->{$d3Key}->{buy}->{max}."</buy_max>\n";
			print FILE "\t\t\t<buy_avg>".$data->{marketstat}->{type}->{$d3Key}->{buy}->{avg}."</buy_avg>\n";
			print FILE "\t\t\t<buy_med>".$data->{marketstat}->{type}->{$d3Key}->{buy}->{median}."</buy_med>\n";
			print FILE "\t\t</".$d3Key.">\n";
			#print $mineral{$m3Key}." min ".$data->{marketstat}->{type}->{$m3Key}->{sell}->{min}."\n";
		}
	}
	elsif($switch eq 1){
		foreach my $d4Key (keys %datacore){
			print FILE "\t\t<".$d4Key." name=\"".$datacore{$d4Key}."\">\n";
			my $data2 = $tmpxml->XMLin(get($sitepre.$d4Key.$sitepost));
			print FILE "\t\t\t<buy_max>".$data2->{row}->{buy_highest}."</buy_max>\n";
			print FILE "\t\t\t<buy_avg>".$data2->{row}->{buy_avg}."</buy_avg>\n";
			print FILE "\t\t\t<buy_med>".$data2->{row}->{buy_highest5}."</buy_med>\n";
			print FILE "\t\t\t<sell_min>".$data2->{row}->{sell_lowest}."</sell_min>\n";
			print FILE "\t\t\t<sell_avg>".$data2->{row}->{sell_avg}."</sell_avg>\n";
			print FILE "\t\t\t<sell_med>".$data2->{row}->{sell_lowest5}."</sell_med>\n";
			print FILE"\t\t</".$d4Key.">\n";
		}
	}
	#else die "Really?  You had to cheat to get here.  Invalid SWITCH again\n";
	print FILE "\t</datacore>\n";
};