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

my %staff; 
my %names;

my %kits;	#$kits{$inventor}{itemID}=quantity

my $joblist="producers.xml";
my $matlist="manufacture.xml";

