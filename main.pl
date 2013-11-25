#!/usr/bin/perl
package Main;

use strict;
use warnings;
use Getopt::Long;

&main();

sub main {
  my ($state);

  $state = {};

  &parse_options($state);

  &load($state, "core");

  while (1) {
    $state->{'main'}->();
  }
}

sub parse_options {
  my ($state) = @_;

  GetOptions("main" => \$state->{'main'});
}

sub load {
  my ($state, $module) = @_;
  my ($fh, $code, $open);

  $open = open($fh, "<", "modules/$module.pl");

  unless ($open) {
    warn "Could not open $module.pl";
    return 0;
  }

  $code = join('', <$fh>);

  eval '&register($state, '. "'$module');\n$code";
  if ($@) {
    warn $@;
    return 0;
  } else {
    return 1;
  }
}

sub register {
  my ($state, $module) = @_;
  my ($oldnum);

  my (undef, $evalno) = caller(0);

  $evalno =~ s/\(eval (\d+)\)/$1/;

  if (not defined $state->{'module_table'}) {
    $state->{'module_table'} = {};
  }

  foreach $oldnum (keys %{$state->{'module_table'}}) {
    if ($state->{'module_table'}->{$oldnum} eq $module) {
      delete $state->{'module_table'}->{$oldnum};
    }
  }

  $state->{'module_table'}->{$evalno} = $module;
}

sub callback {
  my ($state, $name, $func) = @_;

  $state->{$name} = sub {
    $func->($state, @_);
  };
}

