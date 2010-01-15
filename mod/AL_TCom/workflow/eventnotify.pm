package AL_TCom::workflow::eventnotify;
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
use kernel::WfClass;
use itil::workflow::eventnotify;
use Text::Wrap qw($columns &wrap);

@ISA=qw(itil::workflow::eventnotify);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my $class;

   return($self->InitFields(
      $self->SUPER::getDynamicFields(@_),

      new kernel::Field::Text(
                name          =>'eventprmticket',
                xlswidth      =>'15',
                translation   =>'AL_TCom::workflow::eventnotify',
                group         =>'eventnotifyinternal',
                label         =>'related problem ticket',
                container     =>'headref'),

      new kernel::Field::Text(
                name          =>'eventinmticket',
                xlswidth      =>'15',
                translation   =>'AL_TCom::workflow::eventnotify',
                group         =>'eventnotifyinternal',
                label         =>'related incident ticket',
                container     =>'headref'),

      new kernel::Field::Htmlarea(
                name          =>'eventinmrelations',
                translation   =>'AL_TCom::workflow::eventnotify',
                group         =>'eventnotifyinternal',
                label         =>'ServiceCenter event relations',
                htmldetail    =>0,
                searchable    =>0,
                readonly      =>1,
                delend        =>['eventinmticket'],
                onRawValue    =>\&calcSCrelations),

      new kernel::Field::Number(
                name          =>'eventkpistart2firstinfo',
                translation   =>'AL_TCom::workflow::eventnotify',
                group         =>'eventnotifyinternal',
                label         =>'KPI latency eventstart to first info',
                htmldetail    =>0,
                searchable    =>0,
                readonly      =>1,
                delend        =>['eventstart','shortactionlog'],
                onRawValue    =>\&calcKPIs),

      new kernel::Field::Number(
                name          =>'eventkpimintimefollowup',
                translation   =>'AL_TCom::workflow::eventnotify',
                group         =>'eventnotifyinternal',
                label         =>'KPI minimal time between followup infos',
                htmldetail    =>0,
                searchable    =>0,
                readonly      =>1,
                unit          =>'min',
                delend        =>['shortactionlog'],
                onRawValue    =>\&calcKPIs),

      new kernel::Field::Number(
                name          =>'eventkpimaxtimefollowup',
                translation   =>'AL_TCom::workflow::eventnotify',
                group         =>'eventnotifyinternal',
                label         =>'KPI max time between followup infos',
                htmldetail    =>0,
                searchable    =>0,
                readonly      =>1,
                unit          =>'min',
                delend        =>['shortactionlog'],
                onRawValue    =>\&calcKPIs),

      new kernel::Field::Number(
                name          =>'eventkpiavgtimefollowup',
                translation   =>'AL_TCom::workflow::eventnotify',
                group         =>'eventnotifyinternal',
                label         =>'KPI avg time between followup infos',
                htmldetail    =>0,
                searchable    =>0,
                readonly      =>1,
                unit          =>'min',
                delend        =>['shortactionlog'],
                onRawValue    =>\&calcKPIs),

      new kernel::Field::Number(
                name          =>'eventkpieventend2lastinfo',
                translation   =>'AL_TCom::workflow::eventnotify',
                group         =>'eventnotifyinternal',
                label         =>'KPI latency eventend to first info',
                htmldetail    =>0,
                searchable    =>0,
                readonly      =>1,
                unit          =>'min',
                delend        =>['eventend','shortactionlog'],
                onRawValue    =>\&calcKPIs),

      new kernel::Field::Text(
                name          =>'eventchmticket',
                xlswidth      =>'15',
                translation   =>'AL_TCom::workflow::eventnotify',
                group         =>'eventnotifyinternal',
                label         =>'event initiating change number',
                container     =>'headref'),


      new kernel::Field::Textarea(
                name          =>'eventscproblemcause',
                translation   =>'AL_TCom::workflow::eventnotify',
                onRawValue    =>\&loadDataFromSC,
                group         =>'eventnotifyinternal',
                readonly      =>1,
                htmldetail    =>\&isSCproblemSet,
                depend        =>['eventprmticket'],
                label         =>'SC Problem cause'),
      new kernel::Field::Textarea(
                name          =>'eventscproblemsolution',
                translation   =>'AL_TCom::workflow::eventnotify',
                group         =>'eventnotifyinternal',
                depend        =>['eventprmticket'],
                readonly      =>1,
                htmldetail    =>\&isSCproblemSet,
                onRawValue    =>\&loadDataFromSC,
                label         =>'SC Problem soultion'),
      ));

}




sub isSCproblemSet
{
   my $self=shift;
   my $mode=shift;
   my %param=@_;
   my $current=$param{current};
   return(1) if ($current->{eventprmticket} ne "");
   return(0);
}


sub getNotificationSkinbase
{
   my $self=shift;
   my $WfRec=shift;
   return('AL_TCom');
}




sub calcKPIs
{
   my $self=shift;
   my $current=shift;

   
   my $al=$self->getParent->getField("shortactionlog")->RawValue($current);

   my @tl;
   if (ref($al) eq "ARRAY"){
      foreach my $act (@$al){
         if ($act->{name} eq "sendcustinfo"){
            push(@tl,$act->{cdate});
         }
      }
   }
   if ($self->Name() eq "eventkpistart2firstinfo" && $#tl>=0){
      my $start=$self->getParent->getField("eventstart")->RawValue($current);
      my $d=CalcDateDuration($start,$tl[0]);
      my $m=$d->{totalminutes};
      return(0) if ($m<1);
      return($m);
   }
   elsif ($self->Name() eq "eventkpieventend2lastinfo" && $#tl>0){
      my $end=$self->getParent->getField("eventend")->RawValue($current);
      if ($end ne ""){
         my $d=CalcDateDuration($end,$tl[$#tl]);
         my $m=$d->{totalminutes};
         return($m);
      }
   }
   elsif ($#tl>1){
      my $min;
      my $max;
      my $avg;
      for(my $fn=0;$fn<$#tl;$fn++){
         my $t1=$tl[$fn];
         my $t2=$tl[$fn+1];
         my $d=CalcDateDuration($t1,$t2);
         my $m=$d->{totalminutes};
         if (!defined($min) || $min>$m){
            $min=$m;
         }
         if (!defined($max) || $max<$m){
            $max=$m;
         }
         if ($m!=0){
            $avg=($avg+$m)/2;
         }
      }
      if ($self->Name() eq "eventkpimintimefollowup"){
         return($min);
      }
      if ($self->Name() eq "eventkpiavgtimefollowup"){
         return($avg);
      }
      if ($self->Name() eq "eventkpimaxtimefollowup"){
         return($max);
      }
   }
   return(undef);
}


sub calcSCrelations
{
   my $self=shift;
   my $current=shift;
   my $inm=$self->getParent->getField("eventinmticket")->RawValue($current);
   my $sclnk=getModuleObject($self->getParent->Config,"tssc::lnk");
   my $d;
   my @treelist;
   if ($inm ne ""){
      my %chk;
      my @path;
      $d.=$self->getParent->calcSCrelationsSubTree($sclnk,\%chk,\@treelist,
                                                   \@path,
                                                   0,0,0,$inm,'tssc::inm');
   }
   my $raw=join("\n",map({join(",",@$_)} @treelist));
   return({treelist=>\@treelist,RawValue=>$raw,
           HtmlV01=>"<pre>$d</pre>"});
}

sub calcSCrelationsSubTree
{
   my $self=shift;
   my $sclnk=shift;
   my $chk=shift;
   my $treelist=shift;
   my $path=shift;
   my $level=shift;
   my $uplaypos=shift;
   my $uplaymax=shift;
   my $id=shift;
   my $idobj=shift;
   my $d;
   return($d."...") if ($level>10);
   return("") if (exists($chk->{$id}));

   my $off=$level*10;
   my $offtd;
   my $state="unknown";
   if ($idobj ne ""){
      my $idfield;
      $idfield="problemnumber"   if ($idobj eq "tssc::prm");
      $idfield="changenumber"    if ($idobj eq "tssc::chm");
      $idfield="incidentnumber"  if ($idobj eq "tssc::inm");
      if (defined($idfield)){
         my $o=getModuleObject($self->Config,$idobj);
         if (defined($o)){
            $o->SetFilter({$idfield=>\$id});
            my ($r,$msg)=$o->getOnlyFirst(qw(status description));
            if (defined($r)){
               $state=lc($r->{status});
            }
         }
      }
      if ($state eq "closed"){
         $state="<font color=green>$state</font>";
      }
      else{
         $state="<font color=red>$state</font>";
      }
   }
   return() if ($level>2);
   
   $offtd="<td width=$off></td>" if ($off>0);
   $d.="\n<table border=0 cellspacing=0 cellpadding=0 width=100%>".
       "<tr>$offtd<td>$id ($state)</td></tr>\n"; 
   $chk->{$id}++;
   $sclnk->ResetFilter();
   if ($level==0){
      $sclnk->SetFilter({src=>\$id,dst=>"PRM*"});
   }
   if ($level>0){
      $sclnk->SetFilter({src=>\$id,dst=>"CHM*"});
   }
   my @rel=$sclnk->getHashList(qw(dst dstobj));
   if ($level==0){
      my @subprm;
      foreach my $prm (@rel){
         push(@subprm,$prm->{dst}) if ($prm->{dst}=~m/^PRM/);
      }
      if ($#subprm!=-1){
         $sclnk->SetFilter({src=>\@subprm,dst=>"PRM*"});
         my @subrel=$sclnk->getHashList(qw(dst dstobj));
         if ($#subrel!=-1){
            push(@rel,@subrel);
         }
      }
   }
   for(my $laypos=0;$laypos<=$#rel;$laypos++){
      push(@$path,$id);
      my $s=$self->calcSCrelationsSubTree($sclnk,$chk,$treelist,$path,
                                          $level+1,$laypos,$#rel,
                                          $rel[$laypos]->{dst},
                                          $rel[$laypos]->{dstobj});
      pop(@$path);
      if ($s ne ""){
         $d.="<tr>$offtd<td>".$s."</td></tr>\n";
      }
   }
   if ($#rel==-1){
      my @l=(@$path,$id);
      push(@$treelist,\@l);
   }
   $d.="</table>";
   return($d);
}



sub loadDataFromSC
{
   my $self=shift;
   my $current=shift;

   my $reffld=$self->getParent->getField("eventprmticket",$current);
   return(undef) if (!defined($reffld));
   my $prmid=$reffld->RawValue($current);
   return(undef) if (!defined($prmid) || $prmid eq "");
   my $scprm=getModuleObject($self->getParent->Config,"tssc::prm");
   if (defined($scprm)){
      $scprm->SetFilter({problemnumber=>\$prmid});
      my ($prmrec,$msg)=$scprm->getOnlyFirst(qw(cause solution));
      if (defined($prmrec)){ 
         if ($self->Name eq "eventscproblemcause"){
            return($prmrec->{cause});
         }
         if ($self->Name eq "eventscproblemsolution"){
            return($prmrec->{solution});
         }
      }
   }
   
   return(undef);

}


sub getNotifyDestinations
{
   my $self=shift;
   my $mode=shift;    # "custinfo" | "mgmtinfo"
   my $WfRec=shift;
   my $emailto=shift;

   if ($mode eq "rootcausei"){
      my $ia=getModuleObject($self->Config,"base::infoabo");
      if ($WfRec->{eventmode} eq "EVk.infraloc"){
         my $locid=$WfRec->{affectedlocationid};
         $locid=[$locid] if (ref($locid) ne "ARRAY");
         $ia->LoadTargets($emailto,'base::location',\'rootcauseinfo',
                                   $locid);
      }
      if ($WfRec->{eventmode} eq "EVk.net"){
         my $netid=$WfRec->{affectednetworkid};
         $netid=[$netid] if (ref($netid) ne "ARRAY");
         $ia->LoadTargets($emailto,'*::network',\'rootcauseinfo',
                                   $netid);
      }
      if ($WfRec->{eventmode} eq "EVk.appl"){
         my $applid=$WfRec->{affectedapplicationid};
         $applid=[$applid] if (ref($applid) ne "ARRAY");
         my $appl=getModuleObject($self->Config,"itil::appl");
         $appl->SetFilter({id=>$applid});
         my %allcustgrp;
         foreach my $rec ($appl->getHashList(qw( customerid))){
            if ($rec->{customerid}!=0){
               $self->getParent->LoadGroups(\%allcustgrp,"up",
                                            $rec->{customerid});
            }
         }
         if (keys(%allcustgrp)){
            $ia->LoadTargets($emailto,'base::grp',\'rootcauseinfo',
                                      [keys(%allcustgrp)]);
         }
         $ia->LoadTargets($emailto,'*::appl *::custappl',\'rootcauseinfo',
                                   $applid);
      }
   }
   return($self->SUPER::getNotifyDestinations($mode,$WfRec,$emailto));
}

sub IsModuleSelectable
{
   my $self=shift;
   my $acl;

   $acl=$self->getParent->getMenuAcl($ENV{REMOTE_USER},
                          "base::workflow",
                          func=>'New',
                          param=>'WorkflowClass=AL_TCom::workflow::eventnotify');
   if (defined($acl)){
      return(1) if (grep(/^read$/,@$acl));
   }
   return(1) if ($self->getParent->IsMemberOf("admin"));
   return(0);
}

sub activateMailSend
{
   my $self=shift;
   my $WfRec=shift;
   my $wf=shift;
   my $id=shift;
   my $newmailrec=shift;
   my $action=shift;

   my %d=(step=>'base::workflow::mailsend::waitforspool',
          emailsignatur=>'EventNotification: AL DTAG');
   $self->linkMail($WfRec->{id},$id);
   if (my $r=$wf->Store($id,%d)){
      return(1);
   }
   return(0);
}

sub ValidateCreate
{
   my $self=shift;
   my $newrec=shift;

  #
  # laut Tino soll nun auch Extern und DSS zugelassen werden
  #
   if (!defined($newrec->{mandator}) ||    
       ref($newrec->{mandator}) ne "ARRAY" ||
       !grep(/^(Extern|AL DTAG|DSS)$/,@{$newrec->{mandator}})){
      $self->LastMsg(ERROR,"no AL DTAG, Extern or DSS mandator included");
      return(0);
   }
        
   return(1);
}

sub getPosibleEventStatType
{
   my $self=shift;
   my @l;
   
   foreach my $int ('',
                    qw(EVt.iswtsi EVt.iswext EVt.wrkerr 
                       EVt.wrkerrito EVt.wrkerr3ito EVt.wrkerr3thome
                       EVt.dqual EVt.stdswbug EVt.stdswold 
                       EVt.hwfail EVt.busoverflow EVt.tecoverflow
                       EVt.parammod EVt.rzinfra EVt.hitnet EVt.inanalyse
                       EVt.unknown)){
      push(@l,$int,$self->getParent->T($int));
   }
   
   return(@l);
}

sub generateMailSet
{
   my $self=shift;
   my $WfRec=shift;
   my ($action,$eventlang,$additional,$emailprefix,$emailpostfix,
       $emailtext,$emailsep,$emailsubheader,$emailsubtitle,
       $subject,$allowsms,$smstext)=@_;
   my @emailprefix=();
   my @emailpostfix=();
   my @emailtext=();
   my @emailsep=();
   my @emailsubheader=();
   my @emailsubtitle=();

   $$allowsms=0;
   $$smstext="\n";
   if ($action ne "rootcausei"){
      return($self->SUPER::generateMailSet($WfRec,@_));
   }



   my $baseurl;
   if ($ENV{SCRIPT_URI} ne ""){
      $baseurl=$ENV{SCRIPT_URI};
      $baseurl=~s#/auth/.*$##;
   }
   my @baseset=qw(wffields.eventstartofevent 
                  wffields.eventendofevent
                  wffields.eventstatclass );
   # wffields.eventstatnature deleted w5baseid: 12039307490008 
   push(@baseset,qw(wffields.affectedregion));
   if ($WfRec->{eventmode} eq "EVk.appl"){
      push(@baseset,"affectedapplication");
      push(@baseset,"wffields.affectedcustomer");
   }
   my @sets=([@baseset,qw(
                          wffields.eventimpact
                          wffields.eventreason
                          wffields.shorteventelimination
                         )],
             [@baseset,qw(
                          wffields.eventaltimpact
                          wffields.eventaltreason 
                          wffields.altshorteventelimination
                         )]);
   if ($action eq "rootcausei"){
      @sets=([@baseset,qw(wffields.eventimpact wffields.eventscproblemcause 
                          wffields.eventscproblemsolution)],
             [@baseset,qw(wffields.eventimpact wffields.eventscproblemcause 
                          wffields.eventscproblemsolution)]);
   }
   my @eventlanglist=split(/-/,$$eventlang);
   for(my $langno=0;$langno<=$#eventlanglist;$langno++){
      my $lang=$eventlanglist[$langno];
      my $line=0;
      my $mailsep=0;
      $mailsep="$lang:" if ($#emailsep!=-1); 
      $ENV{HTTP_FORCE_LANGUAGE}=$lang;
     
      my @fields=@{shift(@sets)};
     
      foreach my $field (@fields){
         my $fo=$self->getField($field,$WfRec);
         my $sh=0;
         $sh=" " if ($field eq "wffields.eventaltdesciption" ||
                     $field eq "wffields.eventdesciption");
         if (defined($fo)){
            my $v=$fo->FormatedResult($WfRec,"HtmlMail");
            if($field eq "wffields.eventendexpected" && $v eq ""){
               $v=" ";
            }
            if ($v ne ""){
               push(@emailpostfix,"");
               my $data=$v;
               $data=~s/</&lt;/g;
               $data=~s/>/&gt;/g;
               #$columns="50";
               #$data=wrap("","",$data);
     
               push(@emailtext,$data);
               push(@emailsubheader,$sh);
               push(@emailsep,$mailsep);
               push(@emailprefix,$fo->Label().":");
               push(@emailsubtitle,"");
               $line++;
               $mailsep=0;
            }
        }
      }
      my $wf=$self->getParent();
      my $ssfld=$wf->getField("wffields.eventstaticmailsubject",$WfRec);
      if (defined($ssfld)){
         my $sstext=$ssfld->RawValue($WfRec);
         if ($sstext ne ""){
            $$subject=$sstext;
         }
      }
   }
   delete($ENV{HTTP_FORCE_LANGUAGE});
   @$emailprefix=@emailprefix;
   @$emailpostfix=@emailpostfix;
   @$emailtext=@emailtext;
   @$emailsep=@emailsep;
   @$emailsubheader=@emailsubheader;
   @$emailsubtitle=@emailsubtitle;
}

sub getPosibleRelations
{
   my $self=shift;
   my $WfRec=shift;
   return("AL_TCom::workflow::eventnotify"=>'relprobtick',
          $self->SUPER::getPosibleRelations($WfRec));
}

sub getAdditionalMainButtons
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $d="";

   my @buttons=('rootcausei'=>$self->T("Send Root-Cause Info"),
                'startwarum'=>$self->T("Start a WARUM analaysis"));

   while(my $name=shift(@buttons)){
      my $label=shift(@buttons);
      my $dis="";
      $dis="disabled" if (!$self->ValidActionCheck(0,$actions,$name));
      $d.="<input type=submit $dis ".
          "class=workflowbutton name=$name value=\"$label\"><br>";
   }
   return($d);
}

sub getPosibleActions
{
   my $self=shift;
   my $WfRec=shift;
   my $app=$self->getParent;
   my $userid=$self->getParent->getCurrentUserId();
   my @l;

   if ($WfRec->{stateid}==17){
      if ($self->IsIncidentManager($WfRec) || 
          $self->getParent->IsMemberOf(["admin","admin.workflow"])){
         push(@l,"rootcausei");
      }
   }
   return(@l,$self->SUPER::getPosibleActions($WfRec));
}

sub AdditionalMainProcess
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if (!defined($action) && Query->Param("rootcausei")){
      return(-1) if (!$self->ValidActionCheck(1,$actions,"rootcausei"));
      my $prmfld=$self->getField("wffields.eventprmticket",$WfRec);
      my $prmticket=$prmfld->RawValue($WfRec);
      if (!($prmticket=~m/^PRM\d+$/)){
         $self->LastMsg(ERROR,"invalid problemticket registered");
         return(0);
      }
      my @WorkflowStep=Query->Param("WorkflowStep");
      push(@WorkflowStep,"AL_TCom::workflow::eventnotify::sendrootcausei");
      Query->Param("WorkflowStep"=>\@WorkflowStep);
      return(0);
   }
   return(-1);
}


#######################################################################
package AL_TCom::workflow::eventnotify::sendrootcausei;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my @email=@{$self->Context->{CurrentTarget}};
   my $eventlang=();
   my @emailprefix=();
   my @emailpostfix=();
   my @emailtext=();
   my @emailsep=();
   my @emailsubheader=();
   my @emailsubtitle=();
   my %additional=();
   my $smsallow;
   my $smstext;
   my $subject;

   my $eventlango=$self->getField("wffields.eventlang",$WfRec);
   $eventlang=$eventlango->RawValue($WfRec) if (defined($eventlango));

   $self->getParent->generateMailSet($WfRec,"rootcausei",
                    \$eventlang,\%additional,
                    \@emailprefix,\@emailpostfix,\@emailtext,\@emailsep,
                    \@emailsubheader,\@emailsubtitle,
                    \$subject,\$smsallow,\$smstext);
   return($self->generateNotificationPreview(emailtext=>\@emailtext,
                                             emailprefix=>\@emailprefix,
                                             emailsep=>\@emailsep,
                                             emailsubheader=>\@emailsubheader,
                                             emailsubtitle=>\@emailsubtitle,
                                             to=>\@email));
}

sub getPosibleButtons
{  
   my $self=shift;
   my $WfRec=shift;
   my %b=$self->SUPER::getPosibleButtons($WfRec);
   my %em=();
   $self->getParent->getNotifyDestinations("rootcausei",$WfRec,\%em);
   my @email=sort(keys(%em));
   $self->Context->{CurrentTarget}=\@email;
   delete($b{NextStep}) if ($#email==-1);
   delete($b{BreakWorkflow});

   return(%b);
}



sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if ($action eq "NextStep"){
      return(undef) if (!$self->ValidActionCheck(1,$actions,"rootcausei"));
      my %em=();
      $self->getParent->getNotifyDestinations("rootcausei",$WfRec,\%em);
      my @emailto=sort(keys(%em));
      my $id=$WfRec->{id};
      $self->getParent->getParent->Action->ResetFilter();
      $self->getParent->getParent->Action->SetFilter({wfheadid=>\$id});
      my @l=$self->getParent->getParent->Action->getHashList(qw(cdate name));
      my $sendcustinfocount=1;
      foreach my $arec (@l){
         $sendcustinfocount++ if ($arec->{name} eq "sendcustinfo");
      }
      my $wf=getModuleObject($self->Config,"base::workflow");
      my $eventlang;
      my @emailprefix=();
      my @emailpostfix=();
      my @emailtext=();
      my @emailsep=();
      my @emailsubheader=();
      my @emailsubtitle=();
      my $smsallow;
      my $smstext;

      my $eventlango=$self->getField("wffields.eventlang",$WfRec);
      $eventlang=$eventlango->RawValue($WfRec) if (defined($eventlango));
      $ENV{HTTP_FORCE_LANGUAGE}=$eventlang;
      $ENV{HTTP_FORCE_LANGUAGE}=~s/-.*$//;

      my $subjectlabel="Ergebnis der Ursachenanalyse";
      my $headtext="Ergebnis der Ursachenanalyse";
      if ($WfRec->{eventlang}=~m/^en/){
         $subjectlabel="result of root cause analyse";
         $headtext="result of root cause analyse";
      }
      my $ag="";
      if ($WfRec->{eventmode} eq "EVk.appl"){ 
         foreach my $appl (@{$WfRec->{affectedapplication}}){
            $ag.="; " if ($ag ne "");
            $ag.=$appl;
         }
      }

      my $failclass=$WfRec->{eventstatclass};
      my $subject=$self->getParent->getNotificationSubject($WfRec,"rootcausei",
                                    $subjectlabel,$failclass,$ag);
      my $salutation=$self->getParent->getSalutation($WfRec,"rootcausei",$ag);

      my $eventstat=$WfRec->{stateid};
      my $failcolor="#6699FF";
      my $utz=$self->getParent->getParent->UserTimezone();
      my $creationtime=$self->getParent->getParent->ExpandTimeExpression('now',
                                                                "de",$utz,$utz);
      my %additional=(headcolor=>$failcolor,eventtype=>'Event',    
                      headtext=>$headtext,headid=>$id,
                      salutation=>$salutation,
                      altsalutation=>$salutation,
                      creationtime=>$creationtime);
      $self->getParent->generateMailSet($WfRec,"rootcausei",
                       \$eventlang,\%additional,
                       \@emailprefix,\@emailpostfix,\@emailtext,\@emailsep,
                       \@emailsubheader,\@emailsubtitle,\$subject,
                       \$smsallow,\$smstext);
      delete($ENV{HTTP_FORCE_LANGUAGE});
      #
      # calc from address
      #
      my $emailfrom="unknown\@w5base.net";
      my @emailcc=();
      my $uobj=$self->getParent->getPersistentModuleObject("base::user");
      my $userid=$self->getParent->getParent->getCurrentUserId(); 
      $uobj->SetFilter({userid=>\$userid});
      my ($userrec,$msg)=$uobj->getOnlyFirst(qw(email));
      if (defined($userrec) && $userrec->{email} ne ""){
         $emailfrom=$userrec->{email};
         my $qemailfrom=quotemeta($emailfrom);
         if (!grep(/^$qemailfrom$/,@emailto)){
            push(@emailcc,$emailfrom);
         }
      }
      
      #
      # load crator in cc
      #
      if ($WfRec->{openuser} ne ""){
         $uobj->SetFilter({userid=>\$WfRec->{openuser}});
         my ($userrec,$msg)=$uobj->getOnlyFirst(qw(email));
         if (defined($userrec) && $userrec->{email} ne ""){
            my $e=$userrec->{email};
            my $qemailfrom=quotemeta($e);
            if (!grep(/^$qemailfrom$/,@emailto) &&
                !grep(/^$qemailfrom$/,@emailcc)){
               push(@emailcc,$e);
            }
         }
      }
      my $newmailrec={
             class    =>'base::workflow::mailsend',
             step     =>'base::workflow::mailsend::dataload',
             name     =>$subject,
             emailtemplate  =>'eventnotification',
             skinbase       =>$self->getParent->getNotificationSkinbase($WfRec),
             emailfrom      =>$emailfrom,
             emailto        =>\@emailto,
             emailcc        =>\@emailcc,
             allowsms       =>$smsallow,
             emaillang      =>$eventlang,
             emailprefix    =>\@emailprefix,
             emailpostfix   =>\@emailpostfix,
             emailtext      =>\@emailtext,
             emailsep       =>\@emailsep,
             emailsubheader =>\@emailsubheader,
             emailsubtitle  =>\@emailsubtitle,
             additional     =>\%additional
            };
      if (my $id=$wf->Store(undef,$newmailrec)){
         if ($self->getParent->activateMailSend($WfRec,$wf,
                                                $id,$newmailrec,$action)){
            if ($wf->Action->StoreRecord(
                $WfRec->{id},"rootcausi",
                {translation=>'AL_TCom::workflow::eventnotify'},
                undef,undef)){
               Query->Delete("WorkflowStep");
               return(1);
            }
         }
      }
      else{
         return(0);
      }
      return(1);
   }
   return($self->SUPER::Process($action,$WfRec));
}



1;
