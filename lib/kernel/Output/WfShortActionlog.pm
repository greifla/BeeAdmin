package kernel::Output::WfShortActionlog;
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
use base::load;
@ISA    = qw(kernel::Formater);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
  # my $config=$self->getParent->getParent->Config();
   #$self->{SkinLoad}=getModuleObject($config,"base::load");

   return($self);
}

sub getRecordImageUrl
{
   return("../../../public/base/load/icon_html.gif");
}
sub Label
{
   return("Output to Html List");
}
sub Description
{
   return("A simple Html List");
}

sub MimeType
{
   return("text/html");
}




sub getHttpHeader
{  
   my $self=shift;
   my $app=$self->getParent->getParent();
   my $d="";
   $d.="Content-type:".$self->MimeType()."\n\n";
   $d.="<html>";
   $d.="<body>";
   return($d);
}

sub getViewLine
{
   my ($self,$fh,$rec,$msg,$viewlist,$curview)=@_;
   my $d="";
   return($d);
}

sub getStyle
{
   my ($self,$fh)=@_;
   my $app=$self->getParent->getParent();
   my $d="";
  # $d.=$app->getTemplate("css/Output.HtmlV00.css","base");
   return($d);
}



sub ProcessHead
{
   my ($self,$fh,$param)=@_;
   my $app=$self->getParent->getParent();
   my $view=$app->getCurrentViewName();
   my @view=$app->getCurrentView();
   my $d="";
   $d.="<style>";
   $d.=$self->getStyle($fh);
   $d.="</style>\n\n";
   #$d.="<script language=\"JavaScript\">";
   #$d.=$app->getTemplate("toolbox.js");
   #$d.="</script>\n\n";
   if ($param->{ParentMode} ne "HtmlV01"){
      $d.="<table width=100% style=\"table-layout:fixed\"><tr><td>".
          "<div style=\"overflow:hidden\">\n";
      $d.="<tr><td class=mainblock>";
   }
   $d.="<table class=subdatatable width=100%>\n<tr class=subheadline>";
   my $col=0;
   foreach my $f (qw(cdate name)){
      next if (!exists($self->{fieldkeys}->{$f}));
      my $fobj=$self->{fieldobjects}->[$self->{fieldkeys}->{$f}];
         
      my $displayname=$fobj->Label();
      my $width;
      $width="style=\"width:10%\"" if ($col==0);
      $d.="<th class=subheadfield $width>".$displayname."</th>";
      $col++;
   }
   $d.="</tr>\n";
   return($d);
}
sub ProcessLine
{
   my ($self,$fh,$viewgroups,$rec,$msg)=@_;
   my $app=$self->getParent->getParent();
   my $view=$app->getCurrentViewName();
   my @view=$app->getCurrentView();
   $self->{lineclass}=1 if (!exists($self->{lineclass}));
   my $d="";
   my $lineclass="subline".$self->{lineclass};
   my $lineonclick;
   my $idfield=$app->IdField();
   my $idfieldname=$idfield->Name();
   my $id=$idfield->RawValue($rec);

   if (grep(/^Detail$/,$app->getValidWebFunctions())){
      if ($idfield){
         my $dest=$app->Self();
         $dest=~s/::/\//g;
         $dest="../../$dest/Detail?$idfieldname=$id&AllowClose=1";
         my $detailx=$app->DetailX();
         my $detaily=$app->DetailY();
         $lineonclick="openwin(\"$dest\",\"_blank\",".
             "\"height=$detaily,width=$detailx,toolbar=no,status=no,".
             "resizable=yes,scrollbars=no\")";
      }
   }


   $d.="<tr class=$lineclass ".
       "onMouseOver=\"this.className='linehighlight'\" ".
       "onMouseOut=\"this.className='$lineclass'\">\n";
   
   $d.="<td class=subdatafield onClick=$lineonclick ".
       "valign=top nowrap style=\"width:10%\">";
   { # process mdate field
      my $fieldname="cdate";
      if (exists($self->{fieldkeys}->{$fieldname})){
         my $fobj=$self->{fieldobjects}->[$self->{fieldkeys}->{$fieldname}];
         my $data=$app->findtemplvar({viewgroups=>$viewgroups,
                                      mode=>'HtmlWfActionlog',
                                      current=>$rec
                                     },$fieldname,"formated");
         $d.=$data;
      }
      my $fieldname="effort";
      if (exists($self->{fieldkeys}->{$fieldname})){
         my $fobj=$self->{fieldobjects}->[$self->{fieldkeys}->{$fieldname}];
         my $data=$app->findtemplvar({viewgroups=>$viewgroups,
                                      mode=>'HtmlWfActionlog',
                                      current=>$rec
                                     },$fieldname,"formated");
         $d.="<br>($data min)" if ($data ne "");
      }
   }
   $d.="</td>";
   $d.="<td class=subdatafield valign=top style=\"width:auto;cursor:auto\">";
   $d.="<div class=workflowmultilinetext>";
   $d.="<table width=100% cellspacing=0 cellpadding=0>".
       "<tr><td align=left valign=top>";
   $d.="<u>";
   { # process action name field
      my $fieldname="translation";
      my $translation=$self->getParent->getParent();
      if (exists($self->{fieldkeys}->{$fieldname})){
         my $fobj=$self->{fieldobjects}->[$self->{fieldkeys}->{$fieldname}];
         $translation=$fobj->RawValue($rec);
      }
      my $fieldname="name";
      if (exists($self->{fieldkeys}->{$fieldname})){
         my $fobj=$self->{fieldobjects}->[$self->{fieldkeys}->{$fieldname}];
         my $data=$app->findtemplvar({viewgroups=>$viewgroups,
                                      mode=>'HtmlWfActionlog',
                                      current=>$rec
                                     },$fieldname,"formated");
         $d.=$self->getParent->getParent->T($data,$translation).":";
      }
   }
   $d.="</u>";
   $d.="</td><td align=right valign=top>";
   { # process owner name field
      my $fieldname="owner";
      if (exists($self->{fieldkeys}->{$fieldname})){
         my $fobj=$self->{fieldobjects}->[$self->{fieldkeys}->{$fieldname}];
         my $data=$fobj->FormatedDetail($rec,"HtmlDetail");
         $d.=$data;
      }
   }
   $d.="</td></tr>";
   {
      my $fieldname="additional";
      my $add={};
      if (exists($self->{fieldkeys}->{$fieldname})){
         my $fobj=$self->{fieldobjects}->[$self->{fieldkeys}->{$fieldname}];
         $add=$fobj->RawValue($rec);
      }
      if (defined($add->{ForwardToName}) &&
          $#{$add->{ForwardToName}}!=-1){
         $d.="<tr><td colspan=2>".join("<br>",@{$add->{ForwardToName}}).
             "</td></tr>";
      }
   }
   $d.="</table>";
   { # process comments field
      my $fieldname="comments";
      if (exists($self->{fieldkeys}->{$fieldname})){
         my $fobj=$self->{fieldobjects}->[$self->{fieldkeys}->{$fieldname}];
         my $data=$app->findtemplvar({viewgroups=>$viewgroups,
                                      mode=>'HtmlWfActionlog',
                                      current=>$rec
                                     },$fieldname,"formated");
         if ($data ne ""){
            $data=~s/&/&amp;/g;
            $data=~s/</&lt;/g;
            $data=~s/>/&gt;/g;
            $d.="<table cellspacing=0 cellpadding=0 border=0".
                "width=99% style=\"table-layout:fixed\"><tr><td>";
            $d.="<pre class=multilinetext>".FancyLinks($data)."</pre>";
            $d.="</td></tr></table>";
         }
      }
   }
   $d.="</div>";
   $d.="</td>";
   $d.="</tr>";
   return($d);
}
sub ProcessBottom
{
   my ($self,$fh,$rec,$msg,$param)=@_;
   my $app=$self->getParent->getParent();
   my $view=$app->getCurrentViewName();
   my @view=$app->getCurrentView();
   my $d="</table>";
  # $d.="</td></tr></table>\n";
   my $AutoScroll=<<EOF;
<script language="JavaScript\">
var ScrollDestY=0;
var OldScroll=document.body.scrollTop;
function ScrollToDest() {
   var ScrollOffsetDist=ScrollDestY-document.body.scrollTop;
   var ScrollOffset=ScrollOffsetDist/10;
   if (OldScroll>0 && OldScroll!=document.body.scrollTop){
      return;
   }
   OldScroll=document.body.scrollTop;
   if (ScrollOffset>30){
      ScrollOffset=30;
   }
   if (ScrollOffset<3){
      ScrollOffset=3;
   }
   window.scrollBy(0,ScrollOffset);
   OldScroll=document.body.scrollTop;
   if (Math.abs(ScrollOffsetDist)>5){
      window.setTimeout("ScrollToDest()", 50);
   }
   OldScroll=document.body.scrollTop;
}
function ScrollToLog()
{
   var h=getViewportHeight();
   var e=window.document.getElementById("EndOfActionList");
   var p=getAbsolutY(e);
   ScrollDestY=p-h;
   if (ScrollDestY>0){
      ScrollToDest();
   }
}
if (parent.name!="work"){
   window.setTimeout("ScrollToLog()", 1000);
}
</script>
EOF
   if ($self->getParent->getParent->getParent->can("allowAutoScroll") &&
       $self->getParent->getParent->getParent->
              allowAutoScroll($self->{parentcurrent})){
      $d.=$AutoScroll if ($self->{WindowMode} eq "Detail");
   }
   if (defined($msg)){
      if (!$self->{DisableMsg}){
         $d.="<hr>msg=$msg<br>";
      }
   }
   $d.=$self->StoreQuery();
   if ($param->{ParentMode} ne "HtmlV01"){
      $d.="</div></td></tr></table>";
   }
   $d.="<a id=\"EndOfActionList\"></a>";

   return($d);
}

sub StoreQuery
{
   my $self=shift;
   my $d="";
   return($d);
}


sub getHttpFooter
{  
   my $self=shift;
   my $d="";
   $d.="</body>";
   $d.="</html>";
   return($d);
}



1;
