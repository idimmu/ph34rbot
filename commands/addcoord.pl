use strict;
use warnings;

push @::public_commands , 'addcoord';

sub cmd_addcoord($$$$$) {
    my ($kernel, $heap, $who, $chan, $msg) = @_;

    return unless lc($chan->[0]) eq '#desse';


    unless($msg =~ /^(\d{1,3}:\d{1,2}:\d{1,3})\s+(\S+)\s*(\S+)?\s+(P|F|N|E)$/){
	$kernel->post( $::botalias, 'privmsg', $chan, "Use the format 'paddcoord xxx:xx:xx nick alliance P/F/N/E' (Pr0nstar, Friend, Neutral, Enemy) (alliance is optional)" );
	return;
    }
    
    my $input = join ' ',$1,$2,$3,$4;
    my $check = append_file($input, 'coord');
    if($check){
        $kernel->post( $::botalias, 'privmsg', $chan, "Added coord -> $input" );
    }else{
        $kernel->post( $::botalias, 'privmsg', $chan, "Server reported: $!. Error adding coord: '$input'" );
    }    
}

1;
