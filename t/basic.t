use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use Plack::Test;
use HTML::Mason::PlackHandler;
use Cwd qw(abs_path);

(my $comp_root = abs_path(__FILE__)) =~ s![^/]*$!tpl!;

my $mason = HTML::Mason::PlackHandler->new(
  error_mode => 'fatal',
  comp_root  => $comp_root,
);

test_psgi(
  app    => sub { $mason->handle_request(@_) },
  client => sub {
    my $cb = shift;
    {
      my $res = $cb->(GET "http://localhost/index.html");
      is $res->code, 200;
      is $res->content, "before\nindex\nafter\n";

      $res = $cb->(GET "http://localhost/missing");
      is $res->code, 404;

      $res = $cb->(GET "http://localhost/params?abc=1;def=2");
      is $res->code, 200;
      is $res->content, "before\nabc=1\ndef=2\nafter\n";

      $res = $cb->(GET "http://localhost/args?abc=1;def=9&abc=3");
      is $res->code, 200;
      is $res->content, "before\nabc=1\nabc=3\ndef=9\nafter\n";

      $res = $cb->(GET "http://localhost/args?abc=1;def=9");
      is $res->code, 200;
      is $res->content, "before\nabc=1\ndef=9\nafter\n";

      $res = $cb->(GET "http://localhost/headers", 'X-Test' => "AbC");
      is $res->header('X-Test'), "AbC";

      $res = $cb->(GET "http://localhost/redirect");
      is $res->code, 302;
      is $res->header('Location'), "/goto";

      $res = $cb->(GET "http://localhost/redirect_301");
      is $res->code, 301;
      is $res->header('Location'), "/goto301";
    }
  }
);

done_testing;

