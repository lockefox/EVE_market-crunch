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
use POSIX;
use IO;
use lib "/lib";

my %employee;	#Holds staff ID/Name
my %names;	#Holds item ID/Name
my %subset;

### NOTE ###
#
#	Add $subset{$id}="subgroup" hash builder
#	Should increase speed significantly
#
#	What to do about Capital building?
#	if !(exists $subset{$id}) must be cap?
#############

my %kits;	#$kits{$inventor}{itemID}=quantity
my %shopping;	#all materials needed to produce
#	$shopping{subgroup}{name}=qty

my %ramid=(
	"i11476", "Ammo Tech",
	"i11475", "Armor/Hull",
	"i11483", "Electronics",
	"i11482", "Energy",
	"i11481", "Robotics",
	"i11484", "Shield",
	"i11478", "Starship",
	"i11486", "Weapon",
);

my $joblist="producers.xml";
my $matlist="manufacture.xml";
my $complist="component.xml";

my $shoppinglist=1;

my $T1list="t1.xml";

my $t1list="t1.xml";

my $outfile="kits.xml";

my $staffpage = new XML::Simple;
my $staff = $staffpage->XMLin($joblist);

my $matspage = new XML::Simple;
my $mats = $matspage->XMLin($matlist);

#&loadKits;	#BROKEN
&loader;
&quickKits;

&shopping;

&printer;

my (
	%comp,
	%goo,
	%min,
	%PI,
	%DC,
);

sub commify {

        local $_  = shift;
        1 while s/^(-?\d+)(\d{3})/$1,$2/;
        return $_;

};
sub loader {
	###COMPONENT###
	my $comppage = new XML::Simple;
	my $comps = $comppage->XMLin($complist);
	
	foreach my $class (keys %{$comps->{component}}){
		foreach my $prod (keys %{$comps->{component}->{$class}}){
			if ($prod eq "name"){
				next;
			}
			$comp{$prod}=$comps->{component}->{$class}->{$prod}->{name};
		}
	}
	
	%min=(
		"i11399", "Morphite",
		"i37", "Isogen",
		"i40", "Megacyte",
		"i36", "Mexallon",
		"i38", "Nocxium",
		"i35", "Pyerite",
		"i34", "Tritanium",
		"i39", "Zydrine",
	);

	%PI=(
		"i3689", "Mechanical Parts",
		"i9842", "Miniature Electronics",
		"i9834", "Guidance System",
		"i9848", "Robotics",
		"i9830", "Rocket Fuel",
		"i9838", "Super Conductors",
		"i9840", "Transmitter",
		"i3828", "Construction Blocks",
		"i3685", "Hydrogen Batteries",
		"i3687", "Electronic Parts",
	);

	%DC=(
		"i20417", "Datacore - Electromagnetic Physics",
		"i20418", "Datacore - Electronic Engineering",
		"i20419", "Datacore - Graviton Physics",
		"i20411", "Datacore - High Energy Physics",
		"i20171", "Datacore - Hydromagnetic Physics",
		"i20413", "Datacore - Laser Physics",
		"i20424", "Datacore - Mechanical Engineering",
		"i20415", "Datacore - Molecular Engineering",
		"i20416", "Datacore - Nanite Engineering",
		"i20423", "Datacore - Nuclear Physics",
		"i20412", "Datacore - Plasma Physics",
		"i20414", "Datacore - Quantum Physics",
		"i20420", "Datacore - Rocket Science",
		"i20421", "Datacore - Amarrian Starship Engineering",
		"i25887", "Datacore - Caldari Starship Engineering",
		"i20410", "Datacore - Gallentean Starship Engineering",
		"i20172", "Datacore - Minmatar Starship Engineering",
	);

	%goo=(
		"i16670", "Crystalline Carbonite",
		"i17317", "Fermionic Condensates",
		"i16673", "Fernite Carbide",
		"i16683", "Ferrogel",
		"i16679", "Fullerides",
		"i16682", "Hypersynaptic Fibers",
		"i16681", "Nanotransisotrs",
		"i16680", "Phenolic Composits",
		"i16678", "Sylramic Fibers",
		"i16671", "Titanium Carbonite",
		"i16672", "Tungsten Carbonite",
	);
};
sub loadKits{##using slow search method
	foreach my $workers (keys %{$staff->{staff}}){
		$employee{$workers}=$staff->{staff}->{$workers}->{name};
		#print $employee{$workers}.":";
		
		foreach my $products (keys %{$staff->{staff}->{$workers}}){
			if ($products eq "name"){
				next;
			}
			$names{$products}=$staff->{staff}->{$workers}->{$products}->{name};
			my $qty = $staff->{staff}->{$workers}->{$products}->{content};
			my $mult=0;
			#print " ".$names{$products}."x".$qty;
			foreach my $class(keys %{$mats}){
				if ($class eq "capital"){
					next; #make sub for capital kit (all minerals)
				}
				foreach my $group(keys %{$mats->{$class}}){
					foreach my $itemID(keys %{$mats->{$class}->{$group}}){
						if ($itemID eq $products){
							$names{$itemID}=$mats->{$class}->{$group}->{$itemID}->{name};
							$mult=$mats->{$class}->{$group}->{$itemID}->{qty};
							my $x=$qty/$mult;
							foreach my $parts(keys %{$mats->{$class}->{$group}->{$itemID}}){
								if ($parts =~ /^i/ or $parts =~ /[A-Z]/){
									$names{$parts}=$mats->{$class}->{$group}->{$itemID}->{$parts}->{name};
									if (exists $kits{$workers}{$parts}){
										$kits{$workers}{$parts}+= $mats->{$class}->{$group}->{$itemID}->{$parts}->{content}*$x;
									}
									else{
										$kits{$workers}{$parts}= $mats->{$class}->{$group}->{$itemID}->{$parts}->{content}*$x
									}
								}
							}
						}
					}
				}
			}
			#print Dumper (%kits);
		}
		print "\n";
	}
};

sub quickKits{
	&typeLoader();
	
	foreach my $pilot (keys %{$staff->{staff}}){
		$employee{$pilot}=$staff->{staff}->{$pilot}->{name};
		#print $employee{$pilot}.":";
		my $x=0;
		foreach my $products (keys %{$staff->{staff}->{$pilot}}){
			if ($products eq "name"){
				next;
			}
			$names{$products}=$staff->{staff}->{$pilot}->{$products}->{name};
			my $qty = $staff->{staff}->{$pilot}->{$products}->{content};
			
			my $div = $mats->{T2}->{($subset{$products})}->{$products}->{qty};
			
			$x = $qty/$div;
			#print $names{$products}."x".$x."(".$qty."/".$div.")\n";
			foreach my $parts (keys %{$mats->{T2}->{($subset{$products})}->{$products}}){
				if ($parts eq "bld_time"){
					next;
				}
				if ($parts =~ /i/ or $parts =~ /[A-Z]/){
					$names{$parts}=$mats->{T2}->{($subset{$products})}->{$products}->{$parts}->{name};
					if (exists $kits{$pilot}{$parts}){
						$kits{$pilot}{$parts}+=$mats->{T2}->{($subset{$products})}->{$products}->{$parts}->{content} * $x;
					}
					else{
						$kits{$pilot}{$parts}=$mats->{T2}->{($subset{$products})}->{$products}->{$parts}->{content} * $x;
					}
				}
			}
		}
		#print Dumper(%kits);
	}
	
};

sub typeLoader{
	foreach my $type (keys %{$mats->{T2}}){
		foreach my $item (keys %{$mats->{T2}->{$type}}){
			$subset{$item}=$type;
		}
	}
	#print Dumper(%subset);

};

sub shopping{
	my %component;	#$component{$ID}{$material}=qty;
	%component = &compload();
	#	$shopping{$subgroup}{name}=qty
	my $t1page= new XML::Simple;
	my $t1XML = $t1page->XMLin($T1list);
	

	foreach my $pilots (keys %kits){
		foreach my $materialKeys (keys %{$kits{$pilots}}){
			if ( exists $component{$materialKeys}){
				my $qty = $kits{$pilots}{$materialKeys};
				if (!(exists $shopping{"component"}{($names{$materialKeys})})){
					$shopping{"component"}{($names{$materialKeys})} = $qty;
				}
				else {
					$shopping{"component"}{($names{$materialKeys})} += $qty;
				}

				foreach my $sub1 (keys %{$component{$materialKeys}}){
					
					if (!(exists $shopping{"goo"}{($names{$sub1})})){
						$shopping{"goo"}{($names{$sub1})}=$qty * $component{$materialKeys}{$sub1};
					}
					else{
						$shopping{"goo"}{($names{$sub1})}+=$qty * $component{$materialKeys}{$sub1};
					}
				}
				next;
			}
			if( exists $min{$materialKeys}){
					if (!(exists $shopping{"mineral"}{($names{$materialKeys})})){
						$shopping{"mineral"}{($names{$materialKeys})}=$kits{$pilots}{$materialKeys};
					}
					else{
						$shopping{"mineral"}{($names{$materialKeys})}+=$kits{$pilots}{$materialKeys};
					}
				next;
			}
			if(exists $DC{$materialKeys}){
					if (!(exists $shopping{"datacore"}{($names{$materialKeys})})){
						$shopping{"datacore"}{($names{$materialKeys})}=$kits{$pilots}{$materialKeys};
					}
					else{
						$shopping{"datacore"}{($names{$materialKeys})}+=$kits{$pilots}{$materialKeys};
					}
				next;
			}
			if(exists $PI{$materialKeys}){
					if (!(exists $shopping{"PI"}{($names{$materialKeys})})){
						$shopping{"PI"}{($names{$materialKeys})}=$kits{$pilots}{$materialKeys};
					}
					else{
						$shopping{"PI"}{($names{$materialKeys})}+=$kits{$pilots}{$materialKeys};
					}
				next;
			}
			else{
				if (!(exists $shopping{"other"}{($names{$materialKeys})})){
					$shopping{"other"}{($names{$materialKeys})}=$kits{$pilots}{$materialKeys};
				}
				else{
					$shopping{"other"}{($names{$materialKeys})}+=$kits{$pilots}{$materialKeys};
				}
				next;
			}
		}
	}
	#print Dumper (%shopping);
};

sub compload{
	my %data;	#$data{$ID}{$material}=qty
	
	my $components = new XML::Simple;
	my $compXML = $components->XMLin($complist);
	
	foreach my $type (keys %{$compXML->{component}}){
		foreach my $product(keys %{$compXML->{component}->{$type}}){
					$names{$product}=$compXML->{component}->{$type}->{$product}->{name};
			foreach my $part (keys %{$compXML->{component}->{$type}->{$product}}){
				if ($part =~ /^i/){
					$names{$part}=$compXML->{component}->{$type}->{$product}->{$part}->{name};
					$data{$product}{$part}=$compXML->{component}->{$type}->{$product}->{$part}->{content};
					$shopping{$part}=0;#initialize subcomponent values in shopping
				}
			}
		}
	}
	
	return %data;
}

sub printer{
	my $writeout = new IO::File (">$outfile");
	
	my $writer = new XML::Writer ( DATA_MODE => 'true', DATA_INDENT => 2, OUTPUT => $writeout);
	
	$writer->xmlDecl( 'UTF-8' );
	
	$writer->startTag('root');
	
	foreach my $people (keys %{$staff->{staff}}){
		$writer->startTag ("inventor", 'id'=>$people, 'name'=>$employee{$people});
		my %subMin;
		my %subComp;
		my %subDC;
		my %subPI;
		my %subGoo;
		my %subOther;
		

	#%comp,
	#%goo,
	#%min,
	#%PI,
	#%DC,

		foreach my $parts (keys %{$kits{$people}}){
			if (exists $comp{$parts}){	#Component
				$subComp{$names{$parts}}= $parts;
			}
			elsif(exists $goo{$parts}){	#Advanced material
				$subGoo{$names{$parts}}= $parts;
			}	
			elsif(exists $min{$parts}){	#Mineral
				$subMin{$names{$parts}}= $parts;
			}
			elsif(exists $PI{$parts}){	#trade good
				$subPI{$names{$parts}}= $parts;
			}
			elsif(exists $DC{$parts}){	#Datacore
				$subDC{$names{$parts}}= $parts;
			}
			else{	#T1, etc
				print $parts."\n";
				$subOther{$names{$parts}}=$parts;
			}
		}
		
		foreach my $kComp (sort keys %subComp){
			my $id1;
			(undef, $id1)=split('i', $subComp{$kComp});
			$writer->startTag("component", 'name'=>$names{$subComp{$kComp}}, 'id'=>$id1);
			$writer->characters(&commify($kits{$people}{$subComp{$kComp}}));
			$writer->endTag();
		}
		foreach my $kGoo(sort keys %subGoo){
			my $id2;
			(undef, $id2)=split('i', $subGoo{$kGoo});
			$writer->startTag("moongoo", 'name'=>$names{$subGoo{$kGoo}}, 'id'=>$id2);
			$writer->characters(&commify($kits{$people}{$subGoo{$kGoo}}));
			$writer->endTag();
		}
		foreach my $kMin(sort keys %subMin){
			my $id3;
			(undef, $id3)=split('i', $subMin{$kMin});
			$writer->startTag("mineral", 'name'=>$names{$subMin{$kMin}}, 'id'=>$id3);
			$writer->characters(&commify($kits{$people}{$subMin{$kMin}}));
			$writer->endTag();
		}
		foreach my $kPI(sort keys %subPI){
			my $id4;
			(undef, $id4)=split('i', $subPI{$kPI});
			$writer->startTag("PI", 'name'=>$names{$subPI{$kPI}}, 'id'=>$id4);
			$writer->characters(&commify($kits{$people}{$subPI{$kPI}}));
			$writer->endTag();
		}
		foreach my $kDC(sort keys %subDC){
			my $id5;
			(undef, $id5)=split('i', $subDC{$kDC});
			$writer->startTag("datacore", 'name'=>$names{$subDC{$kDC}}, 'id'=>$id5);
			$writer->characters(&commify($kits{$people}{$subDC{$kDC}}));
			$writer->endTag();
		}
		foreach my $kOther(sort keys %subOther){
			my $id6;
			(undef, $id6)=split('i', $subOther{$kOther});
			$writer->startTag("other", 'name'=>$names{$subOther{$kOther}}, 'id'=>$id6);
			$writer->characters(&commify($kits{$people}{$subOther{$kOther}}));
			$writer->endTag();
		}
		$writer->endTag();
		#$writer->startTag($parts, 'name'=>$names{$parts});
		#$writer->characters ($kits{$people}{$parts});
		#$writer->endTag();
		#$writer->endTag();
	}
	if ($shoppinglist eq 1){
		$writer->startTag("Shopping");
		#$writer->startTag("mineral");
			foreach my $compKey (sort keys %{$shopping{"component"}}){
				$writer->startTag("Component", 'name'=>$compKey);
				$writer->characters(&commify($shopping{"component"}{$compKey}));
				$writer->endTag;
			}
			foreach my $gooKey (sort keys %{$shopping{"goo"}}){
				$writer->startTag("goo", 'name'=>$gooKey);
				$writer->characters(&commify($shopping{"goo"}{$gooKey}));
				$writer->endTag;
			}
			foreach my $dcKey (sort keys %{$shopping{"datacore"}}){
				$writer->startTag("Datacore", 'name'=>$dcKey);
				$writer->characters(&commify($shopping{"datacore"}{$dcKey}));
				$writer->endTag;
			}
			foreach my $minKey (sort keys %{$shopping{"mineral"}}){
				$writer->startTag("Mineral", 'name'=>$minKey);
				$writer->characters(&commify($shopping{"mineral"}{$minKey}));
				$writer->endTag;
			}
			foreach my $PIKey (sort keys %{$shopping{"PI"}}){
				$writer->startTag("PI", 'name'=>$PIKey);
				$writer->characters(&commify($shopping{"PI"}{$PIKey}));
				$writer->endTag;
			}
			foreach my $OKey (sort keys %{$shopping{"other"}}){
				$writer->startTag("Other", 'name'=>$OKey);
				$writer->characters(&commify($shopping{"other"}{$OKey}));
				$writer->endTag;
			}
		$writer->endTag();
	}
	$writer->endTag();
	$writer->end();
};

