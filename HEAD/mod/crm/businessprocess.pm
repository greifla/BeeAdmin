package crm::businessprocess;
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
use kernel::MandatorDataACL;
use crm::lib::Listedit;
@ISA=qw(crm::lib::Listedit kernel::MandatorDataACL);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'businessprocess.id'),

      new kernel::Field::Mandator(),

      new kernel::Field::Link(
                name          =>'mandatorid',
                dataobjattr   =>'businessprocess.mandator'),

     new kernel::Field::TextDrop(
                name          =>'customer',
                label         =>'Customer',
                vjointo       =>'base::grp',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['customerid'=>'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'customerid',
                dataobjattr   =>'businessprocess.customer'),
   
      new kernel::Field::Text(
                name          =>'name',
                htmlwidth     =>'250px',
                label         =>'Shortname',
                dataobjattr   =>'businessprocess.name'),

      new kernel::Field::Text(
                name          =>'fullname',
                htmlwidth     =>'250px',
                label         =>'Name',
                dataobjattr   =>'businessprocess.fullname'),

      new kernel::Field::Text(
                name          =>'selector',
                htmlwidth     =>'550px',
                readonly      =>1,
                htmldetail    =>0,
                label         =>'Selector',
                dataobjattr   =>'concat(businessprocess.name,"@",'.
                                'customer.fullname)'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmlwidth     =>'50px',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'businessprocess.cistatus'),

      new kernel::Field::TextDrop(
                name          =>'databoss',
                label         =>'Databoss',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['databossid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'databossid',
                dataobjattr   =>'businessprocess.databoss'),

      new kernel::Field::Contact(
                name          =>'processowner',
                group         =>'procdesc',
                AllowEmpty    =>1,
                vjoineditbase =>{'cistatusid'=>[3,4],
                                 'usertyp'=>[qw(user extern)]},
                label         =>'Process Owner',
                vjoinon       =>'processownerid'),

      new kernel::Field::Link(
                name          =>'processownerid',
                dataobjattr   =>'businessprocess.processowner'),

      new kernel::Field::Contact(
                name          =>'processowner2',
                group         =>'procdesc',
                AllowEmpty    =>1,
                vjoineditbase =>{'cistatusid'=>[3,4],
                                 'usertyp'=>[qw(user extern)]},
                label         =>'Deputy Process Owner',
                vjoinon       =>'processowner2id'),

      new kernel::Field::Link(
                name          =>'processowner2id',
                dataobjattr   =>'businessprocess.processowner2'),

      new kernel::Field::Select(
                name          =>'customerprio',
                group         =>'procdesc',
                label         =>'Customers Process Prioritiy',
                value         =>['1','2','3'],
                default       =>'2',
                htmleditwidth =>'50px',
                dataobjattr   =>'businessprocess.customerprio'),

      new kernel::Field::Select(
                name          =>'importance',
                group         =>'procdesc',
                transprefix   =>'im.',
                htmleditwidth =>'30%',
                label         =>'Importance',
                default       =>'3',
                value         =>[1,2,3,4,5],
                dataobjattr   =>'businessprocess.importance'),

      new kernel::Field::Textarea(
                name          =>'description',
                label         =>'Description',
                group         =>'procdesc',
                dataobjattr   =>'businessprocess.comments'),

      new kernel::Field::SubList(
                name          =>'acls',
                label         =>'Accesscontrol',
                subeditmsk    =>'subedit.businessprocess',
                group         =>'acl',
                allowcleanup  =>1,
                vjoininhash   =>[qw(acltarget acltargetid aclmode)],
                vjointo       =>'crm::businessprocessacl',
                vjoinbase     =>[{'aclparentobj'=>\'crm::businessprocess'}],
                vjoinon       =>['id'=>'refid'],
                vjoindisp     =>['acltargetname','aclmode']),

      new kernel::Field::Select(
                name          =>'eventlang',
                group         =>'misc',
                htmleditwidth =>'30%',
                value         =>['en','de','en-de','de-en'],
                label         =>'default language for eventinformations',
                dataobjattr   =>'businessprocess.eventlang'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                group         =>'misc',
                dataobjattr   =>'businessprocess.comments'),

      new kernel::Field::Container(
                name          =>'additional',
                label         =>'Additionalinformations',
                uivisible     =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   return(0);
                },
                dataobjattr   =>'businessprocess.additional'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'businessprocess.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'businessprocess.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'businessprocess.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'businessprocess.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'businessprocess.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'businessprocess.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'businessprocess.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'businessprocess.editor'),

      new kernel::Field::RealEditor( 
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'businessprocess.realeditor'),

      new kernel::Field::Link(
                name          =>'sectarget',
                noselect      =>'1',
                dataobjattr   =>'businessprocessacl.acltarget'),

      new kernel::Field::Link(
                name          =>'sectargetid',
                noselect      =>'1',
                dataobjattr   =>'businessprocessacl.acltargetid'),

      new kernel::Field::Link(
                name          =>'secroles',
                noselect      =>'1',
                dataobjattr   =>'businessprocessacl.aclmode'),

      new kernel::Field::Email(
                name          =>'wfdataeventnotifytargets',
                label         =>'WF:event notification customer info targets',
                htmldetail    =>0,
                searchable    =>0,
                uploadable    =>0,
                group         =>'workflowbasedata',
                onRawValue    =>\&getWfEventNotifyTargets),
 
   );
   $self->setDefaultView(qw(linenumber selector cistatus importance));
   $self->setWorktable("businessprocess");
   $self->{history}=[qw(insert modify delete)];
   $self->{workflowlink}={ workflowkey=>[id=>'affectedbusinessprocessid']
                         };
   $self->{use_distinct}=1;
   $self->{CI_Handling}={uniquename=>"name",
                         activator=>["admin","w5base.crm.businessprocess"],
                         uniquesize=>40};
   return($self);
}


sub getWfEventNotifyTargets     # calculates the target email addresses
{                               # for an customer information in
   my $self=shift;              # itil::workflow::eventnotify
   my $current=shift;
   my $emailto={};

   my $bpid=$current->{id};
   my $ia=getModuleObject($self->getParent->Config,"base::infoabo");
   my $bp=getModuleObject($self->getParent->Config,"crm::businessprocess");
   $bp->SetFilter({id=>\$bpid});


   my @byfunc;
   my @byorg;
   my @team;
   my %allcustgrp;
   foreach my $rec ($bp->getHashList(qw(processownerid processowner2id))){
      foreach my $v (qw(processownerid processowner2id)){
         my $fo=$bp->getField($v);
         my $userid=$bp->getField($v)->RawValue($rec);
         push(@byfunc,$userid) if ($userid ne "" && $userid>0);
      }
      if ($rec->{customerid}!=0){
         $self->getParent->LoadGroups(\%allcustgrp,"up",
                                      $rec->{customerid});
         
      }
   }
   if (keys(%allcustgrp)){
      $ia->LoadTargets($emailto,'base::grp',\'eventnotify',
                                [keys(%allcustgrp)]);
   }
   $ia->LoadTargets($emailto,'*::businessprocess',\'eventnotify',$bpid);
   $ia->LoadTargets($emailto,'base::staticinfoabo',\'eventnotify',
                             '100000002',\@byfunc,default=>1);

   return([sort(keys(%$emailto))]);
}

sub HandleInfoAboSubscribe
{
   my $self=shift;
   my $id=Query->Param("CurrentIdToEdit");
   my $ia=$self->getPersistentModuleObject("base::infoabo");
   if ($id ne ""){
      $self->ResetFilter();
      $self->SetFilter({id=>\$id});
      my ($rec,$msg)=$self->getOnlyFirst(qw(selector));
      print($ia->WinHandleInfoAboSubscribe({},
                      $self->SelfAsParentObject(),$id,$rec->{fullname},
                      "base::staticinfoabo",undef,undef));
   }
   else{
      print($self->noAccess());
   }
}






sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if ((!defined($oldrec) || defined($newrec->{name})) &&
       $newrec->{name}=~m/^\s*$/){
      $self->LastMsg(ERROR,"invalid name specified");
      return(0);
   }
   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }

   ########################################################################
   # standard security handling
   #
   if ($self->isDataInputFromUserFrontend() && !$self->IsMemberOf("admin")){
      my $userid=$self->getCurrentUserId();
      if (!defined($oldrec)){
         if (!defined($newrec->{databossid}) ||
             $newrec->{databossid}==0){
            my $userid=$self->getCurrentUserId();
            $newrec->{databossid}=$userid;
         }
      }
      if (defined($newrec->{databossid}) &&
          $newrec->{databossid}!=$userid &&
          $newrec->{databossid}!=$oldrec->{databossid}){
         $self->LastMsg(ERROR,"you are not authorized to set other persons ".
                              "as databoss");
         return(0);
      }
   }
   ########################################################################
   my $customerid=effVal($oldrec,$newrec,"customerid");
   if ($customerid==0){
      $self->LastMsg(ERROR,"invalid or no customer specified");
      return(0);
   }
   return(0) if (!$self->HandleCIStatusModification($oldrec,$newrec,"name"));

   return(1);
}


sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->isDirectFilter(@flt) &&
       !$self->IsMemberOf([qw(admin w5base.crm.businessprocess.read 
                              w5base.crm.read)],
                          "RMember")){
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
             [qw(REmployee RApprentice RFreelancer RBoss)],"both");
      my @grpids=keys(%grps);
      my $userid=$self->getCurrentUserId();
      push(@flt,[
                 {mandatorid=>\@mandators},
                 {databossid=>$userid},
                 {sectargetid=>\$userid,sectarget=>\'base::user',
                  secroles=>['write','read']},
                 {sectargetid=>\@grpids,sectarget=>\'base::grp',
                  secroles=>['write','read']}
                ]);
   }
   return($self->SetFilter(@flt));
}

sub SecureValidate
{
   return(kernel::DataObj::SecureValidate(@_));
}



sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $selfasparent=$self->SelfAsParentObject();
   my $from="$worktable left outer join businessprocessacl ".
            "on businessprocessacl.aclparentobj='$selfasparent' ".
            "and $worktable.id=businessprocessacl.refid ".
            "left outer join grp as customer on ".
            "customer.grpid=businessprocess.customer";

   return($from);
}  






sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/crm/load/businessprocess.jpg?".$cgi->query_string());
}




sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   my $userid=$self->getCurrentUserId();
   return("default","procdesc","misc","acl") if (!defined($rec) ||
                         ($rec->{cistatusid}<3 && $rec->{creator}==$userid) ||
                         $self->IsMemberOf($self->{CI_Handling}->{activator}));

   my @databossedit=qw(default procdesc misc acl);

   if ($rec->{databossid}==$userid ||
       $self->IsMemberOf($self->{CI_Handling}->{activator})){
      return($self->expandByDataACL($rec->{mandatorid},@databossedit));
   }

   if (defined($rec->{contacts}) && ref($rec->{contacts}) eq "ARRAY"){
      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
                                  ["RMember"],"both");
      my @grpids=keys(%grps);
      foreach my $contact (@{$rec->{contacts}}){
         if ($contact->{target} eq "base::user" &&
             $contact->{targetid} ne $userid){
            next;
         }
         if ($contact->{target} eq "base::grp"){
            my $grpid=$contact->{targetid};
            next if (!grep(/^$grpid$/,@grpids));
         }
         my @roles=($contact->{roles});
         @roles=@{$contact->{roles}} if (ref($contact->{roles}) eq "ARRAY");
         if (grep(/^write$/,@roles)){
            return($self->expandByDataACL($rec->{mandatorid},@databossedit));
         }
      }
   }
   return($self->expandByDataACL($rec->{mandatorid}));
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}

sub getDetailBlockPriority
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),
          qw(default procdesc acl misc source));
}

sub SelfAsParentObject
{
   my $self=shift;
   return("crm::businessprocess");
}


1;
