package kernel::Field;
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
use kernel::Field::Id;
use kernel::Field::Text;
use kernel::Field::Password;
use kernel::Field::Phonenumber;
use kernel::Field::File;
use kernel::Field::Float;
use kernel::Field::Currency;
use kernel::Field::Number;
use kernel::Field::Percent;
use kernel::Field::Email;
use kernel::Field::Link;
use kernel::Field::DynWebIcon;
use kernel::Field::Interface;
use kernel::Field::Linenumber;
use kernel::Field::TextDrop;
use kernel::Field::MultiDst;
use kernel::Field::Textarea;
use kernel::Field::Htmlarea;
use kernel::Field::GoogleMap;
use kernel::Field::GoogleAddrChk;
use kernel::Field::ListWebLink;
use kernel::Field::Select;
use kernel::Field::Boolean;
use kernel::Field::SubList;
use kernel::Field::ContactLnk;
use kernel::Field::PhoneLnk;
use kernel::Field::FileList;
use kernel::Field::WorkflowRelation;
use kernel::Field::TimeSpans;
use kernel::Field::Date;
use kernel::Field::MDate;
use kernel::Field::CDate;
use kernel::Field::Owner;
use kernel::Field::Creator;
use kernel::Field::Editor;
use kernel::Field::RealEditor;
use kernel::Field::Import;
use kernel::Field::Dynamic;
use kernel::Field::Container;
use kernel::Field::KeyHandler;
use kernel::Field::KeyText;
use kernel::Field::Mandator;
use kernel::Field::Duration;
use kernel::Field::Message;
use kernel::Field::QualityText;
use kernel::Field::QualityState;
use kernel::Field::QualityOk;
use kernel::Field::QualityLastDate;
use kernel::Field::Fulltext;
use kernel::Universal;
@ISA    = qw(kernel::Universal);

sub new
{
   my $type=shift;
   my $self={@_};
   $self=bless($self,$type);
   $self->{group}="default" if (!defined($self->{group}));
   $self->{_permitted}->{mainsearch}=1; # erzeugt gro�es Suchfeld
   $self->{_permitted}->{searchable}=1; # stellt das Feld als suchfeld dar
   $self->{_permitted}->{defsearch}=1;  # automatischer Focus beim Suchen
   $self->{_permitted}->{selectable}=1; # Feld kann im select statement stehen
   $self->{_permitted}->{fields}=1;     # Feld erzeugt dynamisch zus�tzl. Felder
   $self->{_permitted}->{align}=1;      # Ausrichtung
   $self->{_permitted}->{valign}=1;
   $self->{_permitted}->{htmlwidth}=1;  # Breite in der HTML Ausgabe (Spalten)
   $self->{_permitted}->{xlswidth}=1;   # Breite in der XLS Ausgabe (Spalten)
   $self->{_permitted}->{uivisible}=1;  # Anzeige in der Detailsicht bzw. Listen
   $self->{_permitted}->{history}=1;    # �ber das Feld braucht History
   $self->{_permitted}->{htmldetail}=1; # Anzeige in der Detailsicht
   $self->{_permitted}->{translation}=1;# �bersetzungsbasis f�r Labels
   $self->{_permitted}->{selectfix}=1;  # ?
   $self->{_permitted}->{default}=1;    # Default value on new records
   $self->{_permitted}->{unit}=1;       # Unit prefix in detail view
   $self->{_permitted}->{label}=1;      # Die Beschriftung des Felds
   $self->{_permitted}->{readonly}=1;   # Nur zum lesen
   $self->{_permitted}->{frontreadonly}=1;   # Nur zum lesen
   $self->{_permitted}->{grouplabel}=1; # 1 wenn in HTML Detail Grouplabel soll
   $self->{_permitted}->{dlabelpref}=1; # Beschriftungs prefix in HtmlDetail
   $self->{searchable}=1 if (!defined($self->{searchable}));
   $self->{selectable}=1 if (!defined($self->{selectable}));
   $self->{htmldetail}=1 if (!defined($self->{htmldetail}));
   if (!defined($self->{selectfix})){
      $self->{selectfix}=0;
   }
   if (!defined($self->{uivisible}) && $self->{selectable}){
      $self->{uivisible}=1;
   }
   if (!defined($self->{history})){
      $self->{history}=1;
   }
   if (!defined($self->{valign})){
      $self->{valign}="center";
   }
   if (!defined($self->{grouplabel})){
      $self->{grouplabel}=1;
   }
   if (!defined($self->{uivisible}) && !$self->{selectable}){
      $self->{uivisible}=0;
   }
   if (defined($self->{vjointo})){
      $self->{vjoinconcat}="; " if (!defined($self->{vjoinconcat}));
      $self->{_permitted}->{vjoinconcat}=1;# Verkettung der Ergebnisse
      if (!defined($self->{weblinkto})){
         $self->{weblinkto}=$self->{vjointo};
      }
      if (!defined($self->{weblinkon})){
         $self->{weblinkon}=$self->{vjoinon};
      }
   }
   return($self);
}

sub addWebLinkToFacility
{
   my $self=shift;
   my $d=shift;
   my $current=shift;

   my $weblinkon=$self->{weblinkon};
   my $weblinkto=$self->{weblinkto};
   if (ref($weblinkto) eq "CODE"){
      ($weblinkto,$weblinkon)=&{$weblinkto}($self,$d,$current);
   }

   if (defined($weblinkto) && defined($weblinkon) && $weblinkto ne "none"){
      my $target=$weblinkto;
      $target=~s/::/\//g;
      $target="../../$target/Detail";
      my $targetid=$weblinkon->[1];
      my $targetval;
      if (!defined($targetid)){
         $targetid=$weblinkon->[0];
         $targetval=$d;
      }
      else{
         my $linkfield=$self->getParent->getField($weblinkon->[0]);
         if (!defined($linkfield)){
            msg(ERROR,"can't find field '%s' in '%s'",$weblinkon->[0],
                $self->getParent);
            return($d);
         }
         $targetval=$linkfield->RawValue($current);
      }
      if (defined($targetval) && $targetval ne ""){
         my $detailx=$self->getParent->DetailX();
         my $detaily=$self->getParent->DetailY();
         $targetval=$targetval->[0] if (ref($targetval) eq "ARRAY");
         my $onclick="openwin(\"$target?".
                     "AllowClose=1&search_$targetid=$targetval\",".
                     "\"_blank\",".
                     "\"height=$detaily,width=$detailx,toolbar=no,status=no,".
                     "resizable=yes,scrollbars=no\")";
         $d="<a class=sublink href=JavaScript:$onclick>".$d."</a>";
      }
   }
   return($d);
}

sub getSimpleTextInputField
{
   my $self=shift;
   my $value=shift;
   my $readonly=shift;
   my $name=$self->Name();
   $value=~s/"/&quot;/g;
   my $d;

   my $unit=$self->unit;
   $unit="<td width=40>$unit</td>" if ($unit ne "");
   if (!$readonly){
      my $width="100%";
      $width=$self->{htmleditwidth} if (defined($self->{htmleditwidth}));
      $d=<<EOF;
<table style="table-layout:fixed;width:$width" cellspacing=0 cellpadding=0>
<tr><td>
<input type=text value="$value" name=Formated_$name class=finput>
</td>$unit</tr></table>
EOF
   }
   else{
      $d=<<EOF;
<table style="table-layout:fixed;width:100%" cellspacing=0 cellpadding=0>
<tr><td>
<span class="readonlyinput">$value</span>
</td>$unit</tr></table>
EOF
   }
   return($d);
}




sub label
{
   my $self=shift;
   return(&{$self->{label}}($self)) if (ref($self->{label}) eq "CODE");
   return($self->{label});
}

sub Name()
{
   my $self=shift;
   return($self->{name});
}

sub Type()
{
   my $self=shift;
   my ($type)=$self=~m/::([^:]+)=.*$/;
   return($type);
}

sub UiVisible
{
   my $self=shift;
   my $mode=shift;
   my %param=@_;
   if (ref($self->{uivisible}) eq "CODE"){
      return(&{$self->{uivisible}}($self,$mode,%param));
   }
   return($self->{uivisible});
}

sub Uploadable
{
   my $self=shift;
   my %param=@_;
   if (ref($self->{uploadable}) eq "CODE"){
      return(&{$self->{uploadable}}($self,%param));
   }
   return(0) if (!$self->UiVisible("ViewEditor"));
   return(0) if ($self->readonly);
   return(0) if ($self->{name} eq "srcid");
   return(0) if ($self->{name} eq "srcsys");
   return(0) if ($self->{name} eq "srcload");
   return(1);
}

sub DefaultValue
{
   my $self=shift;
   my $newrec=shift;
   if (ref($self->{default}) eq "CODE"){
      return(&{$self->{default}}($self,$newrec));
   }
   return($self->{default});
}


sub FieldCache
{
   my $self=shift;
   my $pc=$self->getParent->Context;
   my $fieldkey="FieldCache:".$self->Name();
   $pc->{$fieldkey}={} if (!defined($pc->{$fieldkey}));
   return($pc->{$fieldkey});
}

sub vjoinobj
{
   my $self=shift;
   return(undef) if (!exists($self->{vjointo}));
   my $jointo=$self->{vjointo};
   my $joinparam=$self->{vjoinparam};
   ($jointo,$joinparam)=&{$jointo}($self) if (ref($jointo) eq "CODE");
   $self->{joincache}={} if (!defined($self->{joincache}));

   if (!defined($self->{joincache}->{$jointo})){
      #msg(INFO,"create of '%s'",$jointo);
      my $o=getModuleObject($self->getParent->Config,$jointo,$joinparam);
      #msg(INFO,"o=$o");
      $self->{joincache}->{$jointo}=$o;
      $self->{joincache}->{$jointo}->setParent($self->getParent);
   }
   $self->{joinobj}=$self->{joincache}->{$jointo};
   return($self->{joinobj});
}

sub vjoinContext
{
   my $self=shift;
   return(undef) if (!defined($self->{vjointo}));
   my $context=$self->{vjointo}.";".join(",",@{$self->{vjoinon}});
   if (defined($self->{vjoinbase})){
#printf STDERR ("fifi vjoinbase=%s on %s\n",$self->{vjoinbase},$self->Name());
      my @l;
      @l=@{$self->{vjoinbase}} if (ref($self->{vjoinbase}) eq "ARRAY");
      @l=%{$self->{vjoinbase}} if (ref($self->{vjoinbase}) eq "HASH");
      $context.="+".join(",",@l);
   }
   return($context);
}

sub Size     # returns the size in chars if any defined
{
   my $self=shift;
   return($self->{size});
}

sub Label
{
   my $self=shift;
   my $label=$self->{label};
   my $d="-NoLabelSet-";
   $d=$label if ($label ne "");
   return($self->getParent->T($d,$self->{translation}));
}

sub rawLabel
{
   my $self=shift;
   my $label=$self->{label};
   my $d="-NoLabelSet-";
   $d=$label if ($label ne "");
   return($d);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $currentstate=shift;   # current state of write record

   if (!exists($newrec->{$self->Name()})){
      if (!defined($oldrec)){
         my $def=$self->DefaultValue($newrec);
         if (defined($def)){
            return({$self->Name()=>$def});
         }
      }
      return({});
   }
   return({$self->Name()=>$newrec->{$self->Name()}});
}

sub copyFrom
{
   my $self=shift;
   my $oldrec=shift;
   my $oldval=$self->RawValue($oldrec);
   return($oldval);
}

sub finishWriteRequestHash
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(undef);
}

sub prepareToSearch
{
   my $self=shift;
   my $filter=shift;
   return($filter);
}

sub preProcessFilter
{
   my $self=shift;
   my $hflt=shift;
   my $fobj=$self;
   my $field=$self->Name();
   my $changed=0;
   my $err;

   if (defined($self->{onPreProcessFilter}) &&
       ref($self->{onPreProcessFilter}) eq "CODE"){
      return(&{$self->{onPreProcessFilter}}($self,$hflt));
   }
   if (defined($fobj->{vjointo})){
      my $loadfield=$fobj->{vjoinon}->[1];
      my $searchfield=$fobj->{vjoindisp};
      if (ref($fobj->{vjoindisp}) eq "ARRAY"){
         $searchfield=$fobj->{vjoindisp}->[0];
      }
      my %flt=($searchfield=>$hflt->{$field});
      $fobj->vjoinobj->ResetFilter();
      $fobj->vjoinobj->SetFilter(\%flt);
      if (defined($hflt->{$fobj->{vjoinon}->[0]})){
         $fobj->vjoinobj->SetNamedFilter("vjoinadd".$field,
                      {$fobj->{vjoinon}->[1]=>$hflt->{$fobj->{vjoinon}->[0]}});
      }


      $fobj->vjoinobj->SetCurrentView($fobj->{vjoinon}->[1]);
      delete($hflt->{$field});
      my $d=$fobj->vjoinobj->getHashIndexed($fobj->{vjoinon}->[1]);
      my @keylist=keys(%{$d->{$fobj->{vjoinon}->[1]}});
      if ($#keylist==-1){
         if ($flt{$searchfield} eq "[LEER]" || $flt{$searchfield} eq "[EMPTY]"){
            @keylist=(undef,"") if ($#keylist==-1);
         }
         else{
            @keylist=(-99) if ($#keylist==-1);
         }
      }
      $hflt->{$fobj->{vjoinon}->[0]}=\@keylist;
      if ($fobj->{vjoinon}->[0] ne $self->Name()){
         $changed=1;
      }
   }
   return($changed,$err);
}


sub Unformat
{
   my $self=shift;
   my $formated=shift;
   my $rec=shift;

   if (defined($self->{onUnformat}) && ref($self->{onUnformat}) eq "CODE"){
      return(&{$self->{onUnformat}}($self,$formated,$rec));
   }
   return({}) if ($self->readonly);
   if ($#{$formated}>0){
      return({$self->Name()=>$formated});
   }
   return({$self->Name()=>$formated->[0]});
}

sub prepUploadRecord   # prepair one record on upload
{
   my $self=shift;
   my $newrec=shift;
   my $oldrec=shift;
   return(1);
}


sub getSelectField     # returns the name/function to place in select
{
   my $self=shift;
   my $mode=shift;
   my $db=shift;

   if ($mode eq "select" || $mode=~m/^where\..*/){
      return(undef) if (!defined($self->{dataobjattr}));
      if (ref($self->{dataobjattr}) eq "ARRAY"){
         $_=$db->DriverName();
         case: {
            /^mysql$/i and do {
               return("concat(".join(",'-',",@{$self->{dataobjattr}}).")");
               return(undef); # noch todo
            };
            /^oracle$/i and do {
               return(undef); # noch todo
            };
            /^odbc$/i and do {
               return(join("+'-'+",
                           map({"'\"'+rtrim(ltrim(convert(char,$_)))+'\"'"} 
                           @{$self->{dataobjattr}})));
            };
            do {
               msg(ERROR,"conversion for date on driver '$_' not ".
                         "defined ToDo!");
               return(undef);
            };
         }
      }
      if ($mode eq "select" && $self->{noselect}){
         return(undef);
      }
      if ($mode eq "select" || $mode eq "where.select"){ 
         if (defined($self->{altdataobjattr})){
            $_=$db->DriverName();
            case: {
               /^mysql$/i and do {
                  my $f="if ($self->{altdataobjattr} is null,".
                        "$self->{dataobjattr},$self->{altdataobjattr})";
                  return($f); # noch todo
               };
               do {
                  msg(ERROR,"alternate conversion for date on driver '$_' not ".
                            "defined ToDo!");
                  return(undef);
               };
            }
            
         }
      }
      return($self->{dataobjattr});
   }
   if ($mode eq "order"){
      my $db=shift;
    
      if (defined($self->{dataobjattr}) && 
          ref($self->{dataobjattr}) ne "ARRAY"){
         my $orderstring=$self->{dataobjattr};
         $orderstring=$self->{name} if ($self->{dataobjattr}=~m/^max\(.*\)$/);
         $orderstring.=" ".$self->{sqlorder} if (defined($self->{sqlorder}));
         return(undef) if ($self->{sqlorder} eq "none");
         return($orderstring);
      }
   }
   return(undef);
}


sub RawValue
{
   my $self=shift;
   my $current=shift;
   my $d;

   if (exists($current->{$self->Name()})){
      $d=$current->{$self->Name()};
   }
   elsif (defined($self->{onRawValue}) && ref($self->{onRawValue}) eq "CODE"){
      $current->{$self->Name()}=&{$self->{onRawValue}}($self,$current);
      $d=$current->{$self->Name()};
   }
   elsif (defined($self->{vjointo})){
      my $c=$self->getParent->Context();
      $c->{JoinData}={} if (!exists($c->{JoinData}));
      $c=$c->{JoinData};
      my $joincontext=$self->vjoinContext();
      my @view=($self->{vjoindisp},$self->{vjoinon}->[1]);
      foreach my $fieldname ($self->getParent->getCurrentView()){
         my $fobj=$self->getParent->getField($fieldname);
         next if (!defined($fobj));
         if ($fobj->vjoinContext() eq $joincontext){
            if (!grep(/^$fobj->{vjoindisp}$/,@view)){
               push(@view,$fobj->{vjoindisp});
            }
         }
      }
      $joincontext.="+".join(",",sort(@view));
      $c->{$joincontext}={} if (!exists($c->{$joincontext}));
      $c=$c->{$joincontext};
      my @joinon=@{$self->{vjoinon}};
      my %flt=();
      my $joinval=0;
      while(my $myfield=shift(@joinon)){
         my $joinfield=shift(@joinon);
         my $myfieldobj=$self->getParent->getField($myfield);
         if (defined($myfieldobj)){
            if ($myfieldobj ne $self){
               my $myval=$myfieldobj->RawValue($current);
               $flt{$joinfield}=\$myval;
               $joinval=1 if (defined($myval));
            }
         #   else{
         #      if (defined($self->{container})){
         #         my $container=$self->getParent->getField($self->{container});
         #         if (defined($container)){
         #            my $containerdata=$container->RawValue($current);
         #            $flt{$joinfield}=$containerdata->{$myfield};
         #            $joinval=1 if (defined($containerdata->{$myfield}));
         #         }
         #      }
         #   }
         }
      }

      my $joinkey=join(";",map({ my $k=$flt{$_};
                                 $k=$$k if (ref($k) eq "SCALAR");
                                 $k=join(";",@$k) if (ref($k) eq "ARRAY");
                                 $_."=".$k;
                               } sort(keys(%flt))));
      delete($self->{VJOINSTATE});
      if (keys(%flt)>0){
         if ($joinval){ 
            if (!exists($c->{$joinkey})){
               if (defined($self->{vjoinbase})){
                  $self->vjoinobj->SetNamedFilter("BASE",@{$self->{vjoinbase}});
               }
               $self->vjoinobj->SetFilter(\%flt);
               $c->{$joinkey}=$self->vjoinobj->getHashList(@view);
            }
            my %u=();
            map({
                   my $bk=$_->{$self->{vjoindisp}};
                   $bk=join(", ",@$bk) if (ref($bk) eq "ARRAY");
                   $u{$bk}=1;
                } @{$c->{$joinkey}});
            if (keys(%u)>0){
               $self->{VJOINSTATE}="ok";
            }
            else{
               $self->{VJOINSTATE}="not found";
            }
            $current->{$self->Name()}=join($self->{vjoinconcat},sort(keys(%u)));
            $d=$current->{$self->Name()};
         }
         else{
            $d=undef;
         }
      }
      else{
         return("ERROR: can't find join target '$self->{vjoinon}->[0]'");
      }
   }
   elsif (defined($self->{container})){
      my $container=$self->getParent->getField($self->{container});
      if (!defined($container)){ # if the container comes from the parrent
                                 # DataObj (if i be a SubDataObj)
         my $parentofparent=$self->getParent->getParent();
         $container=$parentofparent->getField($self->{container});
      }
      my $containerdata=$container->RawValue($current);
      if (wantarray()){
         return(@{$containerdata->{$self->Name}});
      }
      if (ref($containerdata->{$self->Name}) eq "ARRAY" &&
          $#{$containerdata->{$self->Name}}<=0){
         $d=$containerdata->{$self->Name}->[0];
      }
      else{
         $d=$containerdata->{$self->Name};
      }
   }
   elsif (defined($self->{alias})){
      my $fo=$self->getParent->getField($self->{alias});
      return(undef) if (!defined($fo));
      my $d=$fo->RawValue($current);
      return($d);
   }
   else{
      $d=$current->{$self->Name};
   }
   if (ref($self->{prepRawValue}) eq "CODE"){
      $d=&{$self->{prepRawValue}}($self,$d,$current);
   }
   $d=$self->{default} if (exists($self->{default}) && (!defined($d) ||
                           $d eq ""));
   return($d);
}

sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   #printf STDERR ("fifi default FinishWrite handler for field %s\n",
   #               $self->{name});
   if (defined($self->{onFinishWrite}) && 
       ref($self->{onFinishWrite}) eq "CODE"){   
      return(&{$self->{onFinishWrite}}($self,$oldrec,$newrec));
   }
   return(undef);
}

sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;

   if (defined($self->{onFinishDelete}) && 
       ref($self->{onFinishDelete}) eq "CODE"){   
      return(&{$self->{onFinishDelete}}($self,$oldrec));
   }
   return(undef);
}

sub FormatedResult
{
   my $self=shift;
   my $current=shift;
   my $FormatAs=shift;
   my $d=$self->FormatedDetail($current,$FormatAs);
   return($d);
}

sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $d=$self->RawValue($current);
   return($d);
}

sub FormatedSearch
{
   my $self=shift;

   my $name=$self->{name};
   my $label=$self->Label;
   my $curval=Query->Param($name);
   if (!defined($curval)){
      $curval=Query->Param("search_".$name);
   }
   $curval=~s/"/&quot;/g;
   my $d="<table style=\"table-layout:fixed;width:100%\" ".
         "border=0 cellspacing=0 cellpadding=0>\n";
   $d.="<tr><td>". # for min width, add an empty image with 50px width
       "<img width=50 border=0 height=1 ".
       "src=\"../../../public/base/load/empty.gif\">";
   $d.="<input type=text  name=\"search_$name\" ".
       "class=finput style=\"min-width:50px\" value=\"$curval\">";
   $d.="</td>";
   my $FieldHelpUrl=$self->getFieldHelpUrl();
   if (defined($FieldHelpUrl)){
      $d.="<td width=10 valign=top align=right>";
      $d.="<img style=\"cursor:pointer;cursor:hand;float:right;\" ".
          "onClick=\"FieldHelp_On_$name()\" align=right ".
          "src=\"../../../public/base/load/questionmark.gif\" ".
          "border=0>";
      $d.="</td>";
      my $q=kernel::cgi::Hash2QueryString(field=>"search_$name",
                                          label=>$label);
      $d.=<<EOF;
<script langauge="JavaScript">
function FieldHelp_On_$name()
{
   showPopWin('$FieldHelpUrl?$q',500,200,RestartApp);
}
</script>
EOF
   }
   $d.="</td></tr></table>\n";
   return($d);
}

sub getFieldHelpUrl
{
   my $self=shift;

   if (defined($self->{FieldHelp})){
      if (ref($self->{FieldHelp}) eq "CODE"){
         return(&{$self->{FieldHelp}}($self));
      }
      return($self->{FieldHelp});
   }
   my $type=$self->Type();
   if ($type=~m/Date$/){
      return("../../base/load/tmpl/FieldHelp.Date");
   }
   if ($self->{FieldHelp} ne "0"){
      return("../../base/load/tmpl/FieldHelp.Default");
   }
   return(undef);
}

#
# vor history displaying in Workflow Mode
#
sub FormatedStoredWorkspace
{
   my $self=shift;
   my $name=$self->{name};
   my $d="";

   my @curval=Query->Param("Formated_".$name);
   my $disp="";
   my $var=$name;
   if (defined($self->{vjointo})){
      $var=$self->{vjoinon}->[0];
   }
   if ($#curval>0){
      $disp.=$self->FormatedResult({$var=>\@curval},"HtmlDetail");
   }
   else{
      $disp.=$self->FormatedResult({$var=>$curval[0]},"HtmlDetail");
   }
   foreach my $var (@curval){
      $d.="<input type=hidden name=Formated_$name value=\"$var\">";
   }
   $d=$disp.$d;
   return($d);
}

sub getXLSformatname
{
   my $self=shift;
   return("default");
}


# Zugriffs funktionen

1;
