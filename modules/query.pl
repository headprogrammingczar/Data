# module query
use DBI;

my ($connect, $prepare, $fetch, $disconnect);

$connect = sub {
  my ($state, $string, $user, $pass) = @_;
  my ($dbh);

  $dbh = DBI->connect($string, $user, $pass);

  $state->{'dbh'} = $dbh;
};

$prepare = sub {
  my ($state, $name, $query) = @_;
  my ($sth);

  $sth = $state->{'dbh'}->prepare($query);

  $state->{$name} = $sth;
};

$fetch = sub {
  my ($state, $query, @params) = @_;
  my ($sth, $rv, $i, @rows);

  $sth = $state->{$query};

  $rv = $sth->execute(@params);

  @rows = ();

  if ($sth->{'Statement'} =~ /^select/i) {
    for ($i = 0; $i < $rv; $i++) {
      push(@rows, $sth->fetchrow_hashref());
    }
    $sth->finish();

    return @rows;
  } else {
    $sth->finish();
    return $rv;
  }
};

$disconnect = sub {
  my ($state) = @_;

  $state->{'dbh'}->disconnect();
};

&callback($state, "connect_db", $connect);
&callback($state, "prepare", $prepare);
&callback($state, "fetch", $fetch);
&callback($state, "disconnect_db", $disconnect);

