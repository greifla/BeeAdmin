package tsacinv::qrule::compareCluster;
#######################################################################
=pod

=head3 PURPOSE

This qulaity rule compares a W5Base cluster to an AssetManager cluster
and updates on demand nessasary fields.

=head3 IMPORTS

-

=cut
#######################################################################
#
#  W5Base Framework
#  Copyright (C) 2010  Hartmut Vogler (it@guru.de)
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
   return(["itil::itclust","AL_TCom::itclust"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   my $wfrequest={};
   my $forcedupd={};
   my @qmsg;
   my @dataissue;
   my $errorlevel=0;

   return(0,undef) if ($rec->{cistatusid}!=4);
   if ($rec->{clusterid} ne ""){
      my $par=getModuleObject($self->getParent->Config(),"tsacinv::itclust");
      $par->SetFilter({clusterid=>\$rec->{clusterid}});
      my ($parrec,$msg)=$par->getOnlyFirst(qw(ALL));
      return(undef,undef) if (!$par->Ping());
      if (!defined($parrec)){
         push(@qmsg,'given clusterid not found as active in AssetManager');
         push(@dataissue,'given clusterid not found as active in AssetManager');
         $errorlevel=3 if ($errorlevel<3);
      }
   }

   return($self->HandleWfRequest($dataobj,$rec,
                                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest));
}



1;
