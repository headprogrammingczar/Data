# module macro
my ($response);

$response = sub {
  my ($state, $line) = @_;
};

&callback($state, "macro.response", $response);

