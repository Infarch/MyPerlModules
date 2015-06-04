# convert multiselect features to options

use strict;
use warnings;

use lib ("/work/perl_lib", "local_lib");

use Win32::Clipboard;

use ISoft::DB;
use ISoft::DBHelper;

use Option;
use OptionValue;
use Property;
use PropList;
use Feature;

use ExportUtils;


# ignore the features below: they must be multiselect anyway
my %ignore = (
	Listing => 1
);

my $CLIP = Win32::Clipboard();

my $UPDATE = 0;

my $dbh = get_dbh();

validate_tables();

release_dbh($dbh);

exit;

########################################################

sub build_change_script {
	
	open YY, '>alter_features.sql';
	
	foreach my $name( map { $_->{name} } @PropList::List){
		my $hrname = ExportUtils::get_property_name($name);
		my $feature = Feature->new;
		$feature->set('Name', $hrname);
		$feature->select($dbh);
		my $type = $feature->get('Type');
		if($type ne $Feature::TYPE_CHECKBOX_MULTIPLE){
			
			my $feature_id = $feature->get('CartID');
			print "$feature_id\n";
			
			print YY "update `cscart_product_features` set `feature_type`='$type' where `feature_id`=$feature_id;\n";
			print YY "delete from `cscart_product_feature_variant_descriptions` where `variant_id` in (select `variant_id` from `cscart_product_feature_variants` where `feature_id`=$feature_id);\n";
			print YY "delete from `cscart_product_feature_variants` where `feature_id`=$feature_id;\n\n";
		}
		
	}
	
	close YY;

}


sub build_change_list {
	
	open YY, '>alter_features.txt';
	
	foreach my $name( map { $_->{name} } @PropList::List){
		my $hrname = ExportUtils::get_property_name($name);
		my $feature = Feature->new;
		$feature->set('Name', $hrname);
		$feature->select($dbh);
		my $type = $feature->get('Type');
		if($type ne $Feature::TYPE_CHECKBOX_MULTIPLE){
			
			if($type eq $Feature::TYPE_OTHER_TEXT){
				$type = "Other - text";
			}
			elsif($type eq $Feature::TYPE_OTHER_NUMBER){
				$type = "Other - number";
			}
			
			# report the feature to be altered
			print YY "$hrname -> $type\n";
		}
	}
	
	close YY;

}

sub validate_tables {
	my $sql = "select distinct(Name) from property";
	my $data = ISoft::DB::do_query($dbh, sql=>$sql);
	foreach my $name ( map {$_->{Name}} @$data ){
		my $hrname = ExportUtils::get_property_name($name);
		# check existence of an appropriate feature
		my $feature_obj = Feature->new;
		$feature_obj->set("Name", $hrname);
		unless($feature_obj->checkExistence($dbh)){
			next;
		}
		
		# check data for range and number fields
		my $ftype = $feature_obj->get("Type");
		if($ftype eq $Feature::TYPE_OTHER_RANGE){
			check_ranges($name);
		}
		elsif($ftype eq $Feature::TYPE_SELECT_NUMBER){
			check_numbers($feature_obj, $name);
		}
		elsif($ftype eq $Feature::TYPE_OTHER_NUMBER){
			check_numbers($feature_obj, $name);
		}
	}
	
}

sub validInt {
	my $val = shift;
	return $val=~/^-?\d+$/;
}

sub validFloat {
	my $val = shift;
	return $val=~/^-?\d+(|\.\d+)$/;
}

sub check_numbers {
	my ($feature, $pname) = @_;
	
	# all numbers must not be decimal, only integer values are allowed.
	# so if there is a decimal, the feature must be converted to Range
	
	my $property_obj = Property->new;
	$property_obj->set("Name", $pname);
	$property_obj->set("Ignore", 0);
	my $list = $property_obj->listSelect($dbh);
	
	my $valid = 1;
	
	foreach my $obj (@$list){
		my $id = $obj->ID;
		my $v = $obj->get("newValue");
		if(validFloat($v)){
			unless(validInt($v)){
				$valid = 0;
				last;
			}
		} else {
			die "$id : $v";
		}
	}
	
	unless($valid){
		# convert to range
		print "Property: $pname is RANGE now\n";
		
		$feature->set("Type", $Feature::TYPE_OTHER_RANGE);
		$feature->update($dbh) if $UPDATE;
		
		foreach my $obj (@$list){
			$obj->set('newValue2', $obj->get('newValue'));
			$obj->update($dbh) if $UPDATE;
		}
		
		$dbh->commit() if $UPDATE;
		
	}
	
	return 1;	
}


sub check_ranges {
	my $pname = shift;
	my $property_obj = Property->new;
	$property_obj->set("Name", $pname);
	$property_obj->set("Ignore", 0);
	my $list = $property_obj->listSelect($dbh);
	
	foreach my $obj (@$list){
		my $id = $obj->ID;
		my $v1 = $obj->get("newValue");
		my $v2 = $obj->get("newValue2");
		
		unless (validFloat($v1)){
			# check whether this is a "wrong range": a value like "33-44"
			my ($x1, $x2) = split "-", $v1;
			if(validFloat($x1) && validFloat($x1) && !$v2){
				print "$id: improve\n";
				$obj->set("newValue", $x1);
				$obj->set("newValue2", $x2);
				$obj->update($dbh) if $UPDATE;
			} else {
				die "$id : $v1";
			}
		}
		
		if($v2 eq ""){
			# copy the value
			print "$ id: copy\n";
			$obj->set("newValue2", $v1);
			$obj->update($dbh) if $UPDATE;
		} else {
			die "$id : $v2" unless validFloat($v2);
		}
		
	}
	
	$dbh->commit() if $UPDATE;
	
}

sub list_option_properties {
	print "Reading DB\n";
	my $sql = "select distinct(Name) from property";
	my $data = ISoft::DB::do_query($dbh, sql=>$sql);
	print "Processing data\n";
	open XX, '>proplist.txt';
	foreach my $row (@$data){
		my $pname = $row->{Name};
		# skip the name if it has been listed in the ignore list
		next if exists $ignore{$pname};
		
		# check whether there is at least one separator pattern
		my $rows = ISoft::DB::do_query($dbh, sql=>"select ID from property where Value like '%-!-%' and Name='$pname' limit 1");
		
		if(@$rows > 0){
			my $block = qq(
	{
		name => '$pname',
		type => 'X'
	},);
			print XX $block;
		}
		
	}
	close XX;
}

sub start {
	
	foreach my $prop (@PropList::List){
		my $pname = $prop->{name};
		print "- $pname\n";
		my $pt = lc $prop->{type};
		if($pt eq 'x'){
			# unprocessed property
			list_values($pname);
			# copy the name to the windows clipboard
			$CLIP->Set($pname);
			last;
		}
		elsif($pt eq 's'){
			# convert to strings
			make_options($pname, $Feature::TYPE_OTHER_TEXT);
		}
		elsif($pt eq 'n'){
			# convert to strings
			make_options($pname, $Feature::TYPE_OTHER_NUMBER);
		}
		elsif($pt eq 'r'){
			# convert to strings
			make_options($pname, $Feature::TYPE_OTHER_RANGE);
		}
		else {
			die "No type";
		}
	}
		

}

sub make_options {
	my ($pname, $newtype) = @_;
	# make the name human readable
	my $hrname = ExportUtils::get_property_name($pname);
	# get all properties to be converted to options
	my $property_obj = Property->new;
	$property_obj->set("Name", $pname);
	$property_obj->set("Ignore", 0);
	$property_obj->set("Value", '%-!-%');
	$property_obj->setOperator("Value", 'like');
	my $plist = $property_obj->listSelect($dbh);
	
	# nothing to process
	return if @$plist==0;
	
	my $option_obj = Option->new;
	$option_obj->set("Name", $pname);
	if($option_obj->checkExistence($dbh)){
		print "An option already exists\n";
	}else{
		print "Insert a new option\n";
		$option_obj->insert($dbh);
	}
	my $option_id = $option_obj->ID;
	
	# get a Feature object
	my $feature_obj = Feature->new;
	$feature_obj->set("Name", $hrname);
	$feature_obj->set("Type", 'M');
	$feature_obj->select($dbh);
	# prepare a prefix and a suffix
	my $prefix = $feature_obj->get("Prefix") || "";
	my $suffix = $feature_obj->get("Suffix") || "";
	
	# make option values
	foreach my $p_obj (@$plist){
		my $product_id = $p_obj->get('Product_ID');
		my $val = $p_obj->get("newValue");
		die "no value" unless $val;
		foreach my $str ( map {"$prefix$_$suffix"} split '-!-', $val ){
			# create an option value
			my $ov_obj = OptionValue->new;
			$ov_obj->set('Option_ID', $option_id);
			$ov_obj->set('Product_ID', $product_id);
			$ov_obj->set('Value', $str);
			$ov_obj->insert($dbh);
		}
		# mark the property as ignored so it will not be processed with all product's properties anymore
		$p_obj->set('Ignore', 1);
		$p_obj->update($dbh);
		
		# change the feature type from 'multiple' to the specified one
		$feature_obj->set("Type", $newtype);
		$feature_obj->update($dbh);
	}
	
	# check whether there is a filter: it must be disabled
	my $sql = "select * from `cscart_product_filter_descriptions` where `filter`='$hrname'";
	my @rows = ISoft::DB::do_query($dbh, sql=>$sql);
	if(@rows>0){
		open XX, '>>delete_filters.txt';
		print XX $hrname, "\n";
		close XX;
		print "$pname has a filter which must be deleted\n";
	}
	
	# report the feature to be altered
	open YY, '>>alter_features.txt';
	print YY "$hrname -> $newtype\n";
	close YY;
	
	$dbh->commit();
}

sub list_values {
	my $pname = shift;
	my $rows = ISoft::DB::do_query($dbh, sql=>"select distinct(`newValue`) from `Property` where `Name`='$pname'");
	print "$_->{newValue}\n" foreach @$rows;
}

