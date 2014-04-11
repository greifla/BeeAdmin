package itil::w5stat::base;
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
use kernel::Universal;
@ISA=qw(kernel::Universal);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   return($self);
}

sub getPresenter
{
   my $self=shift;

   my @l=(
          'w5baseitil'=>{
                         opcode=>\&displayW5Base,
                         overview=>\&overviewW5Base,
                         prio=>500,
                      },
          'appl'=>{
                         opcode=>\&displayAppl,
                         overview=>\&overviewAppl,
                         prio=>1000,
                      },
          'system'=>{
                         opcode=>\&displaySystem,
                         overview=>\&overviewSystem,
                         prio=>1001,
                      },
          'asset'=>{
                         opcode=>\&displayAsset,
                         overview=>\&overviewAsset,
                         prio=>1002,
                      },
          'swinstance'=>{
                         opcode=>\&displaySWInstance,
                         overview=>\&overviewSWInstance,
                         prio=>1003,
                      },
          'itilchange'=>{
                         opcode=>\&displayChange,
                         prio=>1101,
                      }
         );

}

sub overviewW5Base
{
   my $self=shift;
   my ($primrec,$hist)=@_;
   my $app=$self->getParent();
   my @l;

   my @flds=("ITIL.Total.Application.Count"=>'W5Base total application count',
             "ITIL.Total.Asset.Count"      =>'W5Base total asset count',
             "ITIL.Total.System.Count"     =>'W5Base total system count');
   
   while(my $k=shift(@flds)){
      my $label=shift(@flds);
      my $val=0;
      if (defined($primrec->{stats}->{$k})){
         $val=$primrec->{stats}->{$k}->[0];
         my $color="black";
         push(@l,[$app->T($label),$val,$color,undef]);
      }
   }   
   return(@l);
}

sub displayW5Base
{
   my $self=shift;
   my ($primrec,$hist)=@_;
   my $app=$self->getParent();
   my $d;

   if ((!defined($primrec->{stats}->{'ITIL.Total.Application.Count'}))){
      return(undef);
   }


   my @flds=("ITIL.Total.Application.Count" =>'total Applications',
             "ITIL.Total.Asset.Count"       =>'total Assets',
             "ITIL.Total.System.Count"      =>'total Systems');
   
   while(my $k=shift(@flds)){ 
      my $label=shift(@flds);
      my $data=$app->extractYear($primrec,$hist,$k);
      my $v="Chart".$k;
      $v=~s/\./_/g;
      my $chart=$app->buildChart($v,$data,
                      width=>500,height=>200,
                      label=>$app->T($label));
      $d.=$chart;

   }   
   return($d);
}





sub overviewAppl
{  
   my $self=shift;
   my ($primrec,$hist)=@_;
   my $app=$self->getParent();
   my @l;

   my $keyname='ITIL.Application.Count';
   if (defined($primrec->{stats}->{$keyname})){
      my $color="black";
      my $delta=$app->calcPOffset($primrec,$hist,$keyname);
      push(@l,[$app->T('Count of Application Config-Items'),
               $primrec->{stats}->{$keyname}->[0],$color,$delta]);
   }

   return(@l);
}

sub displayAppl
{  
   my $self=shift;
   my ($primrec,$hist)=@_;
   return() if ($primrec->{dstrange}=~m/KW/);
   my $app=$self->getParent();
   my $data=$app->extractYear($primrec,$hist,"ITIL.Application.Count");
   my $user=$app->extractYear($primrec,$hist,"User",
                              setUndefZero=>1);
   return(undef) if (!defined($data));
   my $chart=$app->buildChart("ofcAppl",$data,
                   employees=>$user,
                   label=>$app->T('Applications'),
                   legend=>$app->T('count of applications'));
   my $d=$app->getParsedTemplate("tmpl/ext.w5stat.appl",
                              {current=>$primrec,
                               static=>{
                                    statname=>$primrec->{fullname},
                                    chart1=>$chart
                                       },
                               skinbase=>'itil'
                              });
   return($d);
}


sub overviewSystem
{  
   my $self=shift;
   my ($primrec,$hist)=@_;
   my $app=$self->getParent();
   my @l;

   my $keyname='ITIL.System.Count';
   if (defined($primrec->{stats}->{$keyname})){
      my $color="black";
      my $delta=$app->calcPOffset($primrec,$hist,$keyname);
      push(@l,[$app->T('Count of System Config-Items'),
               $primrec->{stats}->{$keyname}->[0],$color,$delta]);
   }
   return(@l);
}

sub displaySystem
{  
   my $self=shift;
   my ($primrec,$hist)=@_;
   return() if ($primrec->{dstrange}=~m/KW/);
   my $app=$self->getParent();
   my $data=$app->extractYear($primrec,$hist,"ITIL.System.Count");
   my $user=$app->extractYear($primrec,$hist,"User",
                              setUndefZero=>1);
   return(undef) if (!defined($data));
   my $chart=$app->buildChart("ofcSystem",$data,
   #                greenline=>4,
                   employees=>$user,
                   label=>$app->T('logical systems'),
                   legend=>$app->T('count of logical systems'));

   my $d=$app->getParsedTemplate("tmpl/ext.w5stat.system",
                              {current=>$primrec,
                               static=>{
                                    statname=>$primrec->{fullname},
                                    chart1=>$chart
                                       },
                               skinbase=>'itil'
                              });
   return($d);
}


sub overviewAsset
{  
   my $self=shift;
   my ($primrec,$hist)=@_;
   my $app=$self->getParent();
   my @l;

   my $keyname='ITIL.Asset.Count';
   if (defined($primrec->{stats}->{$keyname})){
      my $color="black";
      my $delta=$app->calcPOffset($primrec,$hist,$keyname);
      push(@l,[$app->T('Count of Asset Config-Items'),
               $primrec->{stats}->{$keyname}->[0],$color,$delta]);
   }
   return(@l);
}

sub displayAsset
{  
   my $self=shift;
   my ($primrec,$hist)=@_;
   return() if ($primrec->{dstrange}=~m/KW/);
   my $app=$self->getParent();
   my $data=$app->extractYear($primrec,$hist,"ITIL.Asset.Count");
   my $user=$app->extractYear($primrec,$hist,"User",
                              setUndefZero=>1);
   return(undef) if (!defined($data));
   my $chart=$app->buildChart("ofcAsset",$data,
#                   greenline=>4,
                   employees=>$user,
                   label=>$app->T('assets'),
                   legend=>$app->T('count of physical systems'));

   my $d=$app->getParsedTemplate("tmpl/ext.w5stat.asset",
                              {current=>$primrec,
                               static=>{
                                    statname=>$primrec->{fullname},
                                    chart1=>$chart
                                       },
                               skinbase=>'itil'
                              });
   return($d);
}


sub displayChange
{  
   my $self=shift;
   my ($primrec,$hist)=@_;
   return() if ($primrec->{dstrange}=~m/KW/);
   my $app=$self->getParent();
   my $data=$app->extractYear($primrec,$hist,"ITIL.Change.Finish.Count");
   return(undef) if (!defined($data));
   my $chart=$app->buildChart("ofcChange",$data,
#                   greenline=>4,
                   label=>$app->T('changes'),
                   legend=>$app->T('count of changes by businessteam'));

   my $d=$app->getParsedTemplate("tmpl/ext.w5stat.changes",
                              {current=>$primrec,
                               static=>{
                                    statname=>$primrec->{fullname},
                                    chart1=>$chart
                                       },
                               skinbase=>'itil'
                              });
   return($d);
}


sub overviewSWInstance
{  
   my $self=shift;
   my ($primrec,$hist)=@_;
   my $app=$self->getParent();
   my @l;

   my $keyname='ITIL.SWInstance.Count';
   if (defined($primrec->{stats}->{$keyname})){
      my $color="black";
      my $delta=$app->calcPOffset($primrec,$hist,$keyname);
      push(@l,[$app->T('Count of Instance Config-Items'),
               $primrec->{stats}->{$keyname}->[0],$color,$delta]);
   }
   return(@l);
}

sub displaySWInstance
{  
   my $self=shift;
   my ($primrec,$hist)=@_;
   return() if ($primrec->{dstrange}=~m/KW/);
   my $app=$self->getParent();
   my $data=$app->extractYear($primrec,$hist,"ITIL.SWInstance.Count");
   my $user=$app->extractYear($primrec,$hist,"User",
                              setUndefZero=>1);
   return(undef) if (!defined($data));
   my $chart=$app->buildChart("ofcSWInstance",$data,
#                   greenline=>4,
                   employees=>$user,
                   label=>$app->T('swinstance'),
                   legend=>$app->T('count of software instances'));

   my $d=$app->getParsedTemplate("tmpl/ext.w5stat.swinstance",
                              {current=>$primrec,
                               static=>{
                                    statname=>$primrec->{fullname},
                                    chart1=>$chart
                                       },
                               skinbase=>'itil'
                              });
   return($d);
}




sub processData
{
   my $self=shift;
   my $dstrange=shift;
   my %param=@_;
   my ($year,$month)=$dstrange=~m/^(\d{4})(\d{2})$/;
   my $count;


   my $appl=getModuleObject($self->getParent->Config,"itil::appl");
   $appl->SetCurrentView(qw(ALL));
   $appl->SetFilter({cistatusid=>'<=4'});
   $appl->SetCurrentOrder("NONE");
   msg(INFO,"starting collect of itil::appl");$count=0;
   my ($rec,$msg)=$appl->getFirst();
   if (defined($rec)){
      do{
         $self->getParent->processRecord('itil::appl',$dstrange,$rec,%param);
         ($rec,$msg)=$appl->getNext();
         $count++;
      } until(!defined($rec));
   }
   msg(INFO,"FINE of itil::appl  $count records");

   my $swinstance=getModuleObject($self->getParent->Config,"itil::swinstance");
   $swinstance->SetCurrentView(qw(ALL));
   $swinstance->SetFilter({cistatusid=>'<=4'});
   $swinstance->SetCurrentOrder("NONE");
   msg(INFO,"starting collect of itil::swinstance");$count=0;
   my ($rec,$msg)=$swinstance->getFirst();
   if (defined($rec)){
      do{
         $self->getParent->processRecord('itil::swinstance',$dstrange,$rec,
                                         %param);
         ($rec,$msg)=$swinstance->getNext();
         $count++;
      } until(!defined($rec));
   }
   msg(INFO,"FINE of itil::swinstance  $count records");



   my $system=getModuleObject($self->getParent->Config,"itil::system");
   $system->SetFilter({cistatusid=>'<=4'});
   $system->SetCurrentView(qw(ALL));
   $system->SetCurrentOrder("NONE");
   msg(INFO,"starting collect of itil::system");$count=0;
   my ($rec,$msg)=$system->getFirst();
   if (defined($rec)){
      do{
         $self->getParent->processRecord('itil::system',$dstrange,$rec,%param);
         $count++;
         ($rec,$msg)=$system->getNext();
      } until(!defined($rec));
   }
   msg(INFO,"FINE of itil::system  $count records");

   my $asset=getModuleObject($self->getParent->Config,"itil::asset");
   $asset->SetFilter({cistatusid=>'<=4'});
   $asset->SetCurrentView(qw(ALL));
   $asset->SetCurrentOrder("NONE");
   msg(INFO,"starting collect of itil::asset");$count=0;
   my ($rec,$msg)=$asset->getFirst();
   if (defined($rec)){
      do{
         $self->getParent->processRecord('itil::asset',$dstrange,$rec,%param);
         $count++;
         ($rec,$msg)=$asset->getNext();
      } until(!defined($rec));
   }
   msg(INFO,"FINE of itil::asset  $count records");
}


sub processRecord
{
   my $self=shift;
   my $module=shift;
   my $monthstamp=shift;
   my $rec=shift;
   my %param=@_;
   my ($year,$month)=$monthstamp=~m/^(\d{4})(\d{2})$/;

   if ($module eq "itil::appl"){
      my $name=$rec->{name};
      if ($rec->{cistatusid}==4){
         $self->getParent->storeStatVar("Group",[$rec->{businessteam},
                                                 $rec->{responseteam}],{},
                                        "ITIL.Application.Count",1);
         $self->getParent->storeStatVar("Mandator",[$rec->{mandator}],
                                        {nameid=>$rec->{mandatorid},
                                         nosplit=>1},
                                        "ITIL.Application.Count",1);
      }
      if ($rec->{cistatusid}<=5){
         $self->getParent->storeStatVar("Group",["admin"],{},
                                        "ITIL.Total.Application.Count",1);

      }
      if ($rec->{dataissuestate} ne "OK"){
         $self->getParent->storeStatVar("Mandator",[$rec->{mandator}],
                                        {nameid=>$rec->{mandatorid},
                                         nosplit=>1},
                                        "base.DataIssue.open",1);
      }
   }
   if ($module eq "itil::system"){
      if ($rec->{cistatusid}==4){
         $self->getParent->storeStatVar("Group",[$rec->{adminteam}],{},
                                        "ITIL.System.Count",1);
         $self->getParent->storeStatVar("Mandator",[$rec->{mandator}],
                                        {nameid=>$rec->{mandatorid},
                                         nosplit=>1},
                                        "ITIL.System.Count",1);
      }
      if ($rec->{cistatusid}<=5){
         $self->getParent->storeStatVar("Group",["admin"],{},
                                        "ITIL.Total.System.Count",1);
      }
      if ($rec->{dataissuestate} ne "OK"){
         $self->getParent->storeStatVar("Mandator",[$rec->{mandator}],
                                        {nameid=>$rec->{mandatorid},
                                         nosplit=>1},
                                        "base.DataIssue.open",1);
      }
   }
   if ($module eq "itil::swinstance"){
      if ($rec->{cistatusid}==4){
         $self->getParent->storeStatVar("Group",[$rec->{swteam}],{},
                                        "ITIL.SWInstance.Count",1);
      }
      if ($rec->{cistatusid}<=5){
         $self->getParent->storeStatVar("Group",["admin"],{},
                                        "ITIL.Total.SWInstance.Count",1);
      }
   }
   if ($module eq "itil::asset"){
      if ($rec->{cistatusid}==4){
         $self->getParent->storeStatVar("Group",[$rec->{guardianteam}],{},
                                        "ITIL.Asset.Count",1);
      }
      if ($rec->{cistatusid}<=5){
         $self->getParent->storeStatVar("Group",["admin"],{},
                                        "ITIL.Total.Asset.Count",1);
      }
   }
   if ($module eq "base::workflow::active"){
      my $countvar;
      $countvar="ITIL.Change.Finish.Count" if ($rec->{class}=~m/::change$/);
      $countvar="ITIL.Incident.Finish.Count" if ($rec->{class}=~m/::incident$/);
      my @affectedapplication=$rec->{affectedapplication};
      if (ref($rec->{affectedapplication}) eq "ARRAY"){
         @affectedapplication=@{$rec->{affectedapplication}};
      }
      my @affectedapplicationid=$rec->{affectedapplicationid};
      if (ref($rec->{affectedapplicationid}) eq "ARRAY"){
         @affectedapplicationid=@{$rec->{affectedapplicationid}};
      }
      my @affectedcontract=$rec->{affectedcontract};
      if (ref($rec->{affectedcontract}) eq "ARRAY"){
         @affectedcontract=@{$rec->{affectedcontract}};
      }
      my $eend=0;
      if ($rec->{eventend} ne ""){
         my ($eyear,$emonth)=$rec->{eventend}=~m/^(\d{4})-(\d{2})-.*$/;
         $eend=1 if ($eyear==$year && $emonth==$month);
      }
      if ($countvar ne ""){
         foreach my $contract (@affectedcontract){
            $self->getParent->storeStatVar("Contract",$contract,
                                           {nosplit=>1},
                                           $countvar,1) if ($eend);
            if ($rec->{class}=~m/::incident$/){
               $self->getParent->storeStatVar("Contract",$contract,
                                              {nosplit=>1,
                                               method=>'tspan.union'},
                                              "ITIL.Incident",
                                              $rec->{eventstart},
                                              $rec->{eventend});
            }
         }
         foreach my $appl (@affectedapplication){
            $self->getParent->storeStatVar("Application",$appl,{nosplit=>1},
                                           $countvar,1) if ($eend);
            if ($rec->{class}=~m/::incident$/){
               $self->getParent->storeStatVar("Application",$appl,
                                              {nosplit=>1,
                                               method=>'tspan.union'},
                                              "ITIL.Incident",
                                              $rec->{eventstart},
                                              $rec->{eventend});
            }
         }
         my $involvedresponseteam=$rec->{involvedresponseteam};
         my $involvedbusinessteam=$rec->{involvedbusinessteam};
         $involvedresponseteam=[$involvedresponseteam] if (!ref($involvedresponseteam));
         $involvedbusinessteam=[$involvedbusinessteam] if (!ref($involvedbusinessteam));
         my @groups=();
         push(@groups,@$involvedresponseteam);
         push(@groups,@$involvedbusinessteam);
         $self->getParent->storeStatVar("Group",
                         \@groups,{},$countvar,1) if ($eend);
         if ($rec->{class}=~m/::incident$/){
            $self->getParent->storeStatVar("Group",\@groups,
                      {method=>'tspan.union'},
                     "ITIL.Incident",
                     $rec->{eventstart},$rec->{eventend});
         }
      }
   }
}


1;