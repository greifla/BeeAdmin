package tsacinv::qrule::clusterSysCheck;
#######################################################################
=pod

=head3 PURPOSE

This qulaity checks, if the current logical system is in AssetManager
member of a cluster. If this true, the field is_clusternode must be
set to true. if the cluster exists in w5base, the link to the cluster
must be documented.


=head3 IMPORTS

From AssetManager the relation to a cluster will be generated.

=cut
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
   return(["itil::system","OSY::system","AL_TCom::system"]);
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
   if ($rec->{systemid} ne ""){
      my %parrec=(); 
      $parrec{isclusternode}=0;
      my $sys=getModuleObject($self->getParent->Config(),"tsacinv::system");
      $sys->SetFilter({systemid=>\$rec->{systemid}});
      #$sys->SetFilter({systemid=>'xx'});
      my ($amsysrec,$msg)=$sys->getOnlyFirst(qw(lclusterid));
      return(undef,undef) if (!$sys->Ping());
      if (defined($amsysrec)){
         if ($amsysrec->{lclusterid} ne ""){
            my $cl=getModuleObject($self->getParent->Config(),
                                   "tsacinv::itclust");
            $cl->SetFilter({lclusterid=>\$amsysrec->{lclusterid}});
            my ($amclust,$msg)=$cl->getOnlyFirst(qw(clusterid));
            if (defined($amclust)){
               $parrec{isclusternode}=1;
               my $cl=getModuleObject($self->getParent->Config(),
                                      "itil::itclust");
               $cl->SetFilter({clusterid=>\$amclust->{clusterid}});
               my ($w5clust,$msg)=$cl->getOnlyFirst(qw(id fullname cistatusid));
               if (defined($w5clust)){
                  $parrec{itclust}=$w5clust->{'fullname'};
                 # printf STDERR ("found\n");
                 # printf STDERR ("amclust=%s\n",Dumper($amclust));
                 # printf STDERR ("w5clust=%s\n",Dumper($w5clust));
               }
               else{
                  push(@qmsg,"ClusterID: '".$amclust->{clusterid}.
                       "' not found in W5Base/Darwin")
                  $errorlevel=3 if ($errorlevel<3);
               }
            }
         }
      }


      $self->IfaceCompare($dataobj,
                          $rec,"isclusternode",
                          \%parrec,"isclusternode",
                          $forcedupd,$wfrequest,
                          \@qmsg,\@dataissue,\$errorlevel,
                          mode=>'boolean');

      $self->IfaceCompare($dataobj,
                          $rec,"itclust",
                          \%parrec,"itclust",
                          $forcedupd,$wfrequest,
                          \@qmsg,\@dataissue,\$errorlevel,
                          mode=>'leftouterlink');
      if (keys(%$forcedupd)){
       #  printf STDERR ("found DataIssue cluster on system $rec->{name}\n");
         if ($dataobj->ValidatedUpdateRecord($rec,$forcedupd,
             {id=>\$rec->{id}})){
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
   return(0,undef);
}



1;
