use strict;
use warnings;

use open qw(:std :utf8);

use SimpleConfig;
use Utils;



# load domains
my @domains = load_lines($constants{General}{DomainFile}, not_empty=>1, unique=>1);

print scalar @domains, " domains\n";

# load folders

my @folders = load_lines($constants{General}{FolderFile}, not_empty=>1, unique=>1)
	unless $constants{General}{NoFolders};


print scalar @folders, " folders\n";

# generate list
my @collection;
my $counter = $constants{General}{FoldersPerDomain};
while($counter-- > 0 ) {
	foreach my $domain (@domains){
		if($constants{General}{NoFolders}){
			push @collection, "$domain/";
		} else {
			my $folder = shift @folders;
			die "Not enough folders" unless $folder;
			push @collection, "$domain/$folder";
		}
	}
}
if(@collection==0){
	die "No domain-folder pairs. Nothing to do\n";
}
save_lines($constants{General}{DomainFolderFile}, \@collection);

# save state of folders
save_lines($constants{General}{FolderFile}, \@folders)
	unless $constants{General}{NoFolders};


print "\n\n";