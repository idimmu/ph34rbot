use strict;
use warnings;

push @::public_commands , 'help';

#  }elsif($msg =~ /^phelp\s*(.*)$/i){
#    my $search = $1;
#    if($search){
#	my ($help, $helpnr, $helptotal) = random_list_element($search, 'help');
#	if($help){
#	  $kernel->post( $::botalias, 'privmsg', $chan, "Search result $helpnr (of $helptotal results) -> $help" );
#        }else{
#          $kernel->post( $::botalias, 'privmsg', $chan, "No help on subject: $search" );
#        }
#    }else{ # deliver default help statement
#      my $help = "ph34rbot help: ";
#      $help .= "To use phelp do 'phelp regex' where regex is your search.";
#      $kernel->post( $::botalias, 'privmsg', $chan, "$help" );
#      $help = "Valid commands are: pgoogle, paddurl, purl, paddquote, pquote, pe2, proll, pcur, pdict, ptodo";
#      $help .= ". These are recommended search keywords.";
#      $kernel->post( $::botalias, 'privmsg', $chan, "$help" );
#    }


sub cmd_help($$$$$) {
    my ($kernel, $heap, $userinfo, $chan, $msg) = @_;
    
    if($msg){
	my ($help, $helpnr, $helptotal) = random_list_element($msg, 'help');
	if($help){
	  $kernel->post( $::botalias, 'privmsg', $chan, "Search result $helpnr (of $helptotal results) -> $help" );
        }else{
          $kernel->post( $::botalias, 'privmsg', $chan, "No help on subject: $msg" );
        }
    }else{
      my $help = "ph34rbot help: ";
      $help .= "To use phelp do 'phelp regex' where regex is your search.";
      $kernel->post( $::botalias, 'privmsg', $chan, "$help" );
      $help = "Valid commands are: pgoogle, paddurl, purl, paddquote, pquote, pe2, proll, pcur, pdict, ptodo";
      $help .= ". These are recommended search keywords.";
      $kernel->post( $::botalias, 'privmsg', $chan, "$help" );
    }
}

