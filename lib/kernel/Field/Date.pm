package kernel::Field::Date;
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
use vars qw(@ISA);
use kernel;
use kernel::date;
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->{_permitted}->{timezone}=1;           # Zeitzone des feldes in DB
   $self->{dayonly}=0                    if (!defined($self->{dayonly}));
   $self->{timezone}="GMT"               if (!defined($self->{timezone}));
   $self->{htmlwidth}="150"              if (!defined($self->{htmlwidth}));
   $self->{htmleditwidth}="200"          if (!defined($self->{htmleditwidth}));
   $self->{xlswidth}="20"                if (!defined($self->{xlswidth}));
   $self->{WSDLfieldType}="xsd:dateTime" if (!defined($self->{WSDLfieldType}));
   return($self);
}


sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $d=$self->RawValue($current);
   my $delta;
   my $dayoffset;
   my $timeonly;

   my $usertimezone=$ENV{HTTP_FORCE_TZ};
   if (!defined($usertimezone)){
      $usertimezone=$self->getParent->UserTimezone();
   }
   if (defined($d)){
      ($d,undef,$dayoffset,$timeonly,$delta)=$self->getFrontendTimeString(
                                             $mode,$d,$usertimezone);
   }
   if (($mode eq "edit" || $mode eq "workflow")){
      my $name=$self->Name();
      my $fromquery=Query->Param("Formated_$name");
      if (defined($fromquery)){
         $d=$fromquery;
      }
      if ($self->{dayonly}){
         $d=~s/\s*\d+:\d+:\d+.*$//;
      }
      return($self->getSimpleInputField($d,$self->{readonly}));
   }
   if ($d ne ""){
      if (length($usertimezone)<=3 && $mode=~m/html/i){
         $d.="&nbsp;"; 
         $d.="$usertimezone";
         if ($mode eq "HtmlSubList"){ 
            $d=~s/ 00:00:00//;
         }
      }
      if ($mode eq "ShortMsg"){         # SMS Modus
         $d=~s/^(.*\d+:\d+):\d+\s*$/$1/;   # cut seconds
      }
      if ($mode eq "HtmlDetail" && $self->{dayonly}){
         $d=~s/\d+:\d+:\d+.*$//;
      }
      if ($mode eq "HtmlDetail" && !$self->{dayonly}){
         if (defined($delta) && $delta!=0){
            my $lang=$self->getParent->Lang();
            my $absdelta=abs($delta);
            my $baseabsdelta=abs($delta);
            my @blks=();
            if ($dayoffset==0){
               if ($lang eq "de"){
                  push(@blks,"heute um $timeonly");
               }
               else{
                 push(@blks,"today at $timeonly");
               }
            }
            elsif ($dayoffset==1){
               if ($lang eq "de"){
                  push(@blks,"gestern um $timeonly");
               }
               else{
                 push(@blks,"yesterday at $timeonly");
               }
            }
            elsif ($dayoffset==-1){
               if ($lang eq "de"){
                  push(@blks,"morgen um $timeonly");
               }
               else{
                 push(@blks,"tomorrow at $timeonly");
               }
            }
            else{
               if ($absdelta>2635200){
                  my $months=int($absdelta/2635200);
                  $absdelta=$absdelta-($months*2635200);
                  if ($lang eq "de"){
                     if ($months==1){
                        push(@blks,"einem Monat");
                     }
                     else{
                        push(@blks,"$months Monaten");
                     }
                  }
                  else{
                     if ($months==1){
                        push(@blks,"one month");
                     }
                     else{
                        push(@blks,"$months months");
                     }
                  }
               }
               if ($absdelta>86400){
                  my $days=int($absdelta/86400);
                  $absdelta=$absdelta-($days*86400);
                  if ($lang eq "de"){
                     if ($days==1){
                        push(@blks,"einem Tag");
                     }
                     else{
                        push(@blks,"$days Tagen");
                     }
                  }
                  else{
                     if ($days==1){
                        push(@blks,"one day");
                     }
                     else{
                        push(@blks,"$days days");
                     }
                  }
               }
               if ($absdelta>3600 && $baseabsdelta<2635200){
                  my $hours=int($absdelta/3600);
                  $absdelta=$absdelta-($hours*3600);
                  if ($lang eq "de"){
                     if ($hours==1){
                        push(@blks,"einer Stunde");
                     }
                     else{
                        push(@blks,"$hours Stunden");
                     }
                  }
                  else{
                     if ($hours==1){
                        push(@blks,"one hour");
                     }
                     else{
                        push(@blks,"$hours hours");
                     }
                  }
               }
               if ($absdelta>60 && $baseabsdelta<2635200){
                  my $hours=int($absdelta/60);
                  $absdelta=$absdelta-($hours*60);
                  if ($lang eq "de"){
                     if ($hours==1){
                        push(@blks,"einer Minute");
                     }
                     else{
                        push(@blks,"$hours Minuten");
                     }
                  }
                  else{
                     if ($hours==1){
                        push(@blks,"one minute");
                     }
                     else{
                        push(@blks,"$hours minutes");
                     }
                  }
               }
               if ($#blks>0){
                  push(@blks,$blks[$#blks]);
                  if ($lang eq "de"){
                     $blks[$#blks-1]="und";
                  }
                  else{
                     $blks[$#blks-1]="and";
                  }
               }
               if ($delta<0){
                  if ($lang eq "de"){
                     unshift(@blks,"vor");
                  }
                  else{
                     push(@blks,"ago");
                  }
               }
               else{
                  unshift(@blks,"in");
               }
            }
            my $deltastr=join(" ",@blks);
            $d.=" &nbsp; ( $deltastr )";
         }
      }
      if ($mode=~m/^XlsV\d+$/){
         my $usertimezone=$self->getParent->UserTimezone();
         $d=$self->getParent->ExpandTimeExpression($d,"ISO8601",
                                                      $usertimezone,
                                                      $usertimezone);
      }
      if ($mode eq "SOAP"){
         my $usertimezone=$self->getParent->UserTimezone();
         $d=$self->getParent->ExpandTimeExpression($d,"SOAP",
                                                      $usertimezone,
                                                      "GMT");
      }
      if ($mode eq "JSON"){
         my $usertimezone=$self->getParent->UserTimezone();
         $d=$self->getParent->ExpandTimeExpression($d,"ISO8601",
                                                      $usertimezone,
                                                      $usertimezone);
         if (defined($d)){
            $d="\\Date($d)\\";
         } 
      }
      return($d);
   }
   if ($d ne ""){
      return("???");
   }
   return($d);
}

sub getFrontendTimeString
{
   my $self=shift;
   my $mode=shift;
   my $d=shift;
   my $usertimezone=shift;
   my $delta;
   my $dayoffset;
   my $timeonly;

   return(undef) if (!defined($d) || $d eq "");
   if (my ($Y,$M,$D,$h,$m,$s)=$d=~
           m/^(\d+)-(\d+)-(\d+)\s+(\d+):(\d+):(\d+)(\..*){0,1}$/){
      my $tz=$self->timezone();
 
      my $time;
      eval('$time=Mktime($tz,$Y,$M,$D,$h,$m,$s);');
      if (defined($time)){
         $delta=$time-time();
      }
      if ($mode=~m/XMLV01$/ || $mode=~m/XLSV01$/){
         ($Y,$M,$D,$h,$m,$s)=Localtime("GMT",$time);
         $d=sprintf("%04d-%02d-%02d %02d:%02d:%02d",$Y,$M,$D,$h,$m,$s);
      }
      else{
         if (!defined($usertimezone)){
            my $UserCache=$self->getParent->Cache->{User}->{Cache};
            if (defined($UserCache->{$ENV{REMOTE_USER}})){
               $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
            }
            if (defined($UserCache->{tz})){
               $usertimezone=$UserCache->{tz};
            }
         }
         ($Y,$M,$D,$h,$m,$s)=Localtime($usertimezone,$time);
         {
            # calc dayoffset
            my ($Y1,$M1,$D1)=Localtime($usertimezone,$time);
            my ($Y2,$M2,$D2)=Localtime($usertimezone,time());
            my ($time1,$time2);
            eval('$time1=Mktime($usertimezone,$Y1,$M1,$D1,0,0,0);');
            eval('$time2=Mktime($usertimezone,$Y2,$M2,$D2,0,0,0);');
            $dayoffset=int(($time2-$time1)/86400);
         }
         my $lang=$self->getParent->Lang();
         $d=Date_to_String($lang,$Y,$M,$D,$h,$m,$s);
         $timeonly=sprintf("%02d:%02d",$h,$m);
      }
   }
   return($d,$usertimezone,$dayoffset,$timeonly,$delta);
}


sub getSelectField
{
   my $self=shift;
   my $mode=shift;
   my $db=shift;

   return(undef) if (!defined($self->{dataobjattr}));
   return(undef) if (ref($self->{dataobjattr}) eq "ARRAY");
   if ($mode eq "select"){
      $_=$db->DriverName();
      case: {
         /^mysql$/i and do {
            return("date_add($self->{dataobjattr},interval 0 second)");
         };
         /^oracle$/i and do {
            return("to_char($self->{dataobjattr},'YYYY-MM-DD HH24:MI:SS')");
         };
         /^odbc$/i and do {
            return("$self->{dataobjattr}");
         };
         do {
            msg(ERROR,"conversion for date on driver '$_' not defined ToDo!");
            return(undef);
         };
      }
   }
   if ($mode eq "order"){
      $_=$db->DriverName();
      case: {   # did not works on tsinet Oracle database
         /^oracle$/i and do {
            return("to_char($self->{dataobjattr},'YYYY-MM-DD HH24:MI:SS')");
         };
      }
   }
   return($self->SUPER::getSelectField($mode,$db));
}  

sub Unformat
{
   my $self=shift;
   my $formated=shift;
   my $rec=shift;
   #printf STDERR ("fifi unformat of %s = %s\n",$self->Name(),Dumper($formated));
   if (defined($formated)){
      $formated=[$formated] if (ref($formated) ne "ARRAY");
      return(undef) if (!defined($formated->[0]));
      my $usertimezone=$ENV{HTTP_FORCE_TZ};
      if (!defined($usertimezone)){
         my $UserCache=$self->getParent->Cache->{User}->{Cache};
         if (defined($UserCache->{$ENV{REMOTE_USER}})){
            $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
         }
         if (defined($UserCache->{tz})){
            $usertimezone=$UserCache->{tz};
         }
      }
      $usertimezone="GMT" if ($usertimezone eq "");
      $formated=trim($formated->[0]) if (ref($formated) eq "ARRAY");
      return({$self->Name()=>undef}) if ($formated=~m/^\s*$/);
      $formated=trim($formated);
      my %dateparam=();
      if ($self->{dayonly}){  # fix format als 12:00 GMT
         $dateparam{defhour}=12;
      }
      my $d=$self->getParent->ExpandTimeExpression($formated,"en",
                                                   undef,
                                                   $self->{timezone},
                                                   %dateparam);
      if ($formated ne "" && $d eq ""){
         return(undef);
      }
      if ($self->{dayonly}){  # fix format als 12:00 GMT
         $d=~s/\s.*$//;
         $d.=" 12:00:00";
      }
      return({$self->Name()=>$d});
   }
   return({});
}


sub getXLSformatname
{
   my $self=shift;
   my $xlscolor=$self->xlscolor;
   my $xlsbgcolor=$self->xlsbgcolor;
   my $xlsbcolor=$self->xlsbcolor;
   my $f="date.".$self->getParent->Lang();
   my $colset=0;
   if (defined($xlscolor)){
      $f.=".color=\"".$xlscolor."\"";
   }
   if (defined($xlsbgcolor)){
      $f.=".bgcolor=\"".$xlsbgcolor."\"";
      $colset++;
   }
   if ($colset || defined($xlsbcolor)){
      if (!defined($xlsbcolor)){
         $xlsbcolor="#8A8383";
      }
      $f.=".bcolor=\"".$xlsbcolor."\"";
   }


   return($f);
}



sub prepUploadRecord   # prepair one record on upload
{
   my $self=shift;
   my $newrec=shift;
   my $oldrec=shift;
   my $name=$self->Name();
   if (defined($newrec->{$name})){
      my $dn=$self->Unformat([$newrec->{$name}],$newrec);
      return(undef) if (!defined($dn));
      $newrec->{$name}=$dn->{$name};
   }
   return(1);
}


sub finishWriteRequestHash
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $parent=$self->getParent;
   if (defined($parent->{DB}) && $parent->{DB}->DriverName() eq "oracle"){
      my $name=$self->{name};
      if (exists($newrec->{$name})){
         my $d=$newrec->{$name};
         if (defined($d)){
            my $val="to_date('$d','YYYY-MM-DD HH24:MI:SS')";
            $newrec->{$name}=\$val;
         }
      }
   }
   return(undef);
}




1;
