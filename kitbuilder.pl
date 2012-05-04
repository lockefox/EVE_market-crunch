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
my %shopping;	#all materials needed to produce	$shopping{id}=qty;

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
my $T1list="t1.xml";
my $outfile="kits.xml";

my $staffpage = new XML::Simple;
my $staff = $staffpage->XMLin($joblist);

my $matspage = new XML::Simple;
my $mats = $matspage->XMLin($matlist);

#&loadKits;	#BROKEN

&quickKits;

&shopping;

#&printer;

sub loadKits{##using slow search method
	foreach my $workers (keys %{$staff->{staff}}){
		$employee{$workers}=$staff->{staff}->{$workers}->{name};
		print $employee{$workers}.":";
		
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
		print $employee{$pilot}.":";
		my $x=0;
		foreach my $products (keys %{$staff->{staff}->{$pilot}}){
			if ($products eq "name"){
				next;
			}
			$names{$products}=$staff->{staff}->{$pilot}->{$products}->{name};
			my $qty = $staff->{staff}->{$pilot}->{$products}->{content};
			
			my $div = $mats->{T2}->{($subset{$products})}->{$products}->{qty};
			
			$x = $qty/$div;
			print $names{$products}."x".$x."(".$qty."/".$div.")\n";
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
	
	my $t1page= new XML::Simple;
	my $t1XML = $t1page->XMLin($T1list);
	
	foreach my $member (keys %{$staff->{staff}}){
		foreach my $tobuild (keys %{$staff->{staff}->{$member}}){
			if ($tobuild eq "name"){
				next;
			}
			my $qty = $staff->{staff}->{$member}->{$tobuild}->{content};
			my $div = $mats->{T2}->{($subset{$tobuild})}->{$tobuild}->{qty};
			
			my $x= $qty/$div;
			foreach my $materials(keys %{$mats->{T2}->{($subset{$tobuild})}->{$tobuild}}){
				if ($materials =~/^i/ or $materials =~ /[A-Z]/){
					my $mult = $mats->{T2}->{($subset{$tobuild})}->{$tobuild}->{$materials}->{content};
					if (!(exists $shopping{$materials})){
						$shopping{$materials}=0;	#Initializes entry
					}
					
					if ($materials =~ /[A-Z]/){		#T1
							my $grp = $subset{$tobuild};
							if ($grp eq "ships"){
								my $sub = $mats->{T2}->{($subset{$tobuild})}->{$tobuild}->{mfg_grp};
								
								foreach my $mins (keys %{$t1XML->{ship}->{$sub}->{$materials}}){
									if ($mins eq "name" or $mins eq "id"){
										next;
									}
									$shopping{$materials}+= $t1XML->{ship}->{$sub}->{$materials}->{$mins}->{content} * $mult *$x;
								}
							}
							else{
								foreach my $mins (keys %{$t1XML->{module}->{$grp}->{$materials}}){
									if ($mins eq "name" or $mins eq "id"){
										next;
									}
									
									$shopping{$materials}+=$t1XML->{module}->{$grp}->{$materials}->{$mins}->{content} * $mult *$x;
								}
							}
					}
					if ($materials =~ /^i/){	#regular materials
						if (exists $component{$materials}){ #component
							foreach my $subcomp (keys %{$component{$materials}}){
								$shopping{$subcomp}+=$component{$materials}{$subcomp} * $mult * $x;
							}
						}
		
						elsif (exists $ramid{$materials}){	#RAM
							#my $y = ceil($x*$mult);	#Round up, for whole numbers
							#$shopping{"i37"} += 74*$y;	#Isogen
							#$shopping{"i36"} += 200*$y;	#Mexallon
							#$shopping{"i38"} += 32*$y;	#Nocxium
							#$shopping{"i35"} += 400*$y; #Pyerite
							#$shopping{"i34"} += 500*$y;	#Tritanium
						}
						else{								#PI, Datacores, minerals
							$shopping{$materials}+= $x * $mult;
						}
					}
				}
			}
		}
	}
	print Dumper (%shopping);
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
		$writer->startTag ($people, 'name'=>$employee{$people});
		foreach my $parts (keys %{$kits{$people}}){
			$writer->startTag($parts, 'name'=>$names{$parts});
			$writer->characters ($kits{$people}{$parts});
			$writer->endTag();
		}
		$writer->endTag();
	}
	$writer->endTag();
	$writer->end();
};

