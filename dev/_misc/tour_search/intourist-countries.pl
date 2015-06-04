use strict;
use warnings;

use utf8;

use YAML 'Dump';


my $text = <<END_OF_DOC;
<option value="13-73">Австрия - Вена</option><option value="13-161">Австрия - Зальцбург</option><option value="30-375">Бельгия - Брюссель</option><option value="57-319">Болгария - все регионы</option><option value="21-305">Великобритания - Глазгоу</option><option value="21-304">Великобритания - Инвернесс</option><option value="21-302">Великобритания - Лидс</option><option value="21-109">Великобритания - Лондон</option><option value="21-303">Великобритания - Эдинбург</option><option value="21-433">Великобритания - Экскурсионный пакет</option><option value="19-87">Венгрия - Будапешт</option><option value="19-417">Венгрия - Бюкфюрдё</option><option value="19-333">Венгрия - Тапольца</option><option value="19-471">Венгрия - Хайдусобосло</option><option value="19-326">Венгрия - Хевиз</option><option value="19-416">Венгрия - Шарвар</option><option value="19-420">Венгрия - Экскурсионный пакет</option><option value="12-335">Германия - Берлин</option><option value="12-437">Германия - Висбаден</option><option value="12-419">Германия - Гамбург</option><option value="12-336">Германия - Дюссельдорф</option><option value="12-337">Германия - Кельн</option><option value="12-68">Германия - Мюнхен</option><option value="12-72">Германия - Нюрнберг</option><option value="12-345">Германия - Франкфурт-на-Майне</option><option value="12-346">Германия - Экскурсионный пакет</option><option value="10-62">Греция - Крит</option><option value="10-59">Греция - Родос</option><option value="7-102">Египет - Хургада</option><option value="7-26">Египет - Шарм эль Шейх</option><option value="52-434">Израиль - Все регионы</option><option value="52-392">Израиль - Каскады</option><option value="52-388">Израиль - Мертвое море</option><option value="52-390">Израиль - Нетания</option><option value="52-391">Израиль - Тель-Авив</option><option value="52-389">Израиль - Эйлат</option><option value="46-180">Индия - Гоа</option><option value="14-78">Испания - Барселона</option><option value="14-77">Испания - Коста Брава</option><option value="14-300">Испания - Коста дель Соль</option><option value="14-80">Испания - Коста Дорада</option><option value="14-177">Испания - Тенерифе</option><option value="14-218">Испания - экс. тур</option><option value="14-362">Испания - экскур. тур + отдых</option><option value="35-427">Италия - SPA / Термальные Курорты</option><option value="35-445">Италия - Искья</option><option value="35-444">Италия - Лидо ди Езоло (Венецианская Ривьера)</option><option value="35-399">Италия - Рим </option><option value="35-443">Италия - Римини (Адриатическое море)</option><option value="35-358">Италия - Сицилия</option><option value="35-356">Италия - Тирренское море</option><option value="35-467">Италия - Тоскана</option><option value="35-422">Италия - Шоппинг</option><option value="35-254">Италия - экскурсионный тур</option><option value="35-371">Италия - экскурсионный тур + отдых</option><option value="15-198">Кипр - Айя-Напа</option><option value="15-350">Кипр - Все регионы</option><option value="15-199">Кипр - Ларнака</option><option value="15-224">Кипр - Лимассол</option><option value="15-398">Кипр - Пафос</option><option value="41-212">Куба - Варадеро</option><option value="41-474">Куба - Гавана</option><option value="41-475">Куба - Кайо Санта Мария</option><option value="41-478">Куба - Комбинированные туры</option><option value="28-142">Латвия - Рига</option><option value="28-143">Латвия - Юрмала</option><option value="37-352">Мальта - Все регионы</option><option value="37-458">Мальта - экск.туры</option><option value="31-366">Нидерланды - Амстердам</option><option value="87-465">Норвегия - Круизы</option><option value="91-468">США - Все регионы</option><option value="6-156">Таиланд - Бангкок, Паттайя</option><option value="6-324">Таиланд - Ко Чанг</option><option value="6-155">Таиланд - Пхукет, Самуи</option><option value="58-245">Тунис - Монастир</option><option value="4-8">Турция - Анталия</option><option value="4-9">Турция - Мармарис</option><option value="24-413">Финляндия - все регионы</option><option value="24-393">Финляндия - Круизы</option><option value="17-451">Франция - Авиньон</option><option value="17-461">Франция - Диснейленд</option><option value="17-450">Франция - Марсель</option><option value="17-299">Франция - Ницца</option><option value="17-92">Франция - Париж</option><option value="17-462">Франция - Талассотерапия</option><option value="17-159">Франция - Тулуза</option><option value="17-166">Франция - Шамони</option><option value="53-351">Хорватия - Все регионы</option><option value="16-108">Чехия - Карловы Вары</option><option value="16-340">Чехия - Марианские Лазне</option><option value="16-89">Чехия - Прага</option><option value="36-169">Швейцария - Женева</option><option value="36-168">Швейцария - Цюрих</option><option value="77-446">Швеция - Круизы</option><option value="77-387">Швеция - Стокгольм</option><option value="27-431">Эстония - Круизы</option><option value="27-133">Эстония - Пярну</option><option value="27-473">Эстония - Раквере</option><option value="27-322">Эстония - Сааремаа</option><option value="27-454">Эстония - СПА туры</option><option value="27-453">Эстония - Таллин</option><option value="27-131">Эстония - Тарту</option><option value="27-472">Эстония - Хаапсалу</option>

<option value="7-102">Египет - Хургада</option><option value="7-26">Египет - Шарм эль Шейх</option><option value="6-156">Таиланд - Бангкок, Паттайя</option><option value="6-155">Таиланд - Пхукет, Самуи</option><option value="4-8">Турция - Анталия</option>

<option value="57-319">Болгария - все регионы</option><option value="21-109">Великобритания - Лондон</option><option value="10-62">Греция - Крит</option><option value="10-282">Греция - Салоники</option><option value="7-286">Египет - Дахаб</option><option value="7-102">Египет - Хургада</option><option value="7-26">Египет - Шарм эль Шейх</option><option value="7-288">Египет - Эль Гуна</option><option value="52-441">Израиль - Иерусалим</option><option value="52-392">Израиль - Каскады</option><option value="52-388">Израиль - Мертвое море</option><option value="52-391">Израиль - Тель-Авив</option><option value="52-389">Израиль - Эйлат</option><option value="46-220">Индия - Северный Гоа</option><option value="46-221">Индия - Центральный Гоа</option><option value="46-219">Индия - Южный Гоа</option><option value="14-77">Испания - Коста Брава</option><option value="14-80">Испания - Коста Дорада</option><option value="14-177">Испания - Тенерифе</option><option value="14-218">Испания - экс. тур</option><option value="14-362">Испания - экскур. тур + отдых</option><option value="55-205">ОАЭ - Дубай</option><option value="6-156">Таиланд - Бангкок, Паттайя</option><option value="6-324">Таиланд - Ко Чанг</option><option value="6-155">Таиланд - Пхукет, Самуи</option><option value="4-8">Турция - Анталия</option><option value="53-351">Хорватия - Все регионы</option>

<option value="13-73">Австрия - Вена</option><option value="7-102">Египет - Хургада</option><option value="7-26">Египет - Шарм эль Шейх</option><option value="4-8">Турция - Анталия</option>

<option value="7-102">Египет - Хургада</option><option value="46-180">Индия - Гоа</option><option value="6-156">Таиланд - Бангкок, Паттайя</option><option value="6-155">Таиланд - Пхукет, Самуи</option><option value="4-8">Турция - Анталия</option><option value="16-108">Чехия - Карловы Вары</option><option value="16-340">Чехия - Марианские Лазне</option><option value="16-89">Чехия - Прага</option>

<option value="7-286">Египет - Дахаб</option><option value="7-102">Египет - Хургада</option><option value="7-26">Египет - Шарм эль Шейх</option><option value="6-156">Таиланд - Бангкок, Паттайя</option><option value="6-155">Таиланд - Пхукет, Самуи</option><option value="4-8">Турция - Анталия</option>

<option value="13-73">Австрия - Вена</option><option value="7-102">Египет - Хургада</option><option value="7-26">Египет - Шарм эль Шейх</option><option value="6-156">Таиланд - Бангкок, Паттайя</option><option value="6-155">Таиланд - Пхукет, Самуи</option><option value="4-8">Турция - Анталия</option><option value="4-65">Турция - Бодрум</option><option value="4-9">Турция - Мармарис</option><option value="16-108">Чехия - Карловы Вары</option><option value="16-340">Чехия - Марианские Лазне</option><option value="16-89">Чехия - Прага</option>

<option value="7-286">Египет - Дахаб</option><option value="7-102">Египет - Хургада</option><option value="7-26">Египет - Шарм эль Шейх</option><option value="6-156">Таиланд - Бангкок, Паттайя</option><option value="6-155">Таиланд - Пхукет, Самуи</option><option value="4-8">Турция - Анталия</option>

<option value="6-156">Таиланд - Бангкок, Паттайя</option><option value="6-324">Таиланд - Ко Чанг</option><option value="6-155">Таиланд - Пхукет, Самуи</option><option value="4-8">Турция - Анталия</option><option value="4-65">Турция - Бодрум</option><option value="4-9">Турция - Мармарис</option><option value="4-64">Турция - Фетие</option>
END_OF_DOC

$text =~ s/\r|\n|\t//g;

my $count = 0;
my %data;
while ( $text =~ /<option value="([\d-]+)">(.+?) - (.+?)<\/option>/g ) #"
{
	my $id = $1;
	
	my $c = $2;
	my $r = $3;
	
	$data{'variants'}{'country'}{"$c - $r"} = $id;
}

$text = <<END_OF_DOC_c;
<select style="width: 98%;" class="select_searchtour" onchange="document.f1.action2.value='chgCity';document.f1.submit();" name="cmbCityFrom">
<option value="222">Cанкт-Петербург</option><option value="736">Алматы</option><option value="565">Екатеринбург</option><option value="1623">Краснодар</option><option value="483">Новосибирск</option><option value="539">Пермь</option><option value="494">Ростов-на-Дону</option><option value="541">Самара</option><option selected="" value="538">Челябинск</option></select>
END_OF_DOC_c

$text =~ s/\r|\n|\t//g;

while ( $text =~ /<option value="(\d+)">([^<]+)<\/option>/g ) #"
{
	my $id = $1;
	my $c = $2;
	
	$data{'variants'}{'city'}{$c} = $id;
}

$text = <<END_OF_DOC_c;
<option value="">--</option><option value="4">2*</option><option value="6">3*</option><option value="2">4*</option><option value="5">5*</option>
END_OF_DOC_c

$text =~ s/\r|\n|\t//g;

while ( $text =~ /<option value="(\d+)">(\d)\*<\/option>/g ) #"
{
	my $id = $1;
	my $c = $2;
	
	$data{'variants'}{'category'}{$c} = $id;
}

$data{'variants'}{'adult'}{1} = 1;
$data{'variants'}{'adult'}{2} = 0;
$data{'variants'}{'adult'}{3} = 2;
$data{'variants'}{'adult'}{4} = 7;


$data{'method'} = 'get';
$data{'search_url'} = 'http://spb.ntk-intourist.ru/searchtour.aspx';
$data{'submit_url'} = 'http://spb.ntk-intourist.ru/searchtour.aspx';
$data{'name'} = 'Intourist';
$data{'service'} = 'Search::Query::Intourist';

$data{mapping} = {
	city => 'cmbCityFrom',
	country => 'cmbCountry',
	region => undef, # prevents error
	hotel => 'hd_name',
	date => 'cmbDates',
	duration => 'cmbDuration',
	adult => 'cmbHROrder',
	flag_ticket => undef,
	flag_hotel => undef
};


open XX, '>encoding(UTF-8)', 'intourist.yaml';
print XX Dump(\%data);
close XX;
