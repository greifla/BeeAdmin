package tsacinv::qrule::compareCluster;
#######################################################################
=pod

=head3 PURPOSE

This qulaity rule compares a W5Base cluster to an AssetManager cluster
and updates on demand nessasary fields.

=head3 IMPORTS

- name of cluster

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
      $self->IfaceCompare($dataobj,
                          $rec,"name",
                          $parrec,"name",
                          $forcedupd,$wfrequest,
                          \@qmsg,\@dataissue,\$errorlevel,
                          mode=>'string');

      my @opList;
      my $res=OpAnalyse(
                 sub{  # comperator 
                    my ($a,$b)=@_;
                    my $eq;
                    printf STDERR ("compare $a->{itservid} = $b->{serviceid}\n"); 
                    if ($a->{itservid} eq $b->{serviceid}){
                       $eq=0;
                   #    $eq=1 if ($a->{comments} eq $b->{description});
                    }
                    return($eq);
                 },
                sub{  # oprec generator
                    my ($mode,$oldrec,$newrec,%p)=@_;
                    if ($mode eq "insert" || $mode eq "update"){
                       my $identifyby=undef;
                       if ($mode eq "update"){
                          $identifyby=$oldrec->{id};
                       }
                       my $opl="";
                       $opl.=$newrec->{name} if ($newrec->{name} ne "");
                       $opl.=" "  if ($opl ne "" && $newrec->{serviceid} ne "");
                       if ($newrec->{serviceid} ne ""){
                          $opl.="(ClusterServiceID:".$newrec->{serviceid}.")";
                       }
                       return({OP=>$mode,
                               OPLABEL=>$opl,
                               MSG=>"$mode ClustService $newrec->{serviceid} ".
                                    "in W5Base",
                               IDENTIFYBY=>$identifyby,
                               DATAOBJ=>'itil::lnkitclustsvc',
                               DATA=>{
                                  name      =>$newrec->{name},
                                  itservid  =>$newrec->{serviceid},
                                  comments  =>$newrec->{usage},
                                  clustid   =>$p{refid}
                                  }
                               });
                    }
                    elsif ($mode eq "delete"){
                       return({OP=>$mode,
                               OPLABEL=>$oldrec->{fullname},
                               MSG=>"delete ClustService $oldrec->{name} ".
                                    "from W5Base",
                               DATAOBJ=>'itil::lnkitclustsvc',
                               IDENTIFYBY=>$oldrec->{id},
                               });
                    }
                    return(undef);
                 },
                 $rec->{services},$parrec->{services},\@opList,
                 refid=>$rec->{id});
            if (!$res){
               if ($rec->{allowifupdate}==1){
                  my $opres=ProcessOpList($self->getParent,\@opList);
               }
               else{
                  #
                  # this can be in the future maybe a seperate function
                  #
                  if ($#opList!=-1){
                     push(@qmsg,"cluster services needs correction");
                     foreach my $oprec (@opList){
                        if ($oprec->{OP} eq "delete"){
                           push(@qmsg,"delete needed for: ".
                                      $oprec->{OPLABEL});
                        }
                        elsif ($oprec->{OP} eq "insert"){
                           push(@qmsg,"insert needed for: ".
                                      $oprec->{OPLABEL});
                        }
                        elsif ($oprec->{OP} eq "update"){
                           push(@qmsg,"update needed for: ".
                                      $oprec->{OPLABEL});
                        }
                     }
                     push(@dataissue,"cluster service list inconsistent to ".
                                     "AssetManager");
                     $errorlevel=3 if ($errorlevel<3);
                  }
                  ##########################################################
               }
            }
   }

   if (keys(%$forcedupd)){
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



1;
