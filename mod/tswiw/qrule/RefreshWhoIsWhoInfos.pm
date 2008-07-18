package tswiw::qrule::RefreshWhoIsWhoInfos;
#######################################################################
=pod

=head3 PURPOSE

Refreshes some Informations from WhoIsWho.

=head3 IMPORTS

Description

=cut
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
   return(["base::grp"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $errorlevel=undef;
   my @qmsg;

   my $forcedupd={};
   if ($rec->{srcsys} eq "WhoIsWho" && $rec->{srcid} ne ""){
      $errorlevel=0;
      my $wiw=getModuleObject($self->getParent->Config(),"tswiw::orgarea");
      $wiw->SetFilter({touid=>\$rec->{srcid}});
      my ($wiwrec,$msg)=$wiw->getOnlyFirst(qw(name));
      if (defined($wiwrec)){
         if ($wiwrec->{name} ne $rec->{description}){
            $forcedupd->{description}=$wiwrec->{name};
         }
      }
   }
   if (keys(%$forcedupd)){
      if ($dataobj->ValidatedUpdateRecord($rec,$forcedupd,
                                          {grpid=>\$rec->{grpid}})){
         push(@qmsg,"all desired fields has been updated: ".
                    join(", ",keys(%$forcedupd)));
      }
      else{
         push(@qmsg,$self->getParent->LastMsg());
         $errorlevel=3 if ($errorlevel<3);
      }
   }
   return($errorlevel,{qmsg=>\@qmsg});
}



1;
