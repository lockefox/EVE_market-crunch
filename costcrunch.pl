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

my %names;
##Saves ID name
## name{ID}="string"

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

my $tstart=time;
&RawCrunch;
&CompCrunch;
my $setupT=time;
print "\nSub-component setup time: ".($tstart-$setupT)."\n";


sub RawCrunch{ #Loads %rawprice	
	my %skipString=(
		"source", 0,
		"fresh",0,
	);
		
	foreach my $matType (keys %{$pricesheet}){
		if (exists $skipString{$matType} ){
			next;
		}
		my $product;
		foreach my $iproduct (keys %{$pricesheet->{$matType}}){
			(undef, $product) = split ('i', $iproduct);
			
			$rawprice{$product} = $pricesheet->{$matType}->{$iproduct}->{$pricekey};
			$names{$product} = $pricesheet->{$matType}->{$iproduct}->{name};
		}
	}
	print "Raw Materials Loaded\n";
};

sub CompCrunch{ #Loads %comp, %capital, and sets $RAM
	my $itemid;
	my $compid;
	foreach my $typeKey (keys %{$componentsheet->{component}}){
		foreach my $compKey (keys %{$componentsheet->{component}->{$typeKey}}){
			(undef, $itemid)=split('i', $compKey);
			$comp{$itemid}=0;
			$names{$itemid}=$componentsheet->{component}->{$typeKey}->{$compKey}->{name};
			
			foreach my $gooKey (keys %{$componentsheet->{component}->{$typeKey}->{$compKey}}){
				if ($gooKey =~ m/\s*i[0-9]/){#if i### use for component calc
					(undef, $compid)=split('i', $gooKey);
										
					$comp{$itemid}= $comp{$itemid}+($componentsheet->{component}->{$typeKey}->{$compKey}->{$gooKey}->{content})*($rawprice{$compid});
				}
			}
		}
	}
	
	print "Component prices calculated\n";
	
	foreach my $typeKey2 (keys %{$componentsheet->{capital}}){
		(undef, $itemid) = split ('i', $typeKey2);
		$capital{$itemid}=0;
		$names{$itemid}=$componentsheet->{capital}->{$typeKey2}->{name};

		foreach my $Cpart (keys %{$componentsheet->{capital}->{$typeKey2}}){
			if ($Cpart =~ m/\s*i[0-9]/){
				(undef, $compid)=split('i', $Cpart);
				$capital{$itemid}+= $componentsheet->{capital}->{$typeKey2}->{$Cpart}->{content} * $rawprice{$compid};
				
			}
		}
	}
	
	print "Capital component prices calculated\n";
	
	foreach my $Rpart (keys %{$componentsheet->{RAM}->{RAM}}){
		$RAM=0;
		my $Rmin;
		if ($Rpart =~ m/\s*i[0-9]/){
			(undef, $Rmin) = split ('i', $Rpart);
			$RAM += $componentsheet->{RAM}->{RAM}->{$Rpart}->{content} * $rawprice{$Rmin};
		}
	}
	
	print "RAM prices  calculated\n";
};