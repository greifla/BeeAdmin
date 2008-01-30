package itil::lnkapplapplcomp;
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
      new kernel::Field::Id(
                name          =>'id',
                label         =>'InterfaceComponentID',
                dataobjattr   =>'lnkapplapplcomp.id'),

      new kernel::Field::Link(
                name          =>'lnkapplappl',
                label         =>'Interface ID',
                dataobjattr   =>'lnkapplapplcomp.lnkapplappl'),

      new kernel::Field::Link(
                name          =>'sortkey',
                label         =>'SortKey',
                dataobjattr   =>'lnkapplapplcomp.sortkey'),

      new kernel::Field::Select(
                name          =>'objtype',
                label         =>'Component type',
                getPostibleValues=>sub{
                   my $self=shift;
                   return('itil::system'=>
                           $self->getParent->T('itil::system','itil::system'));
                },
                dataobjattr   =>'lnkapplapplcomp.objtype'),

      new kernel::Field::MultiDst (
                name          =>'name',
                htmlwidth     =>'200',
                selectwidth   =>'400',
                selectivetyp  =>1,
                dst           =>['itil::system' =>'name',
                                 'itil::appl'=>'name'],
                vjoineditbase =>[{'cistatusid'=>"<5"},
                                 {'cistatusid'=>"<5"}],
                label         =>'Component',
                dsttypfield   =>'objtype',
                dstidfield    =>'obj1id'),

      new kernel::Field::Link(
                name          =>'obj1id',
                label         =>'Object1 ID',
                dataobjattr   =>'lnkapplapplcomp.obj1id'),

      new kernel::Field::MultiDst (
                name          =>'namealt1',
                htmlwidth     =>'200',
                selectwidth   =>'400',
                selectivetyp  =>1,
                dst           =>['itil::system' =>'name',
                                 'itil::appl'=>'name'],
                vjoineditbase =>[{'cistatusid'=>"<5"},
                                 {'cistatusid'=>"<5"}],
                label         =>'Redundance 1',
                dsttypfield   =>'objtype',
                dstidfield    =>'obj2id'),

      new kernel::Field::Link(
                name          =>'obj2id',
                label         =>'Object2 ID',
                dataobjattr   =>'lnkapplapplcomp.obj2id'),

      new kernel::Field::MultiDst (
                name          =>'namealt2',
                htmlwidth     =>'200',
                selectwidth   =>'400',
                selectivetyp  =>1,
                dst           =>['itil::system' =>'name',
                                 'itil::appl'=>'name'],
                vjoineditbase =>[{'cistatusid'=>"<5"},
                                 {'cistatusid'=>"<5"}],
                label         =>'Redundance 2',
                dsttypfield   =>'objtype',
                dstidfield    =>'obj3id'),

      new kernel::Field::Link(
                name          =>'obj3id',
                label         =>'Object3 ID',
                dataobjattr   =>'lnkapplapplcomp.obj3id'),

      new kernel::Field::Text(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'lnkapplapplcomp.comments'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnkapplapplcomp.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'lnkapplapplcomp.modifyuser'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnkapplapplcomp.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnkapplapplcomp.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'lnkapplapplcomp.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkapplapplcomp.createdate'),
                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkapplapplcomp.modifydate'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'lnkapplapplcomp.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'lnkapplapplcomp.realeditor'),
   );
   $self->setDefaultView(qw(id fromappl toappl cdate editor));
   $self->setWorktable("lnkapplapplcomp");
   return($self);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   if (!$self->checkWriteValid($oldrec,$newrec)){
      $self->LastMsg(ERROR,"no access");
      return(0);
   }

   return(1);
}

sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(1);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   #return(undef);
   return("default") if (!defined($rec));
   return("default") if ($self->checkWriteValid($rec));
   return(undef);
}

sub checkWriteValid
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $lnkapplappl=effVal($oldrec,$newrec,"lnkapplappl");

   return(undef) if ($lnkapplappl eq "");

   my $lnkobj=getModuleObject($self->Config,"itil::lnkapplappl");
   if ($lnkobj){
      $lnkobj->SetFilter(id=>\$lnkapplappl);
      my ($aclrec,$msg)=$lnkobj->getOnlyFirst(qw(ALL)); 
      if (defined($aclrec)){
         my @grplist=$lnkobj->isWriteValid($aclrec);
         if (grep(/^interfacescomp$/,@grplist) ||
             grep(/^ALL$/,@grplist)){
            return(1);
         }
      }
      return(0);
   }

   return(1);
}






1;
