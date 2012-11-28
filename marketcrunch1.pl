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

my $AHM_ID=863121;
my $AHM_VCODE= "SYWn7mz9KINz4dYBlHsdZ4mSeeDctH8XZilUcwzhelKegdVJujLfOBajYEIhyBS0";

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

my %secondary=(
	16663, "Ceasarium Cadmide",
	16659, "Carbon Polymers",
	16660, "Ceramic Powder",
	16655, "Crystallite Alloy",
	16668, "Dysporite",			#
	16656, "Fernite Alloy",
	16669, "Ferrofluid",		#
	17769, "Fluxed Condensates",#
	16665, "Hexite",
	16666, "Hyperflurite",		#
	16667, "Neo Mercurite",		#
	16662, "Platinum Technite",
	17960, "Prometium",			#
	16657, "Rolled Tungsten",
	16658, "Silicon Diborite",
	16664, "Solerium",
	16661, "Sulfuric Acid",
	16654, "Titanium Chrimide",
	17958, "Vanadium Hafnite",
);

my %moongoo=(
	16634, "Atmospheric Gas",
	16643, "Cadmium",
	16647, "Ceasium",
	16641, "Chromium",
	16640, "Cobalt",
	16650, "Dysprosium",
	16635, "Evaporite Deposits",
	16648, "Hafnium",
	16633, "Hydrocarbons",
	16646, "Mercury",
	16651, "Neodymium",
	16644, "Platinum",
	16652, "Promethium",
	16639, "Scandium",
	16636, "Silicates",
	16649, "Technetium",
	16653, "Thulium",
	16638, "Titanium",
	16672, "Tungsten",
	16642, "Vanadium",
);

my %POS=(
	9832, "Coolant",
	44, "Enriched Uranium",
	3689, "Mechanical Parts",
	3683, "Oxygen",
	9848, "Robotics",
	16272, "Heavy Water",
	16273, "Liquid Ozone",
	17888, "Nitrogen Isotopes",	#Caldari
	17887, "Oxygen Isotopes",	#Gallente
	16274, "Helium Isotopes",	#Amarr
	17889, "Hydrogen Isotopes",	#Minmatar
	24592, "Amarr Empire Starbase Charter",
	24593, "Caldari State Starbase Charter",
	24594, "Gallente Federation Starbase Charter",
	24595, "Minmatar Republic Starbase Charter",
	24596, "Khanid Kingdom Starbase Charter",
	24597, "Ammatar Mandate Starbase Charter",
);
	
##################################################
#
#	MAIN
#
##################################################

my $switch = 0;
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

&PIs();

&secondaries();

&moongoos();

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
	
	print "Updating from: ".$sitepre."\n";
	
};

##################################################
#
#	minerals
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
			print FILE "\t\t<i".$m3Key." name=\"".$mineral{$m3Key}."\">\n";
			print FILE "\t\t\t<sell_min>".$data->{marketstat}->{type}->{$m3Key}->{sell}->{min}."</sell_min>\n";
			print FILE "\t\t\t<sell_avg>".$data->{marketstat}->{type}->{$m3Key}->{sell}->{avg}."</sell_avg>\n";
			print FILE "\t\t\t<sell_med>".$data->{marketstat}->{type}->{$m3Key}->{sell}->{median}."</sell_med>\n";
			print FILE "\t\t\t<buy_max>".$data->{marketstat}->{type}->{$m3Key}->{buy}->{max}."</buy_max>\n";
			print FILE "\t\t\t<buy_avg>".$data->{marketstat}->{type}->{$m3Key}->{buy}->{avg}."</buy_avg>\n";
			print FILE "\t\t\t<buy_med>".$data->{marketstat}->{type}->{$m3Key}->{buy}->{median}."</buy_med>\n";
			print FILE "\t\t</i".$m3Key.">\n";
			#print $mineral{$m3Key}." min ".$data->{marketstat}->{type}->{$m3Key}->{sell}->{min}."\n";
		}
	}
	elsif($switch eq 1){
		foreach my $m4Key (keys %mineral){
			print FILE "\t\t<i".$m4Key." name=\"".$mineral{$m4Key}."\">\n";
			my $data2 = $tmpxml->XMLin(get($sitepre.$m4Key.$sitepost));
			print FILE "\t\t\t<buy_max>".$data2->{row}->{buy_highest}."</buy_min>\n";
			print FILE "\t\t\t<buy_avg>".$data2->{row}->{buy_avg}."</buy_avg>\n";
			print FILE "\t\t\t<buy_med>".$data2->{row}->{buy_highest5}."</buy_med>\n";
			print FILE "\t\t\t<sell_min>".$data2->{row}->{sell_lowest}."</sell_min>\n";
			print FILE "\t\t\t<sell_avg>".$data2->{row}->{sell_avg}."</sell_avg>\n";
			print FILE "\t\t\t<sell_med>".$data2->{row}->{sell_lowest5}."</sell_med>\n";
			print FILE"\t\t</i".$m4Key.">\n";
		}
	}
	#else die "Really?  You had to cheat to get here.  Invalid SWITCH again\n";
	print FILE "\t</mineral>\n";
	print "Minerals updated\n";
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
			print FILE "\t\t<i".$c3Key." name=\"".$component{$c3Key}."\">\n";
			print FILE "\t\t\t<sell_min>".$data->{marketstat}->{type}->{$c3Key}->{sell}->{min}."</sell_min>\n";
			print FILE "\t\t\t<sell_avg>".$data->{marketstat}->{type}->{$c3Key}->{sell}->{avg}."</sell_avg>\n";
			print FILE "\t\t\t<sell_med>".$data->{marketstat}->{type}->{$c3Key}->{sell}->{median}."</sell_med>\n";
			print FILE "\t\t\t<buy_max>".$data->{marketstat}->{type}->{$c3Key}->{buy}->{max}."</buy_max>\n";
			print FILE "\t\t\t<buy_avg>".$data->{marketstat}->{type}->{$c3Key}->{buy}->{avg}."</buy_avg>\n";
			print FILE "\t\t\t<buy_med>".$data->{marketstat}->{type}->{$c3Key}->{buy}->{median}."</buy_med>\n";
			print FILE "\t\t</i".$c3Key.">\n";
			#print $mineral{$m3Key}." min ".$data->{marketstat}->{type}->{$m3Key}->{sell}->{min}."\n";
		}
	}
	elsif($switch eq 1){
		foreach my $c4Key (keys %component){
			print FILE "\t\t<i".$c4Key." name=\"".$component{$c4Key}."\">\n";
			my $data2 = $tmpxml->XMLin(get($sitepre.$c4Key.$sitepost));
			print FILE "\t\t\t<buy_max>".$data2->{row}->{buy_highest}."</buy_max>\n";
			print FILE "\t\t\t<buy_avg>".$data2->{row}->{buy_avg}."</buy_avg>\n";
			print FILE "\t\t\t<buy_med>".$data2->{row}->{buy_highest5}."</buy_med>\n";
			print FILE "\t\t\t<sell_min>".$data2->{row}->{sell_lowest}."</sell_min>\n";
			print FILE "\t\t\t<sell_avg>".$data2->{row}->{sell_avg}."</sell_avg>\n";
			print FILE "\t\t\t<sell_med>".$data2->{row}->{sell_lowest5}."</sell_med>\n";
			print FILE"\t\t</i".$c4Key.">\n";
		}
	}
	#else die "Really?  You had to cheat to get here.  Invalid SWITCH again\n";
	print FILE "\t</component>\n";
	print "Components Updated\n";
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
			print FILE "\t\t<i".$d3Key." name=\"".$datacore{$d3Key}."\">\n";
			print FILE "\t\t\t<sell_min>".$data->{marketstat}->{type}->{$d3Key}->{sell}->{min}."</sell_min>\n";
			print FILE "\t\t\t<sell_avg>".$data->{marketstat}->{type}->{$d3Key}->{sell}->{avg}."</sell_avg>\n";
			print FILE "\t\t\t<sell_med>".$data->{marketstat}->{type}->{$d3Key}->{sell}->{median}."</sell_med>\n";
			print FILE "\t\t\t<buy_max>".$data->{marketstat}->{type}->{$d3Key}->{buy}->{max}."</buy_max>\n";
			print FILE "\t\t\t<buy_avg>".$data->{marketstat}->{type}->{$d3Key}->{buy}->{avg}."</buy_avg>\n";
			print FILE "\t\t\t<buy_med>".$data->{marketstat}->{type}->{$d3Key}->{buy}->{median}."</buy_med>\n";
			print FILE "\t\t</i".$d3Key.">\n";
			#print $mineral{$m3Key}." min ".$data->{marketstat}->{type}->{$m3Key}->{sell}->{min}."\n";
		}
	}
	elsif($switch eq 1){
		foreach my $d4Key (keys %datacore){
			print FILE "\t\t<i".$d4Key." name=\"".$datacore{$d4Key}."\">\n";
			my $data2 = $tmpxml->XMLin(get($sitepre.$d4Key.$sitepost));
			print FILE "\t\t\t<buy_max>".$data2->{row}->{buy_highest}."</buy_max>\n";
			print FILE "\t\t\t<buy_avg>".$data2->{row}->{buy_avg}."</buy_avg>\n";
			print FILE "\t\t\t<buy_med>".$data2->{row}->{buy_highest5}."</buy_med>\n";
			print FILE "\t\t\t<sell_min>".$data2->{row}->{sell_lowest}."</sell_min>\n";
			print FILE "\t\t\t<sell_avg>".$data2->{row}->{sell_avg}."</sell_avg>\n";
			print FILE "\t\t\t<sell_med>".$data2->{row}->{sell_lowest5}."</sell_med>\n";
			print FILE"\t\t</i".$d4Key.">\n";
		}
	}
	#else die "Really?  You had to cheat to get here.  Invalid SWITCH again\n";
	print FILE "\t</datacore>\n";
	print "Datacores Updated\n";
};

##################################################
#
#	PI
#
##################################################
sub PIs{
	print FILE "\t<PI>\n";
	my $stuffstring;
	
	if ($switch eq 0){
		##Default case (EVE-CENTRAL)
		$stuffstring="";
		foreach my $p1Key (keys %PI){
			$stuffstring= $stuffstring."typeid=".$p1Key."&";
		}
		
	}
		
	elsif ($switch eq 1){##Case for marketeer
		$stuffstring="";
		foreach my $p2Key (keys %PI){
			$stuffstring= $stuffstring.$p2Key."_";
		}
		chop $stuffstring;
	}
	#else die "How did you end up here.  Invalid SWITCH\n";
		
	#print $stuffstring."\n";
	
	my $tmpxml = new XML::Simple;
	my $url = $sitepre.$stuffstring.$sitepost;

	my $data = $tmpxml->XMLin(get($url));
	

	
	if ($switch eq 0){
		foreach my $p3Key (keys %PI){
			print FILE "\t\t<i".$p3Key." name=\"".$PI{$p3Key}."\">\n";
			print FILE "\t\t\t<sell_min>".$data->{marketstat}->{type}->{$p3Key}->{sell}->{min}."</sell_min>\n";
			print FILE "\t\t\t<sell_avg>".$data->{marketstat}->{type}->{$p3Key}->{sell}->{avg}."</sell_avg>\n";
			print FILE "\t\t\t<sell_med>".$data->{marketstat}->{type}->{$p3Key}->{sell}->{median}."</sell_med>\n";
			print FILE "\t\t\t<buy_max>".$data->{marketstat}->{type}->{$p3Key}->{buy}->{max}."</buy_max>\n";
			print FILE "\t\t\t<buy_avg>".$data->{marketstat}->{type}->{$p3Key}->{buy}->{avg}."</buy_avg>\n";
			print FILE "\t\t\t<buy_med>".$data->{marketstat}->{type}->{$p3Key}->{buy}->{median}."</buy_med>\n";
			print FILE "\t\t</i".$p3Key.">\n";
			#print $mineral{$m3Key}." min ".$data->{marketstat}->{type}->{$m3Key}->{sell}->{min}."\n";
		}
	}
	elsif($switch eq 1){
		foreach my $p4Key (keys %PI){
			print FILE "\t\t<i".$p4Key." name=\"".$PI{$p4Key}."\">\n";
			my $data2 = $tmpxml->XMLin(get($sitepre.$p4Key.$sitepost));
			print FILE "\t\t\t<buy_max>".$data2->{row}->{buy_highest}."</buy_max>\n";
			print FILE "\t\t\t<buy_avg>".$data2->{row}->{buy_avg}."</buy_avg>\n";
			print FILE "\t\t\t<buy_med>".$data2->{row}->{buy_highest5}."</buy_med>\n";
			print FILE "\t\t\t<sell_min>".$data2->{row}->{sell_lowest}."</sell_min>\n";
			print FILE "\t\t\t<sell_avg>".$data2->{row}->{sell_avg}."</sell_avg>\n";
			print FILE "\t\t\t<sell_med>".$data2->{row}->{sell_lowest5}."</sell_med>\n";
			print FILE"\t\t</i".$p4Key.">\n";
		}
	}
	#else die "Really?  You had to cheat to get here.  Invalid SWITCH again\n";
	print FILE "\t</PI>\n";
	print "PI's Updated\n";

};

##################################################
#
#	secondaries
#
##################################################
sub secondaries{
	print FILE "\t<intermediate>\n";
	my $stuffstring;
	
	if ($switch eq 0){
		##Default case (EVE-CENTRAL)
		$stuffstring="";
		foreach my $s1Key (keys %secondary){
			$stuffstring= $stuffstring."typeid=".$s1Key."&";
		}
		
	}
		
	elsif ($switch eq 1){##Case for marketeer
		$stuffstring="";
		foreach my $s2Key (keys %secondary){
			$stuffstring= $stuffstring.$s2Key."_";
		}
		chop $stuffstring;
	}
	#else die "How did you end up here.  Invalid SWITCH\n";
		
	#print $stuffstring."\n";
	
	my $tmpxml = new XML::Simple;
	my $url = $sitepre.$stuffstring.$sitepost;

	my $data = $tmpxml->XMLin(get($url));
	

	
	if ($switch eq 0){
		foreach my $s3Key (keys %secondary){
			print FILE "\t\t<i".$s3Key." name=\"".$secondary{$s3Key}."\">\n";
			print FILE "\t\t\t<sell_min>".$data->{marketstat}->{type}->{$s3Key}->{sell}->{min}."</sell_min>\n";
			print FILE "\t\t\t<sell_avg>".$data->{marketstat}->{type}->{$s3Key}->{sell}->{avg}."</sell_avg>\n";
			print FILE "\t\t\t<sell_med>".$data->{marketstat}->{type}->{$s3Key}->{sell}->{median}."</sell_med>\n";
			print FILE "\t\t\t<buy_max>".$data->{marketstat}->{type}->{$s3Key}->{buy}->{max}."</buy_max>\n";
			print FILE "\t\t\t<buy_avg>".$data->{marketstat}->{type}->{$s3Key}->{buy}->{avg}."</buy_avg>\n";
			print FILE "\t\t\t<buy_med>".$data->{marketstat}->{type}->{$s3Key}->{buy}->{median}."</buy_med>\n";
			print FILE "\t\t</i".$s3Key.">\n";
			#print $mineral{$m3Key}." min ".$data->{marketstat}->{type}->{$m3Key}->{sell}->{min}."\n";
		}
	}
	elsif($switch eq 1){
		foreach my $s4Key (keys %secondary){
			print FILE "\t\t<i".$s4Key." name=\"".$secondary{$s4Key}."\">\n";
			my $data2 = $tmpxml->XMLin(get($sitepre.$s4Key.$sitepost));
			print FILE "\t\t\t<buy_max>".$data2->{row}->{buy_highest}."</buy_max>\n";
			print FILE "\t\t\t<buy_avg>".$data2->{row}->{buy_avg}."</buy_avg>\n";
			print FILE "\t\t\t<buy_med>".$data2->{row}->{buy_highest5}."</buy_med>\n";
			print FILE "\t\t\t<sell_min>".$data2->{row}->{sell_lowest}."</sell_min>\n";
			print FILE "\t\t\t<sell_avg>".$data2->{row}->{sell_avg}."</sell_avg>\n";
			print FILE "\t\t\t<sell_med>".$data2->{row}->{sell_lowest5}."</sell_med>\n";
			print FILE"\t\t</i".$s4Key.">\n";
		}
	}
	#else die "Really?  You had to cheat to get here.  Invalid SWITCH again\n";
	print FILE "\t</intermediate>\n";
	print "Intermediate prices updated\n";
};

##################################################
#
#	moongoos
#
##################################################
sub moongoos{
	print FILE "\t<moongoo>\n";
	my $stuffstring;
	
	if ($switch eq 0){
		##Default case (EVE-CENTRAL)
		$stuffstring="";
		foreach my $g1Key (keys %moongoo){
			$stuffstring= $stuffstring."typeid=".$g1Key."&";
		}
		
	}
		
	elsif ($switch eq 1){##Case for marketeer
		$stuffstring="";
		foreach my $g2Key (keys %moongoo){
			$stuffstring= $stuffstring.$g2Key."_";
		}
		chop $stuffstring;
	}
	#else die "How did you end up here.  Invalid SWITCH\n";
		
	#print $stuffstring."\n";
	
	my $tmpxml = new XML::Simple;
	my $url = $sitepre.$stuffstring.$sitepost;

	my $data = $tmpxml->XMLin(get($url));
	

	
	if ($switch eq 0){
		foreach my $g3Key (keys %moongoo){
			print FILE "\t\t<i".$g3Key." name=\"".$moongoo{$g3Key}."\">\n";
			print FILE "\t\t\t<sell_min>".$data->{marketstat}->{type}->{$g3Key}->{sell}->{min}."</sell_min>\n";
			print FILE "\t\t\t<sell_avg>".$data->{marketstat}->{type}->{$g3Key}->{sell}->{avg}."</sell_avg>\n";
			print FILE "\t\t\t<sell_med>".$data->{marketstat}->{type}->{$g3Key}->{sell}->{median}."</sell_med>\n";
			print FILE "\t\t\t<buy_max>".$data->{marketstat}->{type}->{$g3Key}->{buy}->{max}."</buy_max>\n";
			print FILE "\t\t\t<buy_avg>".$data->{marketstat}->{type}->{$g3Key}->{buy}->{avg}."</buy_avg>\n";
			print FILE "\t\t\t<buy_med>".$data->{marketstat}->{type}->{$g3Key}->{buy}->{median}."</buy_med>\n";
			print FILE "\t\t</i".$g3Key.">\n";
			#print $mineral{$m3Key}." min ".$data->{marketstat}->{type}->{$m3Key}->{sell}->{min}."\n";
		}
	}
	elsif($switch eq 1){
		foreach my $g4Key (keys %moongoo){
			print FILE "\t\t<i".$g4Key." name=\"".$moongoo{$g4Key}."\">\n";
			my $data2 = $tmpxml->XMLin(get($sitepre.$g4Key.$sitepost));
			print FILE "\t\t\t<buy_max>".$data2->{row}->{buy_highest}."</buy_max>\n";
			print FILE "\t\t\t<buy_avg>".$data2->{row}->{buy_avg}."</buy_avg>\n";
			print FILE "\t\t\t<buy_med>".$data2->{row}->{buy_highest5}."</buy_med>\n";
			print FILE "\t\t\t<sell_min>".$data2->{row}->{sell_lowest}."</sell_min>\n";
			print FILE "\t\t\t<sell_avg>".$data2->{row}->{sell_avg}."</sell_avg>\n";
			print FILE "\t\t\t<sell_med>".$data2->{row}->{sell_lowest5}."</sell_med>\n";
			print FILE"\t\t</i".$g4Key.">\n";
		}
	}
	#else die "Really?  You had to cheat to get here.  Invalid SWITCH again\n";
	print FILE "\t</moongoo>\n";
	print "Raw goo prices updated\n";
};