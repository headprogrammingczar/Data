# module tminus
my ($set, $check);

$set = sub {
  my ($state, $line) = @_;
  my ($parameters, $day, $hour, $min, $sec, $msg, $time);

  $parameters = $state->{'parameters'}->($line);

  if ($parameters =~ /^[?>]tminus forget$/) {
    delete $state->{'tminus.countdowns'};
    $state->{'reply'}->($line, "I will forget");
  } elsif ($parameters =~ s/^[?>]tminus (.*)$/$1/) {
    $day = 0;
    $hour = 0;
    $min = 0;
    $sec = 0;

    if ($parameters =~ s/^(\d+)d (.*)/$2/) {
      $day = $1;
    }
    if ($parameters =~ s/^(\d+)h (.*)/$2/) {
      $hour = $1;
    }
    if ($parameters =~ s/^(\d+)m (.*)/$2/) {
      $min = $1;
    }
    if ($parameters =~ s/^(\d+)s (.*)/$2/) {
      $sec = $1;
    }

    $msg = $parameters;

    $time = time + $sec + 60 * ($min + 60 * ($hour + 24 * $day));

    if (not defined $state->{'tminus.countdown'}) {
      $state->{'tminus.countdown'} = [];
    }

    push(@{$state->{'tminus.countdown'}}, {at_time => $time, msg => $msg, where => $state->{'response'}->($line)});
    $state->{'reply'}->($line, "I can't wait!");
  }
};

$check = sub {
  my ($state) = @_;
  my (@notices, $notice, $message);

  if (not defined $state->{'tminus.countdown'}) {
    return;
  }

  @notices = @{$state->{'tminus.countdown'}};

  foreach $notice (@notices) {
    if ($notice->{'at_time'} - time < 0) {
      $message = "Countdown finished: ". $notice->{'msg'};
      $state->{'pm'}->($notice->{'where'}, $message);
      $notice->{'done'} = 1;
    }
  }

  @notices = grep {not defined $_->{'done'}} @notices;

  $state->{'tminus.countdown'} = \@notices;
};

&callback($state, "tminus.set", $set);
&callback($state, "tminus.check", $check);

