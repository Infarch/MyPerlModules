use strict;
use warnings;

#use Error ':try';
use WWW::Mechanize;

use SimpleConfig;



my @proxy_list;




load_proxy($constants{General}{Proxy_List}, \@proxy_list);

my $mech = prepare_connection(shift @proxy_list);

do_query($mech, $constants{General}{Query});

my $site_found = open_site($mech, $constants{General}{Look_Url});

if($site_found){
	debug('Do walk...');
	do_walk($mech, $constants{Walk});
}


exit;


# ***************************************************

sub load_proxy {
	my ($listname, $listref) = @_;
	
	open (LL, $listname) or die "Cannot load proxy list from $listname";
	while( <LL> ){
		chomp;
		push (@$listref, $_) if /\S/;
	}
	close LL;
	debug('Loaded proxies: '.scalar @$listref);
}

sub do_walk {
	my ($mech, $list_ref) = @_;
	my @walk_list = @$list_ref;
	
	foreach my $item (@walk_list){
		safe_get($mech, $item);
		debug("Walked to $item");
	}

}

sub open_site {
	my ($mech, $look_url) = @_;
	
	my $site_link;
	my $page_link;
	
	while(!defined ($site_link = $mech->find_link(url_regex=>qr/^$look_url/))){
		debug('No site, check next page');
		last unless defined ($page_link = $mech->find_link(id=>'next_page'));
		safe_get($mech, $page_link);
		debug('Fetched next page');
	}
	
	if(defined $site_link){
		debug("Found requested site");
		safe_get($mech, $site_link);
		debug("The requested site was fetched");
		return 1;
	} else {
		debug("Not found requested site");
		return 0;
	}

}

sub do_query {
	my ($mech, $query) = @_;
	
	# remove spaces from query
	$query =~ s/\s+/+/g;
	
	safe_get($mech, "http://yandex.ua/yandsearch?text=$query");
}

sub prepare_connection {
	my $proxy = shift;
	
	# instantiate Machanize class
	my $mech = WWW::Mechanize->new(autocheck=>0);
	
	# set up proxy
	$mech->proxy('http', "http://$proxy") if $proxy;
	
	# set up agent alias
	my @aliases = $mech->known_agent_aliases();
	my $alias_number = int( rand( scalar @aliases ) );
	$mech->agent_alias( $aliases[$alias_number] );

	# set reasonable timeout value
	$mech->timeout(20);
		
	return $mech;
	
}

sub safe_get {
	my ($mech, $url) = @_;
	
	my $count = 0;
	my $success;
	
	do {
		$mech->get($url);
		debug($mech->status());
		$success = $mech->success();
		debug("Network error: ".$mech->status()) unless $success;
	} while (!$success && ($count++ < 3));
	
	unless ($success){
		die "Cannot fetch content";
		
	}
}

sub debug {
	print "Debug: $_[0]\n";
}