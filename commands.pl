use strict;
use warnings;

@::public_commands = qw(
	addcamp
	addcontacts
	addcoord
	addhelp
	addquote
	addurl
	contact
	coord
	cur
	dict
	e2
	google
	help
	quote
	roll
	url
	todo
);

require "commands/roll.pl";
require "commands/test.pl";
require "commands/url.pl";
require "commands/addurl.pl";
require "commands/quote.pl";
require "commands/addquote.pl";
require "commands/e2.pl";
require "commands/todo.pl";
require "commands/help.pl";
require "commands/addhelp.pl";
require "commands/google.pl";
require "commands/dict.pl";
require "commands/cur.pl";


# PRIVMSG to a public channel received, this is where we process normal commands
sub irc_public{
  my ($kernel, $heap, $who, $chan, $msg) = @_[KERNEL, HEAP, ARG0 .. ARG2];
  (my ($nick, $user, $host) = $who =~ /^(.*)!(.*)@(.*)$/) or die "Erroneous who: $who";

  log_chan_event(@$chan[0], "<$nick> $msg"); #housekeeping
  $heap->{seen_traffic} = 1;   
 
  my %userinfo = (
  	'full' => $who ,
	'nick' => $nick ,
	'user' => $user ,
	'host' => $host
  );
  
  my $command = $1 if $msg =~ /^p(\S+)( .*)?/;
  return unless defined $command;
  my $parameter = $2;
  $parameter =~ s/^ *// if $parameter;

  # Don't allow a command of .* to pass
  return unless grep /^\Q$command\E$/ , @::public_commands;
  
  eval {
    my $funcptr;
    my $evalstr = "\$funcptr = \\\&cmd_${command};";
    eval $evalstr;
    
    &$funcptr($kernel, $heap, \%userinfo, $chan, $parameter);
  };
  
  # Did we find a dynamic command? If not, continue.
  return unless $@;
  
  # static commands go here?
}

1;
