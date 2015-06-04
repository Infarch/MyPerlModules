use strict;
use warnings;

use utf8;
use open qw(:std :utf8);

use lib ("/work/perl_lib");
use ISoft::DB;
use DB_Member;




my $dbh = get_dbh();





# read categories
my $member_obj = DB_Member->new;
$member_obj->set('Type', $DB_Member::TYPE_CATEGORY);

my %ch = map { $_->ID, $_ } $member_obj->listSelect($dbh);

print scalar keys %ch, " categories\n";


# get sites

$member_obj = DB_Member->new;
$member_obj->set('Type', $DB_Member::TYPE_PRODUCT);

my @sitelist = $member_obj->listSelect($dbh);

$dbh->rollback();
$dbh->disconnect();



#my $max = 0;
#foreach my $item (@sitelist){
#	my $val = get_category_count($item->get('Member_ID'));
#	$max = $val if $val>$max;
#}
#print $max;
#exit;



make_csv(\@sitelist);





exit;

sub get_category_items {
	my $cid = shift;
	my @parts;
	while (defined $cid){
		my $obj = $ch{$cid};
		if($cid = $obj->get('Member_ID')){
			unshift @parts, $obj->Name;
		}
	}
	return @parts;
}


sub get_category_count {
	my $cid = shift;
	
	my @parts;
	
	while (defined $cid){
		my $obj = $ch{$cid};
		if($cid = $obj->get('Member_ID')){
			unshift @parts, $obj->Name;
		}
		
	}
	
	return scalar @parts;
	
}


sub make_csv {
	my ($data_ref) = @_;
	
	my @list;
	
	foreach my $item (@$data_ref){
		
		my $descr = $item->get('ShortDescription');
		my $title = $item->get('FullDescription');
		
		my $phone = '';
		if ($descr && $descr=~/(\+\s*\d+\s*\(\s*\d+\s*\)\s*\d+\s*-\s*\d+\s*-\s*\d+)/){
			$phone = $1;
			$phone=~s/\s//g;
		}
		
		my $is_shop = (($descr && $descr =~ /магазин|доставка/i) || ($title && $title =~ /магазин|доставка/i)) ? 1 : 0;
		
		my @ci = get_category_items( $item->get('Member_ID') );
		my @cn;
		for (my $i = 1; $i<9; $i++){
			my $nm = $ci[$i-1] || '';
			push @cn, ("Category$i", $nm);
		}
		
		my $quote = $item->get('Price') || undef;
		
		my %h = (
			@cn,
			Name => $item->Name,
			URL => $item->get('URL'),
			Quote => defined $quote ? int($quote) : '',
			Date => $item->get('Vendor'),
			Title => $title,
			Description => $descr,
			Phone => $phone,
			LooksLikeShop => $is_shop,
		);
		
		push @list, \%h;
	}
	
	open CSV, '>data.csv';
	my $result_ref = csv_provider(\@list);
	foreach my $line (@$result_ref){
		print CSV $line, "\n";
	}

	close CSV;
	
}

sub csv_provider {

	my $data_ref = shift;
	
	my @all_columns = (
		{ title=>'Category1'},
		{ title=>'Category2'},
		{ title=>'Category3'},
		{ title=>'Category4'},
		{ title=>'Category5'},
		{ title=>'Category6'},
		{ title=>'Category7'},
		{ title=>'Category8'},
		{ title=>'Name'}, # header from yandex
		{ title=>'URL'},#
		{ title=>'Quote', default=>0}, #
		{ title=>'Title'}, #
		{ title=>'Description'}, # ShortDescription column
		{ title=>'Phone'},#
		{ title=>'Date'},#
		{ title=>'LooksLikeShop'},#
	);	
	
	# prepare for parsing of input data_ref
	my @header_list;
	my @map_list;
	my @defaults;
	foreach my $column (@all_columns){
		push @header_list, $column->{title};
		push @map_list, exists $column->{mapto} ? $column->{mapto} : $column->{title};
		push @defaults, exists $column->{default} ? $column->{default} : '';
	}
	my $glue_char = "\t";
	my @output;
	# make header
	push @output, join ($glue_char, @header_list);
	# process data
	my $col_number = @map_list;
	foreach my $dataitem (@$data_ref){
		my $cn = 0;
		my $suppress_defaults = $dataitem->{suppress_defaults};
		my @parts;
		while ($cn < $col_number){
			my $key = $map_list[$cn];
			my $value = (exists $dataitem->{$key} && $dataitem->{$key}) ? $dataitem->{$key} : $suppress_defaults ? '' : $defaults[$cn];
			if ($value =~ /$glue_char/o){
				$value = '"' . $value . '"';
			}
			if ( $value =~ /"$/ ) #"
			{
				$value .= ' ';
			}
			push @parts, $value;
			$cn++;
		}
		push @output, join ($glue_char, @parts);
	}
	return \@output;
}

sub get_category {
	my $cid = shift;
	
	my @parts;
	
	while (defined $cid){
		my $obj = $ch{$cid};
		if($cid = $obj->get('Member_ID')){
			unshift @parts, $obj->Name;
		}
		
	}
	
	return join ' >> ', @parts;
	
}

sub get_dbh {
	return ISoft::DB::get_dbh_mysql('yandex_test', 'root', 'admin');
}


