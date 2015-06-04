package Upholstery;

use strict;
use warnings;

use UpholsteryColor;

use base qw(ISoft::DB ISoft::ClassExtender);

sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my %params  = (
	  tablename => 'Upholstery',
	  namecolumn => 'Name',
	  @_
  );
  
  $params{Columns} = {
  	ID   => { Type => $ISoft::DB::TYPE_INT, NotNull => 1, PrimaryKey => 1 },
  	Name => { Type => $ISoft::DB::TYPE_VARCHAR, Length => 250, NotNull => 1, Unique => 1 },
  	URL  => { Type => $ISoft::DB::TYPE_VARCHAR, Length => 500, NotNull => 1 },
  };
  
  my $self = bless(\%params, $class);
  
  return $self;
}

sub getColors {
	my($self, $dbh, $limit)= @_;
	
	my $color = UpholsteryColor->new();
	$color->set("Upholstery_ID", $self->ID);
	$color->maxReturn($limit) if $limit;
	
	return $color->listSelect($dbh);
}

sub getAlias {
	my $self = shift;
	if($self->{alias}){
		return $self->{alias};
	}
	my $url = $self->get("URL");
	
	if($url =~ /.+\/(.+)/){
		return "materialy_upholstery-$1";
	}else{
		die "bad url $url";
	}
}


1;
