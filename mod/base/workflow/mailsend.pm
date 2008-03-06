package base::workflow::mailsend;
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
   $self->{_permitted}->{to}=1;
   $self->AddFields(
      new kernel::Field::Email(   name        =>'emailto',
                                  valign      =>'top',
                                  label       =>'Mail Target Address',
                                  group       =>'mailsend',
                                  translation =>'base::workflow::mailsend',
                                  container   =>'headref'),
                                             
      new kernel::Field::Email(   name        =>'emailfrom',
                                  label       =>'Mail From Address',
                                  group       =>'mailsend',
                                  translation =>'base::workflow::mailsend',
                                  container   =>'headref'),
                                             
      new kernel::Field::Email(   name        =>'emailcc',
                                  label       =>'Mail CC Address',
                                  group       =>'mailsend',
                                  container   =>'headref'),

      new kernel::Field::Email(   name        =>'emailbcc',
                                  label       =>'Mail BCC Address',
                                  uivisible   =>0,
                                  group       =>'mailsend',
                                  container   =>'headref'),

   );
   return($self);
}

sub Init
{
   my $self=shift;

   $self->AddFields(
   );

   $self->AddGroup("mailsend",translation=>'base::workflow::mailsend');
}


sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my $class;

   return($self->InitFields(   
      new kernel::Field::Text(    name        =>'emailtemplate',
                                  label       =>'Template',
                                  group       =>'mailsend',
                                  container   =>'headref'),
                                             
      new kernel::Field::Text(    name        =>'emailsignatur',
                                  label       =>'Signatur',
                                  group       =>'mailsend',
                                  container   =>'headref'),
                                             
      new kernel::Field::Text(    name        =>'skinbase',
                                  label       =>'Skin Base',
                                  group       =>'mailsend',
                                  container   =>'headref'),
                                             
      new kernel::Field::Text(    name        =>'emaillang',
                                  label       =>'Mail Language',
                                  uivisible   =>0,
                                  group       =>'mailsend',
                                  container   =>'headref'),
                                             
      new kernel::Field::Textarea(name        =>'emailhead',
                                  uivisible   =>0,
                                  label       =>'Mail head',
                                  group       =>'mailsend',
                                  container   =>'headref'),

      new kernel::Field::Textarea(name        =>'emailtext',
                                  label       =>'Mail Text',
                                  group       =>'mailsend',
                                  container   =>'headref'),

      new kernel::Field::Textarea(name        =>'emailbottom',
                                  uivisible   =>0,
                                  label       =>'Mail bottom',
                                  group       =>'mailsend',
                                  container   =>'headref'),

      new kernel::Field::Textarea(name        =>'emailtstamp',
                                  label       =>'Mail tstamp',
                                  group       =>'mailsend',
                                  container   =>'headref'),

      new kernel::Field::Textarea(name        =>'emailprefix',
                                  label       =>'Mail prefix',
                                  group       =>'mailsend',
                                  container   =>'headref'),

      new kernel::Field::Textarea(name        =>'emailpostfix',
                                  label       =>'Mail postfix',
                                  group       =>'mailsend',
                                  container   =>'headref'),

      new kernel::Field::Textarea(name        =>'emailsep',
                                  label       =>'Mail sperator',
                                  uivisible   =>0,
                                  group       =>'mailsend',
                                  container   =>'headref'),

      new kernel::Field::Textarea(name        =>'emailsubtitle',
                                  label       =>'Mail SubTitle',
                                  group       =>'mailsend',
                                  container   =>'headref'),

      new kernel::Field::Textarea(name        =>'emailsubheader',
                                  label       =>'Mail SubHeader',
                                  uivisible   =>0,
                                  group       =>'mailsend',
                                  container   =>'headref'),
     )
  );
}

sub IsModuleSelectable
{
   my $self=shift;
   my $to=$self->to;
   if (ref($to) eq "ARRAY"){
      my @view=$self->getParent->getCurrentView();
      foreach my $t (@$to){
         return(1) if (grep(/^$t$/,@view));
      }
      return(0);
   }
   return(0);
}

sub InitWorkflow
{
   my $self=shift;

   # Standard Init
   Query->Param("WorkflowClass"=>$self->Self);
   Query->Param("WorkflowStepList"=>"");
   Query->Param("AllowClose"=>"1");

   # Datensammlung
   my %q=$self->getParent->getSearchHash();
   $self->getParent->SetFilter(\%q);
   my %email=();
   map({
          $email{$_->{email}}={} if ($_->{email} ne "");
       } 
       $self->getParent->getHashList("email"));
   Query->Param("to"=>[keys(%email)]);
   print $self->getParent->HtmlPersistentVariables(qw(to));
   printf("fifi email=%s<br>\n",join(",",keys(%email)));
   printf("fifi workflowclass=%s<br>\n",$self->Self);
   printf("<br>... hier mu� noch was gemacht werden<br>\n");
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default","state","mailsend","header");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(1) if (!defined($rec));
   return(undef);
   return("default","mailsend");
}


sub getNextStep
{
   my $self=shift;
   my $currentstep=shift;
   my $WfRec=shift;

   if ($currentstep eq "base::workflow::mailsend::dataload"){
      return("base::workflow::mailsend::verify"); 
      return("base::workflow::attachment::edit");
   }
#   elsif($currentstep eq "base::workflow::attachment::edit"){
#      return("base::workflow::mailsend::verify"); 
#   }
   elsif($currentstep eq "base::workflow::mailsend::verify"){
      return("base::workflow::mailsend::waitforspool"); 
   }
   elsif($currentstep eq "base::workflow::mailsend::finish"){
      return("base::workflow::mailsend::finish"); 
   }
   elsif($currentstep eq ""){
      return("base::workflow::mailsend::dataload"); 
   }
   return(undef);
}






#######################################################################
package base::workflow::mailsend::dataload;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
use Data::Dumper;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;

   my @currentemaillist=Query->Param("Formated_emailto");
   if ($#currentemaillist==-1){
      if (ref($WfRec->{emailto}) eq "ARRAY"){
         push(@currentemaillist,@{$WfRec->{emailto}});
      }
      else{
         push(@currentemaillist,$WfRec->{emailto});
      }
   }
   my $emptycount=0;
   map({$emptycount++ if ($_=~m/^\s*$/);} @currentemaillist);
   for(;$emptycount<3;$emptycount++){
      push(@currentemaillist,"");
   }
   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
EOF
   foreach my $emailto (@currentemaillist){
      my $input=$self->getField("emailto")->getSimpleTextInputField($emailto);
      $templ.="<tr><td width=1% nowrap class=fname>%emailto(label)%:</td>".
              "<td class=finput>$input</td></tr>";
   }

   $templ.=<<EOF;
<tr>
<td class=fname>%name(label)%:</td>
<td class=finput>%name(detail)%</td>
</tr>
<tr>
<td colspan=2 class=fname>%emailtext(label)%:<br>
%emailtext(detail)%</td>
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

   foreach my $v (qw(name emailtext)){
      if ((!defined($oldrec) || exists($newrec->{$v})) && $newrec->{$v} eq ""){
         $self->LastMsg(ERROR,"field '%s' is empty",
                        $self->getField($v)->Label());
         return(0);
      }
   }
   if ((!defined($oldrec) || exists($newrec->{"emailto"}) ||
                             exists($newrec->{"emailbcc"}))){
      if (ref($newrec->{emailto}) ne "ARRAY"){
         $newrec->{emailto}=[$newrec->{emailto}];
      }
      if (ref($newrec->{emailbcc}) ne "ARRAY"){
         $newrec->{emailbcc}=[$newrec->{emailbcc}];
      }
      my %u=();
      map({trim(\$_);$u{$_}=1; } @{$newrec->{emailto}});
      @{$newrec->{emailto}}=grep(!/^\s*$/,sort(keys(%u)));
      if ($#{$newrec->{emailto}}==-1 &&
          $#{$newrec->{emailbcc}}==-1){
         $self->LastMsg(ERROR,"field '%s' is empty",
                        $self->getField("emailto")->Label());
         return(0);
      }
   }
   if (!defined($oldrec) && !exists($newrec->{emailfrom})){
      my $UserCache=$self->Cache->{User}->{Cache};
      if (defined($UserCache->{$ENV{REMOTE_USER}})){
         $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
      }
      if (defined($UserCache->{userid})){
         $newrec->{emailfrom}= $UserCache->{email};
      }
   }
   $newrec->{step}=$self->getNextStep();
   $newrec->{stateid}=1;
   $newrec->{eventstart}=NowStamp("en");
   $newrec->{eventend}=undef;
   $newrec->{closedate}=undef;
   if (!defined($newrec->{emailtemplate}) || $newrec->{emailtemplate} eq ""){
      $newrec->{emailtemplate}="sendmail";
   }
   if (!defined($newrec->{skinbase}) || $newrec->{skinbase} eq ""){
      $newrec->{skinbase}="base";
   }
   return(1);
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;

   if ($action eq "NextStep"){
      my $h=$self->getWriteRequestHash("web");
      if (!$self->StoreRecord($WfRec,$h)){
         return(0);
      }
   }
   if ($action eq "BreakWorkflow"){
      if (!$self->StoreRecord($WfRec,{
                                step=>'base::workflow::mailsend::break',
                                stateid=>17})){
         return(0);
      }
      return(1);
   }
   return($self->SUPER::Process($action,$WfRec));
}


#######################################################################
package base::workflow::mailsend::verify;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;

   my $templ=<<EOF;
<br><div class=Question><table border=0><tr>
<td><input type=checkbox name=go></td>
<td>Ja, ich bin sicher, dass ich die Mail versenden m�chte.</td>
</tr></table></div>
EOF
   return($templ);
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;

   if ($action eq "NextStep"){
      if (defined(Query->Param("go"))){
         if (!$self->StoreRecord($WfRec,{step=>$self->getNextStep()})){
            # no step change on error - error message in LastMsg
            return(0);
         }
         return(1);
      }
      else{
         $self->LastMsg(ERROR,"no confirmation recieved");
         return(0);
      }
   }
   if ($action eq "BreakWorkflow"){
      if (!$self->StoreRecord($WfRec,{
                                step=>'base::workflow::mailsend::break',
                                stateid=>22})){
         return(0);
      }
      return(1);
   }
   return($self->SUPER::Process($action,$WfRec));
}


#######################################################################
package base::workflow::mailsend::waitforspool;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;
   return(undef) if (!defined($oldrec));
   $newrec->{stateid}=6;

   return(1); 
}

sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $res=$self->W5ServerCall("rpcCallEvent","sendmail",$oldrec->{id});
   if (defined($res) && $res->{exitcode}==0){
       #$self->StoreRecord($WfRec,{state=>5}); 
      msg(DEBUG,"W5Server has been notify about mailsend\n")
   }
}



sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $msg=$self->T("Waiting for processing by the mailspooler.");
   my $templ=<<EOF;
<br><div class=Question><table border=0><tr><td>$msg</td></tr></table></div>
EOF
   return($templ);
}

sub getPosibleButtons
{
   my $self=shift;
   my $WfRec=shift;
   return();
}

sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(100);
}




#######################################################################
package base::workflow::mailsend::finish;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $msg=$self->T("Mail send.");
   my $templ=<<EOF;
<br><div class=Question><table border=0><tr><td>$msg</td></tr></table></div>
EOF
   return($templ);
}

sub getPosibleButtons
{
   my $self=shift;
   my $WfRec=shift;
   return();
}

sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(100);
}

sub Validate
{
   my $self=shift;
   return(1);
}



#######################################################################
package base::workflow::mailsend::break;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $msg=$self->T("Mail not send.");
   my $templ=<<EOF;
<br><div class=Question><table border=0><tr><td>$msg</td></tr></table></div>
EOF
   return($templ);
}

sub getPosibleButtons
{
   my $self=shift;
   my $WfRec=shift;
   return();
}

sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(100);
}


#######################################################################


1;
