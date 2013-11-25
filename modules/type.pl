# module type
use IO::CaptureOutput;
use Encode;

my ($type, $ghci);

$type = sub {
  my ($state, $expr) = @_;
  my ($out, $err, $success, $exit);

  &IO::CaptureOutput::capture(sub {$state->{'type.ghci'}->($expr)}, \$out, \$err);
};

# prints stuff to stdout/err, which gets captured by $type
$ghci = sub {
  my ($state, $expr) = @_;

  # open handle
  # import L.hs
  # type of expression
  # :q
  # close handle
};

&callback($state, "type.type", $type);
&callback($state, "type.ghci", $ghci);

