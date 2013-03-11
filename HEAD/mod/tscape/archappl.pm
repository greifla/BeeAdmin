package tscape::archappl;
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
   $param{MainSearchFieldLines}=3 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'CapeID',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>"Internal_Key"),

      new kernel::Field::Text(
                name          =>'archapplid',
                label         =>'ICTO-Number',
                dataobjattr   =>'ICTO_Nummer'),

      new kernel::Field::Text(
                name          =>'fullname',
                searchable    =>0,
                sqlorder      =>'NONE',
                label         =>'fullname',
                dataobjattr   =>"ICTO_Nummer+': '+Name"),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                dataobjattr   =>'Name'),

      new kernel::Field::Text(
                name          =>'shortname',
                label         =>'Shortname',
                dataobjattr   =>'Kurzbezeichnung'),

      new kernel::Field::SubList(
                name          =>'w5appl',
                label         =>'W5Base Application',
                group         =>'appl',
                vjointo       =>'TS::appl',
                vjoinon       =>['id'=>'ictoid'],
                vjoindisp     =>['name','cistatus']),

      new kernel::Field::Text(
                name          =>'status',
                label         =>'Status',
                dataobjattr   =>'Status'),

      new kernel::Field::Textarea(       
                name          =>'description',
                label         =>'description',
                dataobjattr   =>'Beschreibung')
   );
   $self->{use_distinct}=0;
   $self->{useMenuFullnameAsACL}=$self->Self;
   $self->setDefaultView(qw(archapplid name  status));
   $self->setWorktable("V_DARWIN_EXPORT");
   return($self);
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tscape"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_status"))){
     Query->Param("search_status"=>"\"!Retired\"");
   }
}



sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default");
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/appl.jpg?".$cgi->query_string());
}
         



1;
