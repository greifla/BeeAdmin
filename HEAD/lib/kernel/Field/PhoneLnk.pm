package kernel::Field::PhoneLnk;
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
use kernel::Field::SubList;
use Data::Dumper;
@ISA    = qw(kernel::Field::SubList);


sub new
{
   my $type=shift;
   my %self=@_;
   $self{vjointo}="base::phonenumber"   if (!defined($self{vjointo}));
   $self{vjoinon}=['id'=>'refid']      if (!defined($self{vjoinon}));
   $self{allowcleanup}=1               if (!defined($self{allowcleanup}));
   if (!defined($self{vjoindisp})){
      $self{vjoindisp}=['phonenumber','name'];
   }

   my $self=bless($type->SUPER::new(%self),$type);
   return($self);
}

sub vjoinobjInit
{
   my $self=shift;
   my $p=$self->getParent()->Self();
   $self->{vjoinbase}=[{'parentobj'=>\$p}] if (!defined($self->{vjoinbase}));
   return($self->SUPER::vjoinobjInit());
}









1;
