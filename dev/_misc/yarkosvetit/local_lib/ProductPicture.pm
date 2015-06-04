package ProductPicture;

use strict;
use warnings;


# base class
use base qw(ISoft::ParseEngine::Member::File::ProductPicture);


sub new {
  my $check = shift;
  my $class = ref($check) || $check;
  
  my %params  = (
  	storage => 'd:/pfiles/yarkosvetit/productpictures',
  );
  
  my $self = $class->SUPER::new(%params, @_);

  return $self;
}

#sub getExceptionWeight {
#	my($self, $exception) = @_;
#	if(my $name = ref $exception){
#		if($name eq 'ISoft::Exception::NetworkError'){
#			my $url = $self->get('URL');
#			if($url =~ /\/img\/x\//i){
#				print "X url skipped\n";
#				return 20;
#			}
#		}
#	}
#	return return $self->SUPER::getExceptionWeight($exception);
#}


1;
