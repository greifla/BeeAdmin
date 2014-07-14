package itil::qrule::HardwareRefresh;
#######################################################################
=pod

=head3 PURPOSE

Checking the age of hardware/asset items. This quality rules controles
the refresh of hardware items. The handling is aligned to a maximum
age of 60 months.

=head3 IMPORTS

NONE

=head3 HINTS

no english hints avalilable

[de:]

Die Refresh QualityRule ist darauf ausgerichtet, dass ein 
Hardware-Asset max. 60 Monate im Einsatz sein darf. Die Berechnung
erfolgt auf Basis des Abschreibungsbeginns.
Somit gilt:

 DeadLine = Abschreibungsbeginn + 60 Monate

 RefreshData = DeadLine oder denyupdvalidto falls denyupdvalidto g�ltig ist.

Ein DataIssue wird erzeugt, wenn RefreshData �berschritten wird.



=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2015  Hartmut Vogler (it@guru.de)
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
use kernel::QRule;
@ISA=qw(kernel::QRule);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub getPosibleTargets
{
   return(["itil::asset"]);
}

sub isHardwareRefreshCheckNeeded
{
   my $self=shift;
   my $rec=shift;

   return(0) if ($rec->{cistatusid}<=2 || $rec->{cistatusid}>=5);
   return(1);
}


sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $checksession=shift;
   my $autocorrect=$checksession->{autocorrect};

   my $wfrequest={};
   my $forcedupd={};
   my @qmsg;
   my @dataissue;
   my $errorlevel=0;

   if (!$self->isHardwareRefreshCheckNeeded($rec)){
      return(0,undef);
   }

   my $deprstart=$rec->{deprstart}; 
   my $denyupd=$rec->{denyupd}; 
   my $denyupdvalidto=$rec->{denyupdvalidto}; 
   my $now=NowStamp("en");
   if ($deprstart ne ""){  # nur wenn Abschreibungsbeginn eingetragen!
      my $deadline=$self->getParent->ExpandTimeExpression($deprstart."+60M");
      my $refreshdate=$deadline;
      my $to_deadline=CalcDateDuration($now,$deadline,"GMT");
      if ($denyupd){ # falls Refreshes nicht gewollt/zul�ssig
         if ($denyupdvalidto ne ""){
            my $d=CalcDateDuration($now,$denyupdvalidto,"GMT");
            if (defined($d) && $d->{days}<1080){ # ausschluss max 36 Monate
               my $d=CalcDateDuration($deadline,$denyupdvalidto,"GMT");
               if (defined($d) && $d->{days}>0){  # nur wenn der Ausschluss
                  $refreshdate=$denyupdvalidto;   # Zeitpunkt weiter in der
               }                                  # Zukunft liegt als default
            }
         }
      }
      my %notifyparam=(emailfrom=>"\"Hardware Refresh Notification\" <>");
      my $tmpl=$self->Self;
      $tmpl=~s/::/./g;
      my $skinbase=$self->Self;
      $skinbase=~s/::.*//g;
      my $notifycontrol={useTemplate=>"tmpl/$tmpl",
                         useSkinBase=>$skinbase};

      my $to_refresh=CalcDateDuration($now,$refreshdate,"GMT");

      if ($rec->{refreshinfo3} eq ""  &&      # info 3 level Ende-10 Monate
          defined($to_refresh) && $to_refresh->{days}<300){
         my $late="" if ($to_deadline->{days}<300-30);
         $late="less then" if ($to_deadline->{days}<300-30);
         my $newrec={refreshinfo3=>NowStamp("en")};
         $newrec->{refreshinfo1}=NowStamp("en") if ($rec->{refreshinfo1} eq "");
         $newrec->{refreshinfo2}=NowStamp("en") if ($rec->{refreshinfo2} eq "");
         $self->finalizeNotifyParam($rec,\%notifyparam,"refreshinfo3");
         if ($dataobj->ValidatedUpdateRecord($rec,$newrec,{id=>\$rec->{id}})){
            $dataobj->NotifyWriteAuthorizedContacts($rec,$newrec,
               \%notifyparam, $notifycontrol,
               sub{
                  my $self=shift;
                  my $notifyparam=shift;
                  my $notifycontrol=shift;

                  my $lang=$dataobj->Lang();
                  my $refreshstr=$dataobj->ExpandTimeExpression($refreshdate,
                                                                $lang."day");
                  my $m="24";
                  if ($late ne ""){
                     $m=$self->T($late)." ".$m;
                  }
                  my $subject=sprintf($self->T(
                              "Hardware %s needs to be refreshed in %s months"),
                              $rec->{name},$m);
                  my $applications=$rec->{applicationnames};
                  if (ref($applications) eq "ARRAY"){
                     $applications=join(", ", @{$applications});
                  }
                  my $text=$dataobj->getParsedTemplate(
                               $notifycontrol->{useTemplate},
                               {
                                  skinbase=>$notifycontrol->{useSkinBase},
                                  static=>{
                                     NAME=>$rec->{name},
                                     REFRESH=>$refreshstr,
                                     SYSTEMS=>join(", ",
                                       map({$_->{name}} @{$rec->{systems}})),
                                     APPLICATIONS=>$applications
                                  }
                               });
                  return($subject,$text);
               });
          }
      }
      elsif ($rec->{refreshinfo2} eq "" &&    # info 2 level Ende-18 Monate
          defined($to_refresh) && $to_refresh->{days}<540){
         my $late="" if ($to_deadline->{days}<540-30);
         $late="less then" if ($to_deadline->{days}<540-30);
         my $newrec={refreshinfo2=>NowStamp("en")};
         $newrec->{refreshinfo1}=NowStamp("en") if ($rec->{refreshinfo1} eq "");
         $self->finalizeNotifyParam($rec,\%notifyparam,"refreshinfo2");
         if ($dataobj->ValidatedUpdateRecord($rec,$newrec,{id=>\$rec->{id}})){
            $dataobj->NotifyWriteAuthorizedContacts($rec,$newrec,
               \%notifyparam,
               $notifycontrol,
               sub{
                  my $self=shift;
                  my $notifyparam=shift;
                  my $notifycontrol=shift;

                  my $lang=$dataobj->Lang();
                  my $refreshstr=$dataobj->ExpandTimeExpression($refreshdate,
                                                                $lang."day");
                  my $m="18";
                  if ($late ne ""){
                     $m=$self->T($late)." ".$m;
                  }
                  my $subject=sprintf($self->T(
                              "Hardware %s needs to be refreshed in %s months"),
                              $rec->{name},$m);
                  my $applications=$rec->{applicationnames};
                  if (ref($applications) eq "ARRAY"){
                     $applications=join(", ", @{$applications});
                  }
                  my $text=$dataobj->getParsedTemplate(
                               $notifycontrol->{useTemplate},
                               {
                                  skinbase=>$notifycontrol->{useSkinBase},
                                  static=>{
                                     NAME=>$rec->{name},
                                     REFRESH=>$refreshstr,
                                     SYSTEMS=>join(", ",
                                       map({$_->{name}} @{$rec->{systems}})),
                                     APPLICATIONS=>$applications
                                  }
                               });
                  return($subject,$text);
               });
         }

      }
      elsif ($rec->{refreshinfo1} eq "" &&    # info 1 level Ende-24 Monate
          defined($to_deadline) && $to_deadline->{days}<730){
         my $late="" if ($to_deadline->{days}<730-30);
         $late="less then" if ($to_deadline->{days}<730-30);
         my $newrec={refreshinfo1=>NowStamp("en")};
         $self->finalizeNotifyParam($rec,\%notifyparam,"refreshinfo1");
         if ($dataobj->ValidatedUpdateRecord($rec,$newrec,{id=>\$rec->{id}})){
            $dataobj->NotifyWriteAuthorizedContacts($rec,$newrec,
               \%notifyparam,
               $notifycontrol,
               sub{
                  my $self=shift;
                  my $notifyparam=shift;
                  my $notifycontrol=shift;

                  my $lang=$dataobj->Lang();
                  my $refreshstr=$dataobj->ExpandTimeExpression($refreshdate,
                                                                $lang."day");
                  my $m="24";
                  if ($late ne ""){
                     $m=$self->T($late)." ".$m;
                  }
                  my $subject=sprintf($self->T(
                              "Hardware %s needs to be refreshed in %s months"),
                              $rec->{name},$m);
                  my $applications=$rec->{applicationnames};
                  if (ref($applications) eq "ARRAY"){
                     $applications=join(", ", @{$applications});
                  }
                  my $text=$dataobj->getParsedTemplate(
                               $notifycontrol->{useTemplate},
                               {
                                  skinbase=>$notifycontrol->{useSkinBase},
                                  static=>{
                                     NAME=>$rec->{name},
                                     REFRESH=>$refreshstr,
                                     SYSTEMS=>join(", ",
                                       map({$_->{name}} @{$rec->{systems}})),
                                     APPLICATIONS=>$applications
                                  }
                               });
                  return($subject,$text);
               });
         }
      }

      if (defined($to_refresh) && $to_refresh->{days}<-30){
         my $msg="hardware is out of date - refresh is necessary";
         push(@dataissue,$msg);
         push(@qmsg,$msg);
         $errorlevel=3 if ($errorlevel<3);
      }
   }
   my @result=$self->HandleQRuleResults("None",
                 $dataobj,$rec,$checksession,
                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);
   return(@result);
}

sub finalizeNotifyParam
{
   my $self=shift;
   my $rec=shift;
   my $notifyparam=shift;
   my $mode=shift;

   $notifyparam->{emailcc}=[$self->getApplmgrUserIds($rec)];
}



sub getApplmgrUserIds
{
   my $self=shift;
   my $rec=shift;

   # calculate application managers
   my @applid;
   my @applmgrid;
   foreach my $arec (@{$rec->{applications}}){
      push(@applid,$arec->{applid});
   }
   if ($#applid!=-1){
      my $appl=getModuleObject($self->getParent->Config,"itil::appl");
      $appl->SetFilter({id=>\@applid});
      @applmgrid=$appl->getVal("applmgrid");
   }
   return(@applmgrid);
}







1;
