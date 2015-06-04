#!/usr/bin/perl

use strict;

use CGI ();
CGI->compile(':all');
use CGI::Carp;


my $sitemap_template = "mapcreate.html";
my $sitemap_file = "sitemap.html";

my $page_template = "pagecreate.html";


my $cgi = CGI->new;

print $cgi->header;

my $core = "";

my @titles;
my $title;
my $text_raw;
my $text;

my %handlers = (
	content => \&handle_content,
	title => \&handle_title,
	articles => \&handle_articles,
	desc => \&handle_desc,
	map => \&handle_map
);


if($cgi->param('txt')){
	# update template

	# process titles
	$title = $cgi->param('title');
	push @titles, $title;
	load_lines("titles.txt", \@titles);
	save_lines("titles.txt", \@titles);
	
	# process text
	$text_raw = $cgi->param('txt');
	my @parts = split "\n", $text_raw;
	$text = "";
	foreach (@parts){
		s/\r//g;
		s/\s+$//;
		s/^\s+//;
		$text .= "<p>$_</p>\n" if $_;
	}
	
	# process templates
	process_template($page_template, title_to_name($title));
	process_template($sitemap_template, $sitemap_file);
	
	$core = "<h3>Your templates have been updated</h3><a href='$sitemap_file'>Open sitemap</a><br/>"
		."<a href='form.cgi'>Back to form</a>";
	
} else {
	# display form
	$core = qq{
		<form method="post">
			<input type="text" name="title" style="width:300px" /><br/><br/>
			<textarea rows="30" cols="100" name="txt"></textarea><br/><br/>
			<input type="submit" value="Submit" />
		</form>
	};
}

print qq{
<html>
	<head>
	</head>
	<!-- <body>	</body> -->
	<body>
		$core
	</body>
</html>
};


return 1;


sub process_template {
	my ($tpl_name, $output_name) = @_;
	
	my @lines;
	my @output;
	load_lines($tpl_name, \@lines);
	foreach my $line (@lines){
		push @output, process_line($line);
	}
	
	save_lines($output_name, \@output);
	
}

sub process_line {
	my $line = shift;
	# look for a word in brackets
	if($line=~/\[(.+?)\]/){
		my $tag = $1;
		my $replacement = process_tag($tag);
		if(defined $replacement){
			$line =~ s/\[$tag\]/$replacement/;
		}
	}
	return $line;
}

sub handle_desc {
	my $number = $_[0] || 5;
	my @words = split /\s+/, $text_raw;
	if($number > @words){
		$number = @words;
	}
	my $descr = join ' ', @words[0..$number-1];
	return $descr;
}

sub handle_articles {
	my $number = $_[0] || @titles;
	if ($number > @titles){
		$number = @titles;
	}
	
	my $str = "<ul>";
	for(my $i=0; $i<$number; $i++){
		my $item = $titles[$i];
		$str .= "<li><a href=\"" . title_to_name($item) . "\" title=\"$item\">$item</a></li>";
	}
	$str .= "</ul>";
	
	return $str;
}

sub handle_map {
	my $str = "<ul>";
	foreach (@titles){
		$str .= "<li><a href=\"" . title_to_name($_) . "\" title=\"$_\">$_</a></li>";
	}
	$str .= "</ul>";
	return $str;
}

sub handle_content {
	return $text;
}

sub handle_title {
	return $title;
}

sub title_to_name {
	my $xxx = shift;
	$xxx =~ s/\W+/-/g;
	return lc "$xxx.html";
}

sub process_tag{
	my $fulltag = shift;
	my $output;
	my ($tag, @args) = split "_", $fulltag;
	if($tag && exists $handlers{$tag}){
		$output = $handlers{$tag}->(@args);
	}
}

sub save_lines {
	my ($file, $lines_ref, %params) = @_;
	my $operator = $params{append} ? '>>' : '>';
	open (XX, $operator, $file) or die "Cannot open $file: $!\n";
	foreach (@$lines_ref){
		print XX "$_\n";
	}
	close XX;
}

sub load_lines {
	my ($file, $dataref) = @_;
	if (open (XX, $file)){
		foreach my $line (<XX>){
			chomp $line;
			push @$dataref, $line;
		}
		close XX;
	}
}