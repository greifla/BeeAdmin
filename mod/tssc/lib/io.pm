package tssc::lib::io;
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
use kernel::date;


sub InitScImportEnviroment
{
   my $self=shift;

   $self->{user}=getModuleObject($self->Config,"base::user");
   $self->{appl}=getModuleObject($self->Config,"itil::appl");
   $self->{wf}=getModuleObject($self->Config,"base::workflow");
}



sub ProcessServiceCenterRecord
{
   my $self=shift;
   my $selfname=shift;
   my $rec=shift;
   my $wf=$self->{wf};

   #msg(DEBUG,"chm=%s",Dumper($rec));
   my ($wfstorerec,$updateto);
   if (defined($rec->{changenumber})){
      ($wfstorerec,$updateto)=$self->mkChangeStoreRec($rec,$wf,$selfname);
   }
   if (defined($rec->{problemnumber})){
      ($wfstorerec,$updateto)=$self->mkProblemStoreRec($rec,$wf,$selfname);
   }
   if (defined($rec->{incidentnumber})){
      ($wfstorerec,$updateto)=$self->mkIncidentStoreRec($rec,$wf,$selfname);
   }
   if (defined($wfstorerec)){
      if (!defined($updateto) || $updateto eq ""){
         # create new
         msg(DEBUG,"PROCESS: try to create new workflow entry");
         if (my $id=$wf->Store(undef,$wfstorerec)){
            msg(DEBUG,"workflow id=%s created",$id);
         }
         else{
            msg(ERROR,"failed to create workflow");
         }
      }
      else{
         msg(DEBUG,"PROCESS: update workflow entry '$updateto'");
         $wf->SetFilter({id=>\$updateto});
         $wf->SetCurrentView(qw(ALL));
         $wf->ForeachFilteredRecord(sub{
            msg(DEBUG,"PROCESS: du update to '$updateto'");
            my $oldrec=$_;
            $wf->ValidatedUpdateRecord($oldrec,$wfstorerec,{id=>\$updateto});
         });
      }
   }
   else{
      msg(DEBUG,"no wfstorerec created");
   }
}

sub mkProblemStoreRec
{
   my $self=shift;
   my $rec=shift;
   my $wf=shift;
   my $selfname=shift;
   my $updateto;
   my $oldclass;
   my %wfrec=(srcsys=>$selfname);
   my $app=$self->getParent();
   $wf->SetFilter({srcsys=>\$selfname,srcid=>\$rec->{problemnumber}});
   my @oldrec=$wf->getHashList("id","class","stateid","step");
   if ($#oldrec==0){
      $updateto=$oldrec[0]->{id};
      $oldclass=$oldrec[0]->{class};
   }

   $wfrec{srcid}=$rec->{problemnumber};
   $wfrec{name}=$rec->{name};
   $wfrec{detaildescription}=$rec->{description};
   $wfrec{problemsolution}=$rec->{solution};
   $wfrec{stateid}=1;
   $wfrec{stateid}=21 if (lc($rec->{status}) eq "closed");
   $wfrec{additional}={
      ServiceCenterProblemNumber=>$rec->{problemnumber},
      ServiceCenterState=>$rec->{status},
      ServiceCenterAssignedTo=>$rec->{assignedto},
      ServiceCenterTriggeredBy=>$rec->{triggeredby},
      ServiceCenterHomeAssignment=>$rec->{homeassignment},
#      ServiceCenterRisk=>$rec->{risk},
#      ServiceCenterCategory=>$rec->{category},
      ServiceCenterUrgency=>$rec->{urgency},
      ServiceCenterPriority=>$rec->{priority},
      ServiceCenterImpact=>$rec->{impact},
##      ServiceCenterRequestedBy=>$rec->{requestedby},
      ServiceCenterSysModTime=>$rec->{sysmodtime},
      ServiceCenterSoftwareID=>$rec->{softwareid},
      ServiceCenterCreator=>$rec->{creator},
#      ServiceCenterWorkEnd=>$rec->{workend},
#      ServiceCenterWorkDuration=>$rec->{workduration},
#      ServiceCenterExternChangeID=>$rec->{srcid}
   };
#   if (!($rec->{coordinator}=~m/^\s*$/)){
#      $wfrec{additional}->{ServiceCenterCoordinator}=$rec->{coordinator};
#   }
#   if (!($rec->{resources}=~m/^\s*$/)){
#      $wfrec{additional}->{ServiceCenterResources}=$rec->{resources};
#   }
   $wfrec{eventstart}=$app->ExpandTimeExpression($rec->{createtime},
                                                 "en","CET");
   $wfrec{eventend}=$app->ExpandTimeExpression($rec->{closetime},
                                                 "en","CET");
   $wfrec{mdate}=$app->ExpandTimeExpression($rec->{sysmodtime},"en","CET");
   $wfrec{createdate}=$app->ExpandTimeExpression($rec->{createtime},
                                                 "en","CET");
   $wfrec{closedate}=$app->ExpandTimeExpression($rec->{closetime},
                                                "en","CET");
   $wfrec{openuser}=undef;
   $wfrec{openusername}=undef;
   if ($rec->{creator} ne ""){
      $wfrec{openusername}="wiw/".lc($rec->{creator});
      $self->{user}->SetFilter({posix=>\$rec->{creator}});
      my $userid=$self->{user}->getVal("userid");
      $wfrec{openuser}=$userid if (defined($userid));
   }
#   if (!($rec->{closecode}=~m/^\s*$/)){
#      $wfrec{additional}->{ServiceCenterCloseCode}=$rec->{closecode};
#   }
#
#   if (lc($rec->{status}) eq "closed"){ # anpassung damit I-Network mappen kan
#      $wfrec{additional}->{State4INetwork}=$rec->{status}." ".$rec->{closecode};
#   }
#   else{
#      $wfrec{additional}->{State4INetwork}=$rec->{status};
#   }
#   $wfrec{additional}->{EventStart4INetwork}=$app->ExpandTimeExpression(
#                                        $rec->{plannedstart},"en","CET","CET");
#   $wfrec{additional}->{EventEnd4INetwork}=$app->ExpandTimeExpression(
#                                        $rec->{plannedend},"en","CET","CET");
#   $wfrec{additional}->{Type4INetwork}=$rec->{type};
#   if ($rec->{name}=~m/[^a-z]regel-ipl/i){
#      $wfrec{additional}->{Type4INetwork}="trivial";
#   }
#   # approval check for I-Network (TSM hat zugestimmt)
#   my %approver=();
#   foreach my $agrp (split(/\s/,$rec->{addgrp})){
#      my $g=trim($agrp);
#      $approver{$g}=1 if ($g ne "");
#   }
#   my @tcom=();
#   push(@tcom,grep(/^CSS\.TCOM$/,keys(%approver)));
#   push(@tcom,grep(/^CSS\.TCOM\..*$/,keys(%approver)));
#   if ($#tcom!=-1){
#      my $AlApproveCompletly=0;
#      my %approved=();
#      my $done=0;
#      if (ref($rec->{approved}) eq "ARRAY"){
#         foreach my $a (@{$rec->{approved}}){
#            foreach my $agrp (split(/\s/,$a->{name})){
##               my $g=trim($agrp);
#               $approved{$g}=1 if ($g ne "");
#               my $qg=quotemeta($g);
#               $done++ if (grep(/^$qg$/,@tcom)); 
#            }
#         }
#      }
#      $AlApproveCompletly=1 if ($#tcom+1==$done);
#      msg(DEBUG,"approver=%s",Dumper(\%approver));
#      msg(DEBUG,"approved=%s",Dumper(\%approved));
#      msg(DEBUG,"tcom=%s",Dumper(\@tcom));
#      $wfrec{additional}->{AlApproveCompletly4INetwork}=$AlApproveCompletly;
#   }
#
#
#   $wfrec{changefallback}=$rec->{fallback};
   my ($system,$systemid,
       $anames,$aids,$contrnames,$contrids,$mandator,$mandatorid,
       $costcenter,$customername,$responseteam,$businessteam,
       $truecustomerprio)=
               $self->extractAffectedApplication($rec);
   $wfrec{affectedsystemid}=$systemid;
   $wfrec{affectedsystem}=$system;
   $wfrec{affectedapplicationid}=$aids;
   $wfrec{affectedapplication}=$anames;
   $wfrec{affectedcontractid}=$contrids;
   $wfrec{affectedcontract}=$contrnames;
   $wfrec{involvedresponseteam}=$responseteam;
   $wfrec{involvedbusinessteam}=$businessteam;
   $wfrec{involvedcustomer}=$customername;
   $wfrec{involvedcostcenter}=$costcenter;
   $wfrec{mandator}=$mandator;
   $wfrec{mandatorid}=$mandatorid;
   $wfrec{class}=$oldclass;
   if (defined($updateto) && $#{$aids}!=-1 && 
       $oldclass eq "itil::workflow::problem"){
      $wf->UpdateRecord({class=>'AL_TCom::workflow::problem'},
                        {id=>$updateto});
      #printf STDERR ("WARN: class changed on id $updateto\n");
      $wfrec{class}='AL_TCom::workflow::problem';
      $oldclass='AL_TCom::workflow::problem';
   }
   if (!defined($updateto)){
      if ($#{$aids}!=-1){
         $wfrec{class}='AL_TCom::workflow::problem';
      }
      else{
         $wfrec{class}='itil::workflow::problem';
         $wfrec{stateid}=21;           # non AL-T-Com is automaticly finished
      }
   }
   if (!defined($updateto)){
      $wfrec{openuser}=undef;
      my $posix=lc($rec->{requestedby});
      $wfrec{openusername}="wiw/$posix";
      $self->{user}->ResetFilter();
      $self->{user}->SetFilter({posix=>\$posix});
      my $userid=$self->{user}->getVal("userid");
      $wfrec{openuser}=$userid if (defined($userid));
      $wfrec{step}='itil::workflow::problem::extauthority';
   }
   $wfrec{srcload}=$app->ExpandTimeExpression($rec->{sysmodtime},"en","CET");
   return(\%wfrec,$updateto);
}

sub mkChangeStoreRec
{
   my $self=shift;
   my $rec=shift;
   my $wf=shift;
   my $selfname=shift;
   my $updateto;
   my $oldclass;
   my %wfrec=(srcsys=>$selfname);
   my $app=$self->getParent();
   $wf->ResetFilter();
   $wf->SetFilter({srcsys=>\$selfname,srcid=>\$rec->{changenumber}});
   my @oldrec=$wf->getHashList("id","class","stateid","step");
   msg(DEBUG,"found on oldsearch %s",Dumper(\@oldrec));
   if ($#oldrec==0){
      $updateto=$oldrec[0]->{id};
      $oldclass=$oldrec[0]->{class};
   }

   $wfrec{srcid}=$rec->{changenumber};
   $wfrec{name}=$rec->{name};
   $wfrec{changedescription}=$rec->{description};
   #$wfrec{changedescription}=~s/^-{10}description via Interface//;
   $wfrec{stateid}=0;
   $wfrec{stateid}=1  if ($rec->{status} eq "planning");
   $wfrec{stateid}=3  if ($rec->{status} eq "reviewed");
   $wfrec{stateid}=3  if ($rec->{status} eq "released");
   $wfrec{stateid}=4  if ($rec->{status} eq "work in process");
   $wfrec{stateid}=4  if ($rec->{status} eq "work in progress");
   $wfrec{stateid}=7  if ($rec->{status} eq "confirmed");
   $wfrec{stateid}=17 if ($rec->{status} eq "resolved");
   $wfrec{stateid}=17 if ($rec->{status} eq "closed");
  # if ($wfrec{stateid}==17){
  #    if ($rec->{closecode} eq "rejected"){
  #       $wfrec{stateid}=24;
  #    }
  #    if ($rec->{closecode} eq "unsuccesfull"){
  #       $wfrec{stateid}=23;
  #    }
  # }
   $wfrec{additional}={
      ServiceCenterChangeNumber=>$rec->{changenumber},
      ServiceCenterState=>$rec->{status},
      ServiceCenterAssignedTo=>$rec->{assignedto},
      ServiceCenterRisk=>$rec->{risk},
      ServiceCenterCategory=>$rec->{category},
      ServiceCenterUrgency=>$rec->{urgency},
      ServiceCenterReason=>$rec->{reason},
      ServiceCenterType=>$rec->{type},
      ServiceCenterPriority=>$rec->{priority},
      ServiceCenterImpact=>$rec->{impact},
      ServiceCenterRequestedBy=>$rec->{requestedby},
      ServiceCenterSysModTime=>$rec->{sysmodtime},
      ServiceCenterAssignArea=>$rec->{assignarea},
      ServiceCenterSoftwareID=>$rec->{softwareid},
      ServiceCenterWorkStart=>$rec->{workstart},
      ServiceCenterWorkEnd=>$rec->{workend},
      ServiceCenterWorkDuration=>$rec->{workduration}
   };
   if ($rec->{srcid} ne ""){
      $wfrec{additional}->{ServiceCenterExternChangeID}=$rec->{srcid};
   }
   if ($wfrec{additional}->{ServiceCenterClosedBy} ne
       $rec->{closedby}){
      $wfrec{additional}->{ServiceCenterClosedBy}=$rec->{closedby};
   }
   if ($wfrec{additional}->{ServiceCenterResolvedBy} ne
       $rec->{resolvedby}){
      $wfrec{additional}->{ServiceCenterResolvedBy}=$rec->{resolvedby};
   }

   if (!($rec->{coordinator}=~m/^\s*$/)){
      $wfrec{additional}->{ServiceCenterCoordinator}=$rec->{coordinator};
   }
   if (!($rec->{resources}=~m/^\s*$/)){
      $wfrec{additional}->{ServiceCenterResources}=$rec->{resources};
   }
   $wfrec{eventstart}=$app->ExpandTimeExpression($rec->{plannedstart},
                                                 "en","CET");
   $wfrec{eventend}=$app->ExpandTimeExpression($rec->{plannedend},
                                                 "en","CET");
   $wfrec{mdate}=$app->ExpandTimeExpression($rec->{sysmodtime},"en","CET");
   $wfrec{createdate}=$app->ExpandTimeExpression($rec->{createtime},
                                                 "en","CET");
   $wfrec{closedate}=$app->ExpandTimeExpression($rec->{closetime},
                                                "en","CET");
   if (!($rec->{closecode}=~m/^\s*$/)){
      $wfrec{additional}->{ServiceCenterCloseCode}=$rec->{closecode};
   }

   if (lc($rec->{status}) eq "closed"){ # anpassung damit I-Network mappen kan
      $wfrec{additional}->{State4INetwork}=$rec->{status}." ".$rec->{closecode};
   }
   else{
      $wfrec{additional}->{State4INetwork}=$rec->{status};
   }
   $wfrec{additional}->{EventStart4INetwork}=$app->ExpandTimeExpression(
                                        $rec->{plannedstart},"en","CET","CET");
   $wfrec{additional}->{EventEnd4INetwork}=$app->ExpandTimeExpression(
                                        $rec->{plannedend},"en","CET","CET");

   #
   # ... f�r diesen Code Teil immer Markus Zeiss fragen
   #
   $wfrec{additional}->{Type4INetwork}=$rec->{type};
   if ($rec->{name}=~m/[^a-z]regel-ipl/i){
      $wfrec{additional}->{Type4INetwork}="trivial";
   }
   if (time()>1197242364){  # ca Mo. der 10.12.2007 aktiv
      if ($rec->{type}=~m/^standard$/i){
         $wfrec{additional}->{Type4INetwork}="trivial";
      }
      if ($rec->{type}=~m/^significant$/i){
         $wfrec{additional}->{Type4INetwork}="minor";
      }
      if ($rec->{urgency}=~m/^emergency$/i){
         $wfrec{additional}->{Type4INetwork}="emergency";
      }
   }


   # approval check for I-Network (TSM hat zugestimmt)
   my %approver=();
   foreach my $agrp (split(/\s/,$rec->{addgrp})){
      my $g=trim($agrp);
      $approver{$g}=1 if ($g ne "");
   }
   my @tcom=();
   push(@tcom,grep(/^CSS\.TCOM$/,keys(%approver)));
   push(@tcom,grep(/^CSS\.TCOM\..*$/,keys(%approver)));
   @tcom=grep(!/^CSS\.TCOM\.APPROVE$/,@tcom);
   @tcom=grep(!/^CSS\.TCOM\.CAB\.APPROVE$/,@tcom);
   if ($#tcom!=-1){
      my $AlApproveCompletly=0;
      my %approved=();
      my $done=0;
      if (ref($rec->{approved}) eq "ARRAY"){
         foreach my $a (@{$rec->{approved}}){
            foreach my $agrp (split(/\s/,$a->{name})){
               my $g=trim($agrp);
               $approved{$g}=1 if ($g ne "");
               my $qg=quotemeta($g);
               $done++ if (grep(/^$qg$/,@tcom)); 
            }
         }
      }
      $AlApproveCompletly=1 if ($#tcom+1==$done);
      msg(DEBUG,"approver=%s",Dumper(\%approver));
      msg(DEBUG,"approved=%s",Dumper(\%approved));
      msg(DEBUG,"tcom=%s",Dumper(\@tcom));
      $wfrec{additional}->{AlApproveCompletly4INetwork}=$AlApproveCompletly;
   }


   $wfrec{changefallback}=$rec->{fallback};
   my ($system,$systemid,
       $anames,$aids,$contrnames,$contrids,$mandator,$mandatorid,
       $costcenter,$customername,$responseteam,$businessteam,
       $truecustomerprio)=
               $self->extractAffectedApplication($rec);
   $wfrec{affectedsystemid}=$systemid;
   $wfrec{affectedsystem}=$system;
   $wfrec{affectedapplicationid}=$aids;
   $wfrec{affectedapplication}=$anames;
   $wfrec{affectedcontractid}=$contrids;
   $wfrec{affectedcontract}=$contrnames;
   $wfrec{involvedresponseteam}=$responseteam;
   $wfrec{involvedbusinessteam}=$businessteam;
   $wfrec{involvedcustomer}=$customername;
   $wfrec{involvedcostcenter}=$costcenter;
   $wfrec{mandator}=$mandator;
   $wfrec{mandatorid}=$mandatorid;
   $wfrec{truecustomerprio}=$truecustomerprio;
   $wfrec{class}=$oldclass;
   if (defined($updateto) && $#{$aids}!=-1 && 
       $oldclass eq "itil::workflow::change"){
      $wf->UpdateRecord({class=>'AL_TCom::workflow::change'},
                        {id=>$updateto});
      #printf STDERR ("WARN: class changed on id $updateto\n");
      $wfrec{class}='AL_TCom::workflow::change';
      $oldclass='AL_TCom::workflow::change';
   }
   if (!defined($updateto)){
      if ($#{$aids}!=-1){
         $wfrec{class}='AL_TCom::workflow::change';
      }
      else{
         $wfrec{class}='itil::workflow::change';
         $wfrec{stateid}=21;           # non AL-T-Com is automaticly finished
      }
   }
   if (!defined($updateto)){
      $wfrec{openuser}=undef;
      my $posix=lc($rec->{requestedby});
      $wfrec{openusername}="wiw/$posix";
      $self->{user}->ResetFilter();
      $self->{user}->SetFilter({posix=>\$posix});
      my $userid=$self->{user}->getVal("userid");
      if (defined($userid)){
         $wfrec{openuser}=$userid;
         $wfrec{openusername}="wiw/$posix";
      }
      $wfrec{step}='itil::workflow::change::extauthority';
   }
   if (!($oldrec[0]->{step}=~m/::postreflection$/) &&
       $wfrec{class}=~m/^AL_TCom::/){
       if ($rec->{srcid} ne "" && ($rec->{srcid}=~m/^IN:/)){
          my $srcid=$rec->{srcid};
          $srcid=~s/^IN://i;
          $wfrec{tcomexternalid}=$srcid;
       }
       my $ws=$app->ExpandTimeExpression($rec->{workstart},"en","CET");
       my $we=$app->ExpandTimeExpression($rec->{workend},"en","CET");
       my $wt=0;
       if ((my ($wsY,$wsM,$wsD,$wsh,$wsm,$wss)=$ws=~
              m/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/) &&
           (my ($weY,$weM,$weD,$weh,$wem,$wes)=$we=~
              m/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/)){
          my ($dd,$dh,$dm,$ds);
          eval('($dd,$dh,$dm,$ds)=Delta_DHMS("CET",
                                             $wsY,$wsM,$wsD,$wsh,$wsm,$wss,
                                             $weY,$weM,$weD,$weh,$wem,$wes);
               ');
          if (defined($dd) && defined($dh) && defined($dm)){
             $wt=$dd*24*60+$dh*60+$dm;
          }
       }
       if ($#{$aids}!=-1){ 
          $wfrec{tcomcodrelevant}="yes";
       }
       else{
          $wfrec{tcomcodrelevant}="no";
       }
       #$wfrec{tcomcodcontract}=join(", ",@{$wfrec{affectedcontract}});
       $wfrec{tcomcodcause}="undef";
       $wfrec{tcomcodchmrisk}=$rec->{risk};
       if ($wfrec{tcomcodchmrisk} eq "" || $wfrec{tcomcodchmrisk} eq "0"){
          msg(ERROR,"no tcomcodchmrisk in Changenumber '$rec->{changenumber}'");
       }
       $wfrec{tcomcoddownstart}=$ws;
       $wfrec{tcomcoddownend}=$we;
       $wfrec{tcomworktime}=$wt;
       if ($rec->{tssc_chm_closingcommentsclosingcomments} ne ""){
          $wfrec{tcomcodcomments}=
                  $rec->{tssc_chm_closingcommentsclosingcomments};
       }
       if (lc($rec->{reason}) ne "cus"){
          $wfrec{tcomcodcause}="appl.base.base";
       }
   }
   $wfrec{srcload}=$app->ExpandTimeExpression($rec->{sysmodtime},"en","CET");
   return(\%wfrec,$updateto);
}

sub extractAffectedApplication
{
   my $self=shift;
   my $rec=shift;
   my @mandator=();
   my @mandatorid=();
   my @system=();
   my @systemid=();
   my %system=();
   my %systemid=();
   my @custcontract=();
   my @custcontractid=();
   my @applna=();
   my @applid=();
   my @costcenter=();
   my @responseteam=();
   my @businessteam=();
   my @customername=();
   my %costcenter=();
   my %responseteam=();
   my %businessteam=();
   my %customername=();
   my $truecustomerprio;


   my @chkapplid;
   #  pass 1 : softwareid
   my @l1;
   if (defined($rec->{softwareid})){
      @l1=split(/[,\s;]+/,$rec->{softwareid});
   }

   if (defined($rec->{custapplication})){
      push(@l1,split(/[,\s;]+/,$rec->{custapplication}));
   }



   #  pass 2 : description
   my @l2;
   if (defined($rec->{device}) && ref($rec->{device}) eq "ARRAY"){
      foreach my $r (@{$rec->{device}}){
         if (my ($applid)=$r->{name}=~m/^.*\(((APPL|GER)\d+)\)$/){
            push(@chkapplid,$applid);
         }
      }
   }

   # entfernung des Parsings auf Basis des Requests ...
   # https://darwin.telekom.de/darwin/auth/base/workflow/ById/12428113140002
   #
   #if (defined($rec->{description})){
   #   my ($workdescription)=$rec->{description};
   #   while(my ($line)=$workdescription=~m/^(.*?)[\n]/){
   #      $workdescription=~s/^(.*?)[\n]//;
   #      last if (!($line=~m/^AG[: ]+/) && $#l2==-1);
   #      $line=~s/^AG[: ]+//;
   #      last if ($line=~m/^\s*$/);
   #      push(@l2,split(/[,\s;]+/,$line));
   #      last if (!($line=~m/[,;]\s*$/));
   #   }
   #   if (my ($aglist)=$rec->{description}=~
   #          m/^.*\[AGLIST_START\](.*)\[AGLIST_END\].*$/sm){
   #      $aglist=~s/[\n\r]/ /g;
   #      $aglist=~s/^\s*//g;
   #      $aglist=~s/\s*$//g;
   #      msg(DEBUG,"add AGLIST='%s' by Interface descrition",$aglist);
   #      push(@l2,split(/[,\s;]+/,$aglist));
   #   }
   #}

   #   pass 3 : affacted Softare
   my @l3;
   if (defined($rec->{software})){
      if (ref($rec->{software} eq "ARRAY")){
         map({$_->{name}} @{$rec->{software}});
      }
   }

   #  pass 4 : make all unique with ignoring case
   my %u=();
   map({$u{lc($_)}=$_;} @l1,@l2,@l3);
   my @applna=grep(!/^\s*$/,sort(values(%u)));
   my @applna=grep(!/\>/,@applna);
   my @applna=grep(!/\</,@applna);
   my @applna=grep(!/!/,@applna);
   my @applna=grep(!/\*/,@applna);
   my @applna=grep(!/\?/,@applna);
   my @applna=grep(!/^\s*$/,@applna);
   msg(DEBUG,"validate aglist=%s",join(",",@applna));


   #  pass 5 : validate against W5Base
   my $appl=$self->getPersistentModuleObject("W5BaseAppl","itil::appl");
   my @l;
   if ($#applna!=-1){
      my $flt=join(" ",map({'"'.$_.'"'} @applna));
      $appl->ResetFilter();
      $appl->SetFilter({name=>$flt});
      @l=$appl->getHashList(qw(id name custcontracts customerprio
                               mandator mandatorid customer 
                               businessteam responseteam conumber));
      @applid=sort(map({$_->{id}} @l));
      @applna=sort(map({$_->{name}} @l));
      map({ if (defined($_->{customerprio}) && $_->{customerprio}>0){
               if (!defined($truecustomerprio) || 
                   $truecustomerprio>$_->{customerprio}){
                  $truecustomerprio=$_->{customerprio};
               }
            }
          } @l);
   }
   my $novalidappl=0;
   $novalidappl=1 if ($#applid==-1);
   my $dev=$rec->{deviceid};
   if (my ($applid)=$dev=~m/^.*\(((APPL|GER)\d+)\)$/){
      msg(DEBUG,"ApplicationID=%s",$applid);
      push(@chkapplid,$applid);
   }
   if ($#chkapplid!=-1){
      $appl->ResetFilter();
      $appl->SetFilter({applid=>\@chkapplid});
      my @l1=$appl->getHashList(qw(id name custcontracts 
                               mandator mandatorid customer 
                               businessteam responseteam conumber));
      if ($#l1!=-1){
         push(@l,@l1);
         foreach my $arec (@l1){
            push(@applid,$arec->{id}) if (!grep(/^$arec->{id}$/,@applid));
            my $qn=quotemeta($arec->{name});
            push(@applna,$arec->{name}) if (!grep(/^$qn$/,@applna));
       
         }
      }
   }
   else{
      my @dev=split(/[,;\s]+/,$dev);
      my @dev=grep(!/\</,@dev);
      my @dev=grep(!/\>/,@dev);
      my @dev=grep(!/!/,@dev);
      my @dev=grep(!/\*/,@dev);
      my @dev=grep(!/\?/,@dev);
      my @dev=grep(!/^\s*$/,@dev);
      if ($#dev!=-1){
         my $sys=$self->getPersistentModuleObject("W5BaseSys",
                                                  "itil::system");
         $sys->SetFilter([{name=>\@dev},{systemid=>\@dev}]);
         my @sl=$sys->getHashList(qw(id name applications)); 
         my %applid=();
         my %applna=();
         foreach my $s (@sl){
            $system{$s->{name}}=1;
            $systemid{$s->{id}}=1;
            if ($novalidappl){
               if (ref($s->{applications}) eq "ARRAY"){
                  foreach my $a (@{$s->{applications}}){
                     if ($a->{appl} ne "" && $a->{applid} ne "" &&
                         $a->{applcistatusid}<=4){
                        $applid{$a->{applid}}=1; 
                        $applna{$a->{appl}}=1; 
                     }
                  }
               }
            }
         }
         if ($novalidappl){
            @applid=sort(keys(%applid));
            @applna=sort(keys(%applna));
            $appl->SetFilter({id=>\@applid}); # reread the application table
            @l=$appl->getHashList(qw(id name custcontracts customer 
                                     businessteam responseteam conumber
                                     mandator mandatorid));
         }
      }
   }
   my %mandator=();
   my %mandatorid=();
   my %custcontractid=();
   my %custcontract=();
   foreach my $rec (@l){
      if (ref($rec->{custcontracts}) eq "ARRAY"){
         foreach my $contr (@{$rec->{custcontracts}}){
            $custcontractid{$contr->{custcontractid}}=1;
            $custcontract{$contr->{custcontract}}=1;
         }
      }
      if ($rec->{mandator} ne ""){
         $mandator{$rec->{mandator}}=1;
      }
      if ($rec->{mandatorid} ne ""){
         $mandatorid{$rec->{mandatorid}}=1;
      }
      $costcenter{$rec->{conumber}}=1;
      $customername{$rec->{customer}}=1;
      $responseteam{$rec->{responseteam}}=1;
      $businessteam{$rec->{businessteam}}=1;
   }
   @custcontract=sort(keys(%custcontract));
   @custcontractid=sort(keys(%custcontractid));
   @mandator=sort(keys(%mandator));
   @mandatorid=sort(keys(%mandatorid));
   @costcenter=grep(!/^\s*$/,sort(keys(%costcenter)));
   @customername=grep(!/^\s*$/,sort(keys(%customername)));
   @responseteam=grep(!/^\s*$/,sort(keys(%responseteam)));
   @businessteam=grep(!/^\s*$/,sort(keys(%businessteam)));
   @system=grep(!/^\s*$/,sort(keys(%system)));
   @systemid=grep(!/^\s*$/,sort(keys(%systemid)));

   if ($#mandatorid==-1){
      @mandatorid=(-99);
      @mandator=("none");
   }
   msg(DEBUG,"result aglist  =%s",join(",",@applna));
   msg(DEBUG,"result mandator=%s",join(",",@mandator));
   

   # $rec->{softwareid}
   # $rec->{software} =>array
   # $rec->{description} 


   return(\@system,\@systemid,\@applna,\@applid,
          \@custcontract,\@custcontractid,
          \@mandator,\@mandatorid,\@costcenter,\@customername,
          \@responseteam,\@businessteam,$truecustomerprio);
}


sub mkIncidentStoreRec
{
   my $self=shift;
   my $rec=shift;
   my $wf=shift;
   my $selfname=shift;
   my $updateto;
   my $oldclass;
   my %wfrec=(srcsys=>$selfname);
   my $app=$self->getParent();
   $wf->SetFilter({srcsys=>\$selfname,srcid=>\$rec->{incidentnumber}});
   my @oldrec=$wf->getHashList("id","class","step");
   if ($#oldrec==0){
      $updateto=$oldrec[0]->{id};
      $oldclass=$oldrec[0]->{class};
   }

   $wfrec{srcid}=$rec->{incidentnumber};
   $wfrec{name}=$rec->{name};
   $wfrec{incidentdescription}=$rec->{action};
   $wfrec{incidentresolution}=$rec->{resolution};
   $wfrec{stateid}=1;
   $wfrec{stateid}=17 if ($rec->{status} eq "closed");
   $wfrec{additional}={
      ServiceCenterIncidentNumber=>$rec->{incidentnumber},
      ServiceCenterState=>$rec->{status},
      ServiceCenterReason=>$rec->{reason},
      ServiceCenterPriority=>$rec->{priority},
      ServiceCenterHomeAssignment=>$rec->{hassignment},
      ServiceCenterInitialAssignment=>$rec->{iassignment},
      ServiceCenterResolvedAssignment=>$rec->{rassignment},
      ServiceCenterSysModTime=>$rec->{sysmodtime},
      ServiceCenterInvolvedAssignment=>$rec->{involvedassignment},
      ServiceCenterSoftwareID=>$rec->{softwareid},
      ServiceCenterDowntimeStart=>$rec->{downtimestart},
      ServiceCenterDowntimeEnd=>$rec->{downtimeend},
   };
   if (!($rec->{deviceid}=~m/^\s*$/)){
      $wfrec{additional}->{ServiceCenterDeviceID}=$rec->{deviceid};
   }
   if (!($rec->{causecode}=~m/^\s*$/)){
      $wfrec{additional}->{ServiceCenterCauseCode}=$rec->{causecode};
   }
   if (!($rec->{workstart}=~m/^\s*$/)){
      $wfrec{additional}->{ServiceCenterWorkStart}=$rec->{workstart};
   }
   if (!($rec->{workend}=~m/^\s*$/)){
      $wfrec{additional}->{ServiceCenterWorkEnd}=$rec->{workend};
   }
   $wfrec{eventstart}=$app->ExpandTimeExpression($rec->{downtimestart},"en","CET");
   my $downtimeend=$rec->{downtimeend};
   $downtimeend=$rec->{downtimestart} if (!defined($downtimeend) ||
                                          $downtimeend eq "");
   $wfrec{eventend}=$app->ExpandTimeExpression($downtimeend,"en","CET");
   $wfrec{mdate}=$app->ExpandTimeExpression($rec->{sysmodtime},"en","CET");
   $wfrec{createdate}=$app->ExpandTimeExpression($rec->{opentime},"en","CET");
   $wfrec{closedate}=$app->ExpandTimeExpression($rec->{closetime},"en","CET");
   #$rec->{softwareid}="CMDB" if ($rec->{incidentnumber} eq "GER03733409");

   $wfrec{openuser}=undef;
   $wfrec{openusername}=undef;
   if ($rec->{reportedby} ne ""){
      $wfrec{openusername}="wiw/".lc($rec->{reportedby});
      $self->{user}->SetFilter({posix=>\$rec->{reportedby}});
      my $userid=$self->{user}->getVal("userid");
      $wfrec{openuser}=$userid if (defined($userid));
   }

   my ($system,$systemid,
       $anames,$aids,$contrnames,$contrids,$mandator,$mandatorid,
       $costcenter,$customername,$responseteam,$businessteam)=
                        $self->extractAffectedApplication($rec);
   $wfrec{affectedsystemid}=$systemid;
   $wfrec{affectedsystem}=$system;
   $wfrec{affectedapplicationid}=$aids;
   $wfrec{affectedapplication}=$anames;
   $wfrec{affectedcontractid}=$contrids;
   $wfrec{affectedcontract}=$contrnames;
   $wfrec{involvedresponseteam}=$responseteam;
   $wfrec{involvedbusinessteam}=$businessteam;
   $wfrec{involvedcustomer}=$customername;
   $wfrec{involvedcostcenter}=$costcenter;
   $wfrec{mandator}=$mandator;
   $wfrec{mandatorid}=$mandatorid;

   if (defined($updateto) && $#{$aids}!=-1 &&
       $oldclass eq "itil::workflow::incident"){
      $wf->UpdateRecord({class=>'AL_TCom::workflow::incident'},
                        {id=>$updateto});
      #printf STDERR ("WARN: class incidentd on id $updateto\n");
      $oldclass='AL_TCom::workflow::incident';
   }
   if (!defined($updateto)){
      if ($#{$aids}!=-1){
         $wfrec{class}='AL_TCom::workflow::incident';
      }
      else{
         $wfrec{class}='itil::workflow::incident';
      }
      $wfrec{step}='itil::workflow::incident::extauthority';
   }
   if ($oldclass eq "itil::workflow::incident" ||
       (defined($wfrec{class}) && 
        ($wfrec{class}=~m/itil::workflow::incident/))){
      $wfrec{stateid}=21;           # non AL-T-Com is automaticly finished
      # sollte jetzt auch mit sofort beenden funktionieren
   }
   if (!defined($oldrec[0]) || !($oldrec[0]->{step}=~m/::postreflection$/)){
       my $ws=$app->ExpandTimeExpression($rec->{workstart},"en","CET");
       my $we=$app->ExpandTimeExpression($rec->{workend},"en","CET");
       my $wt=0;
       if ((my ($wsY,$wsM,$wsD,$wsh,$wsm,$wss)=$ws=~
              m/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/) &&
           (my ($weY,$weM,$weD,$weh,$wem,$wes)=$we=~
              m/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/)){
          my ($dd,$dh,$dm,$ds);
          eval('($dd,$dh,$dm,$ds)=Delta_DHMS("CET",$wsY,$wsM,$wsD,$wsh,$wsm,$wss,
                                             $weY,$weM,$weD,$weh,$wem,$wes);
               ');
          if (defined($dd) && defined($dh) && defined($dm)){
             $wt=$dd*24*60+$dh*60+$dm;
          }
       }
       if ($#{$aids}!=-1){ 
          $wfrec{tcomcodrelevant}="yes";
       }
       else{
          $wfrec{tcomcodrelevant}="no";
       }
       $wfrec{tcomcodcause}="appl.base.base";
       $wfrec{tcomworktime}=$wt;
       if ($rec->{resolution} ne ""){
          $wfrec{tcomcodcomments}=$rec->{resolution};
       }
   }

   $wfrec{srcload}=$app->ExpandTimeExpression($rec->{closetime},"en","CET");
   return(\%wfrec,$updateto);
}




1;
