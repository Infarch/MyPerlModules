use strict;
use warnings;

use SimpleConfig;
use Utils;

use FilterEntry;

# load data
my @strings;
Utils::load_lines($constants{Filter}{Source}, \@strings);

# load word list
my @wordlist;
my $checkwords;
if(-e $constants{Filter}{WordList}){
	Utils::load_lines($constants{Filter}{WordList}, \@wordlist);
	$checkwords = @wordlist>0;
}

# make objects
my %stop_domain;
my @entries;
foreach my $string (@strings){
	
	# create object
	my $entry = FilterEntry->new($string);
	
	if($entry->domainLevel()==2 && $entry->justDomain()){
		# this entry should block other entries at the same domain
		$stop_domain{$entry->getDomain()} = 1;
	}
	
	push @entries, $entry;
}


my %reg_subs;
my %reg_files;

my @list_ok;
my @list_bad;

# loop through the object list, filter it
foreach my $entry (@entries){
	
	my $domain_full = $entry->getDomain();
	my $domain_short = $entry->getDomain(2);
	my $just_domain = $entry->justDomain();
	my $level = $entry->domainLevel();
	
	my $ok;
	
	if (exists $stop_domain{$domain_full}){
		# block - do nothing
	} else {
		if($level > 2){
			# has a sub.
			unless( exists $reg_subs{$domain_short} ){
				$reg_subs{$domain_short} = 1;
				$ok = 1;
			}
		} else {
			# look for file at the same level two
			unless( exists $reg_files{$domain_short} ){
				$reg_files{$domain_short} = 1;
				$ok = 1;
			}
		}
	}
	
	if($ok){
		push @list_ok, $entry->getRaw();
	} else {
		push @list_bad, $entry->getRaw();
	}
	
}

# save data
Utils::save_lines($constants{Filter}{FilterOk}, \@list_ok);
Utils::save_lines($constants{Filter}{FilterFailed}, \@list_bad);

