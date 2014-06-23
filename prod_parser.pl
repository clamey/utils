#!/opt/local/bin/perl

use XML::LibXML;
use DateTime::Format::Strptime;
use Data::Dumper;

my $parser = XML::LibXML->new();
my $doc    = $parser->parse_file($ARGV[0]);

foreach my $date($doc->findnodes('/rss/channel/item/created')) {
  $x = $date->to_literal;
  # Tue, 13 Aug 2013 13:57:29 -0600
  my $Strp = new DateTime::Format::Strptime(
   pattern     => '%a, %d %b %Y %T %z',
   on_error    => 'croak' ## die on error
  );
  $dt = $Strp->parse_datetime($x);
  ++$rez{$dt->year()}{$dt->month};
}

foreach $year (keys %rez) {
  foreach $month (keys %{ $rez{$year} } ) {
    print "1-$month-$year,$rez{$year}{$month}\n";
  }
}
