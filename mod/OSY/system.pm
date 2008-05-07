package OSY::system;
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
use itil::system;
@ISA=qw(itil::system);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);


   $self->{workflowlink}->{workflowtyp}=[qw(OSY::workflow::diary
                                            base::workflow::DataIssue 
                                            AL_TCom::workflow::incident 
                                            AL_TCom::workflow::change)];
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

   if (grep(/^OSY::workflow::diary$/,@l)){
      $r->{'OSY::workflow::diary'}={
                                          name=>'Formated_system'
                                       };
   }
   return($r);
}



sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default admin logsys physys ipaddresses systemclass 
             opmode applications software 
             contacts misc attachments control source));
}








1;
