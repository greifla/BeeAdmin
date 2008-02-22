package base::lnkqrulemandator;
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
use Data::Dumper;
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
                label         =>'LinkID',
                dataobjattr   =>'lnkqrulemandator.lnkqrulemandatorid'),

      new kernel::Field::Mandator(allowany=>1),

      new kernel::Field::Link(
                name          =>'mandatorid',
                label         =>'Mandator-ID',
                dataobjattr   =>'lnkqrulemandator.mandator'),
                                                 
      new kernel::Field::Text(
                name          =>'dataobj',
                label         =>'confine to data object',
                dataobjattr   =>'lnkqrulemandator.dataobj'),
                                                 
      new kernel::Field::TextDrop(
                name          =>'qrule',
                label         =>'Quality Rule',
                vjointo       =>'base::qrule',
                vjoinon       =>['qruleid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'qruleid',
                label         =>'QRule-ID',
                dataobjattr   =>'lnkqrulemandator.qrule'),
                                                 
      new kernel::Field::Date(
                name          =>'expiration',
                label         =>'Expiration-Date',
                dataobjattr   =>'lnkqrulemandator.expiration'),
                                                 
      new kernel::Field::Textarea(
                name          =>'comments',
                htmlwidth     =>'150',
                label         =>'Comments',
                dataobjattr   =>'lnkqrulemandator.comments'),
                                                 
      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnkqrulemandator.createuser'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnkqrulemandator.srcsys'),
                                                 
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnkqrulemandator.srcid'),
                                                 
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'lnkqrulemandator.srcload'),
                                                 
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkqrulemandator.createdate'),
                                                 
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkqrulemandator.modifydate'),
                                                 
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'lnkqrulemandator.editor'),
                                                 
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'lnkqrulemandator.realeditor'),
   );
   $self->setDefaultView(qw(mandator qrule cdate dataobj));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5base"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   $self->setWorktable("lnkqrulemandator");
   return(1);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $dataobj=effVal($oldrec,$newrec,"dataobj");
   if (defined($dataobj)){
      $dataobj=trim($dataobj);
      if ($dataobj eq "" ||
          !($dataobj=~m/^[a-z,0-9,_]+::[a-z,0-9,_]+$/i)){
         $self->LastMsg(ERROR,"invalid dataobject nameing");
         return(undef);  
      }
      $newrec->{dataobj};
   }

   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if ($self->IsMemberOf("admin"));
   return(undef);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/lnkmandatorqmgmt.jpg?".$cgi->query_string());
}



1;
