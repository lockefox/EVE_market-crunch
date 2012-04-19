#!/mu/bin/perl -w

#D:\Perl\bin\perl

use strict;
use warnings;
use HTTP::Request::Common qw(POST);
use XML::Simple;
use Time::Local;
use Data::Dumper;
use LWP::Simple;
use CGI;


##########
#
#	Globals
#
##########
my %rawprice;#raw material prices
## ID{rawprice}=cost
## Minerals, Datacores, PI, Raw components

my %comp; #Component hash
## ID{comp}=cost

my $RAM; #All RAM Cost the same (if exists %ramID; $quant * $RAM)
my %ramID=(
	11476, "Ammo Tech",
	11475, "Armor/Hull",
	11483, "Electronics",
	11482, "Energy",
	11481, "Robotics",
	11484, "Shield",
	11478, "Starship",
	11486, "Weapon",
);

my %capital; #Capital raw materials

my $path = `pwd`;
chomp $path;
my $costsheet = $path."/price.xml";#local or internet address
my $pricekey= "sell_min";#switchable
my $outfile = "report.xml";

my $priceXML = new XML::Simple;
my $pricesheet = $priceXML->XMLin($costsheet);


my $componentXML = new XML::Simple;
my $componentsheet = $componentXML->XMLin($path."/component.xml");

#my $t1XML = new XML::Simple;
#my $t1sheet = $t1XML->XMLin($path."/t1.xml");
#
#my $prodXML = new XML::Simple;
#my $prodsheet = $prodXML->XMLin($path."/manufacture.xml");


&RawCrunch;
&CompCrunch;

sub RawCrunch{ #Loads %rawprice
	#{Hash initializers
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
	#}
	
	foreach my $raw1Key (keys %component){
		my $itemID="i".$raw1Key;
		$rawprice{$raw1Key}= $pricesheet->{component}->{$itemID}->{$pricekey};
	}
	
	foreach my $raw2Key (keys %mineral){
		my $itemID="i".$raw2Key;
		$rawprice{$raw2Key}= $pricesheet->{mineral}->{$itemID}->{$pricekey};
	}
	
	foreach my $raw3Key (keys %datacore){
		my $itemID="i".$raw3Key;
		$rawprice{$raw3Key}= $pricesheet->{datacore}->{$itemID}->{$pricekey};
	}
	
	#foreach my $raw4Key (keys %PI){
	#	$rawprice{$raw4Key}= $pricesheet->{PI}->{$raw4Key}->{$pricekey};
	#}
	
};

sub CompCrunch{ #Loads %comp, %capital, and sets $RAM
	my $itemid;
	my $compid;
	foreach my $typeKey (keys %{$componentsheet->{component}}){
		foreach my $compKey (keys %{$componentsheet->{component}->{$typeKey}}){
			(undef, $itemid)=split('i', $compKey);
			$comp{$itemid}=0;
			print $componentsheet->{component}->{$typeKey}->{$compKey}->{name}." ";
			foreach my $gooKey (keys %{$componentsheet->{component}->{$typeKey}->{$compKey}}){
				if ($gooKey =~ m/\s*i[0-9]/){#if i### use for component calc
					(undef, $compid)=split('i', $gooKey);
					#$compid=$gooKey;
					
					#print $compid."x".$componentsheet->{component}->{$typeKey}->{$compKey}->{$gooKey}->{content}." ";
					$comp{$itemid}= $comp{$itemid}+($componentsheet->{component}->{$typeKey}->{$compKey}->{$gooKey}->{content})*($rawprice{$compid});
					#print $gooKey."x".$componentsheet->{component}->{$typeKey}->{$compKey}->{$gooKey}->{content}." ";
				}
			}
			print "cost:".$comp{$itemid};
			print "\n"
			#print "key:".$itemid." price:".$comp{$itemid}."\n";
			
		}
	}
	
	foreach my $typeKey2 (keys %{$componentsheet->{capcomponent}}){
		foreach my $elementKey (keys %{$componentsheet->{capcomponent}->{$typeKey2}}){
			(undef, $itemid) = split ('i', $elementKey);
			$capital{$itemid}=0;
			foreach my $minKey (keys %{$componentsheet->{capcomponent}->{$typeKey2}->{$elementKey}}){
				
			}
		}
	}
};