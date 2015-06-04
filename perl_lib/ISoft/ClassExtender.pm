package ISoft::ClassExtender;

# provides several useful class methods

use strict;
use warnings;

use Error ':try';

use ISoft::Exception::ScriptError;




sub _getset {
	my ($self, $field, $new_val) = @_;
	unless (exists $self->{$field}){
		throw ISoft::Exception::ScriptError(message=>"No field $field");
	}
	my $old_val = $self->{$field};
	$self->{$field} = $new_val if defined $new_val;
	return $old_val;
}

1;
