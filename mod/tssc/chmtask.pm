package tssc::chmtask;
#  W5Base Framework
#  Copyright (C) 2011  Hartmut Vogler (it@guru.de)
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

      new kernel::Field::Text(
                name          =>'changenumber',
                label         =>'Change No.',
                align         =>'left',
                weblinkto     =>'tssc::chm',
                weblinkon     =>['changenumber'=>'changenumber'],
                dataobjattr   =>'cm3tm1.parent_change'),

      new kernel::Field::Id(
                name          =>'tasknumber',
                label         =>'Task No.',
                searchable    =>1,
                align         =>'left',
                htmlwidth     =>'200px',
                dataobjattr   =>'cm3tm1.numberprgn'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Task Brief Description',
                ignorecase    =>1,
                dataobjattr   =>'cm3tm1.brief_description'),

      new kernel::Field::Text(
                name          =>'status',
                group         =>'status',
                label         =>'Status',
                ignorecase    =>1,
                dataobjattr   =>'cm3tm1.status'),

#      new kernel::Field::Text(
#                name          =>'approvalstatus',
#                label         =>'approval status',
#                group         =>'status',
#                ignorecase    =>1,
#                dataobjattr   =>'cm3tm1.approval_status'),

      new kernel::Field::Date(
                name          =>'plannedstart',
                timezone      =>'CET',
                label         =>'Planed Start',
                dataobjattr   =>'cm3tm1.planned_start'),

      new kernel::Field::Date(
                name          =>'plannedend',
                timezone      =>'CET',
                label         =>'Planed End',
                dataobjattr   =>'cm3tm1.planned_end'),

      new kernel::Field::Boolean(          # the field ci_down does not exists
                name          =>'cidown',  # in scadm schema - but in scadm1.
                timezone      =>'CET',     # => soo i build a hack to allow 
                label         =>'PSO-Flag',     # the access on this field
                dataobjattr   =>"decode(downtab.ci_down,'t','1','0')"),

#      new kernel::Field::Date(
#                name          =>'downstart',
#                timezone      =>'CET',
#                group         =>'downtime',
#                label         =>'Down Start',
#                dataobjattr   =>'cm3tm1.down_start'),
#
#      new kernel::Field::Date(
#                name          =>'downend',
#                timezone      =>'CET',
#                group         =>'downtime',
#                label         =>'Down End',
#                dataobjattr   =>'cm3tm1.down_end'),

      new kernel::Field::Textarea(
                name          =>'description',
                label         =>'Description',
                searchable    =>0,
                htmlwidth     =>300,
                sqlorder      =>'NONE',
                dataobjattr   =>'cm3tm1.description'),

      new kernel::Field::SubList(
                name          =>'relations',
                label         =>'Relations',
                group         =>'relations',
                vjointo       =>'tssc::lnk',
                vjoinon       =>['tasknumber'=>'src'],
                vjoininhash   =>['dst','dstobj'],
                vjoindisp     =>[qw(dst dstname)]),

      new kernel::Field::Date(
                name          =>'workstart',
                timezone      =>'CET',
                label         =>'Work Start',
                dataobjattr   =>'cm3tm1.down_start'),

      new kernel::Field::Date(
                name          =>'workend',
                timezone      =>'CET',
                label         =>'Work End',
                dataobjattr   =>'cm3tm1.down_end'),

      new kernel::Field::Text(
                name          =>'assignedto',
                label         =>'Assigned to',
                group         =>'contact',
                ignorecase    =>1,
                dataobjattr   =>'cm3tm1.assigned_to'),

      new kernel::Field::Text(
                name          =>'implementer',
                label         =>'Implementer',
                group         =>'contact',
                ignorecase    =>1,
                dataobjattr   =>'cm3tm1.assign_firstname'),

      new kernel::Field::Text(
                name          =>'editor',
                group         =>'status',
                label         =>'Editor',
                dataobjattr   =>'cm3tm1.sysmoduser'),

      new kernel::Field::Date(
                name          =>'sysmodtime',
                group         =>'status',
                timezone      =>'CET',
                label         =>'SysModTime',
                dataobjattr   =>'cm3tm1.sysmodtime'),

      new kernel::Field::Date(
                name          =>'createtime',
                group         =>'status',
                timezone      =>'CET',
                label         =>'Create time',
                dataobjattr   =>'cm3tm1.orig_date_entered'),

   );

   $self->{use_distinct}=0;
   $self->setDefaultView(qw(linenumber changenumber name));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tssc"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getSqlFrom
{
   my $self=shift;
   my $from="cm3tm1,scadm1.cm3tm1 downtab";
  # my $from="cm3tm1";
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where="cm3tm1.numberprgn=downtab.numberprgn";
   return($where);
}

sub isQualityCheckValid
{
   return(0);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   my @l=qw(header default relations contact status);
   if ($rec->{cidown}){
      push(@l,"downtime");
   }
   
   return(@l);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

sub getDetailBlockPriority                # posibility to change the block order
{
   my $self=shift;
   return(qw(header default downtime relations contact status));
}




1;
