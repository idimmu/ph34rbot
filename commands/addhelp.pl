use strict;
use warnings;

push @::public_commands , 'addhelp';

#  }elsif($msg =~ /^paddhelp\s*(.*)$/i){
#    my $check = append_file( $1, 'help' );
#    if($check){
#      $kernel->post( $::botalias, 'privmsg', $chan, "Added help -> $1" );
#    }else{
#      $kernel->post( $::botalias, 'privmsg', $chan, "Server reported: $!. Error adding help '$1'" );
#    }

sub cmd_addhelp($$$$$) {
    my ($kernel, $heap, $userinfo, $chan, $msg) = @_;
    
    return unless $msg;
    
    my $check = append_file( $msg, 'help' );
    if($check){
	$kernel->post( $::botalias, 'privmsg', $chan, "Added help -> $msg" );
    }else{
	$kernel->post( $::botalias, 'privmsg', $chan, "Server reported: $!. Error adding help '$msg'" );
    }
}
