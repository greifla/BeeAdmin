package kernel::Field::Mandator;
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
use kernel::Field::Select;
use Data::Dumper;
@ISA    = qw(kernel::Field::Select);


sub new
{
   my $type=shift;
   my $self={@_};
   $self->{name}='mandator'                 if (!defined($self->{name}));
   $self->{label}='Mandator'                if (!defined($self->{label}));
   $self->{htmleditwidth}='250px'             if (!defined($self->{htmleditwidth}));
   $self->{htmlwidth}='80px'                if (!defined($self->{htmlwidth}));
   $self->{vjointo}='base::mandator'        if (!defined($self->{vjointo}));
   $self->{vjoinon}=['mandatorid'=>'grpid'] if (!defined($self->{vjoinon}));
   $self->{vjoindisp}="name"                if (!defined($self->{vjoindisp}));
   my $o=bless($type->SUPER::new(%$self),$type);
   return($o);
}

sub getPostibleValues
{
   my $self=shift;
   my $oldrec=shift;
   my $current=shift;
   my $mode=shift;

   if ($mode eq "edit"){
      my $app=$self->getParent();
      my $MandatorCache=$app->Cache->{Mandator}->{Cache};
      return() if (!defined($MandatorCache));
      my @mandators=$app->getMandatorsOf($ENV{REMOTE_USER},"write","direct");
      my $cur=$current->{$self->{vjoinon}->[0]};
      if (defined($cur) && $cur!=0){
         push(@mandators,$cur);
      }
      my @res=();
      if ($self->getParent->IsMemberOf("admin")){
         push(@mandators,keys(%{$MandatorCache->{grpid}}));
      }
      foreach my $mandator (@mandators){
         if (defined($MandatorCache->{grpid}->{$mandator}) &&
             $MandatorCache->{grpid}->{$mandator}->{cistatusid}==4){
            push(@res,$mandator,$MandatorCache->{grpid}->{$mandator}->{name});
         }
      }
      if ($self->{allowany}){
         push(@res,0,"[any]");
      }
      return(@res);
   }
   my @res=$self->SUPER::getPostibleValues($current,$mode);
   if ($self->{allowany}){
      push(@res,0,"[any]");
   }
   return(@res);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $currentstate=shift;   # current state of write record

   if (!$self->readonly($oldrec)){
      my $mandatoridname=$self->{vjoinon}->[0];
      my $requestmandator=$newrec->{$mandatoridname};
      my $app=$self->getParent();
      if ($app->isDataInputFromUserFrontend()){
         my $userid=$app->getCurrentUserId();
         my @mandators=$app->getMandatorsOf($ENV{REMOTE_USER},"write");
         if (!defined($oldrec)){
            if (!defined($newrec->{$mandatoridname}) ||
                ($newrec->{$mandatoridname}==0 && !$self->{allowany})){
               $app->LastMsg(ERROR,"no valid mandator defined");
               return(undef);
            }
         }
         if (!$self->getParent->IsMemberOf("admin")){
            if (defined($newrec->{$mandatoridname}) &&
                !grep(/^$newrec->{$mandatoridname}$/,@mandators) &&
                (!defined($oldrec) ||
                 effVal($oldrec,$newrec,$mandatoridname) ne 
                 $newrec->{$mandatoridname})){
               $app->LastMsg(ERROR,"you are not authorized to write in the ".
                                    "requested mandator");
               return(undef);
            }
         }
      }
   }

   return($self->SUPER::Validate($oldrec,$newrec,$currentstate));
}





1;
