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
use Text::ParseWords;

@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->{_permitted}->{jsonchanged}=1;      # On Changed Handling
   $self->{_permitted}->{jsoninit}=1;      # On Init Handling
   $self->{allownative}=undef if (!exists($self->{allownative}));
   $self->{useNullEmpty}=0    if (!exists($self->{allownative}));
   return($self);
}

sub getPostibleValues
{
   my $self=shift;
   my $current=shift;
   my $newrec=shift;
   my $mode=shift;
 
   if (defined($self->{getPostibleValues}) &&
       ref($self->{getPostibleValues}) eq "CODE"){
      my $f=$self->{getPostibleValues};
      my @l=&$f($self,$current,$newrec);
      return(&$f($self,$current,$newrec));
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
      my $joinidfieldobj=$self->vjoinobj->getField($self->{vjoinon}->[1]);
      if (!defined($joinidfieldobj)){
         msg(ERROR,"program bug - can not find field ".$self->{vjoinon}->[1]);
         exit(1);
      }
      my $joinidfield=$joinidfieldobj->Name();
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
   my $readonly=$self->readonly($current);
   if (($mode eq "workflow" || $mode eq "edit" ) 
       && !($readonly)){
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
      my $disabled="";


      my $s="<select id=\"$name\" name=\"Formated_$name\"";
      if ($self->{multisize}>0){
         $s.=" multiple";
         $s.=" size=\"$self->{multisize}\"";
      }
      if (defined($self->{jsonchanged})){
         $s.=" onchange=\"jsonchanged_$name('onchange');\"";
      }
      $s.=" class=\"finput\" style=\"width:$width\">";
      my @options=$self->getPostibleValues($current,undef,"edit");
      while($#options!=-1){
         my $key=shift(@options);
         my $val=shift(@options);
         $s.="<option value=\"$key\"";
         my $qkey=quotemeta($key);
         my $qval=quotemeta($val);
         $s.=" selected" if (($qkey ne "" && grep(/^$qkey$/,@{$d})) || 
                             ($qval ne "" && grep(/^$qval$/,@{$d})));
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
   if ($mode eq "HtmlDetail"){
      $res.=" ".$self->{unit} if (defined($self->{unit}));
   }

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
      my @options=$fobj->getPostibleValues(undef,undef);
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
            if (defined($chk)){
               foreach my $v (keys(%tr)){
                  push(@newsearch,$tr{$v}) if ($v eq $chk ||
                                               $tr{$v} eq $chk);
               }
            }
            else{
               push(@newsearch,undef);
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
            my $neg=0;
            if ($chk=~m/^!/){
               $neg++;
               $chk=~s/^!//;
            }
            my $qchk='^'.quotemeta($chk).'$';
            $qchk=~s/\\\*/\.*/g;
            $qchk=~s/\\\?/\./g;
            if ($chk eq "[LEER]" || $chk eq "[EMPTY]" ){
               if ($neg){
                  push(@newsearch,keys(%tr),keys(%raw));
               }
               else{
                  push(@newsearch,undef);
               }
            }
            else{
               if ($neg){
                  push(@newsearch,grep(!/$chk$/i,keys(%tr),keys(%raw)));
               }
               else{
                  foreach my $v (keys(%tr)){
                     if ($v=~m/$qchk/i || $tr{$v} eq $chk){
                        if (!grep(/^$tr{$v}$/,@newsearch)){
                           push(@newsearch,$tr{$v});
                        }
                     }
                  }
                  foreach my $v (keys(%raw)){
                     if ($v=~m/$qchk/i || $tr{$v} eq $chk){
                        if (!grep(/^$raw{$v}$/,@newsearch)){
                           push(@newsearch,$raw{$v});
                        }
                     }
                  }
               }
            }
         }
      }
      $hflt->{$field}=\@newsearch;
   }
   my ($subchanged,$suberr)=$self->SUPER::preProcessFilter($hflt);
   return($subchanged+$changed,$err);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $name=$self->{name};
   if (exists($newrec->{$name})){
      my $val=$newrec->{$name};
      if (($val eq "" || (ref($val) eq "ARRAY" && $#{$val}==-1)) 
          && $self->{allowempty}==1){
         if ($self->{useNullEmpty}){
            return({$self->Name()=>undef});
         }
         return({$self->Name()=>$val});
     
      }
      else{
         my @options=$self->getPostibleValues($oldrec,$newrec,"edit");
         my @nativ=@options;
         my %backmap=();
         while($#options!=-1){
            my $key=shift(@options);
            my $val=shift(@options);
            $backmap{$val}=$key;
         }
         my $failfound=0;
         my $chkval=$val;
         my $chkval=[$chkval] if (ref($chkval) ne "ARRAY");
         if (ref($self->{allownative}) eq "ARRAY"){
            push(@nativ,@{$self->{allownative}});
         }
         foreach my $v (@$chkval){
            my $qv=quotemeta($v);
            if (!grep(/^$qv$/,@nativ)){
               $failfound++;
               last;
            }
         }
         if ($self->{allownative} eq "1"){
            $failfound=0;
         }
         if (!$failfound){
            if (defined($self->{dataobjattr}) || defined($self->{container}) ||
                defined($self->{onFinishWrite})){
               return({$self->Name()=>$val});
            }
            else{
               if (defined($self->{vjointo}) &&
                   defined($self->{vjoinon}) &&
                   ref($self->{vjoinon}) eq "ARRAY"){
                  return({$self->{vjoinon}->[0]=>$backmap{$val}});
               }
               $self->getParent->LastMsg(ERROR,"invalid write request ".
                                               "to Select field '$name'");
               return(undef); 
            }
         }
         else{
            $self->getParent->LastMsg(ERROR,"invalid native value ".
                                            "'$val' in $name");
         }
         return(undef);
      }
   }
   return({});
}

sub FormatedResult
{
   my $self=shift;
   my $current=shift;
   my $FormatAs=shift;
   my $d=$self->RawValue($current);
   if (!defined($d)){
      if (defined($self->{value}) && in_array($self->{value},undef)){
         $d=[undef];
      }
      else{
         $d=[];
      }
   }
   $d=[$d] if (ref($d) ne "ARRAY");
  
   if (defined($self->{getPostibleValues}) &&
       ref($self->{getPostibleValues}) eq "CODE"){
      my %opt=&{$self->{getPostibleValues}}($self,$current,undef);
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
      my @options=$self->getPostibleValues($oldrec,$newrec,"edit");
      my @o=@options;
      if ($self->{multisize}>0){  # multivalue selects
         $reqval=[split(/[,;]\s+/,$reqval)] if (ref($reqval) ne "ARRAY");
         $newkey=[];
         if ($#{$reqval}!=-1){
            foreach my $strval (@$reqval){
               my @o=@options;
               my $kval;
               while($#o!=-1){   # pass 1 check if value  matches
                  my $key=shift(@o);
                  my $val=shift(@o);
                  if ($val eq $strval){
                     $kval=$key;
                     last;
                  }
               }
               if (!defined($kval)){
                  print msg(ERROR,
                          $self->getParent->T("no matching value '\%s' ".
                                              "in field '\%s'"),
                        $strval,$name);
                  return(0);
               }
               push(@$newkey,$kval);
            }
         }
      }
      else{
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
      }
      if (!defined($newkey)){
 
         print msg(ERROR,
                 $self->getParent->T("no matching value '\%s' in field '\%s'"),
               $reqval,$name);
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
