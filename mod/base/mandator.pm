package base::mandator;
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
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'mandator.id'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Mandator',
                dataobjattr   =>'mandator.name'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'mandator.cistatus'),

      new kernel::Field::TextDrop(
                name          =>'groupname',
                label         =>'Groupname',
                vjointo       =>'base::grp',
                vjoinon       =>['grpid'=>'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'grpid',
                dataobjattr   =>'mandator.grpid'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'mandator.comments'),

      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                class         =>'mandator',
                vjoininhash   =>['targetid','target','roles'],
                group         =>'contacts'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'mandator.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'mandator.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'mandator.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'mandator.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'mandator.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'mandator.realeditor'),

      new kernel::Field::Container(
                name       =>'additional',
                dataobjattr=>'mandator.additional'),

   );
   $self->setDefaultView(qw(linenumber name groupname cistatus cdate mdate));
   $self->setWorktable("mandator");
   return($self);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/mandator.jpg?".$cgi->query_string());
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $name=trim(effVal($oldrec,$newrec,"name"));
   if ($name=~m/[^a-z0-9 _-]/i){
      $self->LastMsg(ERROR,"invalid mandator '%s' specified",$name); 
      return(undef);
   }
   $newrec->{'name'}=$name;
   my $grpid=trim(effVal($oldrec,$newrec,"grpid"));
   if ($grpid==0){
      $self->LastMsg(ERROR,"invalid group"); 
      return(undef);
   }
   return(1);
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
   return("default","contacts") if ($self->IsMemberOf("admin"));
   return(undef);
}


sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $bak=$self->SUPER::FinishWrite($oldrec,$newrec);
   $self->InvalidateMandatorCache();
   return($bak);
}


sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;
   my $bak=$self->SUPER::FinishDelete($oldrec);

   $self->InvalidateMandatorCache();
   return($bak);
}




1;
