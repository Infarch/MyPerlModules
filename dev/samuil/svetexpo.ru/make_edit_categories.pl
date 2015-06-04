use strict;
use warnings;

use lib ("/work/perl_lib", "local_lib");

use ISoft::DBHelper;

use Category;


my $dbh = get_dbh();
my @list;

process();

release_dbh($dbh);

exit;

sub process_category {
	my ($category, $path) = @_;
	print $category->get("URL"), "\n";
	# get children
	my $sc = Category->new;
	$sc->set("Category_ID", $category->ID);
	my @children = $sc->listSelect($dbh);
	
	foreach my $subcat (@children){
		my $name = correct($subcat->get("Name"));
		# add to list
		push @list, {
			cid => $subcat->ID(),
			name => $name,
			path => $path,
			title => correct($subcat->get("PageTitle")),
			keywords => correct($subcat->get("PageMetakeywords")),
			descr => correct($subcat->get("PageMetaDescription")),
		};
		process_category($subcat, $path."/".$name);
	}
}

sub correct {
	my $value = shift;
	$value =~ s/[\x0d\x0a\x09]/ /g;
	$value =~ s/\s+/ /g;
	$value =~ s/^\s+//;
	$value =~ s/\s+$//;
	return $value;
}

sub save_csv {
	my ($name, $data_ref) = @_;
	my $result_ref = csv_provider($data_ref);
	open (CSV, '>', $name)
		or die "Cannot open file $name: $!";
	foreach my $line (@$result_ref){
		utf8::encode($line);
		#$line = encode($encoding, $line, Encode::FB_DEFAULT);
		print CSV $line, "\n";
	}
	close CSV;
}

sub csv_provider {

	my $data_ref = shift;
	
	# columns definition - webasyst CSV format
	
	my @all_columns_ru = (
		{ title=>'CID', mapto=>'cid'},
		{ title=>'Name', mapto=>'name'},
		{ title=>'Path', mapto=>'path'},
		{ title=>'Title', mapto=>'title', default=>''},
		{ title=>'MetaKeywords', mapto=>'keywords', default=>''},
		{ title=>'MetaDescription', mapto=>'descr', default=>''},
	);	
	
	# prepare for parsing of input data_ref
	my @header_list;
	my @map_list;
	my @defaults;
	my @quotes;
	my @forcedquotes;
	foreach my $column (@all_columns_ru){
		push @header_list, $column->{title};
		push @map_list, $column->{mapto};
		push @defaults, exists $column->{default} ? $column->{default} : '';
		push @quotes, exists $column->{quote} ? $column->{quote} : 0;
		push @forcedquotes, exists $column->{force_quote} ? $column->{force_quote} : 0;
	}
	my $glue_char = ";";
	my @output;
	# make header
	push @output, join ($glue_char, @header_list);
	# process data
	my $col_number = @map_list;
	foreach my $dataitem (@$data_ref){
		my $cn = 0;
		my $suppress_defaults = $dataitem->{suppress_defaults} ? 1 : 0;
		my @parts;
		while ($cn < $col_number){
			my $key = $map_list[$cn];
			my $value = exists $dataitem->{$key} ? $dataitem->{$key} : $suppress_defaults ? '' : $defaults[$cn];
			$value =~ s/"/""/g; #";
			my $quote = $quotes[$cn];
			my $force_quote = $forcedquotes[$cn];
			if($force_quote || ($value ne '')){
				if ($force_quote || $quote || $value =~ /$glue_char/o ){
					$value = '"' . $value . '"';
				}
			}
			push @parts, $value;
			$cn++;
		}
		push @output, join ($glue_char, @parts);
	}
	return \@output;
}

sub process {
	# take the root
	my $root = Category->new;
	$root->set("Level", 0);
	$root->select($dbh);
	
	process_category($root, "");
	
	save_csv("edit.csv", \@list);
}


