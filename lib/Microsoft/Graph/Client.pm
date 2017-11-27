package Microsoft::Graph::Client;

use strict;
use warnings;

use URI::Escape;
use JSON::MaybeXS;
use Carp qw(croak);
use LWP::UserAgent;
use HTTP::Request::Common qw(GET POST DELETE);

sub new {
  my ($class, $args) = @_;

  return bless {}, $class;
}

sub make_query_string {
  my ($self, $arguments) = @_;

  if(ref $arguments eq 'HASH') {
    my @pairs;

    foreach my $key (keys %{$arguments}) {
      push @pairs, uri_escape($key) . '=' . uri_escape($$arguments{$key})
    }

    return join '&', @pairs
  }
}

sub send_request {
  my ($self, $req, $decode_json) = @_;

  my $res = $self->{ua}->request($req);

  if($res->is_success) {
    return decode_json($res->decoded_content), $res if $decode_json;
    return $res->decoded_content, $res
  }

  croak $res->decoded_content
}

1;