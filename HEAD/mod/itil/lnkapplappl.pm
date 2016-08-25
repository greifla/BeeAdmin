package itil::lnkapplappl;
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
use itil::lib::Listedit;
@ISA=qw(itil::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);
   

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                label         =>'LinkID',
                dataobjattr   =>'lnkapplappl.id'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::TextDrop(
                name          =>'fromappl',
                htmlwidth     =>'250px',
                label         =>'from Application',
                vjointo       =>'itil::appl',
                vjoinon       =>['fromapplid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::TextDrop(
                name          =>'toappl',
                htmlwidth     =>'150px',
                label         =>'to Application',
                vjointo       =>'itil::appl',
                vjoinon       =>['toapplid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'Interface-State',
                vjointo       =>'base::cistatus',
                vjoineditbase =>{id=>[3,4,5,6]},
                default       =>'4',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'fullname',
                label         =>'Interface fullname',
                selectfix     =>1,
                dataobjattr   =>"concat(fromappl.name,':',".
                                "toappl.name,':',lnkapplappl.conprotocol)"),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'lnkapplappl.cistatus'),

      new kernel::Field::Select(
                name          =>'contype',
                label         =>'Interfacetype',
                htmlwidth     =>'250px',
                transprefix   =>'contype.',
                value         =>[qw(0 1 2 3 4 5)],
                default       =>'0',
                htmleditwidth =>'350px',
                dataobjattr   =>'lnkapplappl.contype'),

      new kernel::Field::Interface(
                name          =>'rawcontype',
                label         =>'raw Interfacetype',
                dataobjattr   =>'lnkapplappl.contype'),

      new kernel::Field::Select(
                name          =>'conmode',
                label         =>'Interfacemode',
                value         =>[qw(online batch manuell)],
                default       =>'online',
                htmleditwidth =>'150px',
                dataobjattr   =>'lnkapplappl.conmode'),

      new kernel::Field::Select(
                name          =>'conproto',
                label         =>'Interfaceprotocol',
                value         =>[qw( unknown 
                     BCV CAPI CIFS Corba DB-Connection DB-Link dce DCOM DSO 
                     ftp html http https IMAP IMAPS IMAP4 
                     jdbc ldap ldaps LDIF MAPI 
                     MFT MQSeries Netegrity NFS ODBC OSI openFT
                     papier pkix-cmp POP3 POP3S 
                     rcp rfc RMI RPC rsh sftp sldap SMB SMB-AuthOnly
                     smtp snmp SPML
                     ssh tuxedo TCP UC4 UCP/SMS utm X.31 XAPI xml
                     OTHER)],
                default       =>'online',
                htmlwidth     =>'50px',
                htmleditwidth =>'150px',
                dataobjattr   =>'lnkapplappl.conprotocol'),


      new kernel::Field::Htmlarea(
                name          =>'htmldescription',
                searchable    =>0,
                group         =>'desc',
                label         =>'Interface description',
                dataobjattr   =>'lnkapplappl.description'),

      new kernel::Field::Htmlarea(
                name          =>'htmlagreements',
                searchable    =>0,
                group         =>'agreement',
                label         =>'Agreements',
                dataobjattr   =>'lnkapplappl.agreements'),

      new kernel::Field::Select(
                name          =>'fromapplicationcistatus',
                label         =>'from Application CI-State',
                readonly      =>1,
                htmldetail    =>0,
                vjoineditbase =>{id=>">0"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['fromapplcistatus'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'fromapplcistatus',
                label         =>'from Appl CI-Status',
                dataobjattr   =>'fromappl.cistatus'),

      new kernel::Field::Select(
                name          =>'toapplicationcistatus',
                label         =>'to Application CI-State',
                readonly      =>1,
                htmldetail    =>0,
                vjoineditbase =>{id=>">0"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['toapplcistatus'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'toapplcistatus',
                label         =>'to Appl CI-Status',
                dataobjattr   =>'toappl.cistatus'),


      new kernel::Field::SubList(
                name          =>'interfacescomp',
                label         =>'Interface components',
                group         =>'interfacescomp',
                subeditmsk    =>'subedit.appl',
                vjointo       =>'itil::lnkapplapplcomp',
                allowcleanup  =>1,
                vjoinon       =>['id'=>'lnkapplappl'],
                vjoindisp     =>['name','namealt1','namealt2',"comments"]),

      new kernel::Field::Text(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'lnkapplappl.comments'),

      new kernel::Field::Boolean(
                name          =>'ifagreementneeded',
                jsonchanged   =>\&getifagreementHandlingScript,
                jsoninit      =>\&getifagreementHandlingScript,
                group         =>'ifagreement',
                label         =>'interface agreement necessary',
                dataobjattr   =>'lnkapplappl.ifagreementneeded'),

      new kernel::Field::Select(
                name          =>'ifagreementlang',
                label         =>'interface agreement language',
                group         =>'ifagreement',
                value         =>['',LangTable()],
                dataobjattr   =>'lnkapplappl.ifagreementlang'),

      new kernel::Field::File(
                name          =>'ifagreementdoc',
                label         =>'Interface-Agreement-Document',
                searchable    =>0,
                uploadable    =>0,
                types         =>['pdf','xls','doc'],
                mimetype      =>'ifagreementdoctype',
                filename      =>'ifagreementdocname',
                uploaddate    =>'ifagreementdocdate',
                maxsize       =>'2097152',
                group         =>'ifagreement',
                dataobjattr   =>'lnkapplappl.ifagreementdoc'),

      new kernel::Field::Text(
                name          =>'ifagreementdocname',
                label         =>'Interface-Agreement-Document Name',
                searchable    =>0,
                uploadable    =>0,
                readonly      =>1,
                group         =>'ifagreement',
                dataobjattr   =>'lnkapplappl.ifagreementdocname'),

      new kernel::Field::Date(
                name          =>'ifagreementdocdate',
                label         =>'Interface-Agreement-Document Date',
                searchable    =>0,
                uploadable    =>0,
                readonly      =>1,
                group         =>'ifagreement',
                dataobjattr   =>'lnkapplappl.ifagreementdocdate'),

      new kernel::Field::Text(
                name          =>'ifagreementdoctype',
                label         =>'Interface-Agreement-Document Type',
                searchable    =>0,
                uploadable    =>0,
                htmldetail    =>0,
                readonly      =>1,
                group         =>'ifagreement',
                dataobjattr   =>'lnkapplappl.ifagreementdoctype'),

     new kernel::Field::Textarea(
                name          =>'ifagreementexclreason',
                group         =>'ifagreement',
                searchable    =>0,
                htmldetail    =>'NotEmptyOrEdit',
                depend        =>['ifagreementneeded'],
                label         =>'reason on not needed interface agreement',
                dataobjattr   =>'lnkapplappl.ifagreementexclreason'),

      new kernel::Field::Text(
                name          =>'fromurl',
                group         =>'comdetails',
                label         =>'from URL',
                dataobjattr   =>'lnkapplappl.fromurl'),

      new kernel::Field::Text(
                name          =>'fromservice',
                group         =>'comdetails',
                label         =>'from Servicename',
                dataobjattr   =>'lnkapplappl.fromservice'),

      new kernel::Field::Text(
                name          =>'tourl',
                group         =>'comdetails',
                label         =>'to URL',
                dataobjattr   =>'lnkapplappl.tourl'),

      new kernel::Field::Text(
                name          =>'toservice',
                group         =>'comdetails',
                label         =>'to Servicename',
                dataobjattr   =>'lnkapplappl.toservice'),

      new kernel::Field::Select(
                name          =>'monitor',
                group         =>'classi',
                label         =>'Interface Monitoring',
                allowempty    =>1,
                weblinkto     =>"none",
                vjointo       =>'base::itemizedlist',
                vjoinbase     =>{
                   selectlabel=>\'itil::lnkapplappl::monitor',
                },
                vjoineditbase =>{
                   selectlabel=>\'itil::lnkapplappl::monitor',
                   cistatusid=>\'4'
                },
                vjoinon       =>['rawmonitor'=>'name'],
                vjoindisp     =>'displaylabel',
                htmleditwidth =>'200px'),

      new kernel::Field::Interface(
                name          =>'rawmonitor',
                group         =>'classi',
                label         =>'raw Interface Monitoring',
                dataobjattr   =>'lnkapplappl.monitor'),

      new kernel::Field::Select(
                name          =>'monitortool',
                group         =>'classi',
                label         =>'Interface Monitoring Tool',
                allowempty    =>1,
                weblinkto     =>"none",
                vjointo       =>'base::itemizedlist',
                vjoinbase     =>{
                   selectlabel=>\'itil::appl::applbasemoni',
                },
                vjoineditbase =>{
                   selectlabel=>\'itil::appl::applbasemoni',
                   cistatusid=>\'4'
                },
                vjoinon       =>['rawmonitortool'=>'name'],
                vjoindisp     =>'displaylabel',
                htmleditwidth =>'200px'),

      new kernel::Field::Interface(
                name          =>'rawmonitortool',
                group         =>'classi',
                label         =>'raw Interface Monitoring Tool',
                dataobjattr   =>'lnkapplappl.monitortool'),

      new kernel::Field::Select(
                name          =>'monitorinterval',
                group         =>'classi',
                label         =>'Interface Monitoring Interval',
                allowempty    =>1,
                weblinkto     =>"none",
                vjointo       =>'base::itemizedlist',
                vjoinbase     =>{
                   selectlabel=>\'itil::lnkapplappl::monitorinterval',
                },
                vjoineditbase =>{
                   selectlabel=>\'itil::lnkapplappl::monitorinterval',
                   cistatusid=>\'4'
                },
                vjoinon       =>['rawmonitorinterval'=>'name'],
                vjoindisp     =>'displaylabel',
                htmleditwidth =>'200px'),

      new kernel::Field::Interface(
                name          =>'rawmonitorinterval',
                group         =>'classi',
                label         =>'raw Interface Monitoring Interval',
                dataobjattr   =>'lnkapplappl.monitorinterval'),


      new kernel::Field::Select(
                name          =>'persrelated',
                group         =>'classi',
                label         =>'transfer of person related informations',
                default       =>'0',
                transprefix   =>'PERS.',
                value         =>[0,1,2],
                htmleditwidth =>'200px',
                dataobjattr   =>'lnkapplappl.exch_personal_data'),

      new kernel::Field::Select(
                name          =>'iscrypted',
                group         =>'classi',
                label         =>'encrypted communication',
                default       =>'0',
                transprefix   =>'CRYPT.',
                value         =>[0,1,2,3],
                htmleditwidth =>'200px',
                dataobjattr   =>'lnkapplappl.iscrypted'),

      new kernel::Field::Boolean(
                name          =>'handleconfidential',
                group         =>'classi',
                label         =>'handle interface documentation confidential',
                dataobjattr   =>'lnkapplappl.handleconfidential'),


      new kernel::Field::Text(
                name          =>'implapplversion',
                group         =>'impl',
                label         =>'implemented since "from"-application release',
                dataobjattr   =>'lnkapplappl.implapplversion'),

      new kernel::Field::Text(
                name          =>'implproject',
                group         =>'impl',
                label         =>'implementation project name',
                dataobjattr   =>'lnkapplappl.implproject'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnkapplappl.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'lnkapplappl.modifyuser'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnkapplappl.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnkapplappl.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'lnkapplappl.srcload'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"lnkapplappl.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(lnkapplappl.id,35,'0')"),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkapplappl.createdate'),
                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkapplappl.modifydate'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'lnkapplappl.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'lnkapplappl.realeditor'),

      new kernel::Field::Link(
                name          =>'fromapplid',
                label         =>'from ApplID',
                dataobjattr   =>'lnkapplappl.fromappl'),

      new kernel::Field::Link(
                name          =>'lnktoapplid',
                label         =>'to ApplicationID',
                dataobjattr   =>'toappl.applid'),

      new kernel::Field::Link(
                name          =>'toapplid',
                label         =>'to ApplID',
                dataobjattr   =>'lnkapplappl.toappl'),

   );
   $self->{history}={
      insert=>[
         'local',
         {dataobj=>'itil::appl', id=>'fromapplid',
          field=>'toapplid',as=>'interfaces'}
      ],
      update=>[
         'local'
      ],
      delete=>[
         {dataobj=>'itil::appl', id=>'fromapplid',
          field=>'fullname',as=>'interfaces'}
      ]
   };


   $self->setDefaultView(qw(fromappl toappl cistatus cdate editor));
   $self->setWorktable("lnkapplappl");
   return($self);
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
   if (!defined(Query->Param("search_fromapplicationcistatus"))){
     Query->Param("search_fromapplicationcistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
   if (!defined(Query->Param("search_toapplicationcistatus"))){
     Query->Param("search_toapplicationcistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}


sub getSqlFrom
{
   my $self=shift;
   my $from="lnkapplappl ".
            "left outer join appl as toappl ".
            "on lnkapplappl.toappl=toappl.id ".
            "left outer join appl as fromappl ".
            "on lnkapplappl.fromappl=fromappl.id";
   return($from);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/lnkapplappl.jpg?".$cgi->query_string());
}


sub getifagreementHandlingScript
{
   my $self=shift;
   my $app=$self->getParent();

   my $d=<<EOF;

var d=document.forms[0].elements['Formated_ifagreementneeded'];
var c=document.forms[0].elements['Formated_ifagreementexclreason'];

if (d){
   var v=d.options[d.selectedIndex].value;
   if (v!="" && v!="0"){
      if (c){
         c.disabled=true;
         //addClass(c,"disabledClass");
      }
   }
   else{
      if (c){
         c.disabled=false;
         //removeClass(c,"disabledClass");
      }
   }
}

EOF
   return($d);
}




sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $bak=$self->SUPER::FinishWrite($oldrec,$newrec);

   my $userid=$self->getCurrentUserId();
   my $mode;
   my ($applrec,$msg);

   my $toapplChanged=0;
   if (defined($oldrec) && effChanged($oldrec,$newrec,'toapplid')) {
      $toapplChanged=1;
   }

   my $applobj=getModuleObject($self->Config,'itil::appl');

   if (exists($newrec->{toapplid}) && 
       (!defined($oldrec) || $toapplChanged)) {
      $mode='InterfaceNew';
   }
   elsif (effChanged($oldrec,$newrec,'cistatusid')) {
      $mode='InterfaceUpdate';
      $newrec->{id}=$oldrec->{id} if (!defined($newrec->{id}));
   }

   if ($mode ne "") {
      $applobj->SetFilter({id=>\$newrec->{fromapplid}});
      ($applrec,$msg)=$applobj->getOnlyFirst(qw(name));
      $newrec->{fromappl}=$applrec->{name};

      $applobj->ResetFilter();
      $applobj->SetFilter({id=>\$newrec->{toapplid}});
      ($applrec,$msg)=$applobj->getOnlyFirst(qw(databossid contacts name));
      $newrec->{toappl}=$applrec->{name};

      $self->SetFilter({id=>$newrec->{id}});
      my ($lnk,$msg)=$self->getOnlyFirst(qw(cistatus));
      $newrec->{cistatus}=$lnk->{cistatus};
      $applobj->NotifyWriteAuthorizedContacts($applrec,undef,
                   {emailfrom=>$userid},{rec=>$newrec,mode=>$mode},
                   \&NotifyIfPartner);
   }

   if ($toapplChanged) {
      $applobj->ResetFilter();
      $applobj->SetFilter({id=>\$oldrec->{toapplid}});
      ($applrec,$msg)=$applobj->getOnlyFirst(qw(databossid contacts));
      
      $applobj->NotifyWriteAuthorizedContacts($applrec,undef,
                   {emailfrom=>$userid},{rec=>$oldrec,mode=>'InterfaceDeleted'},
                   \&NotifyIfPartner); 
   }

   return($bak);
}


sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;
   my $bak=$self->SUPER::FinishDelete($oldrec);

   my $userid=$self->getCurrentUserId();
   my $appl=getModuleObject($self->Config,'itil::appl');
   $appl->SetFilter({id=>\$oldrec->{toapplid}});
   my ($toappl,$msg)=$appl->getOnlyFirst(qw(databossid contacts));
   $appl->NotifyWriteAuthorizedContacts($toappl,undef,
             {emailfrom=>$userid},{rec=>$oldrec,mode=>'InterfaceDeleted'},
             \&NotifyIfPartner);

   return($bak);
}
 

sub NotifyIfPartner
{
   my $self=shift;
   my $notifyparam=shift;
   my $notifycontrol=shift;
   my $subject;
   my $text;

   return(undef) if (ref($notifycontrol->{rec}) ne 'HASH');
   my %rec=%{$notifycontrol->{rec}};

   my $lnkobj=getModuleObject($self->Config,'itil::lnkapplappl');

   $lnkobj->SetFilter({id=>$rec{id}});
   my ($ifurl,$msg)=$lnkobj->getOnlyFirst('urlofcurrentrec');

   # key = contype of fromappl
   # val = possible contypes of toappl
   my %contypeMap=(0=>[0,3],1=>[2,5],2=>[1,4],
                   3=>[3,0],4=>[2,5],5=>[1,4]);

   my %flt=(fromapplid=>\$rec{toapplid},
            fromapplcistatus=>[3,4,5],
            toapplid=>\$rec{fromapplid},
            conproto=>\$rec{conproto},
            contype=>$contypeMap{$rec{contype}},
            cistatusid=>\'<6');

   my $ifparam=$self->T('Interfacetype').': ';
   $ifparam.=$self->T('contype.'.$rec{contype})."\n";
   $ifparam.=$self->T('Interfaceprotocol').': ';
   $ifparam.=$rec{conproto}."\n";
   $ifparam.=$self->T('Interfacemode').': ';
   $ifparam.=$rec{conmode}."\n";
   $ifparam.=$self->T('Interface-State').': ';
   $ifparam.=$rec{cistatus}."\n\n";
   $ifparam.="Details:\n";
   $ifparam.=$ifurl->{urlofcurrentrec};

   my $todomsg=sprintf($self->T("If necessary, please perform any ".
                                "needed modifications of the ".
                                "interface documentation ".
                                "on the application '%s'."),
                       $rec{toappl});
   $text=$self->T("Dear Databoss").",\n\n";
   if ($notifycontrol->{mode} eq 'InterfaceNew') {
      $lnkobj->ResetFilter();
      $lnkobj->SetFilter(\%flt);
      return(undef) if ($lnkobj->CountRecords()!=0);

      $subject=sprintf($self->T("New Application interface to %s"),
                       $rec{toappl});
      $text.=sprintf($self->T("from the side of application '%s' ".
                              "has been documented a new interface ".
                              "to your application '%s'."),
                     $rec{fromappl},$rec{toappl});
      $text.="\n\n";
      $text.=$ifparam;
      $text.="\n\n";
      $text.=$todomsg;
   }

   if ($notifycontrol->{mode} eq 'InterfaceUpdate') {
      $lnkobj->ResetFilter();
      $lnkobj->SetFilter(\%flt);
      return(undef) if ($lnkobj->CountRecords()<1);
     
      $subject=sprintf($self->T("The status of Application interface ".
                                "to %s has been changed"),
                       $rec{toappl});
      $text.=sprintf($self->T("the application '%s' has changed the status ".
                              "of an application interface to '%s'."),
                     $rec{fromappl},$rec{toappl});
      $text.="\n\n";
      $text.=$ifparam;
      $text.="\n\n";
      $text.=$todomsg;
   }

   if ($notifycontrol->{mode} eq 'InterfaceDeleted') {
      $lnkobj->ResetFilter();
      $lnkobj->SetFilter(\%flt);
      return(undef) if ($lnkobj->CountRecords()<1);

      $subject=sprintf($self->T("An application interface ".
                                "to %s has been deleted"),
                       $rec{toappl});
      $text.=sprintf($self->T("from the side of application '%s' ".
                              "has been deleted an existing interface ".
                              "to your application '%s'."),
                     $rec{fromappl},$rec{toappl});
      $text.="\n\n";
      $text.=$ifparam;
      $text.="\n\n";
      $text.=$todomsg;
   }
   return(($subject,$text));
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $fromapplid=effVal($oldrec,$newrec,"fromapplid");
   if ($fromapplid==0){
      $self->LastMsg(ERROR,"invalid from application");
      return(0);
   }
   my $toapplid=effVal($oldrec,$newrec,"toapplid");
   if ($toapplid==0){
      $self->LastMsg(ERROR,"invalid to application");
      return(0);
   }
   my $fromservice=effVal($oldrec,$newrec,"fromservice");
   if ($fromservice ne "" &&
       ($fromservice=~m/[^a-z0-9_]/i)){
      $self->LastMsg(ERROR,"invalid characters in from service name");
      return(0);
   }

   my $toservice=effVal($oldrec,$newrec,"toservice");
   if ($toservice ne "" &&
       ($toservice=~m/[^a-z0-9_]/i)){
      $self->LastMsg(ERROR,"invalid characters in to service name");
      return(0);
   }
   my $fromurl=effVal($oldrec,$newrec,"fromurl");
   if ($fromurl ne ""){
      my $uri=$self->URLValidate($fromurl);
      if ($uri->{error}) {
         $self->LastMsg(ERROR,$uri->{error});
         return(0);
      }
   }
   my $tourl=effVal($oldrec,$newrec,"tourl");
   if ($tourl ne ""){
      my $uri=$self->URLValidate($tourl);
      if ($uri->{error}) {
         $self->LastMsg(ERROR,$uri->{error});
         return(0);
      }
   }

   if (effVal($oldrec,$newrec,"cistatusid")<5) {
      # check against flag 'isnoifaceappl' in fromappl
      my $fromapplid=effVal($oldrec,$newrec,"fromapplid");
      my $applobj=getModuleObject($self->Config,"itil::appl");
      $applobj->SetFilter({id=>\$fromapplid});
      my ($applrec,$msg)=$applobj->getOnlyFirst(qw(name isnoifaceappl));
      if ($applrec->{isnoifaceappl}) {
         my $msg=sprintf($self->T("Preset of '%s' is: ".
                                  "'Application has no interfaces'"),
                         $applrec->{name});
         $self->LastMsg(ERROR,$msg);
         return(0);
      }
   }

   if (!defined($oldrec)) {
      if (!exists($newrec->{htmlagreements})) {
         $newrec->{htmlagreements}=
            "<ul>".
            "<li><b>Ziel/Zweck der Schnittstelle - ".
            "Purpose of the Interface</b><br>".
            "(nothing documented)</li>".
            "<li><b>Aufbau/Testphase - ".
            "Setup/Testing Phase</b><br>".
            "(nothing documented)</li>".
            "<li><b>Regelverarbeitungen und Wartungen - ".
            "Rule Processing and Maintenance</b><br>".
            "(nothing documented)</li>".
            "<li><b>Verhalten bei Datenfehlern (Ansp.) - ".
            "Behaviour in case of Data Errors (Contact)</b><br>".
            "(nothing documented)</li>".
            "<li><b>Verhalten bei technischen Fehlern (Ansp.) - ".
            "Behaviour in case of Technical Errors (Contact)</b><br>".
            "(nothing documented)</li>".
            "<li><b>Evtl. Regressanspruchsregelungen - ".
            "Possible Regulations for Recourse Rights</b><br>".
            "(nothing documented)</li>".
            "</ul>";
      }
      if (!exists($newrec->{htmldescription})){
         $newrec->{htmldescription}=
            "<ul>".
            "<li><b>Technische Realisation (log. System, IP, usw.) - ".
            "Technical Realisation (log. system, IP, etc.)</b><br>".
            "(nothing documented)</li>".
            "<li><b>Übertragungsvolumen/Datenmenge - ".
            "Transfer Volumes</b><br>".
            "(nothing documented)</li>".
            "<li><b>Lieferzeiten/Lieferungs-Intervall - ".
            "Delivery Times/Delivery Intervals</b><br>".
            "(nothing documented)</li>".
            "<li><b>Beschreibung des Monitorings - ".
            "Detailed Description of Monitoring</b><br>".
            "(nothing documented)</li>".
            "<li><b>Inhalt/Felder - ".
            "Content/Fields</b><br>".
            "(nothing documented)</li>";
      }
   }


   if (exists($newrec->{toapplid}) && 
       (!defined($oldrec) || $oldrec->{toapplid}!=$toapplid)){
      my $applobj=getModuleObject($self->Config,"itil::appl");
      $applobj->SetFilter({id=>\$newrec->{toapplid}});
      my ($applrec,$msg)=$applobj->getOnlyFirst(qw(cistatusid));
      if (!defined($applrec) || 
          $applrec->{cistatusid}>4 || $applrec->{cistatusid}==0){
         $self->LastMsg(ERROR,"selected application is currently unuseable");
         return(0);
      }
   }

   my $applid=effVal($oldrec,$newrec,"fromapplid");

   if (exists($newrec->{ifagreementneeded}) && $newrec->{ifagreementneeded}){
      $newrec->{ifagreementexclreason}='';
   }

   if ($self->isDataInputFromUserFrontend()){
      if (!$self->isWriteOnApplValid($applid,"interfaces")){
         $self->LastMsg(ERROR,"no write access");
         return(0);
      }
   }


   return(1);
}


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default ifagreement agreement comdetails impl
             interfacescomp desc classi source));
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   my @l=qw(header default ifagreement agreement comdetails impl
             interfacescomp desc classi source history); 
   if (defined($rec) && exists($rec->{ifagreementneeded}) &&
       !$rec->{ifagreementneeded}){
      @l=grep(!/^agreement$/,@l);
   }
   if (defined($rec) && $rec->{handleconfidential}){
      my $foundprivread=0;
      foreach my $appid ($rec->{fromapplid},$rec->{toapplid}){
         my $acl=$self->loadPrivacyAcl('itil::appl',$appid);
         if ($acl->{ro}){
            $foundprivread++;
            last;
         }
      }
      if (!$foundprivread){
         @l=grep(!/^agreement$/,@l);
         @l=grep(!/^ifagreement$/,@l);
         @l=grep(!/^impl$/,@l);
         @l=grep(!/^desc$/,@l);
         @l=grep(!/^comdetails$/,@l);
         @l=grep(!/^history$/,@l);
      }
   }


   return(@l);
}

sub SecureValidate
{
   return(kernel::DataObj::SecureValidate(@_));
}


sub isWriteValid
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $applid=effVal($oldrec,$newrec,"fromapplid");
   my @editgroup=("default","interfacescomp","desc","agreement",
                  "ifagreement",
                  "comdetails","impl","classi");

   return(@editgroup) if (!defined($oldrec) && !defined($newrec));
   return(@editgroup) if ($self->IsMemberOf("admin"));
   return(@editgroup) if ($self->isWriteOnApplValid($applid,"interfaces"));
   return(@editgroup) if (!$self->isDataInputFromUserFrontend());

   return(undef);
}

sub getRecordHtmlIndex
{
   my $self=shift;
   my $rec=shift;
   my $id=shift;
   my $viewgroups=shift;
   my $grouplist=shift;
   my $grouplabel=shift;
   my @indexlist=$self->SUPER::getRecordHtmlIndex($rec,$id,$viewgroups,
                                                  $grouplist,$grouplabel);
   push(@indexlist,{label=>$self->T('Interface agreement template'),
           href=>"InterfaceAgreement?id=$id",
           target=>"_blank"
          });

   return(@indexlist);
}

sub InterfaceAgreement
{
   my $self=shift;
   
   my $id=Query->Param("id");
   $self->ResetFilter();
   $self->SetFilter({id=>\$id,cistatusid=>"<=5"});
   my ($masterrec,$msg)=$self->getOnlyFirst(qw(fromapplid toapplid
                                               ifagreementlang));
   if (defined($masterrec)){
      my $oldlang;
      my $lang=$self->Lang();
      if (defined($ENV{HTTP_FORCE_LANGUAGE})) {
         $oldlang=$ENV{HTTP_FORCE_LANGUAGE};
      }
      if ($masterrec->{ifagreementlang} ne '') {
         $lang=$masterrec->{ifagreementlang};
         $ENV{HTTP_FORCE_LANGUAGE}=$lang;
      }

      my $appl=getModuleObject($self->Config,"itil::appl");
      $appl->ResetFilter();
      $appl->SetFilter({id=>\$masterrec->{fromapplid}});
      my ($ag1,$msg)=$appl->getOnlyFirst(qw(name id tsm applmgr description));
      $appl->ResetFilter();
      $appl->SetFilter({id=>\$masterrec->{toapplid}});
      my ($ag2,$msg)=$appl->getOnlyFirst(qw(name id tsm applmgr description));
      my @l=($ag1,$ag2);
      @l=sort({$a->{name} cmp $b->{name}} @l);

      $l[0]->{targetid}=$l[1]->{id};
      $l[1]->{targetid}=$l[0]->{id};
      $l[0]->{targetname}=$l[1]->{name};
      $l[1]->{targetname}=$l[0]->{name};
      $self->ResetFilter();
      $self->SetFilter([{fromapplid=>\$l[0]->{id},
                         toapplid=>\$l[0]->{targetid},
                         cistatusid=>"<=5"},
                        {fromapplid=>\$l[1]->{id},
                         toapplid=>\$l[1]->{targetid},
                         cistatusid=>"<=5"}]);
      my @iflist=$self->getHashList(qw(cdate mdate 
                                       fromapplid toapplid contype 
                                       conmode conproto
                                       htmlagreements htmldescription comments
                                       fromurl fromservice
                                       tourl toservice
                                       monitor monitortool
                                       monitorinterval persrelated));
      my %com=();
      foreach my $ifrec (@iflist){
         $ifrec->{key}=$ifrec->{fromapplid}."_".$ifrec->{toapplid}.
                       "_".$ifrec->{conmode}."_".$ifrec->{conproto};
         $ifrec->{revkey}=$ifrec->{toapplid}."_".$ifrec->{fromapplid}.
                       "_".$ifrec->{conmode}."_".$ifrec->{conproto};
         $com{$ifrec->{key}}++;
      }
      foreach my $ifrec (@iflist){
         $ifrec->{partnerok}=0;
         if (exists($com{$ifrec->{revkey}})){
            $ifrec->{partnerok}=1;
         }
      }
      foreach my $ctrl (@l){
         $ctrl->{interface}=[];
         foreach my $ifrec (@iflist){
            if ($ifrec->{fromapplid} eq $ctrl->{id}){
               push(@{$ctrl->{interface}},$ifrec);
            }
         }
      }

      my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
      my $n="../../../public/itil/load/lnkapplappl.jpg?".$cgi->query_string();
      my $html=$self->HttpHeader("text/html");

      my $skinbase='itil';
      my $formname='head';
      $html.=$self->getParsedTemplate("tmpl/ifagreement.form.$formname",
                                      {skinbase=>$skinbase,
                                       static  =>{LANG=>$lang,
                                                  LOGO=>$n,
                                                  APPLA=>$l[0]->{name},
                                                  APPLB=>$l[1]->{name}}});

      foreach my $ctrl (@l) {
         my $details="<p class=\"attention\">".
               sprintf($self->T("The interface agreement is described ".
                                "from the point of view of application '%s'."),
                                $ag1->{name}).
                     "</p>";
         (my $desc=$ctrl->{description})=~s{\n}{<br />}g;

         if ($#{$ctrl->{interface}}!=-1) {
            $details=$self->getParsedTemplate(
                               "tmpl/ifagreement.detail.head",
                               {skinbase=>$skinbase,
                                static=>{TARGET=>$ctrl->{targetname}}
                               });
            foreach my $ifrec (@{$ctrl->{interface}}){
               my %templvar=(CONMODE =>$ifrec->{conmode},
                             CONPROTO=>$ifrec->{conproto},
                             TARGET  =>$ctrl->{targetname});

               if ($ifrec->{comments} ne ""){
                  $templvar{COMMENTS}=$ifrec->{comments};
               }

               my @ifparam=qw(contype fromurl fromservice tourl toservice
                              monitor monitortool monitorinterval
                              persrelated);
               foreach my $param (@ifparam) {
                  if ($ifrec->{$param} ne "") {
                     my $label=$self->getField($param)->Label;
                     my $value;

                     if ($param eq 'contype') {
                        $value=$self->T("contype.$ifrec->{contype}");
                     }
                     elsif ($param eq 'persrelated') {
                        $value=$self->T("PERS.$ifrec->{persrelated}");
                     }
                     else {
                        $value=$ifrec->{$param};
                     }

                     $templvar{PARAM}.=$self->getParsedTemplate(
                                                 "tmpl/ext.ifagreement.param",
                                                 {skinbase=>$skinbase,
                                                  static=>{
                                                     LABEL=>$label,
                                                     PARAM=>$value
                                                 }});
                  }
               }

               foreach my $desc (qw(htmlagreements htmldescription)) {
                  if ($ifrec->{$desc} ne "") {
                     my $label=$self->getField($desc)->Label;

                     $templvar{DESCRIPTION}.=$self->getParsedTemplate(
                                   "tmpl/ext.ifagreement.description",
                                    {skinbase=>$skinbase,
                                     static=>{
                                        LABEL      =>$label,
                                        DESCRIPTION=>$ifrec->{$desc}
                                    }});
                  }
               }

               $details.=$self->getParsedTemplate(
                                   "tmpl/ifagreement.detail.line",
                                    {skinbase=>$skinbase,
                                     static=>\%templvar});
            }

            $details.=$self->getParsedTemplate(
                                "tmpl/ifagreement.detail.bottom",
                                {skinbase=>$skinbase});
         }

         $formname='line';
         $html.=$self->getParsedTemplate("tmpl/ifagreement.form.$formname",
                                         {skinbase=>$skinbase,
                                          static=>{
                                             APPL       =>$ctrl->{name},
                                             DESCRIPTION=>$desc,
                                             AM         =>$ctrl->{applmgr},
                                             TSM        =>$ctrl->{tsm},
                                             DETAILS    =>$details
                                         }});
      }

      my $dateobj=new kernel::Field::Date();
      $dateobj->setParent($self);
      my ($date,$tz)=$dateobj->getFrontendTimeString("HtmlDetail",
                                                     NowStamp("en"));
      my $formname='bottom';
      $html.=$self->getParsedTemplate("tmpl/ifagreement.form.$formname",
                                      {skinbase=>$skinbase,
                                       static  =>{NOW=>"$date $tz",
                                                  APPLA=>$l[0]->{name},
                                                  APPLB=>$l[1]->{name}}});
      print $html;
      
      if (defined($oldlang)) {
         $ENV{HTTP_FORCE_LANGUAGE}=$oldlang;
      }
      else {
         delete($ENV{HTTP_FORCE_LANGUAGE});
      }
   }
}

sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(), qw(InterfaceAgreement));
}







1;
