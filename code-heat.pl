#!/opt/local/bin/perl -w

use strict;
use File::Find;
use Statistics::Descriptive;

my @dirs = `find . -type d -depth 1`;
my @repos;
my %files;
my %files_lines_added;
my $add_stats = Statistics::Descriptive::Full->new();
my %files_lines_deleted;
my $del_stats = Statistics::Descriptive::Full->new();
my %all_files;
my $count_stats = Statistics::Descriptive::Full->new();
my $loc_stats = Statistics::Descriptive::Full->new();

sub wanted {
  return if !-f;
  return if /class$/;
  return if /\.gitignore$/;
  return if /pbxproj$/;
  return if /gradle$/;
  return if /INFO$/;
  return if /properties$/;
  return if /makefile$/;
  return if /INI$/;
  return if /time$/;
  return if /README$/;
  return if /mxml$/;
  return if /bat$/;
  return if /gradlew$/;
  return if /xml$/;
  return if /txt$/;
  return if /svn-base$/;
  return if /\.svn/;
  my $cnt = `wc -l $_ | awk {\' print \$1\'}`;
  (my $file) = $File::Find::name =~ /.+(\/.*\/.*)$/;
  return if (!$file);
  $all_files{$file} = $cnt;
}

find(\&wanted, ".");

#foreach my $k (keys %all_files) {
#  print "$k\n";
#}

foreach my $dir (@dirs) {
  chomp($dir);
  $dir =~ s/^\.\///;
  next if $dir =~ (/^\./);
  push @repos, $dir;
}

while (<>) {
  chomp();

  next if /\.gitignore$/;
  next if /pbxproj$/;
  next if /gradle$/;
  next if /INFO$/;
  next if /properties$/;
  next if /makefile$/;
  next if /INI$/;
  next if /time$/;
  next if /README$/;
  next if /mxml$/;
  next if /bat$/;
  next if /gradlew$/;
  next if /xml$/;
  next if /txt$/;
  next if /svn-base$/;
  next if /\.svn/;

  #2	2	audio_server/src/integTest/resources/properties/pond15.properties
  if (/^\d+/) {
    (my $lines_added, my $lines_deleted, my $full_path) =  split ("\t");
    (my $file) = $full_path =~ /.+(\/.*\/.*)$/;
    next if (!$file);
    next if (!exists $all_files{$file});
    $files{$file}++;
    $files_lines_deleted{$file} += $lines_deleted;
    $files_lines_added{$file} += $lines_added;
  }
}

my $total=200;

my $cnt=0;
foreach my $file (sort { $files{$b} <=> $files{$a}} keys %files) {
  $add_stats->add_data($files_lines_added{$file});
  $del_stats->add_data($files_lines_deleted{$file});
  $count_stats->add_data($files{$file});
  $cnt++;
  last if ($cnt > $total);
}

print <<HTML
<html>
<body>
<table>
<tr><th bgcolor=\"lightgrey\">File Name</th><th bgcolor=\"lightgrey\">Commit Count</th><th bgcolor=\"lightgrey\">Lines Added</th><th bgcolor=\"lightgrey\">Lines Deleted</th><th bgcolor=\"lightgrey\">Line Count</tr>
HTML
;

$cnt=0;

my @keys;
foreach my $file (sort { $files{$b} <=> $files{$a}} keys %files) {
  push @keys, $file;
  $cnt++;
  last if ($cnt > $total);
}

foreach my $file (sort @keys) {

  print "<tr><td>$file</td>";

  my $color = "white";
  if ($files{$file} >= $count_stats->quantile(1) && $files{$file} < $count_stats->quantile(2)) {
    $color = "green";
  } elsif ($files{$file} >= $count_stats->quantile(2) && $files{$file} < $count_stats->quantile(3)) {
    $color = "yellow";
  } elsif ($files{$file} >= $count_stats->quantile(3)) {
    $color = "red";
  }
  print "<td bgcolor=\"$color\">$files{$file}</td>";

  $color = "white";
  if ($files_lines_added{$file} >= $add_stats->quantile(1) && $files_lines_added{$file} < $add_stats->quantile(2)) {
    $color = "green";
  } elsif ($files_lines_added{$file} >= $add_stats->quantile(2) && $files_lines_added{$file} < $add_stats->quantile(3)) {
    $color = "yellow";
  } elsif ($files_lines_added{$file} >= $add_stats->quantile(3)) {
    $color = "red";
  }
  print "<td bgcolor=\"$color\">$files_lines_added{$file}</td>";

  $color = "white";
  if ($files_lines_deleted{$file} >= $del_stats->quantile(1) && $files_lines_deleted{$file} < $del_stats->quantile(2)) {
    $color = "green";
  } elsif ($files_lines_deleted{$file} >= $del_stats->quantile(2) && $files_lines_deleted{$file} < $del_stats->quantile(3)) {
    $color = "yellow";
  } elsif ($files_lines_deleted{$file} >= $del_stats->quantile(3)) {
    $color = "red";
  }
  print "<td bgcolor=\"$color\">$files_lines_deleted{$file}</td>";

  $color = "white";
  if ($all_files{$file} >= $loc_stats->quantile(1) && $all_files{$file} < $loc_stats->quantile(2)) {
    $color = "green";
  } elsif ($all_files{$file} >= $loc_stats->quantile(2) && $all_files{$file} < $loc_stats->quantile(3)) {
    $color = "yellow";
  } elsif ($all_files{$file} >= $loc_stats->quantile(3)) {
    $color = "red";
  }
  print "<td bgcolor=\"white\">$all_files{$file}</td></tr>\n";
}

print <<HTML
</table>
</body>
</html>
HTML
;
