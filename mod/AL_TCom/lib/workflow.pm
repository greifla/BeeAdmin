package AL_TCom::lib::workflow;
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



sub isPostReflector
{
   my $self=shift;
   my $rec=shift;  # if $rec is not defined, insert is validated

   return(undef) if (!defined($rec));
   
   if (defined($rec) && 
       ref($rec->{affectedcontractid}) eq "ARRAY" &&
       $#{$rec->{affectedcontractid}}!=-1){
      my @p800ids;
      if (my ($y,$m)=$rec->{eventend}=~m/^(\d{4})-(\d{2})-.*$/){
         foreach my $contractid (@{$rec->{affectedcontractid}}){
            push(@p800ids,"$m/$y-$contractid");
         }
         if ($#p800ids!=-1){
            my $wf=$self->getPersistentModuleObject("p800repcheck",
                                                    "base::workflow");
            $wf->SetFilter({srcid=>\@p800ids,
                            stateid=>\'8',
                            srcsys=>\"AL_TCom::event::mkp800"});
            my @l=$wf->getHashList(qw(id));
            return() if ($#l!=-1);
         }
      }
   }

   if (defined($rec) && 
       ref($rec->{affectedapplicationid}) eq "ARRAY" &&
       $#{$rec->{affectedapplicationid}}!=-1 &&
       $self->getParent->IsMemberOf("admin","admin.cod")){
      return(1);
   }
   else{
      my %user=();
      my $userid=$self->getParent->getCurrentUserId();
      CHK: {
         my %grp=$self->getParent->getGroupsOf($ENV{REMOTE_USER},
                                               ["REmployee","RChief"],
                                               "both");
         my @grpids=keys(%grp);

         if (ref($rec->{affectedapplicationid}) eq "ARRAY" &&
             $#{$rec->{affectedapplicationid}}!=-1){

            my @applid=@{$rec->{affectedapplicationid}};
            my $appl=getModuleObject($self->Config,"itil::appl");
            $appl->SetFilter(id=>\@applid);
            my @fl=qw(semid sem2id tsmid tsm2id);
            my @tl=qw(businessteamid);
            my @l=$appl->getHashList(@fl,@tl);
            foreach my $rec (@l){
               foreach my $f (@fl){
                  if ($rec->{$f}==$userid){
                     return(1);
                     last CHK;
                  }
               }
               if (defined($rec->{businessteamid})){
                  if (grep(/^$rec->{businessteamid}$/,@grpids)){
                     return(1);
                     last CHK;
                  }
               }
            }
         }
         if (ref($rec->{affectedcontractid}) eq "ARRAY" &&
             $#{$rec->{affectedcontractid}}!=-1){
            my @contid=@{$rec->{affectedcontractid}};
            my $cont=getModuleObject($self->Config,"itil::custcontract");
            $cont->SetFilter(id=>\@contid);
            my @fl=qw(semid sem2id);
            my @l=$cont->getHashList(@fl);
            foreach my $rec (@l){
               foreach my $f (@fl){
                  if ($rec->{$f}==$userid){
                     return(1);
                     last CHK;
                  }
               }
            }
         }
      }
   }
   return(0);
}


sub tcomcodcause
{
   return(qw(undef
             devsupport
             pilot
             firstconfig
             testinstallation
             documentation
             rollout
             install
             installfix
             installminor
             installmajor
             fallback
             desrecoverytest
             uninstall
             bcardcare
             ETAplan 
             ETArelization 
             ETAbusiness 
             ETApromblemanalyse 
             ETAtestSIT1 
             ETAtestSIT2
             ETAtestSIT3
             ETAtestSIT4 
             misc));
}










1;
