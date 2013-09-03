package TS::system;
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
use kernel::Field;
use itil::system;
@ISA=qw(itil::system);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::TextDrop(
                name          =>'acassingmentgroup',
                label         =>'AssetManager Assignmentgroup',
                group         =>'admin',
                weblinkto     =>'tsacinv::group',
                weblinkon     =>['acassingmentgroup'=>'name'],
                searchable    =>0,
                readonly      =>1,
                async         =>'1',
                vjointo       =>'tsacinv::system',
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>'assignmentgroup'),

      new kernel::Field::TextDrop(
                name          =>'aciassignmentgroup',
                label         =>'AM Incident-Assignmentgroup',
                group         =>'admin',
                weblinkto     =>'tsacinv::group',
                weblinkon     =>['aciassignmentgroup'=>'name'],
                searchable    =>0,
                readonly      =>1,
                async         =>'1',
                vjointo       =>'tsacinv::system',
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>'iassignmentgroup'),

      new kernel::Field::TextDrop(
                name          =>'accontrolcenter',
                label         =>'AM System ControlCenter',
                group         =>'admin',
                weblinkto     =>'tsacinv::group',
                weblinkon     =>['accontrolcenter'=>'name'],
                async         =>'1',
                searchable    =>0,
                readonly      =>1,
                vjointo       =>'tsacinv::system',
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>'controlcenter'),

      new kernel::Field::TextDrop(
                name          =>'accontrolcenter2',
                label         =>'AM Application ControlCenter',
                group         =>'admin',
                weblinkto     =>'tsacinv::group',
                weblinkon     =>['accontrolcenter2'=>'name'],
                async         =>'1',
                searchable    =>0,
                readonly      =>1,
                vjointo       =>'tsacinv::system',
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>'controlcenter2'),

      new kernel::Field::TextDrop(
                name          =>'acsystemname',
                label         =>'AssetManager Systemname',
                group         =>'logsys',
                async         =>'1',
                searchable    =>0,
                readonly      =>1,
                vjointo       =>'tsacinv::system',
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>'systemname'),
      new kernel::Field::Boolean(
                name          =>'acsoxrelevant',
                label         =>'AssetManager SOX relevant',
                group         =>'logsys',
                searchable    =>0,
                weblinkto     =>'NONE',
                async         =>'1',
                readonly      =>1,
                vjointo       =>'tsacinv::system',
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>'soxrelevant'),

      new kernel::Field::Textarea(
                name          =>'ipanalyse',
                label         =>'IP-Analyse',
                depend        =>['name','systemid','rawipanalyse'],
                group         =>'ipaddresses',
                htmldetail    =>0,
                searchable    =>0,
                readonly      =>1,
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $f=$self->getParent->getField("rawipanalyse");
                   my $a=$f->RawValue($current);
                   my $d="";
                   $d.=join("\n",
                            map({"$_->{class}(".$_->{level}."): ".
                                 $_->{label}} @{$a->{systemname}->{msg}}));
                   return($d);
                }),

      new kernel::Field::Interface(
                name          =>'rawipanalyse',
                label         =>'raw IP-Analyse',
                depend        =>['name','systemid','rawipanalyse',
                                 'ipaddresses','isclusternode','itclustid'],
                group         =>'ipaddresses',
                htmldetail    =>0,
                searchable    =>0,
                readonly      =>1,
                onRawValue    =>\&doIPanalyse),
   );

   return($self);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (exists($newrec->{systemid})){
      $newrec->{systemid}=uc($newrec->{systemid}); # T-Systems Standard laut AM
   }
   return($self->SUPER::Validate($oldrec,$newrec));
}

sub doIPanalyse
{
   my $self=shift;
   my $rec=shift;
   my $p=$self->getParent();
   return(undef) if (!defined($rec));
   my $c=$self->Cache();

   my $id=$rec->{id};
   my $systemname=$rec->{name};
   my $systemid=$rec->{systemid};
   my $isclusternode=$rec->{isclusternode};

   my $acsys=$p->getPersistentModuleObject("tsacinv::system");
   my $acautosys=$p->getPersistentModuleObject("tsacinv::autodiscsystem");
   my $noahRec=$p->getPersistentModuleObject("tsnoah::ipaddress");
   my $itclust=$p->getPersistentModuleObject("itil::itclust");
   my $lnkitclustsvc=$p->getPersistentModuleObject("itil::lnkitclustsvc");

   #######################################################################
   # Default Analyse Record
   my %a=($systemname=>{
         itinv=>1,
         ip=>{},
         itinvIP=>{},
         acIP=>{},
         autodiscIP=>{},
         isclusternode=>$isclusternode,
      },
      SHARED=>{
         ip=>{}
      }
   );
   #######################################################################
   # IT-Inventar lesen
   my $ipaddresses=$p->getField("ipaddresses")->RawValue($rec);
   map({$a{$systemname}->{ip}->{$_->{name}}={}}      @$ipaddresses);
   map({$a{$systemname}->{itinvIP}->{$_->{name}}={}} @$ipaddresses);
   push(@{$a{$systemname}->{nodes}},
         {name=>$systemname,systemid=>$systemid});
   
   if ($a{$systemname}->{isclusternode}){
      # load all nodes in cluster and all packages
      if ($rec->{itclustid} ne ""){
         $itclust->SetFilter({id=>\$rec->{itclustid}});
         my ($itclustrec)=$itclust->getOnlyFirst(qw(systems)); 
         if (defined($itclustrec)){
            print STDERR Dumper($itclustrec);
            foreach my $s (@{$itclustrec->{systems}}){
               if (!in_array([map({$_->{systemid}} 
                                  @{$a{$systemname}->{nodes}})],
                   $s->{systemid})){
                  push(@{$a{$systemname}->{nodes}},
                        {name=>$s->{name},systemid=>$s->{systemid}});
               }
            }
         }
         # load all clusterpackage IP-Adresses
         $lnkitclustsvc->SetFilter({clustid=>$rec->{itclustid}});
         foreach my $svc ($lnkitclustsvc->getHashList(qw(fullname 
                           ipaddresses))){
            foreach my $ip (@{$svc->{ipaddresses}}){
               $a{SHARED}->{ip}->{$ip->{name}}={}
            }
         }
      }
   }
   foreach my $s (@{$a{$systemname}->{nodes}}){
      my $node=$s->{name};
      my $nodesystemid=$s->{systemid};

      #####################################
      # AssetManager lesen
      if ($systemid ne ""){
         $a{$node}->{systemid}=$nodesystemid;
         $acsys->ResetFilter();
         $acsys->SetFilter({systemid=>\$nodesystemid});
         my ($acrec,$msg)=$acsys->getOnlyFirst(qw(systemname ipaddresses));
         if (defined($acrec)){
            $a{$node}->{acsystemname}=$acrec->{systemname};
            map({$a{$node}->{ip}->{$_->{ipaddress}}={}}
                @{$acrec->{ipaddresses}});
            map({$a{$node}->{acIP}->{$_->{ipaddress}}={}}
                @{$acrec->{ipaddresses}});
         }
      }
      #####################################
      # AssetManager autodiscovery lesen
      if ($systemid ne ""){
         $acautosys->ResetFilter();
         $acautosys->SetFilter({systemid=>\$nodesystemid});
         my ($acrec,$msg)=$acautosys->getOnlyFirst(qw(name ipaddresses));
         if (defined($acrec)){
            $a{$node}->{acautosystemname}=$acrec->{name};
            map({$a{$node}->{ip}->{$_->{name}}={}}
                @{$acrec->{ipaddresses}});
            map({$a{$node}->{acautoIP}->{$_->{name}}={}}
                @{$acrec->{ipaddresses}});
         }
      }
      #####################################
      # NOAH Registry lesen
      $noahRec->SetFilter([{systemname=>$node},
                          {name=>[keys(%{$a{$node}->{ip}})]}]);
      my @l=$noahRec->getHashList(qw(systemname name));
      $a{$node}->{noahRec}=\@l;
      foreach my $n (@l){
         $a{$node}->{noahIP}->{$n->{name}}={name=>$n->{systemname}};
      }
      #######################################################################
   }
   # Analyse durchf�hren
   my $a=\%a;


   # check if all found ip adresses are exists in autodisc data
   foreach my $ip (keys(%{$a->{$systemname}->{acIP}})){
      if (!exists($a->{$systemname}->{acautoIP}->{$ip})){
         my $ok=0;
         if ($a->{$systemname}->{isclusternode}){
            if (exists($a->{SHARED}->{ip}->{$ip})){
               $ok++;  # alles Super - $ip ist eine ClusterPacket Adresse
            }
            if (!$ok){
               foreach my $node (map({$_->{name}} 
                                     @{$a->{$systemname}->{nodes}})){
                  if (exists($a->{$node}->{acautoIP}->{$ip})){
                     $ok++; # nicht schoen - aber OK - die IP ist auf einem
                  }         # anderen Node im Cluster registriert
               }
            }
         }
         if (!$ok){
            my $clusttext="";
            if ($a->{$systemname}->{isclusternode}){
               $clusttext=" or any other node in the cluster"; 
            }
            push(@{$a->{systemname}->{msg}},
               {class=>'ac.ipoverhead',
                level=>2,
                label=>"The IP-Address '$ip' found in AssetManager, ".
                       "can not be detected (autodiscovery) on the ".
                       "system '$systemname' ($systemid)$clusttext."
                });
         }
      }
      if (exists($a->{$systemname}->{noahIP}->{$ip})){
         my $noahname=$a->{$systemname}->{noahIP}->{$ip}->{name};
         if (lc($noahname) ne lc($systemname)){
            push(@{$a->{systemname}->{msg}},
               {class=>'noah.issue',
                level=>3,
                label=>"The IP-Address '$ip' found in AssetManager, ".
                       "on system '$systemname' belongs in NOAH to ".
                       "an other system ($noahname). ".
                       "This can be very critical." 
                });
         }
      }
   }
   foreach my $ip (keys(%{$a->{$systemname}->{acautoIP}})){
      if (!exists($a->{$systemname}->{acIP}->{$ip})){
         my $ok=0;
         if ($a->{$systemname}->{isclusternode}){
            if (exists($a->{SHARED}->{ip}->{$ip})){
               $ok++;  # alles Super - $ip ist eine ClusterPacket Adresse
            }
            if (!$ok){
               foreach my $node (map({$_->{name}} 
                                     @{$a->{$systemname}->{nodes}})){
                  if (exists($a->{$node}->{acIP}->{$ip})){
                     $ok++; # nicht schoen - aber OK - die IP ist auf einem
                  }         # anderen Node im Cluster registriert
               }
            }
         }
         if (!$ok){
            my $clusttext="";
            if ($a->{$systemname}->{isclusternode}){
               $clusttext=" or any other node in the cluster"; 
            }
            push(@{$a->{systemname}->{msg}},
               {class=>'ac.missip',
                level=>3,
                label=>"The IP-Address '$ip' found by AutoDiscovery ".
                       "on '$systemname' ($systemid) is not documented ".
                       "in AssetManager on systemid ($systemid)$clusttext."
                });
         }
      }
   }

   #print STDERR Dumper(\%a);
   return(\%a);


}






1;
