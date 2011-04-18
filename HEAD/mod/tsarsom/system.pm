package tsarsom::system;
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
                label         =>'ServiceID',
                dataobjattr   =>'v_om_ac_computer.service_id'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Computername',
                dataobjattr   =>'v_om_ac_computer.name_des_system'),

      new kernel::Field::Date(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>"TO_DATE('19700101000000','YYYYMMDDHH24MISS')+".
              "NUMTODSINTERVAL(v_om_ac_computer.letzte_aenderung_am,'SECOND')")
   );
   $self->setDefaultView(qw(linenumber id name mdate description));
   return($self);
}

#sub initSearchQuery
#{
#   my $self=shift;
#   if (!defined(Query->Param("search_islocked"))){
#     Query->Param("search_islocked"=>$self->T("no"));
#   }
#}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default source));
}



sub Initialize
{
   my $self=shift;
   
   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsarsom"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   $self->setWorktable("v_om_ac_computer");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
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
