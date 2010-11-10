package itil::lnkitclustsvcappl;
#  W5Base Framework
#  Copyright (C) 2010  Hartmut Vogler (it@guru.de)
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
                label         =>'LinkID',
                searchable    =>0,
                dataobjattr   =>'lnkitclustsvcappl.id'),
                                                 
      new kernel::Field::TextDrop(
                name          =>'appl',
                label         =>'Application',
                xreadonly      =>1,
                vjointo       =>'itil::appl',
                vjoinon       =>['applid'=>'id'],
                vjoindisp     =>'name'),
                                                   
      new kernel::Field::TextDrop(
                name          =>'itclustsvc',
                label         =>'Cluster Service',
                xreadonly      =>1,
                vjointo       =>'itil::lnkitclustsvc',
                vjoinon       =>['itclustsvcid'=>'id'],
                vjoindisp     =>'fullname'),
                                                   
      new kernel::Field::Link(
                name          =>'applid',
                dataobjattr   =>'lnkitclustsvcappl.appl'),

      new kernel::Field::Link(
                name          =>'itclustid',
                dataobjattr   =>'lnkitclustsvcappl.itclust'),

      new kernel::Field::Link(
                name          =>'itclustsvcid',
                dataobjattr   =>'lnkitclustsvcappl.itclustsvc'),

      new kernel::Field::Text(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'lnkitclustsvcappl.comments'),

      new kernel::Field::Text(
                name          =>'applapplid',
                group         =>'applinfo',
                label         =>'ApplicationID',
                dataobjattr   =>'appl.applid'),

      new kernel::Field::Link(
                name          =>'itclustid',
                group         =>'itclustinfo',
                label         =>'IT-ClusterID',
                dataobjattr   =>'lnkitclustsvc.itclust'),

      new kernel::Field::Select(
                name          =>'applcistatus',
                group         =>'applinfo',
                label         =>'CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['applcistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'applcistatusid',
                group         =>'applinfo',
                label         =>'Application CI-StatusID',
                dataobjattr   =>'appl.cistatus'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnkitclustsvcappl.createuser'),
                                   
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'lnkitclustsvcappl.modifyuser'),
                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnkitclustsvcappl.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnkitclustsvcappl.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'lnkitclustsvcappl.srcload'),
                                                   
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkitclustsvcappl.createdate'),
                                                
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkitclustsvcappl.modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'lnkitclustsvcappl.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'lnkitclustsvcappl.realeditor'),

   );
   $self->{use_distinct}=1;
   $self->setDefaultView(qw(linenumber itclustsvc appl 
                             cdate));
   $self->setWorktable("lnkitclustsvcappl");
   return($self);
}

sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();

   return("$worktable left outer join appl on ".
          "$worktable.appl=appl.id ".
          "left outer join lnkitclustsvc on ".
          "$worktable.itclustsvc=lnkitclustsvc.id");
}




sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return("default","misc") if ($self->IsMemberOf("admin"));
   return(undef);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),
          qw(default applinfo itclustsvcinfo itclustinfo misc source));
}







1;
