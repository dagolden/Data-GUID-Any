package inc::MakeMaker;
use Moose;
extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';
 
use namespace::autoclean;
 
override _build_WriteMakefile_dump => sub {
  my ($self) = @_;
 
  my $str = super;
 
  $str .= ";\n\n";
 
  $str .= <<'END_NONSENSE';
$WriteMakefileArgs{PREREQ_PM} ||= {};

use ExtUtils::CBuilder;
my $have_compiler = ExtUtils::CBuilder->new->have_compiler;
 
my $have_providers = eval {
  use lib 'lib';
  require Data::GUID::Any;
  Data::GUID::Any::v1_guid_as_string(); # dies if no provider
  Data::GUID::Any::v4_guid_as_string(); # dies if no provider
  1;
};

if ( $have_providers ) {
  # nothing to add
}
elsif ( $have_compiler ) {
  $WriteMakefileArgs{PREREQ_PM}{'Data::UUID::MT'} = '0';
}
else {
  $WriteMakefileArgs{PREREQ_PM}{'UUID::Tiny'} = '0';
}
 
END_NONSENSE
 
  return $str;
};
 
1;
