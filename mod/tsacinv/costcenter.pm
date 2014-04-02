package tsacinv::costcenter;
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
   my $self=bless($type->SUPER::new(%param),$type);
  
   $self->AddFields(
      new kernel::Field::Linenumber(
                name       =>'linenumber',
                label      =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'CostCenterID',
                dataobjattr   =>'amcostcenter.lcostid'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'CostCenter-No.',
                dataobjattr   =>'amcostcenter.trimmedtitle'),

      new kernel::Field::Text(
                name          =>'untrimmedname',
                htmldetail    =>0,
                searchable    =>0,
                label         =>'untrimmed CostCenter-No.',
                dataobjattr   =>'amcostcenter.title'),

      new kernel::Field::Boolean(
                name          =>'islocked',
                label         =>'is locked',
                dataobjattr   =>"decode(amcostcenter.flag9,'X',1,0)"),

      new kernel::Field::Text(
                name          =>'code',
                label         =>'CostCenter-Code',
                dataobjattr   =>'amcostcenter.code'),

      new kernel::Field::Text(
                name          =>'description',
                label         =>'Description',
                dataobjattr   =>'amcostcenter.field1'),

      new kernel::Field::Text(
                name          =>'bc',
                label         =>'Business Center',
                ignorecase    =>1,
                dataobjattr   =>'amcostcenter.alternatebusinesscenter'),

      new kernel::Field::Text(
                name          =>'orgunit',
                label         =>'Org-Unit',
                ignorecase    =>1,
                dataobjattr   =>'amcostcenter.orgunit'),

      new kernel::Field::Text(
                name          =>'ictonr',
                label         =>'ICTO-No',
                group         =>'nor',
                ignorecase    =>1,
                dataobjattr   =>'amcostcenter.ictonr'),

      new kernel::Field::Text(
                name          =>'norsolutionmodel',
                label         =>'Solution-Model',
                group         =>'nor',
                ignorecase    =>1,
                dataobjattr   =>'amcostcenter.norsolutionmodel'),

      new kernel::Field::Text(
                name          =>'norinstructiontyp',
                label         =>'Instruction-Typ',
                group         =>'nor',
                ignorecase    =>1,
                dataobjattr   =>'amcostcenter.norinstructiontyp'),

#      new kernel::Field::Text(             # Aufgrund einer Info von Hr.
#                name          =>'bnorcountryexcl',  # Schmied Rainer entfernt.
#                label         =>'Country-Excl',     # (Wir aus AM demn�chst
#                group         =>'nor',              # entfernt).
#                ignorecase    =>1,
#                dataobjattr   =>'amcostcenter.bnorcountryexcl'),

      new kernel::Field::TextDrop(
                name          =>'delmgr',
                group         =>'contact',
                label         =>'lead Delivery Manager',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['delmgrid'=>'lempldeptid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'delmgrid',
                group         =>'contact',
                dataobjattr   =>'amcostcenter.lleadingdeliverymanagerid'),
                                    
     new kernel::Field::TextDrop(
                name          =>'sem',
                label         =>'Customer Business Manager',
                group         =>'contact',
                searchable    =>0,
                vjointo       =>'tsacinv::user',
                vjoinon       =>['semid'=>'lempldeptid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::TextDrop(
                name          =>'productionplanningoss',
                label         =>'Production Planning OSS',
                vjointo       =>'tsacinv::group',
                group         =>'contact',
                vjoinon       =>['productionplanningossid'=>'lgroupid'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'productionplanningossid',
                group         =>'contact',
                dataobjattr   =>'amcostcenter.lproductionplanningossid'),

      new kernel::Field::TextDrop(
                name          =>'customer',
                label         =>'Customer',
                group         =>'contact',
                vjointo       =>'tsacinv::customer',
                vjoinon       =>['lcustomerid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'lcustomerid',
                group         =>'contact',
                dataobjattr   =>'amcostcenter.lcustomerlinkid'),

      new kernel::Field::SubList(
                name          =>'deliverypartner',
                label         =>'Deliverypartner',
                group         =>'contact',
                vjointo       =>'tsacinv::dlvpartner',
                vjoinon       =>['name'=>'name'],
                vjoindisp     =>[qw(deliverymanagement delmgr  
                                  description)]),

     new kernel::Field::TextDrop(
                name          =>'sememail',
                group         =>'contact',
                htmldetail    =>0,
                label         =>'Customer Business Manager E-Mail',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['semid'=>'lempldeptid'],
                vjoindisp     =>'email'),

      new kernel::Field::Link(
                name          =>'semid',
                group         =>'contact',
                dataobjattr   =>'amcostcenter.lservicemanagerid'),

      new kernel::Field::SubList(
                name          =>'applications',
                label         =>'Applications',
                group         =>'applications',
                vjointo       =>'tsacinv::appl',
                vjoinon       =>['name'=>'conumber'],
                vjoindisp     =>[qw(fullname)]),

      new kernel::Field::SubList(
                name          =>'systems',
                label         =>'Systems',
                group         =>'systems',
                vjointo       =>'tsacinv::system',
                vjoinon       =>['name'=>'conumber'],
                vjoindisp     =>[qw(fullname)]),

      new kernel::Field::Text(
                name          =>'saphier',
                label         =>'SAP costcenter hierarchy',
                group         =>'saphier',
                ignorecase    =>1,
                dataobjattr   =>tsacinv::costcenter::getSAPhierSQL()),

      new kernel::Field::Text(
                name          =>'saphier0id',
                label         =>'SAP hierarchy 0',
                group         =>'saphier',
                ignorecase    =>1,
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'amcostcenter.hier0id'),

      new kernel::Field::Text(
                name          =>'saphier1id',
                label         =>'SAP hierarchy 1',
                group         =>'saphier',
                ignorecase    =>1,
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'amcostcenter.hier1id'),

      new kernel::Field::Text(
                name          =>'saphier2id',
                label         =>'SAP hierarchy 2',
                group         =>'saphier',
                ignorecase    =>1,
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'amcostcenter.hier2id'),

      new kernel::Field::Text(
                name          =>'saphier3id',
                label         =>'SAP hierarchy 3',
                group         =>'saphier',
                ignorecase    =>1,
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'amcostcenter.hier3id'),

      new kernel::Field::Text(
                name          =>'saphier4id',
                label         =>'SAP hierarchy 4',
                group         =>'saphier',
                ignorecase    =>1,
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'amcostcenter.hier4id'),

      new kernel::Field::Text(
                name          =>'saphier5id',
                label         =>'SAP hierarchy 5',
                group         =>'saphier',
                ignorecase    =>1,
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'amcostcenter.hier5id'),

      new kernel::Field::Text(
                name          =>'saphier6id',
                label         =>'SAP hierarchy 6',
                group         =>'saphier',
                ignorecase    =>1,
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'amcostcenter.hier6id'),

      new kernel::Field::Text(
                name          =>'saphier7id',
                label         =>'SAP hierarchy 7',
                group         =>'saphier',
                ignorecase    =>1,
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'amcostcenter.hier7id'),

      new kernel::Field::Text(
                name          =>'saphier8id',
                label         =>'SAP hierarchy 8',
                group         =>'saphier',
                ignorecase    =>1,
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'amcostcenter.hier8id'),

      new kernel::Field::Text(
                name          =>'saphier9id',
                label         =>'SAP hierarchy 9',
                group         =>'saphier',
                ignorecase    =>1,
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'amcostcenter.hier9id'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'amcostcenter.externalsystem'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'amcostcenter.externalid'),

      new kernel::Field::Date(
                name          =>'srcload',
                history       =>0,
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'amcostcenter.dtimport'),

      new kernel::Field::Date(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'amcostcenter.dtlastmodif')
   );
   $self->setDefaultView(qw(linenumber id name code description));
   return($self);
}

sub getSAPhierSQL
{
   my $tab=shift;
   $tab="amcostcenter" if ($tab eq "");
   my $saphierfield;
   for(my $c=0;$c<=9;$c++){
      $saphierfield.="||'.'||" if ($saphierfield ne "");
      my $fld="amcostcenter.hier${c}id";
      $saphierfield.="decode($fld,'','-',$fld)";
   }
   return($saphierfield);
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_islocked"))){
     Query->Param("search_islocked"=>$self->T("no"));
   }
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default contact nor applications systems saphier source));
}



sub Initialize
{
   my $self=shift;
   
   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsac"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   $self->setWorktable("amcostcenter");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub initSqlWhere
{
   my $self=shift;
   my $where="amcostcenter.bdelete=0";
   return($where);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/costcenter.jpg?".$cgi->query_string());
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