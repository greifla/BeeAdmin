package itil::MyW5Base::myclosedeventinfo;
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
   $self->{appl}=getModuleObject($self->getParent->Config,"itil::appl");
   return(0) if (!defined($self->{DataObj}));
   return(1);
}

sub getQueryTemplate
{
   my $self=shift;
   my $timelabel=$self->getParent->T("Event end time");;
   my $timedrop=$self->getTimeRangeDrop("Search_TimeRange",
                                        $self->getParent,
                                        qw(month));
   my $d=<<EOF;
<div class=searchframe>
<table class=searchframe><tr>
<td class=fname width=10%>\%id(label)\%:</td>
<td class=finput width=40% >\%id(search)\%</td>
<td class=fname width=10%>\%name(label)\%:</td>
<td class=finput width=40% >\%name(search)\%</td>
</tr><tr>
<td class=fname>$timelabel:</td>
<td class=finput>$timedrop</td>
<td class=fname>\%affectedapplication(label)\%:</td>
<td class=finput>\%affectedapplication(search)\%</td>
</tr>
</table>
</div>
%StdButtonBar(exviewcontrol,deputycontrol,teamviewcontrol,bookmark,print,search)%
EOF
   return($d);
}


sub Result
{
   my $self=shift;
   my %q=$self->{DataObj}->getSearchHash();

   my $userid=$self->getParent->getCurrentUserId();
   $userid=-1 if (!defined($userid) || $userid==0);


   my $dc=Query->Param("EXVIEWCONTROL");
   my @q=();
   my @grpids;
   if ($dc eq "CUSTOMER"){
      my %grp=$self->getParent->getGroupsOf($ENV{REMOTE_USER},
                           ["REmployee","RBoss","RFreelancer","RApprentice",
                            "RINManager","RQManager"],"both");
      @grpids=keys(%grp);
      @grpids=(qw(-1)) if ($#grpids==-1);
      my %q1;
      $q1{cistatusid}='<=4';
      $q1{customerid}=\@grpids;
      push(@q,\%q1);
   }
   if ($dc eq "TEAM"){
      my %grp=$self->getParent->getGroupsOf($ENV{REMOTE_USER},
                           ["REmployee","RBoss","RFreelancer","RApprentice",
                            "RINManager","RQManager"],"down");
      @grpids=keys(%grp);
      @grpids=(qw(-1)) if ($#grpids==-1);
      my (%q1,%q2,%q3);
      $q1{cistatusid}='<=4';
      $q1{businessteamid}=\@grpids;
      $q2{cistatusid}='<=4';
      $q2{responseteamid}=\@grpids;
      $q3{cistatusid}='<=4';
      $q3{mandatorid}=\@grpids;
      push(@q,\%q1,\%q2,\%q3);
   }
   if ($dc eq "ADDDEP" || $dc eq "DEPONLY"){
      my (%q1,%q2,%q3,%q4,%q5,%q6);
      $q1{sem2id}=\$userid;
      $q2{tsm2id}=\$userid;
      my %grp=$self->getParent->getGroupsOf($ENV{REMOTE_USER},
                                            ["RBoss2"],"down");
      my @grpids=keys(%grp);
      @grpids=(qw(-1)) if ($#grpids==-1);
      $q3{businessteamid}=\@grpids;
      $q4{responseteamid}=\@grpids;
      $q5{opm2id}=\$userid;
      $q6{delmgr2id}=\$userid;
      push(@q,\%q1,\%q2,\%q3,\%q4,\%q5,\%q6);
   }
   if ($dc ne "DEPONLY" && $dc ne "TEAM" && $dc ne "CUSTOMER"){
      my (%q1,%q2,%q3,%q4,%q5);
      $q1{semid}=\$userid;
      $q2{tsmid}=\$userid;
      $q3{databossid}=\$userid;
      $q4{delmgrid}=\$userid;
      $q5{opmid}=\$userid;
      push(@q,\%q1,\%q2,\%q3,\%q4,\%q5);
   }

   $self->{appl}->ResetFilter();
   if ($dc ne "CUSTOMER"){
      $self->{appl}->SecureSetFilter(\@q);
   }
   else{
      $self->{appl}->SetFilter(\@q);
   }
   my @l=$self->{appl}->getHashList("id");
   my @appl=("none");
   if ($#l>-1){
      @appl=map({$_->{id}} @l);
   }
   $self->DataObj->doInitialize();
   my %q1=%q;
   $q1{stateid}='>15';
   $q1{isdeleted}=\'0';
   $q1{eventend}=Query->Param("Search_TimeRange");
   $q1{eventend}="<now AND >now-24h" if (!defined($q1{eventend}));
   $q1{class}=[grep(/^.*::eventnotify$/,
                    keys(%{$self->{DataObj}->{SubDataObj}}))];
   $q1{affectedapplicationid}=\@appl;
   if ($#grpids!=-1 && $dc ne "CUSTOMER"){ # hack to find delete 
                                           # applications over mandatorid
      $self->{DataObj}->ResetFilter();    # (most only needed for incidenmanager
      $self->{DataObj}->SecureSetFilter([\%q1]);
      my @l1=$self->{DataObj}->getHashList("id");
      delete($q1{affectedapplicationid});
      $q1{mandatorid}=\@grpids;
      $self->{DataObj}->ResetFilter();
      $self->{DataObj}->SecureSetFilter([\%q1]);
      my @l2=$self->{DataObj}->getHashList("id");
      delete($q1{mandatorid});
      %q1=%q;
      $q1{id}=[map({$_->{id}} @l1),map({$_->{id}} @l2)];
   }
   if ($self->getParent->IsMemberOf("admin") && $dc eq "TEAM"){
      %q1=%q;
      $q1{stateid}='>15';
      $q1{eventend}=Query->Param("Search_TimeRange");
      $q1{eventend}="<now AND >now-24h" if (!defined($q1{eventend}));
      $q1{class}=[grep(/^.*::eventnotify$/,
                       keys(%{$self->{DataObj}->{SubDataObj}}))];
   }


   $self->{DataObj}->ResetFilter();
   $self->{DataObj}->SecureSetFilter([\%q1]);
   $self->{DataObj}->setDefaultView(qw(linenumber eventstart eventend
                                       name state));
   my %param=(ExternalFilter=>1);
   return($self->{DataObj}->Result(%param));
}



1;
