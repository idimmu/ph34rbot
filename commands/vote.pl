use strict;
use warnings;

push @::public_commands , 'vote';
push @::public_commands , 'votestatus';

sub expire_bans() {
	my $time = scalar time;
	
	foreach my $nick (keys %::vote) {
		if ($::vote{$nick}->{time} < ($time - 3600)) {
			# Need to expire this vote
			delete $::vote{$nick};
		}
	}
}

sub cmd_vote($$$$$) {
	my ($kernel, $heap, $userinfo, $chan, $msg) = @_;
	
	return unless $msg =~ /^([A-Za-z0-9_\-[\]\\`\^{}|]+)/ ;
	
	expire_bans();
	
	my $time = scalar time;
	
	my $special = '^(time|total)$';

	my $kickee = lc $1;
	my $kicker = "$userinfo->{user}\@$userinfo->{host}";
	
	if ( $kickee eq lc($::botnick) ) {
		my $autoban = "ban @{$chan}[0] $userinfo->{nick} No";
		$kernel->post( $::botalias, 'privmsg', $::cservice{'nick'}, $autoban);
		return ;
	}
	
	if( not exists $::vote{$kickee} ) {
		$::vote{$kickee}{$kicker} = $userinfo->{nick};
		$::vote{$kickee}{time} = $time;
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
			
			my $message = "";
			
			if( rand 10 < 5 ) {			
				$message = "ban @{$chan}[0] $kickee You are hated by $kickreason!";
			} else {
				$message = "voice @{$chan}[0] $kickee";
			}
			$kernel->post( $::botalias, 'privmsg', $::cservice{'nick'}, $message);
			return ;
		}
		
		return ;
	}
}

sub cmd_votestatus($$$$$) {
	my ($kernel, undef, undef, $chan, undef) = @_;
	
	expire_bans();
	
	my $string;
	
	foreach my $nick (sort keys %::vote) {
		$string .= "$nick (" . $::vote{$nick}->{total} . ")  ";
	}
	
	if( $string eq "" ) {
		$kernel->post( $::botalias, 'privmsg', $chan, 'Noone is scheduled for destruction.' );
	} else {
		$kernel->post( $::botalias, 'privmsg', $chan, $string );
	}
}
