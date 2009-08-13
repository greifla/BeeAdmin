package tssc::mgr;
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
use kernel::App::Web;
use kernel::Field;
use kernel::TemplateParsing;
use tssc::lib::io;
@ISA=qw(kernel::App::Web  kernel::TemplateParsing tssc::lib::io);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}


sub getValidWebFunctions
{
   my $self=shift;
   return("Main",
          $self->SUPER::getValidWebFunctions());
}



sub Main
{
   my $self=shift;

   my $userid=$self->getCurrentUserId();
   my $user=getModuleObject($self->Config,"base::user");
   $user->SetFilter({userid=>\$userid});
   my ($urec,$msg)=$user->getOnlyFirst(qw(posix));


   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css',],
                           title=>'ServiceCenter Incident Creator',
                           js=>[qw( toolbox.js ContextMenu.js)],
                           body=>1,form=>1,target=>'result');
   print <<EOF;
<style>
body{
   overflow:hidden;
}
</style>
<script language="JavaScript">
function showWork(e)
{
   if (e.id=='NewApplIncident'){
      frames['work'].document.location.href="../inm/Process";
   }
   if (e.id=='MyIncidentMgr'){
      frames['work'].document.location.href="../inm/Manager";
   }
   if (e.id=='MyIncidentList'){
      frames['work'].document.location.href="../inm/NativResult?search_openedby=HVOGLER&search_status=!closed&AutoSearch=1";
   }

}
function doOP(o,op,target)
{
   var param="";
   var e=document.getElementById(target);
   var l=document.getElementById("loading");
   o.disabled="disabled";

   e.innerHTML=l.innerHTML;
   param+="&SCUsername="+encodeURI(document.getElementById("SCUsername").value);
   param+="&SCPassword="+encodeURI(document.getElementById("SCPassword").value);
   param+="&Do="+encodeURI(op);
   if (op!="Login"){
      for(c=0;c<frames['work'].document.forms[0].elements.length;c++){
         param+="&"+frames['work'].document.forms[0].elements[c].name+"="+
                 encodeURI(frames['work'].document.forms[0].elements[c].value);
      }
   }
   var xmlhttp=getXMLHttpRequest();
   xmlhttp.open("POST","../inm/Process",true);
   xmlhttp.onreadystatechange=function() {
    if (xmlhttp.readyState==4 && 
        (xmlhttp.status==200 || xmlhttp.status==304)){
       var xmlobject = xmlhttp.responseXML;
       var result=xmlobject.getElementsByTagName("htmlresult");

       var d="";
       for (var i = 0; i < result.length; ++i){
           var childNode=result[i].childNodes[0];
           if (childNode){
              d+=childNode.nodeValue;
           }
       }
       e.innerHTML=d;
       o.disabled="";
    }
   }
   xmlhttp.setRequestHeader("Content-type","application/x-www-form-urlencoded");
   xmlhttp.setRequestHeader("Content-length",param.length);
   xmlhttp.setRequestHeader("Connection","close");

   var r=xmlhttp.send(param);
}
</script>
EOF
   my $SCUsername=Query->Param("SCUsername");
   my $SCPassword=Query->Param("SCPassword");
   if (Query->Param("login")){
      printf("login ok SCUsername=$SCUsername\n");
   }
   else{
      if ($SCUsername eq ""){
         $SCUsername=$urec->{posix};
      }
      print("<table width=100% height=100% border=0 cellspacing=0 cellpadding=0>");
      print("<tr height=1%><td>");
      print <<EOF;
<div id=loading style=\"width:0px;height:0px;padding:0px;margin:0px;overflow:hidden;postion:absolute;visibility:hidden;display:none">
<center><img src="../../base/load/ajaxloader.gif"></center>
</div>
<table border=0 cellspacing=0 cellpadding=0>
<tr>
<td width=1% nowrap>ServiceCenter SCUsername:</td>
<td width=1%><input type=text id=SCUsername name=SCUsername
                    value="$SCUsername"></td>
<td width=1% nowrap>SCPassword:</td>
<td width=1%><input type=password id=SCPassword name=SCPassword></td>
<td></td>
<td width=1%><input type=button id=Restart name=Restart value="Restart"></td>
</tr>
</table>
EOF
      print("</td></tr>");
      print("<tr height=1%><td>");
      print(<<EOF);
<input id=NewApplIncident class=opbutton type=button onclick="showWork(this);"
       value="New Application Incident">
<input id=MyIncidentList  class=opbutton type=button onclick="showWork(this);"
       value="list Incidents created by me">
<input id=MyIncidentMgr  class=opbutton type=button onclick="showWork(this);"
       value="Incident Manager">
EOF
      print("</td></tr>");
      print("<tr><td><iframe name=work ".
            "class=subframe src=\"../inm/Manager\"></iframe></td></tr>");
      print("<tr height=1%><td><div style=\"padding:10px;height:40px\" ".
            "id=result></div></td></tr>");
      print("</table>");
   }
   print $self->HtmlBottom(body=>1,form=>1);
}


1;
