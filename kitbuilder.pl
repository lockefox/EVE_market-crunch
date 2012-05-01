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

my $joblist="producers.xml";
my $matlist="manufacture.xml";
my $outfile="kits.xml";

my $staffpage = new XML::Simple;
my $staff = $staffpage->XMLin($joblist);

my $matspage = new XML::Simple;
my $mats = $matspage->XMLin($matlist);

#&loadKits;	#BROKEN

&quickKits;

&printer;

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
								if ($parts =~ /i/ or $parts =~ /[A-Z]/){
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
		foreach my $products (keys %{$staff->{staff}->{$pilot}}){
			if ($products eq "name"){
				next;
			}
			
			$names{$products}=$staff->{staff}->{$pilot}->{$products}->{name};
			my $qty = $staff->{staff}->{$pilot}->{$products}->{content};
			
			my $div = $mats->{T2}->{($subset{$products})}->{$products}->{qty};
			
			my $x = $qty/$div;
			print $names{$products}."x".$x."\n";
			foreach my $parts (keys %{$mats->{T2}->{($subset{$products})}->{$products}}){
				if ($parts eq "bld_time"){
					next;
				}
				if ($parts =~ /i/ or $parts =~ /[A-Z]/){
					$names{$parts}=$mats->{T2}->{($subset{$products})}->{$products}->{$parts}->{name};
					#print $names{$parts}."x".
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

