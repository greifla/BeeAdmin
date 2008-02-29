package kernel::Field::Select;
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
use Text::ParseWords;

@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->{_permitted}->{jsonchanged}=1;      # On Changed Handling
   return($self);
}

sub getPostibleValues
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
 
   if (defined($self->{getPostibleValues}) &&
       ref($self->{getPostibleValues}) eq "CODE"){
      my $f=$self->{getPostibleValues};
      my @l=&$f($self,$current);
      return(&$f($self,$current));
   }

   if (defined($self->{value}) && ref($self->{value}) eq "ARRAY"){
      my @l=();
   #   map({
   #          my $kval=$_;
   #          my $dispname=$kval;
   #          if (defined($self->{transprefix})){
   #             my $tdispname=$self->{transprefix}.$kval;
   #             my $tr=$self->{translation};
   #             $tr=$self->getParent->Self() if (!defined($tr));
   #             my $newdisp=$self->getParent->T($tdispname,$tr);
   #             if ($tdispname ne $newdisp){
   #                $dispname=$newdisp;
   #             }
   #          }
   #          push(@l,$kval,$dispname);
   #       } @{$self->{value}});
      map({push(@l,$_,$_);} @{$self->{value}});
      if ($self->{allowempty}==1){
         unshift(@l,"","");
      }
      return(@l);
   }
   if (defined($self->{vjointo})){
      $self->vjoinobj->ResetFilter();
      if ($mode eq "edit"){
         if (defined($self->{vjoineditbase})){
            $self->vjoinobj->SetNamedFilter("editbase",$self->{vjoineditbase});
         }
      }
      #$self->vjoinobj->SetFilter({$self->{vjoinon}->[1]=>
      #                           [$joinonval]});
     # my $joinidfield=$self->vjoinobj->IdField->Name();
      my $joinidfield=$self->vjoinobj->getField($self->{vjoinon}->[1])->Name();
      my @view=($self->{vjoindisp},$joinidfield);
      my @l=$self->vjoinobj->getHashList(@view); 
      my @res=(); 
      map({push(@res,$_->{$joinidfield},$_->{$self->{vjoindisp}})} @l);
      if ($self->{allowempty}==1){
         unshift(@res,"","[none]");
      }
      return(@res);
   }
   return();
}

sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $d=$self->RawValue($current);
   my $name=$self->Name();
   $d=[$d] if (ref($d) ne "ARRAY");
   if (($mode eq "workflow" || $mode eq "edit" ) 
       && !($self->readonly($current))){
      my @fromquery=Query->Param("Formated_$name");
      if (defined($self->{vjointo}) && defined($self->{vjoinon})){
         $d=$current->{$self->{vjoinon}->[0]};
      }
      $d=[$d] if (ref($d) ne "ARRAY");
      if (defined(@fromquery)){
         $d=\@fromquery;
      }
      if (($#{$d}==-1 && defined($self->default))||
          ($#{$d}==0 && !defined($d->[0]))){
         $d=[$self->default];
      }
      my $width="100%";
      $width=$self->{htmleditwidth} if (defined($self->{htmleditwidth}));
      my $s="<select name=Formated_$name";
      if ($self->{multisize}>0){
         $s.=" multiple";
         $s.=" size=$self->{multisize}";
      }
      if (defined($self->{jsonchanged})){
         $s.=" onchange=\"jsonchanged_$name('onchange');\"";
      }
      $s.=" style=\"width:$width\">";
      my @options=$self->getPostibleValues($current,"edit");
      while($#options!=-1){
         my $key=shift(@options);
         my $val=shift(@options);
         $s.="<option value=\"$key\"";
         my $qkey=quotemeta($key);
         $s.=" selected" if (grep(/^$qkey$/,@{$d}));
         $s.=">".$self->getParent->T($self->{transprefix}.$val,
                                     $self->{translation})."</option>";
      }

      $s.="</select>";
      if (defined($self->{jsonchanged})){
         $s.="<script language=\"JavaScript\">".
             "function jsonchanged_$name(mode){".
             $self->jsonchanged."}".  
             "</script>";
      }
      return($s);
   }
   my $res=$self->FormatedResult($current,$mode);
   $res=[$res] if (ref($res) ne "ARRAY");
   if ($mode eq "HtmlDetail"){
      $res=[map({$self->addWebLinkToFacility($_,$current)} @{$res})];
   }
   $res=join($self->{vjoinconcat},@$res);

   return($res);
}

sub preProcessFilter
{
   my $self=shift;
   my $hflt=shift;
   my $fobj=$self;
   my $field=$self->Name();
   my $changed=0;
   my $err;

   if (!defined($self->{vjointo})){
      my $oldval=$hflt->{$field};
      my @options=$fobj->getPostibleValues();
      my %tr=();
      my %raw=();
      my @to=@options;
      while(defined(my $key=shift(@to))){
         my $val=shift(@to);
         $raw{$val}=$key;
         my $trval=$val;
         if (defined($self->{transprefix})){
            $trval=$self->{transprefix}.$trval;
         }
         my $tropt=$self->getParent->T($trval,$fobj->{translation});
         $tr{$tropt}=$key;
      }
      my @newsearch=();
      if (ref($oldval) eq "ARRAY"){
         foreach my $chk (@{$oldval}){
            foreach my $v (keys(%tr)){
               push(@newsearch,$tr{$v}) if ($v eq $chk ||
                                            $tr{$v} eq $chk);
            }
         }
      }
      elsif (ref($oldval) eq "SCALAR"){
         if (keys(%tr)!=0){
            foreach my $v (keys(%tr)){
               push(@newsearch,$tr{$v}) if ($v eq ${$oldval} ||
                                            $tr{$v} eq ${$oldval});
            }
         }
         else{
            push(@newsearch,${$oldval});
         }
      }
      else{
         my $procoldval=trim($oldval);
         my @chklist=parse_line(',{0,1}\s+',0,$procoldval);
         foreach my $chk (@chklist){
            my $qchk='^'.quotemeta($chk).'$';
            $qchk=~s/\\\*/\.*/g;
            $qchk=~s/\\\?/\./g;
            foreach my $v (keys(%tr)){
               if ($v=~m/$qchk/i || $tr{$v} eq $chk){
                  push(@newsearch,$tr{$v}) if (!grep(/^$tr{$v}$/,@newsearch));
               }
            }
            foreach my $v (keys(%raw)){
               if ($v=~m/$qchk/i || $tr{$v} eq $chk){
                  push(@newsearch,$raw{$v}) if (!grep(/^$raw{$v}$/,@newsearch));
               }
            }
         }
      }
      $hflt->{$field}=\@newsearch;
   }
   my ($subchanged,$suberr)=$self->SUPER::preProcessFilter($hflt);
   return($subchanged+$changed,$err);
}

sub FormatedResult
{
   my $self=shift;
   my $current=shift;
   my $FormatAs=shift;
   my $d=$self->RawValue($current);
   $d=[]   if (!defined($d));
   $d=[$d] if (ref($d) ne "ARRAY");
  
   if (defined($self->{getPostibleValues}) &&
       ref($self->{getPostibleValues}) eq "CODE"){
      my %opt=&{$self->{getPostibleValues}}($self,$current);
      return(join(", ",map({ defined($opt{$_}) ? $opt{$_} : '?'; } @{$d})));
   }
   return(join(", ",map({
        $self->getParent->T($self->{transprefix}.$_,$self->{translation})
                        } @{$d})));
}


sub Unformat
{
   my $self=shift;
   my $formated=shift;
   my $rec=shift;
   my $r={};
   $formated=[$formated] if (ref($formated) ne "ARRAY");
   if (defined($formated)){
      if (defined($self->{container}) || defined($self->{dataobjattr})){
         return($self->SUPER::Unformat($formated,$rec));
      }
      elsif (defined($self->{vjoinon})){
         $r->{$self->{vjoinon}->[0]}=$formated->[0];
      }
      else{
         $r->{$self->Name()}=$formated;
      }
      if ($self->{allowempty}==1){
         $r->{$self->Name()}=undef if ($r->{$self->Name()} eq "");
      }
   }
   return($r);
}

sub prepUploadRecord   # prepair one record on upload
{
   my $self=shift;
   my $newrec=shift;
   my $oldrec=shift;
   my $name=$self->Name();
   if (defined($newrec->{$name})){
      my $reqval=$newrec->{$name};
      my $newkey;
      my @options=$self->getPostibleValues($oldrec,"edit");
      my @o=@options;
      while($#o!=-1){   # pass 1 check if value  matches
         my $key=shift(@o);
         my $val=shift(@o);
         if ($val eq $reqval){
            $newkey=$key;
            last;
         }
      }
      if (!defined($newkey)){
         my @o=@options;
         while($#o!=-1){  # pass 1 check if value (translated) matches
            my $key=shift(@o);
            my $val=shift(@o);
            if ($self->getParent->T($self->{transprefix}.$val,
                  $self->{translation}) eq $reqval){
               $newkey=$key;
               last;
            }
         }
         if (!defined($newkey)){
            my @o=@options;
            while($#o!=-1){  # pass 1 check if key direct matches
               my $key=shift(@o);
               my $val=shift(@o);
               if ($key eq $reqval){
                  $newkey=$key;
                  last;
               }
            }
         }
      }
      if (!defined($newkey)){
         print msg(ERROR,"no matching value '%s' in field $name",$reqval);
         return(0);
      }
      else{
         if (defined($self->{vjoinon})){
            delete($newrec->{$name});
            $newrec->{$self->{vjoinon}->[0]}=$newkey;
         }
         else{
            $newrec->{$name}=$newkey;
         }
      }
   }
   return(1);
}




1;
