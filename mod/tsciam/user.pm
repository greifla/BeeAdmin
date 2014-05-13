package tsciam::user;
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
   
   $self->setBase("o=DTAG");
   $self->AddFields(
      new kernel::Field::Linenumber(name     =>'linenumber',
                                    label      =>'No.'),

      new kernel::Field::Id(       name       =>'id',
                                   label      =>'PersonalID',
                                   size       =>'10',
                                   htmlwidth  =>'130',
                                   align      =>'left',
                                   dataobjattr=>'tCID'),

      new kernel::Field::Text(     name       =>'uid',
                                   label      =>'UserID',
                                   size       =>'10',
                                   htmlwidth  =>'130',
                                   align      =>'left',
                                   sortvalue  =>'asc',
                                   dataobjattr=>'uid'),

      new kernel::Field::Text(     name       =>'wiwid',
                                   label      =>'WiWid',
                                   size       =>'10',
                                   htmlwidth  =>'130',
                                   align      =>'left',
                                   sortvalue  =>'asc',
                                   dataobjattr=>'twiw-uid'),

      new kernel::Field::Text(     name       =>'fullname',
                                   label      =>'Fullname',
                                   searchable =>0,
                                   onRawValue =>sub{
                                      my $self=shift;
                                      my $current=shift;
                                      my $d=$current->{surname};
                                      my $v=$current->{givenname};
                                      $d.=", " if ($d ne "" && $v ne "");
                                      $d.=$v;
                                      $d.=" " if ($d ne "");
                                      if ($current->{email} ne ""){
                                         $d.="($current->{email})";
                                      }
                                      return($d);
                                   },
                                   depend     =>['surname','givenname',
                                   'email']),

      new kernel::Field::Text(     name       =>'surname',
                                   label      =>'Surname',
                                   size       =>'10',
                                   dataobjattr=>'sn'),

      new kernel::Field::Text(     name       =>'givenname',
                                   label      =>'Givenname',
                                   size       =>'10',
                                   dataobjattr=>'givenname'),

      new kernel::Field::Email(    name       =>'email',
                                   label      =>'E-Mail',
                                   size       =>'10',
                                   dataobjattr=>'mail'),
                                  
      new kernel::Field::Email(    name       =>'email2',
                                   label      =>'E-Mail (tWRmail)',
                                   size       =>'10',
                                   dataobjattr=>'tWRmail'),
                                  
      new kernel::Field::Email(    name       =>'email3',
                                   label  =>'E-Mail (tWRmailAlternateAddress)',
                                   size       =>'10',
                                   dataobjattr=>'tWRmailAlternateAddress'),
                                  
      new kernel::Field::Email(    name       =>'email4',
                                   label  =>'E-Mail (tWRmailRoutingAddress)',
                                   size       =>'10',
                                   dataobjattr=>'tWRmailRoutingAddress'),
                                  
      new kernel::Field::TextDrop( name       =>'office',
                                   label      =>'Office',
                                   group      =>'office',
                                   vjointo    =>'tswiw::orgarea',
                                   vjoinon    =>['touid'=>'touid'],
                                   vjoindisp  =>'name'),

      new kernel::Field::Text(     name       =>'office_state',
                                   group      =>'office',
                                   label      =>'Status',
                                   dataobjattr=>'organizationalstatus'),

      new kernel::Field::Text(     name       =>'office_wrs',
                                   group      =>'office',
                                   label      =>'Workrelationship',
                                   dataobjattr=>'tTypeOfWorkrelationship'),

      new kernel::Field::Text(     name       =>'office_persnum',
                                   group      =>'office',
                                   label      =>'Personal-Number',
                                   dataobjattr=>'employeeNumber'),

      new kernel::Field::Text(     name       =>'office_costcenter',
                                   group      =>'office',
                                   label      =>'CostCenter',
                                   dataobjattr=>'tCostCenterNo'),

      new kernel::Field::Text(     name       =>'office_accarea',
                                   group      =>'office',
                                   label      =>'Accounting Area',
                                   dataobjattr=>'tCostCenterAccountingArea'),

      new kernel::Field::Phonenumber(name     =>'office_phone',
                                   group      =>'office',
                                   label      =>'Phonenumber',
                                   dataobjattr=>'telephoneNumber'),

      new kernel::Field::Phonenumber(name     =>'office_mobile',
                                   group      =>'office',
                                   label      =>'Mobile-Phonenumber',
                                   dataobjattr=>'mobile'),

      new kernel::Field::Phonenumber(name     =>'office_facsimile',
                                   group      =>'office',
                                   label      =>'FAX-Number',
                                   dataobjattr=>'facsimileTelephoneNumber'),

      new kernel::Field::Text(     name       =>'office_room',
                                   group      =>'office',
                                   label      =>'Room',
                                   dataobjattr=>'roomNumber'),

      new kernel::Field::Text(     name       =>'office_street',
                                   group      =>'office',
                                   label      =>'Street',
                                   dataobjattr=>'street'),

      new kernel::Field::Text(     name       =>'office_zipcode',
                                   group      =>'office',
                                   label      =>'ZIP-Code',
                                   dataobjattr=>'postalCode'),

      new kernel::Field::Text(     name       =>'office_location',
                                   group      =>'office',
                                   label      =>'Location',
                                   dataobjattr=>'l'),

      new kernel::Field::Text(     name       =>'touid',
                                   group      =>'office',
                                   label      =>'tOuCID',
                                   dataobjattr=>'tOuCID'),

      #new kernel::Field::Boolean(  name       =>'isVSNFD',
      #                             group      =>'status',
      #                             label      =>'is VS-NfD instructed',
      #                             dataobjattr=>'tVsNfd'),

      new kernel::Field::Text(     name       =>'country',
                                   group      =>'status',
                                   label      =>'Country',
                                   dataobjattr=>'C'),

      new kernel::Field::Text(     name       =>'office_address',
                                   group      =>'status',
                                   label      =>'postalAddress',
                                   dataobjattr=>'postalAddress'),

      new kernel::Field::Text(     name       =>'office_organisation',
                                   group      =>'status',
                                   label      =>'Organisation',
                                   dataobjattr=>'o'),

      new kernel::Field::Text(     name       =>'office_orgunit',
                                   group      =>'status',
                                   label      =>'Orgunit',
                                   dataobjattr=>'ou'),

      new kernel::Field::Text(     name       =>'sex',
                                   group      =>'status',
                                   label      =>'Sex',
                                   dataobjattr=>'tSex'),

      new kernel::Field::Text(     name       =>'lang',
                                   group      =>'status',
                                   label      =>'preferrredLanguage',
                                   dataobjattr=>'preferredLanguage'),

      new kernel::Field::Text(     name       =>'winlogon',
                                   group      =>'status',
                                   label      =>'Window Domain Logon',
                                   dataobjattr=>'tADlogin'),

      #new kernel::Field::Text(     name       =>'photoURL',
      #                             group      =>'status',
      #                             label      =>'photoURL',
      #                             dataobjattr=>'tPhotoURL'),


   );
   $self->setDefaultView(qw(id uid surname givenname email));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDirectory(LDAP=>new kernel::ldapdriver($self,"tsciam"));
   return(@result) if (defined($result[0]) eq "InitERROR");

   return(1) if (defined($self->{tswiw}));
   return(0);
}



sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/user.jpg?".$cgi->query_string());
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
