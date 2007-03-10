use strict;
use warnings;

push @::public_commands , 'cur';

#  }elsif($msg =~ /^pcur\s*(\d+)\s*([a-zA-Z]{3})\s*([a-zA-Z]{3})\s*$/i){
#      my ($amount, $fromcur, $tocur) = ($1, $2, $3);
##      my $url = "http://finance.yahoo.com/m5?a=$amount&s=$fromcur&t=$tocur&c=0";
# #my $url = "http://finance.yahoo.com/currency/convert?amt=$amount&from=$fromcur&to=$tocur&submit=Convert";
#      my $url = "http://www.xe.com/ucc/convert.cgi?Amount=$amount&From=$fromcur&To=$tocur";
#      my $content = get $url;
#      $content =~ s/,//g;
#      my ($cur) = ($content =~ /<b>(\d+\.?\d+)\s*$tocur\s*<\/b>/i);
#      ($fromcur) = ($content =~ /$fromcur.*?<br>(.*?)\s*<\/font>/is);
#      ($tocur) = ($content =~ /$tocur.*?<br>(.*?)\s*<\/font>/is);
##      my ($cur) = ($content =~ /<b>(\d+\.?\d+)<\/b>/);
##      ($fromcur) = ($content =~ /$fromcur>(.*?\($fromcur\))/i);
##      ($tocur) = ($content =~ /$tocur>(.*?\($tocur\))/i);
#      my $reply;
#      if(!$fromcur || !$tocur ){
#	  $reply = "pcur: error processing request, one of your currencies was probably bogus";  
#      }else{
#	  $reply = "pcur: $amount $fromcur is $cur $tocur";
#      }
#      $kernel->post( $::botalias, 'privmsg', $chan, $reply );


sub cmd_cur($$$$$) {
    my ($kernel, $heap, $userinfo, $chan, $msg) = @_;
    
    return unless $msg =~ /^(\d+)\s*([a-zA-Z]{3})\s*([a-zA-Z]{3})\s*$/;
    
    my ($amount, $fromcur, $tocur) = ($1, $2, $3);
    
    my $url = "http://www.xe.com/ucc/convert.cgi?Amount=$amount&From=$fromcur&To=$tocur";
    
    my $content = get $url;
    $content =~ s/,//g;

    my $cur;
    ($cur) = ($content =~ />(\d+\.?\d+)\s*$tocur\s*</ig);
#    ($fromcur) = ($content =~ /($fromcur).*?<\/h2>/ig);
#    ($tocur) = ($content =~ /$tocur.*?<\/h2>(.*?)\n/ig);
    ($fromcur) = ($content =~ /<td align="right" id="XEenlarge">(.*)\n/);
    ($tocur) = ($content =~ /<td align="left" id="XEenlarge">(.*)\n/);

#    ($fromcur) = ($content =~ /$fromcur.*?<br>(.*?)\s*<\/font>/is);
#    ($tocur) = ($content =~ /$tocur.*?<br>(.*?)\s*<\/font>/is);
    
    my $reply;
    if(!$fromcur || !$tocur ){
	$reply = "pcur: error processing request, one of your currencies was probably bogus";  
    }else{
	$reply = "pcur: $amount $fromcur is $cur $tocur";
    }
    $kernel->post( $::botalias, 'privmsg', $chan, $reply );
}
