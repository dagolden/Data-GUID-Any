package t::Util;
use strict;
use warnings;
use base 'Exporter';
our @EXPORT = qw/looks_like_guid/;

my $hex = "A-Z0-9";

sub looks_like_guid {
  my $guid = shift;
  return $guid =~ /[$hex]{8}-[$hex]{4}-[$hex]{4}-[$hex]{4}-[$hex]{12}/;
}

1;
