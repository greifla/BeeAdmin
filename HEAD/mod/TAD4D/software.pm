package TAD4D::software;
#  W5Base Framework
#  Copyright (C) 2014  Hartmut Vogler (it@guru.de)
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
                label         =>'Id',
                group         =>'source',
                dataobjattr   =>'adm.prod_inv.id'),

      new kernel::Field::Text(
                name          =>'hostname',
                label         =>'Hostname',
                ignorecase    =>1,
                dataobjattr   =>'adm.agent.hostname'),

      new kernel::Field::Text(
                name          =>'software',
                label         =>'Software',
                htmlwidth     =>380,
                ignorecase    =>1,
                dataobjattr   =>'adm.component.name'),

      new kernel::Field::Text(
                name          =>'softwareproduct',
                label         =>'Software Product',
                htmlwidth     =>380,
                ignorecase    =>1,
                dataobjattr   =>'adm.swproduct.name'),

      new kernel::Field::Text(
                name          =>'version',
                label         =>'Version',
                ignorecase    =>1,
                dataobjattr   =>'adm.swproduct.version'),

      new kernel::Field::Boolean(
                name          =>'isremote',
                label         =>'Remote',
                dataobjattr   =>'adm.prod_inv.is_remote'),

      new kernel::Field::Text(
                name          =>'scope',
                label         =>'Scope',
                ignorecase    =>1,
                dataobjattr   =>'adm.prod_inv.scope'),

      new kernel::Field::Date(
                name          =>'starttime',
                label         =>'Start-Time',
                dataobjattr   =>"decode(adm.prod_inv.start_time,".
                                "'9999-12-31 00:00:00.000000',".
                                "NULL,adm.prod_inv.start_time)"),

      new kernel::Field::Text(
                name          =>'endtime',
                label         =>'End-Time',
                dataobjattr   =>"decode(adm.prod_inv.end_time,".
                                "'9999-12-31 00:00:00.000000',".
                                "NULL,adm.prod_inv.end_time)"),

      new kernel::Field::Text(
                name          =>'agentid',
                label         =>'Agent ID',
                ignorecase    =>1,
                group         =>'source',
                dataobjattr   =>'adm.agent.id'),

   );
   $self->setDefaultView(qw(hostname software version));
   return($self);
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tad4d"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/software.jpg?".$cgi->query_string());
}


sub getSqlFrom
{
   my $self=shift;
   my $from="adm.prod_inv,adm.agent,adm.swproduct,adm.component";
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where="adm.prod_inv.agent_id=adm.agent.id and ".
             "adm.prod_inv.product_id=adm.swproduct.id and ".
             "adm.prod_inv.component_id=adm.component.id";
   return($where);
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
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


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default software 
             source));
}  

1;