package itil::ext::w5stat;
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
use kernel::Universal;
@ISA=qw(kernel::Universal);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   return($self);
}


sub processData
{
   my $self=shift;
   my $monthstamp=shift;
   my $currentmonth=shift;
   my ($year,$month)=$monthstamp=~m/^(\d{4})(\d{2})$/;
   my $count;


   my $appl=getModuleObject($self->getParent->Config,"itil::appl");
   $appl->SetCurrentView(qw(ALL));
   $appl->SetFilter({cistatusid=>'<=4'});
   $appl->SetCurrentOrder("NONE");
   msg(INFO,"starting collect of itil::appl");$count=0;
   my ($rec,$msg)=$appl->getFirst();
   if (defined($rec)){
      do{
         $self->getParent->processRecord('itil::appl',$monthstamp,$rec);
         ($rec,$msg)=$appl->getNext();
         $count++;
      } until(!defined($rec));
   }
   msg(INFO,"FINE of itil::appl  $count records");

   my $system=getModuleObject($self->getParent->Config,"itil::system");
   $system->SetCurrentView(qw(ALL));
   $system->SetFilter({cistatusid=>'<=4'});
   $system->SetCurrentOrder("NONE");
   msg(INFO,"starting collect of itil::system");$count=0;
   my ($rec,$msg)=$system->getFirst();
   if (defined($rec)){
      do{
         $self->getParent->processRecord('itil::system',$monthstamp,$rec);
         $count++;
         ($rec,$msg)=$system->getNext();
      } until(!defined($rec));
   }
   msg(INFO,"FINE of itil::system  $count records");

   my $asset=getModuleObject($self->getParent->Config,"itil::asset");
   $asset->SetCurrentView(qw(ALL));
   $asset->SetFilter({cistatusid=>'<=4'});
   $asset->SetCurrentOrder("NONE");
   msg(INFO,"starting collect of itil::asset");$count=0;
   my ($rec,$msg)=$asset->getFirst();
   if (defined($rec)){
      do{
         $self->getParent->processRecord('itil::asset',$monthstamp,$rec);
         $count++;
         ($rec,$msg)=$asset->getNext();
      } until(!defined($rec));
   }
   msg(INFO,"FINE of itil::asset  $count records");
}


sub processRecord
{
   my $self=shift;
   my $module=shift;
   my $monthstamp=shift;
   my $rec=shift;
   my ($year,$month)=$monthstamp=~m/^(\d{4})(\d{2})$/;

   if ($module eq "itil::appl"){
      my $name=$rec->{name};
      if ($rec->{cistatusid}==4){
         $self->getParent->storeStatVar("Group",[$rec->{businessteam},
                                                 $rec->{responseteam}],{},
                                        "ITIL.Application.Count",1);
      }
   }
   if ($module eq "itil::system"){
      my $name=$rec->{name};
      if ($rec->{cistatusid}==4){
         $self->getParent->storeStatVar("Group",[$rec->{admteam}],{},
                                        "ITIL.System.Count",1);
      }
   }
   if ($module eq "itil::asset"){
      my $name=$rec->{name};
      if ($rec->{cistatusid}==4){
         $self->getParent->storeStatVar("Group",[$rec->{guardianteam}],{},
                                        "ITIL.System.Count",1);
      }
   }
   if ($module eq "base::workflow::active"){
      my $countvar;
      $countvar="ITIL.Change.Finish.Count" if ($rec->{class}=~m/::change$/);
      $countvar="ITIL.Incident.Finish.Count" if ($rec->{class}=~m/::incident$/);
      my @affectedapplication=$rec->{affectedapplication};
      if (ref($rec->{affectedapplication}) eq "ARRAY"){
         @affectedapplication=@{$rec->{affectedapplication}};
      }
      my @affectedapplicationid=$rec->{affectedapplicationid};
      if (ref($rec->{affectedapplicationid}) eq "ARRAY"){
         @affectedapplicationid=@{$rec->{affectedapplicationid}};
      }
      my @affectedcontract=$rec->{affectedcontract};
      if (ref($rec->{affectedcontract}) eq "ARRAY"){
         @affectedcontract=@{$rec->{affectedcontract}};
      }
      my $eend=0;
      if ($rec->{eventend} ne ""){
         my ($eyear,$emonth)=$rec->{eventend}=~m/^(\d{4})-(\d{2})-.*$/;
         $eend=1 if ($eyear==$year && $emonth==$month);
      }
      if ($countvar ne ""){
         foreach my $contract (@affectedcontract){
            $self->getParent->storeStatVar("Contract",$contract,
                                           {nosplit=>1},
                                           $countvar,1) if ($eend);
            if ($rec->{class}=~m/::incident$/){
               $self->getParent->storeStatVar("Contract",$contract,
                                              {nosplit=>1,
                                               method=>'tspan.union'},
                                              "ITIL.Incident",
                                              $rec->{eventstart},
                                              $rec->{eventend});
            }
         }
         foreach my $appl (@affectedapplication){
            $self->getParent->storeStatVar("Application",$appl,{nosplit=>1},
                                           $countvar,1) if ($eend);
            if ($rec->{class}=~m/::incident$/){
               $self->getParent->storeStatVar("Application",$appl,
                                              {nosplit=>1,
                                               method=>'tspan.union'},
                                              "ITIL.Incident",
                                              $rec->{eventstart},
                                              $rec->{eventend});
            }
         }
         my $involvedresponseteam=$rec->{involvedresponseteam};
         my $involvedbusinessteam=$rec->{involvedbusinessteam};
         $involvedresponseteam=[] if (!ref($involvedresponseteam));
         $involvedbusinessteam=[] if (!ref($involvedbusinessteam));
         my @groups=();
         push(@groups,@$involvedresponseteam);
         push(@groups,@$involvedbusinessteam);
         $self->getParent->storeStatVar("Group",
                         \@groups,{},$countvar,1) if ($eend);
         if ($rec->{class}=~m/::incident$/){
            $self->getParent->storeStatVar("Group",\@groups,
                      {method=>'tspan.union'},
                     "ITIL.Incident",
                     $rec->{eventstart},$rec->{eventend});
         }
      }
   }
}


1;
