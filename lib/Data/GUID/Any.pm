use 5.006;
use strict;
use warnings;
package Data::GUID::Any;
# ABSTRACT: Generic interface for GUID/UUID creation
# VERSION

use Config;
use File::Spec;
use IPC::Cmd;
use base 'Exporter';

our @EXPORT_OK = qw/ guid_as_string v1_guid_as_string v4_guid_as_string/;

our ($Using_vX, $Using_v1, $Using_v4) = ("") x 3;

#--------------------------------------------------------------------------#

my $hex = "A-Z0-9";

sub _looks_like_guid {
  my $guid = shift;
  return $guid =~ /[$hex]{8}-[$hex]{4}-[$hex]{4}-[$hex]{4}-[$hex]{12}/;
}

#--------------------------------------------------------------------------#

# state variables for generator closures
my ($dumt_v1, $dumt_v4, $uuid_v1, $uuid_v4) = (undef) x 4; # reset if reloaded

my %generators = (
  # v1 or v4
  'Data::UUID::MT' => {
    type => 'module',
    v1 => sub {
      $dumt_v1 ||= Data::UUID::MT->new(version => 1);
      return uc $dumt_v1->create_string;
    },
    v4 => sub {
      $dumt_v4 ||= Data::UUID::MT->new(version => 4);
      return uc $dumt_v4->create_string;
    },
  },
  'Data::UUID::LibUUID' => {
    type => 'module',
    v1 => sub { return uc Data::UUID::LibUUID::new_uuid_string(2) },
    v4 => sub { return uc Data::UUID::LibUUID::new_uuid_string(4) },
    vX => sub { return uc Data::UUID::LibUUID::new_uuid_string() },
  },
  'UUID::Tiny' => {
    type => 'module',
    v1 => sub { return uc UUID::Tiny::create_UUID_as_string(UUID::Tiny::UUID_V1()) },
    v4 => sub { return uc UUID::Tiny::create_UUID_as_string(UUID::Tiny::UUID_V4()) },
  },
  'uuid' => {
    type => 'binary',
    v1 => sub {
      $uuid_v1 ||= IPC::Cmd::can_run('uuid');
      chomp( my $guid = qx/$uuid_v1 -v1/ ); return uc $guid;
    },
    v4 => sub {
      $uuid_v4 ||= IPC::Cmd::can_run('uuid');
      chomp( my $guid = qx/$uuid_v4 -v4/ ); return uc $guid;
    },
  },
  # v1 only
  'Data::GUID' => {
    type => 'module',
    v1 => sub { return uc Data::GUID->new->as_string },
  },
  'Data::UUID' => {
    type => 'module',
    v1 => sub { return uc Data::UUID->new->create_str },
  },
  # system dependent or custom
  'UUID' => {
    type => 'module',
    vX => sub { my ($u,$s); UUID::generate($u); UUID::unparse($u, $s); return uc $s },
  },
  'Win32' => {
    type => 'module',
    vX => sub { my $guid = Win32::GuidGen(); return uc substr($guid,1,-1) },
  },
  'APR::UUID' => {
    type => 'module',
    vX => sub { return uc APR::UUID->new->format },
  },
);

our $NO_BINARY; # for testing
sub _is_available {
  my ($name) = @_;
  if ( $generators{$name}{type} eq 'binary' ) {
    return $NO_BINARY ? undef : IPC::Cmd::can_run($name);
  }
  else {
    return eval "require $name; \$name";
  }
}

sub _best_generator {
  my ($list) = @_;
  for my $option ( @$list ) {
    my ($name, $version) = @$option;
    next unless my $g = $generators{$name};
    next unless _is_available($name);
    return ($name, $g->{$version})
      if $g->{$version} && _looks_like_guid( $g->{$version}->() );
  }
  return;
}

#--------------------------------------------------------------------------#

my %sets = (
  any => [
    ['Data::UUID::MT'       => 'v4'],
    ['Data::GUID'           => 'v1'],
    ['Data::UUID'           => 'v1'],
    ['Data::UUID::LibUUID'  => 'vX'],
    ['UUID'                 => 'vX'],
    ['Win32'                => 'vX'],
    ['uuid'                 => 'v1'],
    ['APR::UUID'            => 'vX'],
    ['UUID::Tiny'           => 'v1'],
  ],
  v1 => [
    ['Data::UUID::MT'       => 'v1'],
    ['Data::GUID'           => 'v1'],
    ['Data::UUID'           => 'v1'],
    ['Data::UUID::LibUUID'  => 'v1'],
    ['uuid'                 => 'v1'],
    ['UUID::Tiny'           => 'v1'],
  ],
  v4 => [
    ['Data::UUID::MT'       => 'v4'],
    ['Data::UUID::LibUUID'  => 'v4'],
    ['uuid'                 => 'v4'],
    ['UUID::Tiny'           => 'v4'],
  ],
);

sub _generator_set { return $sets{$_[0]} }

{
  no warnings qw/once redefine/;
  {
    my ($n, $s) = _best_generator(_generator_set("any"));
    die "Couldn't find a GUID provider" unless $n;
    *guid_as_string = $s;
    $Using_vX = $n;
  }
  {
    my ($n, $s) = _best_generator(_generator_set("v1"));
    *v1_guid_as_string = $s || sub { die "No v1 GUID provider found\n" };
    $Using_v1 = $n || '';
  }
  {
    my ($n, $s) = _best_generator(_generator_set("v4"));
    *v4_guid_as_string = $s || sub { die "No v4 GUID provider found\n" };
    $Using_v4 = $n || '';
  }
}

1;

__END__

=head1 SYNOPSIS

    use Data::GUID::Any 'guid_as_string';

    my $guid = guid_as_string();

=head1 DESCRIPTION

This module is a generic wrapper around various ways of obtaining Globally
Unique ID's (GUID's), also known as Universally Unique Identifiers (UUID's).

On installation, if Data::GUID::Any can't detect a way of generating both
version 1 and version 4 GUID's, it will add either Data::UUID::MT or UUID::Tiny
as a prerequisite, depending on whether or not a compiler is available.

=head1 USAGE

The following functions are available for export.

=head2 guid_as_string()

    my $guid = guid_as_string();

Returns a guid in string format with upper-case hex characters:

  FA2D5B34-23DB-11DE-B548-0018F34EC37C

This is the most general subroutine that offers the least amount of control
over the result.  This routine returns whatever is the default type of GUID for
a source, which could be version 1 or version 4 (or, in the case of Win32,
something resembling a version 1, but specific to Microsoft).

It will use any of the following sources, listed from most preferred to least
preferred:

=for :list
* L<Data::UUID::MT> (v4)
* L<Data::GUID> (v1)
* L<Data::UUID> (v1)
* L<Data::UUID::LibUUID> (v4 or v1)
* L<UUID> (v4 or v1)
* L<Win32> (using GuidGen()) (similar to v1)
* uuid (external program) (v1)
* L<APR::UUID> (v4 or v1)
* L<UUID::Tiny> (v1)

At least one of them is guaranteed to exist or Data::GUID::Any will
throw an exception when loaded.

=head2 v1_guid_as_string()

    my $guid = v1_guid_as_string();

Returns a version 1 (timestamp+MAC/random-identifier) GUID in string format
with upper-case hex characters from one of the following sources:

=for :list
* L<Data::UUID::MT>
* L<Data::GUID>
* L<Data::UUID>
* L<Data::UUID::LibUUID>
* uuid (external program)
* L<UUID::Tiny>

If none of them are available, an exception will be thrown when this
is called.

=head2 v4_guid_as_string()

    my $guid = v4_guid_as_string();

Returns a version 4 (random) GUID in string format with upper-case hex
characters from one of the following modules:

=for :list
* L<Data::UUID::MT>
* L<Data::UUID::LibUUID>
* uuid (external program)
* L<UUID::Tiny>

If none of them are available, an exception will be thrown when this
is called.

=head1 SEE ALSO

=for :list
* RFC 4122 [http://tools.ietf.org/html/rfc4122]

=cut

