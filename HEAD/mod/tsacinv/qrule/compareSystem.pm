package tsacinv::qrule::compareSystem;
#######################################################################
=pod

=head3 PURPOSE

This qulaity rule compares a W5Base logical system to an AssetManager logical
system and updates on demand nessasary fields.
Unattended Imports are only done, if the field "Allow automatic interface
updates" is set to "yes".
If a logical system is a workstation, no DataIssue Workflow is started on
a missing systemid.
Only logical systems in W5Base with state "installed/active" will be synced!


=head3 IMPORTS

From AssetManager the fields Memory, CPU-Count, CO-Number,
Description are imported.
IP-Addresses can only be synced, if the field "Allow automatic interface
updates" is set to "yes".
If Mandator is set to "Extern" and "Allow automatic interface updates"
is set to "yes", some aditional Imports are posible:

- "W5Base Administrator" field is set to the supervisor of Assignmentgroup in AC

- "AC Assignmentgroup" is imported to comments field in W5Base

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
      my $par=getModuleObject($self->getParent->Config(),"tsacinv::system");
      $par->SetFilter({systemid=>\$rec->{systemid}});
      my ($parrec,$msg)=$par->getOnlyFirst(qw(ALL));
      return(undef,undef) if (!$par->Ping());
      if (!defined($parrec)){
         push(@qmsg,'given systemid not found as active in AssetManager');
         push(@dataissue,'given systemid not found as active in AssetManager');
         $errorlevel=3 if ($errorlevel<3);
      }
      else{
         #
         # osrelease mapping
         #
         if (!($parrec->{systemos}=~/^\s*$/)){
            my $mapos=$dataobj->ModuleObject("tsacinv::lnkw5bosrelease");
            $mapos->SetFilter({extosrelease=>\$parrec->{systemos}});
            my ($maposrec,$msg)=$mapos->getOnlyFirst(qw(id w5bosrelease));
            if (defined($maposrec)){
               if ($maposrec->{w5bosrelease} ne ""){
                  $parrec->{systemos}=$maposrec->{w5bosrelease};
               }
               else{
                  delete($parrec->{systemos});
               }
            }
            else{
               my %new=(extosrelease=>$parrec->{systemos},direction=>1);
               # try to find an already existing name in W5Base
               my $os=$dataobj->ModuleObject("itil::osrelease");
               $os->SetFilter({name=>'"'.$parrec->{systemos}.'"'});
               my ($w5osrec,$msg)=$mapos->getOnlyFirst(qw(name));
               if (defined($w5osrec)){
                  $new{w5bosrelease}=$w5osrec->{name};
               }
               $mapos->ValidatedInsertRecord(\%new);
               delete($parrec->{systemos});
            }
         }
         #################################################################### 
         
   #      $parrec->{systemos}=~s/[\*\?]/_/g;
   #      my $os=getModuleObject($self->getParent->Config(),"itil::osrelease");
   #      $os->SetFilter({name=>'"'.$parrec->{systemos}."'"});
   #      my ($osrec,$msg)=$os->getOnlyFirst(qw(id name));
   #      if (!defined($osrec)){
   #         delete($parrec->{systemos});
   #      }


         $self->IfaceCompare($dataobj,
                             $rec,"servicesupport",
                             $parrec,"systemola",
                             $forcedupd,$wfrequest,
                             \@qmsg,\@dataissue,\$errorlevel,
                             mode=>'leftouterlinkcreate',
                             onCreate=>{
                               comments=>"automaticly create by QualityCheck",
                               cistatusid=>4,
                               name=>$parrec->{systemola}}
                             );
         $self->IfaceCompare($dataobj,
                             $rec,"memory",
                             $parrec,"systemmemory",
                             $forcedupd,$wfrequest,
                             \@qmsg,\@dataissue,\$errorlevel,
                             tolerance=>5,mode=>'integer');
         $self->IfaceCompare($dataobj,
                             $rec,"cpucount",
                             $parrec,"systemcpucount",
                             $forcedupd,$wfrequest,
                             \@qmsg,\@dataissue,\$errorlevel,
                             mode=>'integer');
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
         $self->IfaceCompare($dataobj,
                             $rec,"osrelease",
                             $parrec,"systemos",
                             $forcedupd,$wfrequest,
                             \@qmsg,\@dataissue,\$errorlevel,
                             mode=>'leftouterlink');
         if ($rec->{allowifupdate}){
            my $net=getModuleObject($self->getParent->Config(),"itil::network");
            $net->SetCurrentView(qw(id name));
            my $netarea=$net->getHashIndexed("name");
            my @opList;
            my $res=OpAnalyse(
                       sub{  # comperator 
                          my ($a,$b)=@_;
                          my $eq;
                          if ($a->{name} eq $b->{ipaddress}){
                             $eq=0;
                             $eq=1 if ($a->{comments} eq $b->{description});
                          }
                          return($eq);
                       },
                       sub{  # oprec generator
                          my ($mode,$oldrec,$newrec,%p)=@_;
                          if ($mode eq "insert" || $mode eq "update"){
                             my $networkid=$p{netarea}->{name}->
                                           {'Insel-Netz/Kunden-LAN'}->{id};
                             my $identifyby=undef;
                             if ($mode eq "update"){
                                $identifyby=$oldrec->{id};
                             }
                             if ($newrec->{ipaddress}=~m/^\s*$/){
                                $mode="nop";
                             }
                             return({OP=>$mode,
                                     MSG=>"$mode ip $newrec->{ipaddress} ".
                                          "in W5Base",
                                     IDENTIFYBY=>$identifyby,
                                     DATAOBJ=>'itil::ipaddress',
                                     DATA=>{
                                        name      =>$newrec->{ipaddress},
                                        cistatusid=>4,
                                        networkid =>$networkid,
                                        comments  =>$newrec->{description},
                                        systemid  =>$p{refid}
                                        }
                                     });
                          }
                          elsif ($mode eq "delete"){
                             return({OP=>$mode,
                                     MSG=>"delete ip $oldrec->{name} ".
                                          "from W5Base",
                                     DATAOBJ=>'itil::ipaddress',
                                     IDENTIFYBY=>$oldrec->{id},
                                     });
                          }
                          return(undef);
                       },
                       $rec->{ipaddresses},$parrec->{ipaddresses},\@opList,
                       refid=>$rec->{id},netarea=>$netarea);
            if (!$res){
               my $opres=ProcessOpList($self->getParent,\@opList);
            }
         }
      }

      if ($rec->{mandator} eq "Extern" && $rec->{allowifupdate}){
         # forced updates on External Data
         my $admid;
         my $acgroup=getModuleObject($self->getParent->Config,"tsacinv::group");
         $acgroup->SetFilter({lgroupid=>\$parrec->{lassignmentid}});
         my ($acgrouprec,$msg)=$acgroup->getOnlyFirst(qw(supervisorldapid));
         if (defined($acgrouprec)){
            if ($acgrouprec->{supervisorldapid} ne "" ||
                $acgrouprec->{supervisoremail} ne ""){
               my $importname=$acgrouprec->{supervisorldapid};
               if ($importname eq ""){
                  $importname=$acgrouprec->{supervisoremail};
               }
               my $tswiw=getModuleObject($self->getParent->Config,
                                         "tswiw::user");
               my $databossid=$tswiw->GetW5BaseUserID($importname);
               if (defined($databossid)){
                  $admid=$databossid;
               }
            }
         }
         if ($admid ne ""){
            $self->IfaceCompare($dataobj,
                                $rec,"admid",
                                {admid=>$admid},"admid",
                                $forcedupd,$wfrequest,\@qmsg,\$errorlevel,
                                mode=>'integer');
         }
         my $comments="";
         if ($parrec->{assignmentgroup} ne ""){
            $comments.="\n" if ($comments ne "");
            $comments.="AssetManager AssignmentGroup: ".
                       $parrec->{assignmentgroup};
         }
         if ($parrec->{conumber} ne ""){
            $comments.="\n" if ($comments ne "");
            $comments.="AssetManager CO-Number: ".
                       $parrec->{conumber};
         }
         $self->IfaceCompare($dataobj,
                             $rec,"comments",
                             {comments=>$comments},"comments",
                             $forcedupd,$wfrequest,\@qmsg,\$errorlevel,
                             mode=>'string');
      }
      if ($rec->{asset} ne ""){
         my $par=getModuleObject($self->getParent->Config(),"tsacinv::asset");
         $par->SetFilter({assetid=>\$rec->{asset}});
         my ($parrec,$msg)=$par->getOnlyFirst(qw(ALL));
         if (!defined($parrec)){
            push(@qmsg,'given assetid not found as active in AssetManager');
            $errorlevel=3 if ($errorlevel<3);
         }
      }
      else{
         push(@qmsg,'no assetid specified');
         push(@dataissue,'no assetid specified');
         $errorlevel=1 if ($errorlevel<1);
      }
   }
   else{
      push(@qmsg,'no systemid specified');
      if (!($rec->{isworkstation})){
         push(@dataissue,'no systemid specified');
         $errorlevel=3 if ($errorlevel<3);
      }
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



1;
