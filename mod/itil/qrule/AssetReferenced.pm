package itil::qrule::AssetReferenced;
#######################################################################
=pod

=head3 PURPOSE

The Quality Rule checks, if an Asset in CI-Status "installed/active"
is "used" be at least ONE logical system in CI-Status "installed/active".
If the CI-Status of the asset is not "marked as delete", it must
be references by at least one logical system in any state.

=head3 IMPORTS

NONE

=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2007  Hartmut Vogler (it@guru.de)
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
   return(["itil::asset"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $checksession=shift;
   my $autocorrect=$checksession->{autocorrect};

   my $wfrequest={};
   my $forcedupd={};
   my @msg;
   my @dataissue;
   my $errorlevel=0;


   return(0,undef) if ($rec->{cistatusid}==6 ||
                       $rec->{cistatusid}==1 ||
                       $rec->{cistatusid}==2);

   my $sysflt={asset=>$rec->{name},cistatusid=>\'4'};
   if ($rec->{cistatusid}!=4){
      delete($sysflt->{cistatusid});
   }
   my $sys=getModuleObject($self->getParent->Config,"itil::system");
   $sys->SetFilter($sysflt);
   my @l=$sys->getHashList(qw(id));
   if ($#l==-1){
      push(@msg,"no logical systems referenced to this asset");
   }

   if ($#msg>=0){
      return(3,{qmsg=>\@msg,dataissue=>\@msg});
   }
   return(0,undef);

}




1;