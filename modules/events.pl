# module events
use IO::Socket;

my (@ping_list, $pings, $connect, $send);

@ping_list = qw(Spock Data);

$connect = sub {
  my ($state, $reconnect) = @_;
  my ($sock);

  if ($reconnect > 0 or not defined $state->{'events.sock'}) {
    $sock = IO::Socket::INET->new(PeerAddr => 'localhost', PeerProto => 'tcp', PeerPort => 8960);
    if (not $sock) {
      warn "could not connect to monitor-server";
      return;
    }
    binmode $sock;
    print $sock "source\n";
    $state->{'events.sock'} = $sock;
  }
};

$pings = sub {
  my ($state, $line) = @_;
  my ($nick, $text, $from);

  if (not defined $state->{'events.sock'}) {
    return;
  }
  $text = $state->{'parameters'}->($line);
  $from = $state->{'sender_nick'}->($line);

  foreach $nick (@ping_list) {
    if ($text =~ /^$nick: /i) {
      $state->{'events.send'}->("Ping $from $text");
    }
  }
};

$send = sub {
  my ($state, $line) = @_;
  my ($sock);

  $sock = $state->{'events.sock'};

  print $sock "$line\n";
  $sock->flush;
};

&callback($state, "events.pings", $pings);
&callback($state, "events.connect", $connect);
&callback($state, "events.send", $send);

