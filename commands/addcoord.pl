use strict;
use warnings;

push @::public_commands , 'addcoord';

sub cmd_test($$$$$) {
    my ($kernel, $heap, $who, $chan, $msg) = @_;
    
    return unless $chan eq '#desse';

    unless($msg =~ /^(\d\d?\d?:\d\d?:\d\d?)\s+(\S+)\s+(P|F|N|E)$/){
	$kernel->post( $botalias, 'privmsg', $chan, "Use the format 'paddcoord nick xxx:xx:xx P/F/N/E' (Pr0nstar, Friend, Neutral, Enemy)" );
	return;
    }
    
    my $input = join ' ',$1,$2,$3;
    my $check = append_file($input, 'coords');
    if($check){
        $kernel->post( $botalias, 'privmsg', $chan, "Added coords -> $input" );
    }else{
        $kernel->post( $botalias, 'privmsg', $chan, "Server reported: $!. Error adding coords: '$input'" );
    }    
}

1;
