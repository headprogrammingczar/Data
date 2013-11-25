# module precog
my ($command, $isprecog, $unprecog, $setprecog, $listen, $add_line);

$command = sub {
  my ($state, $line) = @_;
  my ($parameters, $param, $nick, @rowhashes);

  $parameters = $state->{'parameters'}->($line);
  $nick = $state->{'sender_nick'}->($line);

  if ($parameters =~ /^[>?]precog\s+(.*)$/) {

    $param = $1;

    if ($param =~ /^\d+$/) {
      $param = int($param);
      $state->{'fetch'}->('precog.remove', $nick);
      $state->{'fetch'}->('precog.set', $nick, $param);
      $state->{'reply'}->($line, "You will see the last $param lines of chat.");
    } else {
      $state->{'reply'}->($line, "Error parsing line - syntax: >precog #");
    }
  } elsif ($parameters =~ /^[>?]precog$/) {
    @rowhashes = $state->{'fetch'}->('precog.check', $nick);

    if (scalar @rowhashes > 0) {
      $state->{'fetch'}->('precog.remove', $nick);
      $state->{'reply'}->($line, "You will no longer be PMed channel backlogs.");
    } else {
      $state->{'fetch'}->('precog.set', $nick, 6);
      $state->{'reply'}->($line, "You will see the last 6 lines of chat.");
    }
  }
};

$isprecog = "SELECT * FROM time_travelers WHERE nick=?";
$state->{'prepare'}->('precog.check', $isprecog);

$unprecog = "DELETE FROM time_travelers WHERE nick=?";
$state->{'prepare'}->('precog.remove', $unprecog);

$setprecog = "INSERT INTO time_travelers (nick, line_count) VALUES (?,?)";
$state->{'prepare'}->('precog.set', $setprecog);

$listen = sub {
  my ($state, $line) = @_;
  my ($to, $from, $said, $command, $lines, $count, $num_wanted, @rows, $log_hash, $i, $time, $bang);

  $command = $state->{'command'}->($line);

  if ($command =~ /^privmsg (.*)$/i) {
    # if channel message, log it
    $to = $1;
    $from = $state->{'sender_nick'}->($line);
    $said = $state->{'parameters'}->($line);

    $state->{'precog.add_line'}->($to, $from, $said);
  } elsif ($command =~ /^join$/i) {
    # if join, print precog stuff
    $to = $state->{'sender_nick'}->($line);
    $from = lc $state->{'parameters'}->($line);
    $lines = $state->{'precog.log'}->{$from};

    @rows = $state->{'fetch'}->('precog.check', $to);

    if (defined $lines && scalar @rows > 0) {
      $num_wanted = $rows[0]->{'line_count'};
      $count = scalar @$lines;

      if ($num_wanted < $count) {
        $count = $num_wanted;
      }

      $bang = 0;

      $state->{'enqueue'}->("PRIVMSG $to :The last $count lines of $from are:\r\n");

      # no information before this time, so clearly the universe was just created
      if (scalar @$lines > 0 && $bang > 0) {
        $time = $state->{"pretty_diff_time"}->(0);
        $state->{'enqueue'}->("PRIVMSG $to :$time ago, the unix timestamp overflowed to 0, creating the universe\r\n");
      }

      for ($i = (scalar @$lines - $count); $i < scalar @$lines; $i++) {
        $log_hash = $lines->[$i];

        $time = $state->{"pretty_diff_time"}->($log_hash->{'now'});
        $state->{'enqueue'}->("PRIVMSG $to :\x02$time\x0f ago - $log_hash->{'line'}\r\n");
      }
    }
  }
};

$add_line = sub {
  my ($state, $to, $from, $line) = @_;
  my ($logs, $log, $row);

  # log lines
  $logs = $state->{'precog.log'};

  # ircd can go fuck itself
  $to = lc $to;

  if ($to =~ /^#/) {
    $logs->{$to} ||= [];
    $log = $logs->{$to};
    $row = {now => time, line => "\x0307$to\x0f <\x0304$from\x0f> $line"};

    push(@$log, $row);
    if (scalar @$log > 50) {
      shift @$log;
    }
  }
};

&callback($state, "precog.command", $command);
&callback($state, "precog.listen", $listen);
&callback($state, "precog.add_line", $add_line);

