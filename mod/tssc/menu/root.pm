package tssc::menu::root;
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
use kernel::MenuRegistry;
@ISA=qw(kernel::MenuRegistry);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub Init
{
   my $self=shift;

   $self->RegisterObj("sc",
                      "tmpl/welcome",
                      defaultacl=>['admin',"support"]);
   
   $self->RegisterObj("sc.change",
                      "tssc::chm",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("sc.change.software",
                      "tssc::chm_software",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("sc.change.device",
                      "tssc::chm_device",
                      defaultacl=>['admin',"support"]);
   
   $self->RegisterObj("sc.change.timing",
                      "tssc::chm_timingcheck",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("sc.incident",
                      "tssc::inm",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("sc.incident.assignment",
                      "tssc::inm_assignment",
                      defaultacl=>['admin',"support"]);
   
   $self->RegisterObj("sc.problem",
                      "tssc::prm",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("sc.krn",
                      "tmpl/welcome",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("sc.krn.mandator",
                      "tssc::mandator",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("sc.krn.group.lnkuser",
                      "tssc::lnkusergroup",
                      defaultacl=>['admin']);

   $self->RegisterObj("sc.krn.group",
                      "tssc::group",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("sc.krn.approval",
                      "tssc::approval",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("sc.krn.user",
                      "tssc::user",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("sc.krn.user.lnkgroup",
                      "tssc::lnkusergroup",
                      defaultacl=>['admin']);

   $self->RegisterObj("sc.krn.dictonary",
                      "tssc::DBDataDiconary",
                      defaultacl=>['admin']);

   return($self);
}



1;
