package faq::QuickFind;
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
use kernel::TemplateParsing;
@ISA=qw(kernel::App::Web kernel::TemplateParsing);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub Main
{
   my $self=shift;

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','mainwork.css',
                                   'public/faq/load/QuickFind.css'],
                           title=>"FAQ QuickFind",
                           js=>['toolbox.js'],
                           body=>1,form=>1);
   print $self->getParsedTemplate("tmpl/QuickFind",{
            translation=>'faq::QuickFind',
            static=>{
            }});
   print $self->HtmlBottom(body=>1,form=>1);
   return(0);
}

sub globalHelp
{
   my $self=shift;

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','mainwork.css'],
                           title=>"W5Base global search and help system",
                           target=>'Result',
                           action=>'Result',
                           js=>['toolbox.js','cookie.js'],
                           body=>1,form=>1);
   print $self->getParsedTemplate("tmpl/globalHelp",{
               translation=>'faq::QuickFind',
               static=>{
                 remote_user=>$ENV{REMOTE_USER},
                 newwf=>$self->T("start a new workflow","base::MyW5Base"),
                 myjobs=>$self->T("my current jobs","base::MyW5Base")
               }});
   print $self->HtmlBottom(body=>1,form=>1);
   return(0);
}

sub Welcome
{
   my $self=shift;
   my $label=shift;
   my $searchtext=shift;

   print treeViewHeader($label,1);
   my $faq=getModuleObject($self->Config,"faq::article");

   $faq->SecureSetFilter({categorie=>'W5Base*'});

   foreach my $rec ($faq->getHashList(qw(name faqid))){
      print insDoc("foldersTree",$rec->{name},
                   "../../faq/article/ById/".
                   "$rec->{faqid}");
   }
   return(0);
}

sub doSearch
{
   my $self=shift;
   my $label=shift;
   my $searchtext=shift;

   my @stags=();
   if (Query->Param("forum") ne ""){
      push(@stags,"forum");
   }
   if (Query->Param("article") ne ""){
      push(@stags,"article");
   }
   if (Query->Param("ci") ne ""){
      push(@stags,"ci");
   }
   if ($searchtext ne "" && length($searchtext)<3){
      print treeViewHeader("<font color=red>".$self->T("search text to short").
                           "</font>",1);
      return();
   }




   my $found=0;
   if (grep(/^ci$/,@stags)){
      my $tree="foldersTree";
      if (!$found){
         print treeViewHeader($label,1);
      }
      print <<EOF;
function switchTag(id)
{
   var e=document.getElementById(id);
   if (e.style.visibility!="visible"){
      e.innerHTML='<center><img src="../../base/load/loading.gif"></center>';
      e.style.visibility="visible";
      e.style.display="block";
      var xmlhttp=getXMLHttpRequest();
      var path='QuickFindDetail';
      xmlhttp.open("GET",path+"?id="+id);
      xmlhttp.onreadystatechange=function() {
       if (xmlhttp.readyState==4 && 
           (xmlhttp.status==200 || xmlhttp.status==304)){
          var xmlobject = xmlhttp.responseXML;
          var result=xmlobject.getElementsByTagName("htmlresult")[0];
          var childNode=result.childNodes[0];
          e.innerHTML=childNode.nodeValue;
         // setFunc(fromlang,tolang,resulttext);
         // alert("ifif");
       }
      }
      var r=xmlhttp.send('');
   }
   else{
      e.style.visibility="hidden";
      e.style.display="none";
   }
}
EOF
      $self->LoadSubObjs("QuickFind","QuickFind");
      my @s;
      foreach my $sobj (values(%{$self->{QuickFind}})){
         my $acl=$self->getMenuAcl($ENV{REMOTE_USER},
                                   $sobj->Self());
         if (defined($acl)){
            next if (!grep(/^read$/,@$acl));
         }
         msg(INFO,"mod=%s acl=%s",$sobj->Self(),Dumper($acl));
         if ($sobj->can("CISearchResult")){
            push(@s,$sobj->CISearchResult($searchtext));
         }
      }
      if ($#s!=-1){
         $found++;
      }
      my $group=undef;
      foreach my $res (sort({$a->{group}.";".$a->{name} cmp 
                             $b->{group}.";".$b->{name}} @s)){
          if ($group ne $res->{group}){
             $tree="foldersTree";
             my $gtag=$res->{group};
             $gtag=~s/[^a-z0-9]/_/gi;
             print insFld($tree,$gtag,$res->{group});
             $tree=$gtag;
             $group=$res->{group};
          }
          my $divid="$res->{parent}::$res->{id}";
          my $html="<div class=QuickFindDetail id=\"$divid\" ".
                   "style=\"visibility:hidden;display:none\">XXX</div>";

          print insDoc($tree,$res->{name},"javascript:switchTag('$divid')",
                        appendHTML=>$html); 
      }
#
#printf STDERR ("fifi keys of QuickFind=%s\n",keys(%{$self->{QuickFind}}));
#      $tree="itil__appl";
#      print insDoc($tree,"AG XY \@ DTAG.T-Com",
#                   "javascript:switchTag('yy::xx')",
#                   appendHTML=>"<div id=\"yy::xx\" ".
#                               "style=\"visibility:hidden;display:none\">".
#                               "SeM:xxx<br><a href=http://www.google.com target=_blank>TSM:xxx</a><br></div>");
#      print insDoc($tree,"AG XY<br>","../../faq/forum/Topic/123");
#
   }

   if (grep(/^article$/,@stags)){
      my $tree="foldersTree";
      my $faq=getModuleObject($self->Config,"faq::article");
    
      $faq->SecureSetFilter({kwords=>$searchtext});
      my @l=$faq->getHashList(qw(name faqid));
      my $loop=0;
      foreach my $rec (@l){
         if (!$found){
            print treeViewHeader($label,1);
            $found++;
         }
         if ($loop==0 && $#stags>0){
            print insFld($tree,"article","FAQ-Artikel");
            $tree="article";
            $loop++;
         }
         print insDoc($tree,$rec->{name},
                      "../../faq/article/ById/".
                      "$rec->{faqid}");
      }
   }
   if (grep(/^forum$/,@stags)){
      my $tree="foldersTree";
      my %id;

      my $fo=getModuleObject($self->Config,"faq::forumentry");
      $fo->SecureSetFilter({ftext=>$searchtext});
      my @l=$fo->getHashList(qw(forumtopic));
      foreach my $rec (@l){
         $id{$rec->{forumtopic}}++;
      }
      my $fo=getModuleObject($self->Config,"faq::forumtopic");
      $fo->SecureSetFilter({ftext=>$searchtext});
      my @l=$fo->getHashList(qw(id));
      foreach my $rec (@l){
         $id{$rec->{id}}++;
      }
      $fo->ResetFilter();
      $fo->SecureSetFilter({id=>[keys(%id)]});
      my @l=$fo->getHashList(qw(id name));

      my $loop=0;
      foreach my $rec (@l){
         if (!$found){
            print treeViewHeader($label,1);
            $found++;
         }
         if ($loop==0 && $#stags>0){
            print insFld($tree,"forum","Forum");
            $tree="forum";
            $loop++;
         }
         print insDoc($tree,$rec->{name},
                      "../../faq/forum/Topic/".
                      "$rec->{id}");
      }
   }
   if (!$found){
      print treeViewHeader("<font color=red>".$self->T("nothing found").
                           "</font>",1);
   }
   return(0);
}

sub insDoc
{
   my $tree=shift;
   my $label=shift;
   my $link=shift;
   my %param=@_;

   $label=~s/"/\\"/g;
   if (!($link=~m/^javascript:/)){
      $link=sprintf("javascript:openwin('%s','_blank',".
                    "'height=400,width=640,toolbar=no,".
                    "status=no,resizable=yes,scrollbars=auto')",$link); 
   }
   my $mode="S";
   if ($link=~m/^javascript:/i){
      $link=~s/^javascript://i;
      $mode.="j";
   }
   $link=~s/'/\\\\\\'/g;


   my $d=sprintf("e=insDoc(%s,".
             "gLnk(\"%s\",\"<div class=specialClass>%s</div>\",".
             "\"%s\"));\n",$tree,$mode,$label,$link);
   if (exists($param{appendHTML})){
      $d.=sprintf("e.appendHTML='%s';\n",$param{appendHTML});
   }
   return($d);
}

sub insFld
{
   my $tree=shift;
   my $name=shift;
   my $label=shift;

   my $d=sprintf("%s=insFld(%s,gFld(\"%s\", \"\"));\n",$name,$tree,$label);
   return($d);
}

sub treeViewHeader
{
   my $label=shift;
   my $allopen=shift;
   my $stags=shift;
   $allopen=0 if (!defined($allopen));
   my $d=<<EOF;

<DIV style="position:absolute; top:0; left:0;display:none"><TABLE border=0><TR><TD><FONT size=-2><A style="font-size:7pt;text-decoration:none;color:silver" href="http://www.treemenu.net/" target=_blank>Javascript Tree Menu</A></FONT></TD></TR></TABLE></DIV>

<script langauge="JavaScript"
        src="../../../static/treeview/ua.js"></script>
<script langauge="JavaScript"
        src="../../../static/treeview/ftiens4.js"></script>

<script langauge="JavaScript">
USETEXTLINKS=1;
USEFRAMES=0;
USEICONS=1;
PRESERVESTATE=0;
STARTALLOPEN=$allopen;
ICONPATH = '../../../static/treeview/';
foldersTree=gFld("<i>$label</i>","");
foldersTree.treeID = "Frameless";
foldersTree.iconSrc="../../base/load/help.gif";
EOF
   return($d);
}


sub Result
{
   my $self=shift;
   my $label=shift;
   my $searchtext=Query->Param("searchtext");

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','mainwork.css',
                                   'public/faq/load/QuickFind.css'],
                           title=>"Welcome",
                           js=>['toolbox.js'],
                           body=>1,form=>1);
   if ($searchtext eq ""){
      $self->Welcome($self->T("W5Base Documentation"),$searchtext);
   }
   else{
      $self->doSearch($self->T("Search Result"),$searchtext);
   }

   print(<<EOF);
</script>

<div style="margin:5px">
<script language="JavaScript">
initializeDocument();
</script>
</div>
EOF
   print $self->HtmlBottom(body=>1,form=>1);
}

sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(Main globalHelp Welcome Result QuickFindDetail));
}

sub QuickFindDetail
{
   my $self=shift;

   my $id=Query->Param("id");
   my $htmlresult;

   $self->LoadSubObjs("QuickFind","QuickFind");
   if (my ($mod,$id)=$id=~m/^(.*)::(.*)$/){
      msg(INFO,"load $id from mod=$mod");
      if (defined($self->{QuickFind}->{$mod})){
         $htmlresult=$self->{QuickFind}->{$mod}->QuickFindDetail($id);
      }
      else{
         msg(ERROR,"can't find module $mod"); 
      }
   }
   else{
      msg(ERROR,"can't interpret $id");
   }

   print $self->HttpHeader("text/xml");
   my $res=hash2xml({document=>{htmlresult=>$htmlresult}},{header=>1});
#printf STDERR ("fifi res=$res\n");
   print $res;


}






1;
