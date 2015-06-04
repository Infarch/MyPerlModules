package DB_Page;


use strict;
use warnings;

use threads;
use threads::shared;

use base qw(DB_Prototype);
use DB_LiveUser;

use HTML::TreeBuilder::XPath;
use HTTP::Request;
use HTTP::Response;



sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my $columns = {
  	ID        => { Type => $ISoft::DB::TYPE_INT,     Updated => 0, Value => undef, PrimaryKey => 1 },
  	URL       => { Type => $ISoft::DB::TYPE_VARCHAR, Updated => 0, Value => undef },
  	Status    => { Type => $ISoft::DB::TYPE_INT,     Updated => 0, Value => undef },
  	Errors    => { Type => $ISoft::DB::TYPE_INT,     Updated => 0, Value => undef },
  };

  return $class->SUPER::new(@_, tablename  => 'Page', Columns => $columns);
  
}

sub URL       { return $_[0]->_getset('URL', $_[1]); }
sub Status    { return $_[0]->_getset('Status', $_[1]); }
sub Errors    { return $_[0]->_getset('Errors', $_[1]); }


sub getRequest {
	my $self = shift;
	return new HTTP::Request('GET', $self->URL);
}

sub processResponse {
	my ($self, $dbh, $response) = @_;
	
	my $cnt = $response->decoded_content();

	my $tree = HTML::TreeBuilder::XPath->new;
	$tree->parse_content($cnt);
	
	my @nodes = $tree->findnodes( q{//table[@class='s-list rate-list']/tbody/tr/td[@class='s-list-desc']/span[@class='ljuser ljuser-name_']} );
	my $count = 0;
	foreach my $node(@nodes){
		my $nick = $node->findvalue( q{./@lj:user} );
		my $url = $node->findvalue( q{./a[2]/@href} );
		next if $url !~ /\.livejournal\.com\//;
		$count++;
		
		my $user_obj = DB_LiveUser->new;
		$user_obj->URL($url);
		$user_obj->Nick($nick);
		$user_obj->Status($user_obj->STATUS_NEW);
		$user_obj->insert($dbh);
	}


	$tree->delete();
	
	print $self->URL(), ": $count\n";
	
	
	
	
	$self->Status(__PACKAGE__->STATUS_DONE);
	$self->update($dbh);
	

}


1;
