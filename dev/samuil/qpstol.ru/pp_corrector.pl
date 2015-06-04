use strict;
use warnings;


use File::Copy;
use File::Path;

use lib ("/work/perl_lib", "local_lib");


use ISoft::DBHelper;

use AssemblyManual;
use Category;
use Product;
use ProductPicture;


our $files = 'files';
our $prodpictures = $files . '/' . 'productpictures';
our $pp_backup = $files . '/' . 'pp_backup';

our $output_dir = $files . '/' . 'output';
our $cp_dir = $output_dir . '/' . 'cats_products';

our $supplementary = $output_dir . '/' . 'supplementary_pictures/qps';


# step 1
# restore product picture extensions
#restore_extensions();


# step 2
# after that the images were reviewed there are only images without watermarks
# let's go through all products and investigate what kind of images exists
print "Step 2\n";
check_product_images();

# step 3
# ok, all existing product images are correct, let's convert and resize!
# don't forgot the category pictures too...
print "Step 3-1\n";
convert_resize_cat();
print "Step 3-2\n";
convert_resize_prod();

# step 4
# description pictures and assembly manuals
print "Step 4\n";
copy_description_files();






print "Done\n";

exit;

# ----------------------------------

sub copy_description_files {
	
	my $dbh = get_dbh();

	my $instance = ISoft::ParseEngine::Member::File::ProductDescriptionPicture->new();
	
	prepare_storage($supplementary);
	
	my @piclist = $instance->selectAll($dbh);
	my @asm_list = AssemblyManual->new()->selectAll($dbh);
	push @piclist, @asm_list;
	
	foreach my $pic_obj (@piclist){
		my $md5 = $pic_obj->getMD5Name();
		my $output_name = "$supplementary/$md5";
		if(-e $output_name){
			print "Skipped $md5\n";
		} else {
			copy($pic_obj->getStoragePath(), $output_name);
			print "Copied $md5\n";
		}
		
	}
	
	release_dbh($dbh);
}

sub convert_resize_prod {
	my $dbh = get_dbh();
	
	prepare_storage($cp_dir);
	
	# product pictures
	my @prodlist = Product->new()->selectAll($dbh);
	foreach my $prod_obj (@prodlist){
		my $status = $prod_obj->get('Status');
		my @types;
		if($status == $prod_obj->STATUS_NORMAL_PICTURE){
			push @types, ProductPicture::TYPE_NORMAL;
		} else {
			push @types, ProductPicture::TYPE_ASIS;
		}
		push @types, ProductPicture::TYPE_COLOR;
		my $tmp_pic_obj = ProductPicture->new;
		$tmp_pic_obj->set('Product_ID', $prod_obj->ID);
		$tmp_pic_obj->set('Type', \@types);
		
		my @piclist = $tmp_pic_obj->listSelect($dbh);
		
		foreach my $pic_obj (@piclist){
			
			my $id = $pic_obj->ID;
			
			my $org_name  = sprintf('qps_org_%05d', $id);
			my $th_name   = sprintf('qps_th_%05d', $id);
			my $info_name = sprintf('qps_info_%05d', $id);
			
			my $org_path = $pp_backup . '/' . $id;
			$org_path =~ s#/#\\#g;
			
			my $output_path = $cp_dir;
			$output_path =~ s#/#\\#g;
			
			my $output_name_org  = "$output_path\\$org_name.jpg";
			my $output_name_th   = "$output_path\\$th_name.jpg";
			my $output_name_info = "$output_path\\$info_name.jpg";
			
			if(do_convert($org_path, $output_name_org)){
				# the first picture was converted so we don't need checking other operations
				do_convert($org_path, "-resize", '"150x200>"', $output_name_th);
				do_convert($org_path, "-resize", '"300x400>"', $output_name_info);
			} else {
				print "Conversion failed: $id\n";
			}
			
		}
		
	}
	
	release_dbh($dbh);
}

sub convert_resize_cat {
	my $dbh = get_dbh();
	
	prepare_storage($cp_dir);
	
	# category pictures
	my @cplist = Category->new()->newCategoryPicture()->selectAll($dbh);
	my $updated = 0;
	foreach my $pic_obj (@cplist){
		my $id = $pic_obj->ID;
		my $name = sprintf('qps_cat_%05d', $id);
		my $org_path = $pic_obj->getStoragePath();
		$org_path =~ s#/#\\#g;
		
		my $output_name = "$cp_dir\\$name.jpg";
		$output_name =~ s#/#\\#g;
		
		if(!do_convert($org_path, "-resize", '"100x100>"', $output_name)){
			print "Failed $id\n";
			$pic_obj->markFailed();
			$pic_obj->update($dbh);
			$updated = 1;
		}
	}
	$dbh->commit() if $updated;
	
	release_dbh($dbh);
}

sub check_product_images {
	
	my $dbh = get_dbh();
	
	my @products = Product->new()->selectAll($dbh);
	
	foreach my $product(@products){
		
		my @pictures = $product->getProductPictures($dbh);
		
		my $normal = 0;
		my $asis = 0;
		my $color = 0;
		foreach my $pic_obj (@pictures){
			my $name = $pic_obj->getOrgName();
			my $pathname = $prodpictures . '/' . $name;
			my $sp = $pic_obj->getStoragePath();
			if(-e $pathname){
				my $type = $pic_obj->get('Type');
				if($type == $pic_obj->TYPE_NORMAL){
					$normal = 1;
				} elsif($type == $pic_obj->TYPE_ASIS){
					$asis = 1;
				} elsif($type == $pic_obj->TYPE_COLOR){
					$color = 1;
				}
			} else {
				# no file, delete!
				$pic_obj->delete($dbh);
				print "Deleted ", $pic_obj->ID, "\n";
			}
		}

		if($normal){
			$product->set('Status', $product->STATUS_NORMAL_PICTURE);
		} else {
			$product->set('Status', $product->STATUS_ASIS_PICTURE);
		}
		$product->update($dbh);

	}
	
	$dbh->commit();
		
	release_dbh($dbh);
}

sub restore_extensions {
	
	my $dbh = get_dbh();
	
	my @piclist = ProductPicture->new()->selectAll($dbh);
	
	release_dbh($dbh);
	
	foreach my $pic_obj (@piclist){
		
		my $name = $pic_obj->getOrgName();
		
		my $pathname = $prodpictures . '/' . $name;
		my $sp = $pic_obj->getStoragePath();
		if(-e $pathname){
			print "$pathname already exists\n";
		} else {
			copy($sp, $pathname);
		}
		unlink $sp;
	}
	
	
	
}

sub prepare_storage {
	my ($path) = @_;
	if(!-e $path && !-d $path){
		mkpath($path);
	}
}

sub do_convert {
	unless (system("c:\\work\\im\\convert.exe", @_)==0){
		return 0;
	}
	return 1;
}

