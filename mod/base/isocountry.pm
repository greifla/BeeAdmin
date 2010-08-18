package base::isocountry;
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
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'isocountry.id'),
                                                  
      new kernel::Field::Text(
                name          =>'fullname',
                readonly      =>1,
                label         =>'full country name',
                dataobjattr   =>'isocountry.fullname'),

      new kernel::Field::Text(
                name          =>'token',
                label         =>'Country token',
                dataobjattr   =>'isocountry.token'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Countryname',
                dataobjattr   =>'isocountry.name'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'isocountry.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'isocountry.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'isocountry.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'isocountry.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'isocountry.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'isocountry.realeditor'),

   );
   $self->setDefaultView(qw(linenumber token fullname cistatus cdate mdate));
   $self->setWorktable("isocountry");
   return($self);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;


   my $name=trim(effVal($oldrec,$newrec,"name"));
   my $token=trim(effVal($oldrec,$newrec,"token"));
   if (length($token)!=2 || ($token=~m/\s/)){
      $self->LastMsg(ERROR,"invalid token");
      return(0);
   }
   if ($name eq "" || ($name=~m/[^-a-z0-9\._ \(\)]/i)){
      $self->LastMsg(ERROR,"invalid country name");
      return(0);
   }

   if (exists($newrec->{token}) ||
       exists($newrec->{name})  ){
      $newrec->{token}=uc($newrec->{token});
      my $fname=uc($token);
      $fname.=($fname ne "" && $name ne "" ? "-" : "").$name;
      $newrec->{'fullname'}=$fname;
      $newrec->{'fullname'}=~s/[\(\)]/ /g;
      $newrec->{'fullname'}=~s/\s/_/g;
      $newrec->{'fullname'}=~s/__/_/g;
      $newrec->{'fullname'}=~s/__/_/g;
      $newrec->{'fullname'}=~s/__/_/g;
   }

   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec) && $self->IsMemberOf("admin"));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if ($self->IsMemberOf("admin"));
   return(undef);
}





1;
