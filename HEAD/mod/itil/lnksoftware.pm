package itil::lnksoftware;
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
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4 if (!defined($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);
   

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'LinkID',
                searchable    =>0,
                dataobjattr   =>'lnksoftwaresystem.id'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Fullname',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>
                   "concat(software.name,".
                   "if (lnksoftwaresystem.version<>'',".
                   "concat('-',lnksoftwaresystem.version),''),".
                   "if (lnksoftwaresystem.system is not null,".
                   "concat(' (system installed\@',system.name,')'),".
 
                   "' (cluster service installed)'))"),
                                                 
      new kernel::Field::TextDrop(
                name          =>'software',
                htmlwidth     =>'200px',
                label         =>'Software',
                vjoineditbase =>{cistatusid=>[3,4]},
                vjointo       =>'itil::software',
                vjoinon       =>['softwareid'=>'id'],
                vjoindisp     =>'name'),
                                                   
      new kernel::Field::Text(
                name          =>'version',
                htmlwidth     =>'50px',
                label         =>'Version',
                dataobjattr   =>'lnksoftwaresystem.version'),
                                                   
      new kernel::Field::TextDrop(
                name          =>'system',
                htmlwidth     =>'100px',
                label         =>'System',
                searchable    =>0,
                vjointo       =>'itil::system',
                vjoinon       =>['systemid'=>'id'],
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};
                   return(0) if (defined($current) &&
                                 $current->{insttyp} ne "System");
                   return(1);
                },
                vjoindisp     =>'name'),

      new kernel::Field::TextDrop(
                name          =>'itclustsvc',
                htmlwidth     =>'100px',
                searchable    =>0,
                label         =>'ClusterService',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};
                   return(0) if (defined($current) &&
                                 $current->{insttyp} ne "ClusterService");
                   return(1);
                },
                vjointo       =>'itil::lnkitclustsvc',
                vjoinon       =>['itclustsvcid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Date(
                name          =>'instdate',
                group         =>'misc',
                label         =>'Installation date',
                dataobjattr   =>'lnksoftwaresystem.instdate'),
                                                   
      new kernel::Field::Text(
                name          =>'instpath',
                group         =>'misc',
                label         =>'Installation path',
                dataobjattr   =>'lnksoftwaresystem.instpath'),
                                                   
      new kernel::Field::Textarea(
                name          =>'comments',
                searchable    =>0,
                group         =>'misc',
                label         =>'Comments',
                dataobjattr   =>'lnksoftwaresystem.comments'),

      new kernel::Field::Text(
                name          =>'releasekey',
                readonly      =>1,
                group         =>'releaseinfos',
                label         =>'Releasekey (Beta)',
                dataobjattr   =>'lnksoftwaresystem.releasekey'),
                                                   
      new kernel::Field::Text(
                name          =>'majorminorkey',
                readonly      =>1,
                group         =>'releaseinfos',
                label         =>'majorminorkey (Beta)',
                dataobjattr   =>'lnksoftwaresystem.majorminorkey'),
                                                   
      new kernel::Field::Text(
                name          =>'patchkey',
                readonly      =>1,
                group         =>'releaseinfos',
                label         =>'patchkey (Beta)',
                dataobjattr   =>'lnksoftwaresystem.patchkey'),
                                                   
      new kernel::Field::Text(
                name          =>'insttyp',
                label         =>'Installationtyp',
                readonly      =>1,
                selectfix     =>1,
                dataobjattr   =>
                   "if (lnksoftwaresystem.system is not null,".
                   "'System',".
                   "'ClusterService')"),

      new kernel::Field::TextDrop(
                name          =>'liccontract',
                htmlwidth     =>'100px',
                group         =>'lic',
                AllowEmpty    =>1,
                label         =>'License contract',
                vjointo       =>'itil::liccontract',
                vjoinon       =>['liccontractid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Number(
                name          =>'quantity',
                htmlwidth     =>'40px',
                group         =>'lic',
                precision     =>2,
                label         =>'Quantity',
                dataobjattr   =>'lnksoftwaresystem.quantity'),

      new kernel::Field::Number(
                name          =>'licrelevantcpucount',
                group         =>'lic',
                precision     =>0,
                searchable    =>0,
                htmldetail    =>0,
                label         =>'license relevant logical cpu count',
                onRawValue    =>\&calcLicMetrics),
                                                 
      new kernel::Field::Text(
                name          =>'licrelevantosrelease',
                group         =>'lic',
                searchable    =>0,
                htmldetail    =>0,
                label         =>'license relevant os release',
                onRawValue    =>\&calcLicMetrics),
                                                 
      new kernel::Field::Text(
                name          =>'licrelevantsystemclass',
                group         =>'lic',
                searchable    =>0,
                htmldetail    =>0,
                label         =>'license relevant system class',
                onRawValue    =>\&calcLicMetrics),
                                                 
      new kernel::Field::Text(
                name          =>'licrelevantopmode',
                group         =>'lic',
                searchable    =>0,
                htmldetail    =>0,
                label         =>'license relevant operation mode',
                onRawValue    =>\&calcLicMetrics),
                                                 
      new kernel::Field::Mandator(
                htmldetail    =>0,
                group         =>'link',
                readonly      =>1,
                label         =>'Mandator of relevant Config-Item'),

      new kernel::Field::Link(
                name          =>'mandatorid',
                dataobjattr   =>
                   "if (lnksoftwaresystem.system is not null,".
                   "system.mandator,".
                   "itclust.mandator)"),

      new kernel::Field::Select(
                name          =>'cicistatus',
                htmldetail    =>0,
                group         =>'link',
                readonly      =>1,
                htmleditwidth =>'40%',
                label         =>'CI-State of relevant Config-Item',
                vjoineditbase =>{id=>">0"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cicistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                htmldetail    =>0,
                name          =>'cicistatusid',
                dataobjattr   =>
                   "if (lnksoftwaresystem.system is not null,".
                   "system.cistatus,".
                   "itclust.cistatus)"),

      new kernel::Field::Databoss(
                htmldetail    =>0,
                group         =>'link',
                readonly      =>1),

      new kernel::Field::Link(
                name          =>'databossid',
                group         =>'link',
                dataobjattr   =>
                   "if (lnksoftwaresystem.system is not null,".
                   "system.databoss,".
                   "itclust.databoss)"),

      new kernel::Field::TextDrop(
                name          =>'softwareproducer',
                label         =>'Software Producer',
                htmldetail    =>0,
                vjointo       =>'itil::producer',
                vjoinon       =>['softwareproducerid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'softwareproducerid',
                dataobjattr   =>'software.producer'),

      new kernel::Field::Select(
                name          =>'softwarecistatus',
                group         =>'link',
                searchable    =>0,
                readonly      =>1,
                htmldetail    =>0,
                label         =>'Software CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['softwarecistatusid'=>'id'],
                vjoindisp     =>'name'),
                                                  
      new kernel::Field::Link(
                name          =>'softwarecistatusid',
                label         =>'SoftwareCiStatusID',
                dataobjattr   =>'software.cistatus'),

      new kernel::Field::Select(
                name          =>'rightsmgmt',
                label         =>'rights managed',
                readonly      =>1,
                htmldetail    =>0,
                selectfix     =>1,
                group         =>'link',
                transprefix   =>'right.',
                value         =>['OPTIONAL','YES','NO'],
                translation   =>'itil::software',
                htmleditwidth =>'100px',
                dataobjattr   =>'software.rightsmgmt'),
      
      new kernel::Field::Textarea(
                name          =>'rightsmgmtstatus',
                searchable    =>0,
                htmldetail    =>0,
                group         =>'link',
                label         =>'rights management status (BETA!)',
                onRawValue    =>\&calcRightsMgmtState),

      new kernel::Field::Mandator(
                label         =>'License Mandator',
                name          =>'liccontractmandator',
                vjoinon       =>'liccontractmandatorid',
                htmldetail    =>0,
                group         =>'link',
                readonly      =>1),

      new kernel::Field::Link(
                name          =>'liccontractmandatorid',
                label         =>'LicenseMandatorID',
                group         =>'link',
                dataobjattr   =>'liccontract.mandator'),

      new kernel::Field::Select(
                name          =>'liccontractcistatus',
                readonly      =>1,
                htmldetail    =>0,
                group         =>'link',
                label         =>'License CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['liccontractcistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'liccontractcistatusid',
                selectfix     =>1,
                label         =>'LiccontractCiStatusID',
                dataobjattr   =>'liccontract.cistatus'),
                                                   
      new kernel::Field::Link(
                name          =>'softwareid',
                label         =>'SoftwareID',
                dataobjattr   =>'lnksoftwaresystem.software'),
                                                   
      new kernel::Field::Link(
                name          =>'liccontractid',
                label         =>'LicencenseID',
                dataobjattr   =>'lnksoftwaresystem.liccontract'),
                                                   
      new kernel::Field::Interface(
                name          =>'systemid',
                selectfix     =>1,
                label         =>'SystemId',
                dataobjattr   =>'lnksoftwaresystem.system'),

      new kernel::Field::Interface(
                name          =>'itclustsvcid',
                label         =>'ClusterServiceID',
                selectfix     =>1,
                dataobjattr   =>'lnksoftwaresystem.lnkitclustsvc'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnksoftwaresystem.createuser'),
                                   
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'lnksoftwaresystem.modifyuser'),
                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnksoftwaresystem.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnksoftwaresystem.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'lnksoftwaresystem.srcload'),
                                                   
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnksoftwaresystem.createdate'),
                                                
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnksoftwaresystem.modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'lnksoftwaresystem.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'lnksoftwaresystem.realeditor'),
                                                   
   );
   $self->{history}=[qw(insert modify delete)];
   $self->setDefaultView(qw(software softwareproducer 
                            version quantity insttyp cdate));
   $self->setWorktable("lnksoftwaresystem");
   return($self);
}


sub calcLicMetrics   # licrelevantopmode licrelevantosrelease 
{                    # licrelevantcpucount
   my $self=shift;
   my $current=shift;
   my @sysid;
   my $sysobj=getModuleObject($self->getParent->Config,"itil::system");
   my $appobj=getModuleObject($self->getParent->Config,"itil::appl");
   if ($current->{systemid} ne ""){  # is system installed
      $sysobj->SetFilter({id=>\$current->{systemid}});
   }
   else{
      my $itclustsvcid=$current->{itclustsvcid};
      if ($itclustsvcid ne ""){
         my $o=getModuleObject($self->getParent->Config,"itil::lnkitclustsvc");
         $o->SetFilter({id=>\$itclustsvcid});
         my ($svcrec)=$o->getOnlyFirst(qw(clustid applications));
         if (defined($svcrec)){
            if ($self->{name} eq "licrelevantopmode"){
               my @l;
               foreach my $apprec (@{$svcrec->{applications}}){
                  push(@l,$apprec->{applid});
               }
               if ($#l==-1){  # dieser Sonderfall mu� noch behandelt werden
                  $appobj->SetFilter({id=>\@l,cistatusid=>"<6"});
               }
               else{
                  $appobj->SetFilter({id=>\@l,cistatusid=>"<6"});
               }
            }
            else{
               if ($svcrec->{clustid} ne ""){
                  $sysobj->SetFilter({cistatusid=>'<6',
                                      itclustid=>\$svcrec->{clustid}});
               }
            }
         }
         else{
            return("?");
         }
      } 
   }
   if ($self->{name} eq "licrelevantopmode"){
      if ($current->{systemid} ne ""){  # is system installed
         my $o=getModuleObject($self->getParent->Config,"itil::lnkapplsystem");
         $o->SetFilter({systemid=>\$current->{systemid}});
         my @applid=$o->getVal("applid");
         $appobj->ResetFilter();
         $appobj->SetFilter({id=>\@applid,cistatusid=>"<6"});
      }
      my %o;
      foreach my $apprec ($appobj->getHashList("opmode")){
        $o{$apprec->{opmode}}++;
      }
      return([sort(
                 map({$self->getParent->T('opmode.'.$_,"itil::appl")} keys(%o))
              )]);
   }
   my @res;
   if ($self->{name} eq "licrelevantcpucount" ||
       $self->{name} eq "licrelevantsystemclass" ||
       $self->{name} eq "licrelevantosrelease"){
      my %r;
      my %c;
      my $cpucount=0;
      foreach my $sysrec ($sysobj->getHashList(qw(cpucount osrelease osclass))){
         $r{$sysrec->{'osrelease'}}++;
         $c{$sysrec->{'osclass'}}++;
         $cpucount=$sysrec->{'cpucount'} if ($cpucount<$sysrec->{'cpucount'});
      }
      return([sort(keys(%r))]) if ($self->{name} eq "licrelevantosrelease");
      return([sort(keys(%c))]) if ($self->{name} eq "licrelevantsystemclass");
      return($cpucount) if ($self->{name} eq "licrelevantcpucount");
   }
   return(\@res);
}



sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @filter=@_;

   my $from="lnksoftwaresystem left outer join software ".
            "on lnksoftwaresystem.software=software.id ".
            "left outer join lnkitclustsvc ".
            "on lnksoftwaresystem.lnkitclustsvc=lnkitclustsvc.id ".
            "left outer join itclust ".
            "on lnkitclustsvc.itclust=itclust.id ".
            "left outer join system ".
            "on lnksoftwaresystem.system=system.id ".
            "left outer join liccontract ".
            "on lnksoftwaresystem.liccontract=liccontract.id ";

   return($from);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cicistatus"))){
     Query->Param("search_cicistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}


sub calcRightsMgmtState
{
   my $self=shift;
   my $current=shift;
   my @msg;

   if ($current->{rightsmgmt} eq "YES"){
      if ($current->{liccontractid} eq ""){
         push(@msg,"ERROR: ". 
              $self->getParent->T("missing required license contract"));
      }
   }
   if ($current->{liccontractid} ne ""){
      if ($current->{cicistatusid}==4){
         if ($current->{liccontractcistatusid}!=4){
            push(@msg,"ERROR: ". 
                 $self->getParent->T("license contract is installed/active"));
         }
      }
   }

   if ($#msg==-1){
      push(@msg,"OK");
   }
   return(join("\n",@msg));
}




sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;


   my $instpath=effVal($oldrec,$newrec,"instpath");
   if ($instpath ne ""){
      if (!($instpath=~m/^\/[a-z0-9\.\\_\/:-]+$/i) &&
          !($instpath=~m/^[A-Za-z]:\\[a-zA-Z0-9\.\\_-]+$/)){
         $self->LastMsg(ERROR,"invalid installation path");
         return(undef);
      }
   }
   my $softwareid=effVal($oldrec,$newrec,"softwareid");
   if ($softwareid==0){
      $self->LastMsg(ERROR,"invalid software specified");
      return(undef);
   }
   if (!defined($oldrec) && $newrec->{instdate} eq ""){
      $newrec->{instdate}=NowStamp("en");
   }
   my $version=effVal($oldrec,$newrec,"version");
   my $sw=getModuleObject($self->Config,"itil::software");
   $sw->SetFilter({id=>\$softwareid});
   my ($rec,$msg)=$sw->getOnlyFirst(qw(releaseexp));
   if (!defined($rec)){
      $self->LastMsg(ERROR,"invalid software specified");
      return(undef);
   }
   my $releaseexp=$rec->{releaseexp};
   if (defined($ENV{SERVER_SOFTWARE})){
      if (!($releaseexp=~m/^\s*$/)){
         my $chk;
         eval("\$chk=\$version=~m$releaseexp;");
         if ($@ ne "" || !($chk)){
            $self->LastMsg(ERROR,"invalid software version specified");
            return(undef);
         }
      }
   }
   if ($version ne "" && exists($newrec->{version})){  #release details gen
      my @v=split(/\./,$version);
      my @relkey=();
      for(my $relpos=0;$relpos<5;$relpos++){
         if ($v[$relpos]=~m/^\d+$/){
            $relkey[$relpos]=sprintf("%04d",$v[$relpos]);
         }
         else{
            $relkey[$relpos]="9999";
         }
      }
      $newrec->{releasekey}=join("",@relkey);
      if (my ($rel,$patch)=$version=~m/^(.*\d)(p\d.*)$/){
         $newrec->{patchkey}=$patch;
         $newrec->{majorminorkey}=$rel;
      }
      elsif (my ($rel,$patch)=$version=~m/^(.*\d)(SP\d.*)$/){
         $newrec->{patchkey}=$patch;
         $newrec->{majorminorkey}=$rel;
      }
      elsif (my ($rel,$patch)=$version=~m/^(.*\d) (build.*)$/){
         $newrec->{patchkey}=$patch;
         $newrec->{majorminorkey}=$rel;
      }
      elsif (my ($rel,$patch)=$version=~m/^(\d+\.\d+)\.(.*)$/){
         $newrec->{patchkey}=$patch;
         $newrec->{majorminorkey}=$rel;
      }
      else{
         $newrec->{patchkey}="?";
         $newrec->{majorminorkey}="?";
      }
      
   }
   my $itclustsvcid=effVal($oldrec,$newrec,"itclustsvcid");
   my $systemid=effVal($oldrec,$newrec,"systemid");
   if ($systemid==0 && $itclustsvcid==0){
      $self->LastMsg(ERROR,"invalid system specified");
      return(undef);
   }
   else{
      if (!$self->isParentWriteable($systemid,$itclustsvcid)){
         $self->LastMsg(ERROR,"system is not writeable for you");
         return(undef);
      }
   }
   if (exists($newrec->{quantity}) && ! defined($newrec->{quantity})){
      delete($newrec->{quantity});
   }

   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default","header") if (!defined($rec));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $rw=0;

   $rw=1 if (!defined($rec));
   $rw=1 if (defined($rec) && $self->isParentWriteable($rec->{systemid},
                                                       $rec->{itclustsvcid}));
   $rw=1 if ((!$rw) && ($self->IsMemberOf("admin")));
   if ($rw){
      return("default","lic","misc");
   }
   return(undef);
}

sub isParentWriteable  # Eltern Object Schreibzugriff pr�fen
{
   my $self=shift;
   my $systemid=shift;
   my $itclustsvcid=shift;

   return(1) if (!defined($ENV{SERVER_SOFTWARE}));
   if ($systemid ne ""){
      my $sys=$self->getPersistentModuleObject("W5BaseSystem","itil::system");
      $sys->ResetFilter();
      $sys->SetFilter({id=>\$systemid});
      my ($rec,$msg)=$sys->getOnlyFirst(qw(ALL));
      if (defined($rec) && $sys->isWriteValid($rec)){
         return(1);
      }
   }
   if ($itclustsvcid ne ""){
      my $svc=$self->getPersistentModuleObject("W5BaseITClustSVC",
                                               "itil::lnkitclustsvc");
      $svc->ResetFilter();
      $svc->SetFilter({id=>\$itclustsvcid});
      my ($rec,$msg)=$svc->getOnlyFirst(qw(ALL));
      if (defined($rec) && $svc->isWriteValid($rec)){
         return(1);
      }
   }
   return(0);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default lic useableby misc link releaseinfos source));
}








1;
