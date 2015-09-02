package itil::autodiscrec;
#  W5Base Framework
#  Copyright (C) 2015  Hartmut Vogler (it@guru.de)
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
use itil::lib::Listedit;
@ISA=qw(itil::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'W5BaseID',
                dataobjattr   =>'autodiscrec.id'),
                                                  
      new kernel::Field::TextDrop(
                name          =>'entry',
                label         =>'Entry',
                vjointo       =>'itil::autodiscent',
                vjoinon       =>['entryid'=>'id'],
                vjoindisp     =>'id'),
                                                  
      new kernel::Field::Link(
                name          =>'entryid',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'EntryID',
                dataobjattr   =>'autodiscrec.entryid'),
                                                  
      new kernel::Field::Text(
                name          =>'section',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'Section',
                dataobjattr   =>'autodiscrec.section'),
                                                  
      new kernel::Field::Text(
                name          =>'state',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'StateID',   # 1=erfasst ; 10= 1x  ; 20=auto; 100=fail
                dataobjattr   =>'autodiscrec.state'),
                                                  
      new kernel::Field::Text(
                name          =>'scanname',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'Scanname',
                dataobjattr   =>'autodiscrec.scanname'),
                                                  
      new kernel::Field::Text(
                name          =>'scanextra1',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'Scan Extra1',
                dataobjattr   =>'autodiscrec.scanextra1'),
                                                  
      new kernel::Field::Text(
                name          =>'scanextra2',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'Scan Extra2',
                dataobjattr   =>'autodiscrec.scanextra2'),
                                                  
      new kernel::Field::Text(
                name          =>'scanextra3',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'Scan Extra3',
                dataobjattr   =>'autodiscrec.scanextra3'),
                                                  
      new kernel::Field::Text(
                name          =>'discon',
                sqlorder      =>'desc',
                group         =>'source',
                readonly      =>1,
                label         =>'Discovered on',
                dataobjattr   =>'if (system.name is null,'.
                                'swinstance.fullname,system.name)'),
                                                  
      new kernel::Field::Text(
                name          =>'assumed_system',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'assumed_system',
                dataobjattr   =>'autodiscrec.assumed_system'),
                                                  
      new kernel::Field::Text(
                name          =>'assumed_ipaddress',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'assumed_ipaddress',
                dataobjattr   =>'autodiscrec.assumed_ipaddress'),
                                                  
      new kernel::Field::Number(
                name          =>'misscount',
                sqlorder      =>'desc',
                precision     =>0,
                group         =>'source',
                label         =>'Miss count',
                dataobjattr   =>'autodiscrec.misscount'),

      new kernel::Field::Link(
                name          =>'disc_on_systemid',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'discovered on SystemID',
                dataobjattr   =>'autodiscent.discon_system'),

      new kernel::Field::Text(
                name          =>'lnkto_lnksoftware',
                sqlorder      =>'desc',
                label         =>'lnkto_lnksoftware',
                dataobjattr   =>'autodiscrec.lnkto_lnksoftware'),

      new kernel::Field::Text(
                name          =>'lnkto_system',
                sqlorder      =>'desc',
                label         =>'lnkto_system',
                dataobjattr   =>'autodiscrec.lnkto_system'),


      new kernel::Field::Text(
                name          =>'approve_date',
                sqlorder      =>'desc',
                label         =>'approve_date',
                dataobjattr   =>'autodiscrec.approve_date'),

      new kernel::Field::Text(
                name          =>'approve_user',
                sqlorder      =>'desc',
                label         =>'approve_user',
                dataobjattr   =>'autodiscrec.approve_user'),


                                                  
      new kernel::Field::Link(
                name          =>'engineid',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'EngineID',
                dataobjattr   =>'autodiscent.engine'),

      new kernel::Field::Link(
                name          =>'enginename',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'Engine Name',
                dataobjattr   =>'autodiscengine.name'),

      new kernel::Field::Link(
                name          =>'enginefullname',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'Engine Fullname',
                dataobjattr   =>'autodiscengine.fullname'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'autodiscrec.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'autodiscrec.modifydate'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'autodiscrec.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'autodiscrec.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                history       =>0,
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'autodiscrec.srcload'),

   );
   $self->setDefaultView(qw(scanname scanextra1 discon srcsys mdate));
   $self->setWorktable("autodiscrec");
   return($self);
}


#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/autodiscrec.jpg?".$cgi->query_string());
#}


sub getSqlFrom
{
   my $self=shift;
   my $from="autodiscent join autodiscrec ".
                 "on autodiscent.id=autodiscrec.entryid ".
            "join autodiscengine ".
                 "on autodiscent.engine=autodiscengine.id ".
            "left outer join system ".
                 "on autodiscent.discon_system=system.id ".
            "left outer join swinstance ".
                 "on autodiscent.discon_swinstance=swinstance.id";
   return($from);
}




sub isCopyValid
{
   my $self=shift;

   return(1);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default autoimport source));
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default","autoimport") if ($self->IsMemberOf("admin"));
   return(undef);
}

sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}








sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;


   #printf("fifi 01 in $self\n");
   if (effChanged($oldrec,$newrec,"state")){   # statuswechsel auf
      my $s=$newrec->{state}; 
      if ($s eq "10"){   # einmalig 
         $self->doTakeAutoDiscData($oldrec,$newrec);
      }
   }
   #printf("fifi 02 in $self\n");

   if (effChanged($oldrec,$newrec,"scanname") ||
       effChanged($oldrec,$newrec,"scanextra1") ||
       effChanged($oldrec,$newrec,"scanextra2") ||
       effChanged($oldrec,$newrec,"scanextra3")){
      printf STDERR ("AutoDiscRec - scandata has been changed!\n");

      printf STDERR ("AutoDiscRec - oldrec state=$oldrec->{state}!\n");
      printf STDERR ("AutoDiscRec - newrec state=$newrec->{state}!\n");
      if ($oldrec->{state} eq "20" &&
          effVal($oldrec,$newrec,"state") eq "20"){
         printf STDERR ("AutoDiscRec - do automatic Update!\n");
         my ($exitcode,$exitmsg)=$self->doTakeAutoDiscData($oldrec,$newrec);
         if ($exitcode){
            return(0);
         }
      }
      if ($oldrec->{state} eq "10" &&
          (!exists($newrec->{state}) || !defined($newrec->{state}))){
         # Daten�nderungen vorhanden, es wurde aber nur einmaliges Update
         # zugelassen. Der Datensatz mu� somit wieder als unbehandelt 
         # angesehen werden.
         printf STDERR ("AutoDiscRec - reset to unprocessed!\n");
         $newrec->{state}="1";
      }
   }
     
   return(1);
}


sub doTakeAutoDiscData
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $initrelrec=shift;

   my ($exitcode,$exitmsg);

   my $section=effVal($oldrec,$newrec,"section");

   my $systemid=effVal($oldrec,$newrec,"lnkto_system");
   if (defined($initrelrec)){  # in this case, the adrec is not yet linked
      $systemid=$oldrec->{disc_on_systemid};
   }

   my $sysrec;
   my $o=getModuleObject($self->Config,"itil::system");
   if ($systemid ne ""){
      $o->SetFilter({id=>\$systemid});
      my @l=$o->getHashList(qw(ALL));
      if ($#l==0){
         $sysrec=$l[0];
      }
   }
   #######################################################################
   #  SYSTEMNAME Handling  (direct record handling)
   #######################################################################
   if ($section eq "SYSTEMNAME"){


   }
   #######################################################################
   #  SOFTWARE Handling     (related record handling)
   #######################################################################
   elsif ($section eq "SOFTWARE"){   
      if (defined($initrelrec)){  # create a new related record for update
         #printf STDERR ("initrelrec:%s\n",Dumper($initrelrec));
         my $mapsel=$initrelrec->{lnkto_lnksoftware};
         if ($mapsel eq "newSysInst"){
            my $swi=getModuleObject($self->Config,'itil::lnksoftwaresystem');
            my $version=effVal($oldrec,$newrec,"scanextra2");
            my $instpath=effVal($oldrec,$newrec,"scanextra1");
            my $softwareid=$initrelrec->{softwareid};
            if ($softwareid ne ""){
               #printf STDERR ("fifi 03 mapsel=$mapsel\n");
               if ($mapsel=$swi->SecureValidatedInsertRecord({
                      systemid=>$systemid,
                      version=>$version,
                      softwareid=>$softwareid,
                      instpath=>$instpath,
                      quantity=>1
                   })){
                  $exitcode=0;
               }
               else{
                  $exitcode=100;
                  ($exitmsg)=$swi->LastMsg();
               }
            }
         }
         elsif ($mapsel eq "newClustInst"){
            my $swi=getModuleObject($self->Config,
                                    'itil::lnksoftwareitclustsvc');
            my $version=effVal($oldrec,$newrec,"scanextra2");
            my $instpath=effVal($oldrec,$newrec,"scanextra1");
            my $softwareid=$initrelrec->{softwareid};
            my $itclustsvcid=$initrelrec->{itclustsvcid};
            if ($softwareid ne ""){
               if ($mapsel=$swi->SecureValidatedInsertRecord({
                      itclustsvcid=>$itclustsvcid,
                      version=>$version,
                      instpath=>$instpath,
                      softwareid=>$softwareid,
                      quantity=>1
                   })){
                  $exitcode=0;
               }
               else{
                  $exitcode=100;
                  ($exitmsg)=$swi->LastMsg();
               }
            }
         }
         else{  # direct relate to an existing installation
            $exitcode=0;
         }
         if ($exitcode eq "0"){
            if ($mapsel eq int($mapsel)){
               my $swi=getModuleObject($self->Config,'itil::lnksoftware');
               $swi->SetFilter({id=>\$mapsel});
               my @l=$swi->getHashList(qw(ALL));
               if ($#l==0){
                  my %upd;
                  if (effVal($oldrec,$newrec,"scanextra2") ne "" &&
                      $l[0]->{version} ne effVal($oldrec,$newrec,"scanextra2")){
                     $upd{version}=effVal($oldrec,$newrec,"scanextra2");
                  }
                  if (effVal($oldrec,$newrec,"scanextra1") ne "" &&
                      $l[0]->{instpath} ne 
                      effVal($oldrec,$newrec,"scanextra1")){
                     $upd{instpath}=effVal($oldrec,$newrec,"scanextra1");
                  }
                  if (keys(%upd)){
                     if (!$swi->ValidatedUpdateRecord($l[0],\%upd,
                                                      {id=>\$mapsel})){
                        $exitcode=96;
                        ($exitmsg)=$swi->LastMsg();
                     }
                  }
                  if ($exitcode eq "0"){
                     my $userid=$self->getCurrentUserId();

                     #
                     #
                     # Achtung: beim State 100 oder 0 mu� noch das Recht des
                     #          Users gechecked werden
                     #
                     #

                     if (!$self->ValidatedUpdateRecord($oldrec,{
                            state=>$newrec->{state},
                            lnkto_lnksoftware=>$mapsel,
                            lnkto_asset=>undef,
                            lnkto_system=>$systemid,
                            approve_date=>NowStamp("en"),
                            approve_user=>$userid
                          },{id=>\$oldrec->{id}})){
                        return(98,"ERROR: fail to link autodiscrecord");
                     }
                     else{
                        $exitcode=0;
                     }
                  }
               }
               else{
                  return(97,"ERROR: could not find desired installation record");
               }
            }
            else{
               return(99,"ERROR: operation incomplete");
            }
         }
      }
      else{  # Update handling
         my $swiid=effVal($oldrec,$newrec,"lnkto_lnksoftware");
         my $swirec;
         my $o=getModuleObject($self->Config,"itil::lnksoftware");
         if ($swiid ne ""){
            $o->SetFilter({id=>\$swiid});
            my @l=$o->getHashList(qw(ALL));
            if ($#l==0){
               $swirec=$l[0];
            }
         }
         if (defined($sysrec) && defined($swirec)){
            my %upd;
            my $scanextra2=effVal($oldrec,$newrec,"scanextra2");
            if ($swirec->{version} ne $scanextra2){
               $upd{version}=$scanextra2;
            }
            my $scanextra1=effVal($oldrec,$newrec,"scanextra1");
            if ($swirec->{instpath} ne $scanextra1){
               $upd{instpath}=$scanextra1;
            }
            if (keys(%upd)){
               if ($o->SecureValidatedUpdateRecord($swirec,
                                                   \%upd,{id=>\$swiid})){
                  return(0);
               }
               else{
                  return(1,"ERROR: Installation Update failes");
               }
            }
            return(0);  # nothing needs to be update
         }
      }
   }
   else{
      return(1,"ERROR: inposible section handling");
   }
   return($exitcode,$exitmsg);
}


sub AutoDiscFormatEntry
{
   my $self=shift;
   my $rec=shift;
   my $adrec=shift;
   my $control=shift;
   my $d="<form id='AutoDiscFORM$adrec->{id}'>";

   my $s1="";
   my $s2="";
   if ($adrec->{state} eq "100"){
      $s1="<s>";
      $s2="</s>";
   }
   elsif ($adrec->{state} ne "1"){
      $s1="<font color='green'>";
      $s2="</font>";
   }
   $d.="<div class='AutoDiscTitle' adid='$adrec->{id}'>".
       "<table padding=0 margin=0>".
       "<tr><td valign=middle>$s1".
       $adrec->{section}.": <b>".$adrec->{scanname}."</b> @ ".
       $rec->{name}.
       "$s2</td>".
       "<td width=1%>".
       "<img border=0 height=15 class='AutoDiscDetailButton' ".
       "adid='$adrec->{id}' ".
       "src=\"../../../public/base/load/details.gif\"></td></tr>".
       "</table>".
       "</div>";

   $d.="<div class='AutoDiscDetail' id=\"AutoDiscDetail$adrec->{id}\">";
   $d.="<p>";
   $d.="Frist detected on AutoDiscoveryEngine";

   my $elabel=$adrec->{enginefullname};
   if ($elabel ne ""){
      $elabel.=" (".$adrec->{enginename}.")";
   }
   else{
      $elabel=$adrec->{enginename};
   }
   $d.=" <b>".$elabel."</b> ";
   $d.="at";
   $d.=" <i>".$adrec->{cdate}." GMT</i>. ";
   if ($adrec->{section} eq "SOFTWARE"){
      $d.="The Software was detected as";
      $d.=" <b>\"$adrec->{scanname}\"</b> ";
      $d.="in the Version";
      $d.=" <b>\"".$adrec->{scanextra2}."\"</b> ";
      $d.="at the installationpath";
      $d.=" <b>\"".$adrec->{scanextra1}."\"</b>. ";
      
   }
   $d.="<br>";
   $d.="This information was last seen at";
   $d.=" $adrec->{srcload} GMT";
   if ($adrec->{misscount}>0){
      $d.=" ";
      $d.="and was";
      $d.=$adrec->{misscount};
      $d.=" ";
      $d.="times not refreshed";
   }
   $d.=".";
   $d.="</p>";
   if ($self->IsMemberOf("admin")){
      $d.="<pre>NativeDiscoveryRecord:\n".Dumper($adrec)."</pre>";
   }
   $d.="</div>";

   if ($adrec->{state} eq "1"){
      if ($adrec->{section} eq "SOFTWARE"){
         if (!exists($control->{software})){
            $control->{software}={byid=>{}};
            foreach my $swrec (@{$rec->{software}}){
               $control->{software}->{byid}->{$swrec->{id}}={
                  id=>$swrec->{id},
                  softwareid=>$swrec->{softwareid},
                  typ=>'sys'
               };
            }
            if ($rec->{isclusternode} &&
                $rec->{itclustid} ne ""){ # add clusterservice installations
                my $s=getModuleObject($self->Config,
                                      'itil::lnksoftwareitclustsvc');
                $s->SetFilter({itclustid=>\$rec->{itclustid}});
                foreach my $swrec ($s->getHashList(qw(ALL))){
                   $control->{software}->{byid}->{$swrec->{id}}={
                      id=>$swrec->{id},
                      softwareid=>$swrec->{softwareid},
                      typ=>'clust'
                   };
                }
            }
            my $s=getModuleObject($self->Config,'itil::lnksoftware');
            $s->SetFilter({id=>[keys(%{$control->{software}->{byid}})]});
            foreach my $swrec ($s->getHashList(qw(fullname id))){
                $control->{software}->{byid}->{$swrec->{id}}->{fullname}=
                   $swrec->{fullname};
            }
         }
     
         $d.="<div class='AutoDiscMapSel'>";
         $d.="Software zuordnen zu: ";
         $d.="<select name=SoftwareMapSelector adid='$adrec->{id}' ".
             "class=AutoDiscMapSelector>";
         $d.="<option value=''>- bitte ausw�hlen -</option>";
         $d.="<option value='newSysInst'>".
             "neue Software-Installation am logischen System</option>";
         foreach my $swi (sort({
                            $control->{software}->{byid}->{$a}->{fullname} 
                              <=>
                            $control->{software}->{byid}->{$b}->{fullname} 
                          } keys(%{$control->{software}->{byid}}))){
            if ($control->{software}->{byid}->{$swi}->{typ} eq "sys"){
               my $foundmap=0;
               foreach my $me (@{$control->{admap}}){
                  if ($adrec->{engineid} eq $me->{engineid} &&
                      $adrec->{scanname} eq $me->{scanname} &&
                      $control->{software}->{byid}->{$swi}->{softwareid} eq 
                        $me->{softwareid}){
                     $foundmap++;
                  }
               }
               if ($foundmap){
                  $d.="<option value='$swi'>".
                      $control->{software}->{byid}->{$swi}->{fullname}.
                      "</option>";
               }
            }
         }
         if ($rec->{isclusternode}){
            $d.="<option value=''></option>";
            $d.="<option value='newClustInst'>".
                "neue Software-Installation am Cluster-Service</option>";
            foreach my $swi (sort({
                               $control->{software}->{byid}->{$a}->{fullname} 
                                 <=>
                               $control->{software}->{byid}->{$b}->{fullname} 
                             } keys(%{$control->{software}->{byid}}))){
               if ($control->{software}->{byid}->{$swi}->{typ} eq "clust"){
                  my $foundmap=0;
                  foreach my $me (@{$control->{admap}}){
                     if ($adrec->{engineid} eq $me->{engineid} &&
                         $adrec->{scanname} eq $me->{scanname} &&
                         $control->{software}->{byid}->{$swi}->{softwareid} eq 
                           $me->{softwareid}){
                        $foundmap++;
                     }
                  }
                  if ($foundmap){
                     $d.="<option value='$swi'>".
                         $control->{software}->{byid}->{$swi}->{fullname}.
                         "</option>";
                  }
               }
            }
         }
         $d.="</select>";
         $d.="</div>";
     
         $d.="<div class='AutoDiscAddForm' id='AutoDiscAddForm$adrec->{id}'>";
         $d.="<table border=0>";
         if ($rec->{isclusternode}){
            $d.="<tr class='newClustInst'><td width=20%>ClusterService:</td>";
            $d.="<td><select name=itclustsvcid>";
            if ($rec->{itclustid} ne ""){
               my $s=getModuleObject($self->Config,'itil::lnkitclustsvc');
               $s->SetFilter({clustid=>\$rec->{itclustid}});
               foreach my $clustsrec ($s->getHashList(qw(fullname id))){
                  $d.="<option value=\"$clustsrec->{id}\">";
                  $d.="$clustsrec->{fullname}";
                  $d.="</option>";
               }
            }
            $d.="</select></td>";
            $d.="</tr>";
         }
         $d.="<tr><td>Software:</td>";
         $d.="<td><select name=softwareid>";
         my $foundmap=0;
         foreach my $me (@{$control->{admap}}){
            if ($adrec->{engineid} eq $me->{engineid} &&
                $adrec->{scanname} eq $me->{scanname}){
               $d.="<option value='".$me->{softwareid}."'>".
                   $me->{software}."</option>";
               $foundmap++;
            }
         }
         if (!$foundmap){
            return("");
         }
         $d.="</select></td>";
         $d.="</table>";
         $d.="</div>";
      }

      $d.="<div class='AutoDiscOpLine'>";
      $d.="<div class='AutoDiscStatus' id='AutoDiscStatus$adrec->{id}'>";
      $d.="</div>";
      $d.="<div class='AutoDiscButtonBar'>";
      $d.="<input type='image' src='../../itil/load/autodisc_once.jpg' ".
          "title='einmalige Daten�bernahme' disabled ".
          "adid='$adrec->{id}' id='LoadOnce$adrec->{id}' ".
          "class='LoadOnce AutoDiscButton'>";
      $d.="<input type='image' src='../../itil/load/autodisc_bad.jpg' ".
          "title='AutoDisc Daten fehlerhaft ober nicht verwendbar' ".
          "adid='$adrec->{id}' id='BadScan$adrec->{id}' ".
          "class='BadScan AutoDiscButton'>";
      $d.="<input type='image' src='../../itil/load/autodisc_auto.jpg' ".
        "title='Daten �bernehmen mit zuk�nftigem automatischen Aktualisierungen' ".
          "adid='$adrec->{id}' disabled id='LoadAuto$adrec->{id}' ".
          "class='LoadAuto AutoDiscButton'>";
      $d.="</div>"; # end of AutoDiscButtonBar
      $d.="</div>"; # end of AutoDiscOpLine
   }
   if ($adrec->{state} ne "1"){
      $d.="<div class='AutoDiscOpLine'>";
      $d.="<div class='AutoDiscStatus' id='AutoDiscStatus$adrec->{id}'>";
      $d.="</div>";
      $d.="<div class='AutoDiscButtonBar' style='width:1%'>";
      $d.="<input type='image' src='../../itil/load/autodisc_reset.jpg' ".
          "title='reset to unprocessed' ".
          "adid='$adrec->{id}' id='ResetScan$adrec->{id}' ".
          "class='ResetScan AutoDiscButton'>";
      $d.="</div>"; # end of AutoDiscButtonBar
      $d.="</div>"; # end of AutoDiscOpLine
   }
   $d.="</form>"; 
   return($d);
}


sub getValidWebFunctions
{
   my ($self)=@_;

   my @l=$self->SUPER::getValidWebFunctions();
   push(@l,"AutoDiscProcessor");
   return(@l);
}



sub AutoDiscProcessor
{
   my $self=shift;
   my ($func,$p)=$self->extractFunctionPath();

   my $mode=Query->Param("mode");

   my $exitcode=0;
   my $exitmsg;

   #print STDERR "AutoDiscProcessor:".Query->Dumper();
   my $adid=Query->Param("adid");
   my $adrec;
   if ($adid ne ""){
      $self->SetFilter({id=>\$adid});
      my @adrec=$self->getHashList(qw(ALL));
      if ($#adrec==0){
         $adrec=$adrec[0];
      }
   }


   my $userid=$self->getCurrentUserId();
   if (!defined($adrec)){
         $exitcode=10;
         $exitmsg=msg(ERROR,"invalid or empty adid reference '$adid'");
   }
   else{
      if ($mode eq "bad"){
         if (!$self->ValidatedUpdateRecord($adrec,
                                         {
                                          state=>100,
                                          lnkto_lnksoftware=>undef,
                                          lnkto_system=>undef,
                                          lnkto_asset=>undef,
                                          approve_date=>NowStamp("en"),
                                          approve_user=>$userid
                                          },
                                         {id=>\$adrec->{id}})){
            $exitcode=98;
            $exitmsg="ERROR: fail to link autodiscrecord";
         }
      }
      elsif ($mode eq "reset"){
         if (!$self->ValidatedUpdateRecord($adrec,
                                         {
                                          state=>'1',
                                          lnkto_lnksoftware=>undef,
                                          lnkto_system=>undef,
                                          lnkto_asset=>undef,
                                          approve_date=>NowStamp("en"),
                                          approve_user=>$userid
                                          },
                                         {id=>\$adrec->{id}})){
            $exitcode=98;
            $exitmsg="ERROR: fail to link autodiscrecord";
         }
      }
      elsif ($mode eq "auto" || $mode eq "once"){
         my $state;
         $state=10 if ($mode eq "once");
         $state=20 if ($mode eq "auto");

         my $ado=getModuleObject($self->Config,"itil::autodiscrec");
         ($exitcode,$exitmsg)=$ado->doTakeAutoDiscData($adrec,{
            state=>$state,
         },{
            itclustsvcid=>scalar(Query->Param("itclustsvcid")),
            softwareid=>scalar(Query->Param("softwareid")),
            lnkto_lnksoftware=>scalar(Query->Param("SoftwareMapSelector"))
         });
      }
      else{
         $exitcode=1;
         $exitmsg=msg(ERROR,"unknown ajax function call to AutoDiscProcessor");
      }
   }

   print $self->HttpHeader("text/xml");
   my $res=hash2xml({
      document=>{
         exitmsg=>$exitmsg,
         exitcode=>$exitcode
      }
   },{header=>1});
   print($res);
   return(0);
}



sub HtmlAutoDiscManager
{
   my $self=shift;
   my $param=shift;
   my $baseflt=shift;

   my $sysobj=getModuleObject($self->Config,"itil::system");
   my $swiobj=getModuleObject($self->Config,"itil::swinstance");

   my $view=$param->{view};
   if (!exists($param->{filterTypes})){
      $param->{filterTypes}=1;
   }
   if (!exists($param->{allowReload})){
      $param->{allowReload}=1;
   }
   my $d="";
   $d.=$self->HttpHeader();
   $d.=$self->HtmlHeader(body=>1,
                           js=>['toolbox.js',
                                'jquery.js',
                               # 'firebug-lite.js',
                                ],
                           style=>['default.css','work.css',
                                   'Output.HtmlDetail.css',
                                   'kernel.App.Web.css',
                                   'public/itil/load/AutoDisc.css']);
   $d.="<div id=HtmlDetail>";
   $d.="<div id='AutoDiscManager'>";
   $d.="<div style=\"margin:3px;margin-left:5px;display:inline\">";
   if ($param->{allowReload}){
      $d.="<img src=\"../../../public/base/load/reload.gif\" ".
          "style=\"float:right;cursor:pointer\" ".
          "xalign=right id=AutoDiscoveryManagerReloadIcon>";
   }
   $d.="<img src=\"../../../public/base/load/help.gif\" ".
       "style=\"float:right;cursor:pointer\" ".
       "xalign=right id=AutoDiscoveryManagerHelpIcon>";

   $d.="<p style=\"line-height:20px\">".
       "<font size=+1><b>AutoDiscoveryManager:</b></font><br>".
       "</p>";
   $d.="</div>";
   $d.="<div style=\"display:none;dth:80%\" ".
       "id=AutoDiscoveryManagerHelp>";
   $d.=$self->getParsedTemplate("tmpl/AutoDiscManager.help",{
      skinbase=>'itil'
   });
   $d.="</div>";

   if ($param->{filterTypes}){
      $d.="<div class='AutoDiscFilterMap'>";
      $d.="<div style=\"line-height:20px;display:inline\">";

      $d.="Discovery-Datens�tze:";
      my $act=" recSelektorAct" if ($view eq "SelUnproc");
      $d.="<span id='SelUnproc' class=\"recSelektor$act\">unbehandelt</span>";
      my $act=" recSelektorAct" if ($view eq "SelBad");
      $d.="<span id='SelBad' class=\"recSelektor$act\">makiert als fehlerhaft</span>";
      my $act=" recSelektorAct" if ($view eq "SelAll");
      $d.="<span id='SelAll' class=\"recSelektor$act\">alle behandelten</span>";
      $d.="</div>";
      $d.="</div>";
   }



   if ($view eq "SelBad"){
     foreach my $r (@$baseflt){
        $r->{state}=\'100';
     }
   }
   elsif ($view eq "SelAll"){
     foreach my $r (@$baseflt){
        $r->{state}='!1';
     }
   }
   else{
     foreach my $r (@$baseflt){
        $r->{state}=\'1';
     }
   }
   $self->SetFilter($baseflt);
   my @adrec=$self->getHashList(qw(ALL));

   #printf STDERR ("view=$view disc_on_systemid=$id adrec=%s\n",Dumper(\@adrec));

   my %discnam=();

   foreach my $r (@adrec){
      if ($r->{section} eq "SOFTWARE"){
         my $engine=$r->{engineid};
         my $name=$r->{scanname};
         $discnam{$engine.";".$name}={
            engineid=>\$engine,
            scanname=>\$name
         }
      }
   }
   my @admap;
   my $admap=getModuleObject($self->Config,'itil::autodiscmap');
   if (keys(%discnam)){
      $admap->SetFilter([values(%discnam)]);
      @admap=$admap->getHashList(qw(software scanname softwareid engineid));
      @admap=grep({
         my $bk=0;
         if ($_->{software} ne ""){
            $bk=1;
         }
         $bk;
      } @admap);
   }


#print STDERR Dumper(\@adrec);
#print STDERR Dumper(\@admap);



   my %control=(admap=>\@admap,view=>$view);
   my $rec={};
   my $oldrecid;
   foreach my $adrec (@adrec){
      my $recid;
      if (defined($adrec->{disc_on_systemid})){
         $recid="disc_on_systemid:".$adrec->{disc_on_systemid};
      }
      if (defined($adrec->{disc_on_swinstanceid})){
         $recid="disc_on_swinstanceid:".$adrec->{disc_on_swinstanceid};
      }
      if ($oldrecid ne $recid){
         if (defined($adrec->{disc_on_systemid})){
            $sysobj->ResetFilter();
            $sysobj->SetFilter({id=>\$adrec->{disc_on_systemid}});
            my @l=$sysobj->getHashList(qw(ALL));
            $rec=$l[0];
         }
         if (defined($adrec->{disc_on_swinstanceid})){
            $swiobj->ResetFilter();
            $swiobj->SetFilter({id=>\$adrec->{disc_on_swinstanceid}});
            my @l=$swiobj->getHashList(qw(ALL));
            $rec=$l[0];
         }
      }
      my $htmlEnt=$self->AutoDiscFormatEntry($rec,$adrec,\%control);
      if ($htmlEnt ne ""){
         $d.="<div class=AutoDiscRec id='AutoDiscRec".$adrec->{id}."' ".
             "adid='$adrec->{id}'>".$htmlEnt."</div>";
      }
   }
   $d.="<div id='ControlCenterSelectJob'></div>";
   $d.="<pre>";
   #$d.=Dumper(\@adrec);
   $d.="</pre>";
   $d.=<<EOF;
<script language=JavaScript>
function resizeAutoDiscManager(step)
{
   if (step==0){
      \$('#AutoDiscManager').height(5);
      window.setTimeout(function(){resizeAutoDiscManager(10)},1);
   }
   else{
      \$('#AutoDiscManager').height(\$(document).height()-50);
   }
}

\$(document).ready(function(){
   document.title='AutoDiscovery: $rec->{name}';
   resizeAutoDiscManager(0);
});
\$(window).resize(function(){
   resizeAutoDiscManager(0);
});


function setWorking(adid){
   \$('#AutoDiscStatus'+adid).html(
       '<div style="text-align:center">'+
       '<img src="../../base/load/ajaxloader.gif">'+
       '</div>'
   );
}
\$('#AutoDiscoveryManagerHelpIcon').click(function(e){
   e.preventDefault();
   \$('#AutoDiscoveryManagerHelp').slideToggle(200);
   resizeAutoDiscManager();
   return(false);
});

\$('.AutoDiscDetailButton').click(function(e){
   e.preventDefault();
   var adid=\$(this).attr('adid');
   \$('#AutoDiscDetail'+adid).slideToggle(200);
   return(false);
});

\$('#AutoDiscoveryManagerReloadIcon').click(function(e){
   e.preventDefault();
   window.document.location.href=window.document.location.href;
   return(false);
});

\$('.recSelektor').click(function(e){
   var queryParameters = {};
   var queryString=location.search.substring(1);
   var re = /([^&=]+)=([^&]*)/g;
   var m;
 
   while (m = re.exec(queryString)) {
       queryParameters[decodeURIComponent(m[1])] = decodeURIComponent(m[2]);
   }
   queryParameters['view']=\$(this).attr('id');
   location.search = \$.param(queryParameters);

   e.preventDefault();
   return(false);
});



\$('.BadScan').click(function(e){
   e.preventDefault();
   var adid=\$(this).attr('adid');
   if (adid!=""){
      setWorking(adid);
      \$.ajax({
         type: 'POST',
         url: '../../itil/autodiscrec/AutoDiscProcessor',
         data: \$('#AutoDiscFORM'+adid).serialize()+'&adid='+adid+'&mode=bad',
         success: function (data){ handleAjaxCall(adid,data);},
         dataType:'xml'
      });
   }
   return(false);
});

\$('.ResetScan').click(function(e){
   e.preventDefault();
   var adid=\$(this).attr('adid');
   if (adid!=""){
      setWorking(adid);
      \$.ajax({
         type: 'POST',
         url: '../../itil/autodiscrec/AutoDiscProcessor',
         data: 'adid='+adid+'&mode=reset',
         success: function (data){ handleAjaxCall(adid,data);},
         dataType:'xml'
      });
   }
   return(false);
});


function handleAjaxCall(adid,data)
{
   var xml=\$(data);
   var exitcode=xml.find('exitcode');
   if (exitcode){
      exitcode=exitcode.text();
   }
   if (exitcode!="0"){
      var exitmsg=xml.find('exitmsg').text();
      exitmsg="<font color=red>"+exitmsg+"</font>";
      \$('#AutoDiscStatus'+adid).html(exitmsg);
   }
   else{
      \$('#AutoDiscRec'+adid).fadeOut();
   }
}
\$('.LoadOnce').click(function(e){
   e.preventDefault();
   var adid=\$(this).attr('adid');
   if (adid!=""){
      setWorking(adid);
      \$.ajax({
         type: 'POST',
         url: '../../itil/autodiscrec/AutoDiscProcessor',
         data: \$('#AutoDiscFORM'+adid).serialize()+'&adid='+adid+'&mode=once',
         success: function (data){ handleAjaxCall(adid,data);},
         dataType:'xml'
      });
   }
   return(false);
});
\$('.LoadAuto').click(function(e){
   e.preventDefault();
   var adid=\$(this).attr('adid');
   if (adid!=""){
      setWorking(adid);
      \$.ajax({
         type: 'POST',
         url: '../../itil/autodiscrec/AutoDiscProcessor',
         data: \$('#AutoDiscFORM'+adid).serialize()+'&adid='+adid+'&mode=auto',
         success: function (data){ handleAjaxCall(adid,data);},
         dataType:'xml'
      });
   }
   return(false);
});
\$('select[name=SoftwareMapSelector]').change(function(e){
   var adid=\$(this).attr('adid');
   if (this.value==""){
      \$('#AutoDiscAddForm'+adid).hide();
      \$('#LoadAuto'+adid).attr('disabled','disabled');
      \$('#LoadOnce'+adid).attr('disabled','disabled');
      \$('#BadScan'+adid).removeAttr('disabled');
   }
   else if (this.value=="newSysInst"){
      \$('#AutoDiscAddForm'+adid).show();
      var rows=\$('div#AutoDiscAddForm'+adid+' table tr');
      rows.filter('.newClustInst').hide();
      \$('#LoadAuto'+adid).removeAttr('disabled');
      \$('#LoadOnce'+adid).removeAttr('disabled');
      \$('#BadScan'+adid).attr('disabled','disabled');
   }
   else if (this.value=="newClustInst"){
      \$('#AutoDiscAddForm'+adid).show();
      var rows=\$('div#AutoDiscAddForm'+adid+' table tr');
      rows.filter('.newClustInst').show();
      \$('#LoadAuto'+adid).removeAttr('disabled');
      \$('#LoadOnce'+adid).removeAttr('disabled');
      \$('#BadScan'+adid).attr('disabled','disabled');
   }
   else{
      \$('#AutoDiscAddForm'+adid).hide();
      \$('#LoadAuto'+adid).removeAttr('disabled');
      \$('#LoadOnce'+adid).removeAttr('disabled');
      \$('#BadScan'+adid).attr('disabled','disabled');
   }

   
});


</script>
EOF
   $d.="</div>";  # End of AutoDiscManager
   $d.="</div>";  # End of HtmlDetail
   $d.=$self->HtmlBottom(body=>1);
   return($d);
}




1;