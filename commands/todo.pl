use strict;
use warnings;

push @::public_commands , 'todo';

#  }elsif($msg =~ /^ptodo\s*(.*)$/i){
#    my $todo = $1;
#    if(!$todo || $todo =~ /^next|=(\d+)$/){
#      my $elem = $1 || 1;
#      $elem--;
#      $elem = @{$::lists{'todo'}} if $elem > @{$::lists{'todo'}};
#      my $print = ${$::lists{'todo'}}[$elem];
#      my $total = @{$::lists{'todo'}};
#      $elem++;
#      $kernel->post( $::botalias, 'privmsg', $chan, "todo $elem (of $total) ->  $print" );
#      return;
#    }elsif($todo =~ /^delnext|del=(\d+)$/){
#      my $elem = $1 || 1;
#      $elem--;
#      if($elem > @{$::lists{'todo'}}){
#        $elem--;
#	$kernel->post( $::botalias, 'privmsg', $chan, "$elem is not a valid element in the todo list" );
#        return;
#      }
#      my $print = ${$::lists{'todo'}}[$elem];
#      del_list_element('todo', $elem);
#      $kernel->post( $::botalias, 'privmsg', $chan, "Deleted '$print' from the todo list" );
#      return;
#    }
#    my $check = append_file($todo, 'todo');
#    if($check){
#      $kernel->post( $::botalias, 'privmsg', $chan, "Added todo -> $todo");
#    }else{
#      $kernel->post( $::botalias, 'privmsg', $chan, "Server reported: $!. Error adding todo '$todo'");
#    }


sub cmd_todo($$$$$) {
    my ($kernel, $heap, $userinfo, $chan, $msg) = @_;
	
    if(!$msg || $msg =~ /^(\d+)$/){
	my $elem = $1 || 1;
	$elem--;
	
	$elem = @{$::lists{'todo'}} if $elem > @{$::lists{'todo'}};

	my $print = ${$::lists{'todo'}}[$elem]; 
	my $total = @{$::lists{'todo'}};
	
	$elem++;
	$kernel->post( $::botalias, 'privmsg', $chan, "ptodo $elem (of $total) ->  $print" );
    }elsif($msg =~ /^delnext|del=(\d+)$/){
	my $elem = $1 || 1;
	$elem--;
	if($elem > @{$::lists{'todo'}}){
	    $elem++;
	    $kernel->post( $::botalias, 'privmsg', $chan, "$elem is not a valid element in the todo list" );
	}else{
	    my $print = ${$::lists{'todo'}}[$elem];
	    del_list_element('todo', $elem);
	    $kernel->post( $::botalias, 'privmsg', $chan, "Deleted '$print' from the todo list" );
	}
    }else{
	my $check = append_file($msg, 'todo');
	if($check){
	    $kernel->post( $::botalias, 'privmsg', $chan, "Added todo -> $msg");
	}else{
	    $kernel->post( $::botalias, 'privmsg', $chan, "Server reported: $!. Error adding todo '$msg'");
	}
    }
}
