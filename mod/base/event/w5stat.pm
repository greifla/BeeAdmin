package base::event::w5stat;
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
use kernel::Event;
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


   $self->RegisterEvent("w5stat","w5stat",timeout=>21600);
   $self->RegisterEvent("w5statsend","w5statsend");
   return(1);
}

sub w5stat
{
   my $self=shift;
   my $month=shift;

   if (!defined($month)){
      my ($year,$mon,$day, $hour,$min,$sec) = Today_and_Now("GMT");
      $month=sprintf("%04d%02d",$year,$mon);
   }

   my $stat=getModuleObject($self->Config,"base::w5stat");

   $stat->recreateStats("w5stat",$month);

   return({exitcode=>0});
}

sub w5statsend
{
   my $self=shift;
   my $force=shift;

   my ($year,$mon,$day, $hour,$min,$sec)=Today_and_Now("GMT");
   



   my $month=sprintf("%04d%02d",$year,$mon);
   my $forcesend=0;
   {
      my ($year1,$mon1,$day1, $hour1,$min1,$sec1)=
              Add_Delta_YMD("GMT",$year,$mon,$day,0,0,7);
      if ($mon!=$mon1){
         $forcesend=1;
      }
   }
   if (lc($force) eq "force" ||
       lc($force) eq "-force"){
      $forcesend=1;
   }

   my $w5stat=getModuleObject($self->Config,"base::w5stat");
   my $user=getModuleObject($self->Config,"base::user");
   my $grp=getModuleObject($self->Config,"base::grp");
   my $ia=getModuleObject($self->Config,"base::infoabo");
   my $lnkgrp=getModuleObject($self->Config,"base::lnkgrpuser");
   my $lnkrole=getModuleObject($self->Config,"base::lnkgrpuserrole");
   $grp->SetFilter({cistatusid=>[3,4]});
   #$grp->SetFilter({cistatusid=>[3,4],fullname=>"*t-com.st"});
   $grp->SetCurrentView(qw(grpid fullname));
   my ($rec,$msg)=$grp->getFirst();
   if (defined($rec)){
      do{
         my $emailto={};
         $lnkgrp->ResetFilter();
         $lnkgrp->SetFilter({grpid=>\$rec->{grpid}});
         my @RBoss;
         my @RReportReceive;
         foreach my $lnkrec ($lnkgrp->getHashList(qw(userid lnkgrpuserid))){
            $lnkrole->ResetFilter();
            $lnkrole->SetFilter({lnkgrpuserid=>\$lnkrec->{lnkgrpuserid}});
            foreach my $lnkrolerec ($lnkrole->getHashList("role")){
               if ($lnkrolerec->{role} eq "RBoss"){
                  push(@RBoss,$lnkrec->{userid});
               }
               if ($lnkrolerec->{role} eq "RReportReceive"){
                  push(@RReportReceive,$lnkrec->{userid});
               }
            }
         }
         if ($#RReportReceive==-1){
            $ia->LoadTargets($emailto,'base::staticinfoabo',\'STEVqreportbyorg',
                                      '110000002',\@RBoss,default=>1);
         }
         $user->ResetFilter();
         $user->SetFilter({userid=>\@RReportReceive,cistatusid=>'<=4'});
         foreach my $urec ($user->getHashList("email")){
            if ($urec->{email} ne ""){
               $emailto->{$urec->{email}}++;
            }
         }
         if (keys(%$emailto)){
            my @emailto=keys(%$emailto);
            msg(INFO,"process group $rec->{fullname}($rec->{grpid})");
            
            $w5stat->ResetFilter();
            $w5stat->SetFilter([{month=>\$month,
                                 nameid=>\$rec->{grpid},
                                 sgroup=>\'Group'},
                                {month=>\$month,
                                 fullname=>\$rec->{fullname},
                                 sgroup=>\'Group'}]);
            my ($chkrec,$msg)=$w5stat->getOnlyFirst(qw(id));
            if (defined($chkrec)){
               my ($primrec,$hist)=$w5stat->LoadStatSet(id=>$chkrec->{id});
               if (defined($primrec) &&
                   defined($w5stat->{w5stat}->{'base::ext::w5stat'})){
                  msg(INFO,"primrec ok and stat processor found");
                  my $obj=$w5stat->{w5stat}->{'base::ext::w5stat'};
                  my %P=$obj->getPresenter();
                  if (defined($P{'overview'}) &&
                      defined($P{'overview'}->{opcode})){
                     msg(INFO,"overview tag handler found");
                     foreach my $emailto (@emailto){
                        my $lang="";
                        $user->ResetFilter();
                        $user->SetFilter({email=>\$emailto});
                        my ($urec,$msg)=$user->getOnlyFirst(qw(lastlang 
                                                               lang));
                        if (defined($urec)){
                           if ($urec->{lastlang} ne ""){
                              $lang=$urec->{lastlang};
                           }
                           if ($lang eq ""){
                              $lang=$urec->{lang};
                           }
                           $lang eq "en" if ($lang eq "");

           
                           $ENV{HTTP_FORCE_LANGUAGE}=$lang;
                           my ($d,$ovdata)=&{$P{'overview'}->{opcode}}($obj,
                                                            $primrec,$hist);
                           my $needsend=$forcesend;
                           foreach my $ovrec (@$ovdata){
                              if (defined($ovrec->[2]) && 
                                  $ovrec->[2] eq "red"){
                                 $needsend=1;last;
                              }
                           }
                           msg(INFO,"target=$emailto lang=$lang ".
                                    "needsend=$needsend");
                           if ($needsend && 1){
                              $self->sendOverviewData($emailto,$lang,
                                                  $primrec,$hist,$d,$ovdata);
                           }
                           delete($ENV{HTTP_FORCE_LANGUAGE});
                        }
                     }
                  }
               }
            }
         }
         ($rec,$msg)=$grp->getNext();
      }until(!defined($rec));
   }
   return({exitcode=>0});
}

sub sendOverviewData
{
   my $self=shift;
   my $emailto=shift;
   my $lang=shift;
   my $primrec=shift;
   my $hist=shift;
   my $d=shift;
   my $ovdata=shift;

   my $wf=getModuleObject($self->Config,"base::workflow");
   my $sitename=$wf->Config->Param("SITENAME");
   my $joburl=$wf->Config->Param("EventJobBaseUrl");
   my @emailtext;
   foreach my $ovrec (@$ovdata){
      if ($#{$ovrec}==0){
         push(@emailtext,"---\n".$ovrec->[0]);
      }
      else{
         push(@emailtext,$ovrec->[0].": ".$ovrec->[1]);
      }
   }
   my $month=$primrec->{month};
   my ($Y,$M)=$month=~m/^(\d{4})(\d{2})$/;
   my $month=sprintf("%02d/%04d",$M,$Y);
 
   if (my $id=$wf->Store(undef,{
          class    =>'base::workflow::mailsend',
          step     =>'base::workflow::mailsend::dataload',
          name     =>$sitename.": ".'QualityReport '.
                     $month." ".$primrec->{fullname},
          emailtemplate =>'w5stat',
          emaillang     =>$lang,
          emailcc       =>['hartmut.vogler@t-systems.com'],
          emailfrom     =>$emailto,
          emailtext     =>\@emailtext,
          emailto       =>$emailto,
          additional    =>{
             htmldata=>$d,month=>$month, 
             directlink=>$joburl.
                         "/auth/base/menu/msel/Tools/reflexion?search_id=".
                         $primrec->{id},
             fullname=>$primrec->{fullname}
          },
         })){
      my $r=$wf->Store($id,step=>'base::workflow::mailsend::waitforspool');
      return({msg=>'versandt'});
   }
}

1;
