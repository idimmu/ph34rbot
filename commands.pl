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

# PRIVMSG to a public channel received, this is where we process normal commands
sub irc_public{
  my ($kernel, $heap, $who, $chan, $msg) = @_[KERNEL, HEAP, ARG0 .. ARG2];
  (my ($nick, $user, $host) = $who =~ /^(.*)!(.*)@(.*)$/) or die "Erroneous who: $who";
  log_chan_event(@$chan[0], "<$nick> $msg");
  if(@$chan[0] eq '#badninja'){
      $kernel->post( $::botalias, 'privmsg', '#immortals', "#badninja: <$nick> $msg" );
      return;
  }
  
  my %userinfo = (
  	'full' => $who ,
	'nick' => $nick ,
	'user' => $user ,
	'host' => $host
  );
  
  my $command = $1 if $msg =~ /^p(\S+) (.+)/;
  return unless defined $command;
  my $parameter = $2;

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
  
  if($msg =~ /^pgoogle (.*?)(\s\d\d?)?$/i){ # asking for a google
    #$kernel->post( $::botnick, 'privmsg', $chan, 'pgoogle currently down due to excessive shitness' );
    #return;
    my $searchstring = $1;
    my $returncount = $2 || 1;
    if($searchstring eq '?' || $returncount < 0 || $returncount > 10){ #give help!
      $kernel->post( $::botnick, 'privmsg', $chan, 'syntax: pgoogle <search> <1-10>'); #make a var for $googlehelp
      return;
    }
    my $result = pgoogle($searchstring, $returncount);
    unless($result){
      $kernel->post( $::botalias, 'privmsg', $chan, "pgoogle: ($searchstring) no results found (blame Net::Google and/or the google api)" );
      return; # no need to go any further
    }
    my @prints = multiline_reformat($result, 450, ' . ');# in case the line is too long
    foreach (@prints){
      $kernel->post( $::botalias, 'privmsg', $chan, "pgoogle: $_" );
    }
  }elsif($msg =~ /^pquote\s*(.*)$/i){ # asking for a quote
    my ($quote, $quotenr, $quotetotal) = random_list_element($1, 'quote');#get a random line from $::lists{'quote'}
    if($quote){
      my @prints = multiline_reformat("Quote $quotenr (of $quotetotal) -> $quote", 425, ' ');
      foreach (@prints){
        $kernel->post( $::botalias, 'privmsg', $chan, $_);
      }
    }else{
      if($1){
        $kernel->post( $::botalias, 'privmsg', $chan, "No quote matching '$1' found");
      }else{
        $kernel->post( $::botalias, 'privmsg', $chan, "No quotes found");
      }
    }
  }elsif($msg =~ /^purl\s*(.*)?$/i){ # asking for a url
    my ($url, $urlnr, $urltotal) = random_list_element($1, 'url'); # get a url
    if($url){
      $kernel->post( $::botalias, 'privmsg', $chan, "url $urlnr (of $urltotal) -> $url");
    }else{
      if($1){
        $kernel->post( $::botalias, 'privmsg', $chan, "No urls matching '$1' found");
      }else{
        $kernel->post( $::botalias, 'privmsg', $chan, "No urls found");
      }
    }
  }elsif($msg =~ /^paddquote\s*(.+)$/i){ # someone is adding a quote
    my $check = append_file($1, 'quote'); #quote will also be added to list in append_file
    if($check){
      my @prints = multiline_reformat("Added quote -> $1", 475, ' ');
      $kernel->post( $::botalias, 'privmsg', $chan, "Added quote -> $1");
    }else{
      $kernel->post( $::botalias, 'privmsg', $chan, "Server reported: $!. Error adding quote '$1'" );
    }
  }elsif($msg =~ /^paddurl\s*(.+)$/i){ # someone's adding a url
    my $url = $1;

    $url =~ s/^http:\/\///;
    my @url = split('/', $url);
    foreach (@url){ s/([^\w()'*~!.-])/sprintf '%%%02x', ord $1/eg }
    $url = 'http://'.join('/', @url);
    #or just import CGI::Lite and use urlencode...

    my $check = append_file($url, 'url');
    if($check){
      $kernel->post( $::botalias, 'privmsg', $chan, "Added added url -> $url");
    }else{
      $kernel->post( $::botalias, 'privmsg', $chan, "Server reported: $!. Error adding url '$url'");
    }
  }elsif($msg =~ /^pe2\s*(.*)$/i){ #someone wants an e2 url.
    my $e2 = $1;
    $e2 =~ s/([^\w()'*~!.-])/sprintf '%%%02x', ord $1/eg;
    $kernel->post( $::botalias, 'privmsg', $chan, "pe2 -> http://everything2.com/index.pl?node=$e2");
    # urlify the query, then staple it on the end of the e2 url.
    # some day I'll make it check for actual existance of a requested node and possibly return
    # suggestions based on the search if it doesn't find a node... some day...
  }elsif($msg =~ /^ptodo\s*(.*)$/i){
    my $todo = $1;
    if(!$todo || $todo =~ /^next|=(\d+)$/){
      my $elem = $1 || 1;
      $elem--;
      $elem = @{$::lists{'todo'}} if $elem > @{$::lists{'todo'}};
      my $print = ${$::lists{'todo'}}[$elem];
      my $total = @{$::lists{'todo'}};
      $elem++;
      $kernel->post( $::botalias, 'privmsg', $chan, "todo $elem (of $total) ->  $print" );
      return;
    }elsif($todo =~ /^delnext|del=(\d+)$/){
      my $elem = $1 || 1;
      $elem--;
      if($elem > @{$::lists{'todo'}}){
        $elem--;
	$kernel->post( $::botalias, 'privmsg', $chan, "$elem is not a valid element in the todo list" );
        return;
      }
      my $print = ${$::lists{'todo'}}[$elem];
      del_list_element('todo', $elem);
      $kernel->post( $::botalias, 'privmsg', $chan, "Deleted '$print' from the todo list" );
      return;
    }
    my $check = append_file($todo, 'todo');
    if($check){
      $kernel->post( $::botalias, 'privmsg', $chan, "Added todo -> $todo");
    }else{
      $kernel->post( $::botalias, 'privmsg', $chan, "Server reported: $!. Error adding todo '$todo'");
    }

  }elsif($msg =~ /^paddcontact\s*(.*)$/i && @$chan[0] eq '#immortals'){
      my $full_match = $1;
      if($full_match =~ /^(\S+)\s+(\+?\d+)\s*(.*)/){
	  my $contact_info = join ' ',$1, $2, $3;
	  my $check = append_file($contact_info, 'contact');
	  if($check){
	      $kernel->post( $::botalias, 'privmsg', $chan, "Added Contact -> $contact_info" );
	  }else{
	      $kernel->post( $::botalias, 'privmsg', $chan, "Server reported: $!. Error adding contact '$contact_info'" );
	  }
      }else{
	  $kernel->post( $::botalias, 'privmsg', $chan, "Please use format '<nick> +<phonenumber> <other relevant info>" );
      }
  }elsif($msg =~ /^pcontact\s*(.+)$/i && @$chan[0] eq '#immortals'){
      my $search = $1;
      my $found = 0;
      foreach (@{$::lists{'contact'}}){
	  if(/$search/i){
	      $kernel->post( $::botalias, 'privmsg', $chan, "Contact info: $_" );
	      $found = 1;
	  }
      }
      $kernel->post( $::botalias, 'privmsg', $chan, "No info on $search" ) unless $found;
  }elsif($msg =~ /^pcoord\s*(.+)$/i && lc(@$chan[0]) eq '#desse'){
      my $search = $1;
      my $found = 0; 
      my @coords;
      foreach (@{$::lists{'coords'}}){
	  if(/$search/i){
	      #$kernel->post( $::botalias, 'privmsg', $chan, "-> $_" );
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
	  $kernel->post( $::botalias, 'privmsg', $chan, "No info on $search" );
      }
 }elsif($msg =~ /^paddcoord\s*(.+)$/i && lc(@$chan[0]) eq '#desse'){
      my $add = $1;
      if($add =~ /^(\d\d?\d?:\d\d?:\d\d?)\s+(\S+)\s+(P|F|N|E)$/){
	  my $input = join ' ',$1,$2,$3;
	  my $check = append_file($input, 'coords');
	  if($check){
	      $kernel->post( $::botalias, 'privmsg', $chan, "Added coords -> $input" );
	  }else{
	      $kernel->post( $::botalias, 'privmsg', $chan, "Server reported: $!. Error adding coords: '$input'" );
	  }
      }else{
	  $kernel->post( $::botalias, 'privmsg', $chan, "Use the format 'paddcoord nick xxx:xx:xx P/F/N/E' (Pr0nstar, Friend, Neutral, Enemy)" );
      }
      
  }elsif($msg =~ /^phelp\s*(.*)$/i){
    my $search = $1;
    if($search){
	my ($help, $helpnr, $helptotal) = random_list_element($search, 'help');
	if($help){
	  $kernel->post( $::botalias, 'privmsg', $chan, "Search result $helpnr (of $helptotal results) -> $help" );
        }else{
          $kernel->post( $::botalias, 'privmsg', $chan, "No help on subject: $search" );
        }
    }else{ # deliver default help statement
      my $help = "ph34rbot help: ";
      $help .= "To use phelp do 'phelp regex' where regex is your search.";
      $kernel->post( $::botalias, 'privmsg', $chan, "$help" );
      $help = "Valid commands are: pgoogle, paddurl, purl, paddquote, pquote, pe2, proll, pcur, pdict, ptodo";
      if($chan eq '#immortals'){
        $help .= ", paddcontact, pcontact";
      }
      $help .= ". These are recommended search keywords.";
      $kernel->post( $::botalias, 'privmsg', $chan, "$help" );
    }

  }elsif($msg =~ /^paddhelp\s*(.*)$/i){
    my $check = append_file( $1, 'help' );
    if($check){
      $kernel->post( $::botalias, 'privmsg', $chan, "Added help -> $1" );
    }else{
      $kernel->post( $::botalias, 'privmsg', $chan, "Server reported: $!. Error adding help '$1'" );
    }
  }elsif($msg =~ /^pcur\s*(\d+)\s*([a-zA-Z]{3})\s*([a-zA-Z]{3})\s*$/i){
      my ($amount, $fromcur, $tocur) = ($1, $2, $3);
#      my $url = "http://finance.yahoo.com/m5?a=$amount&s=$fromcur&t=$tocur&c=0";
 #my $url = "http://finance.yahoo.com/currency/convert?amt=$amount&from=$fromcur&to=$tocur&submit=Convert";

      my $url = "http://www.xe.com/ucc/convert.cgi?Amount=$amount&From=$fromcur&To=$tocur";

      my $content = get $url;
      $content =~ s/,//g;
      my ($cur) = ($content =~ /<b>(\d+\.?\d+)\s*$tocur\s*<\/b>/i);
      ($fromcur) = ($content =~ /$fromcur.*?<br>(.*?)\s*<\/font>/is);
      ($tocur) = ($content =~ /$tocur.*?<br>(.*?)\s*<\/font>/is);

#      my ($cur) = ($content =~ /<b>(\d+\.?\d+)<\/b>/);
#      ($fromcur) = ($content =~ /$fromcur>(.*?\($fromcur\))/i);
#      ($tocur) = ($content =~ /$tocur>(.*?\($tocur\))/i);
				
      my $reply;
      if(!$fromcur || !$tocur ){
	  $reply = "pcur: error processing request, one of your currencies was probably bogus";  
      }else{
	  $reply = "pcur: $amount $fromcur is $cur $tocur";
      }
      $kernel->post( $::botalias, 'privmsg', $chan, $reply );
  }elsif($msg =~ /^pdict\s*(\S+)$/i){
      
      my $search = $1;
      my $url = "http://www.dictionary.com/cgi-bin/dict.pl?term=$search";
      my $content = get $url;
      my @results;
      while( $content =~ s/<(DD|LI)[^>]*>(.*?)<\/(DD|LI)>// ){
	  push(@results,$2);
      }
      
      my @information;
      
      foreach (@results){
	  s/<[^>]+>\s*//g;
	  s/^\s+//;
	  push(@information,$_) if $_;
      }
      if(@information){
	  my $count = @information;
	  $kernel->post( $::botalias, 'privmsg', $chan, "pdict: $count results for $search" );
	  if($count == 1){
	      $kernel->post( $::botalias, 'privmsg', $chan, "$information[0]" );
	  }else{
	      $count=0;
	      foreach (@information){
		  $count++;
		  $kernel->post( $::botalias, 'privmsg', $chan, "$count. $_" );
	      }
	  }
      }else{
	  $kernel->post( $::botalias, 'privmsg', $chan, "pdict: No results found for $search." );
      }

  }elsif($msg =~ /^$/i){
      #template for next action
  }
      
  $heap->{seen_traffic} = 1;
}

1;
