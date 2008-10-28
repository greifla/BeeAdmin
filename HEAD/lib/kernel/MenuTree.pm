package kernel::MenuTree;
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
use vars qw(@ISA @EXPORT);
use UNIVERSAL;
use kernel;
use Exporter;
use XML::Smart;
@EXPORT=qw(&BuildHtmlTree);


sub BuildHtmlTree
{
   my %control=@_;
   # $control->{tree}     =Datenstruktur des Trees
   # $control->{rootpath} =rootpath/prefix vor den img tags
   # $control->{rootimg}  =name of the top image
   #
   # tree->{prio}         = sortierreihenfolge
   # tree->{href}         = href link f�r den link
   # tree->{label}        = dargestellter text
   # tree->{tree}         = array pointer auf untermenu

   $control{rootpath}="../"          if (!defined($control{rootpath}));
   $control{rootimg}="miniglobe.gif" if (!defined($control{rootimg}));
   my $d="<div>";
   $d.=_ProcessTreeLayer(\%control,[$#{$control{tree}}+1],$control{tree});
   $d.="</div>"; # ent of id=MenuTree
   $d.="</div>";
  # $d.="<script language=JavaScript>tt_Init();</script>\n";
   return($d);
}



sub _TreeLine
{
   my $control=shift;
   my $indent=shift;
   my $id=shift;
   my $ment=shift;
   my $href;
   my $text;
   my $desc;
   my $d;
   if (defined($ment)){
      $href=$ment->{href};
      $text=$ment->{label};
      $desc=$ment->{description};
   }
   my $rootpath=$control->{rootpath};
   if ($id==0){
      if (defined($control->{rootlink})){
         $d.="<a href=$control->{rootlink}>";
      }
      $d.="<img border=0 ".
          "src=\"${rootpath}../../base/load/$control->{rootimg}\">";
      if (defined($control->{rootlink})){
         $d.="</a>";
      }
      $d.="<div id=MenuTree>";
   }
   else{
      $d.="<div style=\"border-style:none;border-width:1px;".
            "padding:0;margin:0;vertical-align:middle\">";
      $d.="<table width=100% border=0 cellspacing=0 cellpadding=0>";
      $d.="<tr><td valign=center width=1% nowrap>";
      for(my $c=1;$c<=$#{$indent};$c++){
         my $l=4;
         $l=1 if ($indent->[$c-1]>0);
         $d.="<img border=0 src=\"${rootpath}../../base/load/menu_bar_$l.gif\">";
      }
      my $imgname="menu_bar_${id}.gif";
      $d.="<img border=0 src=\"${rootpath}../../base/load/$imgname\">";
      $d.="</td><td valign=center>";
      my $hrefclass;
      $hrefclass="class=$control->{hrefclass}" if (defined($control->{hrefclass}));
      $d.=$ment->{labelprefix}  if (defined($ment->{labelprefix}));
      my $usehref="href=\"$href\"";
      $usehref="href=$href" if ($href=~m/^javascript:/i);
      $d.="<a $hrefclass $usehref title=\"$desc\">" if (defined($href));
      $d.=$text  if (defined($text));
      $d.="</a>" if (defined($href));
      $d.="</td></tr></table>";
      $d.="</div>\n";
   }
   return($d);
}




sub _ProcessTreeLayer
{
   my $control=shift;
   my $layer=shift;
   my $menu=shift;
   my $d="";
   $d.=_TreeLine($control,$layer,0,undef) if ($#{$layer}==0);
   my @mlist=sort({
                     my $bk;
                     if ($a->{prio}==$b->{prio}){
                        $bk=$a->{menuid}<=>$b->{menuid};
                     }
                     else{
                        $bk=$a->{prio}<=>$b->{prio};
                     }
                     $bk;
                  } @{$menu});
   for(my $c=0;$c<=$#mlist;$c++){
      my $m=$mlist[$c];
      my $modid=2;
      if ($c==$#mlist){
         $modid=3;
         $layer->[$#{$layer}]=0;
      }
      $modid=6 if ($m->{active} && $modid==3);
      $modid=5 if ($m->{active} && $modid==2);
      $d.=_TreeLine($control,$layer,$modid,$m);
      if (defined($m->{tree}) && $#{$m->{tree}}!=-1){
         $d.=_ProcessTreeLayer($control,[@$layer,$#{$m->{tree}}+1],
                               $m->{tree});
      }
   }
   return($d);
}

#####################################################################
#####################################################################
#####################################################################


######################################################################
1;
