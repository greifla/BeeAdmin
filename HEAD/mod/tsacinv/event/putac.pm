package tsacinv::event::putac;
#  W5Base Framework
#  Copyright (C) 2006  Hartmut Vogler (it@guru.de)
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
use kernel::Event;
use kernel::FTP;

use LWP::UserAgent;         # for AC XML Interface
use HTTP::Request::Common;  #
use HTTP::Cookies;          #
use XML::Parser;            #
use HTML::Parser;           #

use File::Temp qw(tempfile);
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub Init
{
   my $self=shift;


   $self->RegisterEvent("putac","ApplicationModified");
   $self->RegisterEvent("putacasset","AssetModified",timeout=>40000);
   $self->RegisterEvent("putacappl","ApplicationModified",timeout=>40000);
#   $self->RegisterEvent("putac","SWInstallModified");
#   $self->RegisterEvent("SWInstallModified","SWInstallModified");
   $self->RegisterEvent("ApplicationModified","ApplicationModified");
   $self->RegisterEvent("send2ac","sendFileToAssetManagerOnlineInterface");
   return(1);
}


#
# Bedingungen f�r einen Asset/System Export
#
# - CO-Nummer mu� eingetragen sein, und in W5Base/Darwin als 
#   installiert/aktiv markiert sein.
# - Betreuungsteam mu� innerhalb von DTAG.TSI.Prod.CSS.AS.DTAG* liegen
#   oder das Adminteam mu� innerhalb von DTAG.TSI.Prod.CSS.AS.DTAG* liegen.
# - Es darf NICHT "automatisierte Updates durch Schnittstellen" zugelassen sein
# - CI-Status mu� "installiert/aktiv" sein
# - Dem Asset mu� min. ein System zugeordnet sein. 
# - Beim System mu� ein Asset eingetragen sein, das in AssetManager aktiv ist.
#

sub getAcGroupByW5BaseGroup
{
   my $self=shift;
   my $grpname=shift;
   my $app=$self->getParent;

   my $acgrp=$app->getPersistentModuleObject("tsacgroup","tsacinv::group");

   $grpname=~s/^.*\.CS\.AO\.DTAG/CSS.AO.DTAG/i;
   $grpname=~s/^.*\.Prod\.CS\.Telco/CSS.AO.DTAG/i;
   $grpname=~s/^.*\.TIT/CSS.AO.DTAG/i;
   $grpname=~s/^DTAG\.TSI\.Prod\.CS\.SDMSS\.PSS\.IMS\.IM2$/CSS.SDM.PSS.CIAM/i;
   $grpname=~s/^DTAG\.TSI\.Prod\.CS\.SDMSS\.PSS\.IMS\.IM3$/CSS.SDM.PSS.CIAM/i;
   $grpname=~s/^DTAG\.TSI\.Prod\.CS\.SDMSS\.PSS/CSS.SDM.PSS/i;
   if ($grpname ne ""){
      $acgrp->SetFilter({name=>$grpname}); 
      my ($acgrprec,$msg)=$acgrp->getOnlyFirst(qw(name));
      if (defined($acgrprec)){
         return($acgrprec->{name});
      }
   }
   else{
      return(undef);
   }
   return(undef);
}

sub mkAcFtpRecAsset
{
   my $self=shift;
   my $rec=shift;
   my %param=@_;

   my $CurrentEventId="Process Asset '$rec->{name}'";
   if ($rec->{conumber} eq ""){
      msg(ERROR,$rec->{name}.
                ": export request without conumber");
      return(undef);
   }
   my $assignment=$self->getAcGroupByW5BaseGroup($rec->{guardianteam});
   if (!defined($assignment)){
      msg(ERROR,$rec->{name}.
                ": no ac coresponding group '$rec->{guardianteam}'");
      return(undef);
   }

 	
   my $acrec={
               Asset=>{
                    EventID=>$CurrentEventId,
                    ExternalSystem=>'W5Base',
                    ExternalID=>$rec->{id},
                    Security_Unit=>"TS.DE",
                    Status=>"in work",
                    Usage=>"Productive",
                    SerialNo=>$rec->{serialno},
                    lCPUNumber=>$rec->{cpucount},
                    Remarks=>$rec->{comments},
                    BriefDescription=>$rec->{kwords},
                    Place=>$rec->{place},
                    Description=>$rec->{comments},
                    Security_Unit=>"TS.DE",
                    bDelete=>'0',
                    Location=>'/DE-BAMBERG-GUTENBERGSTR-13/',
                    Sender_CostCenter=>$rec->{conumber},
                    AssignmentGroup=>$assignment,
                    IncidentAG=>$assignment,
               }
             };
   if ($rec->{hwmodel} eq "PROLIANT DL580"){
      $acrec->{Asset}->{Model_Code}="MGER033852";
   }
   else{
      msg(ERROR,$rec->{name}.
                ": export request model $rec->{hwmodel} not defined");
      return(undef);
   }

   if ($rec->{mandator}=~m/AL DTAG/){
      $acrec->{Asset}->{SC_Location_ID}="3826.0000.0000";# T-Com Bonn Land
      $acrec->{Asset}->{CustomerLink}="TS.DE";           # ?
   }
   else{
      msg(ERROR,$rec->{name}.
                ": export request mandator $rec->{mandator} not defined");
      return(undef);
   }
   return($acrec);
}

sub AssetModified
{
   my $self=shift;
   my @assetname=@_;

   my $system=getModuleObject($self->Config,"itil::system");
   my $asset=getModuleObject($self->Config,"itil::asset");
   my $acsystem=getModuleObject($self->Config,"tsacinv::system");
   my $acasset=getModuleObject($self->Config,"tsacinv::asset");

   my %filter=(cistatusid=>\'2',assetid=>\'',allowifupdate=>\'0');
   $self->{DebugMode}=0;
   if ($#assetname!=-1){
      if (grep(/^debug$/i,@assetname)){
         @assetname=grep(!/^debug$/i,@assetname);
         $self->{DebugMode}=1;
         msg(ERROR,"processing DebugMode - loading '%s'",join(",",@assetname));
      }
      $filter{name}=\@assetname;
   }
   my (%fh,%filename);
   my $ftp=new kernel::FTP($self,"tsacftp");
   if (defined($ftp)){
      if (!($ftp->Connect())){
         return({exitcode=>1,msg=>msg(ERROR,"can't connect to ftp server ".
                "- login fails")});
      }
      $self->{ftp}=$ftp;
   }
   else{
      return({exitcode=>1,msg=>msg(ERROR,"can't create ftp object")});
   }

   $self->{jobstart}=NowStamp();
   ($fh{asset},       $filename{asset}               )=$self->InitTransfer();
   ($fh{system},      $filename{system}              )=$self->InitTransfer();
   $asset->SetFilter({cistatusid=>\'2'});
   $asset->SetCurrentView(qw(ALL));

   my ($rec,$msg)=$asset->getFirst(unbuffered=>1);

   my $acnew=0;
   my $acnewback=0;
   if (defined($rec)){
      do{
         if (1){
            msg(INFO,"now searching externid W5Base/$rec->{id} in ac");
            $acasset->SetFilter([{srcsys=>\'W5Base',srcid=>$rec->{id}},
                                 {assetid=>$rec->{name}}]); 
            my ($acrec,$msg)=$acasset->getOnlyFirst(qw(assetid));
            if (defined($acrec)){
               if (lc($acrec->{assetid}) ne lc($rec->{name})){
                  # transfer erfolgreich - Namensupdate in W5Base durchf�hren
                  # cistatus auf verf�gbar stellen
                  $acnewback++;
               }
            }
            else{
               # asset existiert noch nicht in AC und mu� neu angelegt werden
               my $acftprec=$self->mkAcFtpRecAsset($rec,initial=>1);
               if (defined($acftprec)){
                  my $fh=$fh{asset};
                  print $fh hash2xml($acftprec,{header=>0});
                  $acnew++;
               }
            }
         }
         
         ($rec,$msg)=$asset->getNext();
      } until(!defined($rec));
   }
   msg(INFO,"count status: acnew=$acnew acnewback=$acnewback");
   $self->TransferFile($fh{asset},$filename{asset},
                       $ftp,"asset");
   $self->TransferFile($fh{system},$filename{system},
                       $ftp,"logsys");
}


sub ApplicationModified
{
   my $self=shift;
   my @appid=@_;

   my $elements=0;
   my $acappl=getModuleObject($self->Config,"tsacinv::appl");
   my $applappl=getModuleObject($self->Config,"itil::lnkapplappl");
   my $applsys=getModuleObject($self->Config,"itil::lnkapplsystem");
   my $swinstance=getModuleObject($self->Config,"TS::swinstance");
   my $acgrp=getModuleObject($self->Config,"tsacinv::group");
   my $app=getModuleObject($self->Config,"AL_TCom::appl");
   my $user=getModuleObject($self->Config,"base::user");
   my $mand=getModuleObject($self->Config,"tsacinv::mandator");
   my $mandconfig;
   my $acuser=getModuleObject($self->Config,"tsacinv::user");
   my %filter=(cistatusid=>['3','4']);
   $self->{DebugMode}=0;
   if ($#appid!=-1){
      if (grep(/^debug$/i,@appid)){
         @appid=grep(!/^debug$/i,@appid);
         $self->{DebugMode}=1;
         msg(ERROR,"processing DebugMode - loading ids '%s'",join(",",@appid));
      }
      $filter{id}=\@appid;
   }
   {  # mandator init
      $mand->SetFilter({cistatusid=>[3,4]});
      $mand->SetCurrentView(qw(id grpid defaultassignmentid 
                               defaultassignment doexport));
      $mandconfig=$mand->getHashIndexed(qw(grpid doexport));
      if (ref($mandconfig) ne "HASH"){
         return({exitcode=>1,msg=>msg(ERROR,"can not read mandator config")});
      }
      my @mandid=map({$_->{grpid}} @{$mandconfig->{doexport}->{1}});
      if ($#mandid==-1){
         return({exitcode=>1,msg=>msg(ERROR,"no export mandator")});
      }
      $filter{mandatorid}=\@mandid;
   }



   my %w52ac=(0 =>'OTHER',
              5 =>'CUSTOMER RESPONSIBILITY',
              20=>'TEST',
              25=>'DISASTER',
              30=>'TRAINING',
              40=>'REFERENCE',
              50=>'ACCEPTANCE',
              60=>'DEVELOPMENT',
              70=>'PRODUCTION');
  # $filter{name}="*w5base*";
   $app->SetFilter(\%filter);
   $app->SetCurrentView(qw(ALL));
  # $app->SetCurrentView(qw(id name sem tsm tsm2 conumber currentvers
  #                         description businessteam));

   my (%fh,%filename);
   my $ftp=new kernel::FTP($self,"tsacftp");
   if (defined($ftp)){
      if (!($ftp->Connect())){
         return({exitcode=>1,msg=>msg(ERROR,"can't connect to ftp server ".
                "- login fails")});
      }
      $self->{ftp}=$ftp;
   }
   else{
      return({exitcode=>1,msg=>msg(ERROR,"can't create ftp object")});
   }
   ($fh{appl},         $filename{appl}               )=$self->InitTransfer();
   ($fh{appl_appl_rel},$filename{appl_appl_rel}      )=$self->InitTransfer();
   ($fh{ci_appl_rel},  $filename{ci_appl_rel}        )=$self->InitTransfer();
   ($fh{appl_contact_rel},$filename{appl_contact_rel})=$self->InitTransfer();
   ($fh{instance},     $filename{instance}           )=$self->InitTransfer();
   return($ftp) if (ref($ftp) eq "HASH" || !defined($ftp)); # on errors


   my $exclmand;
   {
      $mand->ResetFilter();
      $mand->SetFilter("name"=>'Extern');
      my ($mandrec,$msg)=$mand->getOnlyFirst(qw(grpid));
      if (defined($mandrec)){
         $exclmand=$mandrec->{grpid};
      }
   }
  

   my ($onlinefh,$onlinefilename);
   if (!(($onlinefh, $onlinefilename) = tempfile())){
      return({msg=>$self->msg(ERROR,'can\'t open tempfile'),exitcode=>1});
   }
   print $onlinefh ("<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n\n");
   print $onlinefh ("<XMLInterface>\n");


   my ($rec,$msg)=$app->getFirst();
   $self->{jobstart}=NowStamp();
   my %grpnotfound;
   my %ciapplrel=();
   if (defined($rec)){
      do{
        # msg(INFO,"dump=%s",Dumper($rec));
        # msg(INFO,"id=$rec->{id}");
         my $jobname="W5Base.$self->{jobstart}.".NowStamp().'.Appl_'.$rec->{id};
         if ($rec->{mandatorid} ne $exclmand ){
            msg(INFO,"process application=$rec->{name} jobname=$jobname");
            my $CurrentEventId;
            my $CurrentAppl=$rec->{name};
            my $ApplU=0;
            my $SysCount=0;
            {  # systems
               $applsys->SetFilter({applid=>\$rec->{id},
                                    systemcistatusid=>['3','4']});
               my @l=$applsys->getHashList(qw(id systemsystemid system
                                              istest iseducation isref 
                                              isapprovtest isdevel isprod
                                              shortdesc systemid
                                              srcsys srcid));
               foreach my $lnk (@l){
                  my $SysU=0;
                  $SysU=20 if ($SysU<20 && $lnk->{istest}); 
                  $SysU=30 if ($SysU<30 && $lnk->{iseducation}); 
                  $SysU=40 if ($SysU<40 && $lnk->{isref}); 
                  $SysU=50 if ($SysU<50 && $lnk->{isapprovtest}); 
                  $SysU=60 if ($SysU<60 && $lnk->{isdevel}); 
                  $SysU=70 if ($SysU<70 && $lnk->{isprod}); 
                  $ApplU=$SysU if ($ApplU<$SysU);
                  next if ($lnk->{systemsystemid}=~m/^\s*$/);
                  next if ($lnk->{srcsys} eq "AM-SAPLNK");
                  next if ($lnk->{srcsys} eq "AM");
                  $CurrentEventId="Add System '$lnk->{system}' to $CurrentAppl";
                  my $externalid=$lnk->{id};
                  if ($externalid eq ""){
                     $externalid="C-".$rec->{id}."-".$lnk->{systemid};
                  }
                  my $acftprec={
                                   CI_APPL_REL=>{
                                      EventID=>$CurrentEventId,
                                      ExternalSystem=>'W5Base',
                                      ExternalID=>$externalid,
                                      Appl_ExternalSystem=>'W5Base',
                                      Appl_ExternalID=>$rec->{id},
                                      Port_ExternalSystem=>'W5Base',
                                      Port_ExternalID=>$lnk->{systemid},
                                      Security_Unit=>"TS.DE",
                                      Description=>$lnk->{shortdesc},
                                      bDelete=>'0',
                                      bActive=>'1',
                                   }
                               };
                  if ($rec->{applid} ne ""){
                     $acftprec->{CI_APPL_REL}->{Application}=uc($rec->{applid});
                  }    
                  if ($lnk->{systemsystemid} ne ""){
                     $acftprec->{CI_APPL_REL}->{Portfolio}=
                            uc($lnk->{systemsystemid});
                     $ciapplrel{"$acftprec->{CI_APPL_REL}->{Portfolio}".
                                "-".
                                $acftprec->{CI_APPL_REL}->{Application}}++;
                  }

                  #
                  # Workaround f�r AktiveBilling (Fachbereich Billing)
                  #
                  #if (!($rec->{businessteam}=~m/\.BILLING/i)){
                  # laut Peter soll die Sache am 13.01. auch f�r Billing gelten
                  $acftprec->{CI_APPL_REL}->{Usage}=$w52ac{$SysU};
                  #}
                  my $fh=$fh{ci_appl_rel};
                  print $fh hash2xml($acftprec,{header=>0});
                  print $onlinefh hash2xml($acftprec,{header=>0});
                  $SysCount++;
                  $elements++;
               }
            }
            { # fill up missing system links by SAP application relations in AM
               if ($rec->{applid} ne ""){
                  $acappl->ResetFilter();
                  $acappl->SetFilter({applid=>\$rec->{applid}});
                  my ($acapplrec,$msg)=$acappl->getOnlyFirst(qw(applid id));
                  if (defined($acapplrec)){
                     my $lnks=getModuleObject($self->Config,
                                              "tsacinv::lnkapplsystem");
                     my $acla=getModuleObject($self->Config,
                                              "tsacinv::lnkapplappl");
                     $acla->SetFilter({lparentid=>\$acapplrec->{id},
                                       type=>\'SAP'});
                     foreach my $lnkrec ($acla->getHashList(qw(ALL))){
                        $lnks->ResetFilter();
                        $lnks->SetFilter({lparentid=>\$lnkrec->{lchildid}});
                        foreach my $srec ($lnks->getHashList(qw(systemid))){
                           if (!exists($ciapplrel{$srec->{systemid}."-".
                                                  $acapplrec->{applid}})){
                              my $externalid="SAPLNK-".$srec->{systemid}."-".
                                             $acapplrec->{applid};
                              my $acftprec={
                                   CI_APPL_REL=>{
                                      EventID=>'link by SAP'.
                                               'appl relation '.
                                               $externalid,
                                      Application=>$acapplrec->{applid},
                                      Portfolio=>$srec->{systemid},
                                      ExternalSystem=>'W5Base',
                                      ExternalID=>$externalid,
                                      Security_Unit=>"TS.DE",
                                      Description=>
                                           'fillup link by SAP'.
                                           'application relation',
                                      bDelete=>'0',
                                      bActive=>'1',
                                   }
                                 };
                             
                              my $fh=$fh{ci_appl_rel};
                              print $fh hash2xml($acftprec,{header=>0});
                              print $onlinefh hash2xml($acftprec,{header=>0});
                           }
                        }
                     }
                  }
               }
            }
            my $acapplrec;
            { # Application
               if ($rec->{applid} ne ""){
                  $acappl->ResetFilter();
                  $acappl->SetFilter({applid=>\$rec->{applid}});
                  ($acapplrec,$msg)=$acappl->getOnlyFirst(qw(applid));
           
               }
               else{
                  $acappl->SetFilter({srcsys=>\'W5Base',srcid=>\$rec->{id}});
                  ($acapplrec,$msg)=$acappl->getOnlyFirst(qw(applid));
                  if (defined($acapplrec) && $acapplrec->{applid} ne ""){
                     $app->UpdateRecord({applid=>$acapplrec->{applid}},
                                        {id=>\$rec->{id}});
                  }
               }
               my %posix=();
               my %idno=();
               foreach my $userent (qw(tsm tsm2 opm opm2 sem databoss 
                                       delmgr delmgr2)){
                  if ($rec->{$userent} ne ""){
                     $user->SetFilter({fullname=>\$rec->{$userent}});
                     $user->SetCurrentView("posix","email");
                     my ($rec,$msg)=$user->getFirst();
                     if (defined($rec)){
                        $posix{$userent}=lc($rec->{posix});
                        if ($posix{$userent} ne ""){
                           $acuser->ResetFilter();
                           $acuser->SetFilter([
                              {
                                 loginname=>\$posix{$userent},
                                 tenant=>\'CS'
                              },
                              {
                                 ldapid=>\$posix{$userent},
                                 tenant=>\'CS'
                              },
                              {
                                 idno=>\$posix{$userent},
                                 tenant=>\'CS'
                              },
                              {
                                 email=>\$rec->{email},
                                 tenant=>\'CS'
                              }
                           ]);
                           my @l=$acuser->getHashList(qw(lempldeptid idno));
                           if ($#l>-1 && $#l<3){
                              $idno{$userent}=$l[0]->{idno};
                           }
                        }
                     }
                  }
                  $posix{$userent}="[NULL]" if (!defined($posix{$userent}));
               }
               my $chkassignment=$rec->{businessteam};
               my $assignment=$self->getAcGroupByW5BaseGroup($chkassignment);
               if (!defined($assignment)){
                  if (exists($mandconfig->{grpid}->{$rec->{mandatorid}})){
                     my $mrec=$mandconfig->{grpid}->{$rec->{mandatorid}};
                     if (defined($mrec->{defaultassignment})){
                        $assignment=$mrec->{defaultassignment};
                        $grpnotfound{$chkassignment}=1;
                     }
                  }
               }
               if (!defined($assignment)){
                  $grpnotfound{$chkassignment}=1;
                  $assignment="CSS.AO.DTAG" 
               }
               my $criticality=$rec->{criticality};
               $criticality=~s/^CR//;
               if ($criticality eq ""){
                  if ($rec->{customerprio}==1){
                     $criticality="critical";
                  }
                  elsif ($rec->{customerprio}==2){
                     $criticality="medium";
                  }
                  else{ 
                     $criticality="none";
                  }
               }
               ########################################################
               my $applref="[NULL]";
               if ($rec->{ictono} ne ""){
                  $applref="CapeTS: ".$rec->{ictono};
               }
               ########################################################
               my $issoxappl=$rec->{issoxappl};
               $issoxappl="YES" if ($rec->{issoxappl});
               $issoxappl="NO" if (!($rec->{issoxappl}));
               $CurrentAppl="$rec->{name}($rec->{id})";
               $CurrentEventId="Add Application $CurrentAppl";
               $ApplU=10 if ($rec->{isnosysappl} && $SysCount==0);
               $ApplU=5  if (lc($rec->{mandator}) eq "extern");
               if ($rec->{opmode} ne ""){
                  $ApplU=70 if ($rec->{opmode} eq "prod");
                  $ApplU=60 if ($rec->{opmode} eq "devel");
                  $ApplU=50 if ($rec->{opmode} eq "approvtest");
                  $ApplU=40 if ($rec->{opmode} eq "reference");
                  $ApplU=30 if ($rec->{opmode} eq "education");
                  $ApplU=25 if ($rec->{opmode} eq "cbreakdown");
                  $ApplU=20 if ($rec->{opmode} eq "test");
               }
               my $acstatus="IN OPERATION";
               if ($rec->{cistatusid}==3){
                  $acstatus="PROJECT";
               }
               my $acftprec={
                                Appl=>{
                                   Security_Unit=>"TS.DE",
                                   Status=>$acstatus,
                                   Priority=>$rec->{customerprio},
                                   EventID=>$CurrentEventId,
                                   AssignmentGroup=>$assignment,
                                   CO_CC=>$rec->{conumber},
                                   Description=>$rec->{description},
                                   CustBusinessDesc=>$rec->{description},
                                   Remarks=>$rec->{comments},
                                   MaintWindow=>$rec->{maintwindow},
                                   IncidentAG=>$rec->{acinmassingmentgroup},
                                   Version=>$rec->{currentvers},
                                   SoxRelevant=>$issoxappl,
                                   Criticality=>$criticality,
                                   Technical_Contact=>$idno{tsm},
                                   DataSupervisor=>$idno{databoss},
                                   Service_Manager=>$idno{sem},
                                   Deputy_Technical_Contact=>$idno{tsm2},
                                   Lead_Del_manager=>$idno{opm},
                                   Del_manager=>$idno{delmgr},
                                   Deputy_Del_manager=>$idno{opm2},
                                   bDelete=>'0',
                                   Name=>$rec->{name},
                                   Appl_Group=>$rec->{applgroup},
                                   Appl_Ref=>$applref
                                }
                            };
               #
               # Workaround f�r AktiveBilling (Fachbereich Billing)
               #
               if (!($rec->{businessteam}=~m/\.BILLING/i)){
                  $acftprec->{Appl}->{Customer}='TS.DE';
                  if ($rec->{customer}=~m/^DTAG.T-Home/i){
                     $acftprec->{Appl}->{Customer}="DTAG, T-COM";
                  }
               }
               # laut Peter soll die Sache am 13.01. auch f�r Billing gelten
               $acftprec->{Appl}->{Usage}=$w52ac{$ApplU};
            
               if (defined($acapplrec) && $acapplrec->{applid} ne "" &&
                   ($acapplrec->{applid}=~m/^(APPL|GER)/)){
                  $acftprec->{Appl}->{Code}=$acapplrec->{applid};
                  $acftprec->{Appl}->{ExternalID}=$rec->{id};
                  $acftprec->{Appl}->{ExternalSystem}="W5Base";
               }
               else{
                  $acftprec->{Appl}->{ExternalSystem}="W5Base";
                  $acftprec->{Appl}->{ExternalID}=$rec->{id};
               }
               if ((!exists($acftprec->{Appl}->{Code}) || 
                     $acftprec->{Appl}->{Code} eq "") &&
                   $rec->{applid} ne "" &&
                   ($rec->{applid}=~m/^(APPL|GER)/)){
                  $acftprec->{Appl}->{Code}=$rec->{applid};
               }
                    
               $acftprec->{Appl}->{Description}=~s/[\n\r]/ /g;
               $acftprec->{Appl}->{Version}=~s/[\n\r]/ /g;
               my $fh=$fh{appl};
               print $fh hash2xml($acftprec,{header=>0});
               print $onlinefh hash2xml($acftprec,{header=>0});
               $elements++;
            }
            { # Interfaces
               $applappl->SetFilter({fromapplid=>\$rec->{id},
                                     toapplcistatus=>\"4"});
               my @l=$applappl->getHashList(qw(id toappl lnktoapplid conproto
                                               toapplid conmode comments));
               foreach my $lnk (@l){
                  $CurrentEventId="Add Interface '$lnk->{toappl}' ".
                                  "to $CurrentAppl";
                  my $acftprec={
                                   APPL_APPL_REL=>{
                                      EventID=>$CurrentEventId,
                                      ExternalSystem=>'W5Base',
                                      ExternalID=>$lnk->{id},
                                      C_Appl_ExternalSystem=>'W5Base',
                                      C_Appl_ExternalID=>$lnk->{toapplid},
                                      UseAssignment=>'Parent',
                                      Type=>$lnk->{conproto},
                                      ReplMode=>$lnk->{conmode},
                                      Description=>$lnk->{comments},
                                      Qty=>'1',
                                      bDelete=>'0',
                                   }
                               };
                   if (defined($acapplrec) && $acapplrec->{applid} ne ""){
                      $acftprec->{APPL_APPL_REL}->{Parent_Appl}=
                                                 $acapplrec->{applid};
                      $acftprec->{APPL_APPL_REL}->{P_Appl_ExternalSystem}='W5Base';
                      $acftprec->{APPL_APPL_REL}->{P_Appl_ExternalID}=$rec->{id};
                   }
                   else{
                      $acftprec->{APPL_APPL_REL}->{P_Appl_ExternalSystem}='W5Base';
                      $acftprec->{APPL_APPL_REL}->{P_Appl_ExternalID}=$rec->{id};
                   }
                   if ($lnk->{lnktoapplid} ne ""){   # only if in the child is
                      $acftprec->{APPL_APPL_REL}->{Child_Appl}=    # an applid
                                                 $lnk->{lnktoapplid};  # known
                      my $fh=$fh{appl_appl_rel};
                      print $fh hash2xml($acftprec,{header=>0});
                      print $onlinefh hash2xml($acftprec,{header=>0});
                      $elements++;
                   }
               }
            }
            {  # prepare contacts
               if (ref($rec->{contacts}) eq "ARRAY"){
                  foreach my $contact (@{$rec->{contacts}}){
                     next if ($contact->{target} ne "base::user");
                     $user->SetFilter({userid=>\$contact->{targetid}});
                     $user->SetCurrentView(qw(ALL));
                     my ($urec,$msg)=$user->getFirst();
                     if (defined($urec)){
                        my $idno;
                        my $posix;
                        if ($urec->{posix} ne ""){
                           $posix=$urec->{posix};
                           $acuser->SetFilter({ldapid=>\$urec->{posix}});
                           $acuser->SetCurrentView(qw(lempldeptid));
                           my ($acrec,$msg)=$acuser->getFirst();
                           if (defined($acrec)){
                              $idno=$acrec->{lempldeptid};
                           }
                        }
                        elsif ($urec->{email} ne ""){
                           $acuser->SetFilter({email=>\$urec->{email}});
                           $acuser->SetCurrentView(qw(lempldeptid));
                           my ($acrec,$msg)=$acuser->getFirst();
                           if (defined($acrec)){
                              $idno=$acrec->{lempldeptid};
                           }
                        }
                        next if ($posix eq "");
                        my $acftprec;
                        if (defined($idno)){
                           $CurrentEventId="Add Contact '$posix' ".
                                           "to $CurrentAppl";
           
                           $acftprec={
                                   APPL_CONTACT_REL=>{
                                      EventID=>$CurrentEventId,
                                      Appl_ExternalSystem=>'W5Base',
                                      Appl_ExternalID=>$rec->{id},
                                      Contact=>uc($posix),
                                      Security_Unit=>"TS.DE",
                                      Description=>'',
                                      bDelete=>'0',
                                   }
                               };
                        }
                        else{
                           $CurrentEventId="New Contact '$urec->{email}' ".
                                           "to $CurrentAppl";
                           $acftprec={
                                   APPL_CONTACT_REL=>{
                                      EventID=>$CurrentEventId,
                                      Appl_ExternalSystem=>'W5Base',
                                      Appl_ExternalID=>$rec->{id},
                                      Description=>'',
                                      Security_Unit=>"TS.DE",
                                      Surname=>$urec->{surname},
                                      Givenname=>$urec->{givenname},
                                      EMail=>$urec->{email},
                                      bDelete=>'0',
                                   }
                               };
                        }
                        my $fh=$fh{appl_contact_rel};
                        print $fh hash2xml($acftprec,{header=>0});
                        print $onlinefh hash2xml($acftprec,{header=>0});
                        $elements++;
                        
                     }
                  }
               }
            }
            if ($rec->{applid} ne ""){ # prepare instances
               $swinstance->ResetFilter();
               $swinstance->SetFilter({applid=>\$rec->{id},
                                       cistatusid=>['3','4']});
               foreach my $irec ($swinstance->getHashList(qw(ALL))){
                  $CurrentEventId="Instance '$irec->{fullname}'";
                  my $systemid;
                  if ($irec->{system} ne ""){
                     my $sys=getModuleObject($self->Config,"itil::system");
                     $sys->SetFilter({id=>\$irec->{systemid}});
                     my ($sysrec,$msg)=$sys->getOnlyFirst(qw(systemid));
                     $systemid=$sysrec->{systemid};
                  }
                  if ($systemid ne ""){
                     my $assignment=$irec->{swteam};
                     $assignment=~s/^.*\.CSS\.AO\.DTAG/CSS.AO.DTAG/i;
                     if ($assignment ne ""){
                        $acgrp->ResetFilter(); 
                        $acgrp->SetFilter({name=>$assignment}); 
                        my ($acgrprec,$msg)=$acgrp->getOnlyFirst(qw(name));
                        if (defined($acgrprec)){
                           $assignment=$acgrprec->{name};
                        }
                        else{
                           $grpnotfound{$assignment}=1;
                           $assignment="CSS.AO.DTAG";
                        }
                     }
                     else{
                        $assignment="CSS.AO.DTAG";
                     }
                     ########################################################
                     my $iassignment=$irec->{acinmassingmentgroup};
                     if ($iassignment eq ""){
                        $iassignment="[NULL]";
                     }
                     ########################################################
                     #
                     # Info von Florian Sahlmann vom 11.06.2008:
                     # SAP-Instance:    M079345
                     # APPL_Instance:   M079346
                     # DB-Instance:     M079347
                     # SELECT BarCode from AmModel where Name = 'DB-INSTANCE';
                     #
                     #
                     my $model="M079346";
                     $model="M079345" if ($irec->{swnature}=~m/^SAP.*$/i); 
                     $model="M079347" if ($irec->{swnature}=~m/mysql/i); 
                     $model="M079347" if ($irec->{swnature}=~m/oracle/i); 
                     $model="M079347" if ($irec->{swnature}=~m/informix/i); 
                     $model="M079347" if ($irec->{swnature}=~m/mssql/i); 
                     $model="M079347" if ($irec->{swnature}=~m/db2/i); 
                     my $swi={Instances=>{
                                EventID=>$CurrentEventId,
                                ExternalSystem=>'W5Base',
                                ExternalID=>$irec->{id},
                                Parent=>uc($systemid),
                                Name=>$irec->{fullname},
                                Status=>"in operation",
                                Model=>$model,
                                Remarks=>$irec->{comments},
                                Assignment=>$assignment,
                                IncidentAG=>$iassignment,
                                CostCenter=>$rec->{conumber},
                                Security_Unit=>"TS.DE",
                                CustomerLink=>"TS.DE",
                                bDelete=>'0'
                              }
                             };
                     my $fh=$fh{instance};
                     print $fh hash2xml($swi,{header=>0});
                     print $onlinefh hash2xml($swi,{header=>0});
                     $elements++;
                  }
               }
            }
            #print Dumper($rec->{contacts});
         }
         else{
            msg(INFO,"skipped application=$rec->{name} jobname=$jobname");
         }

         ($rec,$msg)=$app->getNext();
      } until(!defined($rec));
   }
   my %faillog=();
   if (keys(%grpnotfound)){
      $faillog{MissingGroup}={name=>[keys(%grpnotfound)]};
   }
   if (open(F,">/tmp/last.putac.faillog.xml")){
      print F hash2xml(\%faillog,{header=>1});
      close(F);
   }
   print $onlinefh ("</XMLInterface>\n");
   close($onlinefh);

   $self->TransferFile($fh{instance},$filename{instance},
                       $ftp,"instance");
   $self->TransferFile($fh{appl_contact_rel},$filename{appl_contact_rel},
                       $ftp,"appl_contact_rel");
   $self->TransferFile($fh{ci_appl_rel},$filename{ci_appl_rel},
                       $ftp,"ci_appl_rel");
   $self->TransferFile($fh{appl_appl_rel},$filename{appl_appl_rel},
                       $ftp,"appl_appl_rel");
   my $back=$self->TransferFile($fh{appl},$filename{appl},$ftp,"appl");

# temp deakiv, da div. Schnittstellenprobleme noch nicht gekl�rt sind.
#   $self->sendFileToAssetManagerOnlineInterface($onlinefilename,$elements);
   return($back);
}

sub sendFileToAssetManagerOnlineInterface
{
   my $self=shift;
   my $filename=shift;
   my $elements=shift;
   $elements=100000 if (!defined($elements) || $elements==0);

   my $iurl=$self->getParent->Config->Param('DATAOBJSERV');
   my $user=$self->getParent->Config->Param('DATAOBJUSER');
   my $pass=$self->getParent->Config->Param('DATAOBJPASS');
   $iurl={} if (ref($iurl) ne "HASH");
   $user={} if (ref($user) ne "HASH");
   $pass={} if (ref($pass) ne "HASH");
   $iurl=$iurl->{tsaconline};
   $user=$user->{tsaconline};
   $pass=$pass->{tsaconline};
   msg(DEBUG,"Init HTTP Transfer to   : %s",$iurl);
   msg(DEBUG,"AC XML Online-Interface : %s:%s",$user,$pass);
   return($self->sendToAConlineIf($filename,$user,$pass,$iurl,$elements));
}


sub sendToAConlineIf
{
   my $self=shift;
   my $filename=shift;
   my $user=shift;
   my $pass=shift;
   my $iurl=shift;
   my $elements=shift;

   my $timeout=5+2.5*$elements;
   if (open(F,"<$filename") && open(FO,">/tmp/last.AC.Online.put.xml")){
      while(<F>){print FO ($_);}
      close(FO);
      close(F);
   }
   else{
      msg(ERROR,"problems with opening '%s' or tempfile",$filename);
   }
   my $ua=new LWP::UserAgent();
   my $CurrentTag;
   my $ViewState;
   my $EventValidation;
   my $sendname=$filename;
   $sendname=$filename.".xml" if (!($sendname=~m/\.xml$/i));
   $sendname=~s/^.*\///;
   $ua->cookie_jar(HTTP::Cookies->new(file => "$ENV{HOME}/.cookies.txt"));
   my %SubmitForm=();
   $ua->timeout(10);
   msg(DEBUG,"requesting formular");
   my $response=$ua->request(GET($iurl));
   if ($response->code eq "200"){
      msg(INFO,"Parsing original HTML Formular");
      my $htmlp=new HTML::Parser();
      $htmlp->handler(start=>sub {
                            my ($self,$tag,$attr)=@_;
                            if (lc($tag) eq "input"){
                               $SubmitForm{$attr->{name}}=$attr->{value};
                            }
                         },'self, tagname, attr');
      if (open(FO,">/tmp/last.AC.Online.form.html")){
         print FO ($response->content);
         close(FO);
      }
      eval('$htmlp->parse($response->content);');
      if ($@ ne ""){
         msg(ERROR,"html error '%s'",$@);
         msg(ERROR,$response->content);
         return(undef);
      }
   }
   else{
      msg(ERROR,"can't access web url '%s'",$iurl);
      msg(ERROR,"%s",$response->as_string);
      return(undef);
   }
   $SubmitForm{File1}=[$filename,$sendname,'Content-Type'=>'text/xml'];
   $SubmitForm{txWSpwd}=$pass;
   $SubmitForm{txwsLogin}=$user;
   my $req=POST($iurl,Content_Type=>'form-data',Content=>[%SubmitForm]);
   #
   # Check the result (code must be 302)
   #
   $ua->timeout($timeout);
   msg(DEBUG,"requesting operations with timeout=$timeout");
   $response=$ua->request($req);
   if ($response->code ne "302"){
       msg(ERROR,"can't get expected web result. (%s) status_line='%s'",
           $response->code,$response->status_line);
       msg(DEBUG,"%s",$response->as_string);
       return(undef);
   }
   #
   # Load new Location
   #
   my $newiurl=$response->header("Location");
   $iurl=~s/^(\S+:\/\/\S+?)\/.*$/$1$newiurl/;
   msg(DEBUG,"Redirecting to : $iurl");
   $ua->timeout(10);
   $response=$ua->request(GET($iurl));
   if (open(FO,">/tmp/last.AC.Online.result.xml")){
      print FO ($response->content());
      close(FO);
   }
   if ($response->code ne "200"){
      msg(ERROR,"unexpected http repsonse code after redirct=%s",
          $response->code);
      msg(DEBUG,"%s",$response->as_string);
      return(undef);
   }
   #
   # Processing resulting XML file
   #
   my $xmlp=new XML::Parser();
   my $CurrentEventID;
   my $CurrentEventCode;
   my $CurrentEventError;
   my $CurrentEventKey;
   $xmlp->setHandlers(Start=>sub {
                         my ($p,$tag,%attr)=@_;
                         $CurrentTag=$tag;
                         $CurrentTag=undef if (lc($tag) eq lc("Response"));
                      },
                      End=>sub{
                         my ($p,$tag,%attr)=@_;
                         if (lc($tag) eq lc("Response")){
                            if ($CurrentEventCode ne "0"){
                               if (!($CurrentEventKey=~m/^\s*$/)){
                                  $CurrentEventError.=" ($CurrentEventKey)";
                               }
                               msg(ERROR,"EventID: %s",$CurrentEventID);
                               msg(ERROR,"%s",$CurrentEventError);
                            }
                         }
                      },
                      Char=>sub {
                         my ($p,$s)=@_;
                         if (lc($CurrentTag) eq lc("EventId")){
                            $CurrentEventID=$s;
                         }
                         elsif (lc($CurrentTag) eq lc("Error_Code")){
                            $CurrentEventCode=$s;
                         }
                         elsif (lc($CurrentTag) eq lc("Error_Desc")){
                            $CurrentEventError=$s;
                         }
                         elsif (lc($CurrentTag) eq lc("Key")){
                            $CurrentEventKey=$s;
                         }
                         else{
                          #  msg(DEBUG,"($CurrentEventID) s=$s");
                         }
                      });
   eval('$xmlp->parse($response->content);');
   return(1) if ($@ eq "");
   return(undef);
}

sub InitTransfer
{
   my $self=shift;
   my $fh;
   my $filename;

   if (!(($fh, $filename) = tempfile())){
      return({msg=>$self->msg(ERROR,'can\'t open tempfile'),exitcode=>1});
   }
   print $fh ("<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n\n");
   print $fh ("<XMLInterface>\n");

   return($fh,$filename);
}

sub TransferFile
{
   my $self=shift;
   my $fh=shift;
   my $filename=shift;
   my $ftp=shift;
   my $object=shift;

   print $fh ("</XMLInterface>\n");
   close($fh);

   if (open(FI,"<$filename") && open(FO,">/tmp/last.putac.$object.xml")){
      printf FO ("%s",join("",<FI>));
      close(FO);
      close(FI);
   }
   if ($ftp->Connect()){
      msg(INFO,"Connect to FTP Server OK");
      my $jobname="w5base.".$self->{jobstart}.".xml";
      my $jobfile="$object/$jobname";
      msg(INFO,"Processing  job : '%s'",$jobfile);
      msg(INFO,"Processing  file: '%s'",$filename);
      if (!$self->{DebugMode}){
         if (!$ftp->Put($filename,$jobfile)){
            msg(ERROR,"File $filename to $jobfile could not be transfered");
            msg(ERROR,"File $filename results: ".$ftp->message);
         }
         unlink($filename);
      }
      $ftp->Disconnect();
   }
   else{
      return({msg=>$self->msg(ERROR,'can\'t connect to ftp srv'),exitcode=>1});
   }

   return({exitcode=>0,msg=>'OK'});
}




sub SWInstallModified
{
   my $self=shift;
   my @refid=@_;
   my ($fh, $filename);
   $self->{jobstart}=NowStamp();

   my $lnk=getModuleObject($self->Config,"w5v1inv::lnksoftware2system");
   my $sys=getModuleObject($self->Config,"w5v1inv::system");
   my %filter=();
   if ($#refid!=-1){
      $filter{id}=\@refid;
   }
   $lnk->SetFilter(\%filter);
   #$lnk->Limit(100);
   $lnk->SetCurrentView(qw(id w5systemid software version licencecount));
   my $ftp=new kernel::FTP($self,"tsacftp");
   if (defined($ftp)){
      if (!($ftp->Connect())){
         return({exitcode=>1,msg=>msg(ERROR,"can't connect to ftp server ".
                "- login fails")});
      }
      $self->{ftp}=$ftp;
   }
   else{
      return({exitcode=>1,msg=>msg(ERROR,"can't create ftp object")});
   }
   my ($fh,$filename)=$self->InitTransfer();
   return($ftp) if (ref($ftp) eq "HASH" || !defined($ftp)); # on errors

   my ($rec,$msg)=$lnk->getFirst();
   if (defined($rec)){
      do{
         #msg(DEBUG,"dump=%s",Dumper($rec));
         my $jobname="W5Base.$self->{jobstart}.".NowStamp().'.SWInstall_'.
                     sprintf("%d",$rec->{id});
         my $acftprec={
                          SWInstall=>{
                             ExternalSystem=>'W5Base',
                             ExternalID=>$rec->{id},
                             Customer=>"TS.DE",
                             Status=>"installed/active",
                             EventID=>$jobname,
                             AssignmentGroup=>"CSS.AO.DTAG",
                             SoftwareVersion=>$rec->{version},
                             SoftwareName=>$rec->{software},
                             LicenseUnits=>$rec->{licencecount},
                          }
                      };
         if (defined($rec->{w5systemid})){
            $sys->SetFilter(w5systemid=>$rec->{w5systemid});
            my $systemid=$sys->getVal("systemid");
            $acftprec->{SWInstall}->{AssetTag}=$systemid if ($systemid ne "");
         }
         print $fh hash2xml($acftprec,{header=>0});
         ($rec,$msg)=$lnk->getNext();
      } until(!defined($rec));
   }
   return($self->TransferFile($fh,$filename,$ftp,"swinstall"));


}



1;
