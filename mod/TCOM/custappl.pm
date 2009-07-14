package TCOM::custappl;
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
use kernel::DataObj::DB;
use kernel::App::Web::Listedit;
use kernel::CIStatusTools;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::CIStatusTools);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{UseSqlReplace}=1;

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                searchable    =>0,
                label         =>'W5BaseID',
                altdataobjattr=>'appl.id',
                dataobjattr   =>'TCOM_appl.id'),

      new kernel::Field::Text(
                name          =>'name',
                readonly      =>1,
                htmlwidth     =>'200px',
                label         =>'TS Applicationname',
                altdataobjattr=>'appl.name',
                dataobjattr   =>'TCOM_appl.origname'),

      new kernel::Field::Link(
                name          =>'origname',
                readonly      =>1,
                htmlwidth     =>'200px',
                label         =>'Orig TS Applicationname',
                dataobjattr   =>'TCOM_appl.origname'),

      new kernel::Field::Text(
                name          =>'custname',
                htmlwidth     =>'200px',
                group         =>'custapplnameing',
                label         =>'Customer Applicationname',
                dataobjattr   =>'TCOM_appl.name'),

      new kernel::Field::TextDrop(
                name          =>'customer',
                label         =>'Customer',
                readonly      =>1,
                vjointo       =>'base::grp',
                vjoinon       =>['customerid'=>
                                 'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Select(  
                name          =>'cistatus',
                readonly      =>1,
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Boolean(
                name          =>'allowbusinesreq',
                searchable    =>0,
                readonly      =>1,
                htmleditwidth =>'30%',
                label         =>'allow business request workflows',
                container     =>'additional'),

      new kernel::Field::Interface(
                name          =>'cistatusid',   # function is needed to 
                label         =>'CI-StatusID',  # show undefined state
                dataobjattr   =>'if (appl.cistatus is null,0,appl.cistatus)'),

      new kernel::Field::Link(       
                name          =>'customerid',
                altdataobjattr=>'appl.customer',
                dataobjattr   =>'TCOM_appl.customer'),

      new kernel::Field::TextDrop(
                name          =>'wbv',
                group         =>'tcomcontact',
                label         =>'WBV Wirkbetriebsverantwortlicher',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['wbvid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(      
                name          =>'wbvid',
                group         =>'tcomcontact',
                dataobjattr   =>'TCOM_appl.wbv'),

      new kernel::Field::TextDrop(
                name          =>'ev',
                group         =>'tcomcontact',
                label         =>'EV Einf�hrungsverantwortlicher',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['evid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(      
                name          =>'evid',
                group         =>'tcomcontact',
                dataobjattr   =>'TCOM_appl.ev'),

      new kernel::Field::TextDrop(
                name          =>'itv',
                group         =>'tcomcontact',
                label         =>'ITV IT-Verantwortlicher',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['itvid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(      
                name          =>'itvid',
                group         =>'tcomcontact',
                dataobjattr   =>'TCOM_appl.itv'),

      new kernel::Field::TextDrop(
                name          =>'inm',
                group         =>'tcomcontact',
                label         =>'INM Intergrationsmanager',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['inmid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(      
                name          =>'inmid',
                group         =>'tcomcontact',
                dataobjattr   =>'TCOM_appl.inm'),

      new kernel::Field::TextDrop(
                name          =>'ippl',
                group         =>'tcomcontact',
                label         =>'IPPL IP Projektleiter',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['ipplid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(      
                name          =>'ipplid',
                group         =>'tcomcontact',
                dataobjattr   =>'TCOM_appl.ippl'),

      new kernel::Field::Interface(      
                name          =>'semid',
                group         =>'tscontact',
                dataobjattr   =>'appl.sem'),

      new kernel::Field::Interface(
                name          =>'sememail',
                group         =>'tscontact',
                vjointo       =>'base::user',
                vjoinon       =>['semid'=>'userid'],
                vjoindisp     =>'email'),

      new kernel::Field::Interface(
                name          =>'semofficephone',
                group         =>'tscontact',
                vjointo       =>'base::user',
                vjoinon       =>['semid'=>'userid'],
                vjoindisp     =>'office_phone'),

      new kernel::Field::Interface(
                name          =>'semofficemobile',
                group         =>'tscontact',
                vjointo       =>'base::user',
                vjoinon       =>['semid'=>'userid'],
                vjoindisp     =>'office_mobile'),

      new kernel::Field::TextDrop(
                name          =>'sem',
                group         =>'tscontact',
                label         =>'Service Manager',
                translation   =>'itil::appl',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['semid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Interface(
                name          =>'tsmid',
                group         =>'tscontact',
                dataobjattr   =>'appl.tsm'),

      new kernel::Field::Interface(
                name          =>'tsmemail',
                group         =>'tscontact',
                label         =>'TSM E-Mail',
                vjointo       =>'base::user',
                vjoinon       =>['tsmid'=>'userid'],
                vjoindisp     =>'email'),

      new kernel::Field::Interface(
                name          =>'tsmofficephone',
                group         =>'tscontact',
                label         =>'TSM Office Phone',
                vjointo       =>'base::user',
                vjoinon       =>['tsmid'=>'userid'],
                vjoindisp     =>'office_phone'),

      new kernel::Field::Interface(
                name          =>'tsmofficemobile',
                group         =>'tscontact',
                label         =>'TSM Mobile Phone',
                vjointo       =>'base::user',
                vjoinon       =>['tsmid'=>'userid'],
                vjoindisp     =>'office_mobile'),

      new kernel::Field::TextDrop(
                name          =>'tsm',
                group         =>'tscontact',
                translation   =>'itil::appl',
                label         =>'Technical Solution Manager',
                vjointo       =>'base::user',
                vjoinon       =>['tsmid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Interface(
                name          =>'tsm2id',
                group         =>'tscontact',
                dataobjattr   =>'appl.tsm2'),

      new kernel::Field::Interface(
                name          =>'tsm2email',
                group         =>'tscontact',
                label         =>'Deputy TSM E-Mail',
                vjointo       =>'base::user',
                vjoinon       =>['tsm2id'=>'userid'],
                vjoindisp     =>'email'),

      new kernel::Field::Interface(
                name          =>'tsm2officephone',
                group         =>'tscontact',
                label         =>'Deputy TSM Office Phone',
                vjointo       =>'base::user',
                vjoinon       =>['tsm2id'=>'userid'],
                vjoindisp     =>'office_phone'),

      new kernel::Field::Interface(
                name          =>'tsm2officemobile',
                group         =>'tscontact',
                label         =>'Deputy TSM Mobile Phone',
                vjointo       =>'base::user',
                vjoinon       =>['tsm2id'=>'userid'],
                vjoindisp     =>'office_mobile'),

      new kernel::Field::TextDrop(
                name          =>'tsm2',
                group         =>'tscontact',
                translation   =>'itil::appl',
                label         =>'Deputy Technical Solution Manager',
                vjointo       =>'base::user',
                vjoinon       =>['tsm2id'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Text(
                name          =>'businessteambossid',
                searchable    =>0,
                group         =>'tscontact',
                label         =>'Business Team Boss ID',
                onRawValue    =>\&getTeamBossID,
                readonly      =>1,
                uivisible     =>0, 
                depend        =>['businessteamid']),

      new kernel::Field::Text( 
                name          =>'businessteamboss',
                group         =>'tscontact',
                label         =>'Business Team Boss',
                onRawValue    =>\&getTeamBoss, 
                searchable    =>0,
                htmldetail    =>1,
                readonly      =>1,             
                depend        =>['businessteambossid']),

      new kernel::Field::Text( 
                name          =>'businessteambossemail',
                searchable    =>0,
                group         =>'tscontact',
                label         =>'Business Team Boss EMail',
                onRawValue    =>\&getTeamBossEMail, 
                htmldetail    =>0,
                readonly      =>1,             
                depend        =>['businessteambossid']),

      new kernel::Field::Link(
                name          =>'businessteamid',
                dataobjattr   =>'appl.businessteam'),

      new kernel::Field::Interface(
                name          =>'orderin1email',
                label         =>'primary Order in E-Mail',
                group         =>'tscontact',
                onRawValue    =>\&getOrderIn),

      new kernel::Field::Interface(
                name          =>'orderin2email',
                label         =>'secondary Order in E-Mail',
                group         =>'tscontact',
                onRawValue    =>\&getOrderIn),

      #new kernel::Field::Interface(
      new kernel::Field::Text(
                name          =>'orderin1name',
                label         =>'primary Order in',
                group         =>'tscontact',
                onRawValue    =>\&getOrderIn),

      new kernel::Field::Text(
                name          =>'orderin2name',
                label         =>'secondary Order in',
                group         =>'tscontact',
                onRawValue    =>\&getOrderIn),

      new kernel::Field::Interface(
                name          =>'orderin1id',
                label         =>'primary Order in ID',
                group         =>'tscontact',
                onRawValue    =>\&getOrderIn),

      new kernel::Field::Interface(
                name          =>'orderin2id',
                label         =>'secondary Order in ID',
                group         =>'tscontact',
                onRawValue    =>\&getOrderIn),

      new kernel::Field::Text(
                name          =>'custnameid',
                htmlwidth     =>'200px',
                group         =>'custapplnameing',
                label         =>'Customer Application ID',
                dataobjattr   =>'TCOM_appl.custapplid'),

     # new kernel::Field::Interface(  # kommt hinzu, sobald iwr die IDs von
     #           name          =>'custnameid',  # IT-BaseCMDB
     #           htmlwidth     =>'200px',
     #           label         =>'TCOM Applicationname ID',
     #           dataobjattr   =>'TCOM_appl.name'),

      new kernel::Field::SubList(
                name          =>'custcontracts',
                label         =>'Customer Contracts',
                group         =>'custcontracts',
                nodetaillink  =>1,
                vjointo       =>'itil::lnkapplcustcontract',
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>['custcontract','custcontractid',
                                 'custcontractcistatus'],
                vjoinbase     =>[{custcontractcistatusid=>'<=4'}]),

      new kernel::Field::SubList(
                name          =>'systems',
                label         =>'Systems',
                group         =>'systems',
                nodetaillink  =>1,
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{systemcistatusid=>"<=5"}],
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>['system','systemsystemid',
                                 'systemcistatus',
                                 'shortdesc'],
                vjoindispXMLV01=>['system','systemsystemid',
                                 'systemcistatus',
                                 'systemcistatusid',
                                 'isprod', 'isdevel', 'iseducation',
                                 'isapprovtest', 'isreference',
                                 'isapplserver','isbackupsrv',
                                 'isdatabasesrv','iswebserver',
                                 'osrelease',
                                 'shortdesc']),

      new kernel::Field::Container(
                name          =>'additional',
                label         =>'Additionalinformations',
                htmldetail    =>0,
                uivisible     =>0,
                dataobjattr   =>'appl.additional'),

   );
   $self->{history}=[qw(insert modify delete)];

   $self->setDefaultView(qw(name custname cistatus));
   $self->setWorktable("TCOM_appl");
   return($self);
}


sub getOrderIn
{
   my $self=shift;
   my $current=shift;
   my $id=$current->{id};
   my @l;
   if ($id ne ""){
      my %email;
      my $u=$self->getParent->getPersistentModuleObject("base::user");
      my $g=$self->getParent->getPersistentModuleObject("base::lnkgrpuserrole");
      my $l=$self->getParent->getPersistentModuleObject("itil::lnkapplcontact");
      $l->SetFilter({refid=>\$id,parentobj=>\'itil::appl'});
      $l->SetCurrentOrder(qw(NONE));
      foreach my $rec ($l->getHashList(qw(targetid roles target))){
         my @roles=($rec->{roles});
         @roles=@{$rec->{roles}} if (ref($rec->{roles}) eq "ARRAY");
         
         if ($self->{name} eq "orderin1id" && grep(/^orderin1$/,@roles)){
            push(@l,$rec->{targetid});
         }
         if ($self->{name} eq "orderin1name" && grep(/^orderin1$/,@roles)){
            push(@l,$rec->{targetname});
         }
         if ($self->{name} eq "orderin2id" && grep(/^orderin2$/,@roles)){
            push(@l,$rec->{targetid});
         }
         if ($self->{name} eq "orderin2name" && grep(/^orderin2$/,@roles)){
            push(@l,$rec->{targetname});
         }
         if (($self->{name} eq "orderin2email" && grep(/^orderin2$/,@roles)) ||
             ($self->{name} eq "orderin1email" && grep(/^orderin1$/,@roles))){
            if ($rec->{target} eq "base::user"){ 
               $u->SetFilter({userid=>\$rec->{targetid},cistatusid=>\'4'});
               $u->SetCurrentOrder(qw(NONE));
               my ($urec,$msg)=$u->getOnlyFirst(qw(email));
               if (defined($urec) && $urec->{email} ne ""){
                  $email{$urec->{email}}++;
               }
            }
            if ($rec->{target} eq "base::grp"){ 
               $g->SetFilter({grpid=>\$rec->{targetid},
                              nativrole=>\'RMember',cistatusid=>\'4'});
               $g->SetCurrentOrder(qw(NONE));
               foreach my $urec ($g->getHashList(qw(email))){
                  $email{$urec->{email}}++;
               }
            }
         }
      }
      if ($self->{name} eq "orderin2email" ||
          $self->{name} eq "orderin1email"){
         return([keys(%email)]);
      }
   }

   return(\@l);
}

sub getTeamBossID
{
   my $self=shift;
   my $current=shift;
   my $teamfieldname=$self->{depend}->[0];
   my $teamfield=$self->getParent->getField($teamfieldname);
   my $teamid=$teamfield->RawValue($current);
   my @teambossid=();
   if ($teamid ne ""){
      my $lnk=getModuleObject($self->getParent->Config,
                              "base::lnkgrpuser");
      $lnk->SetFilter({grpid=>\$teamid,
                       nativroles=>'RBoss'});
      my %bosslnk;
                     # at 20.02.2008 by Mr. Berdelmann F. it was requested
                     # that only one (the latest) boss should be displayed
      foreach my $rec ($lnk->getHashList(qw(lnkgrpuserid userid mdate))){
         if ($rec->{userid} ne ""){
            $bosslnk{$rec->{lnkgrpuserid}}=$rec;
         }
      }
      if (keys(%bosslnk)==1){
         foreach my $rec (values(%bosslnk)){
            push(@teambossid,$rec->{userid});
         }
      }
      if (keys(%bosslnk)>1){
         my $bossid;
         my $cdate;
         my $lnkr=getModuleObject($self->getParent->Config,
                                 "base::lnkgrpuserrole");
         $lnkr->SetFilter({lnkgrpuserid=>[keys(%bosslnk)],
                           role=>\'RBoss'});
         foreach my $rec ($lnkr->getHashList(qw(lnkgrpuserid cdate))){
            $cdate=$rec->{cdate} if (!defined($cdate));
            if ($cdate le $rec->{cdate}){
               $cdate=$rec->{cdate};
               $bossid=$bosslnk{$rec->{lnkgrpuserid}}->{userid};
            }
         }
         push(@teambossid,$bossid) if (defined($bossid));
      }


   }
   return(\@teambossid);
}

sub getTeamBoss
{
   my $self=shift;
   my $current=shift;
   my $teambossfieldname=$self->{depend}->[0];
   my $teambossfield=$self->getParent->getField($teambossfieldname);
   my $teambossid=$teambossfield->RawValue($current);
   my @teamboss;
   if ($teambossid ne "" && ref($teambossid) eq "ARRAY" && $#{$teambossid}>-1){
      my $user=getModuleObject($self->getParent->Config,"base::user");
      $user->SetFilter({userid=>$teambossid});
      foreach my $rec ($user->getHashList("fullname")){
         if ($rec->{fullname} ne ""){
            push(@teamboss,$rec->{fullname});
         }
      }
   }
   return(\@teamboss);
}


sub getTeamBossEMail
{
   my $self=shift;
   my $current=shift;
   my $teambossfieldname=$self->{depend}->[0];
   my $teambossfield=$self->getParent->getField($teambossfieldname);
   my $teambossid=$teambossfield->RawValue($current);
   my @teamboss;
   if ($teambossid ne "" && ref($teambossid) eq "ARRAY" && $#{$teambossid}>-1){
      my $user=getModuleObject($self->getParent->Config,"base::user");
      $user->SetFilter({userid=>$teambossid});
      foreach my $rec ($user->getHashList("email")){
         if ($rec->{email} ne ""){
            push(@teamboss,$rec->{email});
         }
      }
   }
   return(\@teamboss);
}




sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->IsMemberOf("admin")){
      my $userid=$self->getCurrentUserId();
      my %grp=$self->getGroupsOf($ENV{REMOTE_USER},
                                [qw(RMember RBoss RBoss2 RQManager)],"both");
      my @grpids=keys(%grp);
      @grpids=(qw(NONE)) if ($#grpids==-1);
      $self->SetNamedFilter("Customer",{customerid=>\@grpids});
   }

   return($self->SetFilter(@flt));
}




sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   $newrec->{id}=$oldrec->{id};
   if (!defined($newrec->{id}) || $newrec->{id} eq ""){
      $self->LastMsg(ERROR,"invalid write request to empty id");
      return(undef);
   }
   $newrec->{origname}=effVal($oldrec,$newrec,"name");
   $newrec->{customerid}=effVal($oldrec,$newrec,"customerid");
   if (exists($newrec->{custname})){
      $newrec->{custname}=trim(effVal($oldrec,$newrec,"custname"));
      if ($newrec->{custname} eq ""){
         $self->LastMsg(ERROR,"invalid customer application name - ".
                              "please use delete to remove a relation");
         return(undef);
      }
   }
   if (exists($newrec->{custnameid})){
      $newrec->{custnameid}=trim(effVal($oldrec,$newrec,"custnameid"));
   }

   return(1);
}


sub getSqlFrom
{
   my $self=shift;
   my @from=("appl left outer join TCOM_appl on appl.id=TCOM_appl.id ",
             "TCOM_appl left outer join appl on TCOM_appl.id=appl.id ");

   return(@from);
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
   return("tcomcontact","custapplnameing");
}  

sub getDetailBlockPriority
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),
          qw(default custapplnameing tcomcontact tscontact custcontracts));
}

sub HandleInfoAboSubscribe
{
   my $self=shift;
   my $id=Query->Param("CurrentIdToEdit");
   my $ia=$self->getPersistentModuleObject("base::infoabo");
   if ($id ne ""){
      $self->ResetFilter();
      $self->SetFilter({id=>\$id});
      my ($rec,$msg)=$self->getOnlyFirst(qw(name));
      print($ia->WinHandleInfoAboSubscribe({},
                      $self->SelfAsParentObject(),$id,$rec->{name},
                      "base::staticinfoabo",undef,undef));
   }
   else{
      print($self->noAccess());
   }
}

sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("itil::appl");
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}



















1;
