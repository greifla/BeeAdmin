package kernel::CIStatusTools;
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
use kernel;
use Data::Dumper;


sub ProtectObject
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $admingroups=shift;

   my $effcistatus=effVal($oldrec,$newrec,"cistatusid");
   if (!defined($effcistatus)){
      $self->LastMsg(ERROR,"no cistatus specified");
      return(0);
   }
   my $effowner=effVal($oldrec,$newrec,"owner");
   my $curruserid=$self->getCurrentUserId();
   if ($effcistatus<2 && defined($effowner) && $curruserid!=$effowner){
      $self->LastMsg(ERROR,"you are only authorized to edit this record");
      return(0);
   }
   if ($effcistatus>2 && !$self->IsMemberOf($admingroups)){
      $self->LastMsg(ERROR,"you are only authorized to add in 'order' ".
                           "or 'reserved' state");
      return(0);
   }

   return(1);
}

# process if the cistatus turns from <=4 to >4 - if it is, the primary
# key must be renamed to xxx[n]
sub HandleCIStatusModification
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my @primarykey=@_;

   my $idfield=$self->IdField->Name();
   my $id=effVal($oldrec,$newrec,$idfield);
   my $cistatusid=effVal($oldrec,$newrec,"cistatusid");
   if (!defined($id) && defined($newrec) && $newrec->{cistatusid}==6){
      $self->LastMsg(ERROR,"can't idenfify target record id");
      return(0);
   }
   my $adduniq=0;
   my $deluniq=0;

   if (((defined($oldrec) && $oldrec->{cistatusid}<=5) || !defined($oldrec)) && 
         (defined($newrec->{cistatusid}) && $newrec->{cistatusid}>5)){ 
      $adduniq=1;
   }
   if (defined($newrec->{cistatusid}) && $newrec->{cistatusid}<6){
      $deluniq=1;
   }
   if ($adduniq || $deluniq){
      foreach my $primarykey (@primarykey){
         if (!defined($newrec->{$primarykey})){
            $newrec->{$primarykey}=$oldrec->{$primarykey};
         }
         $newrec->{$primarykey}=trim($newrec->{$primarykey});
      }
   }
   if ($adduniq){
      foreach my $primarykey (@primarykey){
         for(my $c=0;$c<=100;$c++){
            my $chkname=$newrec->{$primarykey}."[$c]";
            $self->SetFilter($primarykey=>\$chkname);
            my $chkid=$self->getVal($idfield);
            if (!defined($chkid)){
               $newrec->{$primarykey}=$chkname;
               return(1);
            }
         }
         $self->LastMsg(ERROR,"can't find a unique name for '%s'",$primarykey);
         return(0);
      }
   }
   if ($deluniq){
      foreach my $primarykey (@primarykey){
         $newrec->{$primarykey}=~s/\[.*\]$//;
      }
   }
   if ($cistatusid!=6){
      foreach my $primarykey (@primarykey){
         my $primkeyval=effVal($oldrec,$newrec,$primarykey);
         if ($primkeyval=~m/\[.*\]\s*$/){
            $self->LastMsg(ERROR,
                           "invalid character in key field '\%s'",$primarykey);
            return(0);
         }
      }
   }

   return(1);   # all ok - now break error
}

sub HandleCIStatus
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my %param=@_;

   $param{activator}="admin" if (!defined($param{activator}));
   $param{activator}=[$param{activator}] if (ref($param{activator}) ne "ARRAY");
   if (!defined($param{mode})){
      my ($package,$filename, $line, $subroutine)=caller(1);
      $subroutine=~s/^.*:://;
      $param{mode}=$subroutine;
   }
   #printf STDERR ("fifi HandleCIStatus mode=$param{mode}\n");
   if ($param{mode} eq "SecureValidate"){
      if (!defined($oldrec)){
         if ($newrec->{cistatusid}>2 || $newrec->{cistatusid}==0){
            if (!$self->isActivator($oldrec,$newrec,%param)){
               $self->LastMsg(ERROR,"you are not authorized to create ".
                                    "items with this state");
               return(0);
            }
         }
      }
      else{
         if (!defined($oldrec) && $newrec->{cistatusid}==0){
            if (!$self->isActivator($oldrec,$newrec,%param)){
               $self->LastMsg(ERROR,"you are not authorized to set ".
                                    "this state");
               return(0);
            }
         }
         if ($oldrec->{cistatusid}==1 && $newrec->{cistatusid}>2){
            if (!$self->isActivator($oldrec,$newrec,%param)){
               $self->LastMsg(ERROR,"you are not authorized to set ".
                                    "this state, please set state ".
                                    "to \"requested\"");
               return(0);
            }
         }
         elsif ($newrec->{cistatusid}>2){
            if ($oldrec->{cistatusid}<4){
               if (!$self->isActivator($oldrec,$newrec,%param)){
                  $self->LastMsg(ERROR,"you are not authorized to set ".
                                       "this state, please wait for ".
                                       "activation");
                  return(0);
               }
            }
         }
      }
   }
   if ($param{mode} eq "Validate"){
      return($self->HandleCIStatusModification($oldrec,$newrec,
                                               $param{uniquename}));
   }
   if ($param{mode} eq "FinishWrite"){
      if (!defined($oldrec)){
         if ($newrec->{cistatusid}==2){
            $self->NotifyAdmin("request",$oldrec,$newrec,%param);
            # notify admin about the request (owner in cc)
         }
         if ($newrec->{cistatusid}==1){
            $self->NotifyAdmin("reservation",$oldrec,$newrec,%param);
            # notify notify owner about the reservation and
            # about the unuseable state of this entry
         }
      }
      else{
         if ($oldrec->{cistatusid}<2 && $newrec->{cistatusid}==2){
            $self->NotifyAdmin("request",$oldrec,$newrec,%param);
         }
         if ($newrec->{cistatusid}==4 && $oldrec->{cistatusid}<3){
            $self->NotifyAdmin("activate",$oldrec,$newrec,%param);
         }
      }
   }
   if ($param{mode} eq "FinishDelete"){
      if ($oldrec->{cistatusid}==2){
         $self->NotifyAdmin("drop",$oldrec,$newrec,%param);
      }
   }
   #printf STDERR ("ciparam=%s\n",Dumper(\%param));


   return(1);
}

sub NotifyAdmin
{
   my $self=shift;
   my $mode=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my %param=@_;

   my $idname=$self->IdField->Name();
   my $creator=effVal($oldrec,$newrec,"creator");
   my $userid=$self->getCurrentUserId();
   my $name=effVal($oldrec,$newrec,$param{uniquename});
   my $id=effVal($oldrec,$newrec,$idname);
   my $modulename=$self->T($self->Self,$self->Self);
   my $wf=getModuleObject($self->Config,"base::workflow");

   my $user=getModuleObject($self->Config,"base::user");
   $user->Initialize();
   #delete($user->{DB});
   return() if ($creator==0);
   $user->SetFilter({userid=>\$creator});
   my ($creatorrec,$msg)=$user->getOnlyFirst(qw(email givenname surname));
   return() if (!defined($creatorrec));
   my $fromname=$creatorrec->{surname};
   $fromname.=", " if ($creatorrec->{givenname} ne "" && $fromname ne "");
   $fromname.=$creatorrec->{givenname} if ($creatorrec->{givenname});
   $fromname=$creatorrec->{email} if ($fromname eq "");

   my $url=$ENV{SCRIPT_URI};
   $url=~s/[^\/]+$//;
   my $publicurl=$url;
   my $listurl=$url;
   my $itemname=$self->T($self->Self,$self->Self);;
   $url.="Detail?$idname=$id";
   $listurl.="Main";
   $publicurl=~s#/auth/#/public/#g;
   my $cistatuspath=$self->Self;
   $cistatuspath=~s/::/\//g;
   $cistatuspath.="/$id";
   $cistatuspath.="?HTTP_ACCEPT_LANGUAGE=".$self->Lang();

   my $wfname;
   my %notiy;
   my $msg;
   if ($mode eq "request"){
      $user->SetFilter({groups=>$param{activator}});
      my @admin=$user->getHashList(qw(email givenname surname));
      $notiy{emailto}=[map({$_->{email}} @admin)];
      $notiy{emailcc}=[$creatorrec->{email}];
      $wfname=$self->T("Request to activate '%s' in module '%s'");
      $wfname=sprintf($wfname,$name,$modulename);
      $msg=$self->T("MSG001");
      $msg=sprintf($msg,$fromname,$name,$url,$itemname,$listurl);
   }
   if ($mode eq "reservation"){
      $notiy{emailto}=[$creatorrec->{email}];
      $wfname=$self->T("Reservation confirmation for '%s' in module '%s'");
      $wfname=sprintf($wfname,$name,$modulename);
      $msg=$self->T("MSG002");
      $msg=sprintf($msg,$fromname,$name,$url,$itemname,$listurl);
   }
   if ($mode eq "activate"){
      $notiy{emailto}=[$creatorrec->{email}];
      $wfname=$self->T("Activation notification for '%s' in module '%s'");
      $wfname=sprintf($wfname,$name,$modulename);
      $msg=$self->T("MSG003");
      $msg=sprintf($msg,$name,$url,$itemname,$listurl);
   }
   if ($mode eq "drop"){
      $notiy{emailto}=[$creatorrec->{email}];
      $wfname=$self->T("Drop notification for '%s' in module '%s'");
      $wfname=sprintf($wfname,$name,$modulename);
      $msg=$self->T("MSG004");
      $msg=sprintf($msg,$name);
      return() if ($creator==$userid);
   }
   my $sitename=$self->Config->Param("SITENAME");
   my $subject=$wfname;
   if ($sitename ne ""){
      $subject=$sitename.": ".$subject;
   }

   my $imgtitle=$self->T("current state of the requested CI");


   $notiy{emailfrom}=$creatorrec->{email};
   $notiy{name}=$subject;
   if ($mode ne "drop"){
      $notiy{emailpostfix}=<<EOF;
<br>
<br>
<img title="$imgtitle" src="${publicurl}../../base/cistatus/show/$cistatuspath">
EOF
   }
   $notiy{emailtext}=$msg;
   $notiy{class}='base::workflow::mailsend';
   $notiy{step}='base::workflow::mailsend::dataload';
   if (my $id=$wf->Store(undef,\%notiy)){
      my %d=(step=>'base::workflow::mailsend::waitforspool');
      my $r=$wf->Store($id,%d);
   }
   return(0);
}





sub isActivator
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my %param=@_;

   if ($self->IsMemberOf($param{activator})){
      return(1);
   }
   return(0);
}

sub NotifyOnCIStatusChange
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (!defined($oldrec) && !$self->IsMemberOf("admin")){
      msg(DEBUG,"now we can notify the admins about the request");
      # notify admin
   }
   if (defined($oldrec)){
      if ($newrec->{cistatus}>2 && $oldrec->{cistatus}<=2){
         msg(DEBUG,"now we can notify the createor about the activation");
         # notify creator
      }
   }


   return();
}

sub NotifyAddOrRemoveObject
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $labelname=shift;
   my $infoaboname=shift;
   my $infoaboid=shift;
   my $idname=$self->IdField->Name();
   my $id=effVal($oldrec,$newrec,$idname);
   my $modulelabel=$self->T($self->Self,$self->Self);
   my $mandatorid=effVal($oldrec,$newrec,"mandatorid");
   my $name=effVal($oldrec,$newrec,$labelname);
   my $fullname="???";

   my $UserCache=$self->Cache->{User}->{Cache};
   if (defined($UserCache->{$ENV{REMOTE_USER}})){
      if ($UserCache->{$ENV{REMOTE_USER}}->{rec}->{fullname} ne ""){
         $fullname=$UserCache->{$ENV{REMOTE_USER}}->{rec}->{fullname};
      }
   }

   my $url=$ENV{SCRIPT_URI};
   $url=~s/[^\/]+$//;
   my $publicurl=$url;
   my $listurl=$url;
   my $itemname=$self->T($self->Self,$self->Self);;
   $url.="Detail?$idname=$id";
   $listurl.="Main";
   $publicurl=~s#/auth/#/public/#g;
   my $cistatuspath=$self->Self;
   $cistatuspath=~s/::/\//g;
   $cistatuspath.="/$id";
   $cistatuspath.="?HTTP_ACCEPT_LANGUAGE=".$self->Lang();

   my $op;
   if (defined($oldrec) && !defined($newrec)){
      $op="delete";
   }
   if (!defined($oldrec) && defined($newrec)){
      $op="insert";
   }
   if (defined($oldrec) && defined($newrec)){
      if (exists($newrec->{cistatusid})){
         if ($newrec->{cistatusid}==4 && $oldrec->{cistatusid}!=4){
            $op="activate";
         }
         if ($newrec->{cistatusid}!=4 && $oldrec->{cistatusid}==4){
            $op="deactivate";
         }
      }
   }
   if (defined($op)){
      my $mandator;
      if ($mandatorid ne ""){
         my $ma=getModuleObject($self->Config,"base::mandator");
         $ma->SetFilter({grpid=>\$mandatorid});
         my ($marec,$msg)=$ma->getOnlyFirst(qw(name));
         if (defined($marec)){ 
            $mandator=$marec->{name};
         }
      }
      my $msg;
      if ($op eq "insert"){
         $msg=$self->T("MSG005");
         $msg=sprintf($msg,$modulelabel,$name,$mandator,$fullname);
         $msg.="\n\nDirectLink:\n$url";
      }
      if ($op eq "delete"){
         $msg=$self->T("MSG006");
         $msg=sprintf($msg,$modulelabel,$name,$mandator,$fullname);
      }
      if ($op eq "activate"){
         $msg=$self->T("MSG007");
         $msg=sprintf($msg,$modulelabel,$name,$mandator,$fullname);
         $msg.="\n\nDirectLink:\n$url";
      }
      if ($op eq "deactivate"){
         $msg=$self->T("MSG008");
         $msg=sprintf($msg,$modulelabel,$name,$mandator,$fullname);
         $msg.="\n\nDirectLink:\n$url";
      }
      my $sitename=$self->Config->Param("SITENAME");
      my $subject="Config-Change: ";
      if ($mandator ne ""){
         $subject.=" $mandator: ";
      }

      $subject.=effVal($oldrec,$newrec,$labelname);
      if ($sitename ne ""){
         $subject=$sitename.": ".$subject;
      }
      my $ia=getModuleObject($self->Config,"base::infoabo");
      my @emailto;
      my $emailto={};
      $ia->LoadTargets($emailto,'base::staticinfoabo',\$infoaboname,
                                 $infoaboid,undef);

      if ($op eq "delete" || $op eq "deactivate"){
         my $databossobj=$self->getField("databossid");
         if (defined($databossobj)){
            my $databossid=effVal($oldrec,$newrec,"databossid");
            my $userid=$self->getCurrentUserId();
            if ($databossid!=$userid && $databossid ne ""){
               my $user=getModuleObject($self->Config,"base::user");
               $user->SetFilter({userid=>\$databossid});
               my ($urec,$msg)=$user->getOnlyFirst(qw(email));
               if (defined($urec) && $urec->{email} ne ""){
                  $emailto->{$urec->{email}}=1;         
               }
            }
         }
      }




      @emailto=keys(%$emailto);
      if ($#emailto!=-1){
         my %notiy;
         $notiy{name}=$subject;
         $notiy{emailtext}=$msg;
         $notiy{emailto}=\@emailto;
         $notiy{class}='base::workflow::mailsend';
         $notiy{step}='base::workflow::mailsend::dataload';
         my $wf=getModuleObject($self->Config,"base::workflow");
         if (my $id=$wf->Store(undef,\%notiy)){
            my %d=(step=>'base::workflow::mailsend::waitforspool');
            my $r=$wf->Store($id,%d);
         }
      }
   }
}


1;

