package base::ext::lnkcontact;
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
   my $current=shift;

   if ($current->{parentobj} eq "base::mandator" ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self() eq "base::mandator")){
      return("read"=>$self->getParent->T("read",$self->Self),
             "write"=>$self->getParent->T("write",$self->Self)
             );
   }
   if ($current->{parentobj}=~m/^.+::projectroom$/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self()=~m/^.+::projectroom$/)){
      return(
             "read"            =>$self->getParent->T("read",
                                                     $self->Self),
             "write"           =>$self->getParent->T("write",
                                                     $self->Self));
   }
   if ($current->{parentobj} eq "base::location" ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self() eq "base::location")){
      return("infrastruct"=>$self->getParent->T("infrastruct",$self->Self),
             "itnetwork"=>$self->getParent->T("itnetwork",$self->Self)
             );
   }
   return();
}




1;
