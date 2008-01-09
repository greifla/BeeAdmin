package w5v1inv::orgarea;
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
use Data::Dumper;
use kernel;
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
use base::workflow::mailsend;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   
   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5v1"));
   return(@result) if (defined($result[0]) eq "InitERROR");

   $self->setWorktable("bcbereiche");

   $self->AddFields(
      new kernel::Field::Id(      name       =>'id',
                                  label      =>'W5BaseID',
                                  size       =>'10',
                                  dataobjattr=>'bcbereiche.id'),

      new kernel::Field::Text(    name       =>'fullname',
                                  label      =>'fullname',
                                  dataobjattr=>'bcbereiche.name'),

      new kernel::Field::Text(    name       =>'name',
                                  label      =>'name',
                                  dataobjattr=>'bcbereiche.shortname'),

      new kernel::Field::Text(    name       =>'ldapid',
                                  label      =>'ldapid',
                                  dataobjattr=>'bcbereiche.ldap_id'),

      new kernel::Field::Link(    name       =>'isdeprecate',
                                  dataobjattr=>'bcbereiche.isdeprecate'),

      new kernel::Field::Link(    name       =>'parentid',
                                  dataobjattr=>'bcbereiche.pbereich'),
   );
   $self->setDefaultView(qw(id fullname name ldapid));
   $self->SetNamedFilter("BASE",{isdeprecate=>'0'});
   return($self);
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
