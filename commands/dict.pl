use strict;
use warnings;

use Data::Dumper;

push @::public_commands , 'dict';

#  }elsif($msg =~ /^pdict\s*(\S+)$/i){
#      
#      my $search = $1;
#      my $url = "http://www.dictionary.com/cgi-bin/dict.pl?term=$search";
#      my $content = get $url;
#      my @results;
#      while( $content =~ s/<(DD|LI)[^>]*>(.*?)<\/(DD|LI)>// ){
#	  push(@results,$2);
#      }
#      
#      my @information;
#      
#      foreach (@results){
#	  s/<[^>]+>\s*//g;
#	  s/^\s+//;
#	  push(@information,$_) if $_;
#      }
#      if(@information){
#	  my $count = @information;
#	  $kernel->post( $::botalias, 'privmsg', $chan, "pdict: $count results for $search" );
#	  if($count == 1){
#	      $kernel->post( $::botalias, 'privmsg', $chan, "$information[0]" );
#	  }else{
#	      $count=0;
#	      foreach (@information){
#		  $count++;
#		  $kernel->post( $::botalias, 'privmsg', $chan, "$count. $_" );
#	      }
#	  }
#      }else{
#	  $kernel->post( $::botalias, 'privmsg', $chan, "pdict: No results found for $search." );
#      }



sub cmd_dict($$$$$) {
    my ($kernel, $heap, $userinfo, $chan, $msg) = @_;
    
    return unless $msg;
    
    #my $url = "http://www.dictionary.com/cgi-bin/dict.pl?term=$msg";
    my $url = "http://www.m-w.com/dictionary/$msg";
    my $content = get $url;
    my @content = split /\n/ , $content;
    my @results;
    
    #while( $content =~ s/<(DD|LI)[^>]*>(.*?)<\/(DD|LI)>// ){
	#push(@results,$2);
    #}
    
    if( $content =~ /Suggestions for/ ) {
    	# Spelling mistake
	$kernel->post( $::botalias, 'privmsg', $chan, "You can't type. Is one of these what you mean:");
	
	my $count = 0;
        foreach (@content) {
            if ( /^\<PRE\>/ ... /^\<\/PRE\>/ ) {
                if( /(\w+)<\/a>/ and $count < 5) {
                    $kernel->post( $::botalias, 'privmsg', $chan,  "  Suggestion: $1");
                    ++$count;
                }
            }
        }
    } else {
        # Presumably this is a real word

        foreach (@content) {
		my $defnline;
	        if( /^<b>:<\/b>/ ) {
			$defnline = $_;
		}
		
		if( /^<b>1( [a-z])?<\/b>/ ) {
			$defnline = $_;
		}
		
		if( defined $defnline ) {
			my @defns = split /<b>:<\/b>/ , $defnline;
			
			my $count = 1;
			foreach (@defns) {
				s/<i>//g; s/<\/i>//g;
				if( /\s*([^<]+)\s*/ and $count <= 5) {
					my $defn = $1;
					next if $defn =~ /^\s*$/;
					next if $defn =~ /^b>1/;
					
					$kernel->post( $::botalias, 'privmsg', $chan, "$count. $defn");
					++$count;
				}
			}
		}
        }
    }
    return;
    
    my @information;
    
    foreach (@results){
	s/<[^>]+>\s*//g;
	s/^\s+//;
	push(@information,$_) if $_;
    }
    
    if(@information){
	my $count = @information;
	$kernel->post( $::botalias, 'privmsg', $chan, "pdict: $count results for $msg" );
	if($count == 1){
	    $kernel->post( $::botalias, 'privmsg', $chan, "$information[0]" );
	}else{
	    my $cnt=0;
# HEY LETS PDICT SET FOR FUN (hashlinux idiotry and algorithmic shittiness in spam shocker!)

	    foreach (@information){
		$cnt++;
		$kernel->post( $::botalias, 'privmsg', $chan, "$cnt. $_" );
		last if $cnt >= 5;
	    }
    	    if($count > $cnt) {
		$kernel->post( $::botalias, 'privmsg', $chan, "Further results found at -> $url" );
	    }
	}
    }else{
	$kernel->post( $::botalias, 'privmsg', $chan, "pdict: No results found for $msg." );
    }
}

1;
