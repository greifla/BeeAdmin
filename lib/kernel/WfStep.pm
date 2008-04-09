package kernel::WfStep;
#  W5Base Framework
#  Copyright (C) 2002  Hartmut Vogler (hartmut.vogler@epost.de)
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
#
use vars qw(@ISA);
use strict;
use kernel;
use kernel::Operator;
use kernel::Wf;
use Data::Dumper;

@ISA=qw(kernel::Operator kernel::Wf);

sub new
{
   my $type=shift;
   my $parent=shift;
   my $self=bless({@_},$type);

   $self->setParent($parent);
   return($self);
}

sub Config
{
   my $self=shift;
   return($self->getParent()->Config);
}

sub getPosibleButtons
{
   my $self=shift;
   my $WfRec=shift;
   my @WorkflowStep=Query->Param("WorkflowStep");
   my %b=();
   if ($#WorkflowStep>0){
      %b=(PrevStep=>$self->T('previous Step'),
          NextStep=>$self->T('next Step'));
   }
   else{
      %b=(NextStep=>$self->T('next Step'));
   }
   if (defined($WfRec->{id})){
      $b{BreakWorkflow}=$self->T('break Workflow');
   }
   return(%b);
}

sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   return($self->getParent->getWorkHeight($WfRec,$actions));
}


sub ProcessNext
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;
   return($self->Process($action,$WfRec,$actions));
}

sub ProcessPrev
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;
   return($self->Process($action,$WfRec,$actions));
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   $self->LastMsg(ERROR,"%s is no storeable step",$self->Self());
   return(0);
}


sub preValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   msg(DEBUG,"default preValidate handler in WfStep");

   return(1);
}

sub StoreRecord
{
   my $self=shift;
   my $WfRec=shift;
   my $new=shift;

   if (defined($WfRec)){
      my $id=$WfRec->{id};
      #if ($self->Validate($WfRec,$new)){
         return($self->getParent->getParent->ValidatedUpdateRecord($WfRec,$new,
                                                                   {id=>$id}));
      #}
      #else{
      #   if (!($self->LastMsg())){
      #      $self->LastMsg(ERROR,"StoreRecord->Validate unknown error");
      #   }
      #   return(undef);
      #}
   } 
   my $newincurrent=0;
   if (!defined($new->{class}) && !defined(Query->Param("id"))){
      $newincurrent=1;
   }
   $new->{class}=$self->getParent->Self() if (!defined($new->{class}));
   $new->{step}=$self->Self()             if (!defined($new->{step}));
   my $bk=$self->getParent->getParent->ValidatedInsertRecord($new);
   if ($newincurrent){
      Query->Param("id"=>$bk);
   } 
   return($bk);
}

sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   msg(DEBUG,"default FinishWrite Handler in $self");
}


sub PostProcess
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   return(undef);           # return isn't matter
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if ($action eq "PrevStep"){
      my @WorkflowStep=Query->Param("WorkflowStep");
      pop(@WorkflowStep);
      Query->Param("WorkflowStep"=>\@WorkflowStep);
      $self->PostProcess($action,$WfRec,$actions);
      return(0);
   }
   elsif ($action eq "NextStep"){
      my $nextstep=$self->getParent->getNextStep($self->Self(),$WfRec); 
      if (!defined($nextstep)){
         $self->getParent->LastMsg(ERROR,"no next step defined in '%s'",
                                   $self->Self());
         return(0);
      }
      my @WorkflowStep=Query->Param("WorkflowStep");
      push(@WorkflowStep,$nextstep);
      Query->Param("WorkflowStep"=>\@WorkflowStep);
      $self->PostProcess($action,$WfRec,$actions);
      return(0);
   }
   elsif($action eq "SaveStep"){
      my $op=Query->Param("OP");
      if ($action ne "" && !grep(/^$op$/,@{$actions})){
         $self->LastMsg(ERROR,"invalid or disallowed action '$action.$op' ".
                              "requested");
         return(0);
      }
      if ($op eq "wfforward"){    # default forwarding Handler
         my $note=Query->Param("note");
         $note=trim($note);

         my $fobj=$self->getParent->getField("fwdtargetname");
         my $h=$self->getWriteRequestHash("web");
         my $newrec;
         if ($newrec=$fobj->Validate($WfRec,$h)){
            if (!defined($newrec->{fwdtarget}) ||
                !defined($newrec->{fwdtargetid} ||
                $newrec->{fwdtargetid}==0)){
               if ($self->LastMsg()==0){
                  $self->LastMsg(ERROR,"invalid forwarding target");
               }
               return(0);
            }
         }
         else{
            return(0);
         }
         my $fwdtargetname=Query->Param("Formated_fwdtargetname");

         if ($self->StoreRecord($WfRec,{stateid=>2,
                                       fwdtarget=>$newrec->{fwdtarget},
                                       fwdtargetid=>$newrec->{fwdtargetid},
                                       fwddebtarget=>undef,
                                       fwddebtargetid=>undef })){
            if ($self->getParent->getParent->Action->StoreRecord(
                $WfRec->{id},"wfforward",
                {translation=>'base::workflow::request'},$fwdtargetname."\n".
                                                         $note,undef)){
               my $openuserid=$WfRec->{openuser};
               $self->PostProcess($action.".".$op,$WfRec,$actions,
                                  note=>$note,
                                  fwdtarget=>$newrec->{fwdtarget},
                                  fwdtargetid=>$newrec->{fwdtargetid},
                                  fwdtargetname=>$fwdtargetname);
               Query->Delete("OP");
               return(1);
            }
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
      if ($op eq "wfmailsend"){    # default mailsending handling
         my $emailto=Query->Param("emailto");
         my $note=Query->Param("emailmsg");
         $note=trim($note);
         my $wf=$self->getParent->getParent();
         my $subject=$WfRec->{name};
         my $from='no_reply@w5base.net';
         my @to=();
         my $UserCache=$self->Cache->{User}->{Cache};
         if ($emailto=~m/^\s*$/){
            $self->LastMsg(ERROR,"no email address specified");
            return(0);
         }
         my %adr=(emailto=>$emailto);
         if (defined($UserCache->{$ENV{REMOTE_USER}})){
            $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
         }
         if (defined($UserCache->{email}) &&
             $UserCache->{email} ne ""){
            $adr{emailcc}=$UserCache->{email};
         }
         if (my $id=$wf->Store(undef,{
                 class    =>'base::workflow::mailsend',
                 step     =>'base::workflow::mailsend::dataload',
                 name     =>$subject,%adr,
                 emailtext=>$note,
                })){
            my %d=(step=>'base::workflow::mailsend::waitforspool');
            if ($wf->Store($id,%d)){
               $self->getParent->getParent->Action->StoreRecord(
                   $WfRec->{id},"wfmailsend",
                   {translation=>'kernel::WfStep'},"\@:".$emailto."\n\n".$note);
               $self->PostProcess($action.".".$op,$WfRec,$actions,
                                  note=>$note);
               Query->Delete("OP");
               Query->Delete("emailto");
               Query->Delete("emailmsg");
            }
            return(1);
         }
      }
   }





   return(0);
}

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   return("no Workspace in ".$self->Self());
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

   if (grep(/^wfforward$/,@$actions)){
      $$selopt.="<option value=\"wfforward\" class=\"$class\">".
                $self->getParent->T("wfforward",$tr).
                "</option>\n";
      my $d="<table width=100% border=0 cellspacing=0 cellpadding=0><tr>".
         "<td colspan=2><textarea name=note style=\"width:100%;height:100px\">".
         "</textarea></td></tr>";
      $d.="<tr><td width=1% nowrap>".
          $self->getParent->T("forward to","base::workflow::request").
          ":&nbsp;</td>".
          "<td>\%fwdtargetname(detail)\%".
          "</td>";
      $d.="</tr></table>";
      $$divset.="<div id=OPwfforward>$d</div>";
   }
   if (grep(/^wfmailsend$/,@$actions)){
      $$selopt.="<option value=\"wfmailsend\" class=\"$class\">".
                $self->getParent->T("wfmailsend",$tr).
                "</option>\n";
      my $d="<table width=100% border=0 cellspacing=0 cellpadding=0>".
         "<tr>".
         "<td colspan=2>".
         $self->getParent->T("This action sends a E-Mail with automaticly ".
                             "dokumentation in the workflow log").
         "</td></tr><tr>".
         "<td colspan=2>".
         "<table width=100% cellspacing=0 cellpadding=0><tr>".
         "<td nowrap width=1%>".
         $self->getParent->T("to").": &nbsp;</td><td>".
         "<input type=text name=emailto style=\"width:100%\">".
         "</td></tr></table></td></tr>".
         "<tr>".
         "<td colspan=2><textarea name=emailmsg ".
         "style=\"width:100%;height:80px\">".
         "</textarea></td></tr>";
      $d.="</table>";
      $$divset.="<div id=OPwfmailsend>$d</div>";
   }
   if (grep(/^wfdefer$/,@$actions)){
      $$selopt.="<option value=\"wfdefer\" class=\"$class\">".
                $self->getParent->T("wfdefer",$tr).
                "</option>\n";
      $$divset.="<div id=OPwfdefer>".$self->getDefaultNoteDiv($WfRec,
                                                              mode=>"defer").
                "</div>";
   }

}

sub generateStoredWorkspace
{
   my $self=shift;
   my @steplist=@_;

   my $step=pop(@steplist);
   if (defined($step)){
      my $StepObj=$self->getParent->getStepObject($self->Config,$step);
      return($StepObj->generateStoredWorkspace(@steplist));
   }
   return("");
}

#sub getFieldObjsByView
#{
#   my $self=shift;
#   return($self->getParent->getFieldObjsByView(@_));
#}

#sub getClassFieldList
#{
#   my $self=shift;
#   return($self->getParent->getClassFieldList(@_));
#}

sub getWriteRequestHash
{
   my $self=shift;

   return($self->getParent->getParent->getWriteRequestHash(@_));
}


sub getField
{
   my $self=shift;

   return($self->getParent->getField(@_));
}

sub getNextStep
{
   my $self=shift;
   return($self->getParent->getNextStep($self->Self,@_)) if ($#_<=0);
   return($self->getParent->getNextStep(@_));
}

sub ValidActionCheck
{
   my $self=shift;
   return($self->getParent->ValidActionCheck(@_));
}


sub getDefaultNoteDiv
{
   my $self=shift;
   my $WfRec=shift;
   my %param=@_;
   my $mode=$param{mode};
   $mode="addnote" if ($mode eq "");

   my $userid=$self->getParent->getParent->getCurrentUserId();
   my $initiatorid=$WfRec->{initiatorid};
   my $creator=$WfRec->{openuser};

   my $note=Query->Param("note");
   my $d="<table width=100% border=0 cellspacing=0 cellpadding=0><tr>".
         "<td colspan=2><textarea name=note style=\"width:100%;height:100px\">".
         $note."</textarea></td></tr>";
   if ($mode eq "addnote"){
      my @t=(''=>'',
             '10'=>'10 min',
             '20'=>'20 min',
             '30'=>'30 min',
             '40'=>'40 min',
             '50'=>'50 min',
             '60'=>'1 h',
             '120'=>'2 h',
             '240'=>'4 h',
             '300'=>'5 h',
             '360'=>'6 h',
             '420'=>'7 h',
             '480'=>'1 day',
             '720'=>'1,5 days',
             '960'=>'2 days');
      $d.="<tr><td width=1% nowrap>".
          $self->getParent->getParent->T("Effort","base::workflowaction").
          ":&nbsp;</td>".
          "<td><select name=Formated_effort style=\"width:80px\">";
      my $oldval=Query->Param("Formated_effort");
      while(defined(my $min=shift(@t))){
         my $l=shift(@t);
         $d.="<option value=\"$min\"";
         $d.=" selected" if ($min==$oldval);
         $d.=">$l</option>";
      }
      $d.="</select></td>";
      $d.="</tr>";
   }
   if ($mode eq "defer"){
      my $app=$self->getParent->getParent;
      my @t=(
             'now+7d'  =>$app->T("one week"),
             'now+14d' =>$app->T("two weeks"),
             'now+28d' =>$app->T("one month"),
             'now+60d' =>$app->T("two months"),
             'now+90d' =>$app->T("three months"),
             'now+180d'=>$app->T("half a year"));
      $d.="<tr><td width=1% nowrap>".
          $app->T("postponed until").
          ":&nbsp;</td>".
          "<td><select name=Formated_postponeduntil style=\"width:180px\">";
      my $oldval=Query->Param("Formated_postponeduntil");
      while(defined(my $min=shift(@t))){
         my $l=shift(@t);
         $d.="<option value=\"$min\"";
         $d.=" selected" if ($min eq $oldval);
         $d.=">$l</option>";
      }
      $d.="</select></td>";
      $d.="</tr>";
   }
   $d.="</table>";
   return($d);
}



sub generateNotificationPreview
{
   my $self=shift;
   return($self->getParent->generateNotificationPreview(@_));
}

sub CreateSubTip
{
   my $self=shift;
   my $subtip="";
   my $url=$ENV{SCRIPT_URI};
   $url=~s/\/auth\/.*$//;
   $url.="/auth/base/menu/msel/MyW5Base";
   my $qhash=Query->MultiVars();
   delete($qhash->{NextStep});
   delete($qhash->{SaveStep});
   my $qhash=new kernel::cgi($qhash);
   my $openquery={OpenURL=>"$ENV{SCRIPT_URI}?".$qhash->QueryString()};
   my $queryobj=new kernel::cgi($openquery);
   $url.="?".$queryobj->QueryString();
   $url=~s/\%/\\\%/g;
   if (length($url)<2048){ # a limitation by Microsoft
      $subtip.="<hr>";
      my $a="<a href=\"$url\" ".
            "target=_blank title=\"Workflow link included current query\">".
            "<img src=\"../../base/load/anker.gif\" ".
            "height=10 border=0></a>";
      $subtip.=sprintf($self->getParent->T(
                    "You can add a shortcut of this anker %s to ".
                    "your bookmarks, to access faster to this workflow.",
                    'base::workflow'),$a);
      $subtip.="<hr>";
   }
   return($subtip);
}


1;

