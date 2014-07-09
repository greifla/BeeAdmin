package kernel::Output::HtmlDetail;
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
use kernel::TemplateParsing;
use base::load;
use kernel::TabSelector;
use kernel::Field::Date;
@ISA    = qw(kernel::Formater kernel::TemplateParsing);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
  # my $config=$self->getParent->getParent->Config();
   #$self->{SkinLoad}=getModuleObject($config,"base::load");

   return($self);
}

sub getHttpHeader
{  
   my $self=shift;
   my $app=$self->getParent->getParent();
   my $d="";
   $d.=$app->HttpHeader();
   $d.=$app->HtmlHeader(style=>['default.css',
                                'work.css',
                                'Output.HtmlDetail.css',
                                'kernel.App.Web.css',
                                'Output.HtmlSubList.css',
                                'kernel.filemgmt.css'],
                        title=>'Detail loading ...',
                        onload=>'DetailInit()');
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
   my ($self,$fh,$rec,$msg,$viewlist,$curview)=@_;
   my $app=$self->getParent->getParent();
   my $d="\n";
#   $d.=$app->getTemplate("css/default.css","base");
#   $d.=$app->getTemplate("css/kernel.App.Web.css","base");
#   $d.=$app->getTemplate("css/Output.HtmlSubList.css","base");
#   $d.=$app->getTemplate("css/Output.HtmlDetail.css","base");
#   $d.=$app->getTemplate("css/kernel.filemgmt.css","base");
   return($d);
}


sub ProcessHead
{
   my ($self,$fh,$rec,$msg,$param)=@_;
   my $app=$self->getParent->getParent();
   my $view=$app->getCurrentViewName();
   my @view=$app->getCurrentView();
   my $scrolly=Query->Param("ScrollY");
   $scrolly=0 if (!defined($scrolly));
   my $newstyle="";
   if ($self->getParent->{NewRecord}){
      $newstyle="overflow:auto;height:300px";
   }
   my $d="";
   $d.="<div id=HtmlDetail style=\"$newstyle\"><div style=\"padding:5px\">";
   $d.="<form method=post target=_self enctype=\"multipart/form-data\">";
   $d.="<style>";
   $d.=$self->getStyle($fh,$rec,$msg,\@view,$view);
   $d.="</style>\n".$self->{fieldsPageHeader};
   $d.="<script type=\"text/javascript\" language=\"JavaScript\">\n";
   if ($scrolly!=0){
      $d.=<<EOF;
function DetailInit()  // used from asyncron sub data to restore position in
{                      // page
   document.body.scrollTop=$scrolly;
   return;
}
EOF
   }
   else{
      $d.=<<EOF;
function DetailInit()  // used from asyncron sub data to restore position in
{                      // page
   return;
}
EOF
   }
   $d.=<<EOF;
function onNew()
{
   var t=document.getElementById("TabSelectorModeSelect");
   if (t){
      var e=document.getElementById("HtmlDetail");
      e.style.height=(t.offsetHeight-30)+"px";
   }
}
function onResize()
{
   var t=document.getElementById("TabSelectorModeSelect");
   if (t){
      var e=document.getElementById("HtmlDetail");
      e.style.height="10px";
   }
   window.setTimeout(onNew,1);

}
addEvent(window, "load",   onNew);
addEvent(window, "resize",   onResize);

EOF
   $d.="</script>\n\n";
   $self->Context->{LINE}=0;
   $self->Context->{jsonchanged}=[];

   return($d);
}


sub  calcViewMatrix
{
   my ($self,$rec,$vMatrix,$fieldbase,$fieldlist,$viewgroups)=@_;

   for(my $c=0;$c<=$#{$fieldlist};$c++){
      my $name=$fieldlist->[$c]->Name();
      $fieldbase->{$name}=$fieldlist->[$c];

      $vMatrix->{uivisibleof}->[$c]=
         $fieldlist->[$c]->UiVisible("HtmlDetail",current=>$rec);


      # fifi fast solution:
      $vMatrix->{uivisibleof}->[$c]=1 if ($fieldlist->[$c]->Type() eq "MatrixHeader");
 
      $vMatrix->{htmldetailof}->[$c]=
         $fieldlist->[$c]->htmldetail("HtmlDetail",current=>$rec);
      next if (!($vMatrix->{uivisibleof}->[$c]));
      next if (!($vMatrix->{htmldetailof}->[$c]));
       
      my @fieldgrouplist=($fieldlist->[$c]->{group});
      if (ref($fieldlist->[$c]->{group}) eq "ARRAY"){
         @fieldgrouplist=@{$fieldlist->[$c]->{group}};
      }
      $vMatrix->{fieldgrouplist}->[$c]=\@fieldgrouplist;
      next if (!in_array($viewgroups,"ALL") &&
               !in_array($viewgroups,$vMatrix->{fieldgrouplist}->[$c]));
              
      $fieldlist->[$c]->extendFieldHeader($self->{WindowMode},$rec,
                                          \$self->{fieldHeaders}->{$name});
      $fieldlist->[$c]->extendPageHeader($self->{WindowMode},$rec,
                                          \$self->{fieldsPageHeader});

      my $grouplabel=$fieldlist->[$c]->grouplabel($rec);
      $vMatrix->{fieldhalfwidth}->{$name}=$fieldlist->[$c]->htmlhalfwidth();
      foreach my $fieldgroup (@fieldgrouplist){
         if ((in_array($viewgroups,$fieldgroup) ||
              in_array($viewgroups,"ALL") ) && 
             (!grep(/^$fieldgroup$/,@{$vMatrix->{grouplist}}))){
            push(@{$vMatrix->{grouplist}},$fieldgroup);
            $vMatrix->{grouplabel}->{$fieldgroup}=0;
         }
         $vMatrix->{grouplabel}->{$fieldgroup}=1 if ($grouplabel);
         if ($vMatrix->{fieldhalfwidth}->{$name}){
            $vMatrix->{grouphavehalfwidth}->{$fieldgroup}++;
         }
      }
   }
}



sub ProcessLine
{
   my ($self,$fh,$viewgroups,$rec,$recordview,$fieldbase,$lineno,$msg)=@_;
   my $app=$self->getParent->getParent();
   my $view=$app->getCurrentViewName();
   my @view=$app->getCurrentView();
   my $fieldbase={};
   my $editgroups=[$app->isWriteValid($rec)];
   my $currentfieldgroup=Query->Param("CurrentFieldGroupToEdit"); 
   my $currentid=Query->Param("CurrentIdToEdit"); 
   $self->{fieldHeaders}={} if (!exists($self->{fieldHeaders}));
   if (!exists($self->{fieldsPageHeader})){
      $self->{fieldsPageHeader}=
           "<script language=\"JavaScript\" ".
           "src=\"../../base/load/HtmlDetail.js\"></script>\n".
           "<script language=\"JavaScript\" ".
           "src=\"../../base/load/toolbox.js\"></script>\n".
           "<script language=\"JavaScript\" ".
           "src=\"../../base/load/ContextMenu.js\"></script>\n";
   }
   
   
   if ($self->Config->Param("W5BaseOperationMode") eq "readonly"){
      $editgroups=[];
   }

   if ($self->getParent->{NewRecord}){
      $currentfieldgroup="default";
   #   $currentid="[new]";
   }
   if ($currentfieldgroup eq "default" && 
       !in_array($viewgroups,["default","ALL"])){
      my @candidats=sort(grep(!/^header$/,@$viewgroups));
      $currentfieldgroup=$candidats[0];
   }
   
   my $d="";
   $currentfieldgroup=undef if ($currentfieldgroup eq "");
   my $field=$app->IdField();
   my $id=$field->RawValue($rec);
   if ($self->Context->{LINE}>0){
      $d.="<div style=\"height:2px;overflow:hidden;padding:0;maring:0\">".
          "&nbsp;</div>";
      $d.="<hr class=detailseperator>";
   }
   my $watermark=$app->getRecordWatermarkUrl($rec);
   if ($watermark ne ""){
      $d.=<<EOF
<script language="JavaScript">
function setBG(){
   var e=document.getElementById("HtmlDetail");
   if (e){
      e.style.backgroundPosition="top left";
      e.style.backgroundImage="url($watermark)";
      e.style.backgroundRepeat="repeat";
   }
}
addEvent(window, "load", setBG);
</script>
EOF
   }

   my $module=$app->Module();
   my $appname=$app->App();
   my @detaillist=$app->getSkinFile("$module/tmpl/$appname.detail.*");
   if ($#detaillist==-1){
      @detaillist=$app->getSkinFile("$module/tmpl/$appname.detail")
   }
   my %template=();
   my %grouplabel;
   my @indexdataaddon;
   if ($#detaillist!=-1){
      for(my $c=0;$c<=$#detaillist;$c++){
         my $template=$detaillist[$c];
         my $dtemp;
         if (open(F,"<$template")){
            sysread(F,$dtemp,65535);
            close(F);
         }
         $template{$template}=$dtemp; 
      }
   }
   else{
      my $headerval;
      if ($self->getParent->getParent->can("getRecordHeader")){
         $headerval=$self->getParent->getParent->getRecordHeader($rec);
      }
      my $H="";
      $headerval='%objecttitle%' if ($headerval eq "");
      my $s=$self->getParent->getParent->T($self->getParent->getParent->Self,
                                           $self->getParent->getParent->Self);
      my $recordimg=$self->getParent->getParent->getRecordImageUrl($rec);
      my $subheader="&nbsp;";

      if ($self->getParent->getParent->can("getRecordHtmlDetailHeader")){
         $H=$self->getParent->getParent->getRecordHtmlDetailHeader($rec);
      }
      else{ 
         $H="<h1 class=detailtoplineobj>$s:</h1>".
            "<h2 class=detailtoplinename>$headerval</h2>";
         $recordimg=$self->getParent->getParent->getRecordImageUrl($rec);
         $subheader=$self->getParent->getParent->getRecordSubHeader($rec);
      }
      if ($recordimg ne ""){
         $recordimg="<img class=toplineimage src=\"$recordimg\">";
      }
      my $ByIdLinkStart="";
      my $ByIdLinkEnd="";
      my $dragname="";
      if ($id ne ""){
         if (grep(/^ById$/,
                  $self->getParent->getParent->getValidWebFunctions())){
            my $targeturl="ById/$id";
            if ($self->getParent->getParent->can("allowAnonymousByIdAccess")){
               if ($self->getParent->getParent->allowAnonymousByIdAccess()){
                  my $s=$self->getParent->getParent->Self();
                  $s=~s/::/\//g;
                  $targeturl="../../../public/$s/ById/$id";
               }
            }
            $ByIdLinkStart="<a id=toplineimage target=_blank title=\"".
            $self->getParent->getParent->T("use this link to reference this ".
            "record (f.e. in mail)")."\" href=\"$targeturl\">";
            $ByIdLinkEnd="</a>";
         }
         if ($self->getParent->getParent->can("getRecordHeaderField")){
            my $fobj=$self->getParent->getParent->getRecordHeaderField($rec);
            if (defined($fobj)){
               $dragname=$self->getParent->getParent->Self;
               $dragname="w5base://".$dragname."/Show/".$id."/".$fobj->Name(); 
            }
         }
      }
      my $sfocus;
      if ($currentfieldgroup ne ""){
         #$sfocus="setFocus(\"\");";
         $sfocus="setEnterSubmit(document.forms[0],DetailEditSave);";
      #   $sfocus="setFocus(\"\");".
      #           "setEnterSubmit(document.forms[0],DetailEditSave);";
      }
      $template{"header"}=<<EOF;
<div id="context_menu" class="context_menu">
 <table cellspacing="1" cellpadding="2" border="0">

  <tr>
   <td class="std" onMouseOver="this.className='active';" 
       onMouseOut="this.className='std';">ContextMenu Test</td>
  </tr>

 </table>
</div>

<a name="index"></a>
<div style="height:4px;border-width:0;overflow:hidden">&nbsp;</div>
<div id=detailtopline class=detailtopline>
   <table width="100%" cellspacing=0 cellpadding=0>
      <tr>
<td rowspan=2 width=1%>$ByIdLinkStart$recordimg$ByIdLinkEnd</a></td>
      <td class=detailtopline>
<table border=0 cellspacing=0 width="100%" style="table-layout:fixed;overflow:hidden"><tr>
<td class=detailtopline align=left>$H
<div style="display:none;visibility:hidden;" id=WindowTitle>$s: $headerval</div>
</td></tr></table>
</td>
      </tr><tr>
      <td class=detailtopline align=right>$subheader</td>
      </tr>
   </table>
</div>

<script language="JavaScript">
function setTitle()
{
   var t=window.document.getElementById("WindowTitle");
   parent.document.title=t.innerHTML;
   if ("$dragname"!=""){
      var toplineimage=document.getElementById("toplineimage");
      addEvent(toplineimage, 'dragstart', function (event) {
         event.dataTransfer.setData('Text', "$dragname");
      });
   }
   return(true);
}
addEvent(window, "load", setTitle);

$sfocus
</script>
EOF

      my @fieldlist=@$recordview;
      my $vMatrix={
         grouplist=>[],         # the list of groups, needs to be displayed
         grouplabel=>{},        # the group labels
         grouphavehalfwidth=>{},# the group have min. 1 halfwidth entry
         uivisibleof=>[],       # field is uivisible
         htmldetailof=>[],      # field ist in htmldetail
         fieldhalfwidth=>{},    # field have half width entry
         fieldgrouplist=>[]     # resolved groups of a field
      };
                      
      $self->calcViewMatrix($rec,$vMatrix,$fieldbase,\@fieldlist,$viewgroups);

      my $spec=$self->getParent->getParent->LoadSpec($rec);
      foreach my $group (@{$vMatrix->{grouplist}}){
         my $subfunctions="topedit,editend";
         my $subblock="";
         my $grpentry=$app->getGroup($group,current=>$rec);
         my $col=0;
         my $MaxMatrixCol=0;
         my $CurMatrixCol=0; 
         for(my $c=0;$c<=$#fieldlist;$c++){
            my $name=$fieldlist[$c]->Name();
            next if (!($vMatrix->{uivisibleof}->[$c]));
            next if (!($vMatrix->{htmldetailof}->[$c]));

            if (in_array($vMatrix->{fieldgrouplist}->[$c],$group)){
               if ($fieldlist[$c]->Type() eq "WebLink"){ # WebLink special
                  push(@indexdataaddon,{                 # handling
                     href=>$fieldlist[$c]->RawValue($rec),
                     target=>'_blank',
                     label=>$fieldlist[$c]->Label()});
                  next;
               }
               my $valign=$fieldlist[$c]->valign();
               $valign=" valign=$valign";
               $valign=" valign=top" if ($fieldlist[$c]->can("EditProcessor"));
               if (!($fieldlist[$c]->can("EditProcessor"))){ 
                  $subfunctions="edit,cancel,save";
               }
               my $fieldspec="";
               my $fieldspecfunc="";
               if (defined($spec->{$name})){
                  $fieldspec="<div id=\"fieldspec_$name\" ".
                             "class=detailfieldspec>".
                             "<table width=\"100%\" ".
                             "style=\"table-layout:fixed\">".
                             "<tr><td><span class=detailfieldspec>".
                             $spec->{$name}."</span></td></tr></table></div>";
                  $fieldspecfunc="OnMouseOver=
                                  \"displaySpec(this,'fieldspec_$name');\"";
               }
               my $prefix=$fieldlist[$c]->dlabelpref(current=>$rec);
               if (defined($fieldlist[$c]->{jsonchanged})){
                  my $n="jsonchanged_".$name;
                  if (!grep(/^$n$/,@{$self->Context->{jsonchanged}})){
                     push(@{$self->Context->{jsonchanged}},$n);
                  }
               }
               my $halfwidth=$vMatrix->{fieldhalfwidth}->{$name};
               $subblock.="<tr class=fline>" if ($col==0);
               if ($fieldlist[$c]->Type() eq "Textarea" ||
                   $fieldlist[$c]->Type() eq "Container" ||
                   $fieldlist[$c]->Type() eq "Htmlarea"){
                  my $datacolspan=2;
                  $datacolspan=4 if ($vMatrix->{grouphavehalfwidth}->{$group});
                  $datacolspan=2 if ($halfwidth);
                  $subblock.=<<EOF;
<td class=fname$valign colspan=$datacolspan><span $fieldspecfunc>$prefix\%$name(label)%:</span>$self->{'fieldHeaders'}->{$name}<br>$fieldspec \%$name(detail)\%</td>
EOF
               }
               elsif ($fieldlist[$c]->Type() eq "TimeSpans"){
                  my $datacolspan=1;
                  $datacolspan=4 if ($vMatrix->{grouphavehalfwidth}->{$group});
                  $datacolspan=2 if ($halfwidth);
                  $subblock.=<<EOF;
<td class=fname$valign colspan=$datacolspan>$self->{'fieldHeaders'}->{$name}\%$name(detail)\%</td>
EOF
               }
               elsif ($fieldlist[$c]->can("EditProcessor")){
                  my $datacolspan=2;
                  $datacolspan=4 if ($vMatrix->{grouphavehalfwidth}->{$group});
                  $datacolspan=2 if ($halfwidth);
                  $subblock.=<<EOF;
<td class=fname$valign colspan=$datacolspan $fieldspecfunc>$self->{'fieldHeaders'}->{$name}$fieldspec\%$name(detail)\%</td>
EOF

               }
               elsif ($fieldlist[$c]->Type() eq "Message" ||
                      $fieldlist[$c]->Type() eq "OSMap" ||
                      $fieldlist[$c]->Type() eq "GoogleMap"){
                  my $datacolspan=2;
                  $datacolspan=4 if ($vMatrix->{grouphavehalfwidth}->{$group});
                  $datacolspan=2 if ($halfwidth);
                  $subblock.=<<EOF;
<td class=finput$valign colspan=$datacolspan>$self->{'fieldHeaders'}->{$name}\%$name(detail)\%</td>
EOF

               }
               elsif ($fieldlist[$c]->Type() eq "MatrixHeader"){
                  my $label=$fieldlist[$c]->Label();
                  $MaxMatrixCol=$#{$label};
                  $subblock.=join("\n",
                                map({
                                   "<td class=finput$valign colspan=1 ".
                                   "align=center><b>".
                                   $_.
                                   "</b></td>";
                                } @$label));
               }
               else{
                  my $align=$fieldlist[$c]->align("Detail");
                  $align="left" if ($align eq "");
                  my $datacolspan=1;
                  $datacolspan=3 if ($vMatrix->{grouphavehalfwidth}->{$group});
                  $datacolspan=1 if ($halfwidth);
                  if ($MaxMatrixCol){
                     if ($CurMatrixCol==0){
                        $subblock.="<td class=fname$valign style=\"width:20%;\">$fieldspec<span $fieldspecfunc>$prefix\%$name(label)%:</span>$self->{'fieldHeaders'}->{$name}</td>";
                     }
                     $subblock.=<<EOF;
<td class=finput colspan=$datacolspan>
<table border=0 cellspacing=0 cellpadding=0 width="100%" style="table-layout:fixed;overflow:hidden"><tr>
<td>
<div style="text-align:$align;width:100%;overflow:hidden">
                          \%$name(detail)\%</div>
</td></tr></table>
</td>
EOF
                     $CurMatrixCol++;
                     if ($CurMatrixCol>=$MaxMatrixCol){
                        $CurMatrixCol=0;
                     }
                  }
                  else{
                     $subblock.=<<EOF;
         <td class=fname$valign style="width:20%;">$fieldspec<span $fieldspecfunc>$prefix\%$name(label)%:</span>$self->{'fieldHeaders'}->{$name}</td>
         <td class=finput colspan=$datacolspan>
<table border=0 cellspacing=0 cellpadding=0 width="100%" style="table-layout:fixed;overflow:hidden"><tr>
<td>
<div style="width:100%;overflow:hidden">
                          \%$name(detail)\%</div>
</td></tr></table>
</td>
EOF
                  }
               }
               if ($fieldlist[$c]->Type() ne "WebLink"){
                  $col++;
                  if ($CurMatrixCol==0){
                     if ($halfwidth){
                        if ($col>=2){
                           $col=0;
                        } 
                     }
                     else{
                        if ($col>=1){
                           $col=0;
                        } 
                     }
                     $subblock.="</tr>" if ($col==0);
                  }
               }
            }
         }
         my $grouplabel="fieldgroup.".$group;
         my $groupspec="";
         if (defined($spec->{$grouplabel})){
            $groupspec="<div class=detailgroupspec>".
                       $spec->{$grouplabel}."</div>";
         }
         if (defined($grpentry) && defined($grpentry->{translation})){
            my $tr=$grpentry->{translation};
            $tr=[$tr] if (ref($tr) ne "ARRAY");
            unshift(@$tr,$self->getParent->getParent->Self());
            $grouplabel=$self->getParent->getParent->T($grouplabel,@$tr);
         }
         else{
            $grouplabel=$self->getParent->getParent->T($grouplabel,
                            $self->getParent->getParent->Self());
         }
         if ($grouplabel eq "fieldgroup.default"){
            $grouplabel=$self->getParent->getParent->T(
                        $self->getParent->getParent->Self(),
                        $self->getParent->getParent->Self());
         }
         if ($group=~m/^privacy_/){
            my $privacy=$self->getParent->getParent->T(
                        "privacy information - ".
                        "only readable with rule write or privacy read");
            $grouplabel.="&nbsp;<a title=\"$privacy\">".
                         "<font color=red>!</font></a>";
         }
         $template{$group}.=<<EOF;
<div class=detailframe>
EOF
         if ($vMatrix->{grouplabel}->{$group}){
            $grouplabel{$group}=$grouplabel;
            $grouplabel=~s/#//g;
            $template{$group}.=<<EOF;
 <div class=detailheadline>
 <table width="100%" cellspacing=0 cellpadding=0>
 <tr>
 <td class=detailheadline align=left>
 <h3 class="grouplabel">$grouplabel</h3>
 </td>
 <td class=detailheadline align=right>%DETAILGROUPFUNCTIONS($subfunctions)%</td>
 </tr>
 </table>
 </div>
 $groupspec
EOF
            $grouplabel{$group}=~s/#.*//g;
         }
         $template{$group}.=<<EOF;
 <table class=detailframe border=1>$subblock
 </table>
</div>
EOF
      }
   }


   my $c=0;
   my @blocks=$self->getParent->getParent->sortDetailBlocks([keys(%template)],
                                                            current=>$rec,
                                                            mode=>'HtmlDetail');
   my @indexdata=$app->getRecordHtmlIndex($rec,$id,$viewgroups,
                                          \@blocks,\%grouplabel);
   if ($#indexdataaddon!=-1){
      push(@indexdata,@indexdataaddon);
   }
   if ($#indexdata!=-1){
      my @set;
      my $setno=0;
      my $indexcols=2; 
      for(my $c=0;$c<=$#indexdata;$c++){
         my $chklabel=$indexdata[$c]->{label};
         $chklabel=~s/\<.*?\>//g; # remove html sequences from check
         if (length($chklabel)>40){
            $indexcols=1;last;
         }
      }
      for(my $c=0;$c<=$#indexdata;$c++){
         if ($indexcols==2){
            $setno++ if ($setno==0 && $c>($#indexdata/2));
         }
         if (defined($indexdata[$c])){
            my $link="<a class=HtmlDetailIndex ".
                     "href=\"$indexdata[$c]->{href}\"";
            if (exists($indexdata[$c]->{target})){
               $link.=" target='$indexdata[$c]->{target}'";
            }
            $link.=">";
            $link=~s/\%/\\%/g;
            $set[$setno].="&bull;&nbsp;$link$indexdata[$c]->{label}</a><br>";
         }
      }
      my $indexcoldata=""; # long group names special handling
      for(my $icolnum=0;$icolnum<$indexcols;$icolnum++){
         $indexcoldata.='<td width=40% valign=top>'.
                        '<table style="table-layout:fixed;width:100%" '.
                        'cellspacing=0 cellpadding=0 border=0><tr><td>'.
                        $set[$icolnum].
                        '</td></tr></table>'.
                        '</td>';
      }

      $template{"header"}.=<<EOF;
<center><div class=HtmlDetailIndex style="text-align:center;width:95%">
<hr>
<table style="xtable-layout:fixed;width:98%" border=0 cellspacing=0 cellpadding=0>
<tr>$indexcoldata</tr>
</table>

<hr>
</div></center>
EOF
   }
     


   $self->{WindowMode}="HtmlDetailEdit" if ($currentfieldgroup ne "");
   my $latelastmsg=0;
   if ($currentfieldgroup eq "" && $self->getParent->getParent->LastMsg()){
      $latelastmsg++;
   }
   foreach my $template (@blocks){
      my $dtemp=$template{$template};
      my $fieldgroup=$template;
      my %param=(id               =>$id,
                 current          =>$rec,
                 currentid        =>$currentid,
                 fieldbase        =>$fieldbase,
                 fieldgroup       =>$fieldgroup,
                 editgroups       =>$editgroups,
                 viewgroups       =>$viewgroups,
                 WindowMode       =>$self->{WindowMode},
                 currentfieldgroup=>$currentfieldgroup);
      $self->ParseTemplateVars(\$dtemp,\%param);
      $d.="\n\n<a name=\"fieldgroup_$fieldgroup\"></a>";
      $d.="\n<a name=\"I.$id.$fieldgroup\"></a>\n";
      if ($c>0 || $#detaillist==0){
         my @msglist;
         if ($fieldgroup eq $currentfieldgroup || 
             ($fieldgroup eq "default" && $latelastmsg)){
            @msglist=$self->getParent->getParent->LastMsg();
         }
         $d.="<div class=lastmsg>".join("<br>\n",map({
           if ($_=~m/^ERROR/){
              $_="<font style=\"color:red;\">".$_."</font>";
           }
           if ($_=~m/^WARN/){
              $_="<font style=\"color:brown;\">".$_."</font>";
           }
           $_;
         } @msglist))."</div>";
      }
      $d.=$dtemp;
      $c++;
   }
   $self->Context->{LINE}+=1;
   return($d);
}





sub ProcessBottom
{
   my ($self,$fh,$rec,$msg)=@_;
   my $app=$self->getParent->getParent();
   my $view=$app->getCurrentViewName();
   my @view=$app->getCurrentView();
   my @pers=qw(CurrentFieldGroupToEdit isCopyFromId CurrentIdToEdit OP
               ScrollY AllowClose CurrentDetailMode);
   my $idname=$app->IdField->Name();
   if (defined($idname) && defined(Query->Param($idname))){
      push(@pers,$idname);
   }
   if (defined($idname) && defined(Query->Param("search_".$idname))){
      Query->Param($idname=>Query->Param("search_".$idname));
      push(@pers,$idname);
   }
   my $d=$app->HtmlPersistentVariables(@pers);
   #$d.="<div style=\"height:".$app->DetailY."px\"></div>";
   $d.="</div>";
   
   my $date=new kernel::Field::Date();
   $date->setParent($self->getParent->getParent());
   my ($str,$ut,$dayoffset)=$date->getFrontendTimeString("HtmlDetail",
                                                         NowStamp("en"));
   my $str2=NowStamp("en");
   my $label=$self->getParent->getParent->T("Condition to:");
   my $user=$ENV{REMOTE_USER};

   my $UserCache=$self->getParent->getParent->Cache->{User}->{Cache};
   if (defined($UserCache->{$ENV{REMOTE_USER}})){
      $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
   }
   if (defined($UserCache->{fullname})){
      $user.=" - ".$UserCache->{fullname};
   }
   $d.="<br><br>";
   $d.="<div style=\"width:100%;padding:0px;margin:0px\">";
   if (!($self->getParent->{NewRecord})){
       $d.="<div class=detailbottomline>".
           "$label $str $ut - $user</div></div>";
   }
   $d.="</div>";

   if ($#{$self->Context->{jsonchanged}}!=-1){
      $d.="\n<script type=\"text/javascript\" language=JavaScript>\n";
      foreach my $f (@{$self->Context->{jsonchanged}}){
         $d.="if (typeof($f)!=\"undefined\"){\n   $f('init');\n}\n";
      }
      $d.="</script>\n";
   }
   $d.="\n<script language=JavaScript>\n";
   if (Query->Param("CurrentIdToEdit") ne ""){
      $d.="if (parent.setEditMode){parent.setEditMode(1);}";
   }
   else{
      $d.="if (parent.setEditMode){parent.setEditMode(0);}";
   }
   $d.="</script>\n";

   return($d);
}


sub getHttpFooter
{  
   my $self=shift;
   my $scrolly=Query->Param("ScrollY");
   $scrolly=0 if (!defined($scrolly));
   my $d="</form></div></body>";
   $d.="</html>";
   if ($scrolly!=0){
      $d.="<script type=\"text/javascript\" language=JavaScript>".
           # IE Hack to restore
          "window.document.body.scrollTop=$scrolly;".# Scroll Position
          "</script>";
   }
   return($d);
}

sub MkFunc
{
   my $self=shift;
   my $class=shift;
   my $js=shift;
   my $name=shift;

   return("<a class=$class href=JavaScript:$js>".
     $self->getParent->getParent->T($name,"kernel::Output::HtmlDetail")."</a>");
}

sub DetailFunctions
{
   my $back="&nbsp;";
   if ($#_!=-1){
      $back="&bull; ".join(" &bull; ",@_)." &bull;";
   }
   $back="<div class=detailfunctions>".
         "<span style=\"\">".
         "<a class=HtmlDetailIndex style=\"cursor:n-resize\" href=\"#index\">".
         "&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;</a></span>".
         $back."</div>";
   return($back);
}


sub findtemplvar
{
   my $self=shift;
   my ($opt,$vari,@param)=@_;
   my $fieldgroup="default";
   $fieldgroup=$opt->{fieldgroup} if (defined($opt->{fieldgroup}));

   if ($vari eq "DETAILGROUPFUNCTIONS"){
      my @func;
      my $editgroups=$opt->{editgroups};
      $editgroups=[] if (!ref($editgroups) eq "ARRAY");
      if (defined($opt->{currentfieldgroup})){
         if ($opt->{currentfieldgroup} eq $opt->{fieldgroup} &&
             $opt->{currentid} eq $opt->{id}){
            if (grep(/^save$/,@param)){
               if (grep(/^$opt->{fieldgroup}$/,@{$editgroups}) ||
                   grep(/^$opt->{fieldgroup}\..+$/,@{$editgroups}) ||
                   grep(/^ALL$/,@{$editgroups})){
                  push(@func,$self->MkFunc("detailfunctions",
                                           "DetailEditSave()","save")); 
               }
            }
            if (grep(/^cancel$/,@param)){
               if ($opt->{id} ne ""){
                  push(@func,$self->MkFunc("detailfunctions",
                                           "DetailEditBreak()","cancel")); 
               }
            }
            if (grep(/^editend$/,@param)){
               push(@func,$self->MkFunc("detailfunctions",
                                        "DetailTopEditBreak()","finish edit")); 
            }
         }
         else{
            @func=();
         }
      }
      else{
         if (grep(/^edit$/,@param)){
            if (grep(/^$opt->{fieldgroup}$/,@{$editgroups}) ||
                grep(/^$opt->{fieldgroup}\..+$/,@{$editgroups}) ||
                grep(/^ALL$/,@{$editgroups})){
               my $qid=$opt->{id};
               $qid=~s/"/\\"/g;
               push(@func,$self->MkFunc("detailfunctions",
                                 "DetailEdit(\"$opt->{fieldgroup}\",".
                                 "\"$qid\")","edit")); 
            }
         }
         if (grep(/^topedit$/,@param)){
            if (grep(/^$opt->{fieldgroup}$/,@{$editgroups}) ||
                grep(/^ALL$/,@{$editgroups})){
               push(@func,$self->MkFunc("detailfunctions",
                                        "DetailTopEdit(\"$opt->{fieldgroup}\",".
                                        "\"$opt->{id}\")","edit")); 
            }
         }
      }
      return(DetailFunctions(@func));
   }

   return($self->SUPER::findtemplvar(@_));   
}



1;