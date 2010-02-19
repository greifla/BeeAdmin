package kernel::Output::JSON;
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
use base::load;
use kernel::Output::HtmlSubList;
@ISA    = qw(kernel::Formater);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}

sub IsModuleSelectable
{
   eval("use JSON;");
   if ($@ ne ""){
      return(0);
   }
   return(1);
}
sub getRecordImageUrl
{
   return("../../../public/base/load/icon_xml.gif");
}
sub Label
{
   return("Output to JSON");
}
sub Description
{
   return("Format as JSON Object list");
}

sub MimeType
{
   return("application/javascript");
}

sub getDownloadFilename
{
   my $self=shift;

   return($self->SUPER::getDownloadFilename().".js");
}


sub getHttpHeader
{  
   my $self=shift;
   my $app=$self->getParent->getParent();
   my $d="";
   $d.="Content-type:".$self->MimeType().";charset=UTF8\n\n";
   return($d);
}

sub Init
{
   my ($self,$fh)=@_;
   eval('use JSON;$self->{JSON}=new JSON;');
   $self->{JSON}->utf8(1);
   my $app=$self->getParent->getParent();
   return();
}

sub ProcessLine
{
   my ($self,$fh,$viewgroups,$rec,$recordview,$fieldbase,$lineno,$msg)=@_;
   my $app=$self->getParent->getParent();
   my @view=$app->getFieldObjsByView([$app->getCurrentView()],current=>$rec);
   my $fieldbase={};
   map({$fieldbase->{$_->Name()}=$_} @view);

   my %rec=();
   my %xmlfields;
   foreach my $fo (@view){
      my $name=$fo->Name();
      my $v=$fo->UiVisible("XML",current=>$rec);
      next if (!$v && ($fo->Type() ne "Interface"));
      if (!defined($self->{fieldkeys}->{$name})){
         push(@{$self->{fieldobjects}},$fo);
         $self->{fieldkeys}->{$name}=$#{$self->{fieldobjects}};
      }
    
      $xmlfields{$name}=$fo;
   }
   foreach my $name (sort(keys(%xmlfields))){
      my $data=$app->findtemplvar({viewgroups=>$viewgroups,
                                   fieldbase=>$fieldbase,
                                   current=>$rec,
                                   mode=>'JSON',
                                  },$name,"formated");
      if (defined($data)){
         $rec{$name}=$data;
      }
      else{
         $rec{$name}=undef;
      }
   }
   my $d;
   if (defined($self->{JSON})){
      #$d=$self->{JSON}->pretty->encode(\%rec);
      $d=$self->{JSON}->encode(\%rec);
   }
   # date hack, to get Date objects in JavaScript!
   $d=~s/"\\\\Date\((\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)\)\\\\"/new Date($1,$2,$3,$4,$5)/g;
   if ($lineno>1){
      $d=",\n".$d;
   }
   return($d);
}

sub ProcessBottom
{
   my ($self,$fh,$rec,$msg)=@_;
   my $d;
   my $app=$self->getParent->getParent();
   $d="];\n";
   return($d);
}

sub ProcessHead
{
   my ($self,$fh,$rec,$msg)=@_;
   my $d;
   my $app=$self->getParent->getParent();
   my $appname="W5Base::".$app->Self;
   $appname=~s/::/\./g;
   $d=<<EOF;
//================================================
//
// target namespace : $appname
//
function createNamespace(ns)
{
   ns="document."+ns;
   var splitNs = ns.split(".");
   var builtNs = splitNs[0];
   if (typeof(window)=="undefined"){
      window={};
   }
   var i, base = window;
   for (i = 0; i < splitNs.length; i++){
      if (typeof(base[splitNs[i]])=="undefined"){
         base[splitNs[i]] = {};
      }
      base=base[splitNs[i]];
   }
   window.document.W5Base['LastResult']=function(){
      return(window.document.$appname.Result);
   };
   return(base);
}
//================================================
EOF
   $d.="createNamespace('$appname')['Result']=\n[\n";
   return($d);
}

1;
