use strict;
use warnings;
use URI::Escape qw(uri_escape);

push @::public_commands , 'e2';

#}elsif($msg =~ /^pe2\s*(.*)$/i){ #someone wants an e2 url.
#my $e2 = $1;
#$e2 =~ s/([^\w()'*~!.-])/sprintf '%%%02x', ord $1/eg;
#$kernel->post( $::botalias, 'privmsg', $chan, "pe2 -> http://everything2.com/index.pl?node=$e2");
# urlify the query, then staple it on the end of the e2 url.
# some day I'll make it check for actual existance of a requested node and possibly return
# suggestions based on the search if it doesn't find a node... some day...


sub cmd_e2($$$$$) {
    my ($kernel, $heap, $userinfo, $chan, $msg) = @_;
    
    return unless $msg;

    my $e2 = uri_escape($msg);
    $kernel->post( $::botalias, 'privmsg', $chan, "pe2 -> http://everything2.com/index.pl?node=$e2");
}
