use strict;
use warnings;

push @::public_commands , 'vote';

sub cmd_vote($$$$$) {
	my ($kernel, $heap, $userinfo, $chan, $msg) = @_;
	
	return unless $msg =~ /^([A-Za-z0-9]+)/ ;
	
	my $kickee = lc $msg;
	my $kicker = "$userinfo->{user}\@$userinfo->{host}";
	
	if ( $kickee eq $::botnick ) {
		$kernel->post( $::botalias, 'privmsg', $::cservice{'nick'}, "ban @{$chan}[0] $userinfo->{nick} No");
#		$kernel->post( $::botalias, 'privmsg', 'GK|green', "ban @{$chan}[0] $userinfo->{nick} No");
		return ;
	}
	
	if( not exists $::vote{$kickee} ) {
		$::vote{$kickee}{$kicker} = scalar time;
		$::vote{$kickee}{time} = scalar time;
		$::vote{$kickee}{total} = 1;
		
		return;
	}
	
	if( exists $::vote{$kickee} ) {
		# Someone already voted!
		if( exists $::vote{$kickee}{$kicker} ) {
			# Double vote. Nigger.
			$kernel->post( $::botalias, 'privmsg', $chan, "Don't be a nigger $userinfo->{nick}." );
			return ;
		}
		
		++$::vote{$kickee}{total};
		$::vote{$kickee}{time} = scalar time;
		$::vote{$kickee}{$kicker} = scalar time;
		
		# Time to kick?
		if( $::vote{$kickee}{total} >= 3 ) {
			$kernel->post( $::botalias, 'privmsg', $chan, "You are the weakest link. Goodbye $kickee!" );
			delete $::vote{$kickee};
			
			$kernel->post( $::botalias, 'privmsg', $::cservice{'nick'}, "ban @{$chan}[0] $kickee Too many votes!");
			return ;
		}
		
		return ;
	}
}
