#!/usr/bin/perl

use warnings;
use strict;
use Text::CSV;
use JSON qw( decode_json );
use Data::Dumper;
use URI::Escape;
require LWP::UserAgent;

my @rows;
my $incsv = Text::CSV->new ( { binary => 1 } ) or die "Cannot use CSV: ".Text::CSV->error_diag ();
my $outcsv = Text::CSV->new ( { binary => 1 } ) or die "Cannot use CSV: ".Text::CSV->error_diag ();

open my $fh, "<:encoding(utf8)", "orig.txt" or die "orig.txt$!";

push @rows, [ 'url','closely_id','name','location','score','potential_score','%_incomplete','%_inconsistent','%_duplicate','missing' ];

my $cnt = 0;
my $ua = LWP::UserAgent->new;
open my $ofh, ">:encoding(utf8)", "biz.csv" or die "biz.csv: $!";

while ( my $row = $incsv->getline( $fh ) ) {
  $cnt++;
  my @newrow;

  my $name = uri_escape_utf8($row->[1]);
  my $location = $row->[5];
  # my $location = uri_escape_utf8($row->[2] . " " . $row->[3] . " " . $row->[4] . " " . $row->[5]);
  my $url = "https://moz.com/local/api/perch?q=$name&loc=$location";

  # print "Hitting $url\n";

  my $response;
  if ($name && $location) {
    $response = $ua->get($url);
  }

  push @newrow, $url;
  push @newrow, $row->[0];
  push @newrow, $row->[1];
  push @newrow, $location;

  if ($location && $name && $response && $response->is_success && $response->content 
    && $response->content_length && $response->content_length > 0) {


    print STDERR "\n\nJSON :\n\n";
    print STDERR Dumper $response->content;
    print STDERR "\n\n";

    my %json = %{ decode_json($response->content) };
    if (%json && (scalar keys %json > 0)) {
      push @newrow, $json{score};
      push @newrow, $json{potential}{score};
      push @newrow, $json{potential}{incomplete};
      push @newrow, $json{potential}{inconsistent};
      push @newrow, $json{potential}{duplicates};

      if ($json{missing}) {
        my @missing = @{ $json{missing} };
        my $out;
        foreach my $item (@missing) {
          if ($out) {
            $out .= "|";
          }
          $out .= ${$item}{source};
        }

        push @newrow, $out;
      }
    }
  }
  else {
    print STDERR "ERROR\n\n\n" . $url . "\n\n\n\n";
    if ($response) {
      print STDERR Dumper $response . "\n\n\n";
    }
  }

  push @rows, \@newrow;
  if ($cnt % 10 == 0) {
    print "Count at $cnt\n";
    $outcsv->eol ("\r\n");
    $outcsv->print ($ofh, $_) for @rows;
    $ofh->flush();
    @rows = [];
  }
}

$incsv->eof or $incsv->error_diag();
close $fh;


$outcsv->eof or $outcsv->error_diag();
close $ofh or die "biz.csv: $!";
