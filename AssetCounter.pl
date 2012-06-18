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

#####	APIs	#####

my $char_ID = 285; #Locke's account key
my $char_VCODE = "fm9UZdCrnM5x7C2x1v7zocPHSahscVMOVasV9AcJoUx1UojLxEWAD5EZi1Rl0mDK";
my $charid = 628592330;	#Lockefox

my $AHM_ID=863121;
my $AHM_VCODE= "SYWn7mz9KINz4dYBlHsdZ4mSeeDctH8XZilUcwzhelKegdVJujLfOBajYEIhyBS0";

my $corp_ID = 579145;
my $corp_VCODE = "VRLLgjaTD4TASFdmrTsx9szx3ymiAHo0hJprwym7oKjQOWBjVDa86qPrBBw7nVpw";
my $corpid = 1894214152;

#####	Website Handles   #####
my $evesite = "http://api.eveonline.com/";
my $cAssets = "corp/AssetList.xml.aspx?";

my $shoplist = "kits.xml";


##### 	Location Handles   #####
my %systems = (
	30000142,"Jita",
	30005310,"Scheenins",
	30002659,"Dodixie",
	30005297,"Ouelletta",
);

my %offices = (			  #Region	#Const	#System	 #Station
	"Scheenins - Roden", (10000068,20000777,30005310,60010342),
	"Scheenins - Chemal", (10000068,20000777,30005310,60010837),
	"Jita - CNA 4-4", (10000002,20000020,30000142,60003760),
	"Ouelletta - Cap Yard", (10000068,20000777,30005297,60014704),
);

my %POSs = (
	474778269,"CM - Ship Prod 1",
	496440073,"CM - Ship Prod 2",
	1005317554579,"CL4 - OFFLINE",
	1005361236760,"CL - Copy Room",
	1005361245083,"CL - Prod 1",
	1005373369913,"CL - Prod 2",
	
);

my %inSpace = (
	1005460976811,"Comp Lab I",
	1005461024680,"Comp Lab II",
	1005461074031,"Comp Lab III",
	1005461047619,"Comp Lab IV",
);

my %skip = (
	16216,"Moblie Lab",	#Mobile Laboratory
	13780,"Equipment Assembly";
	16213,"CL Tower",
	24654,"Med Ship Array",
	28351,"Adv Lab",
	20061,"CM Tower",
	24660,"Component Array",
	17185,"EXP array",
	17184,"KIN array",
	17187,"EM array",
	17186,"THRM array",
	24659,"Drone array",
	
);
###FLAGS
#	62=delivery?
#	116=
#	120=production
#	119=
#	121=Directors
#	ID=27<--office

#####	XML Objects   #####

#my $cAPI_Assets = new XML::Simple;
#my $AssetList = $cAPI_Assets->XMLin(get($evesite.$cAssets."vCode=".$corp_VCODE."&charID=".$charid."&keyID=".$corp_ID));
my $cAPI_Assets = new XML::Simple;
my $AssetList = $cAPI_Assets->XMLin("AssetList.xml");

my $local_Shopping = new XML::Simple;
my $ShoppingList = $local_Shopping->XMLin($shoplist);

#####	Globals   #####
my %datacore;
my %mineral;
my %component;
my %goo;
my %PI;
my %T1;	#NEED TO FIX T1 ID reporting in shopping list
my %names;

##################################################
#
#	MAIN
#
##################################################

&globalLoader;


##################################################
#
#	GlobalLoader
#
##################################################
sub globalLoader{

	#print Dumper($ShoppingList->{Shopping}->{Component});
	foreach my $compKey (keys %{$ShoppingList->{Shopping}->{Component}}){
		$names{$ShoppingList->{Shopping}->{Component}->{$compKey}->{id}}=$compKey;
		$component{$ShoppingList->{Shopping}->{Component}->{$compKey}->{id}}=$ShoppingList->{Shopping}->{Component}->{$compKey}->{content};
	}
	foreach my $dcKey (keys %{$ShoppingList->{Shopping}->{Datacore}}){
		$names{$ShoppingList->{Shopping}->{Datacore}->{$dcKey}->{id}}=$dcKey;
		$datacore{$ShoppingList->{Shopping}->{Datacore}->{$dcKey}->{id}}=$ShoppingList->{Shopping}->{Datacore}->{$dcKey}->{content};
	}
	foreach my $gooKey (keys %{$ShoppingList->{Shopping}->{goo}}){
		$names{$ShoppingList->{Shopping}->{goo}->{$gooKey}->{id}}=$gooKey;
		$goo{$ShoppingList->{Shopping}->{goo}->{$gooKey}->{id}}=$ShoppingList->{Shopping}->{goo}->{$gooKey}->{content};
	}
	foreach my $minKey (keys %{$ShoppingList->{Shopping}->{Mineral}}){
		$names{$ShoppingList->{Shopping}->{Mineral}->{$minKey}->{id}}=$minKey;
		$mineral{$ShoppingList->{Shopping}->{Mineral}->{$minKey}->{id}}=$ShoppingList->{Shopping}->{Mineral}->{$minKey}->{content};
	}
	foreach my $PIKey (keys %{$ShoppingList->{Shopping}->{PI}}){
		$names{$ShoppingList->{Shopping}->{PI}->{$PIKey}->{id}}=$PIKey;
		$PI{$ShoppingList->{Shopping}->{PI}->{$PIKey}->{id}}=$ShoppingList->{Shopping}->{PI}->{$PIKey}->{content};
	}
}