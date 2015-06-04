use strict;
use warnings;
use utf8;
use open qw(:std :utf8);

use XML::LibXML;

use Company2;
use DBHelper;
use Street;
use Town;
use Parsers;

# constants
our $main_office_code = 1;
our $atm_code = 5;
# end of constants





# clean up log files
open TEST, '>test.txt';
close TEST;

open BAD, '>export/badlist.txt';
close BAD;

# read the general list ob banks
open B, 'output/banks.iml' or die 'Can not rean bank list';
my @bank_list = <B>;
close B;


# create singletons
my $company_obj = Company2->new;
my $street_obj = Street->new;
my $town_obj = Town->new;

# create xml objects
my $atm_xml_dom = XML::LibXML::Document->new('1.0', 'UTF-8');
my $atm_xml_root = $atm_xml_dom->createElement('atm');
$atm_xml_dom->setDocumentElement($atm_xml_root);
my $atm_xml_items = $atm_xml_root->addNewChild(undef, 'item');

my $branch_xml_dom = XML::LibXML::Document->new('1.0', 'UTF-8');
my $branch_xml_root = $branch_xml_dom->createElement('branch');
$branch_xml_dom->setDocumentElement($branch_xml_root);
my $branch_xml_items = $branch_xml_root->addNewChild(undef, 'item');


# get database handler
my $dbh = DBHelper::get_dbh();


our $undefined_region_id = DBHelper::search_region($dbh, 'undefined')->{id};

# loop through banks
foreach my $bank_item (@bank_list) {
	
	chomp $bank_item;
	next unless $bank_item;

	# remove html entities
	$bank_item =~ s/&mdash;/-/g;
	$bank_item =~ s/&nbsp;/ /g;
	
	# extract data
	$bank_item =~ /<id>(\d+)<\/id>/;
	my $ext_bank_id = $1;
	
	
	
	$bank_item =~ /<short_name>(.*?)<\/short_name>/;
	my $bank_short_name = $1;
	
	$bank_item =~ /<full_name>(.*?)<\/full_name>/;
	my $bank_full_name = $1;

	$bank_item =~ /<license>(.*?)<\/license>/;
	my $bank_license = $1;
	
	my $company_id;
	my $transformed_name = Parsers::transform_full_company_name($bank_full_name);
	
	if($bank_license){
		
		unless( $company_id = $company_obj->get_id_by_license($dbh, $bank_license) ){
			$company_id = $company_obj->insert($dbh, $transformed_name, $bank_short_name, $bank_license);
		}
		
	} else {
		$company_id = $company_obj->insert($dbh, $transformed_name, $bank_short_name, 'null');
	}
	
	# we sure that the company now exists in our registry
	
	# load xml file, check whether there is any useful content
	# if not then we just skip the iteration
	
	my $content = '';
	open XML, "output/bank_$ext_bank_id.iml" or die "Can not load output/bank_$ext_bank_id";
	while (<XML>){
		chomp;
		$content .= $_;
	}	
	close XML;
	# normalize content

	$content =~ s/&amp;/&/g;
	$content =~ s/&nbsp;/ /g;
	$content =~ s/&mdash;/-/g;
	$content =~ s/<(\/|)nobr>//g;
	$content =~ s/&laquo;|&raquo;/"/g; #"
	
	next if $content =~ /<cities><\/cities/; # nothing to do here
	
	process_company_towns($dbh, $company_id, $content, $atm_xml_items, $branch_xml_items, $bank_full_name);
	
}


# finalize all objects here !!!!

$dbh->rollback(); # should me commit!!!!!!!!

$company_obj->flush('export/company_bank.sql');
$town_obj->flush('export/towns.sql');
$street_obj->flush('export/street.sql');
$atm_xml_dom->toFile('export/atm.xml', 1);
$branch_xml_dom->toFile('export/branch.xml', 1);










# -------------------------- functions -------------------------------

sub check_improve_address {
	my ($dbh, $addr_data, $region_id, $default_town_id) = @_;
	
	my $town_name = $addr_data->{town_name};
	my $town_type = $addr_data->{town_type};
	my $town_id;
	my $town_type_id;
	my $town_region_id;
	
	# check town
	if( $town_name ){
		# ищем в базе айдишку по названию и типу
		
		$town_type_id = $town_obj->get_type_id($dbh, $town_type);
		my $row = $town_obj->search($dbh, $town_name, $town_type_id);
		
		if ($row){
			# есть такой город
			$town_region_id = $row->{region_id};
			$town_id = $row->{id};
		} else {
			# города нет, делаем фантома
			$town_id = $town_obj->insert($dbh, $town_name, $town_type_id, $region_id);
			$town_region_id = $region_id;
		}
		
	} else {
		# если города нет то пытаемся восстановить по таблице
		foreach my $xx (@{ $addr_data->{unknown} }){
			my $row = $town_obj->search($dbh, $xx);
			if ($row){
				$town_id = $row->{id};
				$town_name = $xx;
				$town_region_id = $row->{region_id};
				$town_type_id = $row->{class_town_id};
				last;
			}
		}
	}
	
	if ( !$town_id ){
		# города по-прежнему нет, проверяем дефолтный
		return 0 if !$default_town_id;
		my $row = $town_obj->get_by_id($dbh, $default_town_id);
		$town_id = $row->{id};
		$town_region_id = $row->{region_id};
		$town_type_id = $row->{class_town_id};
	}

	
	my $street_name = $addr_data->{street_name};
	my $street_type = $addr_data->{street_type};
	my $street_type_id;
	my $street_id;
	
	if( $street_name ){
		# ищем в базе айдишку по названию типу
		$street_type_id = $street_obj->get_type_id($dbh, $street_type);
		my $row = $street_obj->search_by_name_type($dbh, $street_name, $street_type_id);
		if ($row){
			# есть такая улица
			$street_id = $row->{id};
		} else {
			# улицы нет, делаем фантома
			$street_id = $street_obj->insert($dbh, $street_name, $street_type_id);
		}

	} else {
		# если улицы нет то пытаемся восстановить по таблице
		foreach my $xx (@{ $addr_data->{unknown} }){
			my $row = $street_obj->search_by_name($dbh, $xx);
			if ($row){
				$street_id = $row->{id};
				$street_name = $xx;
				$street_type_id = $row->{class_street_id};
				last;
			}
		}
	}
	
	# does the street exist?
	return 0 unless $street_id;
	
	# check house
	return 0 if ( !$addr_data->{house} && !$addr_data->{build} && !$addr_data->{block} );
	
	# update address data
	
	$addr_data->{town_id} = $town_id;
	$addr_data->{town_type_id} = $town_type_id;
	$addr_data->{town_region_id} = $town_id;
	$addr_data->{town_id} = $town_region_id;
	
	$addr_data->{street_id} = $street_id;
	$addr_data->{street_type_id} = $street_type_id;
	
	return 1;
}

# extracts brances and atm from a town data
sub process_town {
	my ($dbh, $town_data, $branch_list_ref, $atm_list_ref, $region_id, $default_town_id, $bank_full_name) = @_;
	
	my $central_office_town = $town_data =~ /<strong>Головной офис<\/strong>/;

	# process the city branches
	while ( $town_data =~ /<branch[^>]+>(.*?)<\/branch>/g )
	{
		my $branch_data = $1;
		
		# get code and name of the object
		my ($object_code, $object_name) = get_code_name($branch_data, $central_office_town);
		
		# get address
		my $addr_data;
		my $addr_str = '';
		if ( $branch_data =~ /<span style="color: #888888; font-size: 90%"><strong>Адрес:<\/strong>(.*?)(<strong>|<br \/>|<\/span>)/ ) {
			$addr_str = $1;
			$addr_data = Parsers::get_address($addr_str);
		} else {
			print "No address!!!\n";
			next;
		}
		
		# check and improve the address
		my $ok = check_improve_address($dbh, $addr_data, $region_id, $default_town_id); 
		if (!$ok){
			# log the wrong item
			open BAD, '>>export/badlist.txt';
			print BAD "$bank_full_name\n$object_name\n$addr_str\n\n";
			close BAD;
			next;
		}
		
		if($object_code == $atm_code){

			my $work_time = [];
			if ( $branch_data =~ /<strong>(Режим работы|Обслуживание физических лиц):<\/strong>(.*?)(<\/span>|<strong>)/ ){
				my $time_data = lc $2;
				$work_time = Parsers::get_work_time($time_data);
			}

			my $money_list = [];
			my @money;
			if ( $branch_data =~ />Валюта:\s([^<.]+)[<.]/ ){
				my $money_str = $1;
				$money_list = Parsers::get_money_items($money_str);
				if (@$money_list>0){
					foreach my $currency (@$money_list){
						push @money, DBHelper::get_currency_id_by_name($dbh, $currency);
					}
				}
			}

			push @$atm_list_ref, {
				name => $object_name,
				address => $addr_data,
				cash_recieve => Parsers::takes_cash($branch_data),
				service_payment => Parsers::takes_payments($branch_data),
				timetable => $work_time,
				money => \@money,
			};
			
		} else {

			push @$branch_list_ref, {
				name => $object_name,
				type => $object_code,
				address => $addr_data,
				object_code => $object_code,
			};
			
		}
		
	}
	
}


# parses full company data
sub process_company_towns {
	my ($dbh, $company_id, $content, $atm_xml_items, $branch_xml_items, $bank_full_name) = @_;

	# prepare containers
	
	my @branch_list;
	my @atm_list;

	
	# get cities
	while ( $content =~ /<city .*?name='([^']+)'>(.*?)<\/city>/g  ) #'
	{
		my $town_name = $1;
		my $town_id = 0;
		my $town_data = $2;
		
		my $region_name = Parsers::extract_region($town_name);
		my $region_id;

		if($region_name){
			my $row = DBHelper::search_region($dbh, $region_name) or die "No region $region_name";
			$region_id = $row->{id};
		} else {
			# search the town
			# it is possible that the town name has a prefix. it makes sense to parse it.
			my ($tname, $ttype) = Parsers::extract_town_and_type($town_name);
			my $pattern = $tname ? $tname : $town_name;
			if ( my $town_row = $town_obj->search($dbh, $pattern) ){
				# found the parent town
				$region_id = $town_row->{region_id};
				$town_name = $pattern;
				$town_id = $town_row->{id};
			} else {
				# parent town was not found
				$ttype = $ttype || 'город';
				my $ttype_id = $town_obj->get_type_id($dbh, $ttype) || 1; # unknown type?
				# insert the town
				$town_id = $town_obj->insert($dbh, $pattern, $ttype_id, $undefined_region_id); # no region, let's use an undefined one
				$region_id = $undefined_region_id;
			}
		}

		# process a town (get items)

		process_town($dbh, $town_data, \@branch_list, \@atm_list, $region_id, $town_id, $bank_full_name);
		
	}
	
	# all towns have been processed, let's populate XML

	# --- branches
	
	if (@branch_list > 0){
		$branch_xml_items->addNewChild(undef, 'company_id')->appendText($company_id);
		my $company_items = $branch_xml_items->addNewChild(undef, 'param');
		
		foreach my $branch (@branch_list){
			
			my $item = $company_items->addNewChild(undef, 'item');
			$item->addNewChild(undef, 'name')->appendText( $branch->{name} );
			
			my $office_item = $item->addNewChild(undef, 'office')->addNewChild(undef, 'item');
			$office_item->addNewChild(undef, 'name')->appendText( $branch->{name} );
			
			$office_item->addNewChild(undef, 'addr_type_id')->appendText( $branch->{object_code} );
			
			# address
			generate_address_xml($branch->{address}, $office_item);
			
		}
		
	}
	
	# ----- ATM
	
	if (@atm_list > 0){
		$atm_xml_items->addNewChild(undef, 'company_id')->appendText($company_id);
		my $company_items = $atm_xml_items->addNewChild(undef, 'param');
		
		foreach my $atm (@atm_list){
			
			my $item = $company_items->addNewChild(undef, 'item');
			$item->addNewChild(undef, 'name')->appendText( $atm->{name} );
			
			# address
			generate_address_xml($atm->{address}, $item);
			
			# cash_recieve
			$item->addNewChild(undef, 'cash_recieve')->appendText( $atm->{cash_recieve} );
			
			# service payment
			$item->addNewChild(undef, 'service_payment')->appendText( $atm->{service_payment} );
			
			# timetable
			generate_time_table($atm->{timetable}, $item);
			
			# currencies
			generate_money($atm->{money}, $item);
			
		}
		
	}

}

sub generate_money {
	my ($money, $node) = @_;
	
	my $mnode = $node->addNewChild(undef, 'money');
	foreach my $id (@$money){
		$mnode->addNewChild(undef, 'item')->addNewChild(undef, 'currency_id')->appendText($id);
	}
	
}

sub generate_time_table {
	my ($timetable, $node) = @_;
	
	# process the timetable
	
	my $table_node = $node->addNewChild(undef, 'timetable');
	
	foreach my $time_item (@$timetable){
		next unless $time_item->{normal};
		my $table_item = $table_node->addNewChild(undef, 'item');
		$table_item->addNewChild(undef, 'day_begin')->appendText( $time_item->{start_day} );
		$table_item->addNewChild(undef, 'day_end')->appendText( $time_item->{end_day} );
		$table_item->addNewChild(undef, 'time_begin')->appendText( $time_item->{start_time} );
		$table_item->addNewChild(undef, 'time_end')->appendText( $time_item->{end_time} );
	}
	
}

sub generate_address_xml {
	my ($addr_data, $node) = @_;
	
	$node->addNewChild(undef, 'country_id')->appendText('1');
	$node->addNewChild(undef, 'region_id')->appendText( $addr_data->{town_region_id} );
	
	$node->addNewChild(undef, 'town_id')->appendText( $addr_data->{town_id} );
	$node->addNewChild(undef, 'class_town_id')->appendText( $addr_data->{town_type_id} );
	
	$node->addNewChild(undef, 'street_id')->appendText( $addr_data->{street_id} );
	$node->addNewChild(undef, 'class_street_id')->appendText( $addr_data->{street_type_id} );
	
	$node->addNewChild(undef, 'house')->appendText( $addr_data->{house} );
	$node->addNewChild(undef, 'block')->appendText( $addr_data->{block} );
	$node->addNewChild(undef, 'build')->appendText( $addr_data->{build} );
	$node->addNewChild(undef, 'char')->appendText( $addr_data->{char} );
	
}


# logger
sub test {
	my $text = shift;
	open TEST, '>>test.txt';
	print TEST "$text\n";
	close TEST;
}

# returns array containing two items type code and name.
# codes:
# 1 - Центральный офис (main_office_code)
# 2 - Филиал
# 3 - Отделение
# 5 - Банкомат (atm_code)
sub get_code_name {
	my ($data, $central_office_city) = @_;
	
	my $code = '';
	my $name = '';
	
	if ( $data =~ /<a href="[^"]+" style="text-decoration: none; color: #333"><strong>([^<]+)<\/strong><\/a>/ )#"
	{
		$name = $1;
		# get code
		if ( $name =~ /^Головной офис/ ){
			$code = $main_office_code;
		} elsif ( $name =~ /^Банкомат/ ){
			$code = $atm_code;
		} elsif ( $central_office_city ){
			$code = 3;
		}	else {
			# default
			$code = 2;
		}
	}
	return ($code, $name);
}
