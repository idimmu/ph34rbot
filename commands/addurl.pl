use strict;
use warnings;
use URI::Escape qw(uri_escape);

push @::public_commands , 'addurl';

#  }elsif($msg =~ /^paddurl\s*(.+)$/i){ # someone's adding a url
#    my $url = $1;
#    $url =~ s/^http:\/\///;
#    my @url = split('/', $url);
#    foreach (@url){ s/([^\w()'*~!.-])/sprintf '%%%02x', ord $1/eg }
#    $url = 'http://'.join('/', @url);
#    #or just import CGI::Lite and use urlencode...
#
#    my $check = append_file($url, 'url');
#    if($check){
#      $kernel->post( $::botalias, 'privmsg', $chan, "Added added url -> $url");
#    }else{
#      $kernel->post( $::botalias, 'privmsg', $chan, "Server reported: $!. Error adding url '$url'");
#    }

sub cmd_addurl($$$$$) {
    my ($kernel, $heap, $userinfo, $chan, $msg) = @_;
    
    return unless $msg;
    
    my $url = uri_escape($msg);

    my $check = append_file($url, 'url');
    if($check){
	$kernel->post( $::botalias, 'privmsg', $chan, "Added added url -> $msg");
    }else{
	$kernel->post( $::botalias, 'privmsg', $chan, "Server reported: $!. Error adding url '$msg'");
    }
}
