package itil::appl;
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
use kernel::CIStatusTools;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::CIStatusTools);

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

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                searchable    =>0,
                label         =>'W5BaseID',
                dataobjattr   =>'appl.id'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                htmlwidth     =>'250px',
                label         =>'Name',
                dataobjattr   =>'appl.name'),

      new kernel::Field::Mandator(),

      new kernel::Field::Link(
                name          =>'mandatorid',
                dataobjattr   =>'appl.mandator'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'appl.cistatus'),

      new kernel::Field::TextDrop(
                name          =>'databoss',
                label         =>'Databoss',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['databossid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'databossid',
                dataobjattr   =>'appl.databoss'),

      new kernel::Field::Link(
                name          =>'servicesupportid',
                dataobjattr   =>'appl.servicesupport'),

      new kernel::Field::Text(
                name          =>'conumber',
                htmlwidth     =>'100px',
                label         =>'CO-Number',
                weblinkto     =>'itil::costcenter',
                weblinkon     =>['conumber'=>'name'],
                dataobjattr   =>'appl.conumber'),

      new kernel::Field::Text(
                name          =>'applid',
                htmlwidth     =>'100px',
                label         =>'Application ID',
                dataobjattr   =>'appl.applid'),

      new kernel::Field::TextDrop(
                name          =>'responseteam',
                htmlwidth     =>'300px',
                group         =>'finance',
                label         =>'Service Management Team',
                vjointo       =>'base::grp',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['responseteamid'=>'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'responseteamid',
                dataobjattr   =>'appl.responseteam'),


      new kernel::Field::TextDrop(
                name          =>'sem',
                group         =>'finance',
                label         =>'Service Manager',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['semid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::TextDrop(
                name          =>'sememail',
                group         =>'finance',
                label         =>'Service Manager E-Mail',
                searchable    =>0,
                htmldetail    =>0,
                vjointo       =>'base::user',
                vjoinon       =>['semid'=>'userid'],
                vjoindisp     =>'email'),

      new kernel::Field::TextDrop(
                name          =>'sem2email',
                group         =>'finance',
                label         =>'Deputy Service Manager E-Mail',
                searchable    =>0,
                htmldetail    =>0,
                vjointo       =>'base::user',
                vjoinon       =>['sem2id'=>'userid'],
                vjoindisp     =>'email'),

      new kernel::Field::Link(
                name          =>'semid',
                dataobjattr   =>'appl.sem'),

      new kernel::Field::TextDrop(
                name          =>'businessteam',
                htmlwidth     =>'300px',
                group         =>'technical',
                label         =>'Business Team',
                vjointo       =>'base::grp',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['businessteamid'=>'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::TextDrop(
                name          =>'tsm',
                group         =>'technical',
                label         =>'Technical Solution Manager',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['tsmid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Text(
                name          =>'businessteambossid',
                group         =>'technical',
                label         =>'Business Team Boss ID',
                onRawValue    =>\&getTeamBossID,
                readonly      =>1,
                uivisible     =>0,
                depend        =>['businessteamid']),

      new kernel::Field::Text(
                name          =>'businessteamboss',
                group         =>'technical',
                label         =>'Business Team Boss',
                onRawValue    =>\&getTeamBoss,
                searchable    =>0,
                htmldetail    =>0,
                readonly      =>1,
                depend        =>['businessteambossid']),

      new kernel::Field::TextDrop(
                name          =>'tsmemail',
                group         =>'technical',
                label         =>'Technical Solution Manager E-Mail',
                vjointo       =>'base::user',
                searchable    =>0,
                htmldetail    =>0,
                readonly      =>1,
                vjoinon       =>['tsmid'=>'userid'],
                vjoindisp     =>'email'),

      new kernel::Field::TextDrop(
                name          =>'tsm2email',
                group         =>'technical',
                label         =>'Deputy Technical Solution Manager E-Mail',
                vjointo       =>'base::user',
                searchable    =>0,
                htmldetail    =>0,
                readonly      =>1,
                vjoinon       =>['tsm2id'=>'userid'],
                vjoindisp     =>'email'),

      new kernel::Field::TextDrop(
                name          =>'tsmphone',
                group         =>'technical',
                label         =>'Technical Solution Manager Office-Phone',
                vjointo       =>'base::user',
                htmldetail    =>0,
                readonly      =>1,
                searchable    =>0,
                vjoinon       =>['tsmid'=>'userid'],
                vjoindisp     =>'office_phone'),

      new kernel::Field::TextDrop(
                name          =>'tsmposix',
                group         =>'technical',
                label         =>'Technical Solution Manager POSIX',
                vjointo       =>'base::user',
                searchable    =>0,
                htmldetail    =>0,
                readonly      =>1,
                vjoinon       =>['tsmid'=>'userid'],
                vjoindisp     =>'posix'),

      new kernel::Field::Link(
                name          =>'tsmid',
                group         =>'technical',
                dataobjattr   =>'appl.tsm'),

      new kernel::Field::TextDrop(
                name          =>'customer',
                group         =>'customer',
                label         =>'Customer',
                vjointo       =>'base::grp',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['customerid'=>'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link( 
                name          =>'customerid',
                dataobjattr   =>'appl.customer'),

      new kernel::Field::TextDrop(
                name          =>'sem2',
                AllowEmpty    =>1,
                group         =>'finance',
                label         =>'Deputy Service Manager',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['sem2id'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'sem2id',
                dataobjattr   =>'appl.sem2'),


      new kernel::Field::TextDrop(
                name          =>'tsm2',
                AllowEmpty    =>1,
                group         =>'technical',
                label         =>'Deputy Technical Solution Manager',
                vjointo       =>'base::user',
                vjoinon       =>['tsm2id'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'tsm2id',
                group         =>'technical',
                dataobjattr   =>'appl.tsm2'),

      new kernel::Field::Select(
                name          =>'customerprio',
                group         =>'customer',
                label         =>'Customers Application Prioritiy',
                value         =>['1','2','3'],
                default       =>'2',
                htmleditwidth =>'50px',
                dataobjattr   =>'appl.customerprio'),

      new kernel::Field::Select(
                name          =>'criticality',
                group         =>'customer',
                label         =>'Criticality',
                allowempty    =>1,
                value         =>['CRnone','CRlow','CRmedium','CRhigh',
                                 'CRcritical'],
                htmleditwidth =>'100px',
                dataobjattr   =>'appl.criticality'),

      new kernel::Field::Select(
                name          =>'avgusercount',
                group         =>'customer',
                label         =>'average user count',
                allowempty    =>1,
                value         =>['10','50','100','250',
                                 '500','800','1000','1500','2000','2500','3000',
                                 '4000','5000','7500','10000','12500','15000',
                                 '20000','50000','100000','1000000','10000000'],
                htmleditwidth =>'100px',
                dataobjattr   =>'appl.avgusercount'),

      new kernel::Field::Select(
                name          =>'namedusercount',
                group         =>'customer',
                label         =>'named user count',
                allowempty    =>1,
                value         =>['10','50','100','250',
                                 '500','800','1000','1500','2000','2500','3000',
                                 '4000','5000','7500','10000','12500','15000',
                                 '20000','50000','100000','1000000','10000000'],
                htmleditwidth =>'100px',
                dataobjattr   =>'appl.namedusercount'),

      new kernel::Field::Link(
                name          =>'businessteamid',
                dataobjattr   =>'appl.businessteam'),

      new kernel::Field::SubList(
                name          =>'custcontracts',
                label         =>'Customer Contracts',
                group         =>'custcontracts',
                subeditmsk    =>'subedit.appl',
                vjointo       =>'itil::lnkapplcustcontract',
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>['custcontract','fraction'],
                vjoinbase     =>[{custcontractcistatusid=>'<=4'}],
                vjoininhash   =>['custcontractid','custcontractcistatusid',
                                 'custcontract','custcontractname']),

      new kernel::Field::SubList(
                name          =>'interfaces',
                label         =>'Interfaces',
                group         =>'interfaces',
                subeditmsk    =>'subedit.appl',
                vjointo       =>'itil::lnkapplappl',
                vjoinbase     =>[{toapplcistatus=>"<=4"}],
                vjoinon       =>['id'=>'fromapplid'],
                vjoindisp     =>['toappl','contype','conproto','conmode'],
                vjoininhash   =>['toappl','contype','conproto','conmode',
                                 'toapplid']),

      new kernel::Field::SubList(
                name          =>'systems',
                label         =>'Systems',
                group         =>'systems',
                allowcleanup  =>1,
                subeditmsk    =>'subedit.appl',
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{systemcistatusid=>"<=5"}],
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>['system','systemsystemid','systemcistatus',
                                 'shortdesc'],
                vjoininhash   =>['system','systemsystemid','systemcistatus',
                                 'systemid']),

      new kernel::Field::SubList(
                name          =>'systemnames',
                label         =>'active systemnames',
                group         =>'systems',
                htmldetail    =>0,
                htmlwidth     =>'130px',
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{systemcistatusid=>"4"}],
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>['system']),

      new kernel::Field::SubList(
                name          =>'systemids',
                label         =>'active systemids',
                group         =>'systems',
                htmldetail    =>0,
                htmlwidth     =>'130px',
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{systemcistatusid=>"4"}],
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>['systemsystemid']),

      new kernel::Field::Text(
                name          =>'applgroup',
                label         =>'Application Group',
                dataobjattr   =>'appl.applgroup'),

      new kernel::Field::Textarea(
                name          =>'description',
                label         =>'Application Description',
                dataobjattr   =>'appl.description'),

      new kernel::Field::Textarea(
                name          =>'currentvers',
                label         =>'Application Version',
                dataobjattr   =>'appl.currentvers'),

      new kernel::Field::Boolean(
                name          =>'allowifupdate',
                group         =>'control',
                label         =>'allow automatic updates by interfaces',
                dataobjattr   =>'appl.allowifupdate'),

      new kernel::Field::Boolean(
                name          =>'isnosysappl',
                group         =>'control',
                htmleditwidth =>'30%',
                label         =>'Application has no system components',
                dataobjattr   =>'appl.is_applwithnosys'),

      new kernel::Field::Boolean(
                name          =>'allowdevrequest',
                group         =>'control',
                searchable    =>0,
                htmleditwidth =>'30%',
                label         =>'allow developer request workflows',
                container     =>'additional'),

      new kernel::Field::Boolean(
                name          =>'allowbusinesreq',
                group         =>'control',
                searchable    =>0,
                htmleditwidth =>'30%',
                label         =>'allow business request workflows',
                container     =>'additional'),

      new kernel::Field::Boolean(
                name          =>'issoxappl',
                group         =>'control',
                htmleditwidth =>'30%',
                label         =>'Application is mangaged by rules of SOX',
                dataobjattr   =>'appl.is_soxcontroll'),


      new kernel::Field::TextDrop(
                name          =>'servicesupport',
                label         =>'Service&Support Class',
                group         =>'misc',
                vjointo       =>'itil::servicesupport',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['servicesupportid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Select(
                name          =>'slacontroltool',
                group         =>'misc',
                label         =>'SLA control tool type',
                value         =>['',
                                 'BigBrother',
                                 'Tivoli',
                                 'TV-CC',
                                 'SAP-Reporter',
                                 'no SLA control'],
                htmleditwidth =>'200px',
                dataobjattr   =>'appl.slacontroltool'),

      new kernel::Field::Number(
                name          =>'slacontravail',
                group         =>'misc',
                htmlwidth     =>'100px',
                precision     =>5,
                unit          =>'%',
                searchable    =>0,
                label         =>'SLA availibility guaranted by contract',
                dataobjattr   =>'appl.slacontravail'),

      new kernel::Field::Select(
                name          =>'slacontrbase',
                group         =>'misc',
                label         =>'SLA availibility calculation base',
                transprefix   =>'slabase.',
                searchable    =>0,
                value         =>['',
                                 'month',
                                 'year'],
                htmleditwidth =>'100px',
                dataobjattr   =>'appl.slacontrbase'),

      new kernel::Field::Textarea(
                name          =>'maintwindow',
                group         =>'misc',
                searchable    =>0, 
                label         =>'Maintenance Window',
                dataobjattr   =>'appl.maintwindow'),

      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'misc',
                label         =>'Comments',
                searchable    =>0, 
                dataobjattr   =>'appl.comments'),

      new kernel::Field::Text(
                name          =>'kwords',
                group         =>'misc',
                label         =>'Keywords',
                dataobjattr   =>'appl.kwords'),

      new kernel::Field::FileList(
                name          =>'attachments',
                label         =>'Attachments',
                parentobj     =>'itil::appl',
                group         =>'attachments'),

      new kernel::Field::Container(
                name          =>'additional',
                label         =>'Additionalinformations',
                htmldetail    =>0,
                uivisible     =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $rec=$param{current};
                   if (!defined($rec->{$self->Name()})){
                      return(0);
                   }
                   return(1);
                },
                dataobjattr   =>'appl.additional'),

      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                vjoininhash   =>['mdate','targetid','target','roles'],
                group         =>'contacts'),

      new kernel::Field::PhoneLnk(
                name          =>'phonenumbers',
                searchable    =>0,
                label         =>'Phonenumbers',
                group         =>'phonenumbers',
                vjoinbase     =>[{'parentobj'=>\'itil::appl'}],
                subeditmsk    =>'subedit'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'appl.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'appl.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                history       =>0,
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'appl.srcload'),

      new kernel::Field::SubList(
                name          =>'accountnumbers',
                label         =>'Account numbers',
                group         =>'accountnumbers',
                allowcleanup  =>1,
                subeditmsk    =>'subedit.appl',
                vjointo       =>'itil::lnkaccountingno',
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>['name','cdate','comments']),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'appl.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'appl.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'appl.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'appl.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'appl.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'appl.realeditor'),

      new kernel::Field::Link(
                name          =>'sectarget',
                noselect      =>'1',
                dataobjattr   =>'lnkcontact.target'),

      new kernel::Field::Link(
                name          =>'sectargetid',
                noselect      =>'1',
                dataobjattr   =>'lnkcontact.targetid'),

      new kernel::Field::Link(
                name          =>'secroles',
                noselect      =>'1',
                dataobjattr   =>'lnkcontact.croles'),

      new kernel::Field::QualityText(),
      new kernel::Field::QualityState(),
      new kernel::Field::QualityOk(),
      new kernel::Field::QualityLastDate(
                dataobjattr   =>'appl.lastqcheck'),
   );
   $self->{history}=[qw(insert modify delete)];
   $self->{workflowlink}={ workflowkey=>[id=>'affectedapplicationid']
                         };
   $self->{use_distinct}=1;
   $self->{PhoneLnkUsage}=\&PhoneUsage;
   $self->setDefaultView(qw(name mandator cistatus mdate));
   return($self);
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
      foreach my $rec ($lnk->getHashList("userid")){
         if ($rec->{userid} ne ""){
            push(@teambossid,$rec->{userid});
         }
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

sub PhoneUsage
{
   my $self=shift;
   my $current=shift;
   my @codes=qw(phoneRB phoneMVD phoneMISC phoneDEV);
   my @l;
   foreach my $code (@codes){
      push(@l,$code,$self->T($code));
   }
   return(@l);

}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5base"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   $self->setWorktable("appl");
   return(1);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/appl.jpg?".$cgi->query_string());
}

sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $selfasparent=$self->SelfAsParentObject();
   my $from="$worktable left outer join lnkcontact ".
            "on lnkcontact.parentobj='$selfasparent' ".
            "and $worktable.id=lnkcontact.refid";

   return($from);
}


sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->isDirectFilter(@flt) && 
       !$self->IsMemberOf([qw(admin w5base.itil.appl.read w5base.itil.read)],
                          "RMember")){
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
                                  ["REmployee","RMember"],"both");
      my @grpids=keys(%grps);
      my $userid=$self->getCurrentUserId();
      push(@flt,[
                 {mandatorid=>\@mandators},
                 {databossid=>$userid},
                 {semid=>$userid},       {sem2id=>$userid},
                 {tsmid=>$userid},       {tsm2id=>$userid},
                 {businessteamid=>\@grpids},
                 {responseteamid=>\@grpids},
                 {sectargetid=>\$userid,sectarget=>\'base::user',
                  secroles=>"*roles=?write?=roles* *roles=?read?=roles*"},
                 {sectargetid=>\@grpids,sectarget=>\'base::grp',
                  secroles=>"*roles=?write?=roles* *roles=?read?=roles*"}
                ]);
   }
   return($self->SetFilter(@flt));
}

sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("itil::appl");
}
         

sub SecureValidate
{
   return(kernel::DataObj::SecureValidate(@_));
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $name=trim(effVal($oldrec,$newrec,"name"));
   
   if ($name eq "" || $name=~m/[;,\s\&\\]/){
      $self->LastMsg(ERROR,
           sprintf($self->T("invalid application name '%s' specified"),$name));
      return(0);
   }
   $newrec->{name}=$name;

   if (defined($newrec->{slacontravail})){
      if ($newrec->{slacontravail}>100 || $newrec->{slacontravail}<0){
         my $fo=$self->getField("slacontravail");
         my $msg=sprintf($self->T("value of '%s' is not allowed"),$fo->Label());
         $self->LastMsg(ERROR,$msg);
         return(0);
      }
   }
   if (exists($newrec->{conumber})){
      my $conumber=trim(effVal($oldrec,$newrec,"conumber"));
      if ($conumber ne ""){
         $conumber=~s/^0+//g;
         if (!($conumber=~m/^\d{5,13}$/)){
            my $fo=$self->getField("conumber");
            my $msg=sprintf($self->T("value of '%s' is not correct ".
                                     "numeric"),$fo->Label());
            $self->LastMsg(ERROR,$msg);
            return(0);
         }
         $newrec->{conumber}=$conumber;
      }
   }
   foreach my $v (qw(avgusercount namedusercount)){
      $newrec->{$v}=undef if (exists($newrec->{$v}) && $newrec->{$v} eq "");
   }

   ########################################################################
   # standard security handling
   #
   if ($self->isDataInputFromUserFrontend() && !$self->IsMemberOf("admin")){
      my $userid=$self->getCurrentUserId();
      if (!defined($oldrec)){
         if (!defined($newrec->{databossid}) ||
             $newrec->{databossid}==0){
            my $userid=$self->getCurrentUserId();
            $newrec->{databossid}=$userid;
         }
      }
      if (defined($newrec->{databossid}) &&
          $newrec->{databossid}!=$userid &&
          $newrec->{databossid}!=$oldrec->{databossid}){
         $self->LastMsg(ERROR,"you are not authorized to set other persons ".
                              "as databoss");
         return(0);
      }
   }
   ########################################################################
   if (defined($newrec->{applid})){
      $newrec->{applid}=trim($newrec->{applid});
   }
   if (effVal($oldrec,$newrec,"applid")=~m/^\s*$/){
      $newrec->{applid}=undef;
   }
   ########################################################################

   return(0) if (!$self->HandleCIStatusModification($oldrec,$newrec,"name"));
   return(1);
}


sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $bak=$self->SUPER::FinishWrite($oldrec,$newrec);
   $self->NotifyOnCIStatusChange($oldrec,$newrec);
   return($bak);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();

   my @databossedit=qw(default interfaces finance technical contacts misc
                       systems attachments accountnumbers 
                       customer control phonenumbers);
   if (!defined($rec)){
      return("default");
   }
   else{
      if ($rec->{databossid}==$userid){
         return(@databossedit);
      }
      if ($self->IsMemberOf("admin")){
         return(@databossedit);
      }
      if (defined($rec->{contacts}) && ref($rec->{contacts}) eq "ARRAY"){
         my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
                                     ["RMember"],"both");
         my @grpids=keys(%grps);
         foreach my $contact (@{$rec->{contacts}}){
            if ($contact->{target} eq "base::user" &&
                $contact->{targetid} ne $userid){
               next;
            }
            if ($contact->{target} eq "base::grp"){
               my $grpid=$contact->{targetid};
               next if (!grep(/^$grpid$/,@grpids));
            }
            my @roles=($contact->{roles});
            @roles=@{$contact->{roles}} if (ref($contact->{roles}) eq "ARRAY");
            if (grep(/^write$/,@roles)){
               return(@databossedit);
            }
         }
      }
      if ($rec->{mandatorid}!=0 && 
         $self->IsMemberOf($rec->{mandatorid},"RCFManager","down")){
         return(@databossedit);
      }
      if ($rec->{businessteamid}!=0 && 
         $self->IsMemberOf($rec->{businessteamid},"RCFManager","down")){
         return(@databossedit);
      }
      if ($rec->{responseteamid}!=0 && 
         $self->IsMemberOf($rec->{businessteamid},"RCFManager","down")){
         return(@databossedit);
      }
   }
   return(undef);
}

sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;
   my $bak=$self->SUPER::FinishDelete($oldrec);

   my $refobj=getModuleObject($self->Config,"itil::lnkapplcustcontract");
   if (defined($refobj)){
      my $idname=$self->IdField->Name();
      my $id=$oldrec->{$idname};
      $refobj->SetFilter({'appl'=>\$id});
      $refobj->SetCurrentView(qw(ALL));
      $refobj->ForeachFilteredRecord(sub{
                         $refobj->ValidatedDeleteRecord($_);
                      });
   }
   my $refobj=getModuleObject($self->Config,"itil::lnkapplappl");
   if (defined($refobj)){
      my $idname=$self->IdField->Name();
      my $id=$oldrec->{$idname};
      $refobj->SetFilter({'fromapplid'=>\$id});
      $refobj->SetCurrentView(qw(ALL));
      $refobj->ForeachFilteredRecord(sub{
                         $refobj->ValidatedDeleteRecord($_);
                      });
   }
   return($bak);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),
          qw(default finance technical customer custcontracts 
             contacts phonenumbers 
             interfaces systems misc attachments control 
             accountnumbers source));
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






1;
