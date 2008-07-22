package itil::lnkapplsystem;
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
   $param{MainSearchFieldLines}=5;
   my $self=bless($type->SUPER::new(%param),$type);

   

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'LinkID',
                searchable    =>0,
                dataobjattr   =>'lnkapplsystem.id'),
                                                 
      new kernel::Field::TextDrop(
                name          =>'appl',
                htmlwidth     =>'250px',
                label         =>'Application',
                vjointo       =>'itil::appl',
                vjoinon       =>['applid'=>'id'],
                vjoindisp     =>'name',
                dataobjattr   =>'appl.name'),
                                                   
      new kernel::Field::TextDrop(
                name          =>'system',
                htmlwidth     =>'100px',
                label         =>'System',
                vjointo       =>'itil::system',
                vjoinon       =>['systemid'=>'id'],
                vjoindisp     =>'name',
                dataobjattr   =>'system.name'),
                                                   
      new kernel::Field::Select(
                name          =>'systemcistatus',
                readonly      =>1,
                group         =>'systeminfo',
                label         =>'System CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['systemcistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Text(
                name          =>'systemsystemid',
                label         =>'SystemID',
                readonly      =>1,
                group         =>'systeminfo',
                dataobjattr   =>'system.systemid'),

      new kernel::Field::Text(
                name          =>'shortdesc',
                label         =>'Short Description',
                readonly      =>1,
                group         =>'systeminfo',
                dataobjattr   =>'system.shortdesc'),

      new kernel::Field::Select(
                name          =>'osrelease',
                group         =>'systeminfo',
                readonly      =>1,
                translation   =>'itil::system',
                htmleditwidth =>'40%',
                readonly      =>1,
                label         =>'OS-Release',
                vjointo       =>'itil::osrelease',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['osreleaseid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'osreleaseid',
                label         =>'OSReleaseID',
                dataobjattr   =>'system.osrelease'),

      new kernel::Field::Boolean(
                name          =>'isprod',
                readonly      =>1,
                group         =>'systeminfo',
                htmleditwidth =>'30%',
                label         =>'Productionsystem',
                dataobjattr   =>'system.is_prod'),

      new kernel::Field::Boolean(
                name          =>'istest',
                readonly      =>1,
                group         =>'systeminfo',
                htmleditwidth =>'30%',
                label         =>'Testsystem',
                dataobjattr   =>'system.is_test'),

      new kernel::Field::Percent(
                name          =>'fraction',
                label         =>'Fraction',
                htmlwidth     =>'60px',
                dataobjattr   =>'lnkapplsystem.fraction'),

      new kernel::Field::Textarea(
                name          =>'comments',
                searchable    =>0,
                label         =>'Comments',
                dataobjattr   =>'lnkapplsystem.comments'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnkapplsystem.createuser'),
                                   
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'lnkapplsystem.modifyuser'),
                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnkapplsystem.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnkapplsystem.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'lnkapplsystem.srcload'),
                                                   
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkapplsystem.createdate'),
                                                
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkapplsystem.modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'lnkapplsystem.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'lnkapplsystem.realeditor'),

      new kernel::Field::Mandator(
                group         =>'applinfo',
                readonly      =>1),

      new kernel::Field::Link(
                name          =>'mandatorid',
                label         =>'ApplMandatorID',
                group         =>'applinfo',
                dataobjattr   =>'appl.mandator'),

      new kernel::Field::Select(
                name          =>'applcistatus',
                readonly      =>1,
                group         =>'applinfo',
                label         =>'Application CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['applcistatusid'=>'id'],
                vjoindisp     =>'name'),
                                                  
      new kernel::Field::Text(
                name          =>'applapplid',
                label         =>'ApplicationID',
                readonly      =>1,
                group         =>'applinfo',
                dataobjattr   =>'appl.applid'),

      new kernel::Field::Link(
                name          =>'tsmid',
                label         =>'TSM ID',
                readonly      =>1,
                dataobjattr   =>'appl.tsm'),

      new kernel::Field::TextDrop(
                name          =>'tsm',
                group         =>'applinfo',
                label         =>'Technical Solution Manager',
                htmlwidth     =>'280px',
                readonly      =>1,
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['tsmid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'businessteamid',
                label         =>'Businessteam ID',
                readonly      =>1,
                dataobjattr   =>'appl.businessteam'),

      new kernel::Field::TextDrop(
                name          =>'businessteam',
                htmlwidth     =>'300px',
                readonly      =>1,
                htmlwidth     =>'280px',
                group         =>'applinfo',
                label         =>'Business Team',
                vjointo       =>'base::grp',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['businessteamid'=>'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Text(
                name          =>'applcustomerprio',
                label         =>'Customers Application Prioritiy',
                translation   =>'itil::appl',
                readonly      =>1,
                group         =>'applinfo',
                dataobjattr   =>'appl.customerprio'),

      new kernel::Field::Text(
                name          =>'oncallphones',
                searchable    =>0,
                readonly      =>1,
                label         =>'oncall Phonenumbers',
                htmlwidth     =>'150px',
                group         =>'applinfo',
                translation   =>'itil::appl',
                weblinkto     =>'none',
                vjoinbase     =>[{'parentobj'=>\'itil::appl'}],
                vjointo       =>'base::phonenumber',
                vjoinon       =>['applid'=>'refid'], 
                vjoinbase     =>{'rawname'=>'phoneRB'},
                vjoindisp     =>'phonenumber'),


      new kernel::Field::Link(
                name          =>'applcistatusid',
                label         =>'ApplCiStatusID',
                dataobjattr   =>'appl.cistatus'),

      new kernel::Field::Link(
                name          =>'assetid',
                label         =>'AssetID',
                dataobjattr   =>'system.asset'),

      new kernel::Field::Link(
                name          =>'customerid',
                label         =>'CustomerID',
                dataobjattr   =>'appl.customer'),

      new kernel::Field::Boolean(
                name          =>'isdevel',
                readonly      =>1,
                group         =>'systeminfo',
                htmleditwidth =>'30%',
                label         =>'Developmentsystem',
                dataobjattr   =>'system.is_devel'),

      new kernel::Field::Boolean(
                name          =>'iseducation',
                readonly      =>1,
                group         =>'systeminfo',
                htmleditwidth =>'30%',
                label         =>'Educationsystem',
                dataobjattr   =>'system.is_education'),

      new kernel::Field::Boolean(
                name          =>'isapprovtest',
                readonly      =>1,
                group         =>'systeminfo',
                htmleditwidth =>'30%',
                label         =>'Approval Testsystem',
                dataobjattr   =>'system.is_approvtest'),

      new kernel::Field::Boolean(
                name          =>'isreference',
                readonly      =>1,
                group         =>'systeminfo',
                htmleditwidth =>'30%',
                label         =>'Referencesystem',
                dataobjattr   =>'system.is_reference'),

      new kernel::Field::Boolean(
                name          =>'isapplserver',
                readonly      =>1,
                group         =>'systeminfo',
                htmleditwidth =>'30%',
                label         =>'Applicationserver',
                dataobjattr   =>'system.is_applserver'),

      new kernel::Field::Boolean(
                name          =>'isbackupsrv',
                readonly      =>1,
                group         =>'systeminfo',
                htmleditwidth =>'30%',
                label         =>'Backupserver',
                dataobjattr   =>'system.is_backupsrv'),

      new kernel::Field::Boolean(
                name          =>'isdatabasesrv',
                readonly      =>1,
                group         =>'systeminfo',
                htmleditwidth =>'30%',
                label         =>'Databaseserver',
                dataobjattr   =>'system.is_databasesrv'),

      new kernel::Field::Boolean(
                name          =>'iswebserver',
                readonly      =>1,
                group         =>'systeminfo',
                htmleditwidth =>'30%',
                label         =>'WEB-Server',
                dataobjattr   =>'system.is_webserver'),

                                                   
      new kernel::Field::Interface(
                name          =>'systemcistatusid',
                label         =>'SystemCiStatusID',
                dataobjattr   =>'system.cistatus'),
                                                   
      new kernel::Field::Link(
                name          =>'assetid',
                label         =>'AssetId',
                dataobjattr   =>'system.asset'),
                                                   
      new kernel::Field::Text(
                name          =>'applid',
                htmldetail    =>0,
                label         =>'W5Base Application ID',
                dataobjattr   =>'lnkapplsystem.appl'),
                                                   
      new kernel::Field::Text(
                name          =>'systemid',
                htmldetail    =>0,
                label         =>'W5Base System ID',
                dataobjattr   =>'lnkapplsystem.system'),

      new kernel::Field::Link(
                name          =>'mandatorid',
                label         =>'MandatorID',
                dataobjattr   =>'appl.mandator'),

      new kernel::Field::DynWebIcon(
                name          =>'applweblink',
                searchable    =>0,
                depend        =>['applid'],
                htmlwidth     =>'5px',
                htmldetail    =>0,
                weblink       =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $mode=shift;
                   my $app=$self->getParent;

                   my $applido=$self->getParent->getField("applid");
                   my $applid=$applido->RawValue($current);

                   my $img="<img ";
                   $img.="src=\"../../base/load/directlink.gif\" ";
                   $img.="title=\"\" border=0>";
                   my $dest="../../itil/appl/Detail?id=$applid";
                   my $detailx=$app->DetailX();
                   my $detaily=$app->DetailY();
                   my $onclick="openwin(\"$dest\",\"_blank\",".
                       "\"height=$detaily,width=$detailx,toolbar=no,status=no,".
                       "resizable=yes,scrollbars=no\")";

                   if ($mode=~m/html/i){
                      return("<a href=javascript:$onclick>$img</a>");
                   }
                   return("-only a web useable link-");
                }),

      new kernel::Field::DynWebIcon(
                name          =>'systemweblink',
                searchable    =>0,
                depend        =>['systemid'],
                htmlwidth     =>'5px',
                htmldetail    =>0,
                weblink       =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $mode=shift;
                   my $app=$self->getParent;

                   my $systemido=$self->getParent->getField("systemid");
                   my $systemid=$systemido->RawValue($current);

                   my $img="<img ";
                   $img.="src=\"../../base/load/directlink.gif\" ";
                   $img.="title=\"\" border=0>";
                   my $dest="../../itil/system/Detail?id=$systemid";
                   my $detailx=$app->DetailX();
                   my $detaily=$app->DetailY();
                   my $onclick="openwin(\"$dest\",\"_blank\",".
                       "\"height=$detaily,width=$detailx,toolbar=no,status=no,".
                       "resizable=yes,scrollbars=no\")";

                   if ($mode=~m/html/i){
                      return("<a href=javascript:$onclick>$img</a>");
                   }
                   return("-only a web useable link-");
                }),

   );
   $self->setDefaultView(qw(appl system systemsystemid fraction cdate));
   $self->setWorktable("lnkapplsystem");
   return($self);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/lnkapplsystem.jpg?".$cgi->query_string());
}
         

sub getSqlFrom
{
   my $self=shift;
   my $from="lnkapplsystem left outer join appl ".
            "on lnkapplsystem.appl=appl.id ".
            "left outer join system ".
            "on lnkapplsystem.system=system.id";
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
#      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
#                                  ["REmployee","RMember"],"both");
#      my @grpids=keys(%grps);
#      my $userid=$self->getCurrentUserId();
      push(@flt,[
                 {mandatorid=>\@mandators},
#                 {databossid=>$userid},
#                 {semid=>$userid},       {sem2id=>$userid},
#                 {tsmid=>$userid},       {tsm2id=>$userid},
#                 {businessteamid=>\@grpids},
#                 {responseteamid=>\@grpids},
#                 {sectargetid=>\$userid,sectarget=>\'base::user',
#                  secroles=>"*roles=?write?=roles* *roles=?read?=roles*"},
#                 {sectargetid=>\@grpids,sectarget=>\'base::grp',
#                  secroles=>"*roles=?write?=roles* *roles=?read?=roles*"}
                ]);
   }
   return($self->SetFilter(@flt));
}






sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   if ((!defined($oldrec) && !defined($newrec->{applid})) ||
       (defined($newrec->{applid}) && $newrec->{applid}==0)){
      $self->LastMsg(ERROR,"invalid application specified");
      return(undef);
   }
   if ((!defined($oldrec) && !defined($newrec->{systemid})) ||
       (defined($newrec->{systemid}) && $newrec->{systemid}==0)){
      $self->LastMsg(ERROR,"invalid contract specified");
      return(undef);
   }
   my $applid=effVal($oldrec,$newrec,"applid");

   if ($self->isDataInputFromUserFrontend()){
      if (!$self->isWriteOnApplValid($applid,"systems")){
         $self->LastMsg(ERROR,"no access");
         return(undef);
      }
   }
   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
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
   my $applid=effVal($oldrec,$newrec,"applid");

   return("default") if (!defined($oldrec) && !defined($newrec));
   return("default") if ($self->IsMemberOf("admin"));
   return("default") if ($self->isWriteOnApplValid($applid,"systems"));
   return("default") if (!$self->isDataInputFromUserFrontend() &&
                         !defined($oldrec));

   return(undef);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),
          qw(default misc applinfo systeminfo ));
}







1;
