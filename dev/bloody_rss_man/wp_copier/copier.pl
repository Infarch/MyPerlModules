use strict;
use warnings;

use CGI ();
CGI->compile(':all');
use CGI::Carp qw(fatalsToBrowser);

my $xcgi = new CGI;
start($xcgi);

sub start {
	my $cgi = shift;

	my $toname = 'copy_to';
	my $dbname = 'dbname';
	
	my $respname = 'isresponse';
	
	print $cgi->header,
		$cgi->start_html('Copier'),
		$cgi->h2('Welcome to the copier');
	
	
	# do operation
	my @output;
	my $ok;
	
	if($cgi->param($respname)){
		# 1. update db name
		$ok = update_db_name($cgi, $dbname, \@output);
		
		# 2. copy wordpress
		$ok = $ok && copy_wordpress($cgi, $toname, \@output);
		
		# 3. get and move a theme
		$ok = $ok && copy_theme($cgi, $toname, \@output);
		
		if($ok){
			$cgi->param($dbname, '');
			$cgi->param($toname, '');
		}
	}
		
	if(@output>0){
		print $cgi->hr;
		print join "<br/>", @output;
		print $cgi->hr;
		print "<br/>";
	}

	# print form
  print $cgi->start_form('post');
	
		print "Copy files from /public_html/wp1 to:<br/>";
		print $cgi->textfield($toname, ''), "<br/><br/>";
		
		print "Change database name to<br/>";
		print $cgi->textfield($dbname, ''), "<br/><br/>";

		print $cgi->submit('Sumbit');
		
		print $cgi->hidden($respname, 1);
		
	print $cgi->endform;

	
	
	
	print $cgi->end_html;
}


sub update_db_name {
	my ($cgi, $paramname, $logref) = @_;
	my $name = $cgi->param($paramname);
	if($name){
		
		
		push @$logref, "<i>Database name was changed to $name</i>";
		return 1;
	} else {
		push @$logref, "<i><b>Database name cannot be empty</b></i>";
		return 0;
	}
	
}

sub copy_wordpress {
	my ($cgi, $paramname, $logref) = @_;
	my $path = $cgi->param($paramname);
	$path =~ s!/+$!!;
	if($path){
		
		
		
		my $wp_source = "~/public_html/1wp";
		my $wp_dest = "~/public_html/$path";
		
		push @$logref, "<i>Wordpress was copied to $path</i>";
		return 1;
	} else {
		push @$logref, "<i><b>Copy path cannot be empty</b></i>";
		return 0;
	}
}

sub copy_theme {
	my ($cgi, $paramname, $logref) = @_;
	
	my $path_to = $cgi->param($paramname);
	
	# get awailable themes
	my $themes_path = '/public_html/1themes';
	opendir (DIR, $themes_path) or die "Cannot open directory $themes_path: $!";
	my @themes = grep { /[^.]/ && -d "$themes_path/$_" } readdir DIR;
	closedir DIR;
	
	if(@themes==0){
		push @$logref, "<i><b>No themes!</b></i>";
		return 0;
	}
	
	srand;
	my $ti = int(rand(scalar @themes));
	
	push @$logref, "Found themes: @themes";
	push @$logref, "Copy theme $themes[$ti] to $path_to";
	
}




1;