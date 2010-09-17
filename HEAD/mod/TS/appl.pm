package TS::appl;
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
use kernel::Field;
use itil::appl;
@ISA=qw(itil::appl);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Text(
                name          =>'acapplname',
                label         =>'official AssetManager Applicationname',
                group         =>'source',
                htmldetail    =>0,
                searchable    =>0,
                depend        =>['applid','name'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   if ($current->{name} ne "" &&
                       $current->{applid} ne ""){
                      return(uc($current->{name}." (".$current->{applid}.")"));
                   }
                   return(undef);
                }),

      new kernel::Field::Link(
                name          =>'acinmassignmentgroupid',
                group         =>'control',
                label         =>'Incient Assignmentgroup ID',
                container     =>'additional'),

      new kernel::Field::TextDrop(
                name          =>'acinmassingmentgroup',
                label         =>'Incident Assignmentgroup',
                group         =>'inmchm',
                async         =>'1',
                searchable    =>0,
                vjointo       =>'tsacinv::group',
                vjoinon       =>['acinmassignmentgroupid'=>'lgroupid'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'scapprgroupid',
                group         =>'control',
                label         =>'Change Approvergroup ID',
                container     =>'additional'),

      new kernel::Field::TextDrop(
                name          =>'scapprgroup',
                label         =>'Change Approvergroup',
                vjoineditbase =>{isapprover=>\'1'},
                group         =>'inmchm',
                async         =>'1',
                searchable    =>0,
                vjointo       =>'tssc::group',
                vjoinon       =>['scapprgroupid'=>'id'],
                vjoindisp     =>'name'),
   );
 
   $self->AddFields(
      new kernel::Field::Text(
                name          =>'applnumber',
                searchable    =>0,
                label         =>'Application number',
                container     =>'additional'),
      insertafter=>['applid'] 
   );
   $self->{workflowlink}->{workflowtyp}=[qw(AL_TCom::workflow::diary
                                            OSY::workflow::diary
                                            itil::workflow::devrequest
                                            AL_TCom::workflow::businesreq
                                            THOMEZMD::workflow::businesreq
                                            base::workflow::DataIssue
                                            base::workflow::mailsend
                                            AL_TCom::workflow::change
                                            AL_TCom::workflow::problem
                                            AL_TCom::workflow::eventnotify
                                            AL_TCom::workflow::P800
                                            AL_TCom::workflow::P800special
                                            AL_TCom::workflow::incident)];
   $self->{workflowlink}->{workflowstart}=\&calcWorkflowStart;

   return($self);
}

sub calcWorkflowStart
{
   my $self=shift;
   my $r={};

   my %env=('frontendnew'=>'1');
   my $wf=getModuleObject($self->Config,"base::workflow");
   my @l=$wf->getSelectableModules(%env);

   if (grep(/^AL_TCom::workflow::diary$/,@l)){
      $r->{'AL_TCom::workflow::diary'}={
                                          name=>'Formated_appl'
                                       };
   }
   if (grep(/^AL_TCom::workflow::eventnotify$/,@l)){
      $r->{'AL_TCom::workflow::eventnotify'}={
                                          name=>'Formated_affectedapplication'
                                       };
   }
   return($r);
}

sub getSpecPaths
{
   my $self=shift;
   my $rec=shift;
   my @l=$self->SUPER::getSpecPaths($rec);
   push(@l,"TS/spec/TS.appl");
   return(@l);
}


sub isWriteValid
{
   my $self=shift;
   my @l=$self->SUPER::isWriteValid(@_);
   if (grep(/^(technical|ALL)$/,@l)){
      push(@l,"inmchm");
   }
   return(@l);
}

sub getDetailBlockPriority
{
   my $self=shift;
   my @l=$self->SUPER::getDetailBlockPriority(@_);
   my $inserti=$#l;
   for(my $c=0;$c<=$#l;$c++){
      $inserti=$c+1 if ($l[$c] eq "technical");
   }
   splice(@l,$inserti,$#l-$inserti,("inmchm",@l[$inserti..($#l+-1)]));
   return(@l);

}  







1;
