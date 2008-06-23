package kernel::Field::Boolean;
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
use Data::Dumper;
use kernel::Field::Select;

@ISA    = qw(kernel::Field::Select);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->{value}=[0,1]            if (!defined($self->{values}));
   $self->{transprefix}="boolean." if (!defined($self->{transprefix}));
   $self->{default}="0"            if (!defined($self->{default}));
   return($self);
}

sub FormatedResult
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $d=$self->RawValue($current);
   return($d) if ($mode eq "XMLV01");
   return($self->SUPER::FormatedResult($current,$mode));
}


1;
