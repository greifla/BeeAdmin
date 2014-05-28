package article::ext::lnkcontact;
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
use kernel::Universal;
@ISA=qw(kernel::Universal);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   return($self);
}

sub getPosibleRoles
{
   my $self=shift;
   my $field=shift;
   my $parentobj=shift;
   my $current=shift;
   my $newrec=shift;


   if ($parentobj=~m/^.+::catalog$/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self()=~m/^.+::catalog$/)){
      return(
         "read"            =>$self->getParent->T("read catalog",
                                                 $self->Self),
         "admin"           =>$self->getParent->T("admin catalog",
                                                 $self->Self),
         "order"           =>$self->getParent->T("order from catalog",
                                                 $self->Self),
         "write"           =>$self->getParent->T("write catalog",
                                                 $self->Self),
        );
   }
   if ($parentobj=~m/^.+::delivprovider$/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self()=~m/^.+::delivprovider$/)){
      return(
         "read"            =>$self->getParent->T("read elements",
                                                 $self->Self),
         "admin"           =>$self->getParent->T("admin provider",
                                                 $self->Self),
         "write"           =>$self->getParent->T("write elements",
                                                 $self->Self),
        );
   }
   return();
}





1;