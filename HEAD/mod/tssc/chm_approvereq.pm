package tssc::chm_approvereq;
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
      new kernel::Field::Linenumber(name       =>'linenumber',
                                    label      =>'No.'),

      new kernel::Field::Id(        name       =>'changenumber',
                                    label      =>'Change No.',
                                    align      =>'left',
                                    dataobjattr=>'cm3ra14.numberprgn'),

      new kernel::Field::Text(      name       =>'name',
                                    ignorecase =>1,
                                    label      =>'Pending',
                                    htmldetail =>0,
                                    dataobjattr=>'cm3ra14.current_pending_groups'),

      new kernel::Field::Text(      name       =>'groupname',
                                    label      =>'Pending',
                                    htmlwidth  =>'200px',
                                    vjointo    =>'tssc::group',
                                    vjoinon    =>['name'=>'name'],
                                    vjoindisp  =>['name']),

      new kernel::Field::Text(      name       =>'groupmailbox',
                                    label      =>'Group Email Address',
                                    vjointo    =>'tssc::group',
                                    vjoinon    =>['name'=>'name'],
                                    vjoindisp  =>['groupmailbox']),
   );

   $self->setDefaultView(qw(linenumber groupname groupmailbox));
   $self->{use_distinct}=0;

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
   my $from="cm3ra14";
   return($from);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}


1;
