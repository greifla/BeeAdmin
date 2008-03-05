package itil::servicesupport;
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
use itil::lib::Listedit;
@ISA=qw(itil::lib::Listedit);

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
                searchable    =>1,
                label         =>'W5BaseID',
                dataobjattr   =>'servicesupport.id'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                dataobjattr   =>'servicesupport.name'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'servicesupport.cistatus'),

      new kernel::Field::Select(
                name          =>'tz',
                label         =>'Timezone',
                value         =>['CET','GMT',DateTime::TimeZone::all_names()],
                dataobjattr   =>'servicesupport.timezone'),

      new kernel::Field::TimeSpans(
                name          =>'oncallservice',
                htmlwidth     =>'150px',
                depend        =>['isoncallservice'],
                group         =>'oncallservice',
                label         =>'on-call service',
                container     =>'additional'),

      new kernel::Field::Boolean(
                name          =>'isoncallservice',
                label         =>'oncall active',
                container     =>'additional'),

      new kernel::Field::TimeSpans(
                name          =>'support',
                htmlwidth     =>'150px',
                depend        =>['issupport'],
                group         =>'support',
                label         =>'support',
                container     =>'additional'),

      new kernel::Field::Boolean(
                name          =>'issupport',
                label         =>'support active',
                container     =>'additional'),

      new kernel::Field::TimeSpans(
                name          =>'serivce',
                htmlwidth     =>'150px',
                depend        =>['isservice'],
                group         =>'service',
                label         =>'service',
                container     =>'additional'),

      new kernel::Field::Boolean(
                name          =>'isservice',
                label         =>'service active',
                container     =>'additional'),

      new kernel::Field::TimeSpans(
                name          =>'callcenter',
                htmlwidth     =>'150px',
                depend        =>['iscallcenter'],
                group         =>'callcenter',
                label         =>'callcenter',
                container     =>'additional'),

      new kernel::Field::Boolean(
                name          =>'iscallcenter',
                label         =>'callcenter active',
                container     =>'additional'),

      new kernel::Field::Container(
                name          =>'additional',
                label         =>'Additionalinformations',
                uivisible     =>0,
                dataobjattr   =>'servicesupport.additional'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'servicesupport.comments'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'servicesupport.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'servicesupport.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'servicesupport.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'servicesupport.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'servicesupport.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'servicesupport.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'servicesupport.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'servicesupport.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'servicesupport.realeditor'),
   

   );
   $self->setDefaultView(qw(name cistatus mdate cdate));
   $self->{history}=[qw(insert modify delete)];
   $self->{CI_Handling}={uniquename=>"name",
                         activator=>["admin","admin.itil.servicesupport"],
                         uniquesize=>255};
   return($self);
}


sub getDetailBlockPriority
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),
          qw(default oncallservice support service callcenter source));
}





sub Initialize
{
   my $self=shift;

   $self->setWorktable("servicesupport");
   return($self->SUPER::Initialize());
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if ((!defined($oldrec) || defined($newrec->{name})) &&
       $newrec->{name}=~m/^\s*$/){
      $self->LastMsg(ERROR,"invalid name specified");
      return(0);
   }
   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   return(1);
}


sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   return(1);
}


sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;
   if (!$self->HandleCIStatus($oldrec,undef,%{$self->{CI_Handling}})){
      return(0);
   }
   return(1);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   my $userid=$self->getCurrentUserId();
   return("default") if ($self->IsMemberOf("admin"));
   return("default") if (!defined($rec) ||
                         ($rec->{cistatusid}<3 && $rec->{creator}==$userid) ||
                         $self->IsMemberOf($self->{CI_Handling}->{activator}));
   return(undef);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my @param=@_;
   my @adds=();
   return("header","default") if (!defined($rec));
   foreach my $grp (qw(service oncallservice support callcenter)){
      push(@adds,$grp) if ($rec->{"is".$grp});
   }

   return("header","default","source",@adds);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/service_support.jpg?".$cgi->query_string());
}

1;
