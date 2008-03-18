package tsacinv::qrule::compareSystem;
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
   my $errorlevel=0;

   return(0,undef) if ($rec->{cistatusid}!=4);
   if ($rec->{systemid} ne ""){
      my $par=getModuleObject($self->getParent->Config(),"tsacinv::system");
      $par->SetFilter({systemid=>\$rec->{systemid}});
      my ($parrec,$msg)=$par->getOnlyFirst(qw(ALL));
      if (!defined($parrec)){
         push(@qmsg,'given systemid not found as active in AssetCenter');
         $errorlevel=3 if ($errorlevel<3);
      }
      else{
         $self->IfaceCompare($dataobj,
                             $rec,"servicesupport",
                             $parrec,"systemola",
                             $forcedupd,$wfrequest,\@qmsg,\$errorlevel,
                             mode=>'leftouterlinkcreate',
                             onCreate=>{
                               comments=>"automaticly create by QualityCheck",
                               cistatusid=>4,
                               name=>$parrec->{systemola}}
                             );
         $self->IfaceCompare($dataobj,
                             $rec,"memory",
                             $parrec,"systemmemory",
                             $forcedupd,$wfrequest,\@qmsg,\$errorlevel,
                             tolerance=>5,mode=>'integer');
         $self->IfaceCompare($dataobj,
                             $rec,"cpucount",
                             $parrec,"systemcpucount",
                             $forcedupd,$wfrequest,\@qmsg,\$errorlevel,
                             mode=>'integer');
      }
      if ($rec->{allowifupdate}){
printf STDERR ("ac=%s\n",Dumper($parrec->{ipaddresses}));
printf STDERR ("w5=%s\n",Dumper($rec->{ipaddresses}));
         my $net=getModuleObject($self->getParent->Config(),"itil::network");
         $net->SetCurrentView(qw(id name));
         my $netarea=$net->getHashIndexed("name");
printf STDERR ("netarea=%s\n",Dumper($netarea));
         my @opList;
         my $res=OpAnalyse(sub{  # comperator 
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
            $comments.="AssetCenter AssignmentGroup: ".
                       $parrec->{assignmentgroup};
         }
         if ($parrec->{conumber} ne ""){
            $comments.="\n" if ($comments ne "");
            $comments.="AssetCenter CO-Number: ".
                       $parrec->{conumber};
         }
         $self->IfaceCompare($dataobj,
                             $rec,"comments",
                             {comments=>$comments},"comments",
                             $forcedupd,$wfrequest,\@qmsg,\$errorlevel,
                             mode=>'string');
      }
   }
   else{
      push(@qmsg,'no systemid specified');
      $errorlevel=3 if ($errorlevel<3);
   }

   if ($rec->{asset} ne ""){
      my $par=getModuleObject($self->getParent->Config(),"tsacinv::asset");
      $par->SetFilter({assetid=>\$rec->{asset}});
      my ($parrec,$msg)=$par->getOnlyFirst(qw(ALL));
      if (!defined($parrec)){
         push(@qmsg,'given assetid not found as active in AssetCenter');
         $errorlevel=3 if ($errorlevel<3);
      }
   }
   else{
      push(@qmsg,'no assetid specified');
      $errorlevel=1 if ($errorlevel<1);
   }



   if (keys(%$forcedupd)){
      printf STDERR ("fifi request a forceupd=%s\n",Dumper($forcedupd));
      if ($dataobj->ValidatedUpdateRecord($rec,$forcedupd,{id=>\$rec->{id}})){
         push(@qmsg,"all desired fields has been updated");
      }
      else{
         push(@qmsg,$self->getParent->LastMsg());
         $errorlevel=3 if ($errorlevel<3);
      }
   }
   if (keys(%$wfrequest)){
      printf STDERR ("fifi request a DataIssue Workflow=%s\n",Dumper($wfrequest));
   }

   # now process workflow request for traditional W5Deltas

   # todo

   #######################################################################

   if ($#qmsg!=-1 || $errorlevel>0){
      return($errorlevel,{qmsg=>\@qmsg});
   }

   return($errorlevel,undef);
}


sub OpAnalyse
{
   my $fpComperator=shift;
   my $fpRecGenerator=shift;
   my $refList=shift;
   my $cmpList=shift;
   my $opList=shift;
   my %param=@_;
 
   if (ref($fpComperator) ne "CODE"){
      return(1); 
   }
   if (ref($fpRecGenerator) ne "CODE"){
      return(2); 
   }
   if (ref($refList) ne "ARRAY"){
      return(10); 
   }
   if (ref($cmpList) ne "ARRAY"){
      return(11); 
   }
   if (ref($opList) ne "ARRAY"){
      return(12); 
   }

   my %cmpRes;
   for(my $refC=0;$refC<=$#{$refList};$refC++){
      my $found=0;
      cmpCloop: for(my $cmpC=0;$cmpC<=$#{$cmpList};$cmpC++){
         if (!exists($cmpRes{$refC."-".$cmpC})){
            $a=$refList->[$refC];
            $b=$cmpList->[$cmpC];
            $cmpRes{$refC."-".$cmpC}=&{$fpComperator}();
            if (defined($cmpRes{$refC."-".$cmpC}) && !$cmpRes{$refC."-".$cmpC}){
               # do an update   
               my $mode="update";
               foreach my $op (&{$fpRecGenerator}($mode,
                                                  $refList->[$refC],
                                                  $cmpList->[$cmpC],
                                                  %param)){
                  if (ref($op) eq "HASH"){
                     $op->{OP}=$mode         if (!exists($op->{OP}));
                     $op->{IDENTIFYBY}=undef if (!exists($op->{IDENTIFYBY}));
                     push(@{$opList},$op);
                  }
               }
            }
         }
         if (defined($cmpRes{$refC."-".$cmpC})){
            $found=1;
            last cmpCloop;
         }
      }
      if (!$found){
         # do a delete
         my $mode="delete";
         foreach my $op (&{$fpRecGenerator}($mode,
                                            $refList->[$refC],
                                            undef,
                                            %param)){
            if (ref($op) eq "HASH"){
               $op->{OP}=$mode         if (!exists($op->{OP}));
               $op->{IDENTIFYBY}=undef if (!exists($op->{IDENTIFYBY}));
               push(@{$opList},$op);
            }
         }
      }
   }
   for(my $cmpC=0;$cmpC<=$#{$cmpList};$cmpC++){
      my $found=0;
      refCloop: for(my $refC=0;$refC<=$#{$refList};$refC++){
         if (!exists($cmpRes{$refC."-".$cmpC})){
            $a=$refList->[$refC];
            $b=$cmpList->[$cmpC];
            $cmpRes{$refC."-".$cmpC}=&{$fpComperator}();
            if (defined($cmpRes{$refC."-".$cmpC}) && !$cmpRes{$refC."-".$cmpC}){
               # do an update   
               my $mode="update";
               foreach my $op (&{$fpRecGenerator}($mode,
                                                  $refList->[$refC],
                                                  $cmpList->[$cmpC],
                                                  %param)){
                  if (ref($op) eq "HASH"){
                     $op->{OP}=$mode         if (!exists($op->{OP}));
                     $op->{IDENTIFYBY}=undef if (!exists($op->{IDENTIFYBY}));
                     push(@{$opList},$op);
                  }
               }
            }
         }
         if (defined($cmpRes{$refC."-".$cmpC})){
            $found=1;
            last refCloop;
         }
      }
      if (!$found){
         # do an insert
         my $mode="insert";
         foreach my $op (&{$fpRecGenerator}($mode,
                                            undef,
                                            $cmpList->[$cmpC],
                                            %param)){
            if (ref($op) eq "HASH"){
               $op->{OP}=$mode         if (!exists($op->{OP}));
               $op->{IDENTIFYBY}=undef if (!exists($op->{IDENTIFYBY}));
               push(@{$opList},$op);
            }
         }
      }
   }
}

sub ProcessOpList
{
   my $self=shift;
   my $opList=shift;
   my $config=$self->Config;
   my $objCache={};
   msg(INFO,"ProcessOpList: Start");
   foreach my $op (@{$opList}){
      if (!exists($objCache->{$op->{DATAOBJ}})){
         $objCache->{$op->{DATAOBJ}}=getModuleObject($config,$op->{DATAOBJ});
      }
      my $dataobj=$objCache->{$op->{DATAOBJ}};
      if (defined($dataobj)){
         $dataobj->ResetFilter();
         printf STDERR ("OP:%s\n",Dumper($op));
         if ($op->{OP} eq "insert"){
            my $id=$dataobj->ValidatedInsertRecord($op->{DATA});
            $op->{IDENTIFYBY}=$id;
            msg(INFO,"insert id ok = $id");
         }
         elsif ($op->{OP} eq "update"){
            if ($op->{IDENTIFYBY} ne ""){
               my $idfield=$dataobj->IdField();
               my $idname=$idfield->Name();
               $dataobj->SetFilter({$idname=>\$op->{IDENTIFYBY}});
               my ($oldrec,$msg)=$dataobj->getOnlyFirst(qw(ALL));
               my $id=$dataobj->ValidatedUpdateRecord($oldrec,$op->{DATA},
                                                 {$idname=>\$op->{IDENTIFYBY}});
               msg(INFO,"update id ok = $id");
            }
         }
         elsif ($op->{OP} eq "delete"){
            if ($op->{IDENTIFYBY} ne ""){
               my $idfield=$dataobj->IdField();
               my $idname=$idfield->Name();
               $dataobj->SetFilter({$idname=>\$op->{IDENTIFYBY}});
               my ($oldrec,$msg)=$dataobj->getOnlyFirst(qw(ALL));
               my $id=$dataobj->ValidatedDeleteRecord($oldrec,
                                                 {$idname=>\$op->{IDENTIFYBY}});
               msg(INFO,"delete id ok = $id");
            }
         }
      }
   }
   msg(INFO,"ProcessOpList: End");
}



1;
