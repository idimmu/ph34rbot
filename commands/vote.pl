use strict;
use warnings;

push @::public_commands , 'vote';

sub cmd_vote($$$$$) {
	my ($kernel, $heap, $userinfo, $chan, $msg) = @_;
	
	return unless $msg =~ /^([A-Za-z0-9]+)/ ;
	
	my $special = '^(time|total)$';

	my $kickee = lc $1;
	my $kicker = "$userinfo->{user}\@$userinfo->{host}";
	
	if ( $kickee eq lc($::botnick) ) {
		$kernel->post( $::botalias, 'privmsg', $::cservice{'nick'}, "ban @{$chan}[0] $userinfo->{nick} No");
#		$kernel->post( $::botalias, 'privmsg', 'GK|green', "ban @{$chan}[0] $userinfo->{nick} No");
		return ;
	}
	
	if( not exists $::vote{$kickee} ) {
		$::vote{$kickee}{$kicker} = $userinfo->{nick};
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
		$::vote{$kickee}{$kicker} = $userinfo->{nick};
		
		# Time to kick?
		if( $::vote{$kickee}{total} >= 3 ) {
			# Construct comedy string
			my @haters;
			foreach my $key (keys %{$::vote{$kickee}}) {
				next if $key =~ /$special/;
				push @haters , $::vote{$kickee}{$key};
			}
			@haters = sort @haters;
			my $kickreason = "$haters[0], $haters[1] and $haters[2]";
		
			$kernel->post( $::botalias, 'privmsg', $chan, "You are the weakest link. Goodbye $kickee!" );
			delete $::vote{$kickee};
			
			$kernel->post( $::botalias, 'privmsg', $::cservice{'nick'}, "ban @{$chan}[0] $kickee You are hated by $kickreason!");
#			$kernel->post( $::botalias, 'privmsg', 'GK|green', "ban @{$chan}[0] $kickee You are hated by $kickreason!");
			return ;
		}
		
		return ;
	}
}
