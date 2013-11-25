# module hs
use IO::CaptureOutput;
use Encode;

# mueval
my ($mueval, $munge, $run_mueval);

$mueval = sub {
  my ($state, $code) = @_;
  my ($out, $err, $success, $exit);

  $code = &Encode::encode("utf-8", $code);
  ($out, $err, $success, $exit) = &IO::CaptureOutput::capture_exec("mueval", "-X", "PostfixOperators", "-t", "5", "-l", "L.hs", "--expression=$code");

  $out = $state->{'mueval.munge'}->($out);
  $err = $state->{'mueval.munge'}->($err);

  $out = &Encode::decode("utf-8", $out);

  if ($out eq '' && $err eq '') {
    return "Terminated";
  }

  if ($out eq '') {
    return "  $err";
  } else {
    return "  $out";
  }
};

$munge = sub {
  my ($state, $out) = @_;
  my ($old_out);

  $out =~ s/^\n*//;
  $out =~ s/\n*$//;
  $out =~ s/\t/ /g;

  # surrounding newlines don't count as part of the evaluated expression, nor do tabs
  $old_out = $out;

  $out =~ s/\n.*//;
  $out = $state->{'truncate'}->(200, $out);

  return $out;
};

$run_mueval = sub {
  my ($state, $line) = @_;
  my ($out, $expr);

  if ($state->{'parameters'}->($line) =~ /^[>?] (.*)$/) {
    $expr = $1;
    $out = $state->{'mueval.mueval'}->($expr);
    $state->{'reply'}->($line, $out);
  }

  if ($state->{'parameters'}->($line) =~ /^[>?]eval (.*)$/) {
    $expr = $1;
    $out = $state->{'mueval.mueval'}->($expr);
    $state->{'reply'}->($line, $out);
  }
};

&callback($state, "mueval.mueval", $mueval);
&callback($state, "mueval.munge", $munge);
&callback($state, "mueval.run_mueval", $run_mueval);

# ?type
my ($type, $kind, $ghci, $type_parse);

$kind = sub {
  my ($state, $line) = @_;
  my ($expr, $out, $err);

  if ($state->{'parameters'}->($line) =~ /^[>?]kind (.*)$/) {
    $expr = $1;
    &IO::CaptureOutput::capture(sub {$state->{'type.ghci'}->($expr, ':k')}, \$out, \$err);

    if ($err ne '') {
      $state->{'reply'}->($line, $state->{'mueval.munge'}->($err));
    } else {
      # the hard part: turning "*L> expr :: type" into "type", across newlines
      $state->{'reply'}->($line, $state->{'type.parse'}->($out, $expr));
    }
  }
};

$type = sub {
  my ($state, $line) = @_;
  my ($expr, $out, $err);

  if ($state->{'parameters'}->($line) =~ /^[>?]type (.*)$/) {
    $expr = $1;
    &IO::CaptureOutput::capture(sub {$state->{'type.ghci'}->($expr)}, \$out, \$err);

    if ($err ne '') {
      $state->{'reply'}->($line, $state->{'mueval.munge'}->($err));
    } else {
      # the hard part: turning "*L> expr :: type" into "type", across newlines
      $state->{'reply'}->($line, $state->{'type.parse'}->($out, $expr));
    }
  }
};

# prints stuff to stdout/err, which gets captured by $type
$ghci = sub {
  my ($state, $expr, $query) = @_;
  my ($opened, $ghci);
  my ($outstr);

  if (not defined $query or $query eq '') {
    $query = ':t';
  }

  # open handle
  # import L.hs
  $opened = open($ghci, "| timelimit -t10 -T15 ghci L.hs -fprint-explicit-foralls");
  if (not $opened) {
    warn "Could not open ghci";
    return;
  }
  # type of expression
  # quit
  print $ghci "$query $expr\n:q\n";
  # close handle
  close $ghci;
};

$type_parse = sub {
  my ($state, $out, $expr) = @_;
  my (@lines, $line, $i, $start, $end, $ret_line);

  @lines = split("\n", $out);
  $start = 0;
  $end = 0;
  # remove the extra ghci crap from output
  for ($i = 0; $i < scalar @lines; $i++) {
    $line = $lines[$i];
    if ($start == 0 && $line =~ /^\*L>/) {
      $start = $i;
    }
    if ($start != 0 && $line =~ /^\*L>/) {
      $end = $i - 1;
    }
  }

  # cut out the "*L> expr :: " part
  $ret_line = join(' ', @lines[$start .. $end]);
  $ret_line = substr($ret_line, (length $expr) + 8);
  $ret_line =~ s/^: //;

  return $ret_line;
};

&callback($state, "type.type", $type);
&callback($state, "type.kind", $kind);
&callback($state, "type.ghci", $ghci);
&callback($state, "type.parse", $type_parse);

# ?hoogle
my ($hoogle);

$hoogle = sub {
  my ($state, $line) = @_;
  my ($term, $hoogle_out, $hoogle_err, $success, $exit, @lines, $first, $second, $third, $out, @check_1, @check_2);

  if ($state->{'parameters'}->($line) =~ /^[>?]hoogle (.*)$/) {
    $term = $1;
    ($hoogle_out, $hoogle_err, $success, $exit) = &IO::CaptureOutput::capture_exec("hoogle", "--count=20", $term);
    if ($hoogle_out eq '' && $hoogle_err eq '') {
      return "Terminated";
    }

    @lines = split('\n', $hoogle_out);

    $hoogle_err =~ s/^(.*)\n/$1/;

    @check_1 = split(' ', "package keyword");
    @check_2 = split(' ', "module data type newtype class");

    # pretty formatting - purple keywords, green modules, bold packages
    if (scalar @lines == 0) {
      $state->{'reply'}->($line, $hoogle_err);
    } elsif ($lines[0] eq 'No results found') {
      $state->{'reply'}->($line, $lines[0]);
    } else {
      for (my $i = 0; $i < 3 && $i < scalar @lines; $i++) {
        if ($lines[$i] =~ /^(\S*) (\S*) :: (.*)$/) {
          # function or value
          $first = $1; $second = $2; $third = $3;
          $out = "\x0303$first\x0f $second :: $third";
        } elsif ($lines[$i] =~ /^(\S*) (\S*) (.*)$/) {
          # module, data type, etc
          $first = $1; $second = $2; $third = $3;
          if (grep(/^$first$/, @check_1) || grep(/^$second$/, @check_2)) {
            $out = "\x0303$first\x0f \x0306$second\x0f $third";
          } else {
            $out = $lines[$i];
          }
        } elsif ($lines[$i] =~ /^(\S*) (\S*)$/) {
          # package, or keyword
          $first = $1; $second = $2;
          if ($first eq 'keyword') {
            $out = "\x02$first\x0f \x0306$second\x0f";
          } elsif ($first eq 'package') {
            $out = "\x0306$first\x0f \x02$second\x0f";
          } else {
            $out = $lines[$i];
          }
        } else {
          $out = $lines[$i];
        }
        $state->{'reply'}->($line, $out);
      }
    }
  }
};

&callback($state, "hoogle.hoogle", $hoogle);

