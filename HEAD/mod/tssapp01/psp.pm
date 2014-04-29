package tssapp01::psp;
#  W5Base Framework
#  Copyright (C) 2013  Hartmut Vogler (it@guru.de)
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
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'interface_tssapp01_01.id'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                nowrap        =>1,
                label         =>'PSP Name',
                dataobjattr   =>'interface_tssapp01_01.name'),

      new kernel::Field::Text(
                name          =>'accarea',
                label         =>'Accounting Area',
                dataobjattr   =>'interface_tssapp01_01.accarea'),

      new kernel::Field::Text(
                name          =>'status',
                label         =>'Status',
                dataobjattr   =>'interface_tssapp01_01.status'),

      new kernel::Field::Text(
                name          =>'description',
                label         =>'Description',
                dataobjattr   =>'interface_tssapp01_01.description'),

      new kernel::Field::Link(
                name          =>'etype',
                label         =>'Type',
                dataobjattr   =>'interface_tssapp01_01.etype'),

      new kernel::Field::Text(
                name          =>'bpmark',
                label         =>'Bussinessprocess mark',
                weblinkto     =>'tssapp01::gpk',
                weblinkon     =>['bpmark'=>'name'],
                dataobjattr   =>'interface_tssapp01_01.bpmark'),

      new kernel::Field::Text(
                name          =>'ictono',
                label         =>'ICTO-ID',
                dataobjattr   =>'interface_tssapp01_01.ictono'),

      new kernel::Field::TextDrop(
                name          =>'databoss',
                group         =>'contacts',
                label         =>'Databoss EMail',
                vjointo       =>'tswiw::user',
                vjoinon       =>['databosswiw'=>'uid'],
                vjoindisp     =>'email'),

      new kernel::Field::Text(
                name          =>'databosswiw',
                group         =>'contacts',
                label         =>'Databoss WIW ID',
                dataobjattr   =>'interface_tssapp01_01.databosswiw'),

      new kernel::Field::TextDrop(
                name          =>'sm',
                group         =>'contacts',
                vjointo       =>'tswiw::user',
                label         =>'Service Manager EMail',
                vjoinon       =>['smwiw'=>'uid'],
                vjoindisp     =>'email'),

      new kernel::Field::Text(
                name          =>'smwiw',
                group         =>'contacts',
                label         =>'Service Manager WIW ID',
                dataobjattr   =>'interface_tssapp01_01.smwiw'),

      new kernel::Field::TextDrop(
                name          =>'dm',
                group         =>'contacts',
                label         =>'Delivery Manager EMail',
                vjointo       =>'tswiw::user',
                vjoinon       =>['dmwiw'=>'uid'],
                vjoindisp     =>'email'),

      new kernel::Field::Text(
                name          =>'dmwiw',
                group         =>'contacts',
                label         =>'Delivery Manager WIW ID',
                dataobjattr   =>'interface_tssapp01_01.dmwiw'),

      new kernel::Field::Text(
                name          =>'saphier',
                label         =>'SAP hierarchy',
                group         =>'saphier',
                ignorecase    =>1,
                dataobjattr   =>tssapp01::psp::getSAPhierSQL()),

      new kernel::Field::Text(
                name          =>'saphier1',
                label         =>'SAP hierarchy 1',
                group         =>'saphier',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'interface_tssapp01_01.saphier1'),

      new kernel::Field::Text(
                name          =>'saphier2',
                label         =>'SAP hierarchy 2',
                group         =>'saphier',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'interface_tssapp01_01.saphier2'),

      new kernel::Field::Text(
                name          =>'saphier3',
                label         =>'SAP hierarchy 3',
                group         =>'saphier',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'interface_tssapp01_01.saphier3'),

      new kernel::Field::Text(
                name          =>'saphier1',
                label         =>'SAP hierarchy 4',
                group         =>'saphier',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'interface_tssapp01_01.saphier4'),

      new kernel::Field::Text(
                name          =>'saphier5',
                label         =>'SAP hierarchy 5',
                group         =>'saphier',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'interface_tssapp01_01.saphier5'),

      new kernel::Field::Text(
                name          =>'saphier6',
                label         =>'SAP hierarchy 6',
                group         =>'saphier',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'interface_tssapp01_01.saphier6'),

      new kernel::Field::Text(
                name          =>'saphier7',
                label         =>'SAP hierarchy 7',
                group         =>'saphier',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'interface_tssapp01_01.saphier7'),

      new kernel::Field::Text(
                name          =>'saphier8',
                label         =>'SAP hierarchy 8',
                group         =>'saphier',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'interface_tssapp01_01.saphier8'),

      new kernel::Field::Text(
                name          =>'saphier9',
                label         =>'SAP hierarchy 9',
                group         =>'saphier',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'interface_tssapp01_01.saphier9'),

      new kernel::Field::Text(
                name          =>'saphier10',
                label         =>'SAP hierarchy 10',
                group         =>'saphier',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'interface_tssapp01_01.saphier10'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'interface_tssapp01_01.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'interface_tssapp01_01.modifydate'),

      new kernel::Field::Boolean(
                name          =>'isdeleted',
                uivisible     =>0,
                label         =>'is deleted',
                dataobjattr   =>'interface_tssapp01_01.isdeleted'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'interface_tssapp01_01.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'interface_tssapp01_01.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'interface_tssapp01_01.srcload'),

   );
   $self->setDefaultView(qw(name description cdate mdate));
   $self->setWorktable("interface_tssapp01_01");
   $self->{history}=[qw(insert modify delete)];
   return($self);
}

sub getSAPhierSQL
{
   my $tab=shift;
   $tab="interface_tssapp01_01" if ($tab eq "");
   my $saphierfield;
   for(my $c=1;$c<=10;$c++){
      $saphierfield.=",'.'," if ($saphierfield ne "");
      $saphierfield.="if (${tab}.saphier${c} is null OR ${tab}.saphier${c}='','-',${tab}.saphier${c})";
   }
   $saphierfield="concat($saphierfield)";
   return($saphierfield);
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   $newrec->{etype}='PSP';
   if (exists($newrec->{isdeleted}) && $newrec->{isdeleted} eq ""){
      $newrec->{isdeleted}="0";
   }

   return(1);
}


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default contacts saphier source));
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


sub CO2PSP_Translator
{
   my $self=shift;
   my $co=shift;
   my $mode=shift;   

   $mode="top" if (!defined($mode));

   return() if (!($co=~m/^\S{10}$/));

   # aus Performance gr�nden wird das �ber eine Schleife (nicht �ber
   # eine ODER Suche) durchgef�hrt!
   foreach my $pref ("E-","R-","Q-"){   # X- not supported at now
      $self->ResetFilter();
      $self->SetFilter({name=>$pref.$co});
      my ($saprec,$msg)=$self->getOnlyFirst(qw(name));
      return($saprec->{name}) if (defined($saprec));
   }
   return();
}





1;
