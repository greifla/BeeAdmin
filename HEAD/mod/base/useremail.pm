package base::useremail;
#  W5Base Framework
#  Copyright (C) 2013  Hartmut Vogler (it@guru.de)
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
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

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
                label         =>'E-Mail ID',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   return(0) if (!defined($param{current}));
                   return(1);
                },
                align         =>'left',
                htmlwidth     =>'250',
                dataobjattr   =>'contact.userid'),
                                  
      new kernel::Field::Email(
                name          =>'email',
                label         =>'E-Mail',
                readonly      =>0,
                searchable    =>1,
                align         =>'left',
                htmlwidth     =>'250',
                dataobjattr   =>'contact.email'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjointo       =>'base::cistatus',
                vjoineditbase =>{id=>">0"},
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'contact.cistatus'),

      new kernel::Field::TextDrop(
                name          =>'contactfullname',
                label         =>'Contact',
                vjointo       =>'base::user',
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>'fullname'),
                                  
      new kernel::Field::Link(
                name          =>'userid',
                label         =>'UserID',
                wrdataobjattr =>'contact.pcontact',
                dataobjattr   =>"contact.pcontact"),
                                  
      new kernel::Field::Text(
                name          =>'emailtyp',
                readonly      =>1,
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   return(0) if (!defined($param{current}));
                   return(1);
                },
                label         =>'Type',
                dataobjattr   =>"if (contact.usertyp='altemail',".
                                "'alternate','primary')"),
                                  
      new kernel::Field::Text(
                name          =>'surname',
                label         =>'Surname',
                htmldetail    =>0,
                vjointo       =>'base::user',
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>'surname'),
                                  
      new kernel::Field::Link(
                name          =>'usertyp',
                dataobjattr   =>"contact.usertyp"),
                                  
      new kernel::Field::Link(
                name          =>'fullname',
                dataobjattr   =>"contact.fullname"),
                                  
      new kernel::Field::Text(
                name          =>'givenname',
                label         =>'Givenname',
                htmldetail    =>0,
                vjointo       =>'base::user',
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>'givenname'),
                                  
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'contact.createdate'),

      new kernel::Field::MDate(
                name          =>'mdate',
                label         =>'Modification-Date',
                group         =>'source',
                dataobjattr   =>'contact.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'contact.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'contact.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'contact.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'contact.realeditor'),
                                  
   );
   $self->setWorktable("contact");
   $self->setDefaultView(qw(email cistatus emailtyp contactfullname));
   return($self);
}

sub allowHtmlFullList
{
   my $self=shift;
   return(0) if ($self->getCurrentSecState()<4);
   return(1);
}

sub allowFurtherOutput
{
   my $self=shift;
   return(0) if ($self->getCurrentSecState()<4);
   return(1);
}

sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @filter=@_;

   my ($worktable,$workdb)=$self->getWorktable();

   my $precision0="";
   my $precision1="";
   if ($mode eq "select"){
      foreach my $filter (@filter){
         if (ref($filter) eq "HASH" && defined($filter->{userid})){
            if (!ref($filter->{userid})){
               $precision0.="and pcontact='$filter->{userid}' ";
               $precision1.="and userid='$filter->{userid}' ";
            }
         }
      }
   }

   my $from="(".
            "select  email, cistatus, userid,pcontact, usertyp,".
            "        fullname, createdate, modifydate, createuser, modifyuser,".
            "        editor, realeditor ".
            "from contact as a where usertyp='altemail' ".$precision0.
            " union ".
            "select  email, cistatus, userid,userid pcontact, usertyp,".
            "        fullname, createdate, modifydate, createuser, modifyuser,".
            "        editor, realeditor ".
            "from contact as b where usertyp<>'altemail' ".$precision1.
            ") as contact";

   return($from);
}



sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   $newrec->{fullname}='- ('.effVal($oldrec,$newrec,"email").")";
   $newrec->{usertyp}='altemail';
   if (effVal($oldrec,$newrec,"userid") eq ""){
      $self->LastMsg(ERROR,"none or invalid contact specified");
      return(0);
   }
   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return(qw(default header)) if (!defined($rec));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef) if ($rec->{emailtyp} eq "primary");
   return("default") if ($self->IsMemberOf("admin"));
   return(undef);
}

1;
