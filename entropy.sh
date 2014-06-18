#!/usr/bin/perl

use Cwd;
use Data::Dumper;

# REPOS="core_consolidated media_service browser_plugins voip ba_service auth_service" 

# 6.13 -> 5.4
# 6.15 -> 5.0
# 6.16 -> 3.2

%repos = (
  core_consolidated =>  {
    6.12 => "rt-6.11.4..rt-6.12.1.1",
    6.13 => "rt-6.12.1.1..rt-6.13.0.8",
    6.14 => "rt-6.13.0.8..rt-6.14.1",
    6.15 => "rt-6.14.1..rt-6.15.0.9",
    6.16 => "rt-6.15.0.9..rt-6.16.1",
    6.17 => "rt-6.16.1..origin/release_6.17",
    now => "origin/release_6.17..master" },
  media_service => {
    6.13 => "rt-6.13.0..rt-6.11",
    6.16 => "rt-6.13.0..rt-6.16.0.0",
    now => "rt-6.16.0.0..master" },
  auth_service => {
    6.12 => "rt-6.12..rt-6.13.0",
    6.16 => "rt-6.13.0..rt-6.16.0.0",
    6.17 => "rt-6.16.0.0..origin/release_6.17" ,
    now => "origin/release_6.17..master" },
  ba_service => {
    6.15 => "rt-6.14.0..rt-6.15.0.3",
    6.16 =>"rt-6.16.0.0..rt-6.15.0.3",
    now => "rt-6.16.0.0..master" },
#voip => {
#"origin/alpha..master" },
  browser_plugins => {
    6.16 => "rt-6.13.25..rt-6.16.0.0",
    now => "rt-6.16.0.0..master" }
);

%a_repos = (
  core_consolidated => {
    6.15 => "rt-6.15.0.9..rt-6.16.1",
    6.16 => "rt-6.16.1..origin/release_6.17"}
);


for $repo ( keys %repos ) {
  $path = "$ENV{'HOME'}/src/$repo";
  chdir "$path" || die "Couldn't change to $path: $!\n";
  $cwd = getcwd();
  print "STATS FOR $cwd\n";
  system("git fetch") == 0 or die "Couldn't fetch $?\n";
  system("git pull origin master") == 0 or die "Couldn't pull $?\n";
  foreach my $version ( keys %{ $repos{$repo} } )  {
    my $added;
    my $deleted;
    my $files;
#print "$version --> ";
#system("git diff $version --stat --ignore-space-change \| grep deletion") == 0 or die "Couldn't diff $?\n";
    @diff = ( "git", "diff", $repos{$repo}{$version}, "--numstat", "--ignore-space-change" );
    open(my $OUT, '-|', @diff) or die "$!\n";
    while (<$OUT>) {
      chomp();
# 11      3       build.gradle
      if (/^(\d*)\s*(\d*)\s*(\S*)/) {
        $added += $1;
        $deleted += $2;
        ++$files{$3};
# print "OUTPUT : $added $deleted $files\n";
      }


    }

    $results{$version}{added} += $added;
    $results{$version}{deleted} += $deleted;
    $results{$version}{file_count} += scalar (keys %files);

    print "$repo -> Added $added, Deleted $deleted, File Count " . scalar (keys %files) . "\n";
    close $OUT;
  }
}

print "version,num_lines_added,num_lines_delted,num_files_changed\n";
foreach $v (sort keys %results) {
  print "$v,$results{$v}{added},$results{$v}{deleted},$results{$v}{file_count}\n";
}
