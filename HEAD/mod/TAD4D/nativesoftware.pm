package TAD4D::nativesoftware;
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
      new kernel::Field::Id(
                name          =>'id',
                group         =>'source',
                label         =>'Installation ID',
                dataobjattr   =>'adm.inst_native_sw.native_id'),

      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Text(
                name          =>'hostname',
                label         =>'Hostname',
                ignorecase    =>1,
                dataobjattr   =>'adm.agent.hostname'),

      new kernel::Field::Text(
                name          =>'software',
                label         =>'native Software',
                ignorecase    =>1,
                dataobjattr   =>'adm.native_sw.package_name'),

      new kernel::Field::Text(
                name          =>'version',
                label         =>'Version',
                ignorecase    =>1,
                dataobjattr   =>'adm.native_sw.package_version'),

      new kernel::Field::Text(
                name          =>'agentid',
                label         =>'Agent ID',
                ignorecase    =>1,
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


#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
#}
         


sub getSqlFrom
{
   my $self=shift;
   my $from="adm.agent,adm.inst_native_sw,adm.native_sw";
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where="adm.agent.id=adm.inst_native_sw.agent_id and ".
             "adm.native_sw.id=adm.inst_native_sw.native_id";
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