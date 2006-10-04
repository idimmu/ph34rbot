use strict;
use warnings;

use URI::Escape qw(uri_escape);

push @::public_commands, 'addscore';

sub cmd_addscore($$$$$) {
  my ($kernel, $heap, $userinfo, $chan, $msg) = @_;

  my @religions = ('islam', 'christianity', 'buddhism','hinduism',
		   'judaism', 'sikhism', 'shintoism','scientology');

  unless($msg =~ /^(\S+)\s+(.*)$/){
    $kernel->post( $::botalias, 'privmsg', $chan, "Usage: paddscore <religion> <url>");
    return;
  }

  my $religion = $1;
  my $url = $2;

  my @chosen = grep(/$religion/i, @religions);

  if(scalar(@chosen) != 1) {
    $kernel->post( $::botalias, 'privmsg', $chan, "paddscore <religion> (must be uniquely one of ".
		   join(', ', sort(@religions)).")");
    return;
  }

  my $chosen = $chosen[0];

  $url = uri_escape($url);

  my $check = append_file("$chosen $url", 'score');

  if($check){
    $kernel->post( $::botalias, 'privmsg', $chan, "Added point for $chosen");
  }else{
    $kernel->post( $::botalias, 'privmsg', $chan, "Server reported: $!. Error adding point for '$chosen'" );
  }
}

1;
