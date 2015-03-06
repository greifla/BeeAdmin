package tssmartcube::tcc;
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
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

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
                name          =>'fullname',
                label         =>'Fullname',
                uivisible     =>1,
                htmldetail    =>0,
                dataobjattr   =>"(SYSTEM_NAME||' ('||SYSTEM_ID||')')"),

      new kernel::Field::Text(
                name          =>'systemname',
                label         =>'Systemname',
                htmllabelwidth=>'250',
                ignorecase    =>1,
                dataobjattr   =>'SYSTEM_NAME'),

      new kernel::Field::Id(
                name          =>'systemid',
                label         =>'SystemID',
                group         =>'default',
                htmllabelwidth=>'250',
                searchable    =>1,
                uppersearch   =>1,
                dataobjattr   =>"SYSTEM_ID"),

      new kernel::Field::Text(
                name          =>'assetid',
                label         =>'AssetID',
                htmllabelwidth=>'250',
                ignorecase    =>1,
                dataobjattr   =>'ASSET_ID'),

      new kernel::Field::Text(
                name          =>'productline',
                label         =>'Productline',
                htmllabelwidth=>'150',
                ignorecase    =>1,
                dataobjattr   =>'PRODUCTLINE'),

      new kernel::Field::Number(
                name          =>'check_status',
                label         =>'TCC total state: CheckID',
                htmldetail    =>0,
                dataobjattr   =>'CHECK_STATUS'),

      new kernel::Field::Date(
                name          =>'tcc_report_date',
                searchable    =>0,
                htmllabelwidth=>'250',
                label         =>'Report-Date',
                dataobjattr   =>'REPORT_DATE'),

      new kernel::Field::Text(
                name          =>'check_status_color',
                htmllabelwidth=>'250',
                depend        =>['check_status_color'],
                background    =>\&getTCCbackground,
                label         =>'TCC total state',
                dataobjattr   =>getTCCColorSQL('CHECK_STATUS')),


      #######################################################################
      # Roadmap Compliance ##################################################

      new kernel::Field::Text(
                name          =>'roadmap',
                label         =>'Operationsystem',
                background    =>\&getTCCbackground,
                ignorecase    =>1,
                htmllabelwidth=>'250',
                group         =>['roadmap'],
                dataobjattr   =>'OS_NAME'),

      new kernel::Field::Text(
                name          =>'roadmap_check',
                label         =>'Roadmap Compliance: CheckID',
                htmllabelwidth=>'250',
                group         =>['roadmap'],
                htmldetail    =>0,
                dataobjattr   =>'CHECK_ROADMAP'),

      new kernel::Field::Text(
                name          =>'roadmap_state',
                label         =>'Roadmap Compliance: State',
                htmllabelwidth=>'250',
                group         =>['roadmap'],
                htmldetail    =>0,
                dataobjattr   =>getTCCStateSQL('CHECK_ROADMAP')),

      new kernel::Field::Text(
                name          =>'roadmap_color',
                label         =>'Roadmap Compliance: Color',
                htmllabelwidth=>'250',
                htmldetail    =>0,
                group         =>['roadmap'],
                dataobjattr   =>getTCCColorSQL('CHECK_ROADMAP')),

      #######################################################################
      # Release-/Patchmanagement Compliancy #################################

      new kernel::Field::Text(
                name          =>'os_base_setup',
                label         =>'OS Base-Setup',
                htmllabelwidth=>'250',
                group         =>['patch'],
                depend        =>['os_base_setup_color'],
                background    =>\&getTCCbackground,
                ignorecase    =>1,
                dataobjattr   =>'OS_BASE_SETUP'),

      new kernel::Field::Text(
                name          =>'os_base_setup_check',
                label         =>'OS Base-Setup: CheckID',
                group         =>['patch'],
                htmldetail    =>0,
                dataobjattr   =>'CHECK_OS'),

      new kernel::Field::Text(
                name          =>'os_base_setup_state',
                label         =>'OS Base-Setup: State',
                group         =>['patch'],
                htmldetail    =>0,
                dataobjattr   =>getTCCStateSQL('CHECK_OS')),

      new kernel::Field::Text(
                name          =>'os_base_setup_color',
                label         =>'OS Base-Setup: Color',
                group         =>['patch'],
                htmldetail    =>0,
                dataobjattr   =>getTCCColorSQL('CHECK_OS')),


      new kernel::Field::Text(
                name          =>'other_base_setups',
                label         =>'Other Base-Setups',
                ignorecase    =>1,
                htmllabelwidth=>'250',
                depend        =>['other_base_setups_color'],
                background    =>\&getTCCbackground,
                group         =>['patch'],
                dataobjattr   =>'OTHER_BASE_SETUPS'),

      new kernel::Field::Text(
                name          =>'other_base_setups_check',
                label         =>'Other Base-Setups: CheckID',
                group         =>['patch'],
                htmldetail    =>0,
                dataobjattr   =>'CHECK_OTHER'),

      new kernel::Field::Text(
                name          =>'other_base_setups_state',
                label         =>'Other Base-Setups: State',
                group         =>['patch'],
                htmldetail    =>0,
                dataobjattr   =>getTCCStateSQL('CHECK_OTHER')),

      new kernel::Field::Text(
                name          =>'other_base_setups_color',
                label         =>'Other Base-Setups: Color',
                group         =>['patch'],
                htmldetail    =>0,
                dataobjattr   =>getTCCColorSQL('CHECK_OTHER')),


      new kernel::Field::Text(
                name          =>'ha_base_setup',
                label         =>'Cluster Software',
                ignorecase    =>1,
                htmllabelwidth=>'250',
                group         =>['patch'],
                htmldetail    =>1,
                depend        =>['ha_base_setup_color'],
                background    =>\&getTCCbackground,
                dataobjattr   =>'HA_BASE_SETUP'),

      new kernel::Field::Text(
                name          =>'ha_base_setup_check',
                group         =>['patch'],
                htmldetail    =>0,
                label         =>'Cluster Software: CheckID',
                dataobjattr   =>'CHECK_HA'),

      new kernel::Field::Text(
                name          =>'ha_base_setup_state',
                group         =>['patch'],
                htmldetail    =>0,
                label         =>'Cluster Software: State',
                dataobjattr   =>getTCCStateSQL('CHECK_HA')),

      new kernel::Field::Text(
                name          =>'ha_base_setup_color',
                group         =>['patch'],
                htmldetail    =>0,
                label         =>'Cluster Software: Color',
                dataobjattr   =>getTCCColorSQL('CHECK_HA')),


      new kernel::Field::Text(
                name          =>'hw_base_setup',
                label         =>'Hardware Base-Setup',
                depend        =>['patch'],
                background    =>\&getTCCbackground,
                htmllabelwidth=>'250',
                ignorecase    =>1,
                group         =>['patch'],
                dataobjattr   =>'HW_BASE_SETUP'),

      new kernel::Field::Text(
                name          =>'hw_base_setup_check',
                label         =>'Hardware Base-Setup: CheckID',
                group         =>['patch'],
                htmldetail    =>0,
                dataobjattr   =>'CHECK_HW'),

      new kernel::Field::Text(
                name          =>'hw_base_setup_state',
                label         =>'Hardware Base-Setup: State',
                group         =>['patch'],
                htmldetail    =>0,
                dataobjattr   =>getTCCStateSQL('CHECK_HW')),

      new kernel::Field::Text(
                name          =>'hw_base_setup_color',
                label         =>'Hardware Base-Setup: Color',
                group         =>['patch'],
                htmldetail    =>0,
                dataobjattr   =>getTCCColorSQL('CHECK_HW')),

      new kernel::Field::Text(
                name          =>'sv_versions',
                label         =>'Software-Discovery Script Version',
                ignorecase    =>1,
                htmllabelwidth=>'250',
                group         =>['patch'],
                dataobjattr   =>'SV_VERSIONS'),

      new kernel::Field::Date(
                name          =>'tcc_version_info_date',
                label         =>'Software-Discovery: Importdate',
                group         =>['patch'],
                htmllabelwidth=>'250',
                ignorecase    =>1,
                dataobjattr   =>'VERSION_INFO_DATE'),

      new kernel::Field::Text(
                name          =>'check_release',
                label         =>'Release-/Patchmanagement Compliancy: CheckID',
                group         =>['patch'],
                htmllabelwidth=>'250',
                ignorecase    =>1,
                htmldetail    =>0,
                dataobjattr   =>'CHECK_RELEASE'),

      new kernel::Field::Text(
                name          =>'check_release_state',
                label         =>'Release-/Patchmanagement Compliancy: State',
                group         =>['patch'],
                htmldetail    =>0,
                dataobjattr   =>getTCCStateSQL('CHECK_RELEASE')),

      new kernel::Field::Text(
                name          =>'check_release_color',
                label         =>'Release-/Patchmanagement Compliancy',
                htmllabelwidth=>'250',
                background    =>\&getTCCbackground,
                group         =>['patch'],
                dataobjattr   =>getTCCColorSQL('CHECK_RELEASE')),



      #######################################################################
      # Storage Connectivity Compliancy #####################################

      new kernel::Field::Text(
                name          =>'multipath_access',
                label         =>'SAN Multipath Access',
                ignorecase    =>1,
                htmllabelwidth=>'250',
                group         =>['dsk'],
                depend        =>['multipath_access_color'],
                background    =>\&getTCCbackground,
                dataobjattr   =>'DISK_MULTIPATH_ACCESS'),

      new kernel::Field::Text(
                name          =>'multipath_access_check',
                label         =>'SAN Multipath Access: CheckID',
                htmldetail    =>0,
                group         =>['dsk'],
                dataobjattr   =>'CHECK_MULTIPATH'),

      new kernel::Field::Text(
                name          =>'multipath_access_color',
                label         =>'SAN Multipath Access: Color',
                group         =>['dsk'],
                htmldetail    =>0,
                dataobjattr   =>getTCCColorSQL('CHECK_MULTIPATH')),

      new kernel::Field::Text(
                name          =>'disk',
                label         =>'SAN Disk Settings',
                group         =>'dsk',
                depend        =>['disk_color'],
                background    =>\&getTCCbackground,
                htmllabelwidth=>'250',
                ignorecase    =>1,
                dataobjattr   =>'DISK_SETTINGS'),

      new kernel::Field::Text(
                name          =>'disk_check',
                label         =>'SAN Disk Settings: CheckID',
                group         =>'dsk',
                htmldetail    =>0,
                dataobjattr   =>'CHECK_DISK'),

      new kernel::Field::Text(
                name          =>'disk_state',
                label         =>'SAN Disk Settings: State',
                group         =>['dsk'],
                htmldetail    =>0,
                dataobjattr   =>getTCCStateSQL('CHECK_DISK')),

      new kernel::Field::Text(
                name          =>'disk_color',
                label         =>'SAN Disk Settings: Color',
                group         =>['dsk'],
                htmldetail    =>0,
                dataobjattr   =>getTCCColorSQL('CHECK_DISK')),


      new kernel::Field::Text(
                name          =>'fc_settings',
                label         =>'Fibrechannel Settings',
                depend        =>['fc_settings_color'],
                htmllabelwidth=>'250',
                background    =>\&getTCCbackground,
                group         =>'dsk',
                ignorecase    =>1,
                dataobjattr   =>'FC_SETTINGS'),

      new kernel::Field::Text(
                name          =>'fc_settings_check',
                group         =>'dsk',
                label         =>'Fibrechannel Settings: CheckID',
                htmldetail    =>0,
                dataobjattr   =>'CHECK_FC'),

      new kernel::Field::Text(
                name          =>'fc_settings_state',
                label         =>'SAN Filesets: State',
                group         =>['dsk'],
                htmldetail    =>0,
                dataobjattr   =>getTCCStateSQL('CHECK_FC')),

      new kernel::Field::Text(
                name          =>'fc_settings_color',
                label         =>'SAN Filesets: Color',
                group         =>['dsk'],
                htmldetail    =>0,
                dataobjattr   =>getTCCColorSQL('CHECK_FC')),

      new kernel::Field::Text(
                name          =>'filesets',
                label         =>'SAN Filesets',
                group         =>['dsk'],
                htmllabelwidth=>'250',
                depend        =>['filesets_color'],
                background    =>\&getTCCbackground,
                ignorecase    =>1,
                dataobjattr   =>'FILESETS_AVAILABLE'),

      new kernel::Field::Text(
                name          =>'filesets_check',
                label         =>'SAN Filesets: CheckID',
                group         =>['dsk'],
                htmldetail    =>0,
                ignorecase    =>1,
                dataobjattr   =>'CHECK_FILESETS'),


      new kernel::Field::Text(
                name          =>'filesets_state',
                label         =>'SAN Filesets: State',
                group         =>['dsk'],
                htmldetail    =>0,
                dataobjattr   =>getTCCStateSQL('CHECK_FILESETS')),

      new kernel::Field::Text(
                name          =>'filesets_color',
                label         =>'SAN Filesets: Color',
                group         =>['dsk'],
                htmldetail    =>0,
                dataobjattr   =>getTCCColorSQL('CHECK_FILESETS')),


      new kernel::Field::Text(
                name          =>'vscsi',
                label         =>'VSCSI Settings',
                ignorecase    =>1,
                htmllabelwidth=>'250',
                depend        =>['vscsi_color'],
                background    =>\&getTCCbackground,
                group         =>'dsk',
                dataobjattr   =>'VSCSI_DISK_SETTINGS'),

      new kernel::Field::Text(
                name          =>'vscsi_check',
                label         =>'VSCSI Settings: CheckID',
                htmldetail    =>0,
                group         =>'dsk',
                dataobjattr   =>'CHECK_VSCSI'),

      new kernel::Field::Text(
                name          =>'vscsi_state',
                label         =>'VSCSI Settings: State',
                group         =>['dsk'],
                htmldetail    =>0,
                dataobjattr   =>getTCCStateSQL('CHECK_VSCSI')),

      new kernel::Field::Text(
                name          =>'vscsi_color',
                label         =>'VSCSI Settings: Color',
                group         =>['dsk'],
                htmldetail    =>0,
                dataobjattr   =>getTCCColorSQL('CHECK_VSCSI')),


      new kernel::Field::Text(
                name          =>'iscsi',
                label         =>'ISCSI Settings',
                ignorecase    =>1,
                htmllabelwidth=>'250',
                depend        =>['iscsi_color'],
                background    =>\&getTCCbackground,
                group         =>'dsk',
                dataobjattr   =>'ISCSI_DISK_SETTINGS'),

      new kernel::Field::Text(
                name          =>'iscsi_check',
                label         =>'ISCSI Settings: CheckID',
                htmldetail    =>0,
                group         =>'dsk',
                dataobjattr   =>'CHECK_ISCSI'),

      new kernel::Field::Text(
                name          =>'iscsi_state',
                label         =>'VSCSI Settings: State',
                group         =>['dsk'],
                htmldetail    =>0,
                dataobjattr   =>getTCCStateSQL('CHECK_VSCSI')),

      new kernel::Field::Text(
                name          =>'iscsi_color',
                label         =>'VSCSI Settings: Color',
                group         =>['dsk'],
                htmldetail    =>0,
                dataobjattr   =>getTCCColorSQL('CHECK_VSCSI')),

      new kernel::Field::Text(
                name          =>'storage',
                label         =>'Storage-Discovery Script-Version',
                ignorecase    =>1,
                htmldetail    =>0,
                htmllabelwidth=>'250',
                group         =>'dsk',
                dataobjattr   =>'SV_STORAGE'),

      new kernel::Field::Date(
                name          =>'tcc_storage_date',
                label         =>'Storage-Discovery Importdate',
                group         =>['dsk'],
                htmldetail    =>0,
                htmllabelwidth=>'250',
                dataobjattr   =>'STORAGE_DATE'),

      new kernel::Field::Text(
                name          =>'storage_check',
                label         =>'Storage Connectivity Compliancy: CheckID',
                group         =>'dsk',
                htmldetail    =>0,
                dataobjattr   =>'CHECK_STORAGE'),

      new kernel::Field::Text(
                name          =>'iscsi_state',
                label         =>'Storage Connectivity Compliancy: State',
                group         =>['dsk'],
                htmldetail    =>0,
                dataobjattr   =>getTCCStateSQL('CHECK_STORAGE')),

      new kernel::Field::Text(
                name          =>'storage_color',
                label         =>'Storage Connectivity Compliancy',
                group         =>['dsk'],
                htmllabelwidth=>'250',
                background    =>\&getTCCbackground,
                dataobjattr   =>getTCCColorSQL('CHECK_STORAGE')),



      #######################################################################

      #######################################################################
      new kernel::Field::Text(
                name          =>'srcsys',
                label         =>'AutoDiscovery Sourcesystem',
                searchable    =>0,
                htmllabelwidth=>'250',
                group         =>'source',
                dataobjattr   =>'AD_SOURCE'),

   );
   $self->setWorktable("tcc_report");
   $self->setDefaultView(qw(systemid systemname));
   return($self);
}

#SYSTEM_ID               = SystemID des logischen Systems (aus AssetManager)

#OS_ROADMAP              = aktuelle Betriebssystemversion
#CHECK_ROADMAP           = Farbcodierung f�r das Feld OS_ROADMAP

#OS_BASE_SETUP           = OS Base Setup (aus Versionsscript)
#CHECK_OS                = Farbcodierung
#HA_BASE_SETUP           = HA Base Setup (aus Versionsscript)
#OTHER_BASE_SETUPS       = Other Base Setup (aus Versionsscript)
#CHECK_OTHER             = Farbcodierung
#MONITOR                 = Monitoring Status
#PRODUCTLINE             = Production Line (Appcom, STS, Classic); aus der OLA Klasse im AssetManager ermittelt
#CHECK_FILESETS          = Farbcodierung
#DISK_MULTIPATH_ACCESS   = SAN Disc Multipath Access (aus Storagescript)
#CHECK_MULTIPATH         = Farbcodierung
#CHECK_DISK              = Farbcodierung
#FC_SETTINGS             = SAN FC Settings (aus Storagescript)
#CHECK_FC                = Farbcodierung
#VERSION_INFO_DATE       = Zeitpunkt an dem die Versionsdaten in die Datenbank geladen wurden
#DESCRIPTION             = Kommentar, den TCC Server Administratoren eingeben k�nnen; Kommt nicht aus Asset Manager
#TMR                     = Source von den Autodiscoverydaten
#STORAGE_DATE            = Zeitpunkt an dem die Storage Daten in die Datenbank geladen wurden
#VSCSI_DISK_SETTINGS     = vSCSI Settings (aus Storagescript)
#CHECK_VSCSI             = Farbcodierung
#ISCSI_DISK_SETTINGS     = iSCSI Settings (aus Storagescript)
#CHECK_ISCSI             = Farbcodierung
#SV_VERSIONS             = Version des Scripts, das die Versionsdaten liefert
#SV_STORAGE              = Version des Scripts, das die Storage Daten liefert
#CHECK_VERSIONS          = Farbcodierung
#CHECK_STORAGE           = Farbcodierung
#LAST_UPDATE             = Letzter Ausf�hrungszeitpunkt des Scripts, das die Versionsdaten liefert
#LAST_UPDATE_ST          = Letzter Ausf�hrungszeitpunkt des Scripts, das die Storage Daten liefert


sub getTCCStateSQL
{
   my $fld=shift;

   # 
   #  based on Mail from Wiebe, Helene <Helene.Wiebe@t-systems.com>
   #  from 04.12.2014
   # 

   my $d="decode($fld,0,'ok',".
                     "1,'warning',".
                     "2,'critical',".
                     "3,'undefined',".
                     "4,'never touch',".
                     "5,'pending customer',NULL)";
   return($d);
}

sub getTCCColorSQL
{
   my $fld=shift;

   # 
   #  based on Mail from Wiebe, Helene <Helene.Wiebe@t-systems.com>
   #  from 04.12.2014
   # 

   my $d="decode($fld,0,'green',".
                     "1,'yellow',".
                     "2,'red',".
                     "3,NULL,".
                     "4,'blue',".
                     "5,'blue',NULL)";
   return($d);
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}



sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default roadmap patch dsk ha  hw mon other source));
}




sub getTCCbackground{
   my ($self,$FormatAs,$current)=@_;

   my $name=$self->Name();

   my $colorfield=$name;

   if (!($self->Name()=~m/_color$/)){
      $colorfield.="_color";
   }

   my $f=$self->getParent->getField($colorfield);

   my $col;

   if (defined($f)){
      $col=$f->RawValue($current);
   }

   return($col);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5warehouse"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


#sub initSearchQuery
#{
#   my $self=shift;
#   if (!defined(Query->Param("search_saphier"))){
#     Query->Param("search_saphier"=>
#                  "\"9TS_ES.9DTIT\" \"9TS_ES.9DTIT.*\"");
#   }
#}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/tssmartcube/load/bgtccicon.jpg?".$cgi->query_string());
}




1;
