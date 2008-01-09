package base::MyW5Base::myefforts;
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
use kernel::MyW5Base;
@ISA=qw(kernel::MyW5Base);

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
   $self->{DataObj}=getModuleObject($self->getParent->Config,"base::workflow");
   return(0) if (!defined($self->{DataObj}));
   return(1);
}

sub getDefaultStdButtonBar
{
   my $self=shift;
   return('%StdButtonBar(deputycontrol,print,search)%');
}

sub isSelectable
{
   my $self=shift;

#   my $acl=$self->getParent->getMenuAcl($ENV{REMOTE_USER},
#                          "base::MyW5Base",
#                          func=>'Main',
#                          param=>'MyW5BaseSUBMOD=base::MyW5Base::wfmyjobs');
#   if (defined($acl)){
#      return(1) if (grep(/^read$/,@$acl));
#   }
   return(0);
}

sub Result
{
   my $self=shift;
   my %q=$self->{DataObj}->getSearchHash();

   my $userid=$self->getParent->getCurrentUserId();
   my %grp=$self->getParent->getGroupsOf($ENV{REMOTE_USER},"RMember","both");
   my @grpids=keys(%grp);
   @grpids=(qw(NONE)) if ($#grpids==-1);

   $userid=-1 if (!defined($userid) || $userid==0);
   my $dc=Query->Param("EXVIEWCONTROL");
   my @q=();
   if ($dc eq "ADDDEP" || $dc eq "DEPONLY"){
      my %q1=%q;
      my %q2=%q;
      $q1{fwddebtargetid}=\$userid;
      $q1{fwddebtarget}=\'base::user';
      $q1{stateid}="<20";
      $q2{fwddebtargetid}=\@grpids;
      $q2{fwddebtarget}=\'base::grp';
      $q2{stateid}="<20";
      push(@q,\%q1,\%q2);
   }
   if ($dc ne "DEPONLY"){
      my %q1=%q;
      my %q2=%q;
      my %q3=%q;
      $q1{fwdtargetid}=\$userid;
      $q1{fwdtarget}=\'base::user';
      $q1{stateid}="<20";
      $q2{fwdtargetid}=\@grpids;
      $q2{fwdtarget}=\'base::grp';
      $q2{stateid}="<20";
      $q3{owner}=\$userid;
      $q3{stateid}="<=6";
      push(@q,\%q1,\%q2,\%q3);
   }
   $self->{DataObj}->{OnlyOpenRecords}=1;
   $self->{DataObj}->ResetFilter();
   $self->{DataObj}->SecureSetFilter(\@q);
   $self->{DataObj}->setDefaultView(qw(prio mdate state class name editor));
   
   return($self->{DataObj}->Result(ExternalFilter=>1));
}




1;
