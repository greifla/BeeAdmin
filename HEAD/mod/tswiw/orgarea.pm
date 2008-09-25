package tswiw::orgarea;
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
use kernel::DataObj::LDAP;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::LDAP);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   
   my @result=$self->AddDirectory(LDAP=>new kernel::ldapdriver($self,"tswiw"));
   return(@result) if (defined($result[0]) eq "InitERROR");

   $self->setBase("o=Organisation,o=WiW");
   $self->AddFields(
      new kernel::Field::Id(       name       =>'touid',
                                   label      =>'tOuID',
                                   size       =>'10',
                                   align      =>'left',
                                   dataobjattr=>'tOuID'),

      new kernel::Field::Text(     name       =>'name',
                                   label      =>'Orgarea-Name (tOuLD)',
                                   size       =>'10',
                                   dataobjattr=>'tOuLD'),

      new kernel::Field::Text(     name       =>'shortname',
                                   label      =>'Orgarea-ShortName (tOuSD)',
                                   size       =>'10',
                                   dataobjattr=>'tOuSD'),

      new kernel::Field::TextDrop( name       =>'parent',
                                   label      =>'Parentgroup (tOuSuperior)',
                                   vjointo    =>'tswiw::orgarea',
                                   vjoinon    =>['parentid'=>'touid'],
                                   vjoindisp  =>'name'),

      new kernel::Field::TextDrop( name       =>'boss',
                                   label      =>'Boss (tOuMgr)',
                                   vjointo    =>'tswiw::user',
                                   vjoinon    =>['mgrwiwid'=>'id'],
                                   vjoindisp  =>'id'),

      new kernel::Field::TextDrop( name       =>'bosssurname',
                                   label      =>'Boss (surname)',
                                   vjointo    =>'tswiw::user',
                                   vjoinon    =>['mgrwiwid'=>'id'],
                                   vjoindisp  =>'surname'),

      new kernel::Field::TextDrop( name       =>'bossgivenname',
                                   label      =>'Boss (givenname)',
                                   vjointo    =>'tswiw::user',
                                   vjoinon    =>['mgrwiwid'=>'id'],
                                   vjoindisp  =>'givenname'),

      new kernel::Field::TextDrop( name       =>'bossemail',
                                   label      =>'Boss (email)',
                                   vjointo    =>'tswiw::user',
                                   vjoinon    =>['mgrwiwid'=>'id'],
                                   vjoindisp  =>'email'),

      new kernel::Field::SubList(  name       =>'users',
                                   label      =>'Users',
                                   group      =>'userro',
                                   vjointo    =>'tswiw::user',
                                   vjoinon    =>['touid'=>'touid'],
                                   vjoindisp  =>['surname','givenname',
                                                 'email','office_phone']),

      new kernel::Field::Text(     name       =>'parentid',
                                   label      =>'ParentID (tOuSuperior)',
                                   dataobjattr=>'tOuSuperior'),

      new kernel::Field::Link(     name       =>'mgrwiwid',
                                   dataobjattr=>'tOuMgr'),

      new kernel::Field::QualityText(),
      new kernel::Field::QualityState(),
      new kernel::Field::QualityOk(),
   );
   $self->setDefaultView(qw(touid name users));
   return($self);
}

sub SetFilterForQualityCheck
{  
   my $self=shift;
   my @view=@_;
   return(undef);
}
   


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/grp.jpg?".$cgi->query_string());
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
