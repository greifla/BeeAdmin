package itil::ext::lnkcontact;
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

   if ($current->{parentobj}=~m/^.+::appl/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self()=~m/^.+::appl$/)){
      return("developer"       =>$self->getParent->T("Developer",
                                                     $self->Self),
             "businessemployee"=>$self->getParent->T("Business Employee",
                                                 $self->Self),
             "customer"        =>$self->getParent->T("Customer Contact",
                                                     $self->Self),
             "techcontact"     =>$self->getParent->T("Technical Contact",
                                                     $self->Self),
             "read"            =>$self->getParent->T("read application",
                                                     $self->Self),
             "write"           =>$self->getParent->T("write application",
                                                     $self->Self),
             "support"         =>$self->getParent->T("Support",
                                                     $self->Self));
   }
   if ($current->{parentobj}=~m/^.+::dbinstance/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self()=~m/^.+::dbinstance$/)){
      return(
             "read"            =>$self->getParent->T("read instance",
                                                     $self->Self),
             "write"           =>$self->getParent->T("write instance",
                                                     $self->Self));
   }
   if ($current->{parentobj}=~m/^.+::system/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self()=~m/^.+::system$/)){
      return("read"            =>$self->getParent->T("read system",
                                                     $self->Self),
             "write"           =>$self->getParent->T("write system",
                                                     $self->Self),
            );
   }
   if ($current->{parentobj}=~m/^.+::asset/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self()=~m/^.+::asset$/)){
      return("read"            =>$self->getParent->T("read system",
                                                     $self->Self),
             "write"           =>$self->getParent->T("write system",
                                                     $self->Self),
            );
   }
   return();
}




1;
