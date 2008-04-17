package itil::ipaddress;
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
use Data::Dumper;
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
use kernel::CIStatusTools;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::CIStatusTools);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'ipaddress.id'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'IP-Address',
                dataobjattr   =>'ipaddress.name'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::TextDrop(
                name          =>'system',
                htmlwidth     =>'100px',
                label         =>'assigned to System',
                vjointo       =>'itil::system',
                vjoinon       =>['systemid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Select(
                name          =>'network',
                htmleditwidth =>'190px',
                label         =>'Network',
                vjointo       =>'itil::network',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['networkid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'networkid',
                label         =>'NetworkID',
                dataobjattr   =>'ipaddress.network'),

      new kernel::Field::Link(
                name          =>'systemid',
                label         =>'SystemID',
                dataobjattr   =>'ipaddress.system'),
                                                  
      new kernel::Field::Link(
                name          =>'uniqueflag',
                label         =>'UniqueFlag',
                dataobjattr   =>'ipaddress.uniqueflag'),
                                                  
      new kernel::Field::Text(
                name          =>'dnsname',
                label         =>'DNS-Name',
                dataobjattr   =>'ipaddress.dnsname'),

      new kernel::Field::Select(
                name          =>'type',
                htmleditwidth =>'190px',
                label         =>'Typ',
                transprefix   =>'iptyp.',
                value         =>[qw(0 1 2 3 4 5 8 9 6 7)],
                dataobjattr   =>'ipaddress.addresstyp'),

      new kernel::Field::Text(
                name          =>'ifname',
                htmlwidth     =>'130px',
                label         =>'Interface name',
                dataobjattr   =>'ipaddress.ifname'),

      new kernel::Field::Text(
                name          =>'accountno',
                htmlwidth     =>'130px',
                label         =>'Account Number',
                dataobjattr   =>'ipaddress.accountno'),

      new kernel::Field::Link(
                name          =>'addresstyp',
                htmlwidth     =>'5px',
                dataobjattr   =>'ipaddress.addresstyp'),

      new kernel::Field::DynWebIcon(
                name          =>'webaddresstyp',
                searchable    =>0,
                depend        =>['type'],
                htmlwidth     =>'5px',
                htmldetail    =>0,
                weblink       =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $mode=shift;
                   my $typeo=$self->getParent->getField("type");
                   my $d=$typeo->FormatedDetail($current,"AscV01");
                   my $e=$self->RawValue($current);
                   my $name=$self->Name();
                   my $app=$self->getParent();
                   if ($mode=~m/html/i){
                      return("<img ".
                         "src=\"../../itil/load/iptyp${e}.gif\" title=\"$d\">");
                   }
                   return($d);
                },
                dataobjattr   =>'ipaddress.addresstyp'),

      new kernel::Field::Select(
                name          =>'iscontrolpartner',
                transprefix   =>'boolean.',
                htmleditwidth =>'30%',
                label         =>'ControlCenter Partner',
                value         =>[0,1],
                dataobjattr   =>'ipaddress.is_controllpartner'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'ipaddress.cistatus'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'ipaddress.comments'),

      new kernel::Field::Text(
                name          =>'shortcomments',
                label         =>'Short Comments',
                readonly      =>1,
                htmldetail    =>0,
                htmlwidth     =>'50px',
                onRawValue    =>sub{
                                   my $self=shift;
                                   my $current=shift;
                                   my $d=$current->{comments};
                                   $d=~s/\n/ /g;
                                   $d=substr($d,0,20);
                                   if (length($current->{comments})>
                                       length($d)){
                                      $d.="...";
                                   }
                                   return($d);
                                },
                depend        =>['comments']),

      new kernel::Field::Container(
                name          =>'additional',
                label         =>'Additionalinformations',
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
                dataobjattr   =>'ipaddress.additional'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'ipaddress.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'ipaddress.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'ipaddress.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'ipaddress.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'ipaddress.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'ipaddress.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'ipaddress.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'ipaddress.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'ipaddress.realeditor'),
   

   );
   $self->setDefaultView(qw(name system dnsname cistatus mdate));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5base"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   $self->setWorktable("ipaddress");
   return(1);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $cistatusid=trim(effVal($oldrec,$newrec,"cistatusid"));
   if (!defined($cistatusid) || $cistatusid==0){
      $newrec->{cistatusid}=4;
   }

   my $name=trim(effVal($oldrec,$newrec,"name"));
   $name=~s/\s//g;
   if ($cistatusid<=5){
      $name=~s/\[\d*\]$//;
   }
   if ($name=~m/^\s*$/){
      $self->LastMsg(ERROR,"invalid ip-address or empty specified");
      return(0);
   }
   else{
      $name=~s/\s//g;
      $name=~s/^[0]+([1-9])/$1/g;
      $name=~s/\.[0]+([1-9])/.$1/g;
      if (my ($o1,$o2,$o3,$o4)=$name=~m/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/){
         if (($o1<0 || $o1 >255 || 
              $o2<0 || $o2 >255 ||
              $o3<0 || $o3 >255 ||
              $o4<0 || $o4 >255)||
             ($o1==0 && $o2==0 && $o3==0 && $o4==0) ||
             ($o1==255 && $o2==255 && $o3==255 && $o4==255)){
            $self->LastMsg(ERROR,
                   sprintf($self->T("invalid IPV4 address '\%s'"),$name));
            return(0);
         }
      }
      else{
         $self->LastMsg(ERROR,"unknown ip-address format");
         return(0);
      }
   }
   $newrec->{name}=$name;
   my $dnsname=lc(trim(effVal($oldrec,$newrec,"dnsname")));
   $dnsname=~s/[^a-z0-9]*$//;
   $dnsname=~s/^[^a-z0-9]*//;
   $newrec->{dnsname}=$dnsname;

   my $accountno=trim(effVal($oldrec,$newrec,"accountno"));
   if ($accountno=~m/\s/){
      $self->LastMsg(ERROR,"invalid account number specified");
      return(0);
   }

   msg(INFO,sprintf("iprec=%s\n",Dumper($newrec)));

   my $systemid=effVal($oldrec,$newrec,"systemid");
   if ($systemid<=0){
      $self->LastMsg(ERROR,"invalid system specified");
      return(0);
   } 
   if (!defined($oldrec) && !exists($newrec->{type}) &&
                            !exists($newrec->{addresstyp})){
      $newrec->{addresstyp}=1;
   }
   return(0) if (!($self->isParentWriteable($systemid)));
   #return(1) if ($self->IsMemberOf("admin"));
   return(0) if (!$self->HandleCIStatusModification($oldrec,$newrec,"name"));

   return(1);
}

sub isParentWriteable
{
   my $self=shift;
   my $systemid=shift;

   my $p=$self->getPersistentModuleObject($self->Config,"itil::system");
   my $idname=$p->IdField->Name();
   my %flt=($idname=>\$systemid);
   $p->SetFilter(\%flt);
   my @l=$p->getHashList(qw(ALL));
   if ($#l!=0){
      $self->LastMsg(ERROR,"invalid system reference");
      return(0);
   }
   my @write=$p->isWriteValid($l[0]);
   if (isDataInputFromUserFrontend()){
      if (!grep(/^ALL$/,@write) && !grep(/^ipaddresses$/,@write)){
         $self->LastMsg(ERROR,"no access");
         return(0);
      }
   }
   return(1);
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

   if (defined($rec)){
      return("default") if ($self->IsMemberOf("admin"));
      return(undef) if (!$self->isParentWriteable($rec->{systemid}));
   }

   return("default");
}

sub getRecordHtmlIndex
{ return(); }




1;
