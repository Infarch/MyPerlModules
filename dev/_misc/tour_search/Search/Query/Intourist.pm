package Search::Query::Intourist;

use strict;
use warnings;

use base qw(Search::Query::_base);


use HTML::TreeBuilder::XPath;


#our $field_config = {
#	
#	city => {
#		mapTo => 'cmbCityFrom',
#		extraFields => {action2 => chgCity},
#		submit => 1,
#	},
#	
#};

# constructor
sub new {
  my $check = shift;
  my $class = ref($check) || $check;

  my %params  = (
  	country_value => undef,
  	region_value => undef,
  	
	  @_ # init
  );
  
  return $class->SUPER::new(%params);
}

# override superclass method
sub beforeSetFormField {
	my ($self, $key, $value) = @_;
	if( ($key eq 'country') || ($key eq 'region') ){
		# this site use country and region settings as a single value
		if($key eq 'country'){
			$self->{country_value} = $value;
		} elsif($key eq 'region'){
			$self->{region_value} = $value;
		}
		
		if($self->{country_value} && $self->{region_value}){
			$self->directSetFormField('country', "$self->{country_value} - $self->{region_value}");
		}
		
		return undef;

	}
	
	return $value;
}

sub beforeQuery {
	my ($self) = @_;
	$self->{virtual_form}->{action2} = 'doPrice';
	$self->{virtual_form}->{cmbHROrder} = -1
		unless exists $self->{virtual_form}->{cmbHROrder};
}


# data extraction methods
sub parseDataItem {
	#die "Abstract function was called";
}

sub parsePage {
	my ($self) = @_;
	
	my $tree = HTML::TreeBuilder::XPath->new;
	$tree->parse_content($self->{content});
	
	# first we are looking for the 'next page' url
	
	
	# get nodes
	my $clause = q{/html/body/table/tr[3]/td/table[4]/tr/td/table/tr[position()>1]};
	my @nodes = $tree->findnodes($clause);
	
	return \@nodes;
}




1;
