package base::workflowaction;
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
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
use Data::Dumper;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                htmlwidth     =>'10px',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'ActionID',
                dataobjattr   =>'wfaction.wfactionid'),
                                  
      new kernel::Field::Link(
                name          =>'ascid',        # only for other ordering
                label         =>'ActionID',  
                dataobjattr   =>'wfaction.wfactionid'),
                                  
      new kernel::Field::Text(
                name          =>'wfheadid',
                weblinkto     =>'base::workflow',
                weblinkon     =>['wfheadid'=>'id'],
                sqlorder      =>'none',
                label         =>'WorkflowID',
                dataobjattr   =>'wfaction.wfheadid'),

      new kernel::Field::Text(
                name          =>'wfname',
                vjointo       =>'base::workflow',
                vjoinon       =>['wfheadid'=>'id'],
                vjoindisp     =>'name',
                sqlorder      =>'none',
                searchable    =>'0',
                label         =>'Workflow Name'),

      new kernel::Field::Text(
                name          =>'wfclass',
                vjointo       =>'base::workflow',
                vjoinon       =>['wfheadid'=>'id'],
                vjoindisp     =>'class',
                sqlorder      =>'none',
                htmldetail    =>'0',
                searchable    =>'0',
                label         =>'Workflow Class'),

      new kernel::Field::Text(
                name          =>'wfnature',
                vjointo       =>'base::workflow',
                vjoinon       =>['wfheadid'=>'id'],
                vjoindisp     =>'nature',
                sqlorder      =>'none',
                htmldetail    =>'0',
                searchable    =>'0',
                label         =>'Workflow Nature'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Action',
                sqlorder      =>'none',
                dataobjattr   =>'wfaction.name'),

      new kernel::Field::Text(
                name          =>'translation',
                label         =>'Translation Base',
                sqlorder      =>'none',
                dataobjattr   =>'wfaction.translation'),

      new kernel::Field::Select(
                name          =>'privatestate',
                group         =>'actiondata',
                sqlorder      =>'none',
                label         =>'Private State',
                transprefix   =>'privatestate.',
                value         =>['0','1'],
                dataobjattr   =>'wfaction.privatestate'),

      new kernel::Field::EffortNumber(
                name          =>'effort',
                sqlorder      =>'none',
                group         =>'booking',
                unit          =>'min',
                label         =>'Effort',
                dataobjattr   =>'wfaction.effort'),

      new kernel::Field::Date(
                name          =>'bookingdate',
                group         =>'booking',
                label         =>'Booking date',
                dataobjattr   =>'wfaction.bookingdate'),

      new kernel::Field::Textarea(
                name          =>'effortcomments',            # label for effort lists
                group         =>'actiondata',
                depend        =>['comments','effortlabel'],
                htmldetail    =>0,
                searchable    =>0,
                label         =>'effort description',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   return("$current->{effortlabel}:\n".$current->{comments});
                }),

      new kernel::Field::Text(
                name          =>'effortlabel',            # label for effort lists
                depend        =>['comments','wfheadid'],
                htmldetail    =>0,
                searchable    =>0,
                label         =>'effort label',
                dataobjattr   =>'wfhead.shortdescription'),

      new kernel::Field::Text(
                name          =>'creatorposix',            # posix id of creator contact
                depend        =>['creatorid'],
                htmldetail    =>0,
                searchable    =>0,
                group         =>'source',
                label         =>'creator posix',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;

                   my $user=getModuleObject($self->getParent->Config,"base::user");
                   $user->SetFilter({userid=>\$current->{creatorid}});
                   my ($urec,$msg)=$user->getOnlyFirst(qw(posix));

                   return($urec->{posix});
                }),

      new kernel::Field::Textarea(
                name          =>'comments',
                sqlorder      =>'none',
                group         =>'actiondata',
                label         =>'Comments',
                dataobjattr   =>'wfaction.comments'),

      new kernel::Field::Container(
                name        =>'additional',  # public 
                group       =>'additional',
                label       =>'Additional',  # informations
                uivisible   =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   return(1) if ($mode eq "ViewEditor");
                   my $rec=$param{current};
                   if (!defined($rec->{$self->Name()})){
                      return(0);
                   }
                   return(1);
                },
                dataobjattr =>'wfaction.additional'),

      new kernel::Field::Container(
                name        =>'actionref',   # secure
                group       =>'additional',
                label       =>'Action Ref',  # informations
                uivisible   =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   return(1) if ($self->getParent->IsMemberOf("admin"));
                   return(0);
                },
                dataobjattr =>'wfaction.actionref'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'wfaction.srcsys'),
                                  
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'wfaction.srcid'),
                                  
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'wfaction.srcload'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'wfaction.createuser'),

      new kernel::Field::Link(
                name          =>'creatorid',
                selectfix     =>1,
                label         =>'CreatorID',
                dataobjattr   =>'wfaction.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'wfaction.modifyuser'),

      new kernel::Field::MDate( 
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'wfaction.modifydate'),
                                  
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'wfaction.createdate'),
                                  
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'wfaction.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'wfaction.realeditor'),
   );
   $self->{history}=[qw(insert modify delete)];

   $self->setDefaultView(qw(id name editor comments mdate));
   $self->setWorktable("wfaction");
   return($self);
}


sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="$worktable left outer join wfhead ".
            "on $worktable.wfheadid=wfhead.wfheadid ";

   return($from);
}






sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $name=trim(effVal($oldrec,$newrec,"name"));
   if ($name eq ""){
      $self->LastMsg(ERROR,"invalid action '%s' specified",$name);
      return(0);
   }
   my $translation=trim(effVal($oldrec,$newrec,"translation"));
   if ($translation eq ""){
      $newrec->{translation}=$self->Self;
   }
   my $owner=trim(effVal($oldrec,$newrec,"owner"));
   if ($owner!=0){
      $newrec->{owner}=$owner;
   }
   $newrec->{name}=$name;

   if (!defined($oldrec) && $newrec->{bookingdate} eq ""){
      $newrec->{bookingdate}=NowStamp("en");
   }
   if (effVal($oldrec,$newrec,"bookingdate") eq ""){
      $newrec->{bookingdate}=NowStamp("en");
   }

   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my %param=@_;
   my $userid=$self->getCurrentUserId();

   return("ALL") if ($self->IsMemberOf(["admin",
                                        "workflow.manager",
                                        "workflow.admin"]));
   return("ALL") if ($rec->{creator}==$userid);
   return(undef) if ($param{resultname} eq "HistoryResult" &&
                     $rec->{privatestate}>=1);
   return("header","default","booking","actiondata","source");
   # eine Analyse des betreffenden Workflows, ob "booking" sichtbar gemacht
   # werden darf, w�re an dieser Stelle zu aufwendig. Es existiert also ein
   # gap, dass man nativ die Workflow-Action-Efforts aller User auflisten 
   # k�nnte (per deeplink)
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my %param=@_;
   return("default","actiondata","booking") if ($self->IsMemberOf(["admin",
                                        "workflow.admin"]));
   if (defined($rec) && $rec->{wfheadid}>0){
      my $wf=$self->getPersistentModuleObject("wf","base::workflow");
      $wf->ResetFilter();
      $wf->SetFilter({id=>\$rec->{wfheadid}});
      my ($WfRec,$msg)=$wf->getOnlyFirst(qw(ALL));

      if (defined($WfRec)){
         return(undef) if ($WfRec->{stateid}>=20);
         my $userid=$self->getCurrentUserId();
         if (defined($rec) && $userid == $rec->{creatorid} &&
             $rec->{cdate} ne ""){
            my $d=CalcDateDuration($rec->{cdate},NowStamp("en"));
            if ($d->{totalminutes}<5000){ # modify only allowed for 3 days
               return("actiondata","booking");
            }
         }
         my @grps=$wf->isWriteValid($WfRec,%param);
         return("actiondata") if (grep(/^ALL$/,@grps) ||
                                  grep(/^actions$/,@grps) ||
                                  grep(/^flow$/,@grps));
      }
   }
   return(undef);
}

sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;

   return(1) if ($self->IsMemberOf(["admin","workflow.admin"]));
   return(0);
}

sub StoreRecord
{
   my $self=shift;
   my $wfheadid=shift;
   my $name=shift;
   my $data=shift;
   my $comments=shift;
   my $effort=shift;

   my %rec=%{$data};
   $rec{wfheadid}=$wfheadid;
   $rec{name}=$name;
   $rec{comments}=$comments;
   $rec{effort}=$effort if (defined($effort) && $effort!=0);
   return($self->ValidatedInsertRecord(\%rec));
}

sub NotifyForward
{
   my $self=shift;
   my $wfheadid=shift;
   my $fwdtarget=shift;
   my $fwdtargetid=shift;
   my $fwdname=shift;
   my $comments=shift;
   my %param=@_;

   $param{mode}="FW:" if (!defined($param{mode}));  # default ist forward

   #printf STDERR ("fifi param=%s\n",Dumper(\%param));
   my $wf=getModuleObject($self->Config,"base::workflow");
   my $from='no_reply@w5base.net';
   my @to=();
   my $UserCache=$self->Cache->{User}->{Cache};
   if (defined($UserCache->{$ENV{REMOTE_USER}})){
      $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
   }
   if (defined($UserCache->{email}) &&
       $UserCache->{email} ne ""){
      $from=$UserCache->{email};
   }
   msg(INFO,"forward: search in $fwdtarget id $fwdtargetid");
   if ($fwdtarget eq "base::user"){
      my $u=getModuleObject($self->Config,"base::user");
      $u->SetFilter(userid=>\$fwdtargetid);
      my ($rec,$msg)=$u->getOnlyFirst(qw(email));
      if (defined($rec)){
         push(@to,$rec->{email});
      }
   }
   if ($fwdtarget eq "base::grp"){
      my $grp=$self->{grp};
      if (!defined($grp)){
         $grp=getModuleObject($self->Config,"base::grp");
         $self->{grp}=$grp;
      }
      $grp->ResetFilter();
      if ($fwdtargetid ne ""){ 
         $grp->SetFilter(grpid=>\$fwdtargetid);
      }
      else{
         $grp->SetFilter(fullname=>\$fwdname);
      }
      my @acl=$grp->getHashList(qw(grpid users));
      my %u=();
      #msg(INFO,"d=%s",Dumper(\@acl));
      foreach my $grprec (@acl){
      #msg(INFO,"d=%s %s",ref($grprec->{users}),Dumper($grprec));
         if (defined($grprec->{users}) && ref($grprec->{users}) eq "ARRAY"){
            foreach my $usr (@{$grprec->{users}}){
               $u{$usr->{email}}=1;
            }
         }
      }
      @to=keys(%u);
   }
   if (defined($param{addtarget}) && ref($param{addtarget}) eq "ARRAY"){
      my $u=getModuleObject($self->Config,"base::user");
      foreach my $uid (@{$param{addtarget}}){
         $u->ResetFilter();
         $u->SetFilter(userid=>\$uid);
         my ($rec,$msg)=$u->getOnlyFirst(qw(email));
         if (defined($rec) && $rec->{email} ne ""){
            push(@to,$rec->{email});
         }
      }
   }
   my $wf=$self->{workflow};
   if (!defined($wf)){
      $wf=getModuleObject($self->Config,"base::workflow");
      $self->{workflow}=$wf;
   }
   my $subject=$self->Config->Param("SITENAME");
   $subject.=" " if ($subject ne "");
   $subject.=$self->T($param{mode});
   if (defined($param{forcesubject})){
      $subject.=" " if ($subject ne "");
      $subject.=$param{forcesubject};
   }
   else{
      my ($wfrec,$msg)=$wf->getOnlyFirst({id=>\$wfheadid},qw(name));
      if (defined($wfrec)){
         $subject.=" " if ($subject ne "" && $wfrec->{name} ne "");
         $subject.=$wfrec->{name};
      }
   }

   msg(INFO,"forward subject: %s",$subject);
   msg(INFO,"forward    wfid: %s",$wfheadid);
   msg(INFO,"forward    from: %s",$from);
   msg(INFO,"forward      to: %s",join(", ",@to));
   msg(INFO,"forward comment: %s",$comments);
   if ($#to==-1){
      msg(ERROR,"no mail send, because there is no target found");
      return;
   }
   my $workflowname="$wfheadid";
   if (defined($param{workflowname})){
      $workflowname="'".$param{workflowname}." ID:".$wfheadid."'";
   }
   if ($comments=~m/^\s*$/){
      if ($param{mode} eq "FW:"){
         $comments=sprintf($self->T(
           'The Workflow %s has been forwared to you without comments').".",
           $workflowname);
      }
      elsif ($param{mode} eq "APRREQ:"){
         $comments=sprintf($self->T(
           'An approve for Workflow %s has been requested to you without comments').".",
           $workflowname);
      }
   }
   else{
      if ($param{mode} eq "FW:"){
         $comments.="\n\n".sprintf($self->T(
           'The Workflow %s has been forwared to you').".",$workflowname);
      }
      elsif ($param{mode} eq "APRREQ:"){
         $comments.="\n\n".sprintf($self->T(
           'An approve for Workflow %s has been requested to you').".",
           $workflowname);
      }
   }
   my $baseurl;
   if ($ENV{SCRIPT_URI} ne ""){
      $baseurl=$ENV{SCRIPT_URI};
      $baseurl=~s/\/auth\/.*$//;
      my $url=$baseurl;
      $url.="/auth/base/workflow/ById/".$wfheadid;
      $comments.="\n\n\n".$self->T("Edit").":\n";
      $comments.=$url;
      $comments.="\n\n";
   }
   else{
      my $baseurl=$self->Config->Param("EventJobBaseUrl");
      $baseurl.="/" if (!($baseurl=~m/\/$/));
      my $url=$baseurl;
      $url.="auth/base/workflow/ById/".$wfheadid;
      $comments.="\n\n\n".$self->T("Edit").":\n";
      $comments.=$url;
      $comments.="\n\n";
   }
   my %adr=(emailfrom=>$from,
            emailto  =>\@to);

   if ($param{sendercc} && $from ne 'no_reply@w5base.net'){
      $adr{emailcc}=[$from];
   }
   if (defined($param{sendcc})){
      $param{sendcc}=[$param{sendcc}] if (ref($param{sendcc}) ne "ARRAY");
      $adr{emailcc}=[] if (!defined($adr{emailcc}));
      push(@{$adr{emailcc}},@{$param{sendcc}});
   }
   my $emailpostfix="";
   if ($baseurl ne ""){
      my $lang=$self->Lang();
      $lang="?HTTP_ACCEPT_LANGUAGE=$lang";
      my $imgtitle="current state of workflow";
      $emailpostfix="<img title=\"$imgtitle\" class=status border=0 ".
             "src=\"$baseurl/public/base/workflow/ShowState/$wfheadid$lang\">";
   }

   if (my $id=$wf->Store(undef,{
           class    =>'base::workflow::mailsend',
           step     =>'base::workflow::mailsend::dataload',
           directlnktype =>'base::workflow',
           directlnkid   =>$wfheadid,
           directlnkmode =>"mail.".$param{mode},
           name     =>$subject,%adr,
           emailhead=>$self->T("LABEL:".$param{mode}).":",
           emailpostfix=>$emailpostfix,
           emailtext=>$comments,
          })){
      my %d=(step=>'base::workflow::mailsend::waitforspool');
      my $r=$wf->Store($id,%d);
   }
}

sub Notify
{
   my $self=shift;
   my $mode=shift;   # INFO | WARN | ERROR
   my $subject=shift;
   my $text=shift;
   my %param=@_;

   my $sitename=$self->Config->Param("SiteName");
   $sitename="W5Base" if ($sitename eq "");


   my $wf=getModuleObject($self->Config,"base::workflow");
   my $name;
   if ($mode ne ""){
      $name=$sitename.": ".$mode.": ".$subject;
   }
   else{
      $name=$subject;
   }
   my %mailset=(class    =>'base::workflow::mailsend',
                step     =>'base::workflow::mailsend::dataload',
                name     =>$name,
                emailtext=>$text);

   foreach my $target (qw(emailfrom emailto emailcc emailbcc)){
      if (exists($param{$target})){
         if (ref($param{$target}) ne "ARRAY"){
            $param{$target}=[split(/[;,]/,$param{$target})];
         }
      }
   }
   if ($param{adminbcc}){
      $param{emailbcc}=[] if (!defined($param{emailbcc}));
      my $grpuser=getModuleObject($self->Config,"base::lnkgrpuser");
      $grpuser->SetFilter({grpid=>\'1'});
      foreach my $lnkrec ($grpuser->getHashList(qw(userid roles))){
         if (ref($lnkrec->{roles}) eq "ARRAY"){
            if (grep(/^(RMember)$/,@{$lnkrec->{roles}})){
               push(@{$param{emailbcc}},$lnkrec->{userid});
            }
         }
      }

   }
   my $user=getModuleObject($self->Config,"base::user");
   foreach my $target (qw(emailfrom emailto emailcc emailbcc)){
      if (exists($param{$target})){
         for(my $c=0;$c<=$#{$param{$target}};$c++){
            if ($param{$target}->[$c]=~m/^\d{10,20}$/){  # target is a userid
               $user->ResetFilter();
               $user->SetFilter({userid=>\$param{$target}->[$c],
                                 cistatusid=>"<6"});
               my ($urec)=$user->getOnlyFirst(qw(email));
               if (defined($urec)){
                  $param{$target}->[$c]=$urec->{email};
               }
               else{
                  $param{$target}->[$c]='"invalid ref($param{$target}->[$c])" '.
                                        '<null\@network>';
               }
            }
            elsif ($param{$target}->[$c]=~m/^[a-z0-9]{2,8}$/){ # target posixid
               $user->ResetFilter();
               $user->SetFilter({posix=>\$param{$target}->[$c],
                                 cistatusid=>"<6"});
               my ($urec)=$user->getOnlyFirst(qw(email));
               if (defined($urec)){
                  $param{$target}->[$c]=$urec->{email};
               }
               else{
                  $param{$target}->[$c]='"invalid ref($param{$target}->[$c])" '.
                                        '<null\@network>';
               }
            }
            else{  # target is already a email address
               my $x;
            }
         }
      }
   }
   foreach my $target (qw(emailto emailcc emailbcc)){
      if (exists($param{$target})){
         $mailset{$target}=$param{$target};
      }
   }
   if (!exists($param{emailfrom})){
      $mailset{emailfrom}="\"W5Base-Notify\" <none\@null.com>";
   }
   else{
      $mailset{emailfrom}=$param{emailfrom};
   }

   if (my $id=$wf->Store(undef,\%mailset)){
      my %d=(step=>'base::workflow::mailsend::waitforspool');
      my $r=$wf->Store($id,%d);
   }
}


sub getEffortSelect
{
   my $self=shift;
   my $name=shift;

   my @t=(''=>'',
          '10'=>'10 min',
          '20'=>'20 min',
          '30'=>'30 min',
          '40'=>'40 min',
          '50'=>'50 min',
          '60'=>'1 h',
          '90'=>'1,5 h',
          '120'=>'2 h',
          '150'=>'2,5 h',
          '180'=>'3 h',
          '210'=>'3,5 h',
          '240'=>'4 h',
          '300'=>'5 h',
          '360'=>'6 h',
          '420'=>'7 h',
          '480'=>'1 day',
          '720'=>'1,5 days',
          '960'=>'2 days');

   my $d="<select name=\"$name\" style=\"width:80px\">";
   my $oldval=Query->Param("Formated_effort");
   while(defined(my $min=shift(@t))){
      my $l=shift(@t);
      $d.="<option value=\"$min\"";
      $d.=" selected" if ($min==$oldval);
      $d.=">$l</option>";
   }
   $d.="</select>";
   return($d);

}

sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   if ($newrec->{name} eq "forwardto" || $newrec->{name} eq "reactivate"){
      my %add=Datafield2Hash($newrec->{additional});
      my $fwdtarget=$add{ForwardTarget}->[0];
      my $fwdtargetid=$add{ForwardTargetId}->[0];
      my $fwdname=$add{ForwardToName}->[0];
      my $comments=$newrec->{comments};
      my $wfid=$newrec->{wfheadid};
      if ($fwdtarget ne "" && $fwdtargetid ne ""){
         $self->NotifyForward($wfid,$fwdtarget,$fwdtargetid,$fwdname,$comments);
      }
   }

   return($self->SUPER::FinishWrite($oldrec,$newrec));
}

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","actiondata","booking","default","additional","source");
}


package kernel::Field::EffortNumber;

use strict;
use vars qw(@ISA);
@ISA=qw(kernel::Field::Number);

sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}

sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $FormatAs=shift;
   return(undef) if ($FormatAs eq "SOAP" ||
                     $FormatAs eq "XMLV01"); # security !!!
   if ($FormatAs eq "HtmlDetail" || $FormatAs eq "edit"){
      return($self->SUPER::FormatedDetail($current,$FormatAs));
   } 
   my $userid=$self->getParent->getCurrentUserId();
   return(undef) if ($FormatAs ne "HtmlWfActionlog" && 
                     $userid ne $current->{creatorid}); # security !!!
   return($self->SUPER::FormatedDetail($current,$FormatAs));
}



1;
