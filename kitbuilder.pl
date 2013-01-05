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
#use lib "/lib";

my %employee;	#Holds staff ID/Name
my %names;	#Holds item ID/Name
my %subset;
my %cap_subset;

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

my %capitalParts=(
	"i21017", "Capital Armor Plates",
	"i21019", "Capital Capacitor Battery",
	"i21027", "Capital Cargo Bay",
	"i24547", "Capital Clone Vat Bay",
	"i21035", "Capital Computer System",
	"i21037", "Capital Construction Parts",
	"i24560", "Capital Corporate Hangar Bay",
	"i24556", "Capital Doomsday Weapon Mount",
	"i21029", "Capital Drone Bay",
	"i24545", "Capital Jump Bridge Array",
	"i21025", "Capital Jump Drive",
	"i21041", "Capital Launcher Hardpoint",
	"i21021", "Capital Power Generator",
	"i21009", "Capital Propulsion Engine",
	"i21013", "Capital Sensor Cluster",
	"i21023", "Capital Shield Emitter",
	"i24558", "Capital Ship Maintenance Bay",
	"i21039", "Capital Siege Array",
	"i21011", "Capital Turret Hardpoint",
);
#	$capitalParts{id}{material}=qty

##################################################
#
#	GLOBAL Switches
#
##################################################

my $commas = 1;		#Comify output (default off)
my $shoppinglist=1;	#Add sum of all products (default off`)
my $doT1=1;			#Add T1 minerals to shopping list output (default off)
my $doRAM=1;		#Add RAM minerals to shopping list output (default off)
my $doSplit=1;		#Separate T1/T2/RAM minerals from eachother (default off)

my $joblist="producers.xml";
my $matlist="manufacture.xml";
my $complist="component.xml";

my $T1list="t1.xml";

my $t1list="t1.xml";

my $outfile="kits.xml";

##################################################
#
#	MAIN
#
##################################################

my $staffpage = new XML::Simple;
my $staff = $staffpage->XMLin($joblist);

my $matspage = new XML::Simple;
my $mats = $matspage->XMLin($matlist);

my $t1page = new XML::Simple;
my $T1s = $t1page->XMLin($T1list);

my $comppage = new XML::Simple;
my $comps = $comppage->XMLin($complist);

my $components = new XML::Simple;
my $compXML = $components->XMLin($complist);

&parseargs;
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
	%RAM,
	%T1,
);


sub commify {
	#if ($commas eq 1) {
        local $_  = shift;
        1 while s/^(-?\d+)(\d{3})/$1,$2/;
        return $_;
	#}
	#else{
	#	 local $_  = shift;
	#	 return $_;
	#}

};
sub loader {
	###COMPONENT###

	
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
	
	%RAM=(
		"RAM", "Generic Ram",
		"i11476", "R.A.M.- Ammunition Tech",
		"i11475", "R.A.M.- Armor/Hull Tech",
		"i11483", "R.A.M.- Electronics",
		"i11482", "R.A.M.- Energy Tech",
		"i11481", "R.A.M.- Robotics",
		"i11484", "R.A.M.- Shield Tech",
		"i11478", "R.A.M.- Starship Tech",
		"i11486", "R.A.M.- Weapon Tech",
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
			print Dumper (%kits);
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
			
			my $div=1;
			#print $names{$products}."x".$x."(".$qty."/".$div.")\n";
			if (exists $cap_subset{$products}){
				#print "capital case\n";
				#CAPITAL CASE
				$div=1;
				foreach my $cap_parts (keys %{$mats->{capitals}->{$cap_subset{$products}}->{$products}}){
					if ($cap_parts =~ /^i/){
						#print $cap_parts.":".$mats->{capitals}->{($cap_subset{$products})}->{$products}->{$cap_parts}->{content}."\n";

						$names{$cap_parts}=$mats->{capitals}->{($cap_subset{$products})}->{$products}->{$cap_parts}->{name};
							#Load capital components to kit-list
						if (exists $kits{$pilot}{$cap_parts}){
							$kits{$pilot}{$cap_parts}+=$mats->{capitals}->{($cap_subset{$products})}->{$products}->{$cap_parts}->{content} * $qty;
						}
						else{
							$kits{$pilot}{$cap_parts}=$mats->{capitals}->{($cap_subset{$products})}->{$products}->{$cap_parts}->{content} * $qty;
						}
					}
				}
				
			}
			else{
				$div = $mats->{T2}->{($subset{$products})}->{$products}->{qty};
			
				$x = $qty/$div;
			
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
						if($parts =~ /[A-Z]/){
							$T1{$parts}[0]="i".$mats->{T2}->{($subset{$products})}->{$products}->{$parts}->{id};
							$T1{$parts}[1]=$subset{$products};
							$T1{$parts}[2]=$mats->{T2}->{($subset{$products})}->{$products}->{flag};
							print $parts."=".$T1{$parts}[0].":".$T1{$parts}[1].":".$T1{$parts}[2]."\n";
						}
					}
				}
			}
			print Dumper(%kits);
		}
		#print Dumper(%kits);
		#print Dumper(%T1);
	}
	
};

sub typeLoader{
	foreach my $type (keys %{$mats->{T2}}){
		foreach my $item (keys %{$mats->{T2}->{$type}}){
			$subset{$item}=$type;
		}
	}
	foreach my $cap_type (keys %{$mats->{capitals}}){
		foreach my $cap_ship (keys %{$mats->{capitals}->{$cap_type}}){
			$cap_subset{$cap_ship}=$cap_type;
		}
	}
	#print Dumper(%cap_subset);

};

sub shopping{
	my %component;	#$component{$ID}{$material}=qty;
	%component = &compload();
	#	$shopping{$subgroup}{name}=qty
	my $t1page= new XML::Simple;
	my $t1XML = $t1page->XMLin($T1list);
	
	my %rambuild = (
		"i37", 74,		#Isogen
		"i36", 200,		#Mexallon
		"i38", 32,		#Nocxium
		"i35", 400,		#Pyerite
		"i34", 500,		#Tritanium
		);
	my %T1Keys = (
		"i37",0,
		"i40",0,
		"i36",0,
		"i38",0,
		"i35",0,
		"i34",0,
		"i39",0,
	);
	
	

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
			if (exists $capitalParts{$materialKeys}){
				my $qty = $kits{$pilots}{$materialKeys};
				if (!(exists $shopping{"cap_parts"}{($names{$materialKeys})})){
					$shopping{"cap_parts"}{($names{$materialKeys})} = $kits{$pilots}{$materialKeys};
				}
				else {
					$shopping{"cap_parts"}{($names{$materialKeys})} += $kits{$pilots}{$materialKeys};
				}
				#print $materialKeys.":".$capitalParts{$materialKeys}."\n";
				foreach my $sub1 (keys %{$compXML->{capital}->{$materialKeys}}){
						##Add capital minerals to total mineral count##
					if($sub1 =~/^i/){
						if (!(exists $names{$sub1})){
							$names{$sub1}=$compXML->{capital}->{$materialKeys}->{$sub1}->{name};
						}
						#print "\t".$names{$sub1}.":".$qty*($compXML->{capital}->{$materialKeys}->{$sub1}->{content})."\n";
						if (!(exists $shopping{"mineral"}{($names{$sub1})})){
							$shopping{"mineral"}{($names{$sub1})}=$qty*($compXML->{capital}->{$materialKeys}->{$sub1}->{content});
						}
						else{
							$shopping{"mineral"}{($names{$sub1})}+=$qty*($compXML->{capital}->{$materialKeys}->{$sub1}->{content});
						}
							##Print capital minerals to own subset##
						if (!(exists $shopping{"capital"}{($names{$sub1})})){
							$shopping{"capital"}{($names{$sub1})}=$qty*($compXML->{capital}->{$materialKeys}->{$sub1}->{content});
						}
						else{
							$shopping{"capital"}{($names{$sub1})}+=$qty*($compXML->{capital}->{$materialKeys}->{$sub1}->{content});
						}
					}
				}
				next;
			}
			if( exists $min{$materialKeys}){
				if ($doSplit eq 1){
					if (!(exists $shopping{"T2"}{($names{$materialKeys})})){
						$shopping{"T2"}{($names{$materialKeys})}=$kits{$pilots}{$materialKeys};
					}
					else{
						$shopping{"T2"}{($names{$materialKeys})}+=$kits{$pilots}{$materialKeys};
					}
					if (!(exists $shopping{"mineral"}{($names{$materialKeys})})){
						$shopping{"mineral"}{($names{$materialKeys})}=$kits{$pilots}{$materialKeys};
					}
					else{
						$shopping{"mineral"}{($names{$materialKeys})}+=$kits{$pilots}{$materialKeys};
					}
				}
				else{
					if (!(exists $shopping{"mineral"}{($names{$materialKeys})})){
						$shopping{"mineral"}{($names{$materialKeys})}=$kits{$pilots}{$materialKeys};
					}
					else{
						$shopping{"mineral"}{($names{$materialKeys})}+=$kits{$pilots}{$materialKeys};
					}
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
				if ($doT1 eq 1){

					if ($materialKeys =~ /[A-Z]/){	#####T1 has caps key
						#print $materialKeys.":\n";
						my $mQty = $kits{$pilots}{$materialKeys};
						#print $T1s->{$T1{$materialKeys}[2]}->{$T1{$materialKeys}[1]}->{$T1{$materialKeys}[0]}->{name}."\n";
						#print Dumper($T1s->{$T1{$materialKeys}[2]}->{$T1{$materialKeys}[1]});#->{$T1{$materialKeys}[0]}
						
						##SHIP CASE
						if ($T1{$materialKeys}[1] eq "ships"){
							#print $T1s->{$T1{$materialKeys}[1]}->{$T1{$materialKeys}[2]}->{$T1{$materialKeys}[0]}->{name}."x".$mQty."\n";
							foreach my $mineralKey (keys %T1Keys){
								#print"\t".$T1s->{$T1{$materialKeys}[1]}->{$T1{$materialKeys}[2]}->{$T1{$materialKeys}[0]}->{$mineralKey}->{content}."x".$mQty."\n";
								if($doSplit eq 1){
									if (!(exists $shopping{"T1"}{($names{$mineralKey})})){
										$shopping{"T1"}{($names{$mineralKey})}=$T1s->{$T1{$materialKeys}[1]}->{$T1{$materialKeys}[2]}->{$T1{$materialKeys}[0]}->{$mineralKey}->{content} * $mQty;
										#print "\t".($T1s->{$T1{$materialKeys}[1]}->{$T1{$materialKeys}[2]}->{$T1{$materialKeys}[0]}->{$mineralKey} * $mQty)->{content}." ".$names{$mineralKey}."\n";
									}
									else{
										$shopping{"T1"}{($names{$mineralKey})}+=$T1s->{$T1{$materialKeys}[1]}->{$T1{$materialKeys}[2]}->{$T1{$materialKeys}[0]}->{$mineralKey}->{content} * $mQty;
										print "\t".($T1s->{$T1{$materialKeys}[1]}->{$T1{$materialKeys}[2]}->{$T1{$materialKeys}[0]}->{$mineralKey}->{content} * $mQty)." ".$names{$mineralKey}."\n";
									}
									if (!(exists $shopping{"mineral"}{($names{$mineralKey})})){
										$shopping{"mineral"}{($names{$mineralKey})}=$T1s->{$T1{$materialKeys}[1]}->{$T1{$materialKeys}[2]}->{$T1{$materialKeys}[0]}->{$mineralKey}->{content} * $mQty;
									}
									else{
										$shopping{"mineral"}{($names{$mineralKey})}+=$T1s->{$T1{$materialKeys}[1]}->{$T1{$materialKeys}[2]}->{$T1{$materialKeys}[0]}->{$mineralKey}->{content} * $mQty;
									}
								}
								else{
									if (!(exists $shopping{"mineral"}{($names{$mineralKey})})){
										$shopping{"mineral"}{($names{$mineralKey})}=$T1s->{$T1{$materialKeys}[1]}->{$T1{$materialKeys}[2]}->{$T1{$materialKeys}[0]}->{$mineralKey}->{content} * $mQty;
									}
									else{
										$shopping{"mineral"}{($names{$mineralKey})}+=$T1s->{$T1{$materialKeys}[1]}->{$T1{$materialKeys}[2]}->{$T1{$materialKeys}[0]}->{$mineralKey}->{content} * $mQty;
									}
								}
							}						
						}
						##MODULE CASE
						else{
							print $T1s->{$T1{$materialKeys}[2]}->{$T1{$materialKeys}[1]}->{$T1{$materialKeys}[0]}->{name}."\n";
							foreach my $mineralKey (keys %T1Keys){
								#print"\t".$T1s->{$T1{$materialKeys}[2]}->{$T1{$materialKeys}[1]}->{$T1{$materialKeys}[0]}->{$mineralKey}->{content}."x".$mQty."\n";
									if($doSplit eq 1){
										if (!(exists $shopping{"T1"}{($names{$mineralKey})})){
											#$shopping{"T1"}{($names{$mineralKey})}=$T1s->{$T1{$materialKeys}[2]}->{$T1{$materialKeys}[1]}->{$T1{$materialKeys}[0]}->{$mineralKey}->{content} * $mQty;
											#print "\t".($T1s->{$T1{$materialKeys}[2]}->{$T1{$materialKeys}[1]}->{$T1{$materialKeys}[0]}->{$mineralKey}->{content} * $mQty)." ".$names{$mineralKey}."\n";
										}
										else{
											$shopping{"T1"}{($names{$mineralKey})}+=$T1s->{$T1{$materialKeys}[2]}->{$T1{$materialKeys}[1]}->{$T1{$materialKeys}[0]}->{$mineralKey}->{content} * $mQty;
											#print "\t".($T1s->{$T1{$materialKeys}[2]}->{$T1{$materialKeys}[1]}->{$T1{$materialKeys}[0]}->{$mineralKey}->{content} * $mQty)." ".$names{$mineralKey}."\n";
										}
										if (!(exists $shopping{"mineral"}{($names{$mineralKey})})){
											$shopping{"mineral"}{($names{$mineralKey})}=$T1s->{$T1{$materialKeys}[2]}->{$T1{$materialKeys}[1]}->{$T1{$materialKeys}[0]}->{$mineralKey}->{content} * $mQty;
										}
										else{
											$shopping{"mineral"}{($names{$mineralKey})}+=$T1s->{$T1{$materialKeys}[2]}->{$T1{$materialKeys}[1]}->{$T1{$materialKeys}[0]}->{$mineralKey}->{content} * $mQty;
										}
									}
									else{
										if (!(exists $shopping{"mineral"}{($names{$mineralKey})})){
											$shopping{"mineral"}{($names{$mineralKey})}=$T1s->{$T1{$materialKeys}[2]}->{$T1{$materialKeys}[1]}->{$T1{$materialKeys}[0]}->{$mineralKey}->{content} * $mQty;
										}
										else{
											$shopping{"mineral"}{($names{$mineralKey})}+=$T1s->{$T1{$materialKeys}[2]}->{$T1{$materialKeys}[1]}->{$T1{$materialKeys}[0]}->{$mineralKey}->{content} * $mQty;
										}
									}
								
							}
						}
					}
				}
				
				if ($doRAM eq 1){
					if (exists $RAM{$materialKeys}){
						if ($doSplit eq 1){
							foreach my $ramkey (keys %rambuild){
								if (!(exists $shopping{"ram"}{($names{$ramkey})})){
									$shopping{"ram"}{($names{$ramkey})}=ceil($kits{$pilots}{$materialKeys})* $rambuild{$ramkey};
								}
								else{
									$shopping{"ram"}{($names{$ramkey})}+=ceil($kits{$pilots}{$materialKeys})* $rambuild{$ramkey}
								}
								if (!(exists $shopping{"mineral"}{($names{$ramkey})})){
									$shopping{"mineral"}{($names{$ramkey})}=ceil($kits{$pilots}{$materialKeys})* $rambuild{$ramkey};
								}
								else{
									$shopping{"mineral"}{($names{$ramkey})}+=ceil($kits{$pilots}{$materialKeys})* $rambuild{$ramkey}
								}

							}
						}
					
						else{
							foreach my $ramkey (keys %rambuild){
								if (!(exists $shopping{"mineral"}{($names{$materialKeys})})){
									$shopping{"mineral"}{($names{$materialKeys})}=ceil($kits{$pilots}{$materialKeys})* $rambuild{$ramkey};
								}
								else{
									$shopping{"mineral"}{($names{$materialKeys})}+=ceil($kits{$pilots}{$materialKeys})* $rambuild{$ramkey}
								}

							}
						}
					}
				}
				
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
	my %rName = reverse %names;
	my $shortID;
	foreach my $people (keys %{$staff->{staff}}){
		$writer->startTag ("inventor", 'id'=>$people, 'name'=>$employee{$people});
		my %subMin;
		my %subComp;
		my %subDC;
		my %subPI;
		my %subGoo;
		my %subOther;
		my %subCapParts;
		my %subCapMins;
	
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
			elsif(exists $capitalParts{$parts}){
				$subCapParts{$capitalParts{$parts}}=$parts;
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
		foreach my $kCap(sort keys %subCapParts){
			my $id6;
			(undef, $id6)=split('i', $subCapParts{$kCap});
			$writer->startTag("cap_parts", 'name'=>$names{$subCapParts{$kCap}}, 'id'=>$id6);
			$writer->characters(&commify($kits{$people}{$subCapParts{$kCap}}));
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
				(undef,$shortID)=split ('i',$rName{$compKey});
				$writer->startTag("Component", 'name'=>$compKey, 'id'=>$shortID);
				$writer->characters(&commify($shopping{"component"}{$compKey}));
				$writer->endTag;
			}
			foreach my $capPartKey (sort keys %{$shopping{"cap_parts"}}){
				(undef,$shortID)=split ('i',$rName{$capPartKey});
				$writer->startTag("cap_parts", 'name'=>$capPartKey, 'id'=>$shortID);
				$writer->characters(&commify($shopping{"cap_parts"}{$capPartKey}));
				$writer->endTag;
			}

			foreach my $gooKey (sort keys %{$shopping{"goo"}}){
				(undef,$shortID)=split ('i',$rName{$gooKey});
				$writer->startTag("goo", 'name'=>$gooKey, 'id'=>$shortID);
				$writer->characters(&commify($shopping{"goo"}{$gooKey}));
				$writer->endTag;
			}
			foreach my $dcKey (sort keys %{$shopping{"datacore"}}){
				(undef,$shortID)=split ('i',$rName{$dcKey});
				$writer->startTag("Datacore", 'name'=>$dcKey, 'id'=>$shortID);
				$writer->characters(&commify($shopping{"datacore"}{$dcKey}));
				$writer->endTag;
			}
			foreach my $minKey (sort keys %{$shopping{"mineral"}}){
				(undef,$shortID)=split ('i',$rName{$minKey});
				$writer->startTag("Mineral", 'name'=>$minKey, 'id'=>$shortID);
				$writer->characters(&commify($shopping{"mineral"}{$minKey}));
				$writer->endTag;
			}
			if ($doSplit eq 1){
				foreach my $T2Key (sort keys %{$shopping{"T2"}}){
					(undef,$shortID)=split ('i',$rName{$T2Key});
					$writer->startTag("T2", 'name'=>$T2Key, 'id'=>$shortID);
					$writer->characters(&commify($shopping{"T2"}{$T2Key}));
					$writer->endTag;
				}
			}
			if ($doT1 eq 1){
				foreach my $T1Key (sort keys %{$shopping{"T1"}}){
					(undef,$shortID)=split ('i',$rName{$T1Key});
					$writer->startTag("T1", 'name'=>$T1Key, 'id'=>$shortID);
					$writer->characters(&commify($shopping{"T1"}{$T1Key}));
					$writer->endTag;
				}
			}
			if ($doRAM eq 1){
				foreach my $RAMKey (sort keys %{$shopping{"ram"}}){
					(undef,$shortID)=split ('i',$rName{$RAMKey});
					$writer->startTag("RAM", 'name'=>$RAMKey, 'id'=>$shortID);
					$writer->characters(&commify($shopping{"ram"}{$RAMKey}));
					$writer->endTag;
				}
			}
			foreach my $capKey (sort keys %{$shopping{"capital"}}){
				(undef,$shortID)=split ('i',$rName{$capKey});
				$writer->startTag("capital", 'name'=>$capKey, 'id'=>$shortID);
				$writer->characters(&commify($shopping{"capital"}{$capKey}));
				$writer->endTag;
			}
			foreach my $PIKey (sort keys %{$shopping{"PI"}}){
				(undef,$shortID)=split ('i',$rName{$PIKey});
				$writer->startTag("PI", 'name'=>$PIKey, 'id'=>$shortID);
				$writer->characters(&commify($shopping{"PI"}{$PIKey}));
				$writer->endTag;
			}
			foreach my $OKey (sort keys %{$shopping{"other"}}){
				(undef,$shortID)=split ('i',$rName{$OKey});
				$writer->startTag("Other", 'name'=>$OKey, 'id'=>$shortID);
				$writer->characters(&commify($shopping{"other"}{$OKey}));
				$writer->endTag;
			}

		$writer->endTag();
	}
	$writer->endTag();
	$writer->end();
};

sub parseargs{
	while (my $args = shift (@ARGV)){
		if ($args =~ /-commas/){		#Comify outputs
			$commas=1;
		}
		elsif ($args =~ /-shopping/){	#Sum of all products shopping list
			$shoppinglist=1;
		}
		elsif ($args =~ /-T1/){			#Add T1 minerals to shopping list
			$doT1=1;
		}
		elsif ($args =~ /-RAM/){
			$doRAM=1;
		}
		elsif ($args =~ /-split/){
			$doSplit=1;
		}
		elsif($args =~ /-jobs=/){		#Change source XML for tasks
			(undef, $joblist) = split (/jobs=/,$args);
		}
		elsif($args =~ /-h/ or $args =~ /-help/){
			&help;
		}
	}
};

sub help{
	print "\nkitbuilder.pl\n";
	
	print "-commas\n";
	print "\tCommify output numbers (to be human-readable)\n";
	print "\tDefault:";
	if ($commas eq 0){
		print " disabled\n";
	}
	else{
		print " enabled\n";
	}
	
	print "\n-shopping\n";
	print "\tAdd sum of all products in kits.  Build a shopping list.\n";
	print "\tDefault:";
	if ($shoppinglist eq 0){
		print " disabled\n";
	}
	else{
		print " enabled\n";
	}
	
	print "\n-T1\n";
	print "\tAdd T1 minerals (from ".$T1list.") to shopping list.\n";
	print "\tFor building T1 modules/ships in-house.  ALL or NONE\n";
	print "\tDoes not separate T1/T2/RAM minerals from eachother.\n";
	print "\tNOTE: Does nothing unless -shopping is also enabled\n";
	print "\tDefault:";
	if ($doT1 eq 0){
		print " disabled\n";
	}
	else{
		print " enabled\n";
	}
	
	print "\n-RAM\n";
	print "\tAdd RAM minerals to shopping list.\n";
	print "\tFor building RAM modules/ships in-house.  ALL or NONE\n";
	print "\tDoes not separate T1/T2/RAM minerals from eachother.\n";
	print "\tNOTE: Does nothing unless -shopping is also enabled\n";
	print "\tDefault:";
	if ($doRAM eq 0){
		print " disabled\n";
	}
	else{
		print " enabled\n";
	}
	
	print "\n-split\n";
	print "\tSplit out the T1/RAM/T2 materials for easier split\n";
	print "\tStill prints total <mineral> counts along with individual subgroups";
	print "\tNOTE: Does nothing unless -shopping is also enabled\n";
	print "\tDefault:";
	
	print "\n-jobs=<jobs list>.xml\n";
	print "\tChange source of jobs list.  \n";
	print "\tDefault:".$joblist."\n";
		
	exit;
}
