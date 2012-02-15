package tsbflexx::reviewreq;
#  W5Base Framework
#  Copyright (C) 2012  Hartmut Vogler (it@guru.de)
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
                autogen       =>0,
                searchable    =>0,
                sqlorder      =>'desc',
                label         =>'RecordID',
                dataobjattr   =>'TBL_BFLEXX_WFREVIEW.id'),
                                  
      new kernel::Field::Text(    
                name          =>'w5baseid',
                label         =>'W5BaseID',
                dataobjattr   =>'TBL_BFLEXX_WFREVIEW.w5baseid'),

      new kernel::Field::Text(    
                name          =>'name',
                sqlorder      =>'NONE',
                vjointo       =>'base::workflow',
                vjoinon       =>['w5baseid'=>'id'],
                vjoindisp     =>'name',
                label         =>'Name'),

      new kernel::Field::Text(    
                name          =>'activity',
                sqlorder      =>'NONE',
                label         =>'Activity',
                dataobjattr   =>'TBL_BFLEXX_WFREVIEW.activity'),

      new kernel::Field::Text(    
                name          =>'statusid',
                sqlorder      =>'NONE',
                htmldetail    =>0,
                label         =>'Status',
                dataobjattr   =>'TBL_BFLEXX_WFREVIEW.status'),

      new kernel::Field::Text(    
                name          =>'reason',
                sqlorder      =>'NONE',
                label         =>'Reason',
                dataobjattr   =>'TBL_BFLEXX_WFREVIEW.reason'),
   );
   $self->setDefaultView(qw(linenumber id w5baseid name statusid activity reason));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsbflexx"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   $self->setWorktable("TBL_BFLEXX_WFREVIEW");
   $self->{use_distinct}=0;
   return(1) if (defined($self->{DB}));
   return(0);
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
   return("default") if ($self->IsMemberOf("admin"));
   return(undef);
}

1;
