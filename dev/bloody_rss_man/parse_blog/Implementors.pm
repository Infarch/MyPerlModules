# common functions
package Implementors::Format;

sub pre_filter {
	my $content = shift;
	$content =~ s/<\s*br[^>]*>/ /isg;
	$content =~ s/<\/p>/ <\/p>/isg;
	return $content;
}

sub post_filter {
	my $content = shift;
	$content =~ s/\r|\n/ /g;
	$content =~ s/\s{2,}/ /g;
	if($content =~ /\w$/){
		$content .= '.';
	}
	return $content;
}

# each module provides two functions
#  get_posts($content) returns array of blog entries
#  not_last($content) returns 1 if the given content mean that the page contains posts and we can try to check another page

# IMPLEMENTOR

package Implementors::Wordpress_MU;

use strict;
use warnings;

use HTML::TreeBuilder::XPath;

sub get_posts {
	my ($content, $correct) = @_;
	if ($correct){
		$content = Implementors::Format::pre_filter($content);
	}
	
	my $tree = HTML::TreeBuilder::XPath->new;
	$tree->parse_content($content);

	my @posts = $tree->findnodes( q{//div[@class='entry'] | //div[@class='entry_firstpost'] | //div[@class='postspace']} );
	my @list;
	
	foreach my $post (@posts){
		my $text = $post->findvalue( q{.//p[@class!='info']} );
		if($correct){
			$text = Implementors::Format::post_filter($text);
		} else {
			$text =~ s/\r|\n/ /g;
		}
		if($text =~ /\S/s){
			push @list, $text;
		}
	}
	return @list;
}

sub not_last {
	if($_[0] =~ /404 Not Found/s){
		return 0;
	}
	return 1;
}

# IMPLEMENTOR

package Implementors::Wordpress_MU_1;

use strict;
use warnings;

use HTML::TreeBuilder::XPath;

sub get_posts {
	my ($content, $correct) = @_;
	if ($correct){
		$content = Implementors::Format::pre_filter($content);
	}
	
	my $tree = HTML::TreeBuilder::XPath->new;
	$tree->parse_content($content);

	my @posts = $tree->findnodes( q{//div[@id='content']/p/center} );
	
	my @list;
	
	foreach my $post (@posts){
		foreach ($post->findnodes(q{.//a})){
			$_->delete();
		}
		my $text = $post->findvalue( q{.} );
		if($correct){
			$text = Implementors::Format::post_filter($text);
		} else {
			$text =~ s/\r|\n/ /g;
		}
		if($text =~ /\S/s){
			push @list, $text;
		}
	}
	return @list;
}

sub not_last {
	if($_[0] =~ /404 Not Found/s){
		return 0;
	}
	return 1;
}

# IMPLEMENTOR
# http://hqgoldteens.sensualwriter.com/

package Implementors::Wordpress_MU_2;

use strict;
use warnings;

use HTML::TreeBuilder::XPath;

sub get_posts {
	my ($content, $correct) = @_;
	if ($correct){
		$content = Implementors::Format::pre_filter($content);
	}
	
	my $tree = HTML::TreeBuilder::XPath->new;
	$tree->parse_content($content);

	my @posts = $tree->findnodes( q{//div[@class='post']/div[@class='main_post']} );
	
	my @list;
	
	foreach my $post (@posts){
		foreach ($post->findnodes(q{.//a})){
			$_->delete();
		}
		
		my @texts;
		foreach ($post->findnodes(q{.//p})){
			push @texts, $_->findvalue('.');
		}

		my $text = join ' ', @texts;
		if($correct){
			$text = Implementors::Format::post_filter($text);
		} else {
			$text =~ s/\r|\n/ /g;
		}
		if($text =~ /\S/s){
			push @list, $text;
		}
	}
	return @list;
}

sub not_last {
	if($_[0] =~ /404 Not Found/s){
		return 0;
	}
	return 1;
}

# IMPLEMENTOR
# http://ebonysluts.sensualwriter.com/

package Implementors::Wordpress_MU_3;

use strict;
use warnings;

use HTML::TreeBuilder::XPath;

sub get_posts {
	my ($content, $correct) = @_;
	if ($correct){
		$content = Implementors::Format::pre_filter($content);
	}
	
	my $tree = HTML::TreeBuilder::XPath->new;
	$tree->parse_content($content);

	my @posts = $tree->findnodes( q{//div[@class='postentry']} );
	
	my @list;
	
	foreach my $post (@posts){

		my @plist = $post->findnodes(q{./p});
		
		# we dont need the last paragraph
		pop @plist;
		
		my @texts;
		foreach (@plist){
			push @texts, $_->findvalue('.');
		}

		my $text = join ' ', @texts;
		if($correct){
			$text = Implementors::Format::post_filter($text);
		} else {
			$text =~ s/\r|\n/ /g;
		}
		if($text =~ /\S/s){
			push @list, $text;
		}
	}
	return @list;
}

sub not_last {
	if($_[0] =~ /404 Not Found/s){
		return 0;
	}
	return 1;
}

# IMPLEMENTOR
# http://goldenageporn.sensualwriter.com/

package Implementors::Wordpress_MU_4;

use strict;
use warnings;

use HTML::TreeBuilder::XPath;

sub get_posts {
	my ($content, $correct) = @_;
	if ($correct){
		$content = Implementors::Format::pre_filter($content);
	}
	
	my $tree = HTML::TreeBuilder::XPath->new;
	$tree->parse_content($content);

	my @posts = $tree->findnodes( q{//div[@class='narrow_column']/div[@id]} );
	
	my @list;
	
	foreach my $post (@posts){

		my @plist = $post->findnodes(q{./div[@class='entry']/p});

		my @texts;

		foreach my $part (@plist){
			next if ($part->attr('class') && $part->attr('class') eq 'postinfo');
			push @texts, $part->findvalue('.');
		}

		my $text = join ' ', @texts;
		$text =~ s/^\s+//;
		$text =~ s/\s+$//;
		
		if($correct){
			$text = Implementors::Format::post_filter($text);
		} else {
			$text =~ s/\r|\n/ /g;
		}
		if($text =~ /\S/s){
			push @list, $text;
		}
	}
	return @list;
}

sub not_last {
	if($_[0] =~ /404 Not Found/s){
		return 0;
	}
	return 1;
}

# IMPLEMENTOR
# http://goldenageporn.sensualwriter.com/

package Implementors::Wordpress_MU_5;

use strict;
use warnings;

use HTML::TreeBuilder::XPath;

sub get_posts {
	my ($content, $correct) = @_;
	if ($correct){
		$content = Implementors::Format::pre_filter($content);
	}
	
	my $tree = HTML::TreeBuilder::XPath->new;
	$tree->parse_content($content);

	my @posts = $tree->findnodes( q{//div[@id='content']/table[@width='100%']} );
	
	my @list;
	
	foreach my $post (@posts){

		my $text = $post->as_text();
		
		$text =~ s/^\s+//;
		$text =~ s/\s+$//;
		
		if($correct){
			$text = Implementors::Format::post_filter($text);
		} else {
			$text =~ s/\r|\n/ /g;
		}
		if($text =~ /\S/s){
			push @list, $text;
		}
	}
	return @list;
}

sub not_last {
	if($_[0] =~ /404 Not Found/s){
		return 0;
	}
	return 1;
}

# IMPLEMENTOR
# http://girlsinnylon.sensualwriter.com/

package Implementors::Wordpress_MU_6;

use strict;
use warnings;

use HTML::TreeBuilder::XPath;

sub get_posts {
	my ($content, $correct) = @_;
	if ($correct){
		$content = Implementors::Format::pre_filter($content);
	}
	
	my $tree = HTML::TreeBuilder::XPath->new;
	$tree->parse_content($content);

	my @nodes = $tree->findnodes( q{//div[@id='colTwo']/p} );
	
	my @list;
	
	while (@nodes > 0){
		shift @nodes;
		shift @nodes;
		my $data = shift @nodes;
		shift @nodes;
		
		if(defined $data){
			my $text = $data->as_text();
			$text =~ s/^\s+//;
			$text =~ s/\s+$//;
			if($correct){
				$text = Implementors::Format::post_filter($text);
			} else {
				$text =~ s/\r|\n/ /g;
			}
			if($text =~ /\S/s){
				push @list, $text;
			}
		}
	}
	return @list;
}

sub not_last {
	if($_[0] =~ /404 Not Found/s){
		return 0;
	}
	return 1;
}

# IMPLEMENTOR
# http://sexrightnow.sensualwriter.com/

package Implementors::Wordpress_MU_7;

use strict;
use warnings;

use HTML::TreeBuilder::XPath;

sub get_posts {
	my ($content, $correct) = @_;
	
	if ($correct){
		$content = Implementors::Format::pre_filter($content);
	}
	
	my $tree = HTML::TreeBuilder::XPath->new;
	$tree->parse_content($content);

	my @nodes = $tree->findnodes( q{//div[@id='content']/*} );
	
	my $test;
	do {
		$test = pop @nodes;
	} while ($test->tag() eq 'a');
	push @nodes, $test;
	
	my @postlist;

	my $entry;
	
	foreach my $node (@nodes){
		if($node->tag() eq 'h2'){
			$entry = [];
			push @postlist, $entry;
			next;
		}
		push @$entry, $node;
	}
	
	my @texts;
	foreach my $data (@postlist){
		my $text = '';
		for (my $i=2; $i<(@$data-2); $i++){
			$text .= $data->[$i]->as_text().' ';
		}
		$text =~ s/^\s+//;
		$text =~ s/\s+$//;
		if($correct){
			$text = Implementors::Format::post_filter($text);
		} else {
			$text =~ s/\r|\n/ /g;
		}
		if($text =~ /\S/s){
			push @texts, $text;
		}
	}

	return @texts;

}

sub not_last {
	if($_[0] =~ /404 Not Found/s){
		return 0;
	}
	return 1;
}

# IMPLEMENTOR
# http://bangbrosblog.sensualwriter.com/

package Implementors::Wordpress_MU_8;

use strict;
use warnings;

use HTML::TreeBuilder::XPath;

sub get_posts {
	my ($content, $correct) = @_;
	
	if ($correct){
		$content = Implementors::Format::pre_filter($content);
	}
	
	my $tree = HTML::TreeBuilder::XPath->new;
	$tree->parse_content($content);

	my @nodes = $tree->findnodes( q{//div[@id='content']/*} );
	
	
	my @postlist;

	my $entry;
	
	foreach my $node (@nodes){
		if($node->tag() eq 'h2'){
			$entry = [];
			push @postlist, $entry;
			next;
		}
		push @$entry, $node;
	}
	
	my @texts;
	foreach my $data (@postlist){
		next if @$data<5;
		my $text = $data->[4]->as_text();
		$text =~ s/^\s+//;
		$text =~ s/\s+$//;
		if($correct){
			$text = Implementors::Format::post_filter($text);
		} else {
			$text =~ s/\r|\n/ /g;
		}
		if($text =~ /\S/s){
			push @texts, $text;
		}
	}

	return @texts;

}

sub not_last {
	if($_[0] =~ /404 Not Found/s){
		return 0;
	}
	return 1;
}


# IMPLEMENTOR
# http://partyhardcore.sensualwriter.com/

package Implementors::Wordpress_MU_9;

use strict;
use warnings;

use HTML::TreeBuilder::XPath;

sub get_posts {
	my ($content, $correct) = @_;
	
	if ($correct){
		$content = Implementors::Format::pre_filter($content);
	}
	
	my $tree = HTML::TreeBuilder::XPath->new;
	$tree->parse_content($content);

	my @nodes = $tree->findnodes( q{//div[@id='content']/div[@class='post']/div[@class='storycontent']/p[1]} );
		
	my @texts;
	foreach my $node (@nodes){
		my $text = $node->as_text();
		$text =~ s/^\s+//;
		$text =~ s/\s+$//;
		if($correct){
			$text = Implementors::Format::post_filter($text);
		} else {
			$text =~ s/\r|\n/ /g;
		}
		if($text =~ /\S/s){
			push @texts, $text;
		}
	}

	return @texts;

}

sub not_last {
	if($_[0] =~ /404 Not Found/s){
		return 0;
	}
	return 1;
}

# IMPLEMENTOR
# http://hotmaturesluts.sensualwriter.com/

package Implementors::Wordpress_MU_10;

use strict;
use warnings;

use HTML::TreeBuilder::XPath;

sub get_posts {
	my ($content, $correct) = @_;
	
	if ($correct){
		$content = Implementors::Format::pre_filter($content);
	}
	
	my $tree = HTML::TreeBuilder::XPath->new;
	$tree->parse_content($content);

	my @nodes = $tree->findnodes( q{//div[@class='post']/div[@class='post_content']} );
	
	my @texts;
	foreach my $node (@nodes){
		my $text = $node->as_text();
		$text =~ s/^\s+//;
		$text =~ s/\s+$//;
		if($correct){
			$text = Implementors::Format::post_filter($text);
		} else {
			$text =~ s/\r|\n/ /g;
		}
		if($text =~ /\S/s){
			push @texts, $text;
		}
	}

	return @texts;

}

sub not_last {
	if($_[0] =~ /404 Not Found/s){
		return 0;
	}
	return 1;
}

# IMPLEMENTOR
# http://www.ocxxxteenblog.com/

package Implementors::Wordpress_MU_11;

use strict;
use warnings;

use HTML::TreeBuilder::XPath;

sub get_posts {
	my ($content, $correct) = @_;
	
	if ($correct){
		$content = Implementors::Format::pre_filter($content);
	}
	
	my $tree = HTML::TreeBuilder::XPath->new;
	$tree->parse_content($content);

	my @nodes = $tree->findnodes( q{//div[@class='center-blog']/div[@class='post-content']} );
	
	my @texts;
	foreach my $node (@nodes){
		
		# no meta
		my @metalist = $node->findnodes( q{./div[@class='main-meta']} );
		foreach (@metalist){
			$_->delete();
		}
		
		my $text = $node->as_text();
		$text =~ s/^\s+//;
		$text =~ s/\s+$//;
		$text =~ s/Share This Video//;
		
		if($correct){
			$text = Implementors::Format::post_filter($text);
		} else {
			$text =~ s/\r|\n/ /g;
		}
		if($text =~ /\S/s){
			push @texts, $text;
		}
	}

	return @texts;

}

sub not_last {
	return $_[0] !~ /Not Found/s;
}

# IMPLEMENTOR
# Target:
#  http://blog.cat.org.uk

package Implementors::Wordpress_XX;

use strict;
use warnings;

use HTML::TreeBuilder::XPath;

sub get_posts {
	my ($content, $correct) = @_;
	if ($correct){
		$content = Implementors::Format::pre_filter($content);
	}
	
	my $tree = HTML::TreeBuilder::XPath->new;
	$tree->parse_content($content);

	my @posts = $tree->findnodes( q{//div[@class='storycontent']} );
	my @list;
	foreach my $post (@posts){
		my $text = $post->findvalue( q{./p} );
		if($correct){
			$text = Implementors::Format::post_filter($text);
		} else {
			$text =~ s/\r|\n/ /g;
		}
		if($text =~ /\S/s){
			push @list, $text;
		}
	}
	return @list;
}

sub not_last {
	if($_[0] =~ /Page not found/s){
		return 0;
	}
	return 1;
}

1;
