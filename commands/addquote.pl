use strict;
use warnings;

push @::public_commands , 'addquote';

#  }elsif($msg =~ /^paddquote\s*(.+)$/i){ # someone is adding a quote
#    my $check = append_file($1, 'quote'); #quote will also be added to list in append_file
#    if($check){
#      my @prints = multiline_reformat("Added quote -> $1", 475, ' ');
#      $kernel->post( $::botalias, 'privmsg', $chan, "Added quote -> $1");
#    }else{
#      $kernel->post( $::botalias, 'privmsg', $chan, "Server reported: $!. Error adding quote '$1'" );
#    }



sub cmd_addquote($$$$$) {
    my ($kernel, $heap, $userinfo, $chan, $msg) = @_;

    return unless $msg;
    
    my $check = append_file($msg, 'quote');

    if($check){
	$kernel->post( $::botalias, 'privmsg', $chan, "Added quote -> $msg");
    }else{
	$kernel->post( $::botalias, 'privmsg', $chan, "Server reported: $!. Error adding quote '$msg'" );
    }  
}
