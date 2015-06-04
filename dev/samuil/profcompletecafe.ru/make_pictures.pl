use strict;
use warnings;

# common libraries
use File::Copy;
use File::Path;

use lib ("/work/perl_lib", "local_lib");

# personal libraries
use ISoft::Conf;
use ISoft::DB;

use ISoft::ParseEngine::Member::File::CategoryPicture;
use ISoft::ParseEngine::Member::File::ProductDescriptionPicture;
use ISoft::ParseEngine::Member::File::ProductPicture;


my $dbh = get_dbh();

convert_category_pictures($dbh);
convert_product_pictres($dbh);

copy_description_pictures($dbh);


$dbh->rollback();
$dbh->disconnect();

print "\nAll pictures were processed\n";

exit;


# ---------------- FUNCTIONS ----------------

sub prepare_storage {
	my ($path) = @_;
	
	my $fullpath = "output_files/$path";
	if(!-e $fullpath && !-d $fullpath){
		mkpath($fullpath);
	}
	
	return $fullpath;
}

sub convert_category_pictures {
	my ($dbh) = @_;
	
	my $instance = ISoft::ParseEngine::Member::File::CategoryPicture->new();
	
	my $output_path = prepare_storage('cats_products');
	$output_path =~ s#/#\\#g;
	
	my $updated = 0;
	
	my @piclist = $instance->selectAll($dbh);
	foreach my $pic_obj (@piclist){
		my $id = $pic_obj->ID;
		my $name = sprintf('pccf_cat_%05d', $id);
		my $org_path = $pic_obj->getStoragePath();
		$org_path =~ s#/#\\#g;
		my $output_name = "$output_path\\$name.jpg";
		if(do_convert($org_path, "-resize", '"100x100>"', $output_name)){
			print "Converted $output_name\n";
		} else {
			$pic_obj->markFailed();
			$pic_obj->update($dbh);
			$updated = 1;
		}
	}
	$dbh->commit() if $updated;
}

sub convert_product_pictres {
	my ($dbh) = @_;
	
	my $instance = ISoft::ParseEngine::Member::File::ProductPicture->new();
	
	my $output_path = prepare_storage('cats_products');
	$output_path =~ s#/#\\#g;
	
	my $updated = 0;
	
	my @piclist = $instance->selectAll($dbh);
	foreach my $pic_obj (@piclist){
		my $id = $pic_obj->ID;
		
		my $org_name  = sprintf('pccf_org_%05d', $id);
		my $th_name   = sprintf('pccf_th_%05d', $id);
		my $info_name = sprintf('pccf_info_%05d', $id);
		
		my $org_path = $pic_obj->getStoragePath();
		$org_path =~ s#/#\\#g;

		my $output_name_org  = "$output_path\\$org_name.jpg";
		my $output_name_th   = "$output_path\\$th_name.jpg";
		my $output_name_info = "$output_path\\$info_name.jpg";
		
		if(do_convert($org_path, $output_name_org)){
			# the first picture was converted so we don't need checking other operations
			do_convert($org_path, "-resize", '"150x200>"', $output_name_th);
			do_convert($org_path, "-resize", '"300x400>"', $output_name_info);
			print "Converted $output_name_org\n";
		} else {
			$pic_obj->markFailed();
			$pic_obj->update($dbh);
			$updated = 1;
		}
	}
	$dbh->commit() if $updated;
	
}

sub copy_description_pictures {
	my ($dbh) = @_;

	my $instance = ISoft::ParseEngine::Member::File::ProductDescriptionPicture->new();
	
	my $output_path = prepare_storage('supplementary_pictures/pccf');
	
	my $updated = 0;
	
	my @piclist = $instance->selectAll($dbh);
	foreach my $pic_obj (@piclist){
		my $md5 = $pic_obj->getMD5Name();
		my $output_name = "$output_path/$md5";
		if(-e $output_name){
			print "Skipped $md5\n";
		} else {
			copy($pic_obj->getStoragePath(), $output_name);
			print "Copied $md5\n";
		}
		
	}
	
}

sub get_dbh {
	return ISoft::DB::get_dbh_mysql(
		$constants{Database}{DB_Name},
		$constants{Database}{DB_User},
		$constants{Database}{DB_Password},
		$constants{Database}{DB_Host}
	);
}

sub do_convert {
	
	unless (system("c:\\work\\im\\convert.exe", @_)==0){
		return 0;
	}
	
	return 1;
}


