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
use XML::Parser;
use W5Kernel;
use kernel::date;
use Scalar::Util qw(weaken);
use Exporter;
#use utf8; # scheint nicht notwendig zu sein 15.08.2008 hb
use Encode;
use Unicode::String qw(utf8 latin1 utf16);
@ISA = qw(Exporter);
@EXPORT = qw(&Query &LangTable &extractLanguageBlock 
             &globalContext &NowStamp &CalcDateDuration
             &trim &rtrim &ltrim &limitlen &rmNonLatin1 &in_array
             &hash2xml &xml2hash &effVal &effChanged 
             &Debug &UTF8toLatin1 &Html2Latin1
             &Datafield2Hash &Hash2Datafield &CompressHash
             &unHtml &quoteHtml &quoteSOAP &quoteWap &quoteQueryString &XmlQuote
             &Dumper &CSV2Hash &ObjectRecordCodeResolver
             &FancyLinks &ExpandW5BaseDataLinks &mkInlineAttachment 
             &FormatJsDialCall &HashExtr
             &mkMailInlineAttachment &haveSpecialChar
             &getModuleObject &getConfigObject &generateToken
             &isDataInputFromUserFrontend &orgRoles &extractLangEntry
             &msg &sysmsg &ERROR &WARN &DEBUG &INFO &OK &utf8 &latin1 &utf16
             &utf8_to_latin1
             &Stacktrace);

sub utf8{return(&Unicode::String::utf8);}
sub utf16{return(&Unicode::String::utf16);}
sub latin1{return(&Unicode::String::latin1);}

#
# optimized utf8->latin1 converter to prevent lose of
# charachters based on map ...
# http://www.utf8-chartable.de/unicode-utf8-table.pl?start=256
#
# ISO-8859 Codings from 
# https://de.wikipedia.org/wiki/ISO_8859-15
sub utf8_to_latin1
{
   my $utf8string=shift;
   $utf8string=~s/\xC3[\xb3]/o/g;
   $utf8string=~s/\xC3[\xa0\xa1\xa2\xa3\xa5]/a/g;
   $utf8string=~s/\xC3[\x80\x81\x82\x83\x85]/A/g;
   $utf8string=~s/\xC3[\xa8\xa9\xaa\xab]/e/g;
   $utf8string=~s/\xC3[\x88\x89\x8a\x8b]/E/g;
   $utf8string=~s/\xC5\x81/L/g;
   $utf8string=~s/\xC5[\xba\xbc\xbe]/z/g;
   $utf8string=~s/\xC5[\xb9\xbb\xbd]/Z/g;
   $utf8string=~s/\xC5[\xa9\xab\xad]/u/g;
   $utf8string=~s/\xC5[\xa8\xaa\xac\xae\xb0\b2]/U/g;
   $utf8string=~s/\xC5[\x83\x85\x87\x8a]/N/g;
   $utf8string=~s/\xC5[\x84\x86\x88\x89\x8b]/n/g;
   $utf8string=~s/\xC5[\xb6\xb8]/Y/g;
   $utf8string=~s/\xC5[\x8d\x8f\x91\x93]/o/g;
   $utf8string=~s/\xC6[\xa1\xa3]/o/g;
   $utf8string=~s/\xC7[\x92]/o/g;
   $utf8string=~s/\xC5[\x8c\x8e\x90\x92]/O/g;
   # Codings from ISO_8859-15
   $utf8string=~s/[\xf3\xf4\xf5\xf6\xf0]/o/g;

   my $l=utf8($utf8string)->latin1();
   return($l);
}

sub LangTable
{
   return("en","de");
}

sub Dumper
{
   $Data::Dumper::Sortkeys = 1;
   #$Data::Dumper::Deepcopy = 1;
   
   return(Data::Dumper::Dumper(@_));
}

sub ObjectRecordCodeResolver
{
   my $back;
   if (defined($_[0])){
      my $deep=$_[1];
      $deep=+1;
      if ($deep>50){
         $back=msg(ERROR,$_[0]." deep limit reached in ".
                         "ObjectRecordCodeResolver");
      }
      elsif (ref($_[0]) eq "ARRAY"){
         $back=[];
         foreach my $rec (@{$_[0]}){
            push(@{$back},ObjectRecordCodeResolver($rec,$deep)); 
         }
      }
      elsif (ref($_[0]) eq "HASH"){
         $back={};
         foreach my $k (keys(%{$_[0]})){
            $back->{$k}=ObjectRecordCodeResolver($_[0]->{$k},$deep);
         }
      }
      elsif (ref($_[0])){
         $back=msg(ERROR,$_[0]." not resolvable in ObjectRecordCodeResolver");
      }
      else{
         $back="".$_[0];
      }
   }
   return($back);
}

sub CSV2Hash
{
   my $t=shift;
   my @orgkey=@_;

   my @t=split("\n",$t);
   my @fld=split(/;/,shift(@t));

   if ($#orgkey==-1){
      @t=map({
            my @l=split(/;/,$_);
            my %r;
            for(my $c=0;$c<=$#l;$c++){
            $r{$fld[$c]}=$l[$c];     
            }
            \%r;
            } @t);
      return(\@t);
   }
   my %t;
   while(my $l=shift(@t)){
      my @k=@orgkey;
      my @l=split(/;/,$l);
      my %r;
      for(my $c=0;$c<=$#l;$c++){
         $r{$fld[$c]}=$l[$c];     
      }
      foreach my $k (@k){
         $t{$k}->{$r{$k}}=\%r; 
      }
   }
   return(\%t);
}


sub extractLangEntry       # extracts a specific lang entry from a multiline
{                          # textarea field like :
   my $labeldata=shift;    #
      my $lang=shift;         # hello
      my $maxlen=shift;       # [de:]
      my $multiline=shift;    # Hallo

      $multiline=0 if (!defined($multiline)); # >1 means max lines 0 = join all
      $maxlen=0    if (!defined($maxlen));    # 0 means no limits

      my $curlang="";
   my %ltxt;
   foreach my $line (split('\r{0,1}\n',$labeldata)){
      if (my ($newlang)=$line=~m/^\s*\[([a-z]{1,3}):\]\s*$/){
         $curlang=$newlang;
      }
      else{
         push(@{$ltxt{$curlang}},$line);
      }
   }
   if (exists($ltxt{$lang})){
      $ltxt{""}=$ltxt{$lang};
   }
   my $d;
   if (ref($ltxt{""}) eq "ARRAY"){
      if ($multiline>0){
         $d=trim(join("\n",@{$ltxt{""}}));
      }
      else{
         $d=trim(join(" ",@{$ltxt{""}}));
      }
   }
   else{
      $d="";
   }

   return(trim($d));
}



sub haveSpecialChar
{
   my $str=shift;
   my %param=@_;

   if ($str=~m/[\~�\s,�������\\,;\*\?\r\n\t]/i){
      return(1);
   }
   return(0);
}

sub FormatJsDialCall
{
   my ($dialermode,$dialeripref,$dialerurl,$phone)=@_;
   my $qdialeripref=quotemeta($dialeripref);
   if ($dialermode=~m/Cisco/i){
      $phone=~s/[\s\/\-]//g;
      $phone=~s/$qdialeripref/0/;
      $phone=~s/[\s\/\-]//g;
      $dialerurl=~s/\%phonenumber\%/$phone/g;

      my $open="openwin('$dialerurl',".
         "'_blank',".
         "'height=360,width=580,toolbar=no,status=no,".
         "resizable=yes,scrollbars=no')";
      my $cmd="$open;";
      return($cmd);
   }
   return(undef);
}


sub unHtml
{
   my $d=shift;
   $d=~s/<br>/\n/g;

   return($d);
}

sub quoteSOAP
{
   my $d=shift;

   $d=~s/&/&amp;/g;
   $d=~s/</&lt;/g;
   $d=~s/>/&gt;/g;
   $d=~s/\\/&#92;/g;
   return($d);
}


sub Html2Latin1
{
   my $d=shift;

   $d=~s/<br>/\r\n/g;
   $d=~s/<[a-zA-Z]+[^>]*>//g;
   $d=~s/<\/[a-zA-Z]+[^>]*>//g;
   $d=~s/&amp;/&/g;
   $d=~s/&lt;/</g;
   $d=~s/&gt;/>/g;
   $d=~s/&Auml;/\xC4/g;
   $d=~s/&Ouml;/\xD6/g;
   $d=~s/&Uuml;/\xDC/g;
   $d=~s/&auml;/\xE4/g;
   $d=~s/&ouml;/\xF6/g;
   $d=~s/&uuml;/\xFC/g;
   $d=~s/&szlig;/\xDF/g;
   $d=~s/&quot;/"/g;
   $d=~s/&#x0027;/'/g;
   $d=~s/&nbsp;/ /g;

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
   $d=~s/'/&#x0027;/g;
   $d=~s/&amp;nbsp;/&nbsp;/g;

   return($d);
}

sub quoteWap
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

sub orgRoles
{
   return(qw(REmployee RApprentice RFreelancer RBoss));
}


sub XmlQuote
{
   my $org=shift;
   $org=rmNonLatin1(unHtml($org));
   $org=~s/&/&amp;/g;
   $org=~s/</&lt;/g;
   $org=~s/>/&gt;/g;
   utf8::encode($org);
   return($org);
}

sub xml2hash {
   my $d=shift;
   my $h={};

   my $p=new XML::Parser();

   my $hbuf;
   my $hbuflevel;

   my $CurrentTag;
   my $CurrentRoot;
   my $currentTarget; 
   

   $p->setHandlers(Start=>sub{
                      my ($p,$tag,%attr)=@_;
                      my @c=$p->context();
                      my $chk=$h;
                      foreach my $c (@c){
                         if (!exists($chk->{$c})){
                            $chk->{$c}={};
                         }
                         if (ref($chk) eq "HASH"){
                            $chk=$chk->{$c};
                         }
                         if (ref($chk) eq "ARRAY"){
                            $chk=$chk->[$#{$chk}];
                         }
                      }
                      if (ref($chk->{$tag}) eq "HASH"){
                         my %old=%{$chk->{$tag}};
                         my @sublist=(\%old);
                         $chk->{$tag}=\@sublist;
                         $currentTarget=\$chk->{$tag};
                      }
                      if (ref($chk->{$tag}) eq "ARRAY"){
                         my $newchk={};
                         push(@{$chk->{$tag}},$newchk);
                         $chk=$newchk;
                         $currentTarget=undef;
                      }
                      elsif (!exists($chk->{$tag})){
                         $chk->{$tag}={};
                         $currentTarget=\$chk->{$tag};
                      }
                   },
                   End=>sub{
                      my ($p,$tag,%attr)=@_;
                      my @c=$p->context();
                      $currentTarget=undef;
                    #  $buffer=undef;
                   },
                   Char=>sub {
                      my ($p,$s)=@_;
                      my @c=$p->context();
                      my $trimeds=trim($s);
                      if (defined($currentTarget) && $trimeds ne ""){
                         if (!ref($$currentTarget)){
                            $$currentTarget.=$s;
                         }
                         else{
                            $$currentTarget=$s;
                         }
                      }
                   });

   eval("\$p->parse(\$d);");
   if ($@ ne ""){
      return(undef);
   }
   return($h);
}

sub hash2xml {
  my ($request,$param,$parentKey,$depth) = @_;
  my $xml="";
  $param={} if (!defined($param) || ref($param) ne "HASH");
  $depth=0 if (!defined($depth));

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
        my $usek=$k;                         # in XML no pure numeric key are
        $usek=~s/\s/_/g;
        $usek="ID$k" if ($k=~m/^\d+$/);      # allowed! 
        if (ref($request->{$k}) eq "HASH"){
           $xml.=indent($depth).
                 "<$usek>\n".hash2xml($request->{$k},$param,$k,$depth+1).
                 indent($depth)."</$usek>\n";
        }
        elsif (ref($request->{$k}) eq "ARRAY"){
           foreach my $subrec (@{$request->{$k}}){
              if (ref($subrec)){
                 $xml.=indent($depth).
                       "<$usek>\n".hash2xml($subrec,$param,$k,$depth+1).
                       indent($depth)."</$usek>\n";
              }
              else{
                 $xml.=indent($depth)."<$usek>".XmlQuote($subrec)."</$usek>\n";
              }
           }
        }
        else{
           my $d=$request->{$k};
           if (!($d=~m#^<subrecord>#m) &&
               !($d=~m#^<xmlroot>#m)){  # prevent double quoting
              $d=XmlQuote($d);
           }
           else{
              $d="\n".join(">\n",map({indent($depth).$_} split(">\n",$d))).
                      ">\n";
           }
           $xml.=indent($depth)."<$usek>".$d."</$usek>\n";
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

sub HashExtr
{
   my $h=shift;
   my $path=shift;
   my $regexp=shift;
   my $lastarraylevel=shift;
   my @l;


   if (ref($path) ne "ARRAY"){
      $path=~s/^\/+//g;
      $path=[split(/\//,$path)];
   }
   my @lpath=(@{$path});

   if (ref($h) eq "ARRAY"){
      for(my $c=0;$c<=$#{$h};$c++){
         push(@l,HashExtr($h->[$c],\@lpath,$regexp,$h->[$c]));
      }
   }
   if (ref($h) eq "HASH"){
      if ($#lpath==0){
         if ($h->{$lpath[0]}=~m/$regexp/){
            if (ref($lastarraylevel)){
               push(@l,$lastarraylevel);
            }
            else{
               push(@l,{$lpath[0]=>$h->{$lpath[0]}});
            }
         }
      }
      else{
         my $k=shift(@lpath);
         if (exists($h->{$k})){
            push(@l,HashExtr($h->{$k},\@lpath,$regexp));
         }
      }
   }

   return(@l);
}

sub rmNonLatin1
{
   my $txt=shift;
   $txt=~s/([\x00-\x08])//g; 
   $txt=~s/([\x10])/\n/g; 
   $txt=~s/([^\x00-\xff])/sprintf('&#%d;', ord($1))/ge; 
   $txt=~s/[^\ta-z0-9,:;\!"#\\\?\+\-\/<>\._\&\[\]\(\)\n\{\}= �������\|\@\^\*'\$\�\%]//ig;
   return($txt);
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

#
# detects the effective change of a given variable
#
sub effChanged
{
   my $oldrec=shift;
   my $newrec=shift;
   my $var=shift;
   if (exists($newrec->{$var})){
      if ($newrec->{$var} ne $oldrec->{$var}){
         return(1);
      }
   }
   return(undef);
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
   if ($d1 eq "" && $d2 eq ""){
      return(undef);
   }
   if ((my ($wsY,$wsM,$wsD,$wsh,$wsm,$wss,$wsms)=$d1=~
         m/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})(\.\d{1,3}){0,1}$/) 
       &&
       (my ($weY,$weM,$weD,$weh,$wem,$wes,$wems)=$d2=~
         m/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})(\.\d{1,3}){0,1}$/)){
      # $wsms and $wems will be ignored (ms part of timestamp)
      my ($dd,$dh,$dm,$ds);
      $wsms=~s/^\.//;
      $wems=~s/^\.//;
      $wsms=undef if ($wsms eq "");
      $wems=undef if ($wems eq "");
      $wsms=999 if (defined($wsms) && $wsms>999);
      $wems=999 if (defined($wems) && $wems>999);
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
      $duration->{totaldays}=$duration->{totalminutes}/1440.0;
      if ((defined($wsms) || defined($wems))){  # not final tested ms handling
         if ($duration->{totalseconds}>0){      # (05.08.2015)
            if (defined($wsms)){
               $duration->{totalseconds}-=(1/1000)*$wsms;
            }
            if (defined($wems)){
               $duration->{totalseconds}+=(1/1000)*$wems;
            }
         }
         else{
            if (defined($wsms)){
               $duration->{totalseconds}+=(1/1000)*$wsms;
            }
            if (defined($wems)){
               $duration->{totalseconds}-=(1/1000)*$wems;
            }
         }
      }
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
   else{
      msg(WARN,"parsing error d1='$d1' d2='$d2'");
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

   $W5V2::Config={} if (!defined($W5V2::Config));
   my $configkey="$configname::$basemod";
   return($W5V2::Config->{$configkey}) if (exists($W5V2::Config->{$configkey}));
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
   $W5V2::Config->{$configkey}=$config;
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
   my $modpath=$config->Param("MODPATH");
   if ($modpath ne ""){
      foreach my $path (split(/:/,$modpath)){
         $path.="/mod";
         my $qpath=quotemeta($path);
         unshift(@INC,$path) if (!grep(/^$qpath$/,@INC));
      }
   }
   my $modconf=$config->Param("MODULE");
   if (ref($modconf) eq "HASH"){
      $modconf=$modconf->{$package};
   }
   return(undef) if (lc($modconf) eq "disabled");
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
   $package=~s/[^a-z0-9:_]//gi;
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
            print STDERR ("---\n$msg---\n");
         }
         return(undef);
      }
      else{
         msg(ERROR,"can't create object '%s'",$package); 
         return(undef);
      }
   }
   if (lc($modconf) eq "readonly"){
      no strict;
      my $f="${package}::isWriteValid";
      *$f=sub {return undef};
      my $f="${package}::isDeleteValid";
      *$f=sub {return undef};
   }

   return($o);
}

sub _isWriteValid {return undef};

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

sub _FancyMailLinks
{
   my $link=shift;
   my $prefix=shift;
   my $name=shift;
   my $res="<a href=\"$link\" target=_blank>$link</a>".$prefix;
   if ($name ne ""){
      $res="<a href=\"$link\" title=\"$link\" target=_blank>$name</a>".$prefix;
   }
   return($res);
}

sub FancyLinks
{
   my $data=shift;
   my $newline=chomp($data);
   $data=~s#(http|https|telnet|news)(://\S+?)(\?\S+){0,1}(["']{0,1}\s)#_FancyLinks("$1$2$3",$4)#ge;
   $data=~s#(http|https|telnet|news)(://\S+?)(\?\S+){0,1}$#_FancyLinks("$1$2$3",$4)#ge;
   $data.="\n" if($newline);
   $data=~s#(mailto)(:\S+?)(\@)(\S+)#_FancyMailLinks("$1$2$3$4")#ge;

   return($data);
}


sub _ExpandW5BaseDataLinks
{
   my $self=shift;
   my $formats=shift;
   my $FormatAs=shift;
   my $raw=shift;
   my $targetobj=shift;
   my $mode=shift;
   my $id=shift;
   my $view=shift;

   if (lc($mode) eq "show" && $id ne ""){
      my $obj=getModuleObject($self->Config,$targetobj);
      if (defined($obj)){
         my $idobj=$obj->IdField();
         if (defined($idobj)){
            $obj->SecureSetFilter({$idobj->Name=>\$id});
            my @view=split(/,/,$view);
            my ($trec,$msg)=$obj->getOnlyFirst(@view);
            if (defined($trec)){
               my @d;
               foreach my $k (@view){
                  push(@d,$trec->{$k}) if ($trec->{$k} ne "");
               }
               if ($#d==-1){
                  @d=("[EMPTY LINK]");
               }
               my $d=join(", ",@d);
               if (in_array($formats,$FormatAs)){
                  my $url=$targetobj;
                  $url=~s/::/\//g;
                  $url="../../$url/ById/$id";
                  $d="<a href='$url' target=_blank>".$d."</a>";
               }
               return($d);
            }
         }
      }
   }

   $raw=~s/w5base:/w5base?:/;
   return($raw);
}

sub ExpandW5BaseDataLinks
{
   my $self=shift;
   my $FormatAs=shift;
   my $data=shift;
   my @formats=qw(HtmlWfActionlog HtmlDetail);
   return($data) if (!in_array(\@formats,$FormatAs));

   $data=~s#(w5base://([^\/]+)/([^\/]+)/([^\/]+)/([,0-9,a-z,A-Z_]+))#_ExpandW5BaseDataLinks($self,\@formats,$FormatAs,$1,$2,$3,$4,$5)#ge;

   return($data);
}

sub _mkInlineAttachment
{
   my $id=shift;
   my $rootpath=shift;
   my $size;

   eval("use GD;");
   if ($@ ne ""){
      $size="height=90";
   }
   $rootpath="" if ($rootpath eq "");
   my $d="<img border=0 $size ".
         "src=\"${rootpath}../../base/filemgmt/load/thumbnail/inline/$id\">";
   $d="<a rel=\"lytebox[inline]\" href=\"${rootpath}../../base/filemgmt/load/inline/$id\" ".
      "target=_blank>$d</a>";
   return($d);
}
sub _mkMailInlineAttachment
{
   my $id=shift;
   my $baseurl=shift;
   my $size;

   eval("use GD;");
   if ($@ ne ""){
      $size="height=90";
   }
   my $d="&lt;Attachment&gt;";
   $d="<a rel=\"lytebox[inline]\" ".
      "href=\"$baseurl/public/base/filemgmt/load/inline/$id\" ".
      "target=_blank>$d</a>";
   return($d);
}
sub mkInlineAttachment
{
   my $data=shift;
   my $rootpath=shift;
   $data=~s#\[attachment\((\d+)\)\]#_mkInlineAttachment($1,$rootpath)#ge;
   return($data);
}
sub mkMailInlineAttachment
{
   my $baseurl=shift;
   my $data=shift;
   $data=~s#\[attachment\((\d+)\)\]#_mkMailInlineAttachment($1,$baseurl)#ge;
   return($data);
}

sub Stacktrace {
  my $traceonly=shift;
  my ( $path, $line, $subr );
  my $max_depth = 30;
  my $i = 1;

  print STDERR ("--- Begin stack trace ---\n");
  while ( (my @call_details = (caller($i++))) && ($i<$max_depth) ) {
    print STDERR ("$i $call_details[1]($call_details[2]) ".
                  "in $call_details[3]\n");
  }
  print STDERR ("--- End stack trace ---\n");
  die() if (!$traceonly);
}




1;
