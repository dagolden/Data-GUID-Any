# Copyright (c) 2009 by David Golden. All rights reserved.
# Licensed under Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a
# copy of the License from http://www.apache.org/licenses/LICENSE-2.0

use strict;
use warnings;

use Test::More;
use Config;
use File::Spec;
use t::Util;

# Work around buffering that can show diags out of order
Test::More->builder->failure_output(*STDOUT) if $ENV{HARNESS_VERBOSE};

#--------------------------------------------------------------------------#
# set PATH to find our mock uuid
#--------------------------------------------------------------------------#

local $ENV{PATH} = File::Spec->catdir(qw/t bin/).$Config{path_sep}.$ENV{PATH};
my $binary = File::Spec->catfile(qw/t bin uuid/);
$binary .= ".bat" if $^O eq 'MSWin32';

#--------------------------------------------------------------------------#
# hide some modules
#--------------------------------------------------------------------------#

my %hidden;
sub _hider {
  my ($self, $file) = @_;
  die "Can't locate '$file' (hidden)" if $hidden{$file};
};

unshift @INC, \&_hider;

#--------------------------------------------------------------------------#
# Start tests
#--------------------------------------------------------------------------#

plan 'no_plan';

require_ok( "Data::GUID::Any" )
  or BAIL_OUT "require Data::GUID::Any failed";

my @modules = (Data::GUID::Any::_preferred_modules(), $binary);

while ( my $mod = shift @modules ) {
  SKIP: {
    if ( $mod eq $binary ) {
      skip( "$mod not executable", 1) unless -x $mod;
    }
    else {
      eval "require $mod; 1" or skip( "$mod not available", 1);
    }
    # reload Data::GUID::Any
    delete $INC{'Data/GUID/Any.pm'};
    {
      local $SIG{__WARN__} = sub {};
      eval { require Data::GUID::Any;1 };
      is( $@ , "",
        "reloaded Data::GUID::Any"
      );
    }
    is( $Data::GUID::Any::Using, ($mod eq $binary ? 'uuid' : $mod), 
      "Data::GUID::Any set to use '$mod'" 
    );
    # test getting a guid
    can_ok( 'Data::GUID::Any', $_ ) for qw/ guid_as_string /;
    my $guid =  Data::GUID::Any::guid_as_string();
    ok( t::Util::looks_like_guid( $guid  ),
      "guid_as_string() looks like guid"
    ) or diag $guid;
    # hide module before next loop
    if ( $mod ne $binary) {
      my $mod_path = $mod;
      $mod_path =~ s{::}{/}g;
      $mod_path .= ".pm";
      $hidden{$mod_path} = delete $INC{$mod_path};
      eval "require $mod; 1";
      ok( $@, "$mod hidden" ) 
        or diag "$mod_path";
      undef $Data::GUID::Any::Using;
    }
  }
}


