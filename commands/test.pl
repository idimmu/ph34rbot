use strict;
use warnings;

push @::public_commands , 'test';

sub cmd_test($$$$$) {
	my ($kernel, $heap, $who, $chan, $msg) = @_;
	
	$kernel->post( $::botnick, 'privmsg', $chan, 'Test succeeded: ' . $msg);
}

1;
