use strict;
use warnings;

push @::public_commands , 'roll';

#elsif($msg =~ /^proll\s*(\d*)(\#)?(\d*)d(\d+)([+|-]\d+)?(\s*.*)$/i){
#    my ($numrolls, $hash, $diceprroll, $numbsides, $modifier, $comment) = ( $1, $2, $3, $4, $5, $6 );
#    #$kernel->post( $::botalias, 'privmsg', $chan, "$numrolls, $hash, $diceprroll, $numbsides, $modifier, $comment");
#    $numrolls = 1 unless $numrolls;
#    $diceprroll = 1 unless $diceprroll;
#    #$comment = " $comment" if $comment;
#    my @results;
#    my $total;
#    if($hash){
#	for(my $i = 0; $i < $numrolls && $numrolls < 100; $i++){
#        push @results, roll_dice( $diceprroll, $numbsides, $modifier );
#        $total += $results[$i];
#      }
#      my $rolltype = join('', $numrolls, '#', $diceprroll, 'd', $numbsides, $modifier, "$comment");
#      my $rolls = join(', ', @results);
#      $kernel->post( $::botalias, 'ctcp', $chan, "ACTION ---> $nick rolls $rolltype and gets $rolls = $total");
#    }else{
#      my $total;
#      for(my $i = 0; $i < $numrolls && $numrolls < 100; $i++){
#        $total += int(rand($numbsides)) + 1;
#      }
#      $total += $modifier;
#
#      my $rolltype = join('', $numrolls, 'd', $numbsides, $modifier, "$comment");
#      $kernel->post( $::botalias, 'ctcp', $chan, "ACTION ---> $nick rolls $rolltype and gets $total");
#    }
#  }

sub cmd_roll($$$$$) {
        my ($kernel, $heap, $userinfo, $chan, $msg) = @_;
	
	return unless $msg =~ /^(\d*)(#)?(\d+)d(\d+)([+-]\d+)?/;
	
	my ($numrolls, $hash, $diceperroll, $numsides, $modifier) =
	  ($1, $2, $3, $4, $5);
	
	$numrolls = 1 unless $numrolls;
				      
        #print "$numrolls, $hash, $diceperroll, $numsides, $modifier\n";
	
	my @results;
	my $total;
	
	if($hash) {
		for( my $i = 0 ; $i < $numrolls and $numrolls < 100 ; ++$i) {
			push @results, roll_dice($diceperroll, $numsides, $modifier);
			$total += $results[$i];
		}
		
		my $rolltype = join('', $numrolls, '#', $diceperroll, 'd', $numsides, $modifier);
		my $rolls = join(', ', @results);
		$kernel->post( $::botalias, 'ctcp', $chan, "ACTION ---> " . $userinfo->{'nick'} . " rolls $rolltype and gets $rolls = $total");
	} else {
		my $total;
		for( my $i = 0 ; $i < $diceperroll and $i < 100 ; ++$i) {
			$total += int(rand($numsides)) + 1;
		}
		
		$total += $modifier if $modifier;
		
		my $rolltype = join('', $diceperroll, 'd', $numsides, $modifier);
		$kernel->post( $::botalias, 'ctcp', $chan, "ACTION ---> $userinfo->{nick} rolls $rolltype and gets $total");
	}
}

1;
