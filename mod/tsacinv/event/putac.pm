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
use Data::Dumper;
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
   $self->RegisterEvent("putacappl","ApplicationModified",timeout=>40000);
#   $self->RegisterEvent("putac","SWInstallModified");
   $self->RegisterEvent("SWInstallModified","SWInstallModified");
   $self->RegisterEvent("ApplicationModified","ApplicationModified");
   $self->RegisterEvent("send2ac","sendFileToAssetCenterOnlineInterface");
   return(1);
}


sub ApplicationModified
{
   my $self=shift;
   my @appid=@_;

   my $elements=0;
   my $acappl=getModuleObject($self->Config,"tsacinv::appl");
   my $applappl=getModuleObject($self->Config,"itil::lnkapplappl");
   my $applsys=getModuleObject($self->Config,"itil::lnkapplsystem");
   my $swinstance=getModuleObject($self->Config,"itil::swinstance");
   my $acgrp=getModuleObject($self->Config,"tsacinv::group");
   my $app=getModuleObject($self->Config,"itil::appl");
   my $user=getModuleObject($self->Config,"base::user");
   my $mand=getModuleObject($self->Config,"base::mandator");
   my $acuser=getModuleObject($self->Config,"tsacinv::user");
   my %filter=(cistatusid=>\'4');
   if ($#appid!=-1){
      $filter{id}=\@appid;
   }
   my %w52ac=(0 =>'OTHER',
              5 =>'CUSTOMER RESPONSIBILITY',
              10=>'APPLICATION LICENSE',
              20=>'TEST',
              30=>'TRAINING',
              40=>'REFERENCE',
              50=>'ACCEPTANCE',
              60=>'DEVELOPMENT',
              70=>'PRODUCTION');
   #$filter{name}="*darwin* *routing*";
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
   if (defined($rec)){
      do{
         #msg(DEBUG,"dump=%s",Dumper($rec));
         my $jobname="W5Base.$self->{jobstart}.".NowStamp().'.Appl_'.
                     sprintf("%d",$rec->{id});
         my @okaglist=qw( VGNV_WIRK BACKUP_SERVER DMZ_SERVER );
        # my @okaglist=qw(
        #    VGNV_WIRK BPO4CONGSTER_WIRK IPS4CONGSTER_BPO_WIRK 
        #    SAP4CONGSTER_FK_WIRK WS4CONGSTER_WIRK WC4CONGSTER_WIRK 
        #    SV4CONGSTER_WIRK DKK_NEU_WIRK REO_WIRK DWH_AW_WIRK 
        #    BACKUP_SERVER DMZ_SERVER
        # );
         if ($rec->{mandatorid} ne $exclmand &&
             (!($rec->{businessteam}=~m/\.BILLING/i) || 
               grep(/^$rec->{name}$/,@okaglist))){
            my $CurrentEventId;
            my $CurrentAppl;
            my $ApplU=0;
            my $SysCount=0;
            {  # systems
               $applsys->SetFilter({applid=>\$rec->{id},
                                    systemcistatusid=>\"4"});
               my @l=$applsys->getHashList(qw(id systemsystemid system
                                              istest iseducation isref 
                                              isapprovtest isdevel isprod
                                              shortdesc systemid));
               foreach my $lnk (@l){
                  my $SysU=0;
                  #$SysU=10 if ($SysU<10 && $lnk->{isnosysappl}); 
                                                          # noch nicht drin
                  $SysU=20 if ($SysU<20 && $lnk->{istest}); 
                  $SysU=30 if ($SysU<30 && $lnk->{iseducation}); 
                  $SysU=40 if ($SysU<40 && $lnk->{isref}); 
                  $SysU=50 if ($SysU<50 && $lnk->{isapprovtest}); 
                  $SysU=60 if ($SysU<60 && $lnk->{isdevel}); 
                  $SysU=70 if ($SysU<70 && $lnk->{isprod}); 
                  $ApplU=$SysU if ($ApplU<$SysU);
                  next if ($lnk->{systemsystemid}=~m/^\s*$/);
                  $CurrentEventId="Add System '$lnk->{system}' to $CurrentAppl";
                  my $acftprec={
                                   CI_APPL_REL=>{
                                      EventID=>$CurrentEventId,
                                      ExternalSystem=>'W5Base',
                                      ExternalID=>$lnk->{id},
                                      Usage=>$w52ac{$SysU},
                                      Appl_ExternalSystem=>'W5Base',
                                      Appl_ExternalID=>$rec->{id},
                                      Port_ExternalSystem=>'W5Base',
                                      Port_ExternalID=>$rec->{systemid},
                                      Security_Unit=>"TS.DE",
                                      Description=>$lnk->{shortdesc},
                                      bDelete=>'0',
                                      bActive=>'1',
                                      Portfolio=>$lnk->{systemsystemid},
                                   }
                               };
                   my $fh=$fh{ci_appl_rel};
                   print $fh hash2xml($acftprec,{header=>0});
                   print $onlinefh hash2xml($acftprec,{header=>0});
                   $SysCount++;
                   $elements++;
               }
            }
            my $acapplrec;
            { # Application
               if ($rec->{applid} ne ""){
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
               foreach my $userent (qw(tsm tsm2 sem databoss)){
                  if ($rec->{$userent} ne ""){
                     $user->SetFilter({fullname=>\$rec->{$userent}});
                     $user->SetCurrentView("posix");
                     my ($rec,$msg)=$user->getFirst();
                     if (defined($rec)){
                        $posix{$userent}=lc($rec->{posix});
                     }
                  }
                  $posix{$userent}="[NULL]" if (!defined($posix{$userent}));
               }
               my $assignment=$rec->{businessteam};
               $assignment=~s/^.*\.CSS\.T-Com/CSS.TCOM/i;
               if ($assignment ne ""){
                  $acgrp->ResetFilter(); 
                  $acgrp->SetFilter({name=>$assignment}); 
                  my ($acgrprec,$msg)=$acgrp->getOnlyFirst(qw(name));
                  if (defined($acgrprec)){
                     $assignment=$acgrprec->{name};
                  }
                  else{
                     $grpnotfound{$assignment}=1;
                     $assignment="CSS.TCOM";
                  }
               }
               else{
                  $assignment="CSS.TCOM";
               }
               my $issoxappl=$rec->{issoxappl};
               $issoxappl="YES" if ($rec->{issoxappl});
               $issoxappl="NO" if (!($rec->{issoxappl}));
               $CurrentAppl="$rec->{name}($rec->{id})";
               $CurrentEventId="Add Application $CurrentAppl";
               $ApplU=10 if ($rec->{isnosysappl} && $SysCount==0);
               $ApplU=5  if (lc($rec->{mandator}) eq "extern");
               my $acftprec={
                                Appl=>{
                                   Customer=>"TS.DE",
                                   Security_Unit=>"TS.DE",
                                   Status=>"IN OPERATION",
                                   Priority=>$rec->{customerprio},
                                   Usage=>$w52ac{$ApplU},
                                   EventID=>$CurrentEventId,
                                   AssignmentGroup=>$assignment,
                                   CO_CC=>$rec->{conumber},
                                   Description=>$rec->{description},
                                   Remarks=>$rec->{comments},
                                   MaintWindow=>$rec->{maintwindow},
                                   Version=>$rec->{currentvers},
                                   SoxRelevant=>$issoxappl,
                                   Technical_Contact=>$posix{tsm},
                                   DataSupervisor=>$posix{databoss},
                                   Service_Manager=>$posix{sem},
                                   Deputy_Technical_Contact=>$posix{tsm2},
                                   bDelete=>'0',
                                   Name=>$rec->{name}
                                }
                            };
               if (defined($acapplrec) && $acapplrec->{applid} ne ""){
                  $acftprec->{Appl}->{Code}=$acapplrec->{applid};
               }
               else{
                  $acftprec->{Appl}->{ExternalSystem}="W5Base";
                  $acftprec->{Appl}->{ExternalID}=$rec->{id};
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
                  $CurrentEventId="Add Interface '$lnk->{toappl}' to $CurrentAppl";
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
                                       cistatusid=>\"4"});
               foreach my $irec ($swinstance->getHashList(qw(ALL))){
                  $CurrentEventId="Instance '$irec->{fullname}'";
                  my $systemid;
                  foreach my $system (sort({$a->{systemsystemid} cmp 
                                            $b->{systemsystemid}} 
                                             @{$irec->{systems}})){
                     if ($system->{systemsystemid} ne ""){
                        $systemid=$system->{systemsystemid};
                        last;
                     }
                  }
                  if ($systemid ne ""){
                     my $assignment=$rec->{swteam};
                     $assignment=~s/^.*\.CSS\.T-Com/CSS.TCOM/i;
                     if ($assignment ne ""){
                        $acgrp->ResetFilter(); 
                        $acgrp->SetFilter({name=>$assignment}); 
                        my ($acgrprec,$msg)=$acgrp->getOnlyFirst(qw(name));
                        if (defined($acgrprec)){
                           $assignment=$acgrprec->{name};
                        }
                        else{
                           $grpnotfound{$assignment}=1;
                           $assignment="CSS.TCOM";
                        }
                     }
                     else{
                        $assignment="CSS.TCOM";
                     }
                     my $model="APPL-INSTANCE";
                     $model="SAP-INSTANCE" if ($irec->{swnature}=~m/^SAP.*$/i); 
                     $model="DB-INSTANCE" if ($irec->{swnature}=~m/mysql/i); 
                     $model="DB-INSTANCE" if ($irec->{swnature}=~m/oracle/i); 
                     $model="DB-INSTANCE" if ($irec->{swnature}=~m/informix/i); 
                     $model="DB-INSTANCE" if ($irec->{swnature}=~m/mssql/i); 
                     $model="DB-INSTANCE" if ($irec->{swnature}=~m/db2/i); 
                     my $swi={Instances=>{
                                EventID=>$CurrentEventId,
                                ExternalSystem=>'W5Base',
                                ExternalID=>$irec->{id},
                                Parent=>$systemid,
                                Name=>$irec->{fullname},
                                Status=>"in operation",
                                Model=>$model,
                                Remarks=>$irec->{comments},
                                Assignment=>$assignment,
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
#   $self->sendFileToAssetCenterOnlineInterface($onlinefilename,$elements);
   return($back);
}

sub sendFileToAssetCenterOnlineInterface
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

   if (Debug()){
      if (open(FI,"<$filename") && open(FO,">/tmp/last.putac.$object.xml")){
         printf FO ("%s",join("",<FI>));
         close(FO);
         close(FI);
      }
   }
   if ($ftp->Connect()){
      msg(INFO,"Connect to FTP Server OK");
      my $jobname="w5base.".$self->{jobstart}.".xml";
      my $jobfile="$object/$jobname";
      msg(INFO,"Processing  job : '%s'",$jobfile);
      msg(INFO,"Processing  file: '%s'",$filename);
      if (!$ftp->Put($filename,$jobfile)){
         msg(ERROR,"File $filename to $jobfile could not be transfered");
      }
      unlink($filename);
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
                             AssignmentGroup=>"CSS.TCOM",
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


sub Template
{
   my $self=shift;
   my @appid=@_;
   my ($fh, $filename);
   $self->{jobstart}=NowStamp();

   my $app=getModuleObject($self->Config,"w5v1inv::appl");
   my $user=getModuleObject($self->Config,"base::user");
   my %filter=(cistatusid=>\'4');
   if ($#appid!=-1){
      $filter{id}=\@appid;
   }
   $app->SetFilter(\%filter);
   $app->SetCurrentView(qw(id name sem tsm tsm2 conumber 
                           description release));
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

   my ($rec,$msg)=$app->getFirst();
   if (defined($rec)){
      do{
         #msg(DEBUG,"dump=%s",Dumper($rec));
         my $acftprec={
                          Appl=>{
                             ExternalSystem=>'W5Base',
                             ExternalID=>$rec->{id},
                             Customer=>"TS.DE",
                          }
                      };
         $acftprec->{Appl}->{Version}=~s/[\n\r]/ /g;
         print $fh hash2xml($acftprec,{header=>0});
         ($rec,$msg)=$app->getNext();
      } until(!defined($rec));
   }
   return($self->TransferFile($fh,$filename,$ftp,"appl"));
}



1;
