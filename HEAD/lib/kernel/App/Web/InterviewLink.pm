package kernel::App::Web::InterviewLink;
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

sub HtmlInterviewLink
{
   my ($self)=@_;
   my $idname=$self->IdField()->Name();
   my $id=Query->Param($idname);
   my $imode=Query->Param("IMODE");
   my $interviewcatid=Query->Param("interviewcatid");
   my $archiv=Query->Param("archiv");
   $self->ResetFilter();
   $self->SetFilter({$idname=>\$id});
   my ($rec,$msg)=$self->getOnlyFirst(qw(ALL));
   if (defined($rec)){
      if ($interviewcatid eq ""){ 
         print $self->HttpHeader();
         print $self->HtmlHeader(body=>1,
                                 js=>['toolbox.js',
                                      'jquery.js',
                                      'jquery.ui.js',
                                      'firebug-lite.js',
                                      'jquery.locale.js'],
                                 style=>['default.css','work.css',
                                         'Output.HtmlDetail.css',
                                         'kernel.App.Web.css',
                                         'kernel.App.Web.Interview.css',
                                         'jquery.ui.css']);
         print $self->InterviewMainForm($rec,$idname,$id);
         print $self->HtmlBottom(body=>1);
      }
      else{
         $self->InterviewSubForm($rec,$interviewcatid,$imode);
      }
   }
}

sub InterviewSubForm
{
   my $self=shift;
   my $rec=shift;
   my $interviewcatid=shift;
   my $imode=shift;
   my $state=$rec->{interviewst};

   my $lastquestclust;
   my @q;
   my $HTMLjs;
   foreach my $qrec (@{$state->{TotalActiveQuestions}}){
      my $d;
      if ($imode eq "open"){
         if (exists($state->{AnsweredQuestions}->
                    {interviewid}->{$qrec->{id}}) &&
             $state->{AnsweredQuestions}->
                   {interviewid}->{$qrec->{id}}->{answer} ne ""){
            next;
         }
      }
      if ($qrec->{AnswerViewable}){
         if ($interviewcatid eq $qrec->{interviewcatid}){
            if (!defined($lastquestclust) ||
                $lastquestclust ne $qrec->{questclust}){
               $d.="<div class=\"InterviewQuestClust\">".
                   $qrec->{questclust}."</div>";
               $d.="\n<div class=InterviewQuestHead>".
                   "<table border=0 class=InterviewQuestHead width=95%>".
                   "<tr><td class=InterviewQuestHead></td>".
                   "<td class=InterviewQuestHead width=50 align=center>".
                   "relevant</td>".
                   "<td class=InterviewQuestHead width=180 ".
                   "align=center valign=top>".
                   $self->T("answer","base::interanswer").
                   "</td><td width=1%>&nbsp;&nbsp;</td>".
                   "</tr></table></div>";
            }
            $d.="\n<div class=InterviewQuest><form name=\"F$qrec->{id}\">".
                "<table class=InterviewQuest width=95% 
                  border=0 >".
                "<tr><td><div onclick=switchExt($qrec->{id})>".
                "<span class=InterviewQuestion>".
                $qrec->{name}."</span></div>".
                "</td><td width=50 nowrap valign=top>".
                "<div id=relevant$qrec->{id}>$qrec->{HTMLrelevant}</div></td>".
                "<td width=180 nowrap valign=top>".
                "<div class=InterviewQuestAnswer ".
                "id=answer$qrec->{id}>$qrec->{HTMLanswer}</div></td>".
                "<td width=1% align=center valign=top>".
                "<div class=qhelp onclick=qhelp($qrec->{id})><img border=0 ".
                "src=\"../../../public/base/load/questionmark.gif\">".
                "</div></td>".
                "</tr>".
                "<tr><td colspan=4>".
                "<div id=EXT$qrec->{id} ".
                "style=\"display:none;visibility:hidden\">".
                "<div id=comments$qrec->{id}>$qrec->{HTMLcomments}</div>".
                "</div></td>".
                "</tr></table></form></div>";
            push(@q,$d);
            $HTMLjs.=$qrec->{HTMLjs};
            $lastquestclust=$qrec->{questclust};
            $lastquestclust="" if (!defined($lastquestclust));
         }
      }
   }
   print $self->HttpHeader("text/xml");
   if ($HTMLjs ne ""){
      $HTMLjs="function Init$interviewcatid(){$HTMLjs} Init$interviewcatid(0)";
   }
   else{
      $HTMLjs="function Init$interviewcatid(){}";
   }
   my $res=hash2xml({document=>{result=>'ok',q=>\@q,js=>$HTMLjs,
                                exitcode=>0}},{header=>1});
   print $res;
}


sub InterviewPartners
{
   my $self=shift;
   my $rec=shift;


   return(''=>$self->T("Databoss",$self->Self)) if (!defined($rec));
   return(''=>[$rec->{'databossid'}]) if (exists($rec->{'databossid'}));
   return(''=>[]);
}

sub InterviewMainForm
{
   my $self=shift;
   my $rec=shift;
   my $idname=shift;
   my $id=shift;
   my $state=$rec->{interviewst};
   my $label=$self->getRecordHeader($rec);
   my $d="<div class=Interview><div style=\"padding:2px\">";
   my $srelevant="<select name=relevant onchange=submitChange(this) >".
                 "<option value=\"1\">Ja</option>".
                 "<option value=\"0\">Nein</option>".
                 "</select>";
   my $scomments="<textarea name=comments onchange=submitChange(this) ".
                 "rows=2 style=\"width:100%\"></textarea>";

   $d.=<<EOF;
<script language="JavaScript">

function qhelp(id)
{
   openwin("../../base/interview/Detail?ModeSelectCurrentMode=Question&id="+id,"_blank",
          "height=400,width=600,toolbar=no,status=no,"+
          "resizable=yes,scrollbars=auto");
}

function switchExt(id)
{
   var e=document.getElementById("EXT"+id);
   if (e.style.display=="none" || e.style.display==""){
      e.style.display="block";
      e.style.visibility="visible";
   }
   else{
      e.style.display="none";
      e.style.visibility="hidden";
   }
}
function switchQueryBlock(o,id,imode)
{
   var e=document.getElementById("BLK"+id);
   if (e.style.display=="none" || e.style.display==""){
      e.innerHTML='<center><img src="../../base/load/ajaxloader.gif"></center>';
      e.style.display="block";
      e.style.visibility="visible";
      var o=document.getElementById("BLKON"+id);
      o.style.display="block";
      o.style.visibility="visible";
      var o=document.getElementById("BLKOFF"+id);
      o.style.display="none";
      o.style.visibility="hidden";

      var xmlhttp=getXMLHttpRequest();
      var path='HtmlInterviewLink';
      xmlhttp.open("POST",path);
      xmlhttp.onreadystatechange=function() {
       if (xmlhttp.readyState==4 && 
           (xmlhttp.status==200 || xmlhttp.status==304)){
          var xmlobject = xmlhttp.responseXML;
          var result=xmlobject.getElementsByTagName("q");
          var d="";
          for (var i = 0; i < result.length; ++i){
              var childNode=result[i].childNodes[0];
              if (childNode){
                 d+=childNode.nodeValue;
              }
          }
          if (d!=""){
             e.innerHTML=d;
             var jso=xmlobject.getElementsByTagName("js");
             for (var i = 0; i < jso.length; ++i){
                 var childNode=jso[i].childNodes[0];
                 if (childNode){
                    eval(childNode.nodeValue);
                 }
             }
          }
          else{
             e.innerHTML="Nix meh drin!";
          }
       }
      }
      var q="$idname=$id&interviewcatid="+id+"&IMODE="+imode;
      xmlhttp.setRequestHeader("Content-type","application/x-www-form-urlencoded");
      var r=xmlhttp.send(q);
   }
   else{
      e.style.display="none";
      e.style.visibility="hidden";
      var o=document.getElementById("BLKOFF"+id);
      o.style.display="block";
      o.style.visibility="visible";
      var o=document.getElementById("BLKON"+id);
      o.style.display="none";
      o.style.visibility="hidden";
   }
}
function loadForm(id,xmlobject)
{
   var v=new Array('answer','comments','relevant','js');
   var js="";

   for (var i = 0; i < v.length; ++i){
      var a=document.getElementById(v[i]+id);
      var result=xmlobject.getElementsByTagName("HTML"+v[i])[0];
      var childNode=result.childNodes[0];
      if (childNode){
         if (v[i]=="js"){
            js+=childNode.nodeValue;
         }
         else{
            a.innerHTML=childNode.nodeValue;
         }
      }
   }
   if (js!=""){
      eval(js);
   }
}
function submitChange(o)
{
   var vname=o.name;
   var vval=o.value;
   var qid=o.form.name;
   qid=qid.substring(1,qid.length); // F am Anfang abscheinden
   var parentid=document.getElementById("parentid").value;
   var parentobj=document.getElementById("parentobj").value;

   var xmlhttp=getXMLHttpRequest();
   var path='../../base/interanswer/Store';
   xmlhttp.open("POST",path);
   xmlhttp.onreadystatechange=function() {
    if (xmlhttp.readyState==4 && 
        (xmlhttp.status==200 || xmlhttp.status==304)){
       loadForm(qid,xmlhttp.responseXML);
    }
   }
   var q="vname="+vname+"&vval="+Url.encode(vval)+"&"+"parentid="+parentid+"&"+
         "parentobj="+parentobj+"&"+"qid="+qid;
   xmlhttp.setRequestHeader("Content-type","application/x-www-form-urlencoded");
   var r=xmlhttp.send(q);

  // alert("changed "+vname+" newval="+vval+" in question "+qid+" parentid="+parentid+" parentobj="+parentobj);
}

function setA(formid,val)
{
   if (document.forms['F'+formid]){
      if (document.forms['F'+formid].elements['answer']){
         document.forms['F'+formid].elements['answer'].value=val;
         submitChange(document.forms['F'+formid].elements['answer']);
      }
      else{
         alert("ERROR: can not identify answer element");
      }
   }
   else{
      alert("ERROR: can not identify form");
   }
}

</script>
EOF
   my @sl=('current'=>$self->T("current questions"),
           'open'=>$self->T("not answered questions"),
           'analyses'=>$self->T("analyses"));
   my $s="<select name=IMODE onchange=\"document.forms['control'].submit();\" ".
         "style=\"width:200px\">";
   my $imode=Query->Param("IMODE");
   $imode="current" if ($imode eq "");
   while(my $k=shift(@sl)){
      my $v=shift(@sl);
      $s.="<option value=\"$k\"";
      $s.=" selected" if ($imode eq $k);
      $s.=">$v</option>";
   }
   $s.="</select>";

   my $help=$self->findtemplvar({},"GLOBALHELP","article",
                 "W5Base ".$self->SelfAsParentObject." Config-Item-Interview|".
                 "W5Base Config-Item-Interview");
   $d.="<form name=\"control\">";
   $d.="<div class=header>";
   $d.="<table border=0 width=97%><tr><td width=5>&nbsp;</td>";
   $d.="<td align=left>".$label."</td>";
   $d.="<td align=right width=1%>".$s."</td><td width=20>".
       $help."</td></tr></table>";
   $d.="</div>";
   $d.=sprintf("<input type=hidden name=$idname value=\"%s\">",$id);
   $d.=sprintf("<input type=hidden id=parentid value=\"%s\">",$id);
   $d.=sprintf("<input type=hidden id=parentobj value=\"%s\">",
               $self->SelfAsParentObject);
      $d.="<input type=submit>";
   $d.="</form>";

   if ($imode eq "analyses"){
      $d.="<script language=\"JavaScript\">";
      $self->ResetFilter();
      $self->SetFilter({$idname=>\$id});

      my $output=new kernel::Output($self);
      if ($output->setFormat("JSON")){
         $self->SetCurrentView("interviewst");
         $d.=$output->WriteToScalar(HttpHeader=>0);
      }
      $d.="</script>";
      $d.="<script language=\"JavaScript\">";
      $d.=<<EOF;
//#
//#for (i in W5Base.AL_TCom.appl.Result){
//#      d+="<tr>";
//#      d+="<th width=1% nowrap>"+iparent[i][key]+"</td>";
//#
//#
//#
//#}
\$(document).ready(function(){
   console.log(window.document.W5Base);
});
EOF
      $d.="</script>";
      $d.="<div id=analyses></div>";
   }
   else{
      my $lastquestclust;
      my $lastqblock;
      my $blknum=0;
    
      my @blklist;
      my @blkid;
    
      foreach my $qrec (@{$state->{TotalActiveQuestions}}){
         if ($imode eq "open"){
            if (exists($state->{AnsweredQuestions}->
                       {interviewid}->{$qrec->{id}}) &&
                $state->{AnsweredQuestions}->
                      {interviewid}->{$qrec->{id}}->{answer} ne ""){
               next;
            }
         }
         if ($lastqblock ne $qrec->{queryblock}){
            push(@blklist,$qrec->{queryblock});
            push(@blkid,$qrec->{interviewcatid});
         }
         $lastqblock=$qrec->{queryblock};
      }
      $d.="</div>" if ($lastqblock ne "");
     # push(@blklist,"open");
      $lastqblock=undef;
      for(my $c=0;$c<=$#blklist;$c++){
         my $blk=$blklist[$c];
         my $blkid=$blkid[$c];
         $d.="\n</div>\n" if ($lastqblock ne "");
         $d.="<div class=InterviewQuestBlockFancyHead>$blk - $label</div>";
         $d.="\n<div ".
             "onclick=\"switchQueryBlock(this,'${blkid}','${imode}');\" ".
             "class=InterviewQuestBlockHead>".
             "\n<div id=BLKON${blkid} class=OnOfSwitch ".
             "style=\"visible:hidden;display:none\">".
             "<img border=0 src=\"../../../public/base/load/minus.gif\"></div>".
             "<div id=BLKOFF${blkid} class=OnOfSwitch ".
             "style=\"visible:visible;display:block\">".
             "<img border=0 src=\"../../../public/base/load/plus.gif\"></div>".
             "<div style=\"float:none\">$blk</div></div>";
         $d.="\n<div id=BLK${blkid} name=\"$blk\" class=InterviewQuestBlock>";
         $lastqblock=$blk;
      }
      $d.="</div>" if ($lastqblock ne "");
    
      $d.="</div></div>";
   }
   return($d);
}


######################################################################

1;
