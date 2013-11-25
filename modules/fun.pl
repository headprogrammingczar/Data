use IO::CaptureOutput;

# module fun
my ($muppets, $uptime, $synonymize_call, $synonymize);

$muppets = sub {
  my ($state, $line) = @_;

  if (not defined $state->{'fun.mahna'}) {
    $state->{'fun.mahna'} = 0;
  }

  if ($state->{'parameters'}->($line) =~ /^[>?]mahna mahna$/) {
    if ($state->{'fun.mahna'} == 0) {
      $state->{'reply'}->($line, "do doo do-do-do");
    } elsif ($state->{'fun.mahna'} == 1) {
      $state->{'reply'}->($line, "do do-do do");
    } else {
      $state->{'reply'}->($line, "do doo do-do-do, do-do-do, do-do-do, do-do do-do do-DO DO DO-DO DO");
    }

    $state->{'fun.mahna'} = ($state->{'fun.mahna'} + 1) % 3;
  }
};

$uptime = sub {
  my ($state, $line) = @_;
  my ($pretty_time);

  if ($state->{'parameters'}->($line) =~ /^[>?]uptime$/) {
    $pretty_time = $state->{'pretty_diff_time'}->($state->{'fun.started'});

    $state->{'reply'}->($line, "Uptime: $pretty_time");
  }
};

$synonymize = sub {
  my ($state, $line) = @_;
  my ($text, $out, $err);

  if ($state->{'parameters'}->($line) =~ /^[>?]synonymize (.*)$/) {
    $text = $1;
    &IO::CaptureOutput::capture(sub {$state->{'fun.synonymize_call'}->($text)}, \$out, \$err);

    if ($err ne '') {
      $state->{'reply'}->($line, "an error occurred");
    } else {
      $state->{'reply'}->($line, "  $out");
    }
  }
};

$synonymize_call = sub {
  my ($state, $line) = @_;
  my ($opened, $program);
  my ($outstr);

  # open handle
  # import L.hs
  $opened = open($program, "| synonymize");
  if (not $opened) {
    warn "Could not open synonymizer";
    return;
  }
  # type of expression
  # quit
  print $program $line;
  # close handle
  close $program;
};

if (not defined $state->{'fun.started'}) {
  $state->{'fun.started'} = time;
}

&callback($state, "fun.muppets", $muppets);
&callback($state, "fun.uptime", $uptime);
&callback($state, "fun.synonymize_call", $synonymize_call);
&callback($state, "fun.synonymize", $synonymize);

