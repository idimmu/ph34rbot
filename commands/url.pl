use strict;
use warnings;
use URI::Escape qw(uri_unescape);

push @::public_commands , 'url';

#  }elsif($msg =~ /^purl\s*(.*)?$/i){ # asking for a url
#    my ($url, $urlnr, $urltotal) = random_list_element($1, 'url'); # get a url
#    if($url){
#      $kernel->post( $::botalias, 'privmsg', $chan, "url $urlnr (of $urltotal) -> $url");
#    }
#    }

sub cmd_url($$$$$) {
    my ($kernel, $heap, $userinfo, $chan, $msg) = @_;
    
    my ($url, $urlnr, $urltotal) = random_list_element($msg, 'url');
   
    if($url){
	$url = uri_unescape($url);
	$kernel->post( $::botalias, 'privmsg', $chan, "url $urlnr (of $urltotal) -> $url");
    }else{
	if($msg){
	    $kernel->post( $::botalias, 'privmsg', $chan, "No urls matching '$msg' found");
	}else{
	    $kernel->post( $::botalias, 'privmsg', $chan, "No urls found");
	}
    }
}
