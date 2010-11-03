package tswiw::qrule::WiwUserOrgstruct;
#  W5Base Framework
#  Copyright (C) 2010  Hartmut Vogler (it@guru.de)
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
   return(["base::user"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $errorlevel=0;

   my $Config=$self->getParent->Config;
   $self->{SRCSYS}="WhoIsWho";

   my $user=getModuleObject($Config,"base::user");
   my $mainuser=getModuleObject($Config,"base::user");
   my $grp=getModuleObject($Config,"base::grp");
   my $grpuser=getModuleObject($Config,"base::lnkgrpuser");
   my $wiwusr=getModuleObject($Config,"tswiw::user");
   my $wiworg=getModuleObject($Config,"tswiw::orgarea");

   if (!defined($wiwusr) ||
       !defined($wiworg) ||
       !defined($grpuser)||
       !defined($user)   ||
       !defined($mainuser)   ||
       !defined($grp)){
      msg(ERROR,"WiwUserOrgstruct can't connect nesassary information objects");
      return($errorlevel,undef);
   }


   $mainuser->ResetFilter();
   $mainuser->SetFilter({userid=>\$rec->{userid}});
   my ($urec)=$mainuser->getOnlyFirst(qw(email surname givenname usertyp 
                                         groups posix));
   if (defined($urec)){ # found correct urec record for user
      print STDERR Dumper($urec);
      if (defined($urec) && $urec->{email} ne "" &&
          $urec->{email} ne 'null@null.com' &&
          $urec->{usertyp} eq "user"){     # it seems to be a correct email
         msg(INFO,"processing email addr '%s'",$urec->{email});
         my @curgrpid=$self->extractCurrentGrpIds($urec);
         msg(INFO,"grpids='%s'",join(",",@curgrpid));
         msg(INFO,"validateing userid=$urec->{userid} requested");

         #
         # load srcid's from base::grp
         #
         $grp->SetFilter({grpid=>\@curgrpid,srcsys=>\$self->{SRCSYS}});
         $grp->SetCurrentView(qw(grpid srcid srcsys srcload));
         my $curgrps=$grp->getHashIndexed(qw(grpid srcid));

         #
         # loading the "should" sitiuation from wiw
         #
         msg(DEBUG,"trying to load userinformations from wiw");
         $wiwusr->SetFilter([{email=>$urec->{email}},
                             {email2=>$urec->{email}},
                             {email3=>$urec->{email}}]);
         my ($wiwrec,$msg)=$wiwusr->getOnlyFirst(qw(ALL));
         if (!defined($wiwrec)){
            if (defined($msg)){
               msg(ERROR,"LDAP problem:%s",$msg);
            }
            msg(ERROR,"User '%s' couldn't be found in LDAP",$urec->{email});
            return($errorlevel,undef);
         }
         print STDERR Dumper($wiwrec);


         my $wiwid=$wiwrec->{id};
         my $touid=$wiwrec->{touid};
         my $surname=$wiwrec->{surname};
         my $givenname=$wiwrec->{givenname};
         my $uidlist=$wiwrec->{uid};
         $uidlist=[$uidlist] if (ref($uidlist) ne "ARRAY");
         my @posix=grep(!/^[A-Z]{1,3}\d+$/,@{$uidlist});
         my $posix=$posix[0];

         my $wiwstate=$wiwrec->{office_state};
         my $level1role="RFreelancer";
         if ($wiwstate eq "Intern" ||
             $wiwstate eq "Manager" ||
             $wiwstate eq "Employee"){
            $level1role="REmployee";
         }
         if ($wiwstate eq "Auszubildender"){
            $level1role="RApprentice";
         }
         msg(INFO,"organizationalstatus=$wiwstate --- w5base role=$level1role");
         

         #
         # hinzuf�gen der Userrollen
         #
         if ($touid ne ""){
            $wiworg->SetFilter({touid=>\$touid});
            my ($wiwrec,$msg)=$wiworg->getOnlyFirst(qw(touid name parentid 
                                                       parent shortname));
            if (defined($wiwrec)){
               my $bk=$self->addGrpLinkToUser($grp,$wiworg,$grpuser,
                                              $wiwrec,$urec,
                                              [$level1role,'RMember']);
               return($errorlevel,undef) if (defined($bk));
            }
            else{
               if (defined($msg)){
                  msg(ERROR,"LDAP problem - Orgsearch:%s",$msg);
               }
               msg(ERROR,"WIW Orgarea '%s' not found for user '%s'",
                   $touid,$urec->{email});
            }
         }
         else{
            msg(DEBUG,"user '%s' has no orgarea",$urec->{email});
         }




         #
         # hinzuf�gen der Leiter rollen
         #
         if (!defined($wiwid) || $wiwid eq ""){
            msg(ERROR,"can't find wiwid of user '%s'",$urec->{email});
            return($errorlevel,undef);
         }
         $wiworg->SetFilter({mgrwiwid=>\$wiwid});
         foreach my $wiwrec ($wiworg->getHashList(
                              qw(touid name parentid parent shortname))){
            my $bk=$self->addGrpLinkToUser($grp,$wiworg,$grpuser,
                                           $wiwrec,$urec,
                                           ['RBoss']);
            return($errorlevel,undef) if (defined($bk));
         }


         if ($posix ne "" && defined($urec->{userid})){
            my %upd=(posix=>$posix,
                     surname=>$surname,
                     givenname=>$givenname);
            msg(DEBUG,"Refreshing posix id '$posix' of user '%s'",
                $urec->{email});
            my $back=$user->ValidatedUpdateRecord($urec,\%upd,
                                 {userid=>\$urec->{userid}});
         }
         else{
            msg(DEBUG,"no posix update posix='$posix' ".
                      "userid='$urec->{userid}'");
         }
      }
   }
   return($errorlevel,undef);
}

sub extractCurrentGrpIds
{
   my $self=shift;
   my $urec=shift;

   my @curgrpid=();
   msg(DEBUG,"processing email addr '%s'",$urec->{email});
   if (defined($urec->{groups}) && ref($urec->{groups}) eq "ARRAY"){
      foreach my $grp (@{$urec->{groups}}){
         $grp->{roles}=[] if (!defined($grp->{roles}));
         if (grep(/^REmployee$/,@{$grp->{roles}})){
            push(@curgrpid,$grp->{grpid});
         }
      }
   }
   return(@curgrpid);
}


sub addGrpLinkToUser
{
   my $self=shift;
   my $grp=shift;     # communication object
   my $wiworg=shift;  # communication object
   my $grpuser=shift; # communication object
   my $wiwrec=shift;    # wiw orgarea record
   my $urec=shift;      # aktueller User record
   my $roles=shift;     # array auf zuzuweisende rollen

   my $app=$self->getParent();
   my $nowstamp=$app->ExpandTimeExpression("now","en","GMT","GMT");
   my $grpid2add=$self->getGrpIdOf($grp,$wiworg,$wiwrec);
   if (defined($grpid2add)){
      $grpuser->SetFilter({userid=>\$urec->{userid},
                           grpid=>\$grpid2add});
      $grpuser->SetCurrentView(qw(grpid userid lnkgrpuserid roles 
                                  srcsys srcid srcload));
      my ($lnkrec,$msg)=$grpuser->getFirst();
      my $oldrolestring="";
      my $newrolestring="";
      if (defined($lnkrec)){
         my %newroles;
         my @oldroles;
         my @origroles;
         if (!in_array($roles,"RBoss")){
            my @orgRoles=grep(!/^RBoss$/,orgRoles()); # RBoss muss bleiben!
            if (defined($lnkrec->{roles})){
               $oldrolestring=join(",",sort(@{$lnkrec->{roles}}));
               @origroles=@{$lnkrec->{roles}};
               foreach my $r (@{$lnkrec->{roles}}){
                  push(@oldroles,$r) if (!in_array(\@orgRoles,$r));
               }
            }
         }
         else{
            @oldroles=@{$lnkrec->{roles}};
         }
         foreach my $r (@$roles,@oldroles){
            $newroles{$r}++;
         }
         $newrolestring=join(",",sort(keys(%newroles)));
         my %newlnk=(roles=>[keys(%newroles)],
                     expiration=>undef,
                     alertstate=>undef,
                     srcsys=>$self->{SRCSYS},
                     srcid=>"none",
                     srcload=>$nowstamp);
         my $bk=$grpuser->ValidatedUpdateRecord($lnkrec,\%newlnk,
                            {lnkgrpuserid=>$lnkrec->{lnkgrpuserid}});
         if (!in_array(\@origroles,$roles->[0])){
            $self->NotifyNewTeamRelation($lnkrec->{lnkgrpuserid},
                                         $urec->{userid},$grpid2add,"Rchange",
                                         $roles);
         }
      }
      else{
         $newrolestring=join(",",sort(@$roles));
         my %newlnk=(userid=>$urec->{userid},
                     roles=>$roles,
                     srcsys=>$self->{SRCSYS},
                     srcload=>$nowstamp,
                     expiration=>undef,
                     alertstate=>undef,
                     grpid=>$grpid2add);
         #printf STDERR ("fifi try to create lnk %s\n",Dumper(\%newlnk));
         my $bk=$grpuser->ValidatedInsertRecord(\%newlnk);
         if ($bk){
            $self->NotifyNewTeamRelation($bk,$urec->{userid},$grpid2add,"Rnew",
                                         $roles)
         }
      }
   }
   else{
      msg(ERROR,"Can't create group for user '$urec->{email}'");
      msg(ERROR,$self->getParent->LastMsg());
   }
   return(undef);
}


sub getGrpIdOf
{
   my $self=shift;
   my $grp=shift;
   my $wiworg=shift;
   my $wiwrec=shift;

   msg(DEBUG,"try to find touid=$wiwrec->{touid} in base::grp");

   $grp->SetFilter({srcid=>\$wiwrec->{touid},srcsys=>\$self->{SRCSYS}});
   $grp->SetCurrentView(qw(grpid srcid srcsys srcload));
   my ($rec,$msg)=$grp->getFirst();
   if (defined($rec)){
      return($rec->{grpid});
   }
   return($self->createGrp($grp,$wiworg,$wiwrec));

}


sub createGrp
{
   my $self=shift;
   my $grp=shift;
   my $wiworg=shift;
   my $wiwrec=shift;

   msg(INFO,"try to create touid=$wiwrec->{touid} in base::grp");
   my $parentid;
   if (defined($wiwrec->{parentid})){
      $wiworg->SetFilter({touid=>[$wiwrec->{parentid}]});
      $wiworg->SetCurrentView(qw(touid name parentid parent shortname));
      my ($wiwrec,$msg)=$wiworg->getFirst();
      $parentid=$self->getGrpIdOf($grp,$wiworg,$wiwrec);
      if (!defined($parentid)){
         msg(ERROR,"problem in createGrp '$grp' from WiW ".
                   "tOuID $wiwrec->{touid}");
         return(undef);
      }
   }
   elsif ($wiwrec->{parentid} eq "DE039607"){  # T-Deutschland
      my @view=qw(id name);
      $grp->SetFilter({fullname=>\"DTAG.TDE"});
      $grp->SetCurrentView(@view);
      my ($rec,$msg)=$grp->getFirst();
      if (!defined($rec)){
         $grp->SetFilter({fullname=>\"DTAG"});
         $grp->SetCurrentView(@view);
         my ($rec,$msg)=$grp->getFirst();
         my $parentoftsi;
         if (!defined($rec)){
            my %newgrp=(name=>"DTAG",cistatusid=>4);
            my $back=$grp->ValidatedInsertRecord(\%newgrp);
            $parentoftsi=$back; 
         }
         else{
            $parentoftsi=$rec->{grpid};
         }
         my %newgrp=(name=>"TDE",parent=>'DTAG',cistatusid=>4);
         $parentid=$grp->ValidatedInsertRecord(\%newgrp);
      }
      else{
         $parentid=$rec->{grpid}; 
      }
   }
   else{
      # wenn keine parentid im WIW, dann mit DTAG.TSI "verbinden"
      my @view=qw(id name);
      $grp->SetFilter({fullname=>\"DTAG.TSI"});
      $grp->SetCurrentView(@view);
      my ($rec,$msg)=$grp->getFirst();
      if (!defined($rec)){
         $grp->SetFilter({fullname=>\"DTAG"});
         $grp->SetCurrentView(@view);
         my ($rec,$msg)=$grp->getFirst();
         my $parentoftsi;
         if (!defined($rec)){
            my %newgrp=(name=>"DTAG",cistatusid=>4);
            my $back=$grp->ValidatedInsertRecord(\%newgrp);
            $parentoftsi=$back; 
         }
         else{
            $parentoftsi=$rec->{grpid};
         }
         my %newgrp=(name=>"TSI",parent=>'DTAG',cistatusid=>4);
         $parentid=$grp->ValidatedInsertRecord(\%newgrp);
      }
      else{
         $parentid=$rec->{grpid}; 
      }
   }


   my $newname=$wiwrec->{shortname};
   if ($newname eq ""){
      msg(ERROR,"no shortname for id '$wiwrec->{touid}' found");
      return(undef);
   }
   ################################################################
   $newname=~s/[^A-Z\.0-9,-]/_/gi;    # rewriting for some shit names
   my %newgrp=(name=>$newname,
               srcsys=>$self->{SRCSYS},
               srcid=>$wiwrec->{touid},
               cistatusid=>4,
               srcload=>NowStamp(),
               comments=>"Description from WhoIsWho: ".$wiwrec->{name});
   $newgrp{name}=~s/&/_u_/g;
   $newgrp{parentid}=$parentid if (defined($parentid));
   msg(DEBUG,"Write=%s",Dumper(\%newgrp));
   my $back=$grp->ValidatedInsertRecord(\%newgrp);
   msg(DEBUG,"ValidatedInsertRecord returned=$back");

   return($back);
}

sub NotifyNewTeamRelation
{
   my $self=shift;
   my $relid=shift;
   my $userid=shift;
   my $grpid=shift;
   my $op=shift;
   my $roles=shift;
   my $Config=$self->getParent->Config();
   msg(INFO,"NotifyNewTeamRelation: userid=$userid grpid=$grpid op=$op");

   my $user=getModuleObject($Config,"base::user");
   $user->SetFilter({userid=>\$userid,cistatusid=>"<6"});
   my ($urec)=$user->getOnlyFirst(qw(email lang));

   my $grp=getModuleObject($Config,"base::grp");
   $grp->SetFilter({grpid=>\$grpid,cistatusid=>"<6"});
   my ($grec)=$grp->getOnlyFirst(qw(fullname));
   msg(INFO,"--------------");

   if (defined($urec) && defined($grec)){
      $ENV{HTTP_FORCE_LANGUAGE}=$urec->{lang};
      my @emailcc=();
      my @emailbcc=();
      my $wf=getModuleObject($Config,"base::workflow");
   
      my $grpuser=getModuleObject($Config,"base::lnkgrpuser");
      $grpuser->SetFilter({grpid=>\$grpid});
      foreach my $lnkrec ($grpuser->getHashList(qw(userid roles))){
         if (ref($lnkrec->{roles}) eq "ARRAY"){
            if (grep(/^(RBoss|RBoss2)$/,@{$lnkrec->{roles}})){
               $user->SetFilter({userid=>\$lnkrec->{userid}});
               my ($urec)=$user->getOnlyFirst(qw(email));
               push(@emailcc,$urec->{email}) if ($urec->{email} ne "");
            }
         }
      }
     
      my $grpuser=getModuleObject($Config,"base::lnkgrpuser");
      $grpuser->SetFilter({grpid=>\'1'});
      foreach my $lnkrec ($grpuser->getHashList(qw(userid roles))){
         if (ref($lnkrec->{roles}) eq "ARRAY"){
            if (grep(/^(RMember)$/,@{$lnkrec->{roles}})){
               $user->SetFilter({userid=>\$lnkrec->{userid}});
               my ($urec)=$user->getOnlyFirst(qw(email lang));
               push(@emailbcc,$urec->{email}) if ($urec->{email} ne "");
            }
         }
      }
     

      my %adr=(emailto=>$urec->{email},
               emailfrom=>'"WhoIsWho to W5BaseDarwin" <no_reply@w5base.net>',
               emailcc=>\@emailcc,
               emailbcc=>\@emailbcc);

      my $subject;
      my $mailtext;

      my $sitename=$Config->Param("SiteName");
      $sitename="W5Base" if ($sitename eq "");

    
      if ($op eq "Rnew"){
         $subject="$sitename: ".
                  $self->T("new org relation to")." ".$grec->{fullname}; 
         $mailtext=sprintf($self->T("MAILTEXT.NEW"),$grec->{fullname});
      }
      else{
         $subject="$sitename: ".
                  $self->T("role update to")." ".$grec->{fullname}; 
         $mailtext=sprintf($self->T("MAILTEXT.UPDATE"),$grec->{fullname});
      }
      my $baseurl=$Config->Param("EventJobBaseUrl");
      $baseurl.="/" if (!($baseurl=~m/\/$/));
      my $url=$baseurl;
      $url.="auth/base/lnkgrpuser/ById/".$relid;

      $mailtext.="\n\n   <b>Org-Unit:</b>\n".
                 "   ".$grec->{fullname};
      $mailtext.="\n\n   <b>".$self->T("added roles").":</b>\n";
      foreach my $r (@$roles){
         $mailtext.="   ".$self->T($r,"base::lnkgrpuserrole")."\n";
      }
     
      $mailtext.="\n\nDirectLink:\n".$url;
      my $label=$self->T("WhoIsWho to W5Base/Darwin automatic ".
                         "organisation relation administration:");
     
      if (my $id=$wf->Store(undef,{
              class    =>'base::workflow::mailsend',
              step     =>'base::workflow::mailsend::dataload',
              directlnktype =>'base::user',
              directlnkid   =>$userid,
              directlnkmode =>"mail.$op",
              name     =>$subject,
              %adr,
              emailhead=>$label,
              emailtext=>$mailtext
             })){
         my %d=(step=>'base::workflow::mailsend::waitforspool');
         my $r=$wf->Store($id,%d);
      }
      delete($ENV{HTTP_FORCE_LANGUAGE});
   }
}




1;
