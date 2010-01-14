package kernel::MandatorDataACL;
#  W5Base Framework
#  Copyright (C) 2009  Hartmut Vogler (it@guru.de)
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
use kernel;

sub expandByDataACL
{
   my $self=shift;
   my $mandator=shift;
   my @fieldgroups=@_;
   $mandator=[$mandator] if (ref($mandator) ne "ARRAY");
   my $acl=$self->getPersistentModuleObject("base::mandatordataacl");
   my @flt;
   my %p=($self->Self=>1,$self->SelfAsParentObject=>1);
   foreach my $parentobj (keys(%p)){
      push(@flt,{parentobj=>\$parentobj,mandatorid=>$mandator});
   }
   $acl->SetFilter(\@flt);
   my $grps;
   my $userid=$self->getCurrentUserId();
   my %chkdataname;
   foreach my $acl ($acl->getHashList(qw(dataname prio aclmode 
                                         target targetid))){
      my $dataname=$acl->{dataname};
      my $pref="";
      $pref="!" if ($acl->{aclmode} eq "deny");
      if (!exists($chkdataname{$dataname})){
         if ($acl->{target} eq "base::grp"){
            if (!defined($grps)){
               $grps={$self->getGroupsOf($userid,"RMember","down")};
            }
            if (exists($grps->{$acl->{targetid}})){
               push(@fieldgroups,$pref.$acl->{dataname});
               next;
            }
         }
         if ($acl->{target} eq "base::user" &&
             $acl->{targetid}==$userid){
            push(@fieldgroups,$pref.$acl->{dataname});
            next;
         }
      }
   }
   return(@fieldgroups);
}



######################################################################
1;
