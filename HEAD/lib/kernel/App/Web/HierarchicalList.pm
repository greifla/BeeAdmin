package kernel::App::Web::HierarchicalList;
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
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   #
   # name und fullname sind zwingend
   # fullname muss ein unique key sein und parentid muss den 
   # Verweis auf den Eltern-Datensatz enthalten
   #
   $self->{PathSeperator}="." if (!defined($self->{PathSeperator}));
   return($self);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $parentid;
   if (defined($oldrec)){
      $parentid=$oldrec->{parentid};
      if (!defined($newrec->{name})){
         $newrec->{name}=$oldrec->{name};
      }
   }
   if (defined($newrec->{parentid})){
      $parentid=$newrec->{parentid};
   }
   if (!defined($parentid)){
      $newrec->{fullname}=$newrec->{name};
      $origrec->{fullname}=$newrec->{name};
   }
   else{
      #load parents fullname
      my $idname=$self->IdField->Name;
      my $pname="";
      if ($parentid ne ""){
         $pname=$self->getVal("fullname",{$idname=>$parentid});
      }
      if ($pname ne ""){
         $newrec->{fullname}=$pname.$self->{PathSeperator}.$newrec->{name};
         $origrec->{fullname}=$pname.$self->{PathSeperator}.$newrec->{name};
      }
      else{
         $newrec->{fullname}=$newrec->{name};
         $origrec->{fullname}=$newrec->{name};
      }
   }
   return(1);
}

sub ValidatedUpdateRecord
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my @filter=@_;
   my $idfield=$self->IdField()->Name();

   return(undef) if (!defined($oldrec) || $#filter!=0 ||
                     keys(%{$filter[0]})!=1 ||
                     !defined($filter[0]->{$idfield}));
   my @updfields=keys(%{$newrec});
   if (!grep(/^fullname$/,@updfields) &&
       !grep(/^name$/,@updfields) &&
       !grep(/^parent$/,@updfields) &&
       !grep(/^parentid$/,@updfields) ){ # just make it simple
      return($self->SUPER::ValidatedUpdateRecord($oldrec,$newrec,@filter));
   }
   my ($worktable,$workdb)=$self->getWorktable();
   $workdb=$self->{DB} if (!defined($workdb));
   my $locktables=$self->{locktables};
   $locktables=$worktable." write" if (!defined($locktables));
   if ($workdb->do("lock tables $locktables")){
      msg(DEBUG,"lock $locktables");
      my @dep=(\%{$oldrec});
      my @loadlist=($oldrec->{$idfield});
      while($#loadlist!=-1){
         $self->SetFilter({parentid=>\@loadlist});
         my @d=$self->getHashList(qw(fullname parentid name));
         @loadlist=();
         foreach my $rec (@d){  # load recursive the full dependency
            push(@loadlist,$rec->{$idfield});
            push(@dep,$rec); 
         }
      }
      my $bak=1;
      my $writefailon=undef;
      for(my $c=0;$c<=$#dep;$c++){
         my $writerec=$dep[$c];
         $writerec=$newrec if ($c==0);
         my $bak=$self->SUPER::ValidatedUpdateRecord($dep[$c],$writerec,
                                            {$idfield=>$dep[$c]->{$idfield}});
         if (!$bak){
            if ($c==0){
               $workdb->do("unlock tables"); 
               return($bak);
            }
            $writefailon=$c;
            last;
         }
      }
      if (defined($writefailon) && $writefailon>0){  #undo 
         for(my $c=0;$c<=$#dep;$c++){
            my $writerec=$dep[$c];
            $self->SUPER::ValidatedUpdateRecord($dep[$c],$writerec,
                                            {$idfield=>$dep[$c]->{$idfield}});
         }
         $workdb->do("unlock tables"); 
         return(undef);
      }
      $workdb->do("unlock tables"); 
     
      return($bak);
   }
   $self->LastMsg(ERROR,"can't lock tables");
   return(undef);
}



1;
