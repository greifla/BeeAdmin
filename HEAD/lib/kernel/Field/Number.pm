package kernel::Field::Number;
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
use Data::Dumper;
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->{_permitted}->{precision}=1;
   return($self);
}

sub RawValue
{
   my $self=shift;
   my $d=$self->SUPER::RawValue(@_);
   if (defined($d)){    # normalisierung, damit die Daten intern immer
      $d=~s/,/./g;      # mit . als dezimaltrenner behandelt werden
   }
   return($d);
}


sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $d=$self->RawValue($current);
   my $name=$self->Name();
   if ($mode eq "HtmlSubList" || $mode eq "HtmlV01" || $mode eq "HtmlDetail"){
      if (defined($d)){
         my $format=sprintf("%%.%df",$self->{precision});
         $d=sprintf($format,$d);
         $d=~s/\./,/g;
         $d.=" ".$self->{unit} if ($d ne "" && $mode eq "HtmlDetail");
      }
      return($d);
   }
   if (($mode eq "edit" || $mode eq "workflow") && 
       !defined($self->{vjointo})){
      my $readonly=0;
      if ($self->{readonly}==1){
         $readonly=1;
      }
      if (defined($d)){
         my $format=sprintf("%%.%df",$self->{precision});
         $d=sprintf($format,$d);
         $d=~s/\./,/g;
      }
      my $fromquery=Query->Param("Formated_$name");
      if (defined($fromquery)){
         $d=$fromquery;
      }
      return($self->getSimpleTextInputField($d,$readonly));
   }
   return($d);
}

sub Unformat
{
   my $self=shift;
   my $formated=shift;
   my $rec=shift;
   printf STDERR ("fifi unformat of %s = %s\n",$self->Name(),Dumper($formated));
   if (defined($formated)){
      return(undef) if (!defined($formated->[0]));
      $formated=trim($formated->[0]) if (ref($formated) eq "ARRAY");
      return({$self->Name()=>undef}) if ($formated eq "");
      my $d=$formated;
      my $precision=$self->precision;
      $precision=0 if (!defined($precision));
      if (!($d=~s/(\d+)[,\.]{0,1}([0-9]{0,$precision})[0-9]*$/$1\.$2/)){
         $self->getParent->LastMsg(ERROR,
             sprintf(
                $self->getParent->T("invalid number format '%s' in field '%s'",
                   $self->Self),$d,$self->Label()));
         printf STDERR ("error\n");
         return(undef);
      }
      $d=~s/\.$//;
      printf STDERR ("fifi formated=%s d=$d\n",Dumper($formated));
     # if ($formated ne "" && $d eq ""){
     #    return(undef);
     # }

      return({$self->Name()=>$d});
   }
   return({});
}


sub getXLSformatname
{
   my $self=shift;
   my $data=shift;
   return("number.".$self->precision());
}











1;
