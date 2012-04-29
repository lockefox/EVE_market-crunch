#C:/strawberry/

#/mu/bin/perl -w

#D:\Perl\bin\perl

#use lib '/strawberry/site/lib';
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

my $RAM; #All RAM Cost the same (if exists $ramID{ID}; $quant * $RAM)
my %ramID=(
	"i11476", "Ammo Tech",
	"i11475", "Armor/Hull",
	"i11483", "Electronics",
	"i11482", "Energy",
	"i11481", "Robotics",
	"i11484", "Shield",
	"i11478", "Starship",
	"i11486", "Weapon",
);

my %capital; #Capital raw materials
my %Products; #List of product ID's and prices to build

my $outfile = "results";
my @timedata = localtime(time);
my $week = floor($timedata[7]/7+1);
$outfile = $outfile."_W".$week.".xml";
#open (OUTFILE, '>', $outfile);

my $path = `pwd`;
chomp $path;
my $costsheet = $path."/price.xml";#local or internet address
my $pricekey= "sell_min";#switchable
#my $outfile = "report.xml";

my $priceXML = new XML::Simple;
my $pricesheet = $priceXML->XMLin($costsheet);


my $componentXML = new XML::Simple;
my $componentsheet = $componentXML->XMLin($path."/component.xml");

my $t1XML = new XML::Simple;
my $t1sheet = $t1XML->XMLin($path."/t1.xml");

my $prodXML = new XML::Simple;
my $prodsheet = $prodXML->XMLin($path."/manufacture.xml");

my $tstart=time;
&RawCrunch;
&CompCrunch;
my $setupT=time;
print "\nSub-component setup time: ".($tstart-$setupT)."\n";

&prodCalc;
my $costT=time;

print "\nProducts calculated: ".($tstart-$costT)."\n";

&printer;

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
			
			$rawprice{$iproduct} = $pricesheet->{$matType}->{$iproduct}->{$pricekey};
			$names{$iproduct} = $pricesheet->{$matType}->{$iproduct}->{name};
		}
	}
	print "Raw Materials Loaded\n";
};

sub CompCrunch{ #Loads %comp, %capital, and sets $RAM

	foreach my $typeKey (keys %{$componentsheet->{component}}){
		foreach my $typeKey2 (keys %{$componentsheet->{component}->{$typeKey}}){
			
			$comp{$typeKey2}=0;
			$names{$typeKey2}=$componentsheet->{component}->{$typeKey}->{$typeKey2}->{name};
			
			foreach my $gooKey (keys %{$componentsheet->{component}->{$typeKey}->{$typeKey2}}){
				if ($gooKey =~ m/\s*i[0-9]/){#if i### use for component calc
															
					$comp{$typeKey2}= $comp{$typeKey2}+($componentsheet->{component}->{$typeKey}->{$typeKey2}->{$gooKey}->{content})*($rawprice{$gooKey});
				}
			}
		}
	}
	
	print "Component prices calculated\n";
	
	foreach my $typeKey2 (keys %{$componentsheet->{capital}}){
		
		$capital{$typeKey2}=0;
		$names{$typeKey2}=$componentsheet->{capital}->{$typeKey2}->{name};

		foreach my $Cpart (keys %{$componentsheet->{capital}->{$typeKey2}}){
			if ($Cpart =~ m/\s*i[0-9]/){
				
				$capital{$typeKey2}+= $componentsheet->{capital}->{$typeKey2}->{$Cpart}->{content} * $rawprice{$Cpart};
			}
		}
	}
	
	print "Capital component prices calculated\n";
	$RAM=0;
	foreach my $Rpart (keys %{$componentsheet->{RAM}->{RAM}}){
	
		
		if ($Rpart =~ m/\s*i[0-9]/){
			$RAM += ($componentsheet->{RAM}->{RAM}->{$Rpart}->{content} * $rawprice{$Rpart});
		}
	}
	print "RAM prices  calculated\n";
	foreach my $Rkeys (keys %{$componentsheet->{RAM}}){
		if ($Rkeys eq "RAM"){
			next;
		}
		$names{$Rkeys}= $componentsheet->{RAM}->{$Rkeys}->{name};
	}
};

sub T1{
	my @data = @_;
	my $nick=$data[0];
	my $id="i".$data[1];
	my $type = $data[2];
	my $group= $data[3];
	
	my $price = 0;
	
	foreach my $parts (keys %{$t1sheet->{$type}->{$group}->{$id}}){
		$price += $rawprice{$parts}* $t1sheet->{$type}->{$group}->{$id}->{$parts}->{content};
	}
	
	return $price;
}

sub prodCalc{
	foreach my $class (keys %{$prodsheet}){
		if ($class eq "capitals"){
			foreach my $type (keys %{$prodsheet->{$class}}){
				foreach my $ship (keys %{$prodsheet->{$class}->{$type}}){
					$names{$ship}=$prodsheet->{$class}->{$type}->{$ship}->{name};					
					my $price=0;
					foreach my $parts (keys %{$prodsheet->{$class}->{$type}->{$ship}}){
						if (exists $capital{$parts}){
							$price += $capital{$parts} * $prodsheet->{$class}->{$type}->{$ship}->{$parts}->{content};
						}
					}
					$Products{$ship}=$price;
				}
			}
		}
		elsif ($class eq "T2"){
			foreach my $type (keys %{$prodsheet->{$class}}){
				foreach my $item (keys %{$prodsheet->{$class}->{$type}}){
					$names{$item}=$prodsheet->{$class}->{$type}->{$item}->{name};
					#print $names{$item}.":\n";
					
					my $price=0;
					my $qty;
					my $validflag =0;
					foreach my $parts (keys %{$prodsheet->{$class}->{$type}->{$item}}){
						#if ($validflag eq 1){
						#	next;
						#}
						#if ($prodsheet->{$class}->{$type}->{$item}->{$parts}->{content} eq "NULL"){
						#	$validflag =1;
						#	print "Empty\n";
						#	next;
						#}
						if (exists $rawprice{$parts}){
							
							$price += $rawprice{$parts} * $prodsheet->{$class}->{$type}->{$item}->{$parts}->{content};
							#print "\t".$names{$parts}."x".$prodsheet->{$class}->{$type}->{$item}->{$parts}->{content}.":".$rawprice{$parts}."\n";
						}
						if (exists $comp{$parts}){
							
							$price += $comp{$parts} * $prodsheet->{$class}->{$type}->{$item}->{$parts}->{content};
							#print "\t".$names{$parts}."x".$prodsheet->{$class}->{$type}->{$item}->{$parts}->{content}.":".$comp{$parts}."\n";
						}
						if (exists $ramID{$parts}){
							
							$price += $RAM * $prodsheet->{$class}->{$type}->{$item}->{$parts}->{content};
							#print "\tRAMx".$prodsheet->{$class}->{$type}->{$item}->{$parts}->{content}."x".$RAM."\n";
						}
						if ($parts =~ /[A-Z]/){
							my $flag = $prodsheet->{$class}->{$type}->{$item}->{flag};
							my $group= $prodsheet->{$class}->{$type}->{$item}->{mfg_grp};
							my $id = "i".$prodsheet->{$class}->{$type}->{$item}->{$parts}->{id};
							$names{$id}=$prodsheet->{$class}->{$type}->{$item}->{$parts}->{name};
							my $modprice=0;
							#print $flag."->".$group."->".$id."?";
							foreach my $T1 (keys %{$t1sheet->{$flag}->{$group}->{$id}}){
								if (exists $rawprice{$T1}){
									$modprice += $rawprice{$T1} * $t1sheet->{$flag}->{$group}->{$id}->{$T1}->{content};
								}
								elsif($T1 eq "NULL"){
									next;
								}
							}
							#print "\tT1,".$modprice."\n";
							$price += $modprice * $prodsheet->{$class}->{$type}->{$item}->{$parts}->{content};
						}
						if ($parts eq "qty"){
							$qty=$prodsheet->{$class}->{$type}->{$item}->{qty};
						}
					}
					if ($validflag eq 0){
						$Products{$item}=$price/$qty;
						#print $Products{$item}."\n";
					}
				}
			}
		}
	}
};

sub printer {
	#open my $tmpfile, '>:encoding(iso-8859-1)', $outfile or die "open{$path): $!";
	my $writeout = new IO::File (">$outfile");
	
	my $writer = new XML::Writer ( DATA_MODE => 'true', DATA_INDENT => 2, OUTPUT => $writeout);
	
	$writer->xmlDecl( 'UTF-8' );
	
	$writer->startTag('root');
	foreach my $prodkey (keys %Products){
		$writer->startTag( $prodkey, 'name'=>$names{$prodkey} );
		$writer->startTag('build_cost');
		$writer->characters ( $Products{$prodkey});
		$writer->endTag();
		$writer->endTag();
	}
	$writer->endTag();
	$writer -> end();
};