# module core
use IO::Socket;
use IO::Select;

my ($quit, $main, $connect);

# unqualified names
&load($state, "query");
&load($state, "irc");
&load($state, "queue");
&load($state, "config");

# qualified names
&load($state, "macro");
&load($state, "join");
&load($state, "precog");
&load($state, "hs"); # all the haskell stuff
&load($state, "help");
&load($state, "ddg");
&load($state, "seen");
&load($state, "fun");
&load($state, "events");
&load($state, "tminus");

$SIG{__WARN__} = sub {
  my ($errmsg) = @_;
  my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash) = caller(1);
  my ($module_name, $msg, $line_no);

  if (defined $evaltext && $evaltext =~ /^# module ([^\n]*)\n/) {
    $module_name = $1;
    $errmsg =~ s/^(.*) at \(eval \d+\) line \d+\.$/$1/;
    chomp $errmsg;

    print STDERR "$errmsg at Data module $module_name line $line\n";
  } elsif ($errmsg =~ /^(.*) at \(eval (\d+)\) line (\d+).*$/) {
    $msg = $1;
    $module_name = $2;
    $line_no = $3;

    if (defined $state->{'module_table'}->{$module_name}) {
      # let's use a nice name instead of a number
      $module_name = $state->{'module_table'}->{$module_name};
    } else {
      $module_name = "(eval $module_name)";
    }

    print STDERR "$msg at Data module $module_name line $line\n";
  } else {
    print STDERR join(' ', @_);
  }

  return 1;
};

$main = sub {
  my ($state) = @_;
  my ($line, $fd, @ready);
  my ($nick, $queue_line, $time, @keys, $pat, $key);

  # if not connected, connect
  unless ($state->{'socket'} && $state->{'socket'}->connected()) {
    $state->{'connect'}->();
  }

  $fd = $state->{'socket'};

  while (1) {
    # if disconnected, die
    unless ($state->{'socket'}->connected()) {
      $state->{'quit'}->('disconnected');
    }

    @ready = $state->{'select'}->can_read(1);

    $time = time;

    if ($ready[0]) {
      $line = <$fd>;
      $line =~ s/\r\n$//;

      unless (defined $line) {
        $state->{'quit'}->('undefined $line');
      }

      if ($line =~ /^ERROR/) {
        $state->{'quit'}->('got ERROR from server');
      }

      # get PING, send PONG
      if ($line =~ /^PING :(.*)/) {
        print $fd "PONG :$1\r\n";
      }

      # send PING
      if ($state->{'last_ping'} eq '' || $state->{'last_ping'} < ($time - 60)) {
        print $fd "PING :Data\r\n";
        $state->{'last_ping'} = $time;
      }

      # get PONG
      if ($line =~ /^.* PONG .* :Data$/) {
        $state->{'last_pong'} = $time;
      }


      # ident
      if ($state->{'command'}->($line) =~ /^001/) {
        $state->{'ident'}->();
        $state->{'join.join_channels'}->();
      }


      # stuff that we run first
      $state->{'precog.listen'}->($line);


      # debug stuff
      if ($state->{'parameters'}->($line) =~ /^[>?]keys (.*)$/ && $state->{'check_admin'}->($state->{'sender_nick'}->($line))) {
        @keys = keys %$state;
        $pat = qr/$1/;
        @keys = grep {$_ =~ $pat} @keys ;
        if (scalar @keys > 0) {
          $state->{'reply'}->($line, join(', ', sort @keys));
        } else {
          $state->{'reply'}->($line, "no keys match pattern $pat");
        }
      }

      if ($state->{'parameters'}->($line) =~ /^[>?]delete (.*)$/ && $state->{'check_admin'}->($state->{'sender_nick'}->($line))) {
        $key = $1;

        if (defined $state->{$key}) {
          delete $state->{$key};
          $state->{'reply'}->($line, "deleted state variable at \$state->{$key}");
        }
      }

      if ($state->{'parameters'}->($line) =~ /^[>?]clear$/ && $state->{'check_admin'}->($state->{'sender_nick'}->($line))) {
        $|++;
        print `clear`;
        $|--;
      }

      if ($state->{'parameters'}->($line) =~ /^[>?]onreload$/ && $state->{'check_admin'}->($state->{'sender_nick'}->($line))) {
      }

      if ($state->{'parameters'}->($line) =~ /^[>?]ident$/ && $state->{'check_admin'}->($state->{'sender_nick'}->($line))) {
        $state->{'ident'}->();
      }

      if ($state->{'parameters'}->($line) =~ /^[>?]quit\s*(.*)$/ && $state->{'check_admin'}->($state->{'sender_nick'}->($line))) {
        $state->{'write'}->("QUIT :$1");
        print ">quit $1\n"
      }

      if ($state->{'parameters'}->($line) =~ /^[>?]stfu$/) {
        $state->{'queue'} = [];
        $state->{'reply'}->($line, "Outgoing queue cleared.");
      }


      # channel op stuff
      $state->{'join.part'}->($line);
      $state->{'join.invite'}->($line);
      $state->{'join.kick'}->($line);

      # module stuff
      $state->{'help.help'}->($line);
      $state->{'precog.command'}->($line);
      $state->{'mueval.run_mueval'}->($line);
      $state->{'hoogle.hoogle'}->($line);
      $state->{'type.type'}->($line);
      $state->{'type.kind'}->($line);
      $state->{'ddg.ddg'}->($line);
      $state->{'seen.log'}->($line);
      $state->{'seen.seen'}->($line);
      $state->{'fun.muppets'}->($line);
      $state->{'fun.uptime'}->($line);
      $state->{'fun.synonymize'}->($line);
      $state->{'events.pings'}->($line);
      $state->{'tminus.set'}->($line);
      $state->{'seen.save_tell'}->($line);
      $state->{'seen.show_tells'}->($line);
      $state->{'seen.notify_tells'}->($line);


      if ($state->{'parameters'}->($line) =~ /^[>?]reload/ && $state->{'check_admin'}->($state->{'sender_nick'}->($line))) {
        if (&load($state, "core") > 0) {
          $state->{'reply'}->($line, 'reloaded core');
          return;
        } else {
          $state->{'reply'}->($line, 'an error occurred while reloading core...');
        }
      }
    }

    # scheduled stuff
    $queue_line = shift(@{$state->{'queue'}});
    if (defined $queue_line) {
      print $fd "$queue_line";
    }
    $state->{'tminus.check'}->();

    if (defined $state->{'last_pong'} and $time - $state->{'last_pong'} > 500) {
      die "Exiting due to timeout!";
    }
  }
};

$connect = sub {
  my ($state) = @_;
  my ($nick);

  $state->{'socket'} = new IO::Socket::INET(
    PeerAddr => 'irc.foonetic.net',
    PeerPort => 6667,
    Proto => 'tcp');

  $state->{'select'} = new IO::Select();
  $state->{'select'}->add($state->{'socket'});

  binmode $state->{'socket'} or warn "couldn't binmode socket!\n";

  $nick = $state->{'nick'};

  $state->{'write'}->("NICK $nick".'_');
  $state->{'write'}->("USER $nick 0 * :not a holodeck");
};

$quit = sub {
  my ($state, $msg) = @_;

  print 'called $state->{"quit"}->(' . "$msg);\n";
  0 while <>; # consume stdin, to keep the shell from being stupid
  exit;
};

&callback($state, "main", $main);
&callback($state, "connect", $connect);
&callback($state, "quit", $quit);

$state->{'last_ping'} = '';

