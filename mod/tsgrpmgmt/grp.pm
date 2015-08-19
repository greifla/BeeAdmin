package tsgrpmgmt::grp;
#  W5Base Framework
#  Copyright (C) 2015  Hartmut Vogler (it@guru.de)
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
use kernel::CIStatusTools;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB 
        kernel::CIStatusTools);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=3 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{use_distinct}=0;

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'metagrpmgmt.id'),
                                                  
      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Fullname',
                dataobjattr   =>'metagrpmgmt.fullname'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                dataobjattr   =>'metagrpmgmt.name'),

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
                dataobjattr   =>'metagrpmgmt.cistatus'),

      new kernel::Field::Date(
                name          =>'chkdate',
                history       =>0,
                sqlorder      =>'asc',
                group         =>'chk',
                label         =>'last check date',
                dataobjattr   =>'metagrpmgmt.chkdate'),

      new kernel::Field::Text(
                name          =>'smid',
                group         =>'ref',
                label         =>'GroupID in ServiceManager',
                dataobjattr   =>'metagrpmgmt.smid'),

      new kernel::Field::Date(
                name          =>'smdate',
                group         =>'ref',
                label         =>'Group seen in ServiceManager',
                dataobjattr   =>'metagrpmgmt.smdate'),

      new kernel::Field::Text(
                name          =>'amid',
                group         =>'ref',
                label         =>'GroupID in AssetManager',
                dataobjattr   =>'metagrpmgmt.amid'),

      new kernel::Field::Date(
                name          =>'amdate',
                group         =>'ref',
                label         =>'Group seen in AssetManager',
                dataobjattr   =>'metagrpmgmt.amdate'),

      new kernel::Field::Text(
                name          =>'scid',
                group         =>'ref',
                label         =>'GroupID in ServiceCenter',
                dataobjattr   =>'metagrpmgmt.scid'),

      new kernel::Field::Date(
                name          =>'scdate',
                group         =>'ref',
                label         =>'Group seen in ServiceCenter',
                dataobjattr   =>'metagrpmgmt.scdate'),

      new kernel::Field::Boolean(
                name          =>'ischmapprov',
                label         =>'is change approver group',
                ignorecase    =>1,
                group         =>'grouptype',
                htmlhalfwidth =>1,
                dataobjattr   =>'is_chmapprov'),

      new kernel::Field::Boolean(
                name          =>'isinmassign',
                label         =>'is incident assinment group',
                ignorecase    =>1,
                group         =>'grouptype',
                htmlhalfwidth =>1,
                dataobjattr   =>'is_inmassign'),

      new kernel::Field::Boolean(
                name          =>'iscfmassign',
                label         =>'is config assinment group',
                ignorecase    =>1,
                group         =>'grouptype',
                htmlhalfwidth =>1,
                dataobjattr   =>'is_cfmassign'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                group         =>'chk',
                searchable    =>0,
                dataobjattr   =>'metagrpmgmt.comments'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'metagrpmgmt.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'metagrpmgmt.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'metagrpmgmt.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'metagrpmgmt.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'metagrpmgmt.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'metagrpmgmt.realeditor'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'metagrpmgmt.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'metagrpmgmt.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                history       =>0,
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'metagrpmgmt.srcload'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"metagrpmgmt.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(metagrpmgmt.id,35,'0')"),

   );
   $self->setDefaultView(qw(linenumber fullname mdate));
   $self->setWorktable("metagrpmgmt");
   return($self);
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}

sub getDetailBlockPriority                # posibility to change the block order
{
   my $self=shift;
   return(qw(header default grouptype ref chk source));
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $fullname=effVal($oldrec,$newrec,"fullname");
   my $name=$fullname;
   $name=~s/^.*\.//;
   $name=~s/\[.*$//;
   if (effVal($oldrec,$newrec,"name") ne $name){
      $newrec->{name}=$name;
   }

   return(0) if (!$self->HandleCIStatusModification($oldrec,$newrec,
                                                    "fullname"));
   return(1);
}

sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $bak=$self->SUPER::FinishWrite($oldrec,$newrec);
   $self->NotifyOnCIStatusChange($oldrec,$newrec);
   return($bak);
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec) && $self->IsMemberOf("admin"));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if ($self->IsMemberOf("admin"));
   return(undef);
}


sub isCopyValid
{
   my $self=shift;
   my $copyfrom=shift;
   return(1);
}






1;
