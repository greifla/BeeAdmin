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
   my $autocorrect=shift;

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
          $self->IfComp($dataobj,
                        $rec,"room",
                        {room=>$acroom},"room",
                        $autocorrect,$forcedupd,$wfrequest,
                        \@qmsg,\@dataissue,\$errorlevel,
                        mode=>'string');

          $self->IfComp($dataobj,
                        $rec,"serialno",
                        $parrec,"serialno",
                        $autocorrect,$forcedupd,$wfrequest,
                        \@qmsg,\@dataissue,\$errorlevel,mode=>'string');

         $self->IfComp($dataobj,
                       $rec,"memory",
                       $parrec,"memory",
                       $autocorrect,$forcedupd,$wfrequest,
                       \@qmsg,\@dataissue,\$errorlevel,
                       tolerance=>5,mode=>'integer');

         $self->IfComp($dataobj,
                       $rec,"cpucount",
                       $parrec,"cpucount",
                       $autocorrect,$forcedupd,$wfrequest,
                       \@qmsg,\@dataissue,\$errorlevel,
                       mode=>'integer');

         $self->IfComp($dataobj,
                       $rec,"corecount",
                       $parrec,"corecount",
                       $autocorrect,$forcedupd,$wfrequest,
                       \@qmsg,\@dataissue,\$errorlevel,
                       mode=>'integer');

         my $w5aclocation;

#=$self->getW5ACLocationname($parrec->{locationid},
#                          "QualityCheck of $rec->{name}");
#         msg(INFO,"rec location=$rec->{location}");
#         msg(INFO,"ac  location=$w5aclocation");
         if ($parrec->{locationid} ne ""){
            my $acloc=getModuleObject($self->getParent->Config(),
                                      "tsacinv::location");
            if (defined($acloc)){
               $acloc->SetFilter({locationid=>\$parrec->{locationid}});
               my ($aclocrec,$msg)=$acloc->getOnlyFirst(qw(w5loc_name));
               if (defined($aclocrec)){
                  my $r=$aclocrec->{w5loc_name};
                  $r=[$r] if (ref($r) ne "ARRAY");
                  $r=[sort(@$r)];
                  if (defined($r->[0]) && $r->[0] ne ""){
                     $w5aclocation=$r->[0];
                  }
               }
            }
            else{
               msg(ERROR,"fail to create tsacinv::location object");
            }
         }


         if (defined($w5aclocation)){ # only if a valid W5Base Location found
            $self->IfComp($dataobj,
                          $rec,"location",
                          {location=>$w5aclocation},"location",
                          $autocorrect,$forcedupd,$wfrequest,
                          \@qmsg,\@dataissue,\$errorlevel,
                          mode=>'string');
         }

         #
         # Filter for conumbers, which are allowed to use in darwin
         #
         if (defined($parrec->{conumber})){
            if ($parrec->{conumber} eq ""){
               $parrec->{conumber}=undef;
            }
            if (defined($parrec->{conumber})){
               #
               # hier mu� der Check gegen die SAP P01 rein f�r die 
               # Umrechnung auf PSP Elemente
               #

               ###############################################################
               my $co=getModuleObject($self->getParent->Config,
                                      "finance::costcenter");
               if (defined($co)){
                  if (!($co->ValidateCONumber(
                        $dataobj->SelfAsParentObject,"conumber", $parrec,
                        {conumber=>$parrec->{conumber}}))){ # simulierter newrec
                     $parrec->{conumber}=undef;
                  }
               }
               else{
                  $parrec->{conumber}=undef;
               }
            }
         }


         $self->IfComp($dataobj,
                       $rec,"conumber",
                       $parrec,"conumber",
                       $autocorrect,$forcedupd,$wfrequest,
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
   my $hint=shift;

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
   $w5loc->Normalize(\%lrec);
#   msg(INFO,"requestrec=%s",Dumper(\%lrec));
   

#   my $w5locid=$w5loc->getLocationByHash(%lrec);

   my $debug;
   my $w5locid=$w5loc->getIdByHashIOMapped("tsacinv::location",\%lrec,
                                           DEBUG=>\$debug,
                                           ForceLikeSearch=>1);
   if (!defined($w5locid)){
      $w5loc->Log(ERROR,"basedata",
           "Fail to request base::location\n".
           "queried by tsacinv::location\n".
           "for AC location $aclocrec->{fullname}\n".
           "while $hint. Contact Admin to add\n".
           "Location:\n".
           join("\n",map({sprintf(" * %-10s='%s'",$_,$lrec{$_})} keys(%lrec))).
           "\n-");
   }

   return(undef) if (!defined($w5locid));
   $w5loc->SetFilter({id=>\$w5locid}); 
   my ($w5locrec,$msg)=$w5loc->getOnlyFirst(qw(name));
   return(undef) if (!defined($w5locrec));
   msg(INFO,"used w5 location=$w5locrec->{name}");
   return($w5locrec->{name});

}


1;
