use strict;
use warnings;

use URI::Escape qw(uri_unescape);

push @::public_commands, 'score';

sub cmd_score($$$$$) {
  my ($kernel, $heap, $userinfo, $chan, $msg) = @_;

  return unless $msg;
  
  my @religions = ('islam', 'christianity', 'buddhism',
		'hinduism', 'judaism', 'sikhism', 'shintoism',
		'scientology');

  my @chosen = grep(/$msg/i, @religions);
  if(scalar(@chosen) != 1) {
    $kernel->post( $::botalias, 'privmsg', $chan, "pscore <religion> (must be uniquely one of ".
		   join(', ', sort(@religions)).")");
    return;
  }

  my $chosen = $chosen[0];
  my ($score, $scorenr, $scoretotal) = random_list_element('^'.$chosen, 'score');

  if($score){

    my @url = $score =~ /$chosen (.*)/;
    my $url = $url[0];
    $url = uri_unescape($url);

    $kernel->post( $::botalias, 'privmsg', $chan, "$chosen has $scoretotal points, for incidents such as: $url");
  }else{
    $kernel->post( $::botalias, 'privmsg', $chan, "$chosen has no points, what a bunch of losers\n");
  }

}

1;
