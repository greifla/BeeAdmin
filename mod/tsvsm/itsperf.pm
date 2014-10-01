package tsvsm::itsperf;
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
   #$param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                label         =>'ID',
                dataobjattr   =>"darwin_id"),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'IT-Service HashTag',
                dataobjattr   =>'hashtag'),

      new kernel::Field::Text(
                name          =>'mperiod',
                label         =>'measure period',
                dataobjattr   =>'messzeitraum'),

      new kernel::Field::Number(
                name          =>'avail',
                precision     =>2,
                label         =>'availability',
                dataobjattr   =>'verfuegbarkeit'),

      new kernel::Field::Number(
                name          =>'perf',
                precision     =>2,
                label         =>'performance',
                dataobjattr   =>'performance'),

      new kernel::Field::Number(
                name          =>'quality',
                precision     =>2,
                label         =>'quality',
                dataobjattr   =>'quality'),

      new kernel::Field::Number(
                name          =>'resptime',
                precision     =>2,
                label         =>'response time',
                dataobjattr   =>'antwortzeit'),

   );
   $self->setWorktable("darwin");

   $self->setDefaultView(qw(name mperiod avail perf quality));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsvsm"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

#sub initSearchQuery
#{
#   my $self=shift;
#   if (!defined(Query->Param("search_validto"))){
#     Query->Param("search_validto"=>
#                  ">now OR [EMPTY]");
#   }
#}


sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default");
}


#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/base/load/location.jpg?".$cgi->query_string());
#}
         

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