package tsacinv::user;
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
                name          =>'lempldeptid',
                label         =>'UserID',
                dataobjattr   =>'amempldept.lempldeptid'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Fullname',
                htmlwidth     =>'250',
                searchable    =>0,
                onRawValue    =>\&mkFullname,
                depend        =>['name','email','firstname']),

      new kernel::Field::Text(
                name          =>'acfullname',
                label         =>'AC-Internal Fullname',
                htmlwidth     =>'250',
                ignorecase    =>1,
                dataobjattr   =>'amempldept.fullname'),

      new kernel::Field::Text(
                name          =>'loginname',
                label         =>'User-Login',
                ignorecase    =>1,
                dataobjattr   =>'amempldept.userlogin'),

      new kernel::Field::Text(
                name          =>'contactid',
                label         =>'ContactID',
                lowersearch   =>1,
                dataobjattr   =>'amempldept.contactid'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                ignorecase    =>1,
                dataobjattr   =>'amempldept.name'),

      new kernel::Field::Text(
                name          =>'firstname',
                label         =>'Firstname',
                ignorecase    =>1,
                dataobjattr   =>'amempldept.firstname'),

      new kernel::Field::Text(
                name          =>'email',
                label         =>'E-Mail',
                ignorecase    =>1,
                dataobjattr   =>'amempldept.email'),

      new kernel::Field::Text(
                name          =>'ldapid',
                label         =>'LDAPID',
                lowersearch   =>1,
                dataobjattr   =>'amempldept.ldapid'),

      new kernel::Field::SubList(
                name          =>'groups',
                label         =>'Groups',
                vjointo       =>'tsacinv::lnkusergroup',
                vjoinon       =>['lempldeptid'=>'lempldeptid'],
                vjoindisp     =>['group']),

      new kernel::Field::Text(
                name          =>'webpassword',
                label         =>'WEB-Password',
                group         =>'sec',
                lowersearch   =>1,
                dataobjattr   =>'amempldept.webpassword'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'amempldept.externalsystem'),
                                                
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'amempldept.externalid'),
                                                   
   );
   $self->setDefaultView(qw(lempldeptid fullname name ldapid srcsys srcid));
   return($self);
}

sub mkFullname
{
   my $self=shift;
   my $current=shift;

   my $fullname="";
   my $name=$current->{name};
   if ($name ne ""){
      $name=lc($name);
      $name=~tr/���/���/;
      $name=~s/^([a-z])/uc($1)/ge;
      $name=~s/[\s-]([a-z])/uc($1)/ge;
   }
   $fullname.=$name;
   $fullname.=", " if ($fullname ne "" && $current->{firstname} ne "");
   $fullname.=$current->{firstname};
   if ($current->{email} ne ""){
      $fullname.=" " if ($fullname ne "");
      $fullname.="(".lc($current->{email}).")";
   }

   return($fullname);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsac"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/user.jpg?".$cgi->query_string());
}
         

sub getSqlFrom
{
   my $self=shift;
   my $from="amempldept";
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where="amempldept.lempldeptid<>0";
   return($where);
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
