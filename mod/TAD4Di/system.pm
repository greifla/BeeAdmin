package TAD4Di::system;
#  W5Base Framework
#  Copyright (C) 2014  Hartmut Vogler (it@guru.de)
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
use TAD4D::system;
@ISA=qw(TAD4D::system);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->getField("software")->{vjointo}="TAD4Di::software";
   $self->getField("nativesoftware")->{vjointo}="TAD4Di::nativesoftware";
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tad4di"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


1;