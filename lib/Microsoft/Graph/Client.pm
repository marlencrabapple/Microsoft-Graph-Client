package Microsoft::Graph::Client;

use strict;
use warnings;

use URI::Escape;
use JSON::MaybeXS;
use Carp qw(croak);
use LWP::UserAgent;
use HTTP::Request::Common qw(GET POST DELETE);

our $api_base_url = 'https://graph.microsoft.com/v1.0';

sub new {
  my ($class, $args) = @_;

  $$args{scope} = join(' ', @ { $$args{scope} })
    if(ref $$args{scope} eq 'ARRAY');

  croak "Missing scope(s)." unless $$args{scope};
  croak "Missing client ID." unless $$args{client_id};
  croak "Missing client secret." unless $$args{client_secret};
  croak "Missing redirect uri." unless $$args{redirect_uri};
  croak "Missing tenant." unless $$args{tenant};

  my $attribs = {
    client_id => $$args{client_id},
    client_secret => $$args{client_secret},
    tenant => $$args{tenant},
    scope => $$args{scope},
    redirect_uri => $$args{redirect_uri}
  };

  $$attribs{oauth_base_uri} = "https://login.microsoftonline.com/$$args{tenant}/oauth2/v2.0";

  my $self = bless {}, $class;

  $$self{attribs} = $attribs;
  $$self{ua} = LWP::UserAgent->new;

  return $self
}

sub get_user_authorization_uri {
  my ($self, $args) = @_;

  my $query_hashref = $args;
  $$query_hashref{client_id} = $$self{attribs}->{client_id};
  $$query_hashref{redirect_uri} = $$self{attribs}->{redirect_uri};
  $$query_hashref{scope} = $$self{attribs}->{scope};
  $$query_hashref{response_type} = 'code';
  
  $$self{'authorization_data'} = { %{ $query_hashref } };

  my $query_string = $self->make_query_string($query_hashref);
  my $uri = "$$self{attribs}->{oauth_base_uri}/authorize?$query_string";

  return $uri
}

sub get_tokens {
  my ($self, $code) = @_;

  croak "Missing authorization code." unless $code;

  my $form_vars = {
    client_id => $$self{attribs}->{client_id},
    client_secret => $$self{attribs}->{client_secret},
    redirect_uri => $$self{attribs}->{redirect_uri},
    grant_type => 'authorization_code',
    scope => $$self{attribs}->{scope},
    code => $code
  };

  my $req = POST "$$self{attribs}->{oauth_base_uri}/token", $form_vars;

  my ($content, $res) = $self->send_request($req, { decode_json => 1 });

  return $content
}

sub refresh_tokens {
  my ($self, $refresh_token) = @_;

  croak "Missing refresh token." unless $refresh_token;

  my $form_vars = {
    client_id => $$self{attribs}->{client_id},
    client_secret => $$self{attribs}->{client_secret},
    redirect_uri => $$self{attribs}->{redirect_uri},
    grant_type => 'refresh_token',
    refresh_token => $refresh_token,
    scope => $$self{attribs}->{scope}
  };

  my $req = POST "$$self->{attribs}->{oauth_base_uri}/token", $form_vars;

  my ($content, $res) = $self->send_request($req, { decode_json => 1 });

  return $content
}

sub list_people {
  my ($self) = @_;
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
  my ($self, $req, $args) = @_;

  $args = ref $args eq 'HASH' ? $args : {};

  $req->header('Authorization', "Bearer $$args{bearer_token}")
    if $$args{bearer_token};

  my $res = $self->{ua}->request($req);

  if($res->is_success) {
    return decode_json($res->decoded_content), $res if $$args{decode_json};
    return $res->decoded_content, $res
  }

  croak $res->decoded_content
}

1;