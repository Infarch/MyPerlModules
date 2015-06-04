use strict;
use warnings;

use utf8;

use lib ("/work/perl_lib", "local_lib");

use ISoft::Conf;
use ISoft::DBHelper;
use Category;
use Product;

use DBI;
use FindBin;
use Encode;

my $dbh = get_dbh();
my $cdbh = get_csv_dbh();



my $sql = "select * from data";
my $rows = ISoft::DB::do_query($cdbh, sql=>$sql);

print scalar @$rows, "\n";

# skip the first row - header
shift @$rows;

foreach my $row (@$rows){
	
	print $row->{oid}, "\n";
	
	my $obj = $row->{object}->new;
	$obj->set("ID", $row->{oid});
	$obj->select($dbh);
	
	$obj->set("Name", $row->{name});
	$obj->set("PageTitle", fix($row->{title})." - Мебелион");
	$obj->set("PageMetakeywords", fix($row->{metakeywords}));
	$obj->set("PageMetaDescription", fix($row->{metadescription}));
	$obj->update($dbh);
	$dbh->commit();
	
}








release_dbh($dbh);
exit;

##############################################################

sub fix {
	my $str = Encode::decode("utf-8", shift);
	$str =~ s/"{2,}/"/g;
	$str =~ s/&amp;*/&/g;
	$str =~ s/\\"/"/g;
	return $str;
}

sub get_csv_dbh {
	my $dbh = DBI->connect ("dbi:CSV:", undef, undef, {
		f_dir => $FindBin::Bin,
		csv_quote_char => '"',
    csv_escape_char => '"',
    csv_sep_char => ";",
    FetchHashKeyName => "NAME_lc",
		csv_tables => {
    	data => { file => "edit.csv" },
    },
	}) or die $DBI::errstr;
	return $dbh;
}
