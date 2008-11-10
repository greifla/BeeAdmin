package cache;

use strict;
use Data::Dumper;


sub new
{
   my $type=shift;
   my $configname=shift;
   my $self={@_};
   $self=bless($self,$type);
   return($self);
}
if (!defined($W5V2::Cache)){
   $W5V2::Cache=new cache();
}

sub AddHandler
{
   my ($self,$name,%p)=@_;

   if (exists($self->{'C'}->{$name})){
      printf STDERR ("WARN:  redifining existing cache handler '%s'\n",$name);
   }
   $self->{'C'}->{$name}={CacheFailCode=>$p{CacheFailCode},
                          Database=>$p{Database}};
}

sub Value($$)
{
   my ($self,$name,$key)=@_;

   printf STDERR ("read cache value $name -> {$key}\n");
}

sub Validate
{
   my ($self,@names)=@_;


}

sub Invalidate
{
   my ($self,@names)=@_;


}

package kernel;
#  W5Base Framework
#  Copyright (C) 2006  Hartmut Vogler (it@guru.de)
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
use strict;
use vars qw(@EXPORT @ISA);
use Data::Dumper;
use kernel::date;
use Scalar::Util qw(weaken);
use Exporter;
#use utf8; # scheint nicht notwendig zu sein 15.08.2008 hb
use Encode;
use Unicode::String qw(utf8 latin1 utf16);
@ISA = qw(Exporter);
@EXPORT = qw(&Query &LangTable &globalContext &NowStamp &CalcDateDuration
             &trim &rtrim &ltrim &hash2xml &effVal &Debug &UTF8toLatin1
             &Datafield2Hash &Hash2Datafield &CompressHash
             &unHtml &quoteHtml &quoteQueryString &Dumper 
             &FancyLinks &mkInlineAttachment &haveSpecialChar
             &getModuleObject &getConfigObject &generateToken
             &isDataInputFromUserFrontend
             &msg &ERROR &WARN &DEBUG &INFO &OK &utf8 &latin1 &utf16);

sub utf8{return(&Unicode::String::utf8);}
sub utf16{return(&Unicode::String::utf16);}
sub latin1{return(&Unicode::String::latin1);}
sub LangTable
{
  return("en","de");
}

sub Dumper
{
   return(Data::Dumper::Dumper(@_));
}



sub ERROR() {return("ERROR")}
sub OK()    {return("OK")}
sub WARN()  {return("WARN")}
sub DEBUG() {return("DEBUG")}
sub INFO()  {return("INFO")}

sub haveSpecialChar
{
   my $str=shift;
   my %param=@_;

   if ($str=~m/[\~�\s,����\\,;\*\?\r\n\t]/i){
      return(1);
   }
   return(0);
}


sub ltrim
{
  return(undef) if (!defined($_[0]));
  if (ref($_[0]) eq "SCALAR"){
     return(undef) if (!defined(${$_[0]}));
     ${$_[0]}=~s/\s*$//;
     return(${$_[0]});
  }
  $_[0]=~s/^\s*//;
  return($_[0]);
}

sub rtrim
{
  return(undef) if (!defined($_[0]));
  if (ref($_[0]) eq "SCALAR"){
     return(undef) if (!defined(${$_[0]}));
     ${$_[0]}=~s/\s*$//;
     return(${$_[0]});
  }
  $_[0]=~s/\s*$//;
  return($_[0]);
}

sub trim
{
  return(undef) if (!defined($_[0]));
  ltrim($_[0]);
  rtrim($_[0]);
  if (ref($_[0])){
     return(${$_[0]});
  }
  return($_[0]);
}

sub unHtml
{
   my $d=shift;
   $d=~s/<br>/\n/g;

   return($d);
}

sub quoteHtml
{
   my $d=shift;

   $d=~s/&/&amp;/g;
   $d=~s/</&lt;/g;
   $d=~s/>/&gt;/g;
   $d=~s/\xC4/&Auml;/g;
   $d=~s/\xD6/&Ouml;/g;
   $d=~s/\xDC/&Uuml;/g;
   $d=~s/\xE4/&auml;/g;
   $d=~s/\xF6/&ouml;/g;
   $d=~s/\xFC/&uuml;/g;
   $d=~s/\xDF/&szlig;/g;
   $d=~s/"/&quot;/g;
   $d=~s/'/&prime;/g;
   $d=~s/&amp;nbsp;/&nbsp;/g;

   return($d);
}

sub quoteQueryString {
  my $toencode = shift;
  return undef unless defined($toencode);
  # force bytes while preserving backward compatibility -- dankogai
  $toencode = pack("C*", unpack("C*", $toencode));
  $toencode=~s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg;
  return $toencode;
}


sub hash2xml {
  my ($request,$param,$parentKey,$depth) = @_;
  my $xml="";
  $param={} if (!defined($param) || ref($param) ne "HASH");
  $depth=0 if (!defined($depth));

  sub XmlQuote
  {
     my $org=shift;
     $org=unHtml($org);
     $org=~s/&/&amp;/g;
     $org=~s/</&lt;/g;
     $org=~s/>/&gt;/g;
     utf8::encode($org);
     return($org);
  }
  sub indent
  {
     my $n=shift;
     my $i="";
     for(my $c=0;$c<$n;$c++){
        $i.=" ";
     }
     return($i);
  }
  return($xml) if (!ref($request));
  if (ref($request) eq "HASH"){
     foreach my $k (keys(%{$request})){
        if (ref($request->{$k}) eq "HASH"){
           $xml.=indent($depth).
                 "<$k>\n".hash2xml($request->{$k},$param,$k,$depth+1).
                 indent($depth)."</$k>\n";
        }
        elsif (ref($request->{$k}) eq "ARRAY"){
           foreach my $subrec (@{$request->{$k}}){
              $xml.=indent($depth).
                    "<$k>\n".hash2xml($subrec,$param,$k,$depth+1).
                    indent($depth)."</$k>\n";
           }
        }
        else{
           my $d=$request->{$k};
           if (!($d=~m#^<subrecord>#m)){  # prevent double quoting
              $d=XmlQuote($d);
           }
           else{
              $d="\n".join(">\n",map({indent($depth).$_} split(">\n",$d))).
                      ">\n";
           }
           $xml.=indent($depth)."<$k>".$d."</$k>\n";
        }
     }
  }
  if (ref($request) eq "ARRAY"){
     foreach my $d (@{$request}){
        if (ref($d)){
           $xml.=hash2xml($d,$param,$parentKey,$depth+1);;
        }
        else{
           if (!($d=~m#^<subrecord>#m)){  # prevent double quoting
              $d=XmlQuote($d);
           }
           else{
              $d="\n".join(">\n",map({indent($depth).$_} split(">\n",$d))).
                      ">\n";
           }
           $xml.=indent($depth)."<$parentKey>".$d."</$parentKey>\n";
        }
     }
  }
  if ($depth==0 && $param->{header}==1){
     my $encoding="UTF-8";
     $xml="<?xml version=\"1.0\" encoding=\"$encoding\" ?>\n\n".$xml;
  }
  return $xml;
}

sub UTF8toLatin1
{
   my $dd=shift;
   if ($dd=~m/\xC3/){
      utf8::decode($dd);
   }
   if (utf8::is_utf8($dd)){
      utf8::downgrade($dd,1);
      $dd=~s/\x{201e}/"/g;
      decode_utf8($dd,0);
      $dd=encode("iso-8859-1", $dd);
   }
   return($dd);
}


sub Datafield2Hash
{
   my $data=shift;
   my %hash;
   my @lines=split(/\n/,$data);

   foreach my $l (@lines){
      if ($l=~/^\s*(.*)\s*=\s*'(.*)'.*$/){
         my $key=$1;
         my $val=$2;
         $val=~s/<br>/\n/g;
         $val=~s/\\&lt;br&gt;/<br>/g;
         if (defined($hash{$key})){
            push(@{$hash{$key}},$val);
         }
         else{
            $hash{$key}=[$val];
         }
      }
   }
   return(%hash);
}

sub Hash2Datafield
{
   my %hash=@_;
   my $data="\n\n";
   foreach my $k (sort(keys(%hash))){
      my $d=$hash{$k};
      my @dlist=($d);
      if (ref($d) eq "ARRAY"){
         @dlist=@{$d};
      }
      foreach my $d (@dlist){
         $d=~s/\'/"/g;
         $d=~s/<br>/\\&lt;br&gt;/g;
         $d=~s/\n/<br>/g;
         utf8::decode($d);
         $data="$data$k='".$d."'=$k\r\n";
      }
   }
   $data.="\n";
   return($data);
}

sub CompressHash
{
   my $h;
   if (ref($_[0]) eq "HASH"){
      $h=shift;
   }
   else{
      $h={@_};
   }
   foreach my $k (keys(%$h)){
      if (ref($h->{$k}) eq "ARRAY" &&
          $#{$h->{$k}}<=0){
         $h->{$k}=$h->{$k}->[0];
      }
   }
   return($h);
}

#
# detects the effective value in a validate operation
#
sub effVal
{
   my $oldrec=shift;
   my $newrec=shift;
   my $var=shift;
   if (exists($newrec->{$var})){
      return($newrec->{$var});
   }
   if (defined($oldrec) && exists($oldrec->{$var}) && 
       !(exists($newrec->{$var}))){
      return($oldrec->{$var});
   }
   return(undef);
}




sub msg
{
   my $type=shift;
   my $msg=shift;
   $msg=~s/%/%%/g if ($#_==-1);
   $msg=sprintf($msg,@_);
   return("") if ($type eq "DEBUG" && $W5V2::Debug==0);
   my $d;
   foreach my $linemsg (split(/\n/,$msg)){
      $d.=sprintf("%-6s %s\n",$type.":",$linemsg);
   }
   print STDERR $d;
   return($d);
}

sub Debug
{
   return($W5V2::Debug);
}

sub isDataInputFromUserFrontend
{
   if (($ENV{SCRIPT_URI} ne "" || $ENV{REMOTE_ADDR} ne "" ) &&
       $W5V2::OperationContext ne "QualityCheck"){
      return(1);
   }
   return(0);
}



sub globalContext
{
   $W5V2::Context->{GLOBAL}={} if (!exists($W5V2::Context->{GLOBAL}));
   return($W5V2::Context->{GLOBAL});
}

sub Query
{
   return($W5V2::Query);
}


sub CalcDateDuration
{
   my $d1=shift;
   my $d2=shift;
   my $tz=shift;
   $tz="GMT" if (!defined($tz));

   if (ref($d1)){
      $d1=$d1->ymd." ".$d1->hms;
   }
   if (ref($d2)){
      $d2=$d2->ymd." ".$d2->hms;
   }
   if ((my ($wsY,$wsM,$wsD,$wsh,$wsm,$wss)=$d1=~
          m/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/) &&
       (my ($weY,$weM,$weD,$weh,$wem,$wes)=$d2=~
          m/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/)){
      my ($dd,$dh,$dm,$ds);
      eval('($dd,$dh,$dm,$ds)=Delta_DHMS($tz,
                                         $wsY,$wsM,$wsD,$wsh,$wsm,$wss,
                                         $weY,$weM,$weD,$weh,$wem,$wes);');
      if ($@ ne ""){
         return(undef);
      }
      $dd=0 if (!defined($dd)); 
      $dh=0 if (!defined($dh)); 
      $dm=0 if (!defined($dm)); 
      $ds=0 if (!defined($ds)); 
      my $duration={days=>$dd,hours=>$dh,minutes=>$dm, seconds=>$ds};
      $duration->{totalminutes}=($dd*24*60)+($dh*60)+$dm+(1/60*$ds);
      $duration->{totalseconds}=($dd*24*60*60)+($dh*60*60)+($dm*60)+$ds;
      my $d="";
      $d.="${dd}d" if ($dd!=0);
      $d.=" "      if ($dh!=0 && $d ne "");
      $d.="${dh}h" if ($dh!=0);
      $d.=" "      if ($dm!=0 && $d ne "");
      $d.="${dm}m" if ($dm!=0);
      $d.=" "      if ($ds!=0 && $d ne "");
      $d.="${ds}s" if ($ds!=0);
      $duration->{string}=$d;
      return($duration);
   }
   return(undef);
}

sub NowStamp
{
   if ($_[0] eq "en"){
      return(sprintf("%04d-%02d-%02d %02d:%02d:%02d",Today_and_Now("GMT")));
   }
   return(sprintf("%04d%02d%02d%02d%02d%02d",Today_and_Now("GMT")));
}

sub getConfigObject($$$)
{
   my $instdir=shift;
   my $configname=shift;
   my $package=shift;

   my ($basemod,$app)=$package=~m/^(\S+)::(.*)$/;
   my $config=new kernel::config();
   if (!$config->readconfig($instdir,$configname,$basemod)){
      if ($ENV{SERVER_SOFTWARE} ne ""){
         print("Content-type:text/plain\n\n");
         print msg(ERROR,"can't read configfile '%s'",$configname); 
         exit(1);
      }
      else{
         msg(ERROR,"can't read configfile '%s'",$configname); 
         exit(1);
      }
   }
   return($config);
}

sub generateToken
{
   my $len=shift;
   my $token="";

   my @set=('a'..'z','A'..'Z','0'..'9');
   for(my $c=0;$c<$len;$c++){
      if ($c==3){
         $token.=time();
      }
      $token.=$set[rand($#set)];
   }
   return(substr($token,0,$len));
}


sub getModuleObject
{
   my $config;
   my $package;
   my $param;
   if (ref($_[0])){
      $config=shift;
      $package=shift;
      $param=shift;
   }
   else{
      my $instdir=shift;
      my $configname=shift;
      $package=shift;
      $param=shift;
      $config=getConfigObject($instdir,$configname,$package);
   }
   my ($basemod,$app)=$package=~m/^(\S+)::(.*)$/;
   return(undef) if (!defined($config));
   #printf STDERR ("dump%s\n",Dumper($config));
   my %modparam=();
   $modparam{Config}=$config;
   $modparam{param}=$param if (defined($param));;
   my $virtualtab=$config->Param("VIRTUALMODULE");
   if (ref($virtualtab) eq "HASH"){
      if (defined($virtualtab->{$app})){
         $modparam{OrigModule}=$basemod;  
         ($basemod,$app)=$virtualtab->{$app}=~m/^(\S+)::(.*)$/;
      }
      if (defined($virtualtab->{$package})){
         $modparam{OrigModule}=$basemod;  
         ($basemod,$app)=$virtualtab->{$package}=~m/^(\S+)::(.*)$/;
      }
   }
   my ($o,$msg);
   $package="${basemod}::${app}"; # MOD neuaufbau - basemod vieleicht ver�ndert
   #msg(INFO,"kernel::webapp::RunWebApp create of $package");
   if ($config->Param("SAFE") eq "1"){
      my $compartment=new Safe();
      #
      # Das ist mit Sicherheit noch nicht fertig !!!
      #
      $compartment->reval("use $package;\$o=new $package(\%modparam);");
   }
   else{
      eval("use $package;(\$o,\$msg)=new $package(\%modparam);");
   }
   if ($@ ne "" || !defined($o) || $o eq "InitERROR"){
      $msg=$@;
      if ($ENV{SERVER_SOFTWARE} ne ""){
         #print("Content-type:text/plain\n\n");
         msg(ERROR,"can't create object '%s'",$package); 
         if ($msg ne ""){ 
            print STDERR ("--\n$msg");
         }
         return(undef);
      }
      else{
         msg(ERROR,"can't create object '%s'",$package); 
         return(undef);
      }
   }
   return($o);
}

sub _FancyLinks
{
   my $link=shift;
   my $prefix=shift;
   my $name=shift;
   my $res="<a href=\"$link\" target=_blank>$link</a>".$prefix;
   if ($name ne ""){
      $res="<a href=\"$link\" title=\"$link\" target=_blank>$name</a>".$prefix;
   }
   else{
      if (length($link)>55){
         my $start;
         my $ll=index($link,"//");
         $ll=index($link,"/",$ll+2);
         $start=$ll+15;
         $start=55 if ($start<10 || $start>55);
         my $slink=substr($link,0,$start)."...".
                   substr($link,length($link)-16,16);
         my $title=$link;
         $title=~s/^.*?://g;
         $res="<a href=\"$link\" target=_blank title=\"$title\">".
              "$slink</a>".$prefix;
      }
   }
   return($res);
}

sub FancyLinks
{
   my $data=shift;
   $data=~s#(http|https|telnet|news)(://\S+?)(\?\S+){0,1}(["']{0,1}\s)#_FancyLinks("$1$2$3",$4)#ge;
   $data=~s#(http|https|telnet|news)(://\S+?)(\?\S+){0,1}$#_FancyLinks("$1$2$3",$4)#ge;

#   foreach my $color (qw(RED GREEN BLUE)){
#      $data=~s/&lt;w5${color}&gt;/<font color=$color>/ig;
#      $data=~s/&lt;\/w5${color}&gt;/<\/font>/ig;
#   }
#   $data=~s/&lt;w5BOLD&gt;/<b>/ig;
#   $data=~s/&lt;\/w5BOLD&gt;/<\/b>/ig;
#   $data=~s/&lt;w5ITALIC&gt;/<i>/ig;
#   $data=~s/&lt;\/w5ITALIC&gt;/<\/i>/ig;

   return($data);
}

sub _mkInlineAttachment
{
   my $id=shift;
   my $size;

   eval("use GD;");
   if ($@ ne ""){
      $size="height=90";
   }
   my $d="<img border=0 $size ".
         "src=\"../../base/filemgmt/load/thumbnail/inline/$id\">";
   $d="<a rel=\"lytebox[inline]\" href=\"../../base/filemgmt/load/inline/$id\" ".
      "target=_blank>$d</a>";
   return($d);
}
sub mkInlineAttachment
{
   my $data=shift;
   $data=~s#\[attachment\((\d+)\)\]#_mkInlineAttachment($1)#ge;
   return($data);
}



1;
