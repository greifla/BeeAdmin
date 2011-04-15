package kernel::App::Web::DBDataDiconary;
#  W5Base Framework
#  Copyright (C) 2008  Hartmut Vogler (it@guru.de)
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
use kernel::Field;
use kernel::App::Web::Listedit;
use kernel::DataObj::DB;
@ISA    = qw(kernel::App::Web::Listedit kernel::DataObj::DB);

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
                align         =>'left',
                label         =>'ID',
                uivisible     =>'0',
                dataobjattr   =>'f.fieldname'),

      new kernel::Field::Text(
                name          =>'fieldname',
                align         =>'left',
                label         =>'Fieldname',
                dataobjattr   =>'lower(f.fieldname)'),

      new kernel::Field::Text(
                name          =>'datatype',
                uppersearch   =>'1',
                label         =>'Datatype',
                dataobjattr   =>'f.data_type'),

      new kernel::Field::Text(
                name          =>'datalenght',
                uppersearch   =>'1',
                htmlwidth     =>'50px',
                align         =>'right',
                label         =>'Datalenght',
                dataobjattr   =>'f.data_length'),

      new kernel::Field::Boolean(
                name          =>'isindexed',
                label         =>'Index',
                dataobjattr   =>"f.isindexed"),

      new kernel::Field::Text(
                name          =>'schemaname',
                align         =>'left',
                uppersearch   =>'1',
                label         =>'Schema',
                dataobjattr   =>'f.owner'),

   );
   $self->setDefaultView(qw(linenumber schemaname fieldname datatype 
                            datalenght isindexed));
   $self->setWorktable("f");

   return($self);
}

sub getSqlFrom
{
   my $self=shift;
   my $wt=$self->{Worktable};
   my $from=<<EOF;
(select distinct t.owner schemaname,
       lower(t.owner||'.'||t.table_name||'.'||t.column_name) fieldname,
       t.data_type,
       t.owner,
       t.data_length,
       decode(i.index_name,null,0,1) isindexed,
       t.owner||'.'||t.table_name||'.'||t.column_name id
from all_tab_columns t, all_ind_columns i 
where t.table_name=i.table_name(+) 
      and t.owner=i.table_owner(+) 
      and t.column_name=i.column_name(+)) f
EOF
   return($from);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   return("ALL");
}



