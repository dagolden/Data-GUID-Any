use 5.006;
use strict;
use warnings;
package Data::GUID::Any;
# ABSTRACT Generic interface for GUID creation
# VERSION

use Config;
use File::Spec;
use base 'Exporter';

our @EXPORT_OK = qw/ guid_as_string /;

our $Using;

#--------------------------------------------------------------------------#

my $hex = "A-Z0-9";

sub _looks_like_guid {
  my $guid = shift;
  return $guid =~ /[$hex]{8}-[$hex]{4}-[$hex]{4}-[$hex]{4}-[$hex]{12}/;
}

#--------------------------------------------------------------------------#

my @binaries = (
  [ uuid => 'uuid' => '-v1'],
);

sub _check_binaries {
  BIN:
  for my $bin ( @binaries ) {
    my ($name, $cmd, $args) = @$bin;
    my $path;
    my @suffixes = $^O eq 'MSWin32' ? (qw/.exe .com .bat/) : ( '' );
    SUFFIX:
    for my $suffix ( @suffixes ) {
      ($path) = grep { -x }
                map { File::Spec->catfile( $_, $cmd ) . $suffix }
                File::Spec->path;
      next SUFFIX unless $path;
    }
    next BIN unless $path;
    my $sub = sub { chomp( my $guid = qx/$path $args/ ); return uc $guid };
    return ($name, $sub) if _looks_like_guid( $sub->() );
  }
}

#--------------------------------------------------------------------------#

my @modules = (
  ['Data::GUID' => sub { return Data::GUID->new->as_string }],
  ['Data::UUID' => sub { return Data::UUID->new->create_str }],
  ['Data::UUID::LibUUID' => sub{ return uc Data::UUID::LibUUID::new_uuid_string() }],
  ['UUID' => sub { my ($u,$s); UUID::generate($u); UUID::unparse($u, $s); return uc $s }],
  ['Win32' => sub { my $guid = Win32::GuidGen(); return substr($guid,1,-1) }],
  ['UUID::Generator::PurePerl' => sub { return uc UUID::Generator::PurePerl->new->generate_v1->as_string }],
  ['APR::UUID' => sub { return uc APR::UUID->new->format }],
  ['UUID::Random' => sub { return uc UUID::Random::generate() }],
);

sub _preferred_modules {
  return map { $_->[0] } @modules;
}

sub _check_modules {
  for my $option ( @modules ) {
    my ($mod,$sub) = @$option;
    next unless eval "require $mod; 1";
    return ($mod, $sub) if _looks_like_guid( $sub->() );
  }
}

#--------------------------------------------------------------------------#

my ($which_bin, $bin_sub) = _check_binaries();
my ($which_mod, $mod_sub) = _check_modules();

die "Couldn't find a GUID module or binary" unless $bin_sub || $mod_sub;

{
  no warnings;
  if ( $mod_sub ) {
    *guid_as_string = $mod_sub;
    $Using = $which_mod
  }
  else {
    *guid_as_string = $bin_sub;
    $Using = $which_bin
  }
}

1;

__END__

=head1 SYNOPSIS

    use Data::GUID::Any 'guid_as_string';

    my $guid = guid_as_string();

=head1 DESCRIPTION

This module is a generic wrapper around various ways of obtaining
Globally Unique ID's (GUID's).  It will use any of the following, listed
from most preferred to least preferred:

=for :list
* L<Data::GUID>
* L<Data::UUID>
* L<Data::UUID::LibUUID>
* L<UUID>
* L<Win32> (using GuidGen())
* L<UUID::Generator::PurePerl>
* L<APR::UUID> (random)
* L<UUID::Random> (random)
* uuid (external program)

If none are available when Data::GUID::Any is installed, it will
add Data::GUID as a prerequisite.

=head1 USAGE

=head2 guid_as_string()

    my $guid = guid_as_string();

Returns a guid in string format with upper-case hex characters:

  FA2D5B34-23DB-11DE-B548-0018F34EC37C

Except for modules that only produce random GUID's, these are 'version 1'
GUID's.

=head1 SEE ALSO

=for :list
* RFC 4122 [http://tools.ietf.org/html/rfc4122]

=cut

