use strict;
use warnings;

push @::public_commands , 'ubcoord';

sub cmd_ubcoord($$$$$) {
    my ($kernel, $heap, $who, $chan, $msg) = @_;

    return unless lc($chan->[0]) eq '#desse' || lc($chan->[0]) eq '#sqrl-fu';

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
            $kernel->post( $::botalias, 'privmsg', $chan, "-> $_" );
        }
    }else{
        $kernel->post( $::botalias, 'privmsg', $chan, "No info on $msg" );
    }

}

1;
