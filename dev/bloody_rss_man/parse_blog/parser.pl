use strict;
use warnings;

use Encode qw/encode decode/;
use LWP::UserAgent;

use Implementors;
use SimpleConfig;







# start work

my $agent = LWP::UserAgent->new;


# start parsing
my $start_url = $constants{General}{Url};
$start_url =~ s/\/$//;
my $url = $start_url;
my $page = 2;

my $page_limit = $constants{Debug}{PageLimit} || 0;

# parsed lines
my @collector;

if(!$constants{Debug}{LoremIpsum}){
	while (parse_url($agent, $url, \@collector)){
		
		if($page_limit && $page >= $page_limit){
			print "Limitation applied\n";
			last;
		}
		
		$url = $start_url . '/page/' . $page++;
		# wait a second
		sleep 1;
	}
} else {

@collector = (
'Lorem ipsum dolor sit amet, consectetur adipiscing elit',
'Lorem ipsum dolor sit amet, consectetur adipiscing elit',
'Lorem ipsum dolor sit amet, consectetur adipiscing elit',
'Suspendisse auctor nunc in sapien consectetur at congue est rutrum',
'Etiam molestie sapien non ipsum varius et tincidunt nibh imperdiet',
'Morbi arcu tellus, ultricies eu vulputate nec, vestibulum sit amet purus',
'Sed orci libero, pulvinar et suscipit et, laoreet vitae tortor',
'Sed porttitor sagittis velit, non egestas dolor vehicula faucibus',
'In vitae molestie lacus',
'In vehicula interdum enim, eget accumsan magna tincidunt eget',
'Nam congue accumsan nibh, eu mattis lectus adipiscing a',
'Aliquam vehicula consequat lacus, at volutpat velit pulvinar ac',
'Vivamus ut turpis sed felis fringilla porta',
'In mattis, erat eget porta fermentum, nunc tellus posuere velit, ac fringilla neque felis at nisl',
'Morbi lacinia pretium metus ut tincidunt',
'Sed fermentum consequat massa, sed viverra sem sodales id',
'Phasellus sit amet aliquam leo',
'Vestibulum congue metus non magna sagittis at iaculis leo commodo',
'Phasellus sit amet aliquam leo',
'Phasellus sit amet aliquam leo',
);

}



print scalar @collector, " in collector\n";

# test the collector for duplicate records, return only really fresh lines
my $real_fresh = check_fresh(\@collector);

print scalar @$real_fresh, " fresh lines\n";


# compare the fresh lines to archive, save data
my $new_lines = archive_lookup($real_fresh);

print scalar @$new_lines, " new lines\n";

# updates both archive and fresh
update_files($new_lines);


exit;

sub debug_list {
	my $reff = shift;
	
	foreach my $line (@$reff){
		print substr $line, 0, 70;
		print "\n";
		
	}
	
}

# ------------------------------------- FUNCTIONS -------------------------------------

sub update_files {
	my $new_lines_ref = shift;
	
	if(@$new_lines_ref > 0){
		save_lines($constants{General}{Archive}, $new_lines_ref, 1);
		save_lines($constants{General}{Fresh}, $new_lines_ref, 1);
	}
	
}

sub archive_lookup {
	my $fresh_ref = shift;
	
	my @archive;
	load_lines($constants{General}{Archive}, \@archive);
	
	my @news;
	my @dupes;
	
	foreach my $fresh_item (@$fresh_ref){
		my $is_new = 1;
		foreach my $archive_item (@archive){
			if(is_identic($archive_item, $fresh_item)){
				$is_new = 0;
				print "Found a duplicate entry in archive\n";
				push @dupes, $fresh_item;
				last;
			}
		}
		if($is_new){
			push @news, $fresh_item;
		}
	}
	
	# save dupes
	save_lines($constants{General}{Dupes}, \@dupes, 1) if @dupes>0;
	
	return \@news;
}

sub check_fresh {
	my $collector_ref = shift;
	my @filtered;
	foreach my $c_item (@$collector_ref){
		my $fresh = 1;
		foreach my $f_item (@filtered) {
			if(is_identic($f_item, $c_item)){
				print "Found a duplicate post in blog\n";
				$fresh = 0;
				last;
			}
		}
		push @filtered, $c_item if $fresh;
	}
	return \@filtered;
}

sub is_identic {
	my ($a, $b) = @_;
	
	# just EQ for now
	return $a eq $b;
	
}


sub parse_url {
	my ($agent, $url, $collector_ref) = @_;
	
	my $content = safe_get($agent, $url);
	return 0 unless $content;
	my $tree = HTML::TreeBuilder::XPath->new;
	$tree->parse_content($content);

	my $implementor = $constants{General}{Implementor};
	my $correct = $constants{General}{CorrectText};
	my @list;
	eval "\@list = Implementors::${implementor}::get_posts(\$content, \$correct)";
	
	push @$collector_ref, @list;
	
	my $pcount = @list;
	
	my $not_last;
	
	eval "\$not_last = Implementors::${implementor}::not_last(\$content)";
	
	print "Parsed $url ($pcount records)\n";
	
	return $not_last;
}

sub safe_get {
	my ($agent, $url) = @_;
	
	my $response;
	my $error_counter = 0;
	do {
		if(defined $response){
			if($error_counter++ == $constants{General}{ErrorsBeforeFinish}){
				print "Too many errors. Seems that it is the end of the blog.\n";
				return undef;
			}
			print "Request failed, try again\n";
			sleep 1;
		}
		$response = $agent->get($url);
	} while (!$response->is_success());
	
	return $response->decoded_content();
}

sub load_lines {
	my ($file, $list_ref) = @_;
	
	#return 0 unless open SRC, '<:encoding(UTF-8)', $file;
	return 0 unless open SRC, $file;
	
	my $is_first = 1;
	
	while (<SRC>){
		chomp;
		push @$list_ref, $_;
		if($is_first){
			$list_ref->[0] =~ s/^\xEF\xBB\xBF//;
			$is_first = 0;
		}
	}
	close SRC;

	for(my $i=0; $i<@$list_ref; $i++){
		$list_ref->[$i] = decode('utf-8', $list_ref->[$i]);
	}
	return 1;
}

sub save_lines {
	my ($file, $list_ref, $append) = @_;
	
	my $operator = $append ? '>>' : '>';
	
	open DEST, $operator.':encoding(UTF-8)', $file or die "Cannot open file: $!";
	#open DEST, "$operator$file" or die "Cannot open file: $!";
	foreach (@$list_ref){
		print DEST "$_\n";
	}
	close DEST;
}

