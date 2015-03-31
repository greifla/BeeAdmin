package itil::qrule::ApplUsetime;
#######################################################################
=pod

=head3 PURPOSE

For every Prio1-Application must be defined
"Main use time" and "Secondary use time."

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

In each Field "Main use time" and "Secondary use time" will be expected
minimum two time specifications like "hh:mm".

[de:]

In den Feldern "Hauptnutzungszeit" und "Nebennutzungszeit" werden
jeweils mindestens zwei Zeitangaben in der Form "hh:mm" erwartet.

=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2015  Hartmut Vogler (it@guru.de)
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
use kernel::QRule;
@ISA=qw(kernel::QRule);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub getPosibleTargets
{
   return(["itil::appl"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   return(0,undef) if ($rec->{customerprio}!=1 || 
                       ($rec->{cistatusid}!=4 &&
                        $rec->{cistatusid}!=5));
   my @msg;
   foreach my $field ('mainusetime','secusetime') {
      if ($rec->{$field}=~m/^\s*$/) {
         push(@msg,"$field not specified");
      } else {
         my @match=$rec->{$field}=~m/\b[0-2]?\d:[0-5]\d\b/g;
         if ($#match<1) {
            push(@msg,"no valid time specifications in field $field");
         }
      }
   }

   return(3,{qmsg=>\@msg,dataissue=>\@msg}) if ($#msg>-1);
   return(0,undef);
}



1;