#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Checks the expiration of Complex Infoabos. 
If expired, the 'active' flag of the Complex Infoabo will be set to 0.

No dataissue will be generated by this rule.

=head3 IMPORTS

NONE

=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2017  Hartmut Vogler (it@guru.de)
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
package itil::qrule::ComplexinfoaboExp;
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
   return(["itil::complexinfoabo"]);
}


sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   if (!$rec->{'active'} ||
       !defined($rec->{expiration})) {
      return(0,undef);
   }

   my $d=CalcDateDuration(NowStamp('en'),$rec->{expiration},'GMT');

   if ($d->{totalminutes}<0) {
      $dataobj->ValidatedUpdateRecord($rec,{active=>0},{id=>$rec->{id}});

      my $msg="set complex infoabo inactive due to expiration";
      return(0,{qmsg=>[$msg]});
   }

   return(0,undef);
}



1;