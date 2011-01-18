package tsacinv::qrule::compareAsset;
#######################################################################
=pod

=head3 PURPOSE

This qulaity rule compares a W5Base physical system to an AssetManager physical
system (Asset) and updates on demand nessasary fields.
Unattended Imports are only done, if the field "Allow automatic interface
updates" is set to "yes".
Only assets in W5Base with state "installed/active" will be synced!

=head3 IMPORTS

Location, Room, Memory, CPU-Count, Core-Count, SerialNo, CO-Number

=cut

#######################################################################

#  Functions:
#  * at cistatus "installed/active":
#    - check if systemid is valid in tsacinv::system
#    - check if assetid is valid in tsacinv::asset 
#
#######################################################################
#
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
   return(["itil::asset","OSY::asset","AL_TCom::asset"]);
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
   return(0,undef) if ($rec->{name}=~m/^ServiceID:/); 
   return(0,undef) if ($rec->{name} eq $rec->{id}); 
   if ($rec->{name} ne ""){
      my $par=getModuleObject($self->getParent->Config(),"tsacinv::asset");
      $par->SetFilter({assetid=>\$rec->{name},
                       status=>'"!wasted"'});
      my ($parrec,$msg)=$par->getOnlyFirst(qw(ALL));
      return(undef,undef) if (!$par->Ping());
      if (!defined($parrec)){
         push(@qmsg,'given assetid not found as active in AssetManager');
         push(@dataissue,'given assetid not found as active in AssetManager');
         $errorlevel=3 if ($errorlevel<3);
      }
      else{
          my $acroom=$parrec->{room};
          my $acloc=$parrec->{tsacinv_locationfullname};
          if ($acroom=~m/^\d{1,2}\.\d{3}$/){
             if (my ($geb)=$acloc=~m#^/[^/]+/([A-Z]{1})/#){
                $acroom=$geb.$acroom;
             }
          }
         # $acroom="C1.300" if ($acroom eq "1.300"); 
#printf STDERR ("acroom=$acroom asset=%s\n",Dumper($parrec));
          $self->IfaceCompare($dataobj,
                              $rec,"room",
                              {room=>$acroom},"room",
                              $forcedupd,$wfrequest,
                              \@qmsg,\@dataissue,\$errorlevel,
                              mode=>'string');

          $self->IfaceCompare($dataobj,
                              $rec,"serialno",
                              $parrec,"serialno",
                              $forcedupd,$wfrequest,
                              \@qmsg,\@dataissue,\$errorlevel,
                              mode=>'string');

         $self->IfaceCompare($dataobj,
                             $rec,"memory",
                             $parrec,"memory",
                             $forcedupd,$wfrequest,
                             \@qmsg,\@dataissue,\$errorlevel,
                             tolerance=>5,mode=>'integer');

         $self->IfaceCompare($dataobj,
                             $rec,"cpucount",
                             $parrec,"cpucount",
                             $forcedupd,$wfrequest,\@qmsg,\$errorlevel,
                             mode=>'integer');

         $self->IfaceCompare($dataobj,
                             $rec,"corecount",
                             $parrec,"corecount",
                             $forcedupd,$wfrequest,\@qmsg,\$errorlevel,
                             mode=>'integer');

         my $w5aclocation=$self->getW5ACLocationname($parrec->{locationid});
         msg(INFO,"rec location=$rec->{location}");
         msg(INFO,"ac  location=$w5aclocation");
         if (defined($w5aclocation)){ # only if a valid W5Base Location found
            $self->IfaceCompare($dataobj,
                                $rec,"location",
                                {location=>$w5aclocation},"location",
                                $forcedupd,$wfrequest,\@qmsg,\$errorlevel,
                                mode=>'string');
         }

         if (defined($parrec->{conumber}) &&
             !($parrec->{conumber}=~m/^\d+$/)){
            $parrec->{conumber}=undef;
         }
         $self->IfaceCompare($dataobj,
                             $rec,"conumber",
                             $parrec,"conumber",
                             $forcedupd,$wfrequest,
                             \@qmsg,\@dataissue,\$errorlevel,
                             mode=>'string');

         return(undef,undef) if (!$par->Ping());
      }
   }
   else{
      push(@qmsg,'no assetid specified');
      push(@dataissue,'no assetid specified');
      $errorlevel=3 if ($errorlevel<3);
   }

   if (keys(%$forcedupd)){
      #printf STDERR ("fifi request a forceupd=%s\n",Dumper($forcedupd));
      if ($dataobj->ValidatedUpdateRecord($rec,$forcedupd,{id=>\$rec->{id}})){
         push(@qmsg,"all desired fields has been updated: ".
                    join(", ",keys(%$forcedupd)));
      }
      else{
         push(@qmsg,$self->getParent->LastMsg());
         $errorlevel=3 if ($errorlevel<3);
      }
   }
   if (keys(%$wfrequest)){
      my $msg="different values stored in AssetManager: ";
      push(@qmsg,$msg);
      push(@dataissue,$msg);
      $errorlevel=3 if ($errorlevel<3);
   }
   return($self->HandleWfRequest($dataobj,$rec,
                                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest));
}


sub getW5ACLocationname
{
   my $self=shift;
   my $aclocationid=shift;

   msg(INFO,"start getW5ACLocationname");
   return(undef) if ($aclocationid eq "" || $aclocationid==0);
   my $acloc=$self->getPersistentModuleObject('tsacinv::location');
   my $w5loc=$self->getPersistentModuleObject('base::location');
   $acloc->SetFilter({locationid=>\$aclocationid}); 
   my ($aclocrec,$msg)=$acloc->getOnlyFirst(qw(ALL));
   my %lrec;

   msg(INFO,"req  ac location=$aclocrec->{fullname}");
   $lrec{label}=$aclocrec->{label};
   $lrec{address1}=$aclocrec->{address1};
   $lrec{location}=$aclocrec->{location};
   $lrec{zipcode}=$aclocrec->{zipcode};
   $lrec{country}=$aclocrec->{country};
   $lrec{cistatusid}=4;

   return(undef) if ($lrec{zipcode} eq "0");
   return(undef) if ($lrec{location} eq "0");
   return(undef) if ($lrec{address1} eq "0");
   #
   # pre process aclocation 
   #
   delete($lrec{country}) if ($lrec{country} eq ""); 
   delete($lrec{zipcode}) if ($lrec{zipcode} eq ""); 
   $lrec{label}=""        if (!defined($lrec{label}));

   if (!defined($lrec{country})){
      if ($aclocrec->{fullname}=~m/^\/DE[_-]/){
         $lrec{country}="DE";
      }
   }
   msg(INFO,"requestrec=%s",Dumper(\%lrec));
   

   my $w5locid=$w5loc->getLocationByHash(%lrec);
   return(undef) if (!defined($w5locid));
   $w5loc->SetFilter({id=>\$w5locid}); 
   my ($w5locrec,$msg)=$w5loc->getOnlyFirst(qw(name));
   return(undef) if (!defined($w5locrec));
   msg(INFO,"used w5 location=$w5locrec->{name}");
   return($w5locrec->{name});

}


1;
