package tsacinv::asset;
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
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
use Data::Dumper;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=3;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'assetid',
                label         =>'AssetId',
                size          =>'20',
                uppersearch   =>1,
                align         =>'left',
                dataobjattr   =>'assetportfolio.assettag'),

      new kernel::Field::Text(
                name          =>'status',
                label         =>'Status',
                dataobjattr   =>'amasset.status'),

      new kernel::Field::Text(
                name          =>'systemname',
                vjointo       =>'tsacinv::system',
                vjoinon       =>['lassetid'=>'lassetid'],
                weblinkto     =>'none',
                vjoindisp     =>'systemname',
                label         =>'Systemname'),

      new kernel::Field::Text(
                name          =>'systemid',
                vjointo       =>'tsacinv::system',
                vjoinon       =>['lassetid'=>'lassetid'],
                weblinkto     =>'none',
                vjoindisp     =>'systemid',
                label         =>'SystemID'),

      new kernel::Field::Date(
                name          =>'install',
                label         =>'Install Date',
                timezone      =>'CET',
                dataobjattr   =>'amasset.dinstall'),

      new kernel::Field::TextDrop(
                name          =>'assignmentgroup',
                label         =>'Assignment Group',
                vjointo       =>'tsacinv::group',
                vjoinon       =>['lassignmentid'=>'lgroupid'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'lassignmentid',
                label         =>'AC-AssignmentID',
                dataobjattr   =>'assetportfolio.lassignmentid'),

      new kernel::Field::Text(
                name          =>'conumber',
                vjointo       =>'tsacinv::system',
                vjoinon       =>['lassetid'=>'lassetid'],
                weblinkto     =>'none',
                vjoindisp     =>'conumber',
                label         =>'CO-Number'),

      new kernel::Field::Import( $self,
                weblinkto     =>'tsacinv::location',
                weblinkon     =>['locationid'=>'locationid'],
                vjointo       =>'tsacinv::location',
                vjoinon       =>['locationid'=>'locationid'],
                group         =>'location',
                fields        =>['fullname','location']),

      new kernel::Field::Text(
                name          =>'room',
                label         =>'Room',
                group         =>"location",
                dataobjattr   =>'assetportfolio.room'),

      new kernel::Field::Import( $self,
                weblinkto     =>'tsacinv::model',
                vjointo       =>'tsacinv::model',
                vjoinon       =>['lmodelid'=>'lmodelid'],
                weblinkon     =>['lmodelid'=>'lmodelid'],
                prefix        =>'model',
                group         =>'default',
                fields        =>['name']),

      new kernel::Field::Float(
                name          =>'cpucount',
                label         =>'Asset CPU count',
                precision     =>'0',
                dataobjattr   =>'decode(amasset.lcpunumber,0,NULL,'.
                                'amasset.lcpunumber)'),

      new kernel::Field::Float(
                name          =>'cpuspeed',
                label         =>'Asset CPU speed',
                precision     =>'0',
                dataobjattr   =>'decode(amasset.lcpuspeedmhz,0,NULL,'.
                                'amasset.lcpuspeedmhz)'),

      new kernel::Field::Float(
                name          =>'corecount',
                label         =>'Asset Core count',
                precision     =>'0',
                dataobjattr   =>'decode(amasset.itotalnumberofcores,0,NULL,'.
                                'amasset.itotalnumberofcores)'),

      new kernel::Field::Text(
                name          =>'serialno',
                ignorecase    =>1,
                label         =>'Asset Serialnumber',
                dataobjattr   =>'amasset.serialno'),

      new kernel::Field::Text(
                name          =>'inventoryno',
                label         =>'Asset Inventoryno',
                dataobjattr   =>'amasset.inventoryno'),

      new kernel::Field::Float(
                name          =>'systemsonasset',
                label         =>'Systems on Asset',
                precision     =>'0',
                depend        =>[qw(lassetid)],
                onRawValue    =>\&CalcSystemsOnAsset),

      new kernel::Field::Date(
                name          =>'deprstart',
                group         =>'finanz',
                depend        =>'assetid',
                onRawValue    =>\&CalcDep,
                label         =>'Deprecation Start',
                timezone      =>'CET'),

      new kernel::Field::Date(
                name          =>'deprend',
                group         =>'finanz',
                depend        =>'assetid',
                onRawValue    =>\&CalcDep,
                label         =>'Deprecation End',
                timezone      =>'CET'),

      new kernel::Field::Date(
                name          =>'compdeprstart',
                group         =>'finanz',
                depend        =>'assetid',
                onRawValue    =>\&CalcDep,
                label         =>'Component Deprecation Start',
                timezone      =>'CET'),

      new kernel::Field::Date(
                name          =>'compdeprend',
                group         =>'finanz',
                depend        =>'assetid',
                onRawValue    =>\&CalcDep,
                label         =>'Component Deprecation End',
                timezone      =>'CET'),

      new kernel::Field::Currency(
                name          =>'mdepr',
                label         =>'Asset Depr./Month',
                size          =>'20',
                group         =>'finanz',
                dataobjattr   =>'amasset.mdeprcalc'),

      new kernel::Field::Currency(
                name          =>'mmaint',
                label         =>'Asset Maint./Month',
                size          =>'20',
                group         =>'finanz',
                dataobjattr   =>'amasset.mmaintrate'),

      new kernel::Field::Float(
                name          =>'powerinput',
                vjointo       =>'tsacinv::model',
                vjoinon       =>['lmodelid'=>'lmodelid'],
                vjoindisp     =>'assetpowerinput',
                label         =>'PowerInput of Asset',
                unit          =>'KVA'),

      new kernel::Field::Text(
                name          =>'maitcond',
                label         =>'Maintenance Codition',
                dataobjattr   =>'amasset.maintcond'),

      new kernel::Field::Link(
                name          =>'locationid',
                label         =>'LocationID',
                dataobjattr   =>'assetportfolio.llocaid'),

      new kernel::Field::Link(
                name          =>'lassetid',
                label         =>'LAssetId',
                dataobjattr   =>'assetportfolio.lportfolioitemid'),

      new kernel::Field::Link(
                name          =>'lmodelid',
                label         =>'LModelId',
                dataobjattr   =>'assetportfolio.lmodelid'),

      new kernel::Field::SubList(
                name          =>'fixedassets',
                label         =>'Components',
                group         =>'components',
                vjointo       =>'tsacinv::fixedasset',
                vjoinon       =>['assetid'=>'assetid'],
                vjoindisp     =>['name','deprstart','deprend','deprbase']),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'assetportfolio.externalsystem'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'assetportfolio.externalid'),

   );
   $self->setDefaultView(qw(assetid tsacinv_locationfullname 
                            systemname serialno));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsac"));
   return(@result) if (defined($result[0]) eq "InitERROR");

   return(1);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/asset.jpg?".$cgi->query_string());
}
         

sub CalcSystemsOnAsset
{
   my $self=shift;
   my $current=shift;
   my $sys=$self->getParent->getPersistentModuleObject("CalcSystemsOnAssetobj",
                                                       "tsacinv::system");
   my $assetid=$current->{lassetid};
   $sys->SetFilter({'lassetid'=>$assetid});
   my @l=$sys->getHashList(qw(lassetid));
   return($#l+1);
}

sub CalcDep
{
   my $self=shift;
   my $current=shift;
   my $name=$self->Name();
   my $assetid=$current->{assetid};
   my $context=$self->getParent->Context();
   return(undef) if (!defined($assetid) || $assetid eq "");
   if (!defined($context->{CalcDep}->{$assetid})){
      $context->{CalcDep}->{$assetid}=
           $self->getParent->CalcDepr($current,$assetid);
   }
   return($context->{CalcDep}->{$assetid}->{$name});
}

sub CalcDepr
{
   my $self=shift;
   my $current=shift;
   my $assetid=shift;
   my $ac=$self->getPersistentModuleObject("CalcDepr","tsacinv::fixedasset");

   my $compdeprend;
   my $compdeprstart;
   my $deprend;
   my $deprstart;
   if ($assetid ne ""){
      $ac->ResetFilter();
      $ac->SetFilter({assetid=>\$assetid});
      my @fal=$ac->getHashList(qw(deprend deprstart deprbase));
      my $maxdeprbase=0; 
      foreach my $fa (@fal){
         $maxdeprbase=$fa->{deprbase} if ($fa->{deprbase}>$maxdeprbase);
      }
      foreach my $fa (@fal){
         if ($maxdeprbase==$fa->{deprbase}){
            $deprend=$fa->{deprend}         if (!defined($deprend));
            $deprstart=$fa->{deprstart}     if (!defined($deprstart));
         }
         else{
            $compdeprend=$fa->{deprend}     if (!defined($compdeprend));
            $compdeprstart=$fa->{deprstart} if (!defined($compdeprstart));
            if ($compdeprend lt $fa->{deprend}){
               $compdeprend=$fa->{deprend};
            }
            if ($compdeprstart gt $fa->{deprstart}){
               $compdeprstart=$fa->{deprstart};
            }
         }
      }
   }
   $compdeprend=$deprend     if (!defined($compdeprend));
   $compdeprstart=$deprstart if (!defined($compdeprstart));

   return({compdeprend=>$compdeprend,compdeprstart=>$compdeprstart,
           deprend=>$deprend,deprstart=>$deprstart});


}


sub getSqlFrom
{
   my $self=shift;
   my $from="amasset, amportfolio assetportfolio,ammodel, amlocation";
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where=
      "assetportfolio.assettag=amasset.assettag ".
      "and assetportfolio.lmodelid=ammodel.lmodelid ".
      "and assetportfolio.llocaid=amlocation.llocaid(+) ".
      "and assetportfolio.bdelete=0 ".
      "and ammodel.fullname like '/HARDWARE/%'";
   return($where);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}


1;
