package itil::mgmtitemgroup;
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
use itil::lib::Listedit;
@ISA=qw(itil::lib::Listedit);

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
                dataobjattr   =>'mgmtitemgroup.id'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                htmlwidth     =>'180px',
                label         =>'Name',
                dataobjattr   =>'mgmtitemgroup.name'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'mgmtitemgroup.cistatus'),

      new kernel::Field::Databoss(
                group         =>'comments'),

      new kernel::Field::Link(
                name          =>'databossid',
                group         =>'comments',
                dataobjattr   =>'mgmtitemgroup.databoss'),

      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'comments',
                label         =>'Comments',
                dataobjattr   =>'mgmtitemgroup.comments'),

      new kernel::Field::SubList(
                name          =>'applications',
                label         =>'applications',
                group         =>'applications',
                subeditmsk    =>'subedit.applications',
                forwardSearch =>1,
                vjointo       =>'itil::lnkmgmtitemgroup',
                vjoinbase     =>[{lnkto=>">now-24h OR [EMPTY]",
                                  applid=>"![EMPTY]"}],
                vjoinon       =>['id'=>'mgmtitemgroupid'],
                vjoindisp     =>['appl','lnkfrom','lnkto']),

      new kernel::Field::SubList(
                name          =>'locations',
                label         =>'locations',
                group         =>'locations',
                subeditmsk    =>'subedit.locations',
                forwardSearch =>1,
                vjointo       =>'itil::lnkmgmtitemgroup',
                vjoinbase     =>[{lnkto=>">now-24h OR [EMPTY]",
                                  locationid=>"![EMPTY]"}],
                vjoinon       =>['id'=>'mgmtitemgroupid'],
                vjoindisp     =>['location','lnkfrom','lnkto']),


      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                vjoinbase     =>[{'parentobj'=>\'itil::mgmtitemgroup'}],
                vjoininhash   =>['targetid','target','roles'],
                group         =>'contacts'),


#      new kernel::Field::Container(
#                name          =>'additional',
#                label         =>'Additionalinformations',
#                uivisible     =>sub{
#                   my $self=shift;
#                   my $mode=shift;
#                   my %param=@_;
#                   my $rec=$param{current};
#                   if (!defined($rec->{$self->Name()})){
#                      return(0);
#                   }
#                   return(1);
#                },
#                dataobjattr   =>'mgmtitemgroup.additional'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'mgmtitemgroup.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'mgmtitemgroup.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'mgmtitemgroup.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'mgmtitemgroup.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'mgmtitemgroup.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'mgmtitemgroup.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'mgmtitemgroup.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'mgmtitemgroup.editor'),

      new kernel::Field::RealEditor( 
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'mgmtitemgroup.realeditor'),
   

   );
   $self->{history}=[qw(insert modify delete)];
   $self->setDefaultView(qw(name cistatus cdate mdate));
   $self->setWorktable("mgmtitemgroup");
   $self->{CI_Handling}={uniquename=>"name",
                         activator=>["admin","admin.itil.mgmtitemgroup"],
                         uniquesize=>255};
   return($self);
}


#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/mgmtitemgroup.jpg?".$cgi->query_string());
#}

sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $wrgroups=shift;

   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   return($self->SUPER::SecureValidate($oldrec,$newrec,$wrgroups));
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default comments applications locations contacts source));
}





sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (!defined($oldrec) || defined($newrec->{name})){
      if ($newrec->{name}=~m/^\s*$/ || !($newrec->{name}=~m/^[a-z0-9-]+$/i)){
         $self->LastMsg(ERROR,"invalid name specified");
         return(0);
      }
   }
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
   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   return(1);
}


sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   return(1);
}



sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   my $userid=$self->getCurrentUserId();
   return("default") if (!defined($rec));


   my $databossedit=0;
   if ($self->IsMemberOf($self->{CI_Handling}->{activator})){
      return("default","comments","applications","locations","contacts");
   }
   if ($self->IsMemberOf("admin")){
      return("default","comments","applications","locations","contacts");
   }

   my @databossgrp=("comments","contacts","applications","locations");

   if ($rec->{cistatusid}<3){
      push(@databossgrp,"default");
   }

   if ($rec->{databossid}==$userid){
      $databossedit++;
   }
   elsif (defined($rec->{contacts}) && ref($rec->{contacts}) eq "ARRAY"){
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
            $databossedit++;
         }
      }
   }
   return(@databossgrp) if ($databossedit);

   return(undef);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}



1;
