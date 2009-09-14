package kernel::Field::Container;
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
   my %self=(@_);
   $self{uivisible}=0 if (!defined($self{uivisible}));
   my $self=bless($type->SUPER::new(%self),$type);
   $self->{WSDLfieldType}="Container" if (!defined($self->{WSDLfieldType}));
   return($self);
}


sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $d=$self->RawValue($current);
   my $name=$self->Name();
   if ($mode eq "SOAP"){
      my $xml;
      if (ref($d) eq "HASH"){
         foreach my $k (sort(keys(%$d))){
            my $val=$d->{$k};
            $val=[$val] if (ref($val) ne "ARRAY");
            foreach my $vval (@$val){
               $xml.="<item><name>$k</name><value>".
                     quoteSOAP($vval)."</value></item>";
            }
         }
      }
      return($xml);
   }
   if ($mode=~m/html/i){
      if (defined($d) && ref($d) eq "HASH" && keys(%{$d})>0){
         my $r="<table class=containerframe>"; 
         foreach my $k (sort(keys(%{$d}))){
            $r.="<tr>"; 
            my $descwidth="width=1%";
            if (defined($self->{desccolwidth})){
               $descwidth="width=$self->{desccolwidth}"; 
            }
            $r.="<td class=containerfname $descwidth valign=top>$k</td>"; 
            my $dd=join(", ",@{$d->{$k}});
            $dd="&nbsp;" if ($dd=~m/^\s*$/);
            #$dd=~s/\n/<br>\n/g;
            if ($dd=~m/\n/ || $dd=~m/\S{40}/){
               $dd="<table ".
                  "style=\"width:100%;table-layout:fixed;padding:0;margin:0\">".
                   "<tr><td><div class=multilinetext ".
                   "style=\"height:auto;border-style:none\">".
                   "<pre class=multilinetext>$dd</pre></div></td></tr></table>";
            }
            $r.="<td class=containerfval valign=top>$dd</td>"; 
            $r.="</tr>"; 
         }
         $r.="</table>"; 
         return($r);
      }
      return(undef);
   }
   return($d);
}

sub RawValue
{
   my $self=shift;
   my $current=shift;

   if (ref($current->{$self->Name}) ne "HASH"){
      my %h=Datafield2Hash($current->{$self->Name});
      $current->{$self->Name}=\%h;
   #   printf STDERR ("fifi RawValue=%s\n",Dumper($current->{$self->Name}));
   }
   return($current->{$self->Name});
}

sub finishWriteRequestHash
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $changed=0;
   my $p=$self->getParent;

   my %oldcopy;
   %oldcopy=%{$self->RawValue($oldrec)} if (defined($oldrec));
   my $oldhash=\%oldcopy; 
   foreach my $fo ($p->getFieldObjsByView([$p->getCurrentView()],
                                          current=>$newrec,oldrec=>$oldrec)){
      if (defined($fo->{container}) && $fo->{container} eq $self->Name()){
         if (exists($newrec->{$fo->Name()})){
            $oldhash->{$fo->Name()}=$newrec->{$fo->Name()};
            delete($newrec->{$fo->Name()});
            $changed=1;
         }
      }
   }
   if (ref($newrec->{$self->Name}) eq "HASH"){
      $newrec->{$self->Name}=Hash2Datafield(%{$newrec->{$self->Name}}); 
   }
   if ($changed){
      $newrec->{$self->Name}="" if (!defined($newrec->{$self->Name}));
      $newrec->{$self->Name}.=Hash2Datafield(%{$oldhash});
   }
   # preparing the hash - > todo

   return(undef);
}

sub copyFrom
{
   my $self=shift;
   my $oldrec=shift;
   return(undef);
}


sub fields
{
   my $self=shift;
   my %param=@_;
   my $name=$self->Name();
   my @fl;
   if (defined($param{current})){
      if (defined($param{current}->{$name})){
         if (ref($param{current}->{$name}) ne "HASH"){
            my %h=Datafield2Hash($param{current}->{$name});
            $param{current}->{$name}=\%h;
         }
         foreach my $k (keys(%{$param{current}->{$name}})){
            push(@fl, new kernel::Field::Text(
                              name       =>$k,
                              label      =>$k,
                              container  =>$name));
         }
      }   
   }
   return($self->getParent->InitFields(@fl));
}








1;
