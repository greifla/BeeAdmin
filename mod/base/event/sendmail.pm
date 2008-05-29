package base::event::sendmail;
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
use Data::Dumper;
use kernel;
use kernel::Event;
use kernel::mime;
use MIME::Base64;
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub Init
{
   my $self=shift;

   $self->RegisterEvent("sendmail","Sendmail");
  # $self->CreateIntervalEvent("MyTime",10);
   return(1);
}

sub Sendmail
{
   my $self=shift;
   my $id=shift;
   my @processed=();
   my $app=$self->getParent();
   msg(DEBUG,"start Event Sendmail");
   my @sendmailpath=qw(/usr/local/sbin/sendmail 
                       /sbin/sendmail 
                       /usr/sbin/sendmail 
                       /usr/lib/sendmail
                       /usr/lib/sbin/sendmail);
   my $sendmail=undef;
   foreach my $s (@sendmailpath){
      if (-x $s){
         $sendmail=$s;
         last;
      }
   }
   if (!defined($sendmail)){
      printf STDERR ("ERROR Handling fehlt\n");
      exit(1);
   }
   msg(DEBUG,"found sendmail at $sendmail");

   my $wf=getModuleObject($self->Config,"base::workflow");
   msg(DEBUG,"workflow DataObj loaded");
   if (defined($id)){
      msg(DEBUG,"Event($self):Sendmail wfheadid=$id");
      $wf->SetFilter({class=>'base::workflow::mailsend',state=>\'6',id=>\$id});
   }
   else{
      msg(DEBUG,"Event($self):Sendmail cleanup");
      $wf->SetFilter({class=>'base::workflow::mailsend',
                      state=>\'6',
                      mdate=>"<now-1h"});
   }
   $wf->SetCurrentView(qw(ALL));
   $wf->Limit(1);
   my ($rec,$msg)=$wf->getFirst();
   if (defined($rec)){
      msg(DEBUG,"found record");
      my $smstext;
      $wf->Store($rec,{state=>4,step=>'base::workflow::mailsend::finish'});
      msg(DEBUG,"state of record id '%s' is set to 4",$rec->{id});
      do{
         my $blkcount=-1;
         my $emailsig;
         if ($rec->{emailsignatur} ne ""){
            my $ms=getModuleObject($self->Config,"base::mailsignatur");
            $ms->SetFilter({name=>\$rec->{emailsignatur},userid=>undef});
            my $msg;
            ($emailsig,$msg)=$ms->getOnlyFirst(qw(ALL));
         }
         $ENV{LANG}=$rec->{initiallang};
         msg(DEBUG,"loading mail informations");
         foreach my $d (qw(emailtext emailtstamp emailprefix emailpostfix 
                           emailhead emailsep emailsubheader emailsubtitle)){
            if (defined($rec->{$d})){
               if (ref($rec->{$d}) ne "ARRAY"){
                  $rec->{$d}=[$rec->{$d}];
               }
               if ($#{$rec->{$d}}>$blkcount){
                  $blkcount=$#{$rec->{$d}};
               }
            }
            else{
               $rec->{$d}=[];
            }
         }
         my $mail;
         my @emaillang=split(/[,;\-.]/,$rec->{emaillang});
         my $e=$rec->{emaillang};
         @emaillang=@{$rec->{emaillang}} if (ref($rec->{emaillang}) eq "ARRAY");
         my $langcontrol;
         if ($#emaillang>0){
            foreach my $lang (@emaillang){
               $langcontrol.=" - " if ($langcontrol ne "");
               $langcontrol.="<a class=langcontrol href=\"#lang.$lang\">
                             $lang</a>";
            }
         }
         
         my $bound="d6f5".time()."af".time()."jhdfjasd";
         my $from=$rec->{emailfrom};
         if ($from eq ""){
            $from="no_reply\@".$rec->{initialsite};
         }
         my $template=$rec->{emailtemplate};
         $template="sendmail" if ($template eq "");
         my $skinbase=$rec->{skinbase};
         $skinbase="base" if ($skinbase eq "");
         if (my ($b,$t)=$template=~m/^(\S+)\/(\S+)$/){
            $skinbase=$b;
            $template=$t;
         }
         my $opmode=$self->Config->Param("W5BaseOperationMode");
         my @mailallow=split(/[,;]/,$self->Config->Param("W5BaseMailAllow"));
         msg(DEBUG,"sendmail:W5BaseOperationMode=$opmode");
         msg(DEBUG,"sendmail:W5BaseMailAllow=".join(" ",@mailallow));
         @mailallow=grep(!/^\s*$/,@mailallow);
         # TO Handling
         $rec->{emailto}=[$rec->{emailto}] if (ref($rec->{emailto}) ne "ARRAY");
         my @emailto=@{$rec->{emailto}};
         if ($#mailallow!=-1 || $opmode eq "test"){
            @emailto=map({my $m=$_;
                          my $qm=quotemeta($m);
                          if (!grep(/^$qm$/i,@mailallow)){
                             $m=~s/\@.*$/\@null.com/;
                          }
                          $m;
                         } @emailto);
         }
         my $to=join(",\n ",@emailto);
         # CC Handling
         $rec->{emailcc}=[$rec->{emailcc}] if (ref($rec->{emailcc}) ne "ARRAY");
         my @emailcc=@{$rec->{emailcc}};
         if ($#mailallow!=-1 || $opmode eq "test"){
            @emailcc=map({my $m=$_;
                          my $qm=quotemeta($m);
                          if (!grep(/^$qm$/i,@mailallow)){
                             $m=~s/\@.*$/\@null.com/;
                          }
                          $m;
                         } @emailcc);
         }
         my $cc=join(",\n ",@emailcc);
         # BCC Handling
         if (ref($rec->{emailbcc}) ne "ARRAY"){
            $rec->{emailbcc}=[$rec->{emailbcc}];
         }
         my @emailbcc=@{$rec->{emailbcc}};
         if ($#mailallow!=-1 || $opmode eq "test"){
            @emailbcc=map({my $m=$_;
                          my $qm=quotemeta($m);
                          if (!grep(/^$qm$/i,@mailallow)){
                             $m=~s/\@.*$/\@null.com/;
                          }
                          $m;
                         } @emailbcc);
         }
         my $bcc=join(",\n ",@emailbcc);
         msg(DEBUG,"building mail header\nto=%s\ncc=%s\nbcc=%s\nallowed=%s",
             Dumper(\@emailto),Dumper(\@emailcc),Dumper(\@emailbcc),
             Dumper(\@mailallow));
         if (defined($emailsig) && $emailsig->{fromaddress} ne ""){
            $mail.="From: $emailsig->{fromaddress}\n";
         }else{
            $mail.="From: $from\n";
         }
         $mail.="To: $to\n" if ($to ne "");
         if (defined($emailsig) && $emailsig->{replyto} ne ""){
            $mail.="Reply-To: $emailsig->{replyto}\n";
         }
         $mail.="Cc: $cc\n" if ($cc ne "");
         $mail.="bcc: $bcc\n" if ($bcc ne "");
         $mail.=mimeencode("Subject: ".$rec->{name})."\n";
         $mail.="Message-ID: <".$rec->{id}.'@'.$rec->{initialconfig}.'@'.
                $rec->{initialsite}.'@'."W5Base>\n";
         $mail.="Mime-Version: 1.0\n";
         $mail.="Content-Type: multipart/alternative; boundary=\"$bound\"\n";
         $mail.="--$bound";
         $mail.="\n";
         $mail.="Content-Type: text/plain; charset=\"iso-8859-1\"\n\n";
         {
            my $plaintext;
            for(my $blk=0;$blk<=$blkcount;$blk++){
               $plaintext.=$rec->{emailprefix}->[$blk];
               $plaintext.="\n"; 
               my $emailtext=$rec->{emailtext}->[$blk];
               $emailtext=~s#<[a-z/].*?>##g;
               $emailtext=~s#&nbsp;# #g;
               $emailtext=~s#^\.\s*$# .\n#mg;  # prevent . finish of mail
               $plaintext.=$emailtext;
               $plaintext.="\n-\n"; 
            }
            if ($plaintext ne ""){
               $mail.=$plaintext;
               $smstext=$plaintext;
            }
         }
         $mail.="\n--$bound";
         $mail.="\n";
         my $relbound="Rel.$bound";
         $mail.="Content-Type: multipart/related; boundary=\"$relbound\"\n\n";
         $mail.="--$relbound";
         $mail.="\n";
         $mail.="Content-Type: text/html; charset=\"iso-8859-1\"\n\n";
         my $additional=$rec->{additional};
         my %additional=();
         foreach my $k (keys(%$additional)){
            if (ref($additional->{$k}) eq "ARRAY"){
               $additional{$k}=join(", ",@{$additional->{$k}});
            }
            else{
               $additional{$k}=$additional->{$k};
            }
         }
         msg(DEBUG,"add=%s",Dumper(\%additional));
         my $currentlang=shift(@emaillang);
         my $formname="tmpl/$template.form.head";
         my $maildata="ERROR: critical application problem - ".
                      "mail template not found";
         msg(DEBUG,"loading and parsing mail template");
         $app->setSkinBase($skinbase);
         if ($app->getSkinFile($app->SkinBase()."/".$formname)){
            $maildata=$app->getParsedTemplate($formname,
                                     {static=>{
                                        %additional,
                                        currentlang =>$currentlang,
                                        langcontrol =>$langcontrol,
                                      }
                                     });
         }
         $mail.=$maildata;
         msg(DEBUG,"adding $blkcount datablocks to mail body");
         my $sep=0;
         $mail.="<a name=\"separation.$sep\"></a>";
         $mail.="<div class=separation id=\"separation.$sep\">";
         $mail.="<div class=separationbackground\">";
         for(my $blk=0;$blk<=$blkcount;$blk++){
            my $formname="tmpl/$template.form.line";
            my $maildata="ERROR: Mail template not found";
            if ($app->getSkinFile($app->SkinBase()."/".$formname)){
               my $emailtext=$rec->{emailtext}->[$blk];
               if (!(($emailtext=~m/<a/) ||
                     ($emailtext=~m/<b>/) ||
                     ($emailtext=~m/<\/b>/) ||
                     ($emailtext=~m/<\/ul>/) ||
                     ($emailtext=~m/<i>/) ||
                     ($emailtext=~m/<div/))){
                  $emailtext=~s/</&lt;/g;
                  $emailtext=~s/>/&gt;/g;
               }
               $emailtext=FancyLinks($emailtext);
               my $emailbottom=$rec->{emailbottom};
               if (ref($rec->{emailbottom}) eq "ARRAY"){
                  $emailbottom=$rec->{emailbottom}->[$blk];
               }
               if ($emailbottom eq ""){
                  $emailbottom="<td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td>";
               }
               msg(DEBUG,"try add blk $blk");
               if ($rec->{emailsubheader}->[$blk] ne "" &&
                   $rec->{emailsubheader}->[$blk] ne "0"){
                  my $sh=$rec->{emailsubheader}->[$blk];
                  if ($sh eq "1"){
                     $sh="";
                  }
                  if ($sh eq " "){
                     $sh="&nbsp;";
                  }
                  $sh=~s/\n/<br>\n/g;
                  $mail.="<div class=subheader>".$sh."</div>";
               }
               my $prepemailpostfix=$rec->{emailpostfix}->[$blk];
               if ($prepemailpostfix=~m/^\s*$/){
                  $prepemailpostfix="<font size=1>&nbsp;</font>";
               }
               $maildata=$app->getParsedTemplate($formname,{
                                  static=>{
                                     %additional,
                                     emailtext   =>$emailtext,
                                     emailhead   =>$rec->{emailhead}->[$blk],
                                     emailbottom =>$emailbottom,
                                     emailtstamp =>$rec->{emailtstamp}->[$blk],
                                     emailprefix =>$rec->{emailprefix}->[$blk],
                                     emailsubtitle =>$rec->{emailsubtitle}->[$blk],
                                     emailpostfix=>$prepemailpostfix,
                                     currentlang =>$currentlang,
                                     langcontrol =>$langcontrol,
                                                          }
                                   });
               $maildata=~s#^\.\s*$# .\n#mg;  # prevent . finish of mail
               if ($rec->{emailsep}->[$blk] ne "" &&
                   $rec->{emailsep}->[$blk] ne "0"){
                  $currentlang=shift(@emaillang);
                  my $septext=$rec->{emailsep}->[$blk];
                  if ($septext eq "1"){
                     $septext="";
                  }
                  $mail.="</div>";
                  $mail.="</div>";
                  $sep++;
                  my $formname="tmpl/$template.form.sep";
                  my $maildata="ERROR: Mail template not found";
                  if ($app->getSkinFile($app->SkinBase()."/".$formname)){
                     my $sep=$app->getParsedTemplate($formname,{
                                        static=>{
                                           %additional,
                                           currentlang=>$currentlang,
                                           separation=>$sep,
                                           septext=>$septext,
                                           langcontrol =>$langcontrol,
                                         }});
                     $mail.=$sep;
                
                  }
                  $mail.="<a name=\"separation.$sep\"></a>";
                  $mail.="<div class=separation id=\"separation.$sep\">";
                  $mail.="<div class=separationbackground\">";
               }
               msg(DEBUG,"add blk $blk ok");
            }
            $mail.=$maildata;
         }
         $mail.="</div>";
         $mail.="</div>";
         msg(DEBUG,"adding mail bottom");
         my $formname="tmpl/$template.form.bottom";
         my $maildata="ERROR: Mail template not found";
         if ($app->getSkinFile($app->SkinBase()."/".$formname)){
            my $emailbottom=$rec->{emailbottom};
            if (ref($emailbottom) eq "ARRAY"){
               $emailbottom=join("",@{$emailbottom});
            }
            $maildata=$app->getParsedTemplate($formname,{
                                           static=>{
                                              %additional,
                                              langcontrol =>$langcontrol,
                                              emailbottom =>$emailbottom
                                           }});
         }
         if (defined($emailsig) && $emailsig->{htmlsig} ne ""){
            $maildata.=$emailsig->{htmlsig};
         }
         $mail.=$maildata;

         $mail.="\n--$relbound";
         #printf STDERR ("%s\n",$mail);       
         msg(DEBUG,"adding pictures to mail body as multiplart content");
         for(my $c=1;$c<=9;$c++){
            my $imgname="$template.bild$c.jpg";
            if (my $pic=$app->getSkinFile($app->SkinBase()."/img/".$imgname)){
               if (open(IMG,"<$pic")){
                  my $imgbin=join("",<IMG>);
                  close(IMG);
                  $mail.="\nContent-ID: <$imgname>\n";
                  $mail.="Content-Type: image/jpg\n";
                  $mail.="Content-Name: $imgname\n";
                  $mail.="Content-Transfer-Encoding: base64\n\n";
                  $mail.=encode_base64($imgbin);
                  $mail.="\n--$relbound";
               }
            }
         }
         $mail.="--\n";
         $mail.="\n--$bound--\n";
         ####################################################################
         # SMS Handling
         if ($rec->{allowsms}==1 &&
             $self->Config->Param("SMSInterfaceScript") ne ""){
            my $smsscript=$self->Config->Param("SMSInterfaceScript");
            msg(DEBUG,"prepare to call $smsscript");
            my $user=getModuleObject($self->Config,"base::user");
            $user->SetFilter({email=>\@emailto});
            my @smsrec=$user->getHashList(qw(fullname sms 
                                             office_mobile home_mobile));
            $smstext=$rec->{smstext} if ($rec->{smstext} ne "");
            foreach my $smsrec (@smsrec){
               my $number;
               if ($smsrec->{sms} eq "officealways"){
                  $number=$smsrec->{office_mobile};
               }
               if ($smsrec->{sms} eq "homealways"){
                  $number=$smsrec->{home_mobile};
               }
               if (defined($number)){
                  $number=~s/\s//g;
                  msg(DEBUG,"sending sms to $smsrec->{fullname}");
                  if (open(F,"|".$smsscript." \"$number\"")){
                     print F $smstext;
                     close(F);
                  }
               }
            }
         }
         ####################################################################
         msg(DEBUG,"deliver maildata to $sendmail");
         if (open(F,"|".$sendmail." -t")){
            print F $mail;
            close(F);
            push(@processed,$rec->{id});
            if (open(D,">/tmp/mail.".$rec->{id}.".dump.tmp")){
               print D $mail;
               $wf->Store($rec,{state=>21,
                                eventend=>NowStamp("en"),
                                closedate=>NowStamp("en"),
                                step=>'base::workflow::mailsend::finish'});
               close(D);
            }
         }
         msg(DEBUG,"try to load next record");
         ($rec,$msg)=$wf->getNext();
      }until(!defined($rec));
   }

   
   return({exitcode=>0,processed=>\@processed});
}





1;
