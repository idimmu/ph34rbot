use strict;
use warnings;
use URI::Escape qw(uri_escape);

push @::public_commands , 'wiki';

sub cmd_wiki($$$$$) {
    my ($kernel, $heap, $userinfo, $chan, $msg) = @_;

    return unless $msg;

    my $e2 = uri_escape($msg);
    $kernel->post( $::botalias, 'privmsg', $chan, "pwiki -> http://en.wikipedia.org/wiki/Special:Search?search=$e2&go=Go");
}

