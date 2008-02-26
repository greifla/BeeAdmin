package base::workflow::DataIssue;
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
@ISA=qw(kernel::WfClass);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{history}=[qw(insert modify delete)];

   $self->LoadSubObjs("ext/DataIssue","DI");
   foreach my $objname (keys(%{$self->{DI}})){
      my $obj=$self->{DI}->{$objname};
      foreach my $entry (@{$obj->getControlRecord()}){
         $self->{da}->{$entry->{dataobj}}=$entry;
         $self->{da}->{$entry->{dataobj}}->{DI}=$objname;
      }
   }

   return($self);
}

sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my $class;


   #printf STDERR ("param in getDynamicFields=%s\n",Dumper(\%param));
   #printf STDERR ("Query in getDynamicFields=%s\n",
   #               Dumper(scalar(Query->MultiVars())));
   my $affectedobject;
   if (defined($param{current})){
      $affectedobject=$param{current}->{affectedobject};
   }
   else{
      Query->Param("Formated_affectedobject");
   }
   my $dst;
   foreach my $dstobj (sort(keys(%{$self->{da}}))){
      if ($self->{da}->{$dstobj}->{dataobj}=~m/::/){
         push(@$dst,$self->{da}->{$dstobj}->{dataobj},
              $self->{da}->{$dstobj}->{target});
      }
   }
   my ($DataIssueName,$dataobjname)=split(/;/,$affectedobject);
   my @dynfields=$self->InitFields(
                   new kernel::Field::Select(  
                             name               =>'affectedobject',
                             selectwidth        =>'350px',
                             translation        =>'base::workflow::DataIssue',
                             getPostibleValues  =>\&getObjectList,
                             htmldetail    =>sub {
                                my $self=shift;
                                my $mode=shift;
                                my %param=@_;
                                my $current=$param{current};
                                return(1) if ($current->{affectedobject} ne "");
                                return(0);
                             },

                             label              =>'affected Dataobject Type',
                             container          =>'additional'),
                   new kernel::Field::MultiDst(  
                             name               =>'dataissueobjectname',
                             translation        =>'base::workflow::DataIssue',
                             label              =>'affected Dataobject',
                             htmldetail    =>sub {
                                my $self=shift;
                                my $mode=shift;
                                my %param=@_;
                                my $current=$param{current};
                                return(1) if ($current->{affectedobject} ne "");
                                return(0);
                             },
                             dst                =>$dst,
                             selectivetyp       =>1,
                             altnamestore       =>'altaffectedobjectname',
                             dsttypfield        =>'affectedobject',
                             dstidfield         =>'affectedobjectid'),
                   new kernel::Field::Link(  
                             name               =>'affectedobjectid',
                             translation        =>'base::workflow::DataIssue',
                             label              =>'affected Dataelement ID',
                             container          =>'additional'),
                   new kernel::Field::Link(  
                             name               =>'altaffectedobjectname',
                             translation        =>'base::workflow::DataIssue',
                             label              =>'affected Dataelement Name',
                             container          =>'additional'),
                   new kernel::Field::Link(  
                             name               =>'DATAISSUEOPERATIONSRC',
                             translation        =>'base::workflow::DataIssue',
                             label              =>'DataIssue Source',
                             container          =>'additional'),
                   new kernel::Field::Link(  
                             name               =>'DATAISSUEOPERATIONOBJ',
                             translation        =>'base::workflow::DataIssue',
                             label              =>'DataIssue Operation Obj',
                             container          =>'additional'),
                   new kernel::Field::Link(  
                             name               =>'DATAISSUEOPERATIONMOD',
                             translation        =>'base::workflow::DataIssue',
                             label              =>'DataIssue Operation Mode',
                             container          =>'additional'),
                   new kernel::Field::Link(  
                             name               =>'DATAISSUEOPERATIONFLD',
                             translation        =>'base::workflow::DataIssue',
                             label              =>'DataIssue Operation Fields',
                             container          =>'additional'),
                 );
#   if (defined($self->getParent->


   return(@dynfields);
}

sub getObjectList
{
   my $self=shift;
   my $app=$self->getParent->getParent();

   my @l;
   foreach my $k (sort({$app->T($a,$a) cmp $app->T($b,$b)} 
                       keys(%{$self->getParent->{da}}))){
      push(@l,$k,$app->T($k,$k));
   }
   return(@l);

}


sub completeWriteRequest
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   foreach my $objname (keys(%{$self->{DI}})){
      my $obj=$self->{DI}->{$objname};
      if ($obj->can("completeWriteRequest")){
         if (!($obj->completeWriteRequest($oldrec,$newrec))){
            return(undef);
         }
      }
   }
   if ($newrec->{fwdtargetid} eq "" ||
       $newrec->{fwdtarget} eq ""){
      my $grpobj=getModuleObject($self->getParent->Config(),"base::grp");
      $grpobj->SetFilter({name=>\'admin'});
      my ($grprec,$msg)=$grpobj->getOnlyFirst(qw(grpid));
      if (defined($grprec)){
         $newrec->{fwdtargetid}=$grprec->{grpid}; 
         $newrec->{fwdtarget}="base::grp"; 
         return(1);
      }
      return(undef);
    
   }
   return(1);
}





sub IsModuleSelectable
{
   my $self=shift;
   my $acl;

   $acl=$self->getParent->getMenuAcl($ENV{REMOTE_USER},
                          "base::workflow",
                          func=>'New',
                          param=>'WorkflowClass=base::workflow::DataIssue');
   if (defined($acl)){
      return(1) if (grep(/^read$/,@$acl));
   }
   return(1) if ($self->getParent->IsMemberOf("admin"));
   return(0);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default","state","source","flow","header","relations","init","history");
}

sub getDetailBlockPriority            # posibility to change the block order
{
   return("header","default","flow","state","source");
}



sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(1) if (!defined($rec));
   my @l;
#   push(@l,"default") if ($rec->{state}<=20 &&
#                         ($self->isCurrentForward() ||
#                          $self->getParent->IsMemberOf("admin")));
#   if (grep(/^default$/,@l) &&
#       ($self->getParent->getCurrentUserId() != $rec->{initiatorid} ||
#        $self->getParent->IsMemberOf("admin"))){
#      push(@l,"init");
#   }
   return(@l);
}




sub getStepByShortname
{
   my $self=shift;
   my $shortname=shift;
   my $WfRec=shift;

   return("base::workflow::DataIssue::".$shortname);
}


sub getNextStep
{
   my $self=shift;
   my $currentstep=shift;
   my $WfRec=shift;

   if($currentstep eq ""){
      return($self->getStepByShortname("dataload",$WfRec)); 
   }
   elsif($currentstep=~m/::dataload$/){
      return($self->getStepByShortname("main",$WfRec)); 
   }
   return(undef);
}

sub isOptionalFieldVisible
{
   my $self=shift;
   my $mode=shift;
   my %param=@_;
   my $name=$param{field}->Name();

   return(1) if ($name eq "prio");
   return(1) if ($name eq "name");
   return(1) if ($name eq "shortactionlog");
   return(1) if ($name eq "detaildescription");
   return(0);
}



sub getPosibleActions
{
   my $self=shift;
   my $WfRec=shift;
   my $app=$self->getParent;
   my $userid=$self->getParent->getCurrentUserId();
   my $isadmin=$self->getParent->IsMemberOf("admin");
   my $stateid=$WfRec->{stateid};
   my $lastworker=$WfRec->{owner};
   my $creator=$WfRec->{openuser};
   my $initiatorid=$WfRec->{initiatorid};
   my @l=();
   my $iscurrent=$self->isCurrentForward($WfRec);

   if ($iscurrent && ($stateid==2 || $stateid==4)){
      push(@l,"wfaddnote");
      push(@l,"wfdefer");
      push(@l,"wfdifine");
   }
   if ($iscurrent && $creator==$userid && ($stateid==16)){
      push(@l,"wfdireproc");
      push(@l,"wffine");
   }
   push(@l,"nop") if ($#l==-1 && $stateid<=20);
   if ($creator==$userid && $stateid==2){
      push(@l,"wfbreak");
   }
   if ($isadmin){
      push(@l,"wfbreak");
   }
   return(@l);
}


sub NotifyUsers
{
   my $self=shift;

}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/issue.jpg?".$cgi->query_string());
}


#######################################################################
package base::workflow::DataIssue::dataload;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
use Data::Dumper;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
<tr>
<td class=fname width=20%>%affectedobject(label)%:</td>
<td class=finput>%affectedobject(detail)%</td>
</tr>
<tr>
<td class=fname width=20%>%dataissueobjectname(label)%:</td>
<td class=finput>%dataissueobjectname(detail)%</td>
</tr>
<tr>
<td class=fname width=20%>%name(label)%:</td>
<td class=finput>%name(detail)%</td>
</tr>
<tr>
<td class=fname valign=top width=20%>detailierte Beschreibung<br>des Datenproblems:</td>
<td class=finput>%detaildescription(detail)%</td>
</tr>
</table>
EOF
   return($templ);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;
   printf STDERR ("fifi Validate $self\n");

#  nativ needed
#   - name
#   - detaildescription
#   - affectedobject
#   - affectedobjectid
#

   my $issuesrc=effVal($oldrec,$newrec,"DATAISSUEOPERATIONSRC");
   $newrec->{DATAISSUEOPERATIONSRC}="manual" if ($issuesrc eq "");
                                             # if src is "qualitycheck" there
                                             # is no need to inform the creator
                                             # on finish

   # requested from Quality Check
#   $newrec->{DATAISSUEOPERATIONOBJ}="itil::appl";
#   $newrec->{DATAISSUEOPERATIONMOD}="update";
#   $newrec->{DATAISSUEOPERATIONFLD}="name,xx";
#   $newrec->{headref}={name=>'hans',
#                       xx=>'wert von xx'};



   #$newrec->{name}="Kundenpriorität ist nicht korrekt eingetragen";
   #$newrec->{detaildescription}="xxo";

   foreach my $v (qw(name detaildescription)){
      if ((!defined($oldrec) || exists($newrec->{$v})) && $newrec->{$v} eq ""){
         $self->LastMsg(ERROR,"field '%s' is empty",
                        $self->getField($v)->Label());
         return(0);
      }
   }
   $newrec->{stateid}=2 if (!defined(effVal($oldrec,$newrec,"cistatusid")));

   $newrec->{affectedobject}=effVal($oldrec,$newrec,"affectedobject");
   $newrec->{affectedobjectid}=effVal($oldrec,$newrec,"affectedobjectid");
   $newrec->{step}=$self->getNextStep();
   if (!$self->getParent->completeWriteRequest($oldrec,$newrec)){
      $self->LastMsg(ERROR,"can't complete Write Request");
      return(undef);
   }

      #
      # now it's time to add fwdtarget,fwdtargetid,mandatorid,
      # fwddebtarget,fwddebtargetid
      # in an object specified method
      #
     

   return(1);
}


sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if ($action eq "NextStep"){
      my $fo=$self->getField("dataissueobjectname");
      my $foval=Query->Param("Formated_".$fo->Name());
      if ($foval=~m/^\s*$/){
         $self->LastMsg(ERROR,"no object specified");
         return(0);
      }
      my $obj;
      if (!($obj=$fo->Validate($WfRec,{$fo->Name=>$foval}))){
         $self->LastMsg(ERROR,"unknown error") if (!$self->LastMsg());
         return(0);
      }

      my $h=$self->getWriteRequestHash("web");
      $h->{eventstart}=NowStamp("en");
      $h->{eventend}=undef;
      $h->{DATAISSUEOPERATIONSRC}="manual";
      printf STDERR ("fifi getWriteRequestHash=%s\n",Dumper($h));
      if (my $id=$self->StoreRecord($WfRec,$h)){
         $h->{id}=$id;
      }
      else{
         return(0);
      }
      return(1);
   }

   return($self->SUPER::Process($action,$WfRec));
}



sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return("100%");
}


#######################################################################
package base::workflow::DataIssue::main;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
use Data::Dumper;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   my $divset="";
   my $selopt="";

   return("") if ($#{$actions}==-1);
   $self->generateWorkspacePages($WfRec,$actions,\$divset,\$selopt);   
   my $oldop=Query->Param("OP");
   my $templ;
   my $pa=$self->getParent->T("posible action");
   $templ=<<EOF;
<table width=100% height=148 border=0 cellspacing=0 cellpadding=0>
<tr height=1%><td width=1% nowrap>$pa &nbsp;</td>
<td><select id=OP name=OP style="width:100%">$selopt</select></td></tr>
<tr><td colspan=3 valign=top>$divset</td></tr>
</table>
<script language="JavaScript">
function fineSwitch(s)
{
   var sa=document.forms[0].elements['SaveStep'];
   if (s.value=="nop"){
      if (sa){
         sa.disabled=true;
      }
   }
   else{
      if (sa){
         sa.disabled=false;
      }
   }
}
function InitDivs()
{
   var s=document.getElementById("OP");
   divSwitcher(s,"$oldop",fineSwitch);
}
addEvent(window,"load",InitDivs);
//InitDivs();
//window.setTimeout(InitDivs,1000);   // ensure to disable button (mozilla bug)
</script>
EOF

   return($templ);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   if (defined($newrec->{stateid}) &&
       $newrec->{stateid}==21){
      if ($self->getParent->getParent->Action->StoreRecord(
          $oldrec->{id},"wfobsolete",
          {translation=>'base::workflow::DataIssue'},"",undef)){
         $newrec->{step}="base::workflow::DataIssue::finish";
         $newrec->{eventend}=$self->getParent->ExpandTimeExpression("now",
                                                                  "en","GMT");;
         $newrec->{closedate}=$self->getParent->ExpandTimeExpression("now",
                                                                  "en","GMT");;
         return(1);
      }
      return(0);
   }
   elsif (defined($newrec->{stateid}) &&
       $newrec->{stateid}==22){
       $newrec->{eventend}=$self->getParent->ExpandTimeExpression("now",
                                                                "en","GMT");;
       $newrec->{closedate}=$self->getParent->ExpandTimeExpression("now",
                                                                "en","GMT");;
   }
   else{
      if (!$self->getParent->completeWriteRequest($oldrec,$newrec)){
         $self->LastMsg(ERROR,"can't complete Write Request");
         return(undef);
      }
   }

   return(1);
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   
   if ($action eq "BreakWorkflow"){
      if ($action ne "" && !grep(/^wfbreak$/,@{$actions})){
         $self->LastMsg(ERROR,"invalid disalloed action requested");
         return(0);
      }
      my $oprec={};
      $oprec->{stateid}=22;
      if ($self->getParent->getParent->Action->StoreRecord(
          $WfRec->{id},"wfbreak",
          {translation=>'base::workflow::request'},undef,undef)){
         $self->StoreRecord($WfRec,$oprec);
         $self->PostProcess($action,$WfRec,$actions);
         Query->Delete("note");
         return(1);
      }
   }
   elsif ($action eq "SaveStep"){
      my $op=Query->Param("OP");
      if ($action ne "" && !grep(/^$op$/,@{$actions})){
         $self->LastMsg(ERROR,"invalid disalloed action requested");
         return(0);
      }
      if ($op eq "wfaddnote"){
         my $note=Query->Param("note");
         if ($note=~m/^\s*$/  || length($note)<10){
            $self->LastMsg(ERROR,"empty or to short notes are not allowed");
            return(0);
         }
         $note=trim($note);
         my $oprec={};
         $oprec->{stateid}=4;
         my $effort=Query->Param("Formated_effort");
         if ($self->getParent->getParent->Action->StoreRecord(
             $WfRec->{id},"wfaddnote",
             {translation=>'base::workflow::request'},$note,$effort)){
            $self->StoreRecord($WfRec,$oprec);
            $self->PostProcess($action.".".$op,$WfRec,$actions);
            Query->Delete("note");
            return(1);
         }
         return(0);
      }
      if ($op eq "wfdefer"){
         my $app=$self->getParent->getParent;
         my $note=Query->Param("note");
         if ($note=~m/^\s*$/  || length($note)<10){
            $self->LastMsg(ERROR,"empty or to short notes are not allowed");
            return(0);
         }
         $note=trim($note);
         my $oprec={};
         $oprec->{stateid}=5;
         my $postponeduntil=Query->Param("Formated_postponeduntil");
         $oprec->{postponeduntil}=$app->ExpandTimeExpression($postponeduntil);
         if ($oprec->{postponeduntil} ne ""){
            if ($app->Action->StoreRecord($WfRec->{id},"wfdefer",
                {translation=>'base::workflow::request'},$note)){
               $self->StoreRecord($WfRec,$oprec);
               $self->PostProcess($action.".".$op,$WfRec,$actions);
               Query->Delete("note");
               return(1);
            }
         }
         else{
            $app->LastMsg(ERROR,"invalid postponeduntil specifed");
         }
         return(0);
      }
      if ($op eq "wfdifine"){
         my $app=$self->getParent->getParent;
         my $note=Query->Param("note");
         $note=trim($note);
         my $oprec={};
         $oprec->{postponeduntil}=undef;
         if ($WfRec->{openuser} eq ""){
            $oprec->{stateid}=21;
            $oprec->{step}='base::workflow::DataIssue::finish';
            $oprec->{fwdtarget}=undef;
            $oprec->{fwdtargetid}=undef;
         }
         else{
            $oprec->{stateid}=16;
            $oprec->{fwdtarget}='base::user';
            $oprec->{fwdtargetid}=$WfRec->{openuser};
            $oprec->{eventend}=$self->getParent->ExpandTimeExpression("now",
                                                                 "en","GMT");;
         }
         if ($app->Action->StoreRecord($WfRec->{id},"wffine",
             {translation=>'base::workflow::DataIssue'},$note)){
            $self->StoreRecord($WfRec,$oprec);
            $self->PostProcess($action.".".$op,$WfRec,$actions);
            Query->Delete("note");
            return(1);
         }
         return(0);
      }
      if ($op eq "wffine"){
         my $app=$self->getParent->getParent;
         my $note=Query->Param("note");
         $note=trim($note);
         my $oprec={};
         $oprec->{postponeduntil}=undef;
         $oprec->{stateid}=21;
         $oprec->{step}='base::workflow::DataIssue::finish';
         $oprec->{fwdtarget}=undef;
         $oprec->{fwdtargetid}=undef;
         if ($app->Action->StoreRecord($WfRec->{id},"wffine",
             {translation=>'base::workflow::DataIssue'},$note)){
            $self->StoreRecord($WfRec,$oprec);
            $self->PostProcess($action.".".$op,$WfRec,$actions);
            Query->Delete("note");
            return(1);
         }
         return(0);
      }
      if ($op eq "wfdireproc"){
         my $app=$self->getParent->getParent;
         my $note=Query->Param("note");
         $note=trim($note);
         my $oprec={};
         $oprec->{postponeduntil}=undef;
         $oprec->{eventend}=undef;
         $oprec->{stateid}=2;
         $oprec->{step}='base::workflow::DataIssue::main';
         $oprec->{affectedobject}=effVal($WfRec,$oprec,"affectedobject");
         $oprec->{affectedobjectid}=effVal($WfRec,$oprec,"affectedobjectid");
         if (!$self->getParent->completeWriteRequest(undef,$oprec)){
            $self->LastMsg(ERROR,"can't complete Write Request");
            return(undef);
         }
         if ($app->Action->StoreRecord($WfRec->{id},"wfdireproc",
             {translation=>'base::workflow::DataIssue'},$note)){
            $self->StoreRecord($WfRec,$oprec);
            $self->PostProcess($action.".".$op,$WfRec,$actions);
            Query->Delete("note");
            return(1);
         }
         return(0);
      }
   }
   return($self->SUPER::Process($action,$WfRec));
}



sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   my @saveables=grep(!/^wfbreak$/,@$actions);
   return(0)  if ($#{$actions}==-1);
   return(20) if ($#saveables==-1);
   return(180);
}

sub getPosibleButtons
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my @WorkflowStep=Query->Param("WorkflowStep");
   my %b=();
   my @saveables=grep(!/^wfbreak$/,@$actions);
   if ($#saveables!=-1){
      %b=(SaveStep=>$self->T('Save')) if ($#{$actions}!=-1);
   }
   if (defined($WfRec->{id})){
      if (grep(/^wfbreak$/,@$actions)){
         $b{BreakWorkflow}=$self->T('abbort request');
      }
   }
   return(%b);
}  


sub generateWorkspacePages
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $divset=shift;
   my $selopt=shift;
   my $tr="base::workflow::actions";
   my $class="display:none;visibility:hidden";

   if (grep(/^nop$/,@$actions)){
      $$selopt.="<option value=\"nop\" class=\"$class\">".
                $self->getParent->T("nop",$tr).
                "</option>\n";
      $$divset.="<div id=OPnop style=\"margin:15px\"><br>".
                $self->getParent->T("The current workflow isn't forwared ".
                "to you. At now there is no action nessasary.",$tr)."</div>";
   }
   if (grep(/^wffine$/,@$actions)){
      $$selopt.="<option value=\"wffine\" class=\"$class\">".
                $self->getParent->T("wffine",$tr).
                "</option>\n";
      $$divset.="<div id=OPwffine>".
                "</div>";
   }
   if (grep(/^wfdifine$/,@$actions)){
      $$selopt.="<option value=\"wfdifine\" class=\"$class\">".
                $self->getParent->T("wfdifine",$tr).
                "</option>\n";
      $$divset.="<div id=OPwfdifine>".$self->getDefaultNoteDiv($WfRec).
                "</div>";
   }
   if (grep(/^wfaddnote$/,@$actions)){
      $$selopt.="<option value=\"wfaddnote\" class=\"$class\">".
                $self->getParent->T("wfaddnote",$tr).
                "</option>\n";
      $$divset.="<div id=OPwfaddnote>".$self->getDefaultNoteDiv($WfRec).
                "</div>";
   }
   if (grep(/^wfdefer$/,@$actions)){
      $$selopt.="<option value=\"wfdefer\" class=\"$class\">".
                $self->getParent->T("wfdefer",$tr).
                "</option>\n";
      $$divset.="<div id=OPwfdefer>".$self->getDefaultNoteDiv($WfRec,
                                                              mode=>"defer").
                "</div>";
   }
   if (grep(/^wfdireproc$/,@$actions)){
      $$selopt.="<option value=\"wfdireproc\" class=\"$class\">".
                $self->getParent->T("wfdireproc",$tr).
                "</option>\n";
      $$divset.="<div id=OPwfdireproc>".$self->getDefaultNoteDiv($WfRec).
                "</div>";
   }
}



#######################################################################
package base::workflow::DataIssue::finish;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
use Data::Dumper;
@ISA=qw(kernel::WfStep);


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   if ($newrec->{stateid}==21){
      $newrec->{eventend}=$self->getParent->ExpandTimeExpression("now",
                                                                 "en","GMT");;
      $newrec->{closedate}=$self->getParent->ExpandTimeExpression("now",
                                                               "en","GMT");;
      return(1);
   }
   return(0);
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return("0");
}


1;
