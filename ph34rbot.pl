#!/usr/bin/perl

use warnings;
use strict;

#use Net::Google;
use POE;
use POE::Component::IRC;
use LWP::Simple qw(get $ua);

use Fcntl ':flock';

###############################################################################
# My variables

my $pipedir  = '/home/jester/html/poe-named-pipe';
my $logdir   = '/home/jester/wd/logs';

#my $pipedir  = 'poe-named-pipe';
#my $logdir   = 'logs';

$::botalias = 'ph34rbot'; # www.megatokyo.com
$::botnick  = $::botalias; # current nickname the bot has registered with the server
my %cservice = ( # This'll be useful later
  'nick' => 'P@cservice.netgamers.org',
  'who'  => 'P!cservice@netgamers.org',
);

my %files = (
  'quote' => "$0.quote",
  'url'  => "$0.urldb",
  'todo' => "$0.todo",
  'help' => "$0.help",
  'ban' => "$0.ban",
  'coord' => "$0.coord",
);


#%::lists; # corresponding names to those in %files

my %channels; # add channels here on join, elements are currently not used, but later additions may change this
#$::target; #pcamp target
#$::targchan;

my $server   = shift       || 'london.uk.eu.netgamers.org';
my $port     = shift       || '6667';
my $username = shift       || 'camper';
my $ircname  = @ARGV ? join (' ', @ARGV)  : 'evil l33t';


###############################################################################
# Executing code begins here

# make a file called ph34rbot.pl.pid that only has this program's pid.
# used by the restarting script
open(PIDFILE, ">$0.pid" );
print PIDFILE "$$";
close(PIDFILE);

# make sure the logging dirs are in order
unless(-d $logdir){
  mkdir $logdir, 0700;
}
unless(-d "$logdir/$server"){
  mkdir "$logdir/$server", 0700;
}

# read quotes, urls and any other files into %::lists
foreach (keys %files){
  read_file($_);
}

Server::spawn($pipedir); # spawn a new named pipe server

chmod 0760, $pipedir; # make sure the pipe has the right chmod

POE::Component::IRC->new( 'ph34rbot' ) or
  die "Can't instantiate new IRC component!\n";
  # new IRC server with alias ph34rbot or die trying

$ua->agent("Lynx/2.8.5rel.1 libwww-FM/2.14 SSL-MM/1.4.1 GNUTLS/0.8.12");
#we lie and say we're lynx

require "commands.pl";

#and hook these subroutines
POE::Session->new( 'main' => [qw( _start _stop irc_001 irc_disconnected
                                 irc_socketerr irc_public irc_join
                                 irc_invite irc_part irc_disconnected
                                 irc_quit irc_kick irc_mode irc_352
                                 irc_nick irc_433 irc_ctcp_action irc_topic
				 autoping)] );


$poe_kernel->run();  ### Nothing below here will execute
exit 0;

###############################################################################
#########################       subroutines          ##########################

###############################################################################
# The hooks for POE::Component::IRC
# These are the hooked soubroutines for the IRC bot
# For full documentation see the POE::Component::IRC pod

# do this when we start the kernel
sub _start{
  my ( $kernel ) = $_[ KERNEL ];

  $kernel->alias_set( $::botalias );
  $kernel->post( $::botalias, 'register', 'all');
  # we're interested in hearing about all events
  # Keep-alive timer.
  #$kernel->delay( autoping => 300 );
  spawn_connection($kernel);
}

# do this when the kernel stops
sub _stop{
  my ($kernel) = $_[KERNEL];
  print STDERR "Control session stopped.\n";
  unlink $pipedir;
  exit 0;
}

sub _default {
  my ($state, $event, $args, $heap) = @_[STATE, ARG0, ARG1, HEAP];
  $args ||= [ ];
  print STDERR  "default $state = $event (@$args)\n";
  $heap->{seen_traffic} = 1;
  return 0;
}

# this is the first message an IRC server sends when a client has connected
sub irc_001{
  my ($kernel) = $_[KERNEL];

  $kernel->post( $::botalias, 'mode', $::botnick, '+ix');
  $kernel->post( $::botalias, 'privmsg', $cservice{'nick'}, 'auth ph34rbot armageddon');
  $kernel->post( $::botalias, 'join', '#tset');
}

# WHO query reply, used to compile IAL, and
sub irc_352{
  my ( $kernel, $servname, $msg ) = @_[ KERNEL, ARG0..ARG1 ];
  (my ($chan, $user, $host, undef, $nick, $userstat, undef, $realname) = $msg =~ /^(\#\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+([H|G]\*?[@|+|%]?\w*)\s+:(\d+)\s+(.*)$/g) or die "I HATE WHO! : $msg";
  my ($away, $chanstatus, $modes) = $userstat =~ /^([H|G])\*?([@|+|%]?)(\w*)$/;
  $channels{$chan}{$nick} = [($nick, $user, $host, $realname, $chanstatus)]; #unpretty, but better than what I had in Java
}

#test method to see that the who list was compiled correctly
#sub irc_315{
#  my ( $kernel, $servname, $msg ) = @_[ KERNEL, ARG0..ARG1 ];
#  #print STDERR "FOO! - ".$channels{'#Sqrl-Fu'}{'Jester'}[0] . " - FOO!";
#  foreach (keys %channels){
#    print "$_" . join(' ', @{$channels{$_}{'Jester'}}) . "\n";
#    my $chan = $_;
#    foreach (keys %{$channels{$chan}}){
#      print join(' ', @{$channels{$chan}{$_}}) . "\n";
#    }
#  }
#}

# connection lost, reconnect?
sub irc_disconnected{ #did I just disconnect?
  my ($kernel) = $_[KERNEL];
  #sleep(2); #don't spam the server
  #spawn_connection($kernel);
  exit 0;
}
sub irc_socketerr{
  my ($kernel) = $_[KERNEL];
  #sleep(2);# spam is bad, mmmkay?
  #spawn_connection($kernel);
  exit 0;
}

#sub irc_error{
#  my $err = $_[ARG0];
#  print STDERR "Server error occurred! $err\n";
#}

# someone has joined a channel
sub irc_join{
  my ( $kernel, $who, $chan ) = @_[ KERNEL, ARG0..ARG1 ];
  (my ($nick, $user, $host) = $who =~ /^(.*)!(.*)@(.*)$/) or die "Erroneous who: $who";
  if($nick eq $::botnick){ #the bot joined a channel, add it to the hash
    $channels{$chan}{$::botnick} = [( $::botnick, $user, $host, $ircname, undef )];
    $kernel->post( $::botalias, 'who', $chan ); # going to need a list of users to build the IAL
  }else{
    $channels{$chan}{$nick} = [($nick, $user, $host, undef, undef)]; # keep the IAL up-to-date
    #log_chan_event( $chan, "* Joins: $nick ($user\@$host)" );
    log_chan_event( $chan, "$nick ($user\@$host) joined $chan");
  }

}

#someone has parted a channel
sub irc_part{
  my ($kernel, $who, $chan) = @_[KERNEL, ARG0 .. ARG1];
  (my ($nick, $user, $host) = $who =~ /^(.*)!(.*)@(.*)$/) or die "Erroneous who: $who";
  $chan =~ s/^(\#\S+)\s+.*/$1/g;
  if($nick eq $::botnick){
    delete $channels{$chan}; # the bot parted a channel, delete it from the hash
  }else{
    delete $channels{$chan}{$nick}; # don't need that anymore
  }
  #log_chan_event( $chan, "* Parts: $nick ($user\@$host)" );
  log_chan_event( $chan, "$nick ($user\@$host) left $chan");
}

# Someone has been kicked from a channel, currently for logging purposes only
# there's a bug in here somewhere, cba to sort it
sub irc_kick{
  my ($kernel, $who, $chan, $kicked, $reason) = @_[KERNEL, ARG0 .. ARG3];
  my ($kicker, $user, $host);
  ($kicker, $user, $host) = ($who =~ /^(.*)!(.*)@(.*)$/) or ($kicker = $who);
  delete $channels{$chan}{$kicked};
  #log_chan_event( $chan, "* $kicked was kicked by $who ($reason)");
  log_chan_event( $chan, "$kicked kicked from $chan by $kicker: $reason");
}

# IRC Quit
sub irc_quit{
  #this method has intentionally been left blank
  my ($kernel, $who, $reason) = @_[KERNEL, ARG0 .. ARG1];
  (my ($nick, $user, $host) = $who =~ /^(.*)!(.*)@(.*)$/) or die "Erroneous who: $who";
  foreach (keys %channels){
    if($channels{$_}{$nick}){
      delete $channels{$_}{$nick};
      log_chan_event( $_, "$nick ($user\@$host) left irc: $reason");
    }
  }
}

#someone has invited the bot to a channel
sub irc_invite{
  my ($kernel, $who, $chan) = @_[KERNEL, ARG0..ARG1];
  if($who eq $cservice{'who'}){#always follow an invite given by a chanservice
    $kernel->post( $::botalias, 'join', $chan);
  }
  #$who =~ s/^(.*)!.*$/$1/ or die "Erroneous who: $who";
  # uncomment the above line if more action is to be taken on invites by non services
}

# channel mode change, not implemented in the IAL yet, but no code checks usermode yet, so it's gotten low priority
sub irc_mode{
  my ( $kernel, $who, $chan, $mode, @targets ) = @_[ KERNEL, ARG0..$#_];
  my ($nick, $user, $host);
  (($nick, $user, $host) = $who =~ /^(.*)!(.*)@(.*)$/) or ($nick = $who);
  if($chan =~ /^\#/){
    log_chan_event( $chan, "$chan: mode change '$mode ".join(' ', @targets)."' by $who");
  }else{
    # $chan is not a channel, self mode set. Currently ignore.
  }
}

# someone's nick was changed, better keep the IAL uptodate
sub irc_nick{
  my ( $kernel, $who, $newnick ) = @_[ KERNEL, ARG0..ARG1 ];
  (my ($nick, $user, $host) = $who =~ /^(.*)!(.*)@(.*)$/) or die "Erroneous who: $who";
  if($nick eq $::botnick){# my nick was changed
    foreach (keys %channels){
      $channels{$_}{$newnick}=[$channels{$_}{$::botnick}];
      delete $channels{$_}{$::botnick};
      @{$channels{$_}{$newnick}}[0]=$newnick;
    }
    $::botnick = $newnick;
  }else{
    # Keep the IAL in order!
    foreach (keys %channels){
      if($channels{$_}{$nick}){
        $channels{$_}{$newnick}=[$channels{$_}{$nick}];
        delete $channels{$_}{$nick};
        @{$channels{$_}{$newnick}}[0]=$newnick;
        #log_chan_event($_, "* $nick now known as $newnick");
        log_chan_event( $_, "Nick change: $nick -> $newnick");
      }
    }
    if($::target && $::target eq $nick){
      $::target = $newnick;
    }
  }
}

# nick already in use error, get a random nick and try it
sub irc_433{
  my $kernel = $_[ KERNEL ];

  #my $nick = gen_random_nick();
  my $nick = $::botalias."-".int(rand(1000));
  $kernel->post( $::botalias, 'nick', $nick );
}

# the most common ctcp event, usually the /me command on a client, used for logging
sub irc_ctcp_action{
  my ($kernel, $who, $text);
  ($kernel, $who, $::target, $text) = @_[ KERNEL, ARG0..ARG2 ];
  (my ($nick, $user, $host) = $who =~ /^(.*)!(.*)@(.*)$/) or die "Erroneous who: $who";
  log_chan_event( @$::target[0], "Action: $nick $text");
}

# new topic set, better log that
sub irc_topic{
  my ($kernel, $who, $chan, $text) = @_[ KERNEL, ARG0..ARG2 ];
  log_chan_event( $chan, "Topic changed on $chan by $who: $text");
}


###############################################################################
# Helper methods for the IRC bot

# a general connection sub
sub spawn_connection{
  my $kernel=shift;
  $kernel->post( $::botalias, 'connect', {  Debug     => 0,
                                          Nick      => $::botalias,
                                          Server    => $server,
                                          Port      => $port,
                                          Username  => $username,
                                          Ircname   => $ircname,
                                        }
  );
  $kernel->delay( autoping => 300 );
}

sub autoping {
  my ($kernel, $heap) = @_[KERNEL, HEAP];
  $kernel->post( $::botalias, 'userhost', $::botnick ) unless $heap->{seen_traffic};
  $heap->{seen_traffic} = 0;
  $kernel->delay( autoping => 300 );
}

#log an event that was sent from a channel
sub log_chan_event {
  my ( $chan, $text ) = @_;
  $chan = lc($chan); # might as well make sure glitches don't make it log to other files
  my ($minute, $hour, $day, $month, $year)=(localtime)[1..5];
  $year+=1900; # readable year
  $month++;
  #my $file = join('', $chan, $year, ($month+1), $day);
  my $file = sprintf("%s%d%02d%02d", $chan, $year, $month, $day);

  open(CHANLOG, ">>$logdir/$server/$file.log") or warn "$0: Can't open file $file.log: $!";
  printf CHANLOG "[%02d:%02d] %s\n", $hour, $minute, $text;
  close(CHANLOG);
}

#read file takes one argument, a string that matches a key in %files. Info goes into an array in %::lists with corresponding key
# returns undef on failure
sub read_file{
  my $key = shift || return;
  my $filename = $files{$key} || return;
  delete $::lists{$key}; #if(@{$::lists{key}}); #empty the list if it has elements
  open(INFILE, "<$filename") or return;
  while(<INFILE>){
    chomp($_);
    push(@{$::lists{$key}}, $_);
  }
  close(INFILE);
  return 1;
}

#Appends a text to a file and its corresponding list
sub append_file{
  my $text = shift || return;
  my $key  = shift || return;
  my $filename = $files{$key} || return;
  open(APPFILE, ">>$filename") or return;
  print APPFILE "$text\n";
  close(APPFILE);
  push(@{$::lists{$key}}, $text);
  return 1;
}

# googler
sub pgoogle{
  my $searchstring = shift || return;
  my $resultcount  = shift || return;

  #see the Net::Google documentation for more on this
  my $google = Net::Google->new(key=>"9i+1UftQFHI1vMKrdKNU243OLYAGHhrQ");
  my $session = $google->search();
  $session->safe("");

  $searchstring =~ s/\s*$//;
  $searchstring =~ s/\s+/\+/g;

  $session->query($searchstring);
  my $results = $session->results();
  my $hits="";
  my $count=0;
  foreach my $result (@$results){
    last unless ($count < $resultcount);
    $hits.=($result->URL().' ');
    $count++;
  }
  return $hits; #return a whitespace seperated string of results
}

# shorten a string over a set length
# this is because an ircd will ignore every line sent that is over 512 chars long
# and will shorten any line that becomes over 512 chars long when nick!user@host
# is prepended
sub multiline_reformat{
  my $string  = shift || return undef;
  my $len     = shift || return undef;
  my $delim   = shift || return undef;
  my @strings = split(/ /, $string); #split on spaces
  my @result;
  my $count=0;
  foreach (@strings){
    if(( length($result[$count]) + length($_) ) >$len){
      $result[$count] =~ s/$delim$//;
      $result[++$count] .= "$_$delim";
    }else{
      $result[$count] .= "$_$delim";
    }
  }
  $result[$count] =~ s/$delim$//;#cut off trailing delims
  return @result;
}

#get a random list element (for pquote/purl etc)
sub random_list_element{
  my $search   =  shift;
  my $listname =  shift;
  return unless $::lists{$listname};
  my $desindex;
  my $randnr;
  if($search && $search =~ s/^=(\d+)\s*//){
    $desindex = $1;
  }
  if($search){
    #build a list of matching quotes, get a random quote from them
    my @tmp;

    foreach (@{$::lists{$listname}}){
      push(@tmp,$_) if eval {/$search/i} || index($_, $search) > -1;
    }
    return unless @tmp;
    $randnr = $desindex || int(rand(@tmp));
    $randnr-- if $desindex;
    #$randnr = $randnr > $#tmp ? $#tmp : $randnr;
    return $tmp[$randnr], $randnr+1, scalar(@tmp);
  }else{
    $randnr = $desindex || int(rand(scalar(@{$::lists{$listname}})));
    $randnr-- if $desindex;
    #$randnr = $randnr > scalar(@{$::lists{$listname}}) ? scalar(@{$::lists{$listname}}) : $randnr;
    return ${$::lists{$listname}}[$randnr], $randnr+1, scalar(@{$::lists{$listname}});
    #say that three time fast
  }
  # should never make it here
}

sub roll_dice{
  my ( $numbdice, $numbsides, $modifier ) = @_;
  my $result;
  return if $numbdice > 100;
  for(my $i = 0; $i < $numbdice; $i++){
    $result += ((int(rand($numbsides))) + 1);
  }

  return $result + $modifier || 0;
}

# delete a set of list elements, then redump the list to file
sub del_list_element{
  my $listhandle = shift;
  my @numbs      = @_;
  @numbs = reverse sort { $a <=> $b } @numbs;
  # sort the numbers from biggest to smallest, so that a deletion doesn't effect
  # a later splice statement

  open(FILE, ">$files{$listhandle}") or return;
  flock(FILE, LOCK_EX) or return; #lock the file while we're deleting
  seek(FILE, 0, 2);# and, in case someone appended while we were waiting...

  foreach (@numbs){
    splice(@{$::lists{$listhandle}}, $_, 1);
  }
  foreach (@{$::lists{$listhandle}}){
    print FILE "$_\n";
  }
  flock(FILE, LOCK_UN);
  close(FILE);
  return 1;
}



###############################################################################
# The UNIX socket server.
# This and the server session code are almost completely taken from the POE cookbook
# No point reinventing the wheel

package Server;
use POE::Session;    # For KERNEL, HEAP, etc.
use Socket;          # For PF_UNIX.
# Spawn a UNIX socket server at a particular rendezvous.  jinzougen
# says "rendezvous" is a UNIX socket term for the inode where clients
# and servers get together.  Note that this is NOT A POE EVENT
# HANDLER.  Rather it is a plain function.
sub spawn {
    my $rendezvous = shift;
    POE::Session->create
      ( inline_states =>
          { _start => \&server_started,
            got_client => \&server_accepted,
            got_error  => \&server_error,
          },
        heap => { rendezvous => $rendezvous, },
      );
}

# The server session has started.  Create a socket factory that
# listens for UNIX socket connections and returns connected sockets.
# This unlinks the rendezvous socket
sub server_started {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    unlink $heap->{rendezvous} if -e $heap->{rendezvous};
    $heap->{server} = POE::Wheel::SocketFactory->new
      ( SocketDomain => PF_UNIX,
        BindAddress  => $heap->{rendezvous},
        SuccessEvent => 'got_client',
        FailureEvent => 'got_error',
      );
}

# The server encountered an error while setting up or perhaps while
# accepting a connection.  Register the error and shut down the server
# socket.  This will not end the program until all clients have
# disconnected, but it will prevent the server from receiving new
# connections.
sub server_error {
    my ( $heap, $syscall, $errno, $error ) = @_[ HEAP, ARG0 .. ARG2 ];
    print STDERR $heap->{rendezvous}."\n";
    $error = "Normal disconnection." unless $errno;
    warn "Server socket encountered $syscall error $errno: $error\n";
    delete $heap->{server};
}

# The server accepted a connection.  Start another session to process
# data on it.
sub server_accepted {
    my $client_socket = $_[ARG0];
    ServerSession::spawn($client_socket);
}

###############################################################################
# The UNIX socket server session.  This is a server-side session to
# handle client connections.
package ServerSession;
use POE::Session;    # For KERNEL, HEAP, etc.
# Spawn a server session for a particular socket.  Note that this is
# NOT A POE EVENT HANDLER.  Rather it is a plain function.
sub spawn {
    my $socket = shift;
    POE::Session->create
      ( inline_states =>
          { _start => \&server_session_start,
            got_client_input => \&server_session_input,
            got_client_error => \&server_session_error,
          },
        args => [$socket],
      );
}

# The server session has started.  Wrap the socket it's been given in
# a ReadWrite wheel.  ReadWrite handles the tedious task of performing
# buffered reading and writing on an unbuffered socket.
sub server_session_start {
    my ( $heap, $socket ) = @_[ HEAP, ARG0 ];
    $heap->{client} = POE::Wheel::ReadWrite->new
      ( Handle => $socket,
        InputEvent => 'got_client_input',
        ErrorEvent => 'got_client_error',
      );
    $heap->{client}->put( "CONNECTED $::botalias" );
}

# The server session received some input from its attached client.
# Process it and send a result
sub server_session_input {
    my ( $kernel, $heap, $input ) = @_[ KERNEL, HEAP, ARG0 ];
    my $output;

    # see the protocol documentation for what each command is supposed to do
    # processes $input and sets a result in $output, which is sent back to the
    # client
    if($input =~ /^UPDATE (.*)/){
      if($files{$1}){
        read_file($1);
        $output = "SUCCESS UPDATE $1";
      }else{
        $output = "FAILURE UPDATE $1: Not a valid file key";
      }
    }elsif($input =~ /^IRCPRIVMSG (\S+) (.*)/){
      $kernel->post($::botalias, 'privmsg', $1, $2);
      $output = "SUCCESS PRIVMSG $1 $2";
    }elsif($input =~ /^IRCACTION (\S+) (.*)/){
      $kernel->post( $::botalias, lc($1), $2);
      $output = "SUCCESS $1 $2";
    }elsif($input =~ /^CHANLIST$/){
      $output = "SUCCESS CHANLIST " . join(' ', sort(keys(%channels)));
    }elsif($input =~ /^FILELIST$/){
      $output = "SUCCESS FILELIST " . join(' ', sort(keys(%files)));
    }elsif($input =~ /^LISTCONTENTS (\S+)$/){
      if($::lists{$1}){
        my $counter = 0;
        my $listlength = $#{$::lists{$1}};
        foreach (@{$::lists{$1}}){
          $heap->{client}->put("SUCCESS LISTCONTENTS $counter $listlength $_");
          $counter++;
        }
        $output = "SUCCESS LISTCONTENTS";
      }else{
        $output = "FAILURE LISTCONTENTS $1: List empty or not found";
      }
    }elsif($input =~ /^DELETE (\S+) ((\d+\s*)*)/){
      my $listhandle = $1;
      my @dels = split / +/, $2;
      my $result = main::del_list_element($listhandle, @dels);
      if($result){
        $output = "SUCCESS DELETE $listhandle".join ' ', @dels;
      }else{#error!
        $output = "FAILURE DELETE $listhandle ". join ' ', @dels . " $result";
      }
    }else{
      $heap->{client}->put("FAILURE unknown command");
      return;
    }

    $heap->{client}->put($output);
}

# The server session received an error from the client socket.  Log
# the error and shut down this session.  The main server remains
# untouched by this.
sub server_session_error {
    my ( $heap, $syscall, $errno, $error ) = @_[ HEAP, ARG0 .. ARG2 ];
    $error = "Normal disconnection." unless $errno;
    warn "Server session encountered $syscall error $errno: $error\n";
    delete $heap->{client};
}
