use strict;
use warnings;

push @::public_commands , 'quote';

#  }elsif($msg =~ /^pquote\s*(.*)$/i){ # asking for a quote
#    my ($quote, $quotenr, $quotetotal) = random_list_element($1, 'quote');#get a random line from $::lists{'quote'}
#    if($quote){
#      my @prints = multiline_reformat("Quote $quotenr (of $quotetotal) -> $quote", 425, ' ');
#      foreach (@prints){
#        $kernel->post( $::botalias, 'privmsg', $chan, $_);
#      }
#    }else{
#      if($1){
#        $kernel->post( $::botalias, 'privmsg', $chan, "No quote matching '$1' found");
#      }else{
#        $kernel->post( $::botalias, 'privmsg', $chan, "No quotes found");
#      }
#    }

sub cmd_quote($$$$$) {
    my ($kernel, $heap, $userinfo, $chan, $msg) = @_;

    my ($quote, $quotenr, $quotetotal) = random_list_element($msg, 'quote');
    
    if($quote){
	my @prints = multiline_reformat("Quote $quotenr (of $quotetotal) -> $quote", 425, ' ');
	foreach (@prints){
	    $kernel->post( $::botalias, 'privmsg', $chan, $_);
	}
    }else{
	if($msg){
	    $kernel->post( $::botalias, 'privmsg', $chan, "No quote matching '$msg' found");
	}else{
	    $kernel->post( $::botalias, 'privmsg', $chan, "No quotes found");
	}
    }
}
