package base::userlogon;
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
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(        name        =>'id',
                                    label       =>'W5BaseID',
                                    dataobjattr =>['userlogon.account',
                                                   'userlogon.loghour']),
                                  
      new kernel::Field::Text(      name        =>'account',
                                    label       =>'Account',
                                    dataobjattr =>'userlogon.account'),

      new kernel::Field::Text(      name        =>'logonhour',
                                    label       =>'Logon Hour',
                                    dataobjattr =>'userlogon.loghour'),

      new kernel::Field::Date(      name        =>'logondate',
                                    sqlorder    =>'desc',
                                    label       =>'Logon-Date',
                                    dataobjattr =>'userlogon.logondate'),

      new kernel::Field::Text(      name        =>'logonip',
                                    label       =>'Logon IP',
                                    htmlwidth   =>'80px',
                                    dataobjattr =>'userlogon.logonip'),

      new kernel::Field::Text(      name        =>'logonbrowser',
                                    label       =>'Logon Browser',
                                    dataobjattr =>'userlogon.logonbrowser'),

      new kernel::Field::Text(      name        =>'lang',
                                    label       =>'Language',
                                    dataobjattr =>'userlogon.lang'),

      new kernel::Field::Text(      name        =>'site',
                                    label       =>'Site',
                                    dataobjattr =>'userlogon.site'),

   );
   $self->setDefaultView(qw(logondate account logonip logonbrowser));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5base"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   $self->setWorktable("userlogon");
   return(1);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(1);
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

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/env.jpg?".$cgi->query_string());
}

1;
