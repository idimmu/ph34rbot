use strict;
use warnings;

push @::public_commands , 'coord';

sub cmd_coord($$$$$) {
    my ($kernel, $heap, $who, $chan, $msg) = @_;

    return unless lc($chan->[0]) eq '#desse';
    
    my $found = 0;
    my @coords;
    foreach(@{$::lists{'coord'}}){
	if(/$msg/i){
	    $found = 1;
	    push @coords, $_;
	}
    }
    if($found){
	# welcome to the sort from hell! (do cluster, then parallel, then z coord)
	my @sorted_coords;
	@sorted_coords =  sort {
	    ($a =~ /^(\d+)/)[0] <=> ($b =~ /^(\d+)/)[0]
		||
		($a =~ /:(\d+)/)[0] <=> ($b =~ /:(\d+)/)[0]
		||
		($a =~ /:(\d+)\s/)[0] <=> ($b =~ /:(\d+)\s/)[0]
	    } @coords;
	foreach (@sorted_coords){
	    if($found++ < 6){
		$kernel->post( $::botalias, 'privmsg', $chan, "-> $_" );
	    }else{
		$kernel->post( $::botalias, 'privmsg', $who->{'nick'}, "-> $_" );
	    }
	    
	}
    }else{
	$kernel->post( $::botalias, 'privmsg', $chan, "No info on $msg" );
    }

}

1;
