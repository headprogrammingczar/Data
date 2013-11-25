# module queue
my ($enqueue, $dequeue);

$enqueue = sub {
  my ($state, $line) = @_;

  if (defined $state->{'queue'}) {
    push(@{$state->{'queue'}}, $line);
  } else {
    $state->{'queue'} = [$line];
  }
};

$dequeue = sub {
  my ($state) = @_;

  if (defined $state->{'queue'}) {
    return '';
  } else {
    return shift(@{$state->{'queue'}});
  }
};

&callback($state, 'enqueue', $enqueue);
&callback($state, 'dequeue', $dequeue);

