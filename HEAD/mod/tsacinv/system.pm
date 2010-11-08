package tsacinv::system;
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
use tsacinv::lib::tools;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB tsacinv::lib::tools);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);

   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Text(
                name          =>'systemname',
                label         =>'Systemname',
                uppersearch   =>1,
                size          =>'16',
                dataobjattr   =>'amportfolio.name'),

      new kernel::Field::Id(
                name          =>'systemid',
                label         =>'SystemId',
                size          =>'13',
                searchable    =>1,
                uppersearch   =>1,
                align         =>'left',
                dataobjattr   =>'amportfolio.assettag'),

      new kernel::Field::Text(
                name          =>'conumber',
                label         =>'CO-Number',
                size          =>'15',
                weblinkto     =>'tsacinv::costcenter',
                weblinkon     =>['lcostcenterid'=>'id'],
                dataobjattr   =>'amcostcenter.trimmedtitle'),

      new kernel::Field::Import($self,
                vjointo       =>'tsacinv::location',
                vjoinon       =>['locationid'=>'locationid'],
                group         =>"location",
                fields        =>[qw(fullname location)]),

      new kernel::Field::Import($self,
                vjointo       =>'tsacinv::asset',
                vjoinon       =>['lassetid'=>'lassetid'],
                weblinkto     =>'none',
              #  weblinkon     =>['lassetid'=>'lassetid'],
                prefix        =>"asset",
                group         =>"location",
                fields        =>[qw(room place)]),

      new kernel::Field::Link(
                name          =>'lcostcenterid',
                label         =>'CostCenterID',
                dataobjattr   =>'amcostcenter.lcostid'),

      new kernel::Field::Text(
                name          =>'cocustomeroffice',
                searchable    =>0,
                label         =>'Customer Office',
                size          =>'20',
                dataobjattr   =>'amcostcenter.customeroffice'),

      new kernel::Field::Text(
                name          =>'bc',
                label         =>'Business Center',
                dataobjattr   =>'amcostcenter.alternatebusinesscenter'),

      new kernel::Field::TextDrop(
                name          =>'assignmentgroup',
                label         =>'Assignment Group',
                vjointo       =>'tsacinv::group',
                vjoinon       =>['lassignmentid'=>'lgroupid'],
                vjoindisp     =>'name'),

      new kernel::Field::TextDrop(
                name          =>'assignmentgroupsupervisor',
                label         =>'Assignment Group Supervisor',
                htmldetail    =>0,
                vjointo       =>'tsacinv::group',
                vjoinon       =>['lassignmentid'=>'lgroupid'],
                vjoindisp     =>'supervisor'),

      new kernel::Field::TextDrop(
                name          =>'assignmentgroupsupervisoremail',
                label         =>'Assignment Group Supervisor E-Mail',
                htmldetail    =>0,
                vjointo       =>'tsacinv::group',
                vjoinon       =>['lassignmentid'=>'lgroupid'],
                vjoindisp     =>'supervisoremail'),

      new kernel::Field::TextDrop(
                name          =>'iassignmentgroup',
                label         =>'Incident Assignment Group',
                vjointo       =>'tsacinv::group',
                vjoinon       =>['lincidentagid'=>'lgroupid'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'lassignmentid',
                label         =>'AC-AssignmentID',
                dataobjattr   =>'amportfolio.lassignmentid'),

      new kernel::Field::Link(
                name          =>'lincidentagid',
                label         =>'AC-Incident-AssignmentID',
                dataobjattr   =>'amportfolio.lincidentagid'),

      new kernel::Field::Text(
                name          =>'controlcenter',
                weblinkto     =>'tsacinv::group',
                weblinkon     =>['controlcenter'=>'name'],
                label         =>'System ControlCenter',
                dataobjattr   =>'amportfolio.controlcenter'),

      new kernel::Field::Text(
                name          =>'controlcenter2',
                weblinkto     =>'tsacinv::group',
                weblinkon     =>['controlcenter2'=>'name'],
                label         =>'Application ControlCenter',
                dataobjattr   =>'amportfolio.controlcenter2'),

      new kernel::Field::Text(
                name          =>'status',
                group         =>'form',
                label         =>'Status',
                dataobjattr   =>'amcomputer.status'),

      new kernel::Field::Text(
                name          =>'usage',
                group         =>'form',
                label         =>'Usage',
                dataobjattr   =>'amportfolio.usage'),

      new kernel::Field::Text(
                name          =>'type',
                label         =>'Type',
                group         =>'form',
                dataobjattr   =>'amcomputer.computertype'),

      new kernel::Field::Boolean(
                name          =>'soxrelevant',
                label         =>'SOX relevant',
                group         =>'form',
                dataobjattr   =>"decode(amportfolio.soxrelevant,'YES',1,0)"),

      new kernel::Field::Float(
                name          =>'systemcpucount',
                label         =>'System CPU count',
                unit          =>'CPU',
                precision     =>0,
                dataobjattr   =>'amcomputer.itotalnumberofcores'),

      new kernel::Field::Float(
                name          =>'systemcpuspeed',
                label         =>'System CPU speed',
                unit          =>'MHz',
                precision     =>0,
                dataobjattr   =>'amcomputer.lcpuspeedmhz'),

      new kernel::Field::Text(
                name          =>'systemcputype',
                label         =>'System CPU type',
                unit          =>'MHz',
                dataobjattr   =>'amcomputer.cputype'),

      new kernel::Field::Text(
                name          =>'systemtpmc',
                label         =>'System tpmC',
                unit          =>'tpmC',
                dataobjattr   =>'amcomputer.lProcCalcSpeed'),

      new kernel::Field::Float(
                name          =>'systemmemory',
                label         =>'System Memory',
                unit          =>'MB',
                precision     =>0,
                dataobjattr   =>'amcomputer.lmemorysizemb'),

      new kernel::Field::Text(
                name          =>'virtualization',
                htmldetail    =>0,
                label         =>'Virualization Status',
                dataobjattr   =>'amcomputer.virtualization'),

      new kernel::Field::Text(
                name          =>'systemos',
                label         =>'System OS',
                dataobjattr   =>'trim(amcomputer.operatingsystem)'),

      new kernel::Field::Float(
                name          =>'partofasset',
                label         =>'System Part of Asset',
                unit          =>'%',
                depend        =>['lassetid'],
                prepRawValue  =>\&SystemPartOfCorrection,
                dataobjattr   =>'amcomputer.psystempartofasset'),

      new kernel::Field::Text(
                name          =>'costallocactive',
                label         =>'Cost allocation active',
                dataobjattr   =>'amcomputer.bcostallocactive'),

      new kernel::Field::Text(
                name          =>'systemola',
                label         =>'System OLA',
                dataobjattr   =>'amcomputer.olaclasssystem'),

      new kernel::Field::Select(
                name          =>'systemolaclass',
                label         =>'System OLA Service Class',
                value         =>['0','10','20','25','30'], 
                transprefix   =>'SYSCLASS.',
                dataobjattr   =>'amcomputer.seappcom'),

      new kernel::Field::Text(
                name          =>'priority',
                label         =>'Priority of system',
                dataobjattr   =>'amportfolio.priority'),

      new kernel::Field::Import($self,
                vjointo       =>'tsacinv::asset',
                vjoinon       =>['lassetid'=>'lassetid'],
                weblinkto     =>'tsacinv::asset',
                weblinkon     =>['lassetid'=>'lassetid'],
                prefix        =>"asset",
                group         =>"assetdata",
                fields        =>[qw(assetid serialno inventoryno modelname 
                                    powerinput cpucount cputype cpuspeed 
                                    corecount
                                    systemsonasset maitcond)]),

      new kernel::Field::Import($self,
                vjointo       =>'tsacinv::asset',
                vjoinon       =>['lassetid'=>'lassetid'],
                prefix        =>"asset",
                group         =>"assetfinanz",
                fields        =>[qw( mdepr mmaint)]),

      new kernel::Field::Date(
                name          =>'compdeprstart',
                vjointo       =>'tsacinv::asset',
                vjoinon       =>['lassetid'=>'lassetid'],
                vjoindisp     =>'compdeprstart',
                htmldetail    =>0,
                group         =>"assetfinanz",
                label         =>'Asset complete deprecation start'),

      new kernel::Field::Date(
                name          =>'compdeprend',
                vjointo       =>'tsacinv::asset',
                vjoinon       =>['lassetid'=>'lassetid'],
                vjoindisp     =>'compdeprend',
                htmldetail    =>0,
                group         =>"assetfinanz",
                label         =>'Asset complete deprecation end'),

      new kernel::Field::Link(
                name          =>'partofassetdec',
                label         =>'System Part of Asset',
                dataobjattr   =>'amcomputer.psystempartofasset'),

      new kernel::Field::Link(
                name          =>'lcomputerid',
                label         =>'AC-ComputerID',
                dataobjattr   =>'amcomputer.lcomputerid'),

      new kernel::Field::Link(
                name          =>'lassetid',
                label         =>'AC-AssetID',
                dataobjattr   =>'amportfolio.lparentid'),

      new kernel::Field::Link(
                name          =>'lclusterid',
                label         =>'AC-ClusterID',
                dataobjattr   =>'amcomputer.lparentid'),

      new kernel::Field::Link(
                name          =>'lportfolioitemid',
                label         =>'PortfolioID',
                dataobjattr   =>'amportfolio.lportfolioitemid'),

      new kernel::Field::Link(
                name          =>'locationid',
                label         =>'AC-LocationID',
                vjointo       =>'tsacinv::asset',
                vjoinon       =>['lassetid'=>'lassetid'],
                vjoindisp     =>'locationid'),

      new kernel::Field::Link(
                name          =>'altbc',
                label         =>'Alternate BC',
                dataobjattr   =>'amcostcenter.alternatebusinesscenter'),

      new kernel::Field::SubList(
                name          =>'services',
                label         =>'Services',
                group         =>'services',
                vjointo       =>'tsacinv::service',
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>[qw(name type ammount unit)],
                vjoininhash   =>['name','type','ammount']),

      new kernel::Field::SubList(
                name          =>'ipaddresses',
                label         =>'IP-Adresses',
                group         =>'ipaddresses',
                vjointo       =>'tsacinv::ipaddress',
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>[qw(ipaddress description)]),

      new kernel::Field::SubList(
                name          =>'applications',
                label         =>'Applications',
                group         =>'applications',
                vjointo       =>'tsacinv::lnkapplsystem',
                vjoinon       =>['lportfolioitemid'=>'lchildid'],
                vjoindisp     =>[qw(parent applid)]),

      new kernel::Field::SubList(
                name          =>'applicationnames',
                label         =>'Applicationnames',
                group         =>'applications',
                searchable    =>0,
                htmldetail    =>0,
                vjointo       =>'tsacinv::lnkapplsystem',
                vjoinon       =>['lportfolioitemid'=>'lchildid'],
                vjoindisp     =>[qw(parent)]),

      new kernel::Field::SubList(
                name          =>'applicationids',
                htmldetail    =>0,
                label         =>'ApplicationIDs',
                group         =>'applications',
                vjointo       =>'tsacinv::lnkapplsystem',
                vjoinon       =>['lportfolioitemid'=>'lchildid'],
                vjoindisp     =>[qw(applid)]),

      new kernel::Field::SubList(
                name          =>'software',
                label         =>'Software',
                group         =>'software',
                vjointo       =>'tsacinv::lnksystemsoftware',
                vjoinon       =>['lportfolioitemid'=>'lparentid'],
                vjoindisp     =>[qw(id name)]),

      new kernel::Field::Dynamic(
                name          =>'dynservices',
                searchable    =>0,
                depend        =>[qw(systemid)],
                group         =>'services',
                label         =>'Services Columns',
                fields        =>\&AddServices),

      new kernel::Field::Text(
                name          =>'w5base_appl',
                group         =>'w5basedata',
                searchable    =>0,
                label         =>'W5Base Anwendung',
                onRawValue    =>\&AddW5BaseData,
                depend        =>'systemid'),

      new kernel::Field::Text(
                name          =>'w5base_sem',
                searchable    =>0,
                group         =>'w5basedata',
                label         =>'W5Base SeM',
                onRawValue    =>\&AddW5BaseData,
                depend        =>'systemid'),

      new kernel::Field::Text(
                name          =>'w5base_tsm',
                searchable    =>0,
                group         =>'w5basedata',
                label         =>'W5Base TSM',
                onRawValue    =>\&AddW5BaseData,
                depend        =>'systemid'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'amportfolio.externalsystem'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'amportfolio.externalid'),


   );
   $self->setDefaultView(qw(systemname bc tsacinv_locationfullname 
                            systemid assetassetid));
   return($self);
}

sub AddW5BaseData
{
   my $self=shift;
   my $current=shift;
   my $systemid=$current->{systemid};
   my $app=$self->getParent();
   my $c=$self->getParent->Context();
   return(undef) if (!defined($systemid) || $systemid eq "");
   if (!defined($c->{W5BaseSys}->{$systemid})){
      my $w5sys=$app->getPersistentModuleObject("W5BaseSys","itil::system");
      my $w5appl=$app->getPersistentModuleObject("W5BaseAppl","itil::appl");
      $w5sys->ResetFilter();
      $w5sys->SetFilter({systemid=>\$systemid});
      my ($rec,$msg)=$w5sys->getOnlyFirst(qw(applications sem tsm));
      my %l=();
      if (defined($rec)){
         my %appl=();
         my %sem=();
         my %tsm=();
         if (defined($rec->{applications}) && 
             ref($rec->{applications}) eq "ARRAY"){
            foreach my $app (@{$rec->{applications}}){
               $appl{$app->{applid}}=$app->{appl};
               $w5appl->ResetFilter();
               $w5appl->SetFilter({id=>\$app->{applid}});
               my ($arec,$msg)=$w5appl->getOnlyFirst(qw(sem semid tsm tsmid));
               if (defined($arec)){
                  $sem{$arec->{semid}}=$arec->{sem};
                  $tsm{$arec->{tsmid}}=$arec->{tsm};
               }
            }
         }
         $l{w5base_appl}=[sort(values(%appl))];
         $l{w5base_sem}=[sort(values(%sem))];
         $l{w5base_tsm}=[sort(values(%tsm))];
      }
      $c->{W5BaseSys}->{$systemid}=\%l;
   }
   return($c->{W5BaseSys}->{$systemid}->{$self->Name});
   
}

sub AddServices
{
   my $self=shift;
   my %param=@_;
   my @dyn=();
   my $c=$self->Context();
   if (!defined($c->{db})){
      $c->{db}=getModuleObject($self->getParent->Config,"tsacinv::service");
   }
   if (defined($param{current})){
      my $systemid=$param{current}->{systemid};
      $c->{db}->SetFilter({systemid=>\$systemid});
      my @l=$c->{db}->getHashList(qw(name ammount));
      my %sumrec=();
      foreach my $rec (@l){
         $sumrec{$rec->{name}}+=$rec->{ammount};
      }
      foreach my $ola (keys(%sumrec)){
         push(@dyn,$self->getParent->InitFields(
              new kernel::Field::Float(   name       =>'ola'.$ola,
                                          label      =>$ola,
                                          group      =>'services',
                                          htmldetail =>0,
                                          onRawValue =>sub {
                                                          return($sumrec{$ola});
                                                       },
                                          dataobjattr=>'amcomputer.name'
                                      )
             ));
      }
   }
   return(@dyn);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsac"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
}
         

sub SystemPartOfCorrection
{
   my $self=shift;
   my $val=shift;
   my $current=shift;
   my $context=$self->Context();

   if (!defined($context->{SystemPartOfobj})){
      $context->{SystemPartOfobj}=getModuleObject($self->getParent->Config,
                                                  "tsacinv::system");
   }
   my $sys=$context->{SystemPartOfobj};

   if (defined($val) && $val==0){             # recalculate "SystemPartOf" if
      my $lassetid=$current->{lassetid};      # value is 0 and not the complete
      if ($lassetid ne ""){                   # asset is distributed to systems
         $sys->SetFilter({lassetid=>\$lassetid});
         my @l=$sys->getHashList(qw(partofassetdec));
         my $nullsys=0;
         my $sumok=0;
         foreach my $rec (@l){
            $sumok+=$rec->{partofassetdec} if ($rec->{partofassetdec}>0);
            $nullsys++ if ($rec->{partofassetdec}==0);
         }
         if ($nullsys>0){
            $val=(1-$sumok)/$nullsys;
         }
      }
   }
   if (defined($val) && $val>0){
      $val=100*$val;
   }
   return($val);
}

sub getSqlFrom
{
   my $self=shift;
   my $from=
      "amcomputer, ".
      "(select amportfolio.* from amportfolio ".
      " where amportfolio.bdelete=0) amportfolio,ammodel,".
      "(select amcostcenter.* from amcostcenter ".
      " where amcostcenter.bdelete=0) amcostcenter";

   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where=
      "amportfolio.lportfolioitemid=amcomputer.litemid ".
      "and amportfolio.lmodelid=ammodel.lmodelid ".
      "and amportfolio.lcostid=amcostcenter.lcostid(+) ".
      "and ammodel.name='LOGICAL SYSTEM' ".
      "and amcomputer.status<>'out of operation'";
   return($where);
}

sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   return($self->addAltBCSetFilter(@flt));
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


sub getDetailBlockPriority
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),
          qw(default form applications location ipaddresses software 
             assetdata assetfinanz 
             services w5basedata source));
}  


sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(),qw(ImportSystem));
}  

sub ImportSystem
{
   my $self=shift;

   my $importname=Query->Param("importname");
   if (Query->Param("DOIT")){
      if ($self->Import({importname=>$importname})){
         Query->Delete("importname");
         $self->LastMsg(OK,"system has been successfuly imported");
      }
      Query->Delete("DOIT");
   }


   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css',
                                   'kernel.App.Web.css'],
                           static=>{importname=>$importname},
                           body=>1,form=>1,
                           title=>"AssetManager System Import");
   print $self->getParsedTemplate("tmpl/minitool.system.import",{});
   print $self->HtmlBottom(body=>1,form=>1);
}


   

sub Import
{
   my $self=shift;
   my $param=shift;

   my $flt;
   if ($param->{importname} ne ""){
      $flt={systemid=>[$param->{importname}]};
   }
   else{
      return(undef);
   }
   $self->ResetFilter();
   $self->SetFilter($flt);
   my @l=$self->getHashList(qw(systemid systemname lassignmentid assetid));
   if ($#l==-1){
      $self->LastMsg(ERROR,"SystemID not found in AssetManager");
      return(undef);
   }
   if ($#l>0){
      $self->LastMsg(ERROR,"SystemID not unique in AssetManager");
      return(undef);
   }

   my $sysrec=$l[0];
   my $sys=getModuleObject($self->Config,"itil::system");
   $sys->SetFilter($flt);
   my ($w5sysrec,$msg)=$sys->getOnlyFirst(qw(ALL));
   my $identifyby;
   if (defined($w5sysrec)){
      if ($w5sysrec->{cistatusid}==4){
         $self->LastMsg(ERROR,"SystemID already exists in W5Base");
         return(undef);
      }
      $identifyby=$sys->ValidatedUpdateRecord($w5sysrec,{cistatusid=>4},
                                              {id=>\$w5sysrec->{id}});
   }
   else{
      # check 1: Assigmenen Group registered
      if ($sysrec->{lassignmentid} eq ""){
         $self->LastMsg(ERROR,"SystemID has no Assignment Group");
         return(undef);
      }
      printf STDERR Dumper($sysrec);
      # check 2: Assingment Group active
      my $acgroup=getModuleObject($self->Config,"tsacinv::group");
      $acgroup->SetFilter({lgroupid=>\$sysrec->{lassignmentid}});
      my ($acgrouprec,$msg)=$acgroup->getOnlyFirst(qw(supervisorldapid));
      if (!defined($acgrouprec)){
         $self->LastMsg(ERROR,"Can't find Assignment Group of system");
         return(undef);
      }
      # check 3: Supervisor registered
      if ($acgrouprec->{supervisorldapid} eq "" &&
          $acgrouprec->{supervisoremail} eq ""){
         $self->LastMsg(ERROR,"incomplet Supervisor at Assignment Group");
         return(undef);
      }
      my $importname=$acgrouprec->{supervisorldapid};
      $importname=$acgrouprec->{supervisoremail} if ($importname eq "");
      # check 4: load Supervisor ID in W5Base
      my $tswiw=getModuleObject($self->Config,"tswiw::user");
      my $databossid=$tswiw->GetW5BaseUserID($importname);
      if (!defined($databossid)){
         $self->LastMsg(ERROR,"Can't import Supervisor as Databoss");
         return(undef);
      }
      # check 5: find id of mandator "extern"
      my $mand=getModuleObject($self->Config,"base::mandator");
      $mand->SetFilter({name=>"extern"});
      my ($mandrec,$msg)=$mand->getOnlyFirst(qw(grpid));
      if (!defined($mandrec)){
         $self->LastMsg(ERROR,"Can't find mandator extern");
         return(undef);
      }
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"write","direct");
      my $mandatorid=$mandrec->{grpid};
      if (in_array(\@mandators,200)){
         $mandatorid=200;
      }

      # final: do the insert operation
      my $newrec={name=>$sysrec->{systemname},
                  systemid=>$sysrec->{systemid},
                  admid=>$databossid,
                  allowifupdate=>1,
                  mandatorid=>$mandatorid,
                  cistatusid=>4};
      $identifyby=$sys->ValidatedInsertRecord($newrec);
   }
   if (defined($identifyby) && $identifyby!=0){
      $sys->ResetFilter();
      $sys->SetFilter({'id'=>\$identifyby});
      my ($rec,$msg)=$sys->getOnlyFirst(qw(ALL));
      if (defined($rec)){
         my $qc=getModuleObject($self->Config,"base::qrule");
         $qc->setParent($sys);
         $qc->nativQualityCheck($sys->getQualityCheckCompat($rec),$rec);
      }
   }
   return($identifyby);
}





1;
