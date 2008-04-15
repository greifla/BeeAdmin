package tsacinv::qrule::compareAppl;
#######################################################################
=pod

=head3 PURPOSE

This qulaity rule compares a W5Base application to an AssetCenter application
and updates on demand nessasary fields.
Unattended Imports are only done, if the field "Allow automatic interface
updates" is set to "yes".

=head3 IMPORTS

From AssetCenter the fields CO-Number, ApplicationID, Application Number,
CurrentVersion and Description are imported. SeM and TSM are imported, if
it was successfuly to import the relatied contacts.
#If Mandator is "Extern" and "Allow automatic interface updates" is set to "yes",
#there will be also the Name of the application, the databoss and the cistatus 
#imported from AssetCenter.

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
   return(["itil::appl","AL_TCom::appl"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   my $wfrequest={};
   my $forcedupd={};
   my @qmsg;
   my $errorlevel=0;

   return(0,undef) if ($rec->{cistatusid}!=4);
   if ($rec->{applid} ne ""){
      my $tswiw=getModuleObject($self->getParent->Config,"tswiw::user");
      my $par=getModuleObject($self->getParent->Config(),"tsacinv::appl");
      $par->SetFilter({applid=>\$rec->{applid}});
      my ($parrec,$msg)=$par->getOnlyFirst(qw(ALL));
      if (!defined($parrec)){
         push(@qmsg,'given applicationid not found as active in AssetCenter');
         $errorlevel=3 if ($errorlevel<3);
      }
      else{
         $self->IfaceCompare($dataobj,
                             $rec,"conumber",
                             $parrec,"conumber",
                             $forcedupd,$wfrequest,\@qmsg,\$errorlevel,
                             mode=>'native');
         if ($parrec->{sememail} ne ""){
            my $semid=$tswiw->GetW5BaseUserID($parrec->{sememail});
            if (defined($semid)){
               $self->IfaceCompare($dataobj,
                                   $rec,"semid",
                                   {semid=>$semid},"semid",
                                   $forcedupd,$wfrequest,\@qmsg,\$errorlevel,
                                   mode=>'native');
            }
         }
         if ($parrec->{tsmemail} ne ""){
            my $tsmid=$tswiw->GetW5BaseUserID($parrec->{tsmemail});
            if (defined($tsmid)){
               $self->IfaceCompare($dataobj,
                                   $rec,"tsmid",
                                   {tsmid=>$tsmid},"tsmid",
                                   $forcedupd,$wfrequest,\@qmsg,\$errorlevel,
                                   mode=>'native');
            }
         }
         $self->IfaceCompare($dataobj,
                             $rec,"applnumber",
                             $parrec,"ref",
                             $forcedupd,$wfrequest,\@qmsg,\$errorlevel,
                             mode=>'native');
         $self->IfaceCompare($dataobj,
                             $rec,"description",
                             $parrec,"description",
                             $forcedupd,$wfrequest,\@qmsg,\$errorlevel,
                             mode=>'native');
         $self->IfaceCompare($dataobj,
                             $rec,"currentvers",
                             $parrec,"version",
                             $forcedupd,$wfrequest,\@qmsg,\$errorlevel,
                             mode=>'native');
      }
      if ($rec->{allowifupdate}){
#printf STDERR ("ac=%s\n",Dumper($parrec->{systems}));
#printf STDERR ("w5=%s\n",Dumper($rec->{systems}));
#         my $net=getModuleObject($self->getParent->Config(),"itil::network");
#         $net->SetCurrentView(qw(id name));
#         my $netarea=$net->getHashIndexed("name");
#printf STDERR ("netarea=%s\n",Dumper($netarea));
#         my @opList;
#         my $res=OpAnalyse(sub{  # comperator 
#                              my $eq;
#                              if ($a->{name} eq $b->{ipaddress}){
#                                 $eq=0;
#                                 $eq=1 if ($a->{comments} eq $b->{description});
#                              }
#                              return($eq);
#                           },
#                           sub{  # oprec generator
#                              my ($mode,$oldrec,$newrec,%p)=@_;
#                              if ($mode eq "insert" || $mode eq "update"){
#                                 my $networkid=$p{netarea}->{name}->
#                                               {'Insel-Netz/Kunden-LAN'}->{id};
#                                 my $identifyby=undef;
#                                 if ($mode eq "update"){
#                                    $identifyby=$oldrec->{id};
#                                 }
#                                 return({OP=>$mode,
#                                         MSG=>"$mode ip $newrec->{ipaddress} ".
#                                              "in W5Base",
#                                         IDENTIFYBY=>$identifyby,
#                                         DATAOBJ=>'itil::ipaddress',
#                                         DATA=>{
#                                            name      =>$newrec->{ipaddress},
#                                            cistatusid=>4,
#                                            networkid =>$networkid,
#                                            comments  =>$newrec->{description},
#                                            systemid  =>$p{refid}
#                                            }
#                                         });
#                              }
#                              elsif ($mode eq "delete"){
#                                 return({OP=>$mode,
#                                         MSG=>"delete ip $oldrec->{name} ".
#                                              "from W5Base",
#                                         DATAOBJ=>'itil::ipaddress',
#                                         IDENTIFYBY=>$oldrec->{id},
#                                         });
#                              }
#                              return(undef);
#                           },
#                           $rec->{ipaddresses},$parrec->{ipaddresses},\@opList,
#                           refid=>$rec->{id},netarea=>$netarea);
#         if (!$res){
#            my $opres=ProcessOpList($self->getParent,\@opList);
#         }
      }

      if ($rec->{mandator} eq "Extern" && $rec->{allowifupdate}){
         # forced updates on External Data
         if (!defined($parrec)){
            $forcedupd->{cistatusid}=5;
         }
         else{
            my $databossid;
            my $acgroup=getModuleObject($self->getParent->Config,
                                        "tsacinv::group");
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
    #              my $newdatabossid=$tswiw->GetW5BaseUserID($importname);
    # noch nicht   if (defined($newdatabossid)){
    #                 $databossid=$newdatabossid;
    #              }
               }
            }
            if ($databossid ne ""){
    #           $self->IfaceCompare($dataobj,
    #                               $rec,"databossid",
    # noch nicht                    {databossid=>$databossid},"databossid",
    #                               $forcedupd,$wfrequest,\@qmsg,\$errorlevel,
    #                               mode=>'integer');
            }
    #        my $newname=$parrec->{name};
    #        $newname=~s/[^a-z0-9_-]/_/gi;
    #        $self->IfaceCompare($dataobj,
    #                            $rec,"name",
    #                            {name=>$newname},"name",
    # noch nicht                 $forcedupd,$wfrequest,\@qmsg,\$errorlevel,
    #                            mode=>'string');
           
           
           
#            my $comments="";
#            if ($parrec->{assignmentgroup} ne ""){
#               $comments.="\n" if ($comments ne "");
#               $comments.="AssetCenter AssignmentGroup: ".
#                          $parrec->{assignmentgroup};
#            }
#            if ($parrec->{conumber} ne ""){
#               $comments.="\n" if ($comments ne "");
#               $comments.="AssetCenter CO-Number: ".
#                          $parrec->{conumber};
#            }
#            $self->IfaceCompare($dataobj,
#                                $rec,"comments",
#                                {comments=>$comments},"comments",
#                                $forcedupd,$wfrequest,\@qmsg,\$errorlevel,
#                                mode=>'string');
         }
      }
   }
   else{
      push(@qmsg,'no applicationid specified');
      $errorlevel=3 if ($errorlevel<3);
   }



   if (keys(%$forcedupd)>0){
      msg(INFO,sprintf("forceupd=%s\n",Dumper($forcedupd)));
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
#      printf STDERR ("fifi request a DataIssue Workflow=%s\n",Dumper($wfrequest));
   }

   # now process workflow request for traditional W5Deltas

   # todo

   #######################################################################

   if ($#qmsg!=-1 || $errorlevel>0){
      return($errorlevel,{qmsg=>\@qmsg});
   }

   return($errorlevel,undef);
}



1;
