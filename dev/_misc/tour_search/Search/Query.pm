package Search::Query;

# exports a function get_search_engine

use base qw(Exporter);

our @EXPORT;

BEGIN {
	@EXPORT = qw( get_search_engine );
}


sub get_search_engine {
	my $config = shift;
	
	my $service_name = $config->{service};
	
	my $pkg = $service_name;
	$pkg =~ s/::/\//g;
	
	require "$pkg.pm";
	
	return $service_name->new(config=>$config);

}




1;
