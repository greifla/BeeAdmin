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
                name       =>'id',
                label      =>'CostCenterID',
                dataobjattr=>'amcostcenter.lcostid'),

      new kernel::Field::Text(
                name       =>'name',
                label      =>'CostCenter-No.',
                dataobjattr=>'amcostcenter.trimmedtitle'),

      new kernel::Field::Text(
                name       =>'code',
                label      =>'CostCenter-Code',
                dataobjattr=>'amcostcenter.code'),

      new kernel::Field::Text(
                name       =>'description',
                label      =>'Description',
                dataobjattr=>'amcostcenter.field1'),

      new kernel::Field::Text(
                name       =>'bc',
                label      =>'Business Center',
                dataobjattr=>'amcostcenter.alternatebusinesscenter'),

      new kernel::Field::TextDrop(
                name          =>'delmgr',
                label         =>'Delivery Manager',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['delmgrid'=>'lempldeptid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'delmgrid',
                dataobjattr   =>'amcostcenter.arldeliverymanagementid'),
                                    
     new kernel::Field::TextDrop(
                name          =>'sem',
                label         =>'Service Manager',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['semid'=>'lempldeptid'],
                vjoindisp     =>'fullname'),

     new kernel::Field::TextDrop(
                name          =>'sememail',
                htmldetail    =>0,
                label         =>'Service Manager E-Mail',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['semid'=>'lempldeptid'],
                vjoindisp     =>'email'),

      new kernel::Field::Link(
                name          =>'semid',
                dataobjattr   =>'amcostcenter.lservicemanagerid'),
                                    

   );
   $self->setDefaultView(qw(linenumber id name code description));
   return($self);
}

sub Initialize
{
   my $self=shift;
   
   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsac"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   $self->setWorktable("amcostcenter");
   return(1);
}

sub initSqlWhere
{
   my $self=shift;
   my $where="amcostcenter.bdelete=0 ";
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
