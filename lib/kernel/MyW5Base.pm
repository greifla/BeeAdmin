package kernel::MyW5Base;
#  W5Base Framework
#  Copyright (C) 2002  Hartmut Vogler (hartmut.vogler@epost.de)
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
#
use vars qw(@ISA);
use strict;
use kernel;
use kernel::App;
use kernel::date;
use kernel::Universal;
use kernel::WSDLbase;

@ISA=qw(kernel::App kernel::WSDLbase);

sub new
{
   no strict 'refs';
   my $type=shift;
   my $self=bless({@_},$type);
   $self->{isInitalized}=0;

   foreach my $method (qw(IdField getFieldList getFieldObjsByView
                          getField ViewEditor
                          isViewValid isWriteValid
                          getHashList ResetFilter
                          SetCurrentView 
                          getOnlyFirst)){
      *$method = sub {
            my $s = shift;
            return ($s->getDataObj()->$method(@_));
        }
   } 
   return($self);
}

sub Init
{
   my $self=shift;
   my $dataobj=$self->getDataObj();
   return(0) if (!defined($dataobj));
   $dataobj->setParent($self);
   $self->{isInitalized}=1;
   return(1);
}

sub isSelectable
{
   my $self=shift;
   my %param=@_;

   return(1);
}

sub getLabel
{
   my $self=shift;

   return($self->getParent->T($self->Self(),$self->Self()));
}

sub getDefaultFormat
{
   my $self=shift;

   return("HtmlV01");
}

sub doAutoSearch
{
   my $self=shift;

   return(1);
}

sub getDataObj
{
   my $self=shift;
   return($self->{DataObj});
}



sub getDefaultStdButtonBar
{
   my $self=shift;
   return('%StdButtonBar(print,search)%');
}

sub getQueryTemplate
{
   my $self=shift;
   my $bb=$self->getDefaultStdButtonBar();
   return($bb);
}



sub getTimeRangeDrop
{
   my $self=shift;
   my $name=shift;
   my $app=shift;
   my @modes=@_;
   my $d="<select style=\"width:100%\" name=$name";
   if (grep(/^rangeChangedEvent$/,@modes)){
      $d.=" onchange=\"rangeChangedEvent()\"";
   }
   $d.=">\n";
   my ($year,$month,$day, $hour,$min,$sec) = Today_and_Now("GMT");
   my %k=();

   my $lmonth=$month-1;
   my $lyear=$year;
   if ($lmonth==0){
      $lyear=$year-1;
      $lmonth=12;
   }
   my $oldval=Query->Param($name);
   $oldval=undef if (grep(/^fixmonth$/,@modes) && 
                     (!($oldval=~m/^\d+-\d+$/) && 
                      !($oldval=~m/^nextmonth$/) &&
                      !($oldval=~m/^currentmonth$/) &&
                      !($oldval=~m/^lastmonth$/)));
   $oldval=undef if (grep(/^month$/,@modes) && !($oldval=~m/AND/));
   foreach my $blk (@modes){
      if ($blk eq "nearfuture"){
         my @l=(
                '>today AND <today+48h'=>
                $app->T("current and next 48h"), 
                '>now AND <now+3d'=>
                $app->T("next 3 days"), 
                '>now AND <now+7d'=>
                $app->T("next 7 days"), 
                '>now AND <now+14d'=>
                $app->T("next 14 days"), 
                '>now AND <now+15d'=>
                $app->T("next 15 days"), 
                '>now AND <now+30d'=>
                $app->T("next 30 days"));
         while(defined(my $exp=shift(@l))){
            my $nam=shift(@l);
            $d.="<option value=\"".$exp."\"";
            $d.=" selected" if ($exp eq $oldval);
            $d.=">$nam</option>";
            $k{$exp}=$nam;
         }
      }
      $oldval='>today-48h' if ($blk eq "selectshorthistory" &&
                                             $oldval eq "");
      if ($blk eq "shorthistory"){
         my @l=(
                '>today-48h'=>
                $app->T("future and last 48h"), 
                '>now-3d'=>
                $app->T("future and last 3 days"), 
                '>now-7d'=>
                $app->T("future and last 7 days"), 
                '>now-14d'=>
                $app->T("future and last 14 days"), 
                '>now-15d'=>
                $app->T("future and last 15 days"), 
                '>now-28d'=>
                $app->T("future and last 28 days"));
         while(defined(my $exp=shift(@l))){
            my $nam=shift(@l);
            $d.="<option value=\"".$exp."\"";
            $d.=" selected" if ($exp eq $oldval);
            $d.=">$nam</option>";
            $k{$exp}=$nam;
         }
      }
      if ($blk eq "longhistory"){
         my @l=(
                '>now-84d'=>
                $app->T("future and last 12 weeks"), 
                '>now-365d'=>
                $app->T("future and last 365 days"));
         while(defined(my $exp=shift(@l))){
            my $nam=shift(@l);
            $d.="<option value=\"".$exp."\"";
            $d.=" selected" if ($exp eq $oldval);
            $d.=">$nam</option>";
            $k{$exp}=$nam;
         }
      }
      if ($blk eq "month" || $blk eq "monthyear" || $blk eq "fixmonth"){
         my $sM=$month+6;
         my $sY=$year;
         if ($sM>12){
            $sM=$sM-12;
            $sY++;
         }
         my $histl=60;
         $histl=9 if (grep(/^shorthist$/,@modes));
         for(my $c=0;$c<=$histl;$c++){
            my $eM=$sM-1;
            my $eY=$sY;
            if ($eM==0){
               $eY-=1;
               $eM=12;
            }
            #my $exp=sprintf(">=%02d/%04d AND <=%02d/%04d-1s",$eM,$eY,$sM,$sY);
            my $exp=sprintf("(%02d/%04d)",$eM,$eY);
            if (grep(/^fixmonth$/,@modes)){
               $exp=sprintf("%02d/%04d",$eM,$eY);
            }
            my $nam=sprintf("%02d/%04d",$eM,$eY);
            $d.="<option value=\"".$exp."\"";
            $nam.=" ".$app->T("current month") if ($month==$eM && $year==$eY);
            $d.=" selected" if ($exp eq $oldval || 
                                (!defined($oldval) && 
                                 !grep(/^selectlastmonth$/,@modes) &&
                                  $month==$eM && $year==$eY)||
                                (!defined($oldval) && 
                                 grep(/^selectlastmonth$/,@modes) &&
                                  $lmonth==$eM && $lyear==$eY));
            $d.=">$nam</option>\n";
            $k{$exp}=$nam;
            if ($blk eq "monthyear" && $eM==1){
               $exp="($eY)";
               $k{$exp}=$nam;
               $d.="<option value=\"".$exp."\"";
               $d.=" selected" if ($exp eq $oldval);
               $d.=">$eY</option>\n";
            }
            $sM-=1;
            if ($sM==0){
               $sY-=1;
               $sM=12;
            }
         }
      }
   }
   if (grep(/^relativemonth$/,@modes)){
      $d.="<option value=\"nextmonth\"";
      $d.=" selected" if ($oldval eq "nextmonth");
      $d.=">".$self->getParent->T("nextmonth")."</option>";
      $k{nextmonth}="nextmonth";
   }
   if (grep(/^relativemonth$/,@modes)){
      $d.="<option value=\"currentmonth\"";
      $d.=" selected" if ($oldval eq "currentmonth");
      $d.=">".$self->getParent->T("currentmonth")."</option>";
      $k{currentmonth}="currentmonth";
   }
   if (grep(/^lastmonth$/,@modes) ||
       grep(/^relativemonth$/,@modes)){
      $d.="<option value=\"lastmonth\"";
      $d.=" selected" if ($oldval eq "lastmonth");
      $d.=">".$self->getParent->T("lastmonth")."</option>";
      $k{lastmonth}="lastmonth";
   }
   $d.="</select>\n"; 
   if (wantarray()){
      return(%k);
   }
   return($d);
}


#######################################################################
#
# DataObj compatibility Interface
#
sub Config
{
   my $self=shift;
   return($self->getParent->Config(@_));
}

sub SecureSetFilter
{
   my $self=shift;
   return($self->SetFilter(@_));
}



sub ExpandTimeExpression
{
   my $self=shift;
   return($self->getParent->ExpandTimeExpression(@_));
}


#######################################################################


sub WSDLaddNativFieldList
{
   my $self=shift;
   my $o=$self;
   my $uri=shift;
   my $ns=shift;
   my $fp=shift;
   my $class=shift;
   my $mode=shift;
   my $XMLbinding=shift;
   my $XMLportType=shift;
   my $XMLmessage=shift;
   my $XMLtypes=shift;

   if ($mode eq "filter"){
      $$XMLtypes.="<xsd:element minOccurs=\"0\" maxOccurs=\"1\" ".
                  "name=\"exviewcontrol\" type=\"xsd:string\" />";
   }


   return($self->SUPER::WSDLaddNativFieldList($uri,$ns,$fp,$class,$mode,
                              $XMLbinding,$XMLportType,$XMLmessage,$XMLtypes));
}






1;

