# Copyright (c) 2009 by David Golden. All rights reserved.
# Licensed under Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a 
# copy of the License from http://www.apache.org/licenses/LICENSE-2.0

use strict;
use warnings;
no warnings 'once';

use Test::More;
use t::Util;

# Work around buffering that can show diags out of order
Test::More->builder->failure_output(*STDOUT) if $ENV{HARNESS_VERBOSE};

plan tests => 3;

$Data::GUID::Prefer_Perl = 1;
require_ok( 'Data::GUID::Any' );

can_ok( 'Data::GUID::Any', $_ ) for qw/ guid_as_string /;
my $guid =  Data::GUID::Any::guid_as_string();
ok( looks_like_guid( $guid  ), "looks like guid" ) or diag $guid;
