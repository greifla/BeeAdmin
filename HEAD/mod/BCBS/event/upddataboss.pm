package BCBS::event::upddataboss;
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
use kernel::Event;
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub Init
{
   my $self=shift;


   $self->RegisterEvent("upddataboss","upddataboss");
   return(1);
}

sub upddataboss
{
   my $self=shift;


   my $sys=getModuleObject($self->Config,"itil::system");
   my $osys=getModuleObject($self->Config,"itil::system");
   my $appl=getModuleObject($self->Config,"itil::appl");
   my $ass=getModuleObject($self->Config,"itil::asset");
   my $asset=getModuleObject($self->Config,"itil::asset");
   $ass->SetFilter({databoss=>'[EMPTY]'});
   $ass->SetCurrentView(qw(id name systems));
   if (my ($rec,$msg)=$ass->getFirst()){
      my $count=1;
      while(defined($rec)){
         msg(INFO,"$count ass=$rec->{name}");
         my $databoss;
         findboss: foreach my $sysrec (@{$rec->{systems}}){
            $sys->ResetFilter();
            $sys->SetFilter({id=>\$sysrec->{id}});
            my ($rec,$msg)=$sys->getOnlyFirst("id","databoss");
            if (defined($rec) && $rec->{databoss} ne ""){
               $databoss=$rec->{databoss};
               last findboss;
            }
         }
         msg(INFO,"===> using $databoss");
         if (defined($databoss)){
            $asset->ResetFilter();
            $asset->SetFilter({id=>\$rec->{id}});
            my ($arec,$msg)=$asset->getOnlyFirst(qw(ALL));
            if ($arec->{databoss} eq ""){
               $asset->ValidatedUpdateRecord($arec,{databoss=>$databoss},
                                             {id=>\$arec->{id}});
            }
#            $osys->ResetFilter();
#            $osys->SetFilter({id=>\$rec->{id}});
#            my ($arec,$msg)=$osys->getOnlyFirst(qw(ALL));
#            if ($arec->{databoss} eq ""){
#               $osys->ValidatedUpdateRecord($arec,{databoss=>$databoss},
#                                             {id=>\$arec->{id}});
#            }
         }
         ($rec,$msg)=$ass->getNext();
         $count++;
         last if (!defined($rec));
      }
   }

   return({exitcode=>0});
}


1;