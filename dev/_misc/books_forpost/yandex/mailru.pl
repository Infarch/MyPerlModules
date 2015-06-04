#!/usr/bin/perl -w
use strict;
use warnings;

use FindBin;
use Config::IniFiles;
use WWW::Mechanize;
use LWP::Simple 'getstore';
use DBI;
use Error ':try';
use Encode qw(encode decode);
use Image::Resize;
use File::Copy;



# prepare global variables
our $cfg = Config::IniFiles->new( -file => $FindBin::Bin . "/conf.ini" );
our $dbh = get_dbh();
our $mech;
our $brand_id = $cfg->val('Tables', 'BrandID');
our $tempfile = $FindBin::Bin . "/tempfile.jpg";
our $pics_path = $cfg->val('Directories', 'Pictures');
our $main_domain = $cfg->val('Networking', 'Domain');
sub prepare_mech;


my $products = get_unprocessed_products();
#my $products = get_id(1787);


if(@$products>0){
	# open start page
	prepare_mech();
	process_products($products);
}

# release database handler
release_dbh($dbh);

print "Done\n";
exit;


# -----------------------------

sub open_prod_description {
	if( my $testlink = $mech->find_link(url_regex => qr/description\//i, n=>1) ){
		$mech->get( $testlink->url_abs() );
		return 1;
	} else {
		return 0;
	}
}

sub open_category {
	if( my $testlink = $mech->find_link(url_regex => qr/magazilla\.php\?/i, n=>1) ){
		$mech->get( $testlink->url_abs() );
		return 1;
	} else {
		return 0;
	}
}

sub find_product {
	my $searchdata = shift;
	
	$mech->get("http://$main_domain/");
	my $f = 1;
	
	try {
		# look for a product
		$mech->submit_form(with_fields=>{
			search_ => encode('cp-1251', $searchdata)
		});
	} otherwise {		
		$f = 0;
	};

	return 0 unless $f;
	
	if (open_prod_description()){
		return 1;
	} else {
		# no description link, check category link
		if ( open_category() ){
			if( open_prod_description() ){
				return 2;
			}
		}
	}
	return 0;
}

sub parse_update_product {
	my $prod_id = shift;
	
	my $content = $mech->response()->decoded_content();
	
	$content =~ s/\r|\n|\t/ /g;
	$content =~ s/\s{2,}/ /g;
	
	# get description
	
	if( $content =~ /(<table [^>]* id="help_table">.*?<\/table>)<div class="op5"><div class="line11"><spacer width="1" height="1"><\/div><div class="v_pad"><spacer width="1" height="1"><\/div><div class="v_pad"><spacer width="1" height="1"><\/div>(.*?)<\/td><td width="33%" class="op4" rowspan="2">/ )
	{
		my $descr = $1.$2;
		my $sql = "update SS_products set description=? where productID=$prod_id";
		do_query(sql=>$sql, values=>[$descr]);
	}
	
	# get photo
	if( $content =~ /<td class="cart1" rowspan="2" nowrap width="32%" id="op91">(.*?)<\/td>/ ){
		
		my $block = $1;
		my $large = '';
		my $small = '';
		# look for small image
		if($block =~ /<img src="([^"]+)" width="[^"]+" height="[^"]+" border="0" alt="[^"]+">/) #"
		{
			$small = $1;
			$small =~ s/^\.//;
			$small = "http://$main_domain".$small;
			
			my ($sm_name, $md_name) = process_small_medium($small, $prod_id);
			if( $sm_name ){
				if($block=~/onclick="window\.open\('(.*?)'/) #"
				{
					$large = $1;
					getstore($large, $tempfile);
				}
				my $l_name = check_path($pics_path, "mb_$prod_id", "jpg");
				$l_name .= ".jpg";
				copy($tempfile, "$pics_path/$l_name");
				# insert a new picture into table
				my $sql = "insert into SS_product_pictures (productID, filename, thumbnail, enlarged) values (?,?,?,?)";
				do_query(sql=>$sql, values=>[$prod_id, $md_name, $sm_name, $l_name]);
				# set this picture as default
				my $pic_id = do_query(sql=>'select LAST_INSERT_ID()', single=>1);
				$sql = "update SS_products set default_picture=$pic_id where productID=$prod_id";
				do_query(sql=>$sql);
			}
		}
	}
	
}

sub do_resize {
	my ($resize, $w, $h, $name) = @_;
	my $gd = $resize->gd();
	my ($width, $height) = $gd->getBounds();
	if($width>$w || $height>$h){
		$gd = $resize->resize($w, $h);
	}

	my $new_name = check_path($pics_path, $name, "jpg");

	open XX, ">$pics_path/$new_name.jpg" or die "$!";
	binmode XX;
	print XX $gd->jpeg();
	close XX;
	
	return $new_name.".jpg";
}

sub process_small_medium {
	my ($url, $prod_id) = @_;
	
	my $sm;
	my $md;
	
	if(getstore($url, $tempfile)){
		try {
			
			
			my $resize = Image::Resize->new($tempfile);
			$sm = do_resize($resize, 154, 115, "smm_$prod_id");
			$md = do_resize($resize, 186, 139, "m_$prod_id");
		} otherwise {
			my $E = shift;
			my $msg = $E->text();
			print "Error in picture processor : $msg\n";
			
		};
	}
	
	return ($sm, $md);
}

sub check_path {
	my ($path, $name, $ext) = @_;
	
	my $temp_name = $name;
	my $c = 1;
	
	while(-e "$path/$temp_name.$ext"){
		$temp_name = $name.'_'.$c++;
	}
	
	return $temp_name;
}

sub prepare_mech(){
	$mech = WWW::Mechanize->new( autocheck=>1 );
	$mech->agent('Mozilla/5.0 (Windows; U; Windows NT 5.0; ru-RU; rv:1.7.7) Gecko/20050414 Firefox/1.0.3.x');
}

sub process_product {
	my $product = shift;
	
	my $id = $product->{productID};
	my $search_data = $product->{name};
	
	# nothing to search
	return unless $search_data;
	
	# check brand
	if ($brand_id){
		my $sql = "select var.option_value from SS_products_opt_val_variants var where var.optionID=$brand_id and exists (select * from `SS_product_options_set` where variantID=var.variantID and productID=$id)";
		my $brand = do_query(sql=>$sql, single=>1);
		if($brand){
			if( $search_data!~/$brand/i ){
				$search_data = "$brand $search_data";
			}
		}
	}
	
	print "Looking for $id : $search_data\n";
	
	if( find_product($search_data) ){
		parse_update_product($id);
	} else {
		print "Not found\n";
	}

}

sub mark_done {
	my $product = shift;
	my $id = $product->{productID};
	my $sql = "update SS_products set yandex=1 where productID=$id";
	do_query(sql=>$sql);
}

sub process_products {
	my $products = shift;
	
	foreach my $product (@$products){
		
		try {
			
			process_product($product);
			mark_done($product);
			$dbh->commit();
			
		} otherwise {
			my $E = shift;
			$dbh->rollback();
			my $msg = $E->text();
			print "Error: $msg\n";
		};
		
	}
	
}

sub get_id {
	my ($id) = @_;
	
	my $sql = "select * from SS_products where productID=$id";
	
	my $rows = do_query(sql=>$sql);
	return $rows;
	
}

sub get_unprocessed_products {
	
	my $limit = $cfg->val('Networking', 'ReadLimit');
	if($limit){
		$limit = "limit $limit";
	} else {
		$limit = '';
	}
	my $sql = "select * from SS_products where yandex=0 and name is not null and name != '' $limit";
	
	my $rows = do_query(sql=>$sql);
	return $rows;
}

sub do_query {
	my %params = @_;
	my $sql = $params{sql};
	my $hashref = exists $params{hashref} ? $params{hashref} : 0;
	my $arr_ref = exists $params{arr_ref} ? $params{arr_ref} : 0;
	my $single  = exists $params{single}  ? $params{single}  : 0;

	my @vals;
	if (exists $params{values}){
		my $rf = ref $params{values};
		if($rf && $rf eq 'ARRAY'){
			@vals = @{$params{values}};
		} else {
			die "The 'values' parameter should be an array reference";
		}
	}

	my $sth = $dbh->prepare($sql);
	if (@vals>0){
		$sth->execute(@vals) or die "SQL Error: ".$dbh->err()." ($sql)";
	} else {
		$sth->execute() or die "SQL Error: ".$dbh->err()." ($sql)\n";
	}

	my $rows = [];
	if( !$sth->{NUM_OF_FIELDS} ) {
		# Query was not a SELECT, ignore
	} elsif($hashref) {
		$rows = $sth->fetchall_arrayref({});
	} elsif($arr_ref || $single) {
		$rows = $sth->fetchall_arrayref([]);
	} else {
		$rows = $sth->fetchall_arrayref({});
	}
	$sth->finish;

	if($single){
		return @$rows>0 ? $rows->[0]->[0] : undef;
	}
	return $rows;
}

sub release_dbh {
	my $dbh = shift;
	$dbh->rollback();
	$dbh->disconnect();
}

sub get_dbh {
	my $host = $cfg->val('DB', 'Host');
	my $database = $cfg->val('DB', 'Database');
	my $dbh = DBI->connect("dbi:mysql:$database:host=$host", $cfg->val('DB', 'User'), $cfg->val('DB', 'Password')) or 
		die "Connection Error: $DBI::errstr\n";
		
	$dbh->{'mysql_enable_utf8'} = 1;
	$dbh->do("set names utf8");
	
	$dbh->{AutoCommit} = 0;
	return $dbh;
}

