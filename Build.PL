# Copyright (c) 2009 by David Golden. All rights reserved.
# Licensed under Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a 
# copy of the License from http://www.apache.org/licenses/LICENSE-2.0

use 5.006;
use strict;
use warnings;
use lib 'inc';
eval "require Pod::WikiDoc";
my $class = $@ ? "Module::Build" : "Module::Build::WikiDoc";
eval "require $class";

my @maybe_reqs;

unless ( eval { require 'lib/Data/GUID/Any.pm'; 1 } ) {
  push @maybe_reqs, 'Data::GUID', 0;
}

my $build = $class->new( 
  module_name => 'Data::GUID::Any',
  dist_author => 'David Golden <dagolden@cpan.org>',
  license => 'apache',
  create_readme => 1,
  requires => {
    'perl' => 5.006,
    'base' => 0, 
    'Exporter' => 0,
    'File::Spec' => 3.12, 
    @maybe_reqs,
  },
  build_requires => {
    'File::Find' => 0,
    'Test::More' => 0.62, 
  },
  meta_add            => { 
    configure_requires => { 
      'Module::Build' => 0.30 
    },
    no_index => { 
      directory => [ qw/ examples inc t xt /],
    },
    resources => {
      repository => "http://github.com/dagolden/data-guid-any/", 
      bugtracker => "http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-GUID-Any",
    },
  },
);
$build->create_build_script;

