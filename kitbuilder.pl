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

my $staffpage = new XML::Simple;
my $staff = $staffpage->XMLin($joblist);

my $matspage = new XML::Simple;
my $mats = $matspage->XMLin($matlist);

#&loadKits;	#BROKEN

&quickKits;

sub loadKits{##using slow search method
	foreach my $workers (keys %{$staff}){
		print $workers;
		$employee{$workers}=$staff->{$workers}->{name};
		foreach my $items (keys %{$staff->{$workers}}){
			my $mult=0;
			my $q=$staff->{$workers}->{$items}->{content};
			$names{$items}={$workers}->{$items}->{name};
			if ($items eq "name"){
				next;
			}
			foreach my $class (keys %{$mats}){
				foreach my $type (keys %{$mats->{$class}}){
					foreach my $itemID (keys %{$mats->{$class}->{$type}}){
						if ($itemID eq $items){
							$mult=$q/($mats->{$class}->{$type}->{$itemID}->{qty});
							
							foreach my $parts (keys %{$mats->{$class}->{$type}->{$itemID}}){
								if ($parts =~ /i/ or $parts =~ /[A-Z]/){
									$names{$parts}=$mats->{$class}->{$type}->{$itemID}->{$parts}->{name};
									if (!(exists $kits{$workers}{$parts})){
										$kits{$workers}{$parts}=$mats->{$class}->{$type}->{$itemID}->{$parts}->{content} * $mult;
									}
									else{
										$kits{$workers}{$parts}+=$mats->{$class}->{$type}->{$itemID}->{$parts}->{content} * $mult;
									}
								}
							}
						}
					}
				}
			}
		}
	}
	print Dumper{%kits};
};

sub quickKits{
	&typeLoader();
	
	foreach my $pilot (keys %{$staff}){
		print $pilot;
		$employee{$pilot}=$staff->{$pilot}->{name};
		foreach my $produce (keys %{$staff->{$pilot}}){
			if ($produce eq "name"){
				next;
			}
			
			$names{$produce}=$mats->{T2}->{($subset{$produce})}->{$produce}->{qty};
			my $mult = ($staff->{$pilot}->{$produce}->{content})/($mats->{T2}->{($subset{$produce})}->{$produce}->{qty});
			foreach my $parts (keys %{$mats->{T2}->{($subset{$produce})}->{$produce}}){
				if ($parts =~ /i/ or $parts =~ /[A-Z]/){
					if (exists $kits{$pilot}{$produce}{$parts}){
						$kits{$pilot}{$produce}{$parts} += $mats->{T2}->{($subset{$produce})}->{$produce}->{$parts}->{content} * $mult;
					}
					else{
						$kits{$pilot}{$produce}{$parts} = $mats->{T2}->{($subset{$produce})}->{$produce}->{$parts}->{content} * $mult;
					}
					$names{$parts}=$mats->{T2}->{($subset{$produce})}->{$produce}->{$parts}->{name};
				}

			}
		}
	}
};

sub typeLoader{
	foreach my $type (keys %{$mats->{T2}}){
		foreach my $item (keys %{$mats->{T2}->{$type}}){
			$subset{$item}=$type;
		}
	}

};

