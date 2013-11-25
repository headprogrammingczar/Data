# module help
my ($help);

$help = sub {
  my ($state, $line) = @_;
  my ($module, $help_page);

  $help_page = "http://hpc.dyndns-web.com:8000/data/docs.cgi";

  if ($state->{'parameters'}->($line) =~ /^[>?]help\s+(.*)$/) {
    $module = $1;
  } elsif ($state->{'parameters'}->($line) =~ /^[>?]help$/) {
    $module = "main";
  } elsif ($state->{'parameters'}->($line) =~ /^Data:?\s+help/) {
    $module = "main";
  } else {
    return;
  }

  if ($module eq 'precog') {
    $state->{'reply'}->($line, "$help_page?module=precog");
  } elsif ($module eq 'eval') {
    $state->{'reply'}->($line, "$help_page?module=eval");
  } elsif ($module eq 'hoogle') {
    $state->{'reply'}->($line, "$help_page?module=hoogle");
  } elsif ($module eq 'type') {
    $state->{'reply'}->($line, "$help_page?module=type");
  } elsif ($module eq 'seen') {
    $state->{'reply'}->($line, "$help_page?module=seen");
  } elsif ($module eq 'tell' or $module eq 'ask') {
    $state->{'reply'}->($line, "$help_page?module=tell");
  } elsif ($module eq 'tminus') {
    $state->{'reply'}->($line, "$help_page?module=tminus");
  } elsif ($module eq 'ddg') {
    $state->{'reply'}->($line, "$help_page?module=ddg");
  } elsif ($module eq 'misc' || $module eq 'stfu' || $module eq 'part' ||
           $module eq 'invite' || $module eq 'kick') {
    $state->{'reply'}->($line, "$help_page?module=misc");
  } else {
    $state->{'reply'}->($line, $help_page);
  }
};

&callback($state, "help.help", $help);

