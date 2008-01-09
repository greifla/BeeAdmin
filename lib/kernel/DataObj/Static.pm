package kernel::DataObj::Static;
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
use kernel::DataObj;
use Text::ParseWords;
@ISA = qw(kernel::DataObj);

sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}

sub Initialize
{
   my $self=shift;
   $self->{_permitted}->{data}=1;
   return(1);
}

sub Fields
{
   my $self=shift;
   return(@{$self->{'FieldOrder'}});
}


sub resolvField
{
   my $self=shift;
   my $field=shift;
   my $rec=shift;
   return(undef);
}

sub tieRec
{
   my $self=shift;

   if (defined($self->data->[$self->{'Pointer'}])){
      my %rec;
      tie(%rec,'kernel::DataObj::Static::rec',$self,
          $self->data->[$self->{'Pointer'}]);
      return(\%rec);
   }
   return(undef);

}

sub getOnlyFirst
{
   my $self=shift;
   if (ref($_[0]) eq "HASH"){
      $self->SetFilter($_[0]);
      shift;
   }
   my @view=@_;
   $self->SetCurrentView(@view);
   $self->Limit(1,1);
   my @res=$self->getFirst();
   return(@res);
}


sub getFirst
{
   my $self=shift;
   $self->{'Pointer'}=0;
   while(!($self->CheckFilter()) && 
         defined($self->data->[$self->{'Pointer'}])){ 
      $self->{'Pointer'}++;
   }
   return($self->tieRec());
}

sub getNext
{
   my $self=shift;
   $self->{'Pointer'}++;

   while(!($self->CheckFilter()) && 
         defined($self->data->[$self->{'Pointer'}])){ 
      $self->{'Pointer'}++;
   }
   return($self->tieRec());
}

sub Rows
{
   my $self=shift;

   return(undef);
}

sub CheckFilter
{
   my $self=shift;
   my $rec=$self->tieRec();
   my @flt=$self->getFilterSet();
   return(1) if (!defined($rec));
   return(1) if (!defined($#flt==-1));
   my $failcount=0;
   CHK: foreach my $filter (@flt){
      foreach my $k (keys(%{$filter})){
         if (exists($filter->{$k}) && !defined($filter->{$k})){ # compare on 
            if (!(!defined($rec->{$k}) && exists($rec->{$k}))){ # null entrys
               $failcount=1;
               last CHK;
            }
         }
         elsif (ref($filter->{$k}) eq "SCALAR"){
            if ($rec->{$k} ne ${$filter->{$k}}){
               $failcount=1;
               last CHK;
            }
         }
         elsif (ref($filter->{$k}) eq "ARRAY"){
            my $subcheck=0;
            FLTCHK: foreach my $v (@{$filter->{$k}}){
               if (ref($rec->{$k}) eq "ARRAY"){
                  foreach my $subval (@{$rec->{$k}}){
                     if ($v eq $subval){
                        $subcheck=1;
                        last FLTCHK;
                     }
                  }
               }
               else{
                  if ($v eq $rec->{$k}){
                     $subcheck=1;
                     last FLTCHK;
                  }
               }
            }
            if ($subcheck==0){
               $failcount=1;
               last CHK;
            }
         }
         else{
            my $chk=$filter->{$k};
            my @words=parse_line('[,;]{0,1}\s+',0,$chk);
            if (!($chk=~m/^\s*$/) && $#words==-1){  # maybe an invalid " struct
               $failcount=1;
               last CHK;
            }
            else{
               foreach my $chk (@words){
                  if ($chk=~m/^>/){
                     $chk=~s/^>//;
                     if (!($rec->{$k}>$chk)){
                        $failcount=1;
                        last CHK;
                     }
                  }
                  elsif ($chk=~m/^</){
                     $chk=~s/^<//;
                     if (!($rec->{$k}<$chk)){
                        $failcount=1;
                        last CHK;
                     }
                  }
                  else{
                     $chk=~s/\?/\./g;
                     $chk=~s/\*/\.*/g;
                     if (!($rec->{$k}=~m/^$chk$/i)){
                        $failcount=1;
                        last CHK;
                     }
                  }
               }
            }
         } 
      }
   }
   return(0) if ($failcount); 
   return(1);
}



package kernel::DataObj::Static::rec;
use strict;
use vars qw(@ISA);
use Tie::Hash;

@ISA=qw(Tie::Hash);

sub getParent
{
   return($_[0]->{Parent});
}

sub TIEHASH
{
   my $type=shift;
   my $parent=shift;
   my $rec=shift;
   return(bless({Parent=>$parent,Rec=>$rec},$type));
}

sub FIRSTKEY
{
   my $self=shift;
   $self->{'keylist'}=[$self->getParent->Fields()];
   return(shift(@{$self->{'keylist'}}));
}

sub EXISTS
{
   my $self=shift;
   my $key=shift;
   return(grep(/^$key$/,$self->getParent->Fields()) ? 1:0);
}

sub NEXTKEY
{
   my $self=shift;
   return(shift(@{$self->{'keylist'}}));
}

sub FETCH
{  
   my $self=shift;
   my $key=shift;
   return($self->{Rec}->{$key}) if (exists($self->{Rec}->{$key}));
   my $p=$self->getParent;
   if (defined($p)){
      my $fobj;
      if (!defined($self->{View}->{$key})){
         $fobj=$p->getField($key,$self->{Rec});
      }
      else{
         $fobj=$self->{View}->{$key};
      }
      return($p->RawValue($key,$self->{Rec},$fobj));
   }
   return("- unknown parent for '$key' -");
}





1;
