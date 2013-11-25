# module irc
use URI::Escape;

my ($write, $pm, $prefix, $command, $parameters, $sender_nick, $response, $reply, $pretty_diff_time, $url_escape, $url_unescape, $truncate);

$write = sub {
  my ($state, $line) = @_;
  my ($fh);

  $fh = $state->{'socket'};

  $line = substr($line, 0, 450);

  print $fh "$line\n";
};

$pm = sub {
  my ($state, $dest, $line) = @_;

  $state->{'write'}->("PRIVMSG $dest :$line");

  if ($state->{'precog.add_line'}) {
    $state->{'precog.add_line'}->($dest, $state->{'nick'}, $line);
  }
};

$prefix = sub {
  my ($state, $line) = @_;

  if ($line =~ /^:(\S+) /) {
    return $1;
  } else {
    return '';
  }
};

$command = sub {
  my ($state, $line) = @_;

  $line =~ s/^:\S+ //;

  if ($line =~ /^([^:]*) :.*$/) {
    return $1;
  } else {
    return '';
  }
};

$parameters = sub {
  my ($state, $line) = @_;

  $line =~ s/^:\S+ //;
  $line =~ s/^[^:]*://;
  $line =~ s/^\s*(.*)/$1/;
  $line =~ s/(.*?)\s*$/$1/;

  return $line;
};

$sender_nick = sub {
  my ($state, $line) = @_;

  if ($state->{'prefix'}->($line) =~ /^([^!]+)!/) {
    return $1;
  } else {
    return '';
  }
};

$response = sub {
  my ($state, $line) = @_;
  my ($command);

  $command = $state->{'command'}->($line);

  if ($command =~ /^\S+ (#\S+)/) {
    return $1;
  } else {
    return $state->{'sender_nick'}->($line);
  }
};

$reply = sub {
  my ($state, $line, $reply) = @_;

  $state->{'pm'}->($state->{'response'}->($line), $reply);
};

$pretty_diff_time = sub {
  my ($state, $time) = @_;
  my ($now, $pretty_time, $day, $hour, $minute, $second);

  $now = time;
  $time = int($now - $time);

  $second = $time % 60; $time = int($time / 60);
  $minute = $time % 60; $time = int($time / 60);
  $hour = $time % 24; $time = int($time / 24);
  $day = $time;
  $pretty_time = '';

  if ($day > 0) {
    $pretty_time .= $day .'d ';
  }

  if ($hour > 0) {
    $pretty_time .= $hour .'h ';
  }

  if ($minute > 0) {
    $pretty_time .= $minute .'m ';
  }

  $pretty_time .= $second .'s';

  return $pretty_time;
};

# easier than importing each time
$url_escape = sub {
  my ($state, $string) = @_;

  return &URI::Escape::uri_escape_utf8($string);
};

$url_unescape = sub {
  my ($state, $string) = @_;

  return &URI::Escape::uri_unescape($string);
};

$truncate = sub {
  my ($state, $size, $line) = @_;

  if (length $line > $size) {
    $line = substr($line, 0, $size) ."...";
  }

  return $line;
};

&callback($state, "write", $write);
&callback($state, "pm", $pm);
&callback($state, "prefix", $prefix);
&callback($state, "command", $command);
&callback($state, "parameters", $parameters);
&callback($state, "sender_nick", $sender_nick);
&callback($state, "response", $response);
&callback($state, "reply", $reply);
&callback($state, "pretty_diff_time", $pretty_diff_time);
&callback($state, "url_escape", $url_escape);
&callback($state, "url_unescape", $url_unescape);
&callback($state, "truncate", $truncate);

