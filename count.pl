#!/opt/local/bin/perl -w

use strict;
use Cwd;

my %commits;
my %jiras;
my $file_mod_count=0;
my $line_del_count=0;
my $line_add_count=0;
my %authors;

my @repos = qw(auth_service deploy quicklauncher ba_service core_consolidated media_service cloud-proxy core_database voip);

foreach my $repo (@repos) {
  print "\nStarting on repo $repo\n";
  my $cwd = getcwd;
  chdir $repo;
  `git co master`;
  `git pull`;
  my @local_commits;
  push (@local_commits, `git log -p --since=31-12-2011 --before=1-1-2013`);
  foreach my $commit (@local_commits) {

    chomp($commit);

    # Get Jira Ticket IDs
    my ($jira_id) = $commit =~ /^\s*(\w*\-\d*)\:\ .*$/;
    if ($jira_id) {
      $jiras{$jira_id} = (); 
    }
    if ($commit =~ /^commit/) {
      (my $c) = $commit =~ /^commit\ (.*)/;
      $commits{$c} = ();
    }

    # Look at commit details to get file and line info
    if ($commit =~ /^---/) {
      $file_mod_count++;
    } elsif ($commit =~ /^-\s*/) {
      $line_del_count++;
    } elsif ($commit =~ /^\+\s*/) {
      $line_add_count++;
    } elsif ($commit =~ /^Author:/) {
      (my $author) = $commit =~ /^Author:\ (.*) \<.*/;
      $authors{$author} = ();
    } else {
      next;
    }
  }
  chdir $cwd;
}

my $author_count = scalar keys %authors;
my $commit_count = scalar keys %commits;

print keys (%jiras) . " Jira tickets\n";
print "Number of files modified: $file_mod_count\n";
print "Number of lines removed: $line_del_count\n";
print "Number of lines added: $line_add_count\n";
print "Difference: " . ($line_add_count - $line_del_count) . "\n";
print "Number of authors : $author_count\n";
foreach my $k (keys %authors) {
  print "$k\n";
}
print "$commit_count git commits\n";
