# module join
my ($join, $part, $kick, $invite);

$state->{'prepare'}->('select_channels', "select * from channels where bot=?");
$state->{'prepare'}->('drop_channel', "delete from channels where channel=? and bot=?");
$state->{'prepare'}->('add_channel', "insert into channels (channel, bot) values (?,?)");

$join = sub {
  my ($state) = @_;
  my (@channels, $channel);

  @channels = $state->{'fetch'}->('select_channels', $state->{'nick'});

  foreach (@channels) {
    $channel = $_->{'channel'};
    $state->{'write'}->("JOIN $channel");
  }
};

#$misc = sub {
#  my ($state, $line) = @_;
#  my ($nick, $chan);
#
#  if ($line =~ /^INVITE :(.*)$/) {
#    $chan = $1;
#  } elsif ($line =~ /^KICK ([^\s]*) ([^\s]*) :(.*)$/) {
#    $chan = $1;
#    $nick = $2;
#  } elsif ($state->{'parameters'}->($line) =~ /^[>?]part$/) {
#    $chan = $state->{'response'}->($line);
#    if ($chan =~ /^#/) {
#    }
#  }
#};

$part = sub {
  my ($state, $line) = @_;
  my ($chan);

  if ($state->{'parameters'}->($line) =~ /^[>?]part$/) {
    $chan = $state->{'response'}->($line);
    if ($chan =~ /^#/) {
      $state->{'write'}->("PART $chan");
      $state->{'fetch'}->('drop_channel', $chan, $state->{'nick'});
    }
  }
};

$invite = sub {
  my ($state, $line) = @_;
  my ($chan, $nick);

  if ($state->{'command'}->($line) =~ /^INVITE (.*)$/) {
    $nick = $1;
    if ($nick eq $state->{'nick'}) {
      $chan = $state->{'parameters'}->($line);
      $state->{'write'}->("JOIN $chan");
      $state->{'fetch'}->('add_channel', $chan, $state->{'nick'});
    }
  }
};

$kick = sub {
  my ($state, $line) = @_;
  my ($chan, $nick);

  if ($state->{'command'}->($line) =~ /^KICK ([^\s]*) ([^\s]*)$/) {
    $chan = $1;
    $nick = $2;
    if ($nick eq $state->{'nick'}) {
      $state->{'fetch'}->('drop_channel', $chan, $state->{'nick'});
    }
  }
};

&callback($state, "join.join_channels", $join);
&callback($state, "join.part", $part);
&callback($state, "join.invite", $invite);
&callback($state, "join.kick", $kick);

