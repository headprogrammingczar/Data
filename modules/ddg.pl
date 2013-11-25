# module ddg
use WWW::DuckDuckGo;

my ($zcb, $printinfo, $printcategory, $ddg, $mangle, $related, $get_related_from_array);

# send a request, then reply back with the answer
$zcb = sub {
  my ($state, $line, $term) = @_;
  my ($info, $valid_search);

  $term =~ s/^\//\\/;

  # make a ddg object that only uses https and doesn't use any content filtering
  if (!defined $state->{'ddg.duck'}) {
    $state->{'ddg.duck'} = WWW::DuckDuckGo->new(forcesecure=>1, http_agent_name=>'Data IRC Bot - WWW::DuckDuckGo');
  }

  # wrapped in an eval because sometimes WWW::DDG is a crashy piece of shit
  $valid_search = eval {
    $info = $state->{'ddg.duck'}->zeroclickinfo($term);
  };

  if ($valid_search) {
    $state->{'ddg.printinfo'}->($line, $info, $term);
  } else {
    $state->{'reply'}->($line, "You seem to have encountered a bug in WWW::DuckDuckGo.");
    print "Someone searched for \"$term\", but it crashed WWW::DuckDuckGo!\n";
    print $@;
  }
};

# magic formatting of content returned by duckduckgo
$printinfo = sub {
  my ($state, $line, $info, $term) = @_;
  my ($text, $src, $url);
  my ($topics, $categories, $see_also, $results, $i, $j, @also, $links, $topic, $also);
  my (@filtered_topics, @output, $category);

  # get related topics and categories
  ($topics, $categories, $see_also, $results) = $state->{'ddg.related'}->($info);

  if ($info->has_redirect && $info->redirect !~ /^var/) {
    $state->{'reply'}->($line, $info->redirect);
  } elsif ($info->has_answer) {
    $state->{'reply'}->($line, $info->answer);
  } elsif ($info->has_abstract_text && $info->has_abstract_source && $info->has_abstract_url) {
    # print text, followed by the source of the text and some related topics

    @also = ();

    $text = $state->{'ddg.mangle'}->($info->abstract_text);
    $src = $info->abstract_source;
    $url = $info->abstract_url;

    $state->{'reply'}->($line, $text);

    # after printing the info text, print the source
    push(@also, "\x02$src\x0f - $url");

    # and also print some related links
    for ($i = 0; $i < scalar @$topics && scalar @also < 2; $i++) {
      $topic = $topics->[$i];

      # ignore duckduckgo categories - their results are useless and wrong
      if ($topic->{'url'} !~ m[^https?://duckduckgo\.com/c/]) {
        $text = $state->{'truncate'}->(80, $topic->{'text'});
        push(@also, "\x02$text\x0f - $topic->{'url'}");
      }
    }

    for ($i = 0; $i < scalar @$results && scalar @also < 2; $i++) {
      $topic = $results->[$i];

      # ignore duckduckgo categories - their results are useless and wrong
      if ($topic->{'url'} !~ m[^https?://duckduckgo\.com/c/] && $topic->{'url'} ne $url) {
        $text = $state->{'truncate'}->(80, $topic->{'text'});
        push(@also, "\x02$text\x0f - $topic->{'url'}");
      }
    }

    $links = join(', ', @also);

    $state->{'reply'}->($line, $links);
  } elsif (scalar @$results > 0) {
    $also = $results->[0];
    $state->{'reply'}->($line, "$also->{'text'} - $also->{'url'}");
  } elsif ($info->has_type && $info->type eq 'D') {
    # on disambiguations, print the first topics in default topics, see also, and other categories (limit 3 lines of output)

    @filtered_topics = grep {$_->{'category'} eq '_'} @$topics;
    @output = ();

    if (scalar @filtered_topics > 0) {
      push(@output, $state->{'ddg.printcategory'}->(\@filtered_topics));
    }

    if (scalar @$see_also > 0) {
      push(@output, "\x02See Also\x0f: ". $state->{'ddg.printcategory'}->($see_also));
    }

    for ($i = 0; $i < scalar @$categories && scalar @output < 3; $i++) {
      $category = $categories->[$i]->{'name'};
      @filtered_topics = grep {$_->{'category'} eq $category} @$topics;
      @also = ();

      if (scalar @filtered_topics > 0) {
        push(@output, "\x02$category\x0f: ". $state->{'ddg.printcategory'}->(\@filtered_topics));
      }
    }

    foreach (@output) {
      $state->{'reply'}->($line, $_);
    }
  } elsif ($info->has_abstract_url && $info->has_abstract_source) {
    # we at least have SOME information to give

    $src = $info->abstract_source;
    $url = $info->abstract_url;

    $state->{'reply'}->($line, "\x02$src\x0f - $url");

    if (scalar @$see_also > 0) {
      $also = "\x02See Also\x0f: ". $state->{'ddg.printcategory'}->($see_also);

      $state->{'reply'}->($line, $also);
    }
  } else {
    # no info, so just print a URL to search ddg directly
    $state->{'reply'}->($line, "https://duckduckgo.com/?q=". $state->{'url_escape'}->($term));
    print "Someone searched for \"$term\", but no results could be displayed!\n";
  }
};

$printcategory = sub {
  my ($state, $topics) = @_;
  my ($topic, @accum, $i);

  @accum = ();

  for ($i = 0; $i < scalar @$topics && $i < 3; $i++) {
    $topic = $topics->[$i];
    push(@accum, "\x02$topic->{'text'}\x0f - $topic->{'url'}");
  }
  return join(', ', @accum);
};

# combine all the topics and categories
$related = sub {
  my ($state, $info) = @_;
  my (@topics, @categories, @see_also, @results, $link, $categories, $category, $title, $text, $topic);

  @topics = ();
  @categories = ();
  @see_also = ();
  @results = ();

  # grab default related topics first, as they are most relevant
  if ($info->has_default_related_topics) {
    foreach $topic ($state->{'ddg.get_related_from_array'}->('_', $info->default_related_topics)) {
      push(@topics, $topic);
    }
  }

  # now grab categories
  if ($info->has_related_topics_sections) {
    $categories = $info->related_topics_sections;

    # now read the see also
    if (defined $categories->{'See also'}) {
      foreach $topic ($state->{'ddg.get_related_from_array'}->('See also', $categories->{'See also'})) {
        push(@see_also, $topic);
      }
    }

    # remove the categories we have already processed, since we already did it above
    delete $categories->{'_'};
    delete $categories->{'See also'};

    foreach $category (sort keys %$categories) {
      push(@categories, {name=>$category, size=>scalar @{$categories->{$category}}});

      # while we are at it, grab subtopics

      foreach $topic ($state->{'ddg.get_related_from_array'}->($category, $categories->{$category})) {
        push(@topics, $topic);
      }
    }
  }

  # now grab results
  if ($info->has_results) {
    foreach $topic ($state->{'ddg.get_related_from_array'}->('Results', $info->results)) {
      push(@results, $topic);
    }
  }

  # smallest categories first - don't want all the results to say the same thing
  @categories = sort {$a->{'size'} <=> $b->{'size'}} @categories;

  return (\@topics, \@categories, \@see_also, \@results);
};

$get_related_from_array = sub {
  my ($state, $category, $links) = @_;
  my ($link, @related, $title);

  @related = ();

  foreach $link (@$links) {
    if ($link->has_first_url && $link->has_text && $link->has_result) {
      if ($link->result =~ m#<a href="[^"]*">(.*?)</a>#) {
        $title = $1;
      } else {
        $title = $state->{'truncate'}->(50, $link->text);
      }

      push(@related, {url=>$link->first_url, text=>$title, category=>$category});
    }
  }

  return @related;
};

# parse line, call functions if needed
$ddg = sub {
  my ($state, $line) = @_;
  my ($term);

  if ($state->{'parameters'}->($line) =~ /^[>?]ddg (.*)$/) {
    $term = $1;
    $state->{'ddg.zcb'}->($line, $term);
  }
};

$mangle = sub {
  my ($state, $text) = @_;

  # format code at the start of programming language queries - huge hack
  $text =~ s#<pre><code>##g;
  $text =~ s#</code></pre># -#g;

  # convert html to unicode
  $text =~ s/&#(\d+);/chr($1)/eg;

  return $text;
};

&callback($state, "ddg.zcb", $zcb);
&callback($state, "ddg.printinfo", $printinfo);
&callback($state, "ddg.printcategory", $printcategory);
&callback($state, "ddg.related", $related);
&callback($state, "ddg.get_related_from_array", $get_related_from_array);
&callback($state, "ddg.ddg", $ddg);
&callback($state, "ddg.mangle", $mangle);

