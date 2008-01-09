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
   if ($action eq "NextStep"){
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
   return(0);
}

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   return("no Workspace in ".$self->Self());
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
   my $lastmsg=shift;
   my $actions=shift;
   my @reqaction=@_;
   foreach my $a (@reqaction){
      return(1) if ($a ne "" && grep(/^$a$/,@{$actions}));
   }
   if ($lastmsg){
      my $app=$self->getParent->getParent();
      $app->LastMsg(ERROR,$app->T("ileagal action '%s' requested"),
                    join(",",@reqaction));
   }
   return(0);
}



sub generateNotificationPreview
{
   my $self=shift;
   my %param=@_;
   my $email=join("; ",@{$param{to}});
   my $emailcc="";
   $emailcc=join("; ",@{$param{cc}}) if (ref($param{cc}) eq "ARRAY");

   my $preview=$self->getParent->getParent->T("Preview");
   my $tomsg=$self->getParent->getParent->T("To");
   my $ccmsg=$self->getParent->getParent->T("CC");
   my $sepstart="<table class=emailpreviewset border=1>";
   my $sepend="</table>";
   my $templ=<<EOF;
<div class=emailpreview>
&nbsp;<b>$preview:</b>
<table class=emailpreview>
<tr>
<td valign=top>$tomsg:</td>
<td>$email</td>
</tr>
EOF
   $templ.=<<EOF if ($emailcc ne "");
<tr>
<td valign=top>$ccmsg:</td>
<td>$emailcc</td>
</tr>
EOF
   $templ.=<<EOF;
<tr>
<td colspan=2>$sepstart
EOF
   for(my $blk=0;$blk<=$#{$param{emailtext}};$blk++){

      if ($param{emailsubheader}->[$blk] ne "" &&
          $param{emailsubheader}->[$blk] ne "0"){
         my $sh=$param{emailsubheader}->[$blk];
         if ($sh eq "1"){
            $sh="";
         }
         if ($sh eq " "){
            $sh="&nbsp;";
         }
         $templ.="<tr><td colspan=2 class=emailpreviewemailsubheader>".
                 $sh."</td></tr>";
      }

      if ($param{emailsep}->[$blk] ne "" &&
          $param{emailsep}->[$blk] ne "0"){
         my $septext=$param{emailsep}->[$blk];
         if ($septext eq "1"){
            $septext="";
         }
         $templ.=$sepend.$septext.$sepstart;
      }
      $templ.="<tr>";
      $templ.="<td class=emailpreviewemailprefix>".
              $param{emailprefix}->[$blk]."</td>";
      $templ.="<td class=emailpreviewemailtext>".
              "<table style=\"table-layout:fixed;width:100%\" ".
              "cellspacing=0 cellpadding=0><tr><td>".
              "<pre class=emailpreview>".
              FancyLinks($param{emailtext}->[$blk])."</pre>".
              "</td></tr></table></td>";
      $templ.="</tr>";
   }
   $templ.=$sepend."</td></tr></table></div>";

#   sub processlink
#   {
#      my $link=shift;
#      my $prefix=shift;
#      my $res="<a href=\"$link\">$link</a>".$prefix;
#      if (length($link)>20){
#         $res="<a href=\"$link\">".
#              "&lt;direct link&gt;</a>".$prefix;
#      }
#      return($res);
#   }
#   $templ=~s#(http|https|telnet|news)(://\S+?)(\?\S+){0,1}(["']{0,1}\s)#processlink("$1$2$3",$4)#ge;

   return($templ);


}


1;

