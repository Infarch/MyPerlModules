package Parsers;

use strict;
use warnings;

use utf8;
use open qw(:std :utf8);


sub get_address {
	my ($addr_str) = @_;
	
	my $town_name = '';
	my $town_type = 'неопределен';
	
	my $street_name = '';
	my $street_type = '';
	
	my $zip = '';
	
	my $house = '';
	my $housechar = '';
	my $build = '';
	my $block = '';
	
	my $region = '';
	my $rn = '';
	my $pom = '';
	
	my @unknown;
	
	# remove the '(xxx)' sequences
	while ( $addr_str =~ /\( [^()]* \)/x ) {
		$addr_str =~ s/\( [^()]* \)//xg;
	}

	# first corrections
	$addr_str =~ s/\d{6}\W//; # zip
	$addr_str =~ s/\sобл\.\s/ обл., /;
	$addr_str =~ s/(\sул\.\s[^,]+,)/,$1/;
	
	
	my @addr_parts = split ',', $addr_str;
	
	foreach my $part (@addr_parts){
		# trim
		$part =~ s/^\s+//;
		$part =~ s/\s+$//;
		
		if(!$town_name){
			my ($xname, $xtype) = extract_town_and_type($part);
			if($xname){
				$town_name = $xname;
				$town_type = $xtype;
				next;
			}
		}
		
		my ($xname, $xtype) = (undef, undef);
		
		if(!$street_name){
			my ($xname, $xtype) = extract_street_and_type($part);
			if ($xname){
				$street_name = $xname;
				$street_type = $xtype;
				next;
			}
		}

		my $rx = extract_region($part);
		if ($rx){
			$region = $rx;
			next;
		}

		if ( $part =~ /^(\w+(-\w+|)\s+р-о?н\.?)$/ ){
			$rn = $1;
			
		} elsif ( $part =~ /^\d{5,}$/ ){
			$zip = $part;
			
		} elsif ( $part =~ /^мкр-н (.*)/ ){
			if (!$street_name){
				$street_name = $1;
				$street_type = 'микрорайон';
			}
			
		} elsif ( $part =~ /^мкр(н|)\.\s*(.*)/ ){
			if (!$street_name){
				$street_name = $2;
				$street_type = 'микрорайон';
			}

		} elsif ( $part =~ /^(.+?)\s+мкр-н$/ ){
			if (!$street_name){
				$street_name = $1;
				$street_type = 'микрорайон';
			}
		} elsif ( $part =~ /^(.+?)\s+мкрн\.?$/ ){
			if (!$street_name){
				$street_name = $1;
				$street_type = 'микрорайон';
			}
			
		} elsif ( $part =~ /^д\.\s?(.*)/ ){
			$house = $1;
		} elsif ( $part =~ /^вл\.\s(.*)/ ){
			$house = $1 if !$house;
		} elsif ( $part =~ /^д\s(.+)/ ){
			$house = $1;
		} elsif ( $part =~ /^дом\s(.+)/ ){
			$house = $1;
		} elsif ( $part =~ /^(\d+)$/ ){
			$house = $1;
		} elsif ( $part =~ /^(\d+)\/(.+)$/ ){
			$house = $1;
			$block = $2;
			
		} elsif ( $part =~ /^стр\.(\s|)(.*)/ ){
			$build = $2;
			
		} elsif ( $part =~ /^корп\.\s?(.*)/ ){
			$block = $1;
		} elsif ( $part =~ /^(кор|корп)[. ]*(.*)/ ){
			$block = $2;
			
		} elsif ( $part =~ /^литер\s(.*)/i ){
			$housechar = $1;
		} elsif ( $part =~ /^(лит|литер|литера)\.?\s?(.*)/i ){
			$housechar = $2;
			
		} elsif ( $part =~ /^(к|пом|помещ|помещение)\.?\s?(.*)/ ){
			$pom = $2;
			
		} else {
			push @unknown, $part
		}

	}
	
	# некоторые коррекции номера и буквы
	if ( $house && $house =~ /\D/ ){
		$house =~ s/&#8470;\s*//;
		if ( $house =~ /^(\d+)\/(.+)$/ ){
			$house = $1;
			$block = $2;
		} elsif ( $house =~ /^(\d+)(\D)$/ ){
			$house = $1;
			$housechar = $2;
		} elsif ( $house =~ /^(\d+)\s(\D)$/ ){
			$house = $1;
			$housechar = $2;
		} elsif ( $house =~ /^(\d+)\s*'(\D)'$/ ){
			$house = $1;
			$housechar = $2;
		} elsif ( $house =~ /^(\d+)\s*"(\D)"$/ ){
			$house = $1;
			$housechar = $2;
		} elsif ( $house =~ /^(\d+)-(.+)$/ ){
			$house = $1;
			$block = $2;
		} elsif ( $house =~ /^(\d+)\s(стр\.|корп\.|литер\s|лит\.)\s?(.+)$/ ){
			$house = $1;
			$block = $2;
		} elsif ( $house =~ /^(\d+)(\D)[\/-]/ ){
			$house = $1;
			$housechar = $2;
		} elsif ( $house =~ /^(\d+)$/ ){
			$house = $1;
		} else {
			# bad data
			$house = '';
		}
	}
	
	# trim again
	$street_name =~ s/^\s+//;
	$street_name =~ s/\s+$//;

	$street_name =~ s/"$//; #"
	$street_name =~ s/^"//; #"
	
	$town_name =~ s/^\s+//;
	$town_name =~ s/\s+$//;

	return {
		town_name => $town_name,
		town_type => $town_type,
	
		street_name => $street_name,
		street_type => $street_type,
	
		house => $house,
		char => $housechar,
		build => $build,
		block => $block,
		
		unknown => \@unknown
	};
}

sub transform_full_company_name {
	my $cn = shift;
	if ( $cn =~ /^(ООО|ОАО|ЗАО|OAO)\s/ )
	{
		my $xxx = $1;
		$cn =~ s/^\w\w\w\s*//; #"
		$cn =~ s/\s+$//;
		return "$cn($xxx)";
	} else {
		return $cn;
	}
}

sub extract_region {
	my $part = shift;

	if ( $part =~ /^(\w+(-\w+|)\s+обл\.?)$/ ){
		return "$1 область";
	} elsif ( $part =~ /^(\w+(-\w+|)\s+область\.?)$/ ){
		$part =~ s/\.$//;
		return $part;
	} elsif ( $part =~ /^(\w+(-\w+|)\s+край\.?)$/ ){
		$part =~ s/\.$//;
		return $part;
	}

	return '';
}

sub extract_street_and_type {
	my $part = shift;

	my $street_name = '';
	my $street_type = '';

	if ( $part =~ /^ул\.(.*)/ ){
		$street_name = $1;
		$street_type = 'улица';
	} elsif ( $part =~ /^\.ул\.\s(.*)/ ){
		$street_name = $1;
		$street_type = 'улица';
	} elsif ( $part =~ /^ул (.*)/ ){
		$street_name = $1;
		$street_type = 'улица';
	} elsif ( $part =~ /(.*? вал)$/ ){
		$street_name = $1;
		$street_type = 'улица';
	} elsif ( $part =~ /(.+?)\s+ул\.$/ ){
		$street_name = $1;
		$street_type = 'улица';
		
	} elsif ( $part =~ /(.*?) бул\.$/ ){
		$street_name = $1;
		$street_type = 'бульвар';
	} elsif ( $part =~ /(.*?) б-р\.?$/ ){
		$street_name = $1;
		$street_type = 'бульвар';
	} elsif ( $part =~ /^бул (.*)/ ){
		$street_name = $1;
		$street_type = 'бульвар';
	} elsif ( $part =~ /^б-р (.*)/ ){
		$street_name = $1;
		$street_type = 'бульвар';
	} elsif ( $part =~ /^бул\. (.*)/ ){
		$street_name = $1;
		$street_type = 'бульвар';
		
	} elsif ( $part =~ /(.*?) пр-т$/ ){
		$street_name = $1;
		$street_type = 'проспект';

	} elsif ( $part =~ /(.*?) пл\.$/ ){
		$street_name = $1;
		$street_type = 'площадь';

	} elsif ( $part =~ /(.*?) пер\.$/ ){
		$street_name = $1;
		$street_type = 'переулок';
	} elsif ( $part =~ /(.*?) пер$/ ){
		$street_name = $1;
		$street_type = 'переулок';
	} elsif ( $part =~ /^пер\. (.*)/ ){
		$street_name = $1;
		$street_type = 'переулок';

	} elsif ( $part =~ /(.*?) пр-д\.$/ ){
		$street_name = $1;
		$street_type = 'проезд';
	} elsif ( $part =~ /(.*?) пр-д$/ ){
		$street_name = $1;
		$street_type = 'проезд';

	} elsif ( $part =~ /(.*?) пр\.$/ ){
		$street_name = $1;
		$street_type = 'проспект';
	} elsif ( $part =~ /(.*?) пр-т\.$/ ){
		$street_name = $1;
		$street_type = 'проспект';
	} elsif ( $part =~ /^пр-т (.*)/ ){
		$street_name = $1;
		$street_type = 'проспект';
	} elsif ( $part =~ /^пр\. (.*)/ ){
		$street_name = $1;
		$street_type = 'проспект';

	} elsif ( $part =~ /(.*?) ш\.$/ ){
		$street_name = $1;
		$street_type = 'шоссе';
	} elsif ( $part =~ /^ш\. (.*)/ ){
		$street_name = $1;
		$street_type = 'шоссе';
	} elsif ( $part =~ /^(.*)\sш$/ ){
		$street_name = $1;
		$street_type = 'шоссе';

	} elsif ( $part =~ /^п\. (.*)/ ){
		$street_name = $1;
		$street_type = 'площадь';
	} elsif ( $part =~ /(.+?)\s+площадь$/ ){
		$street_name = $1;
		$street_type = 'площадь';
	} elsif ( $part =~ /^пл\. (.*)/ ){
		$street_name = $1;
		$street_type = 'площадь';

	} elsif ( $part =~ /^пр-д (.*)/ ){
		$street_name = $1;
		$street_type = 'проезд';

	} elsif ( $part =~ /^наб (.*)/ ){
		$street_name = $1;
		$street_type = 'набережная';
	} elsif ( $part =~ /^наб\. (.*)/ ){
		$street_name = $1;
		$street_type = 'набережная';
	} elsif ( $part =~ /(.*?) наб\.$/ ){
		$street_name = $1;
		$street_type = 'набережная';

	} elsif ( $part =~ /^(.+?)\s+переезд$/ ){
		$street_name = $1;
		$street_type = 'переезд';
	}

	return ($street_name, $street_type);
}

sub extract_town_and_type {
	my $part = shift;
	
	my $town_name = '';
	my $town_type = '';
	
	if ( $part =~ /^г\.(\s|)(.*)/ ){
		$town_name = $2;
		$town_type = 'город';
	} elsif ( $part =~ /^г\s(.*)/ ){
		$town_name = $1;
		$town_type = 'город';
	} elsif ( $part =~ /^г\. о\. (.*)/ ){
		$town_name = $1;
		$town_type = 'город';
	} elsif ( $part =~ /^пгт\.(\s|)(.*)/ ){
		$town_name = $2;
		$town_type = 'поселок городского типа';
	} elsif ( $part =~ /^свх\.\s(.*)/ ){
		$town_name = $1;
		$town_type = 'совхоз';
	} elsif ( $part =~ /^с\.(\s|)(.*)/ ){
		$town_name = $2;
		$town_type = 'село';
	} elsif ( $part =~ /^село\s(.*)/ ){
		$town_name = $1;
		$town_type = 'село';
	} elsif ( $part =~ /^сел\.\s(.*)/ ){
		$town_name = $1;
		$town_type = 'село';
	} elsif ( $part =~ /^пгт\.?\s?(.*)/ ){
		$town_name = $1;
		$town_type = 'поселок городского типа';
	} elsif ( $part =~ /^п\.\s?г\.\s?т\.\s?(.*)/ ){
		$town_name = $1;
		$town_type = 'поселок городского типа';
	} elsif ( $part =~ /^р\.\sп\.\s(.*)/ ){
		$town_name = $1;
		$town_type = 'поселок';
	} elsif ( $part =~ /^р\/п\s(.*)/ ){
		$town_name = $1;
		$town_type = 'поселок';
	} elsif ( $part =~ /^раб\.\sпос\.\s(.*)/ ){
		$town_name = $1;
		$town_type = 'поселок';
	} elsif ( $part =~ /^(рабочий\s|)пос\.(\s|)(.*)/ ){
		$town_name = $3;
		$town_type = 'поселок';
	} elsif ( $part =~ /^д\.\sп\.\s*(.*)/ ){
		$town_name = $1;
		$town_type = 'поселок';
	} elsif ( $part =~ /^д\/пs*(.*)/ ){
		$town_name = $1;
		$town_type = 'поселок';
	} elsif ( $part =~ /^п\.\s?(.*)/ ){
		$town_name = $1;
		$town_type = 'поселок';
	} elsif ( $part =~ /^пос\.\s?(.*)/ ){
		$town_name = $1;
		$town_type = 'поселок';
	} elsif ( $part =~ /^дер\.(\s|)(.*)/ ){
		$town_name = $2;
		$town_type = 'деревня';
	} elsif ( $part =~ /^деревня\s(.*)/ ){
		$town_name = $1;
		$town_type = 'деревня';
	} elsif ( $part =~ /^д\.\s(\D+)$/ && !$town_name){
		$town_name = $1;
		$town_type = 'деревня';
	} elsif ( $part =~ /^д\.(\D+)$/ && !$town_name){
		$town_name = $1;
		$town_type = 'деревня';
	} elsif ( $part =~ /^ст\.\s(.+)$/ ){
		$town_name = $1;
		$town_type = 'станция';
	} elsif ( $part =~ /^станция\s+(?!метро)(.+)$/ ){
		$town_name = $2;
		$town_type = 'станция';
	} elsif ( $part =~ /^д\s(\D+)$/ ){
		$town_name = $1;
		$town_type = 'деревня';
	} elsif ( $part =~ /^станица\s(.+)$/ ){
		$town_name = $1;
		$town_type = 'станица';
	}	
	
	# some errors hapen very often
	if ( $town_name =~ /[СC](\s|)анкт\W+Пет(е|)р(бург|убг)/i ){
		$town_name = 'Санкт-Петербург';
	}
	
	return ($town_name, $town_type);
}


sub takes_payments {
	my $branch_data = shift;
	my $ok = 0;
	if( $branch_data =~ /оплата услуг/i ){
		$ok = 1;
	}
	return $ok;
}

sub takes_cash {
	my $branch_data = shift;
	my $tc = 0;
	if( $branch_data =~ /С функцией приема наличных/i ){
		$tc = 1;
	} elsif ( $branch_data =~ /выдача\/прием наличных/i ){
		$tc = 1;
	} elsif ( $branch_data =~ /Банкомат с функциями снятия и внесения наличных/i ){
		$tc = 1;
	}
	return $tc;
}

sub get_money_items {
	my $money_data = shift;
	
	$money_data =~ s/\([^()]*\)//;
	
	my @parts = split ',', $money_data;
	
	my @result;
	
	foreach my $part (@parts) {
		
		$part =~ s/^\s+//;
		$part =~ s/\s+$//;
		
		if ($part =~ /рубли(\sРФ|)/i){
			$part = 'Российский рубль';
		} elsif ($part =~ /д[оа]ллары(\sСША|)/i){ # there is a misspelling
			$part = 'Доллар США';
		} elsif ($part eq 'евро'){
			$part = 'Евро';
		}
		
		push @result, $part;
		
	}
	
	return \@result;
}

sub day_number {
	my $day = shift;
	
	if($day eq 'пн' || $day eq 'понедельник'){
		return 1;
	} elsif($day eq 'вт' || $day eq 'вторник'){
		return 2;
	} elsif($day eq 'ср' || $day eq 'среда'){
		return 3;
	} elsif($day eq 'чт' || $day eq 'четверг'){
		return 4;
	} elsif($day eq 'пт' || $day eq 'пятница'){
		return 5;
	} elsif($day eq 'сб' || $day eq 'cб' || $day eq 'суббота'){
		return 6;
	} elsif($day eq 'вс' || $day eq 'воскресенье'){
		return 7;
	} else {
		die "Wrong day $day";
	}	
}

sub get_work_time {
	my ($time_data) = @_;
	
	# there might be different optons
	my @time_table;
	
	# split data
	my @parts = split /<br[^>]*>/, $time_data;
	my @other;
	my $stop = 0;
	foreach my $part (@parts){
		next if !$part || $part eq ' ';
		$part =~ s/^\s+//;
		$part =~ s/\s+$//;
		if($stop){
			push @other, $part;
		} elsif ( $part =~ /^(пн|вт|ср|чт|пт|сб|вс)\.?\s?[-–]\s?(пн|вт|ср|чт|пт|сб|вс)\.?:{0,2}\s?(\d\d)[:.](\d\d)\s?[-–]\s?(\d\d)[:.](\d\d)/ ){
			
			# пн.-пт.: 09:00-21:00
			# пн. - пт.: 10:00-20:00 
			# пн.-сб: 08:30-20:30 

			my $d1 = day_number($1);
			my $d2 = day_number($2);
			
			my $t1 = "$3:$4:00";
			my $t2 = "$5:$6:00";
			
			push @time_table, {
				normal => 1,
				start_day => $d1,
				start_time => $t1,
				end_day => $d2,
				end_time => $t2
			};
			
		} elsif ( $part =~ /^(пн|вт|ср|чт|пт|сб|cб|вс)\.?\s?:?\s(\d\d)[.:](\d\d)\s?[-–]\s?(\d\d)[.:](\d\d)/ ) {
			
			# сб.: 10:00-16:00
			# вс: 08:30-19:30
			# чт. 08:30-18:00
			
			my $d1 = day_number($1);

			my $t1 = "$2:$3:00";
			my $t2 = "$4:$5:00";

			push @time_table, {
				normal => 1,
				start_day => $d1,
				start_time => $t1,
				end_day => $d1,
				end_time => $t2
			};
			
		} elsif ( $part =~ /^(\d\d)[.:](\d\d)\s?[-–]\s?(\d\d)[.:](\d\d)$/ ) {
			
			# 10:00-16:00
			
			my $d1 = 1;
			my $d2 = 7;

			my $t1 = "$1:$2:00";
			my $t2 = "$3:$4:00";

			push @time_table, {
				normal => 1,
				start_day => $d1,
				start_time => $t1,
				end_day => $d2,
				end_time => $t2
			};
			
		} elsif ( $part =~ /^(пн|вт|ср|чт|пт|сб|вс)\.,\s?(пн|вт|ср|чт|пт|сб|вс)\.:\s(\d\d:\d\d)[-–](\d\d:\d\d)/ ) {
			
			# сб.,вс.: 10:00-16:00
			# сб., вс.: 09:00-17:00
			
			my $d1 = day_number($1);
			my $d2 = day_number($2);
			
			my $t1 = "$3:00";
			my $t2 = "$4:00";

			push @time_table, {
				normal => 1,
				start_day => $d1,
				start_time => $t1,
				end_day => $d1,
				end_time => $t2
			};
			push @time_table, {
				normal => 1,
				start_day => $d2,
				start_time => $t1,
				end_day => $d2,
				end_time => $t2
			};

			
		} elsif ( $part =~ /
			^(понедельник|вторник|среда|четверг|пятница|суббота|воскресенье)
			\s?[-–]\s?
			(понедельник|вторник|среда|четверг|пятница|суббота|воскресенье)
			:\s
			(\d\d)[.:](\d\d)\s?[-–]\s?(\d\d)[.:](\d\d)
			[.,;]\s?
			(понедельник|вторник|среда|четверг|пятница|суббота|воскресенье)
			:\s?
			(\d\d[.:]\d\d\s?[-–]\s?\d\d[.:]\d\d)\.?$
		/x ) {
			
			# понедельник-пятница: 09:00-19:00, суббота: 10:00-18:00.
			# понедельник-пятница: 08:20-18:00, суббота: 08:20-15:00.
			# понедельник - пятница: 09:00-19:30;суббота: 09:00-16:30.
			
			my $d1 = day_number($1);
			my $d2 = day_number($2);
			
			my $t1 = "$3:$4:00";
			my $t2 = "$5:$6:00";
			
			my $d3 = day_number($7);
			
			my $subtime = $8;
			
			$subtime =~ /(\d\d)[.:](\d\d)\s?[-–]\s?(\d\d)[.:](\d\d)/;
			my $t3 = "$1:$2:00";
			my $t4 = "$3:$4:00";

			push @time_table, {
				normal => 1,
				start_day => $d1,
				start_time => $t1,
				end_day => $d2,
				end_time => $t2
			};

			push @time_table, {
				normal => 1,
				start_day => $d3,
				start_time => $t3,
				end_day => $d3,
				end_time => $t4
			};
		
		} elsif ( $part =~ /
			^(понедельник|вторник|среда|четверг|пятница|суббота|воскресенье)
			\s?[-–]\s?
			(понедельник|вторник|среда|четверг|пятница|суббота|воскресенье)
			:\s
			(\d\d)[.:](\d\d)\s?[-–]\s?(\d\d)[.:](\d\d)\.?
		$/x ){
			# понедельник-пятница: 09:00-19:00.

			my $d1 = day_number($1);
			my $d2 = day_number($2);
			
			my $t1 = "$3:$4:00";
			my $t2 = "$5:$6:00";

			push @time_table, {
				normal => 1,
				start_day => $d1,
				start_time => $t1,
				end_day => $d2,
				end_time => $t2
			};
			
		} elsif ( $part =~ /
			^(понедельник|вторник|среда|четверг|пятница|суббота|воскресенье):\s
			(\d\d)[.:](\d\d)\s?[-–]\s?(\d\d)[.:](\d\d)\.?
		$/x ){
			# суббота: 09:00-17:00.

			my $d1 = day_number($1);
			
			my $t1 = "$2:$3:00";
			my $t2 = "$4:$5:00";

			push @time_table, {
				normal => 1,
				start_day => $d1,
				start_time => $t1,
				end_day => $d1,
				end_time => $t2
			};

		} elsif ( $part =~ /
			^(пн|вт|ср|чт|пт|сб|cб|вс).,\s
			(пн|вт|ср|чт|пт|сб|cб|вс).,\s
			(пн|вт|ср|чт|пт|сб|cб|вс).,\s
			(пн|вт|ср|чт|пт|сб|cб|вс).:\s
			(\d\d)[.:](\d\d)\s?[-–]\s?(\d\d)[.:](\d\d)
		/x ){
			# пн., вт., чт., вс.: 10:00-20:00

			my $d1 = day_number($1);
			my $d2 = day_number($2);
			my $d3 = day_number($3);
			my $d4 = day_number($4);

			my $t1 = "$5:$6:00";
			my $t2 = "$7:$8:00";

			push @time_table, {
				normal => 1,
				start_day => $d1,
				start_time => $t1,
				end_day => $d1,
				end_time => $t2
			};
			push @time_table, {
				normal => 1,
				start_day => $d2,
				start_time => $t1,
				end_day => $d2,
				end_time => $t2
			};
			push @time_table, {
				normal => 1,
				start_day => $d3,
				start_time => $t1,
				end_day => $d3,
				end_time => $t2
			};
			push @time_table, {
				normal => 1,
				start_day => $d4,
				start_time => $t1,
				end_day => $d4,
				end_time => $t2
			};

		} elsif ( $part =~ /
			^(пн|вт|ср|чт|пт|сб|cб|вс).,\s
			(пн|вт|ср|чт|пт|сб|cб|вс).,\s
			(пн|вт|ср|чт|пт|сб|cб|вс).:\s
			(\d\d)[.:](\d\d)\s?[-–]\s?(\d\d)[.:](\d\d)
		/x ){
			# пн., вт., вс.: 10:00-20:00

			my $d1 = day_number($1);
			my $d2 = day_number($2);
			my $d3 = day_number($3);

			my $t1 = "$4:$5:00";
			my $t2 = "$6:$7:00";
			
			push @time_table, {
				normal => 1,
				start_day => $d1,
				start_time => $t1,
				end_day => $d1,
				end_time => $t2
			};
			push @time_table, {
				normal => 1,
				start_day => $d2,
				start_time => $t1,
				end_day => $d2,
				end_time => $t2
			};
			push @time_table, {
				normal => 1,
				start_day => $d3,
				start_time => $t1,
				end_day => $d3,
				end_time => $t2
			};

		} elsif ( $part =~ /^круглосуточно\.?$/ ) {
			
			# круглосуточно

			push @time_table, {
				normal => 1,
				start_day => 1,
				start_time => '00:00:00',
				end_day => 7,
				end_time => '23:59:59'
			};
			
		} else {
			$stop = 1;
			push @other, $part;
		}
			
			
	}
	
	if (@other>0 && @time_table==0){
		push @time_table, {
			normal => 0,
			other => join ' ', @other
		};

	}

	return \@time_table;
		
}

# logger
sub test {
	my $text = shift;
	open TEST, '>>test.txt';
	print TEST "$text\n";
	close TEST;
}

1;
