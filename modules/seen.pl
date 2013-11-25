# module seen
my ($log, $seen, $save_tell, $show_tells, $notify_tells);

$state->{'prepare'}->('seen.get_tells', "select *, unix_timestamp(sent_time) as unix_sent_time from tells where bot=? and to_nick=?");
$state->{'prepare'}->('seen.clear_tells', "delete from tells where bot=? and to_nick=?");
$state->{'prepare'}->('seen.insert_tell', "insert into tells (bot, to_nick, from_nick, message) values (?,?,?,?)");
$state->{'prepare'}->('seen.mark_notified', "update tells set notified='true' where bot=? and to_nick=?");
$state->{'prepare'}->('seen.check_unnotified', "select * from tells where notified='false' and bot=? and to_nick=?");

$seen = sub {
  my ($state, $line) = @_;
  my ($nick, $seen_hash, $pretty_diff_time, $response);

  if (!defined $state->{'seen.hash'}) {
    $state->{'seen.hash'} = {};
  }

  if ($state->{'parameters'}->($line) =~ /^[>?]seen (.*)$/) {
    $nick = $1;
    $seen_hash = $state->{'seen.hash'}->{lc($nick)};

    if (lc($nick) eq lc($state->{'nick'})) {
      $response = $state->{'response'}->($line);
      $state->{'reply'}->($line, "$nick was last seen 0s ago in $response saying: " x 3 ."...");
    } elsif ($seen_hash) {
      $pretty_diff_time = $state->{'pretty_diff_time'}->($seen_hash->{'when'});

      $state->{'reply'}->($line, "$nick was last seen $pretty_diff_time ago in $seen_hash->{'channel'}, saying: $seen_hash->{'line'}");
    } else {
      $state->{'reply'}->($line, "No record of anyone with nick $nick.");
    }
  }
};

$log = sub {
  my ($state, $line) = @_;
  my ($nick, $channel);

  if (!defined $state->{'seen.hash'}) {
    $state->{'seen.hash'} = {};
  }

  if ($state->{'command'}->($line) =~ /^PRIVMSG (.*)$/) {
    $channel = $1;
    $nick = $state->{'sender_nick'}->($line);

    if ($channel =~ /^#/) {
      $state->{'seen.hash'}->{lc($nick)} = {nick => $nick, channel => $channel, line => $state->{'parameters'}->($line), when => time};
    }
  }
};

$save_tell = sub {
  my ($state, $line) = @_;
  my ($to, $from, $message);

  if ($state->{'parameters'}->($line) =~ /^[>?]tell (\S*) (.*)$/ or $state->{'parameters'}->($line) =~ /^[>?]ask (\S*) (.*)$/) {
    $to = $1;
    $message = $2;
    $from = $state->{'sender_nick'}->($line);

    $state->{'fetch'}->('seen.insert_tell', $state->{'nick'}, $to, $from, $message);
    $state->{'reply'}->($line, "Message saved for $to");
    warn "Message saved for $to from $from\n";
  }
};

$show_tells = sub {
  my ($state, $line) = @_;
  my ($to, @messages, $message, $pretty_diff_time);

  if ($state->{'parameters'}->($line) =~ /^[>?]tells$/) {
    $to = $state->{'sender_nick'}->($line);

    @messages = $state->{'fetch'}->('seen.get_tells', $state->{'nick'}, $to);
    $state->{'pm'}->($to, "You have ". scalar @messages ." unread messages");

    foreach $message (@messages) {
      $pretty_diff_time = $state->{'pretty_diff_time'}->($message->{'unix_sent_time'});
      $state->{'enqueue'}->("PRIVMSG $to :$pretty_diff_time ago - <$message->{'from_nick'}> $message->{'message'}\r\n");
    }

    $state->{'fetch'}->('seen.clear_tells', $state->{'nick'}, $to);
  }
};

$notify_tells = sub {
  my ($state, $line) = @_;
  my ($to, @messages);

  $to = $state->{'sender_nick'}->($line);
  @messages = $state->{'fetch'}->('seen.check_unnotified', $state->{'nick'}, $to);

  if (scalar @messages > 0) {
    # if we have un-notified messages
    @messages = $state->{'fetch'}->('seen.get_tells', $state->{'nick'}, $to);

    $state->{'reply'}->($line, "$to: you have ". scalar @messages ." unread messages. Type '>tells' to view.");
  @messages = $state->{'fetch'}->('seen.mark_notified', $state->{'nick'}, $to);
  }
};

&callback($state, "seen.seen", $seen);
&callback($state, "seen.log", $log);
&callback($state, "seen.save_tell", $save_tell);
&callback($state, "seen.show_tells", $show_tells);
&callback($state, "seen.notify_tells", $notify_tells);

