use strict;
use warnings;

push @::public_commands , 'google';

#  if($msg =~ /^pgoogle (.*?)(\s\d\d?)?$/i){ # asking for a google
##    #$kernel->post( $::botnick, 'privmsg', $chan, 'pgoogle currently down due to excessive shitness' );
##    #return;
#    my $searchstring = $1;
#    my $returncount = $2 || 1;
#    if($searchstring eq '?' || $returncount < 0 || $returncount > 10){ #give help!
#      $kernel->post( $::botnick, 'privmsg', $chan, 'syntax: pgoogle <search> <1-10>'); #make a var for $googlehelp
#      return;
#    }
#    my $result = pgoogle($searchstring, $returncount);
#    unless($result){
#      $kernel->post( $::botalias, 'privmsg', $chan, "pgoogle: ($searchstring) no results found (blame Net::Google and/or the google api)" );
#      return; # no need to go any further
#    }
#    my @prints = multiline_reformat($result, 450, ' . ');# in case the line is too long
#    foreach (@prints){
#      $kernel->post( $::botalias, 'privmsg', $chan, "pgoogle: $_" );
#    }


sub cmd_google($$$$$) {
    my ($kernel, $heap, $userinfo, $chan, $msg) = @_;
    return unless $msg =~ /^(.*?)(\s\d\d?)?$/;
    
    my $searchstring = $1;
    my $returncount = $2 || 1;
    if($searchstring eq '?' || $returncount < 0 || $returncount > 10){ #give help!
	$kernel->post( $::botnick, 'privmsg', $chan, 'syntax: pgoogle <search> <1-10>'); #make a var for $googlehelp
	return;
    }

    my $result = pgoogle($searchstring, $returncount);

    unless($result){
	$kernel->post( $::botalias, 'privmsg', $chan, "pgoogle: ($searchstring) no results found (blame Net::Google and/or the google api)" );
    }else{
	my @prints = multiline_reformat($result, 450, ' . ');# in case the line is too long
	foreach (@prints){
	    $kernel->post( $::botalias, 'privmsg', $chan, "pgoogle: $_" );
	}
    }
}
