package kernel::App::Web::Listedit;
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
use kernel::config;
use kernel::App::Web;
use kernel::App::Web::History;
use kernel::App::Web::WorkflowLink;
use kernel::App::Web::InterviewLink;
use kernel::Output;
use kernel::Input;
use kernel::TabSelector;
@ISA    = qw(kernel::App::Web kernel::App::Web::History 
             kernel::App::Web::WorkflowLink);

sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->{IsFrontendInitialized}=0;
   $self->{ResultLineClickHandler}="Detail";
   return($self);
}  

sub ModuleObjectInfo
{
   my $self=shift;

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css',
                                   'kernel.App.Web.ModuleObjectInfo.css'],
                           js=>['toolbox.js'],
                           title=>$self->T('Module Object Information'),
                           form=>1);
   print("<table width=98%>");
   printf("<tr><td valign=top nowrap><b>%s:</b></td>",$self->T("Frontend name"));
   printf("<td>%s</td></tr>",$self->T($self->Self,$self->Self));
   printf("<tr><td valign=top nowrap><b>%s:</b></td>",$self->T("Internal object name"));
   printf("<td>%s</td></tr>",$self->Self);
   printf("<tr><td valign=top nowrap><b>%s:</b></td>",$self->T("Self as parent object"));
   printf("<td>%s</td></tr>",$self->SelfAsParentObject);
   printf("<tr><td valign=top nowrap><b>%s:</b></td>",$self->T("Parent classes"));
   printf("<td>%s</td></tr>",join(", ",@ISA));
   printf("<tr><td valign=bottom><b>%s:</b></td>",$self->T("Datafields"));
   printf("<td align=right><span class=sublink>".
          "<img border=0 style=\"margin-bottom:2px\" onclick=doPrint() ".
          "src=\"../../../public/base/load/miniprint.gif\"></span>".
          "</td></tr>");
   printf("<tr><td colspan=2>");
   printf("<div class=fieldlist><center><table border=1 width=520>");
      print("<tr>");
      printf("<td><b>%s</b></td>",$self->T("Frontend field"));
      printf("<td width=1%% nowrap><b>%s</b></td>",$self->T("Internal field"));
      printf("<td width=1%% nowrap><b>%s</b></td>",$self->T("Field type"));
      printf("<td width=1%% nowrap><b>%s</b></td>",$self->T("Searchable"));
      print("</tr>");
   foreach my $fo ($self->getFieldObjsByView([qw(ALL)])){
      print("<tr>");
      my $label=$fo->Label();
      $label=~s/\// \/ /g;
      $label=~s/-/ - /g;
      $label="&nbsp; &nbsp;" if ($label=~m/^\s*$/);
      printf("<td valign=top>%s</td>",$label);
      printf("<td valign=top>%s</td>",$fo->Name());
      printf("<td valign=top>%s</td>",$fo->Type());
      printf("<td align=center>%s</td>",
             $fo->searchable ? $self->T("yes") : $self->T("no"));
      print("</tr>");
   }
   printf("</table></div>");
   
   printf("</td></tr>");
   print("</table>");
   print(<<EOF);
<script language="JavaScript">
function doPrint()
{
   window.print();
}
</script>
EOF


   print $self->HtmlBottom(form=>1);
}

sub addAttach
{
   my $self=shift;
  
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css'],
                           js=>['toolbox.js'],
                           title=>$self->T('Add Inline Attachment'),
                           multipart=>1,
                           form=>1);
   if (Query->Param("save")){
      no strict;
      my $f=Query->Param("file");
      msg(INFO,"got filetransfer request ref=$f");
      my $bk=seek($f,0,SEEK_SET);
      (undef,undef,undef,undef,undef,undef,undef,
       $size,$atime,$mtime,$ctime,$blksize,$blocks)=stat($f);
      msg(INFO,"size=$size");
      my $filename=sprintf("%s",$f);
      $filename=~s/^.*[\/\\]//;
      msg(INFO,"filename=$filename");
      if ($size<128 || !($filename=~m/\.(jpg|jpeg|png|gif|xls|pdf)$/i)){
         $self->LastMsg(ERROR,"invalid file or filetype");
      }
      elsif ($size>3145728){
         $self->LastMsg(ERROR,"file is larger then the limit of 3MB");
      }
      else{
         my $newrec={parentobj=>$self->Self(),
                     inheritrights=>0,
                     srcsys=>"W5Base::InlineAttach",
                     name=>$filename,
                     file=>$f};
         my $filemgmt=getModuleObject($self->Config,"base::filemgmt");
         if (my ($id)=$filemgmt->ValidatedInsertRecord($newrec)){
            print "<script language=\"javascript\">";
            print "if (parent.currentObject){";
            print "   insertAtCursor(parent.currentObject,". 
                  "\" [attachment($id)] \");";
            print "}";
            print "else{";
            print "  alert(\"can not find currentObject\");";
            print "}";
            print "parent.hidePopWin(true,false);";
            print "</script>";
            print $self->HtmlBottom(form=>1);
         }
      }
   }
   print $self->getParsedTemplate("tmpl/addTextareaAttachment",
                                  {skinbase=>'base'});
   print $self->HtmlBottom(form=>1);
}


sub recordWriteOperators
{
   my $self=shift;
   my $databoss=$self->getField("databossid");
   my $idobj=$self->IdField();
   my $prim=[];
   my $sec=[];

   foreach my $oprec ($self->getHashList($idobj->Name(),"databossid")){
      if ($oprec->{databossid} ne ""){
         push(@$prim,$oprec->{databossid});
      }
      if (ref($oprec->{contacts}) eq "ARRAY"){
         foreach my $crec (@{$oprec->{contacts}}){
            my $r=$crec->{roles};
            $r=[$r] if (ref($r) ne "ARRAY");
            if (grep(/^write$/,@$r)){
               if ($crec->{target} eq "base::user"){
                  push(@$sec,$crec->{targetid});
               }
               if ($crec->{target} eq "base::grp"){
                  foreach my $uid ($self->getMembersOf($crec->{targetid},
                                   "RMember","down")){
                     push(@$sec,$uid);
                  }
               }
            }
         }
      }
   }

   return($prim,$sec);
}



sub getValidWebFunctions
{  
   my ($self)=@_;
   $self->doFrontendInitialize();
   my @l=qw(NativMain Main MainWithNew addAttach 
            NativResult Result Upload UploadWelcome UploadFrame
            Welcome Empty Detail HtmlDetail HandleInfoAboSubscribe
            New Copy FormatSelect Bookmark startWorkflow
            DeleteRec InitWorkflow AsyncSubListView 
            EditProcessor ViewProcessor HandleQualityCheck
            ViewEditor ById ModuleObjectInfo);
   if ($self->can("HtmlHistory")){
      push(@l,qw(HtmlHistory HistoryResult));
   }
   if ($self->can("HtmlWorkflowLink")){
      push(@l,qw(HtmlWorkflowLink WorkflowLinkResult));
   }
   if ($self->can("HtmlInterviewLink")){
      push(@l,qw(HtmlInterviewLink));
   }
   return(@l);
}

sub ById
{
   my ($self)=@_;
   my $idfield=$self->IdField();
   my $idname=$idfield->Name();
   my $val="undefined";
   if (defined(Query->Param("FunctionPath"))){
      $val=Query->Param("FunctionPath");
   }
   $val=~s/^\///;
   $val="UNDEF" if ($val eq "");
   $self->HtmlGoto("../Detail",post=>{$idname=>$val});
   return();
}

sub allowAnonymousByIdAccess
{
   my $self=shift;
   my $id=shift;
   return(0);
}


sub isUploadValid  # validates if upload functionality is allowed
{
   my $self=shift;

   return(1);
}

sub doFrontendInitialize
{
   my $self=shift;
   if (!$self->{IsFrontendInitialized}){
      $self->{IsFrontendInitialized}=$self->FrontendInitialize();
   }
   return($self->{IsFrontendInitialized});
}


sub FrontendInitialize
{
   my $self=shift;
   $self->{userview}=getModuleObject($self->Config,"base::userview");
   $self->{UseSoftLimit}=1 if (!defined($self->{UseSoftLimit}));
   return(1);
}

sub HandleSubListEdit
{
   my ($self,%param)=@_;
   my $subeditmsk=$param{subeditmsk};
   $subeditmsk="default.subedit" if (!defined($subeditmsk));
   my $idname=$self->IdField->Name();

   print("<script language=JavaScript ".
         "src=\"../../../public/base/load/OutputHtml.js\"></script>\n");
   print("<script language=JavaScript ".
         "src=\"../../../public/base/load/toolbox.js\"></script>\n");
   print("<script language=JavaScript ".
         "src=\"../../../public/base/load/sortabletable.js\"></script>\n");
   my $op=$self->ProcessDataModificationOP();
   {
      # SubList Edit-Mask anzeigen
      my $id=Query->Param("CurrentIdToEdit");
      my ($rec,$msg);
      if (defined($id) && $id ne ""){
         $self->SetFilter({$self->IdField->Name()=>$id});
         $self->SetCurrentView($self->getFieldList());
         ($rec,$msg)=$self->getFirst();
         $self->SetCurrentView();
      }
      my $app=$self->App();
      print <<EOF;
<link rel=stylesheet type="text/css"
      href="../../../public/base/load/kernel.App.Web.css"></link>
<link rel=stylesheet type="text/css"
      href="../../../public/base/load/Output.HtmlSubListEdit.css"></link>
EOF
      if (defined($rec)){
         printf("<script language=\"JavaScript\">".
                "setEnterSubmit(document.forms[0],DoSubListEditSave);".
                "</script>");
      }
      else{
         printf("<script language=\"JavaScript\">".
                "setEnterSubmit(document.forms[0],DoSubListEditAdd);".
                "</script>");
      }
      print $self->getParsedTemplate("tmpl/$app.$subeditmsk",{current=>$rec});
   }
   print $self->findtemplvar({},"LASTMSG");
   if ($op eq "delete" || $op eq "save"){
      $self->ClearSaveQuery();
   }
}

sub getForceParamForSubedit
{
   my $self=shift;
   my $id=shift;
   my $dfield=shift;

   my %forceparam=();
   #######################################################################
   # forceparameter berechnen, die im SubEdit modus die Verbindung zum
   # Elternobjekt erzeugt/darstellen
   #
   $self->SetFilter({$self->IdField->Name()=>$id});
   $self->SetCurrentView($dfield->{vjoinon}->[0]);
   my ($rec,$msg)=$self->getFirst();
   my $joinf=$self->getField($dfield->{vjoinon}->[0]);
   my $lnk=$joinf->RawValue($rec);

   $forceparam{$dfield->{vjoinon}->[1]}=$lnk;
   if (defined($dfield->{vjoinbase})){
      my @filter=($dfield->{vjoinbase});
      if (ref($dfield->{vjoinbase}) eq "ARRAY"){
         @filter=@{$dfield->{vjoinbase}};
      }
      foreach my $filter (@filter){
         foreach my $var (keys(%$filter)){
            if (ref($filter->{$var}) eq "SCALAR"){
               $forceparam{$var}=${$filter->{$var}};
            }
         }
      }
   }
   #######################################################################
   return(%forceparam);
}

sub EditProcessor
{
   my ($self)=@_;
   my $id=Query->Param("RefFromId");
   my $seq=Query->Param("Seq");
   my $field=Query->Param("Field");
   my $dfield=$self->getField($field);
   if (defined($dfield)){
      return($dfield->EditProcessor($id,$field,$seq));
   }
   else{
      print $self->HttpHeader("text/html");
      print "ERROR: EditProcessor no access to FunctionPath";
   }
}

sub ViewProcessor
{
   my ($self)=@_;
   my $fp=Query->Param("FunctionPath");
   $fp=~s/^\///;
   my ($mode,$field,$refid,$id,$seq)=split(/\//,$fp);
   my $dfield=$self->getField($field);
   if (defined($dfield)){
      return($dfield->ViewProcessor($mode,$refid,$id,$field,$seq));
   }
   else{
      print $self->HttpHeader("text/html");
      print "ERROR: ViewProcessor no access to FunctionPath";
   }
}

sub AsyncSubListView
{
   my ($self)=@_;
   print $self->HttpHeader("text/html");
   my $id=Query->Param("RefFromId");
   my $seq=Query->Param("Seq");
   my $field=Query->Param("Field");
   printf("<html>");
   printf("<body OnLoad=resizeme()>");
   my $dfield=$self->getField($field);

   $self->SetFilter({$self->IdField->Name()=>$id});
   $self->SetCurrentView($field);
   my ($rec,$msg)=$self->getFirst();
   if (defined($rec)){
      print $dfield->FormatedResult($rec,"HtmlDetail");
   }
   else{
      print (msg(ERROR,"problem msg=$msg rec=$rec id=$rec idfield=%s",
                       $self->IdField->Name()));
   }
   printf("</body>");
print <<EOF;
<script language=JavaScript>
function resizeme()
{
   var p=window.parent.document;
   var dst=p.getElementById('div.sublist.$field.$seq.$id');
   if (dst){
      dst.innerHTML=document.body.innerHTML;
      window.parent.DetailInit();
   }
}
</script>
EOF
   print $self->HtmlBottom();
}

sub initSearchQuery
{
   my $self=shift;
}

sub getParsedSearchTemplate
{
   my $self=shift;
   my %param=@_;
   my $pagelimit=20;
   my $UserCache=$self->Cache->{User}->{Cache};
   if (defined($UserCache->{$ENV{REMOTE_USER}})){
      $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
   }
   $self->initSearchQuery();
   if (defined($UserCache->{pagelimit}) && $UserCache->{pagelimit} ne ""){
      $pagelimit=$UserCache->{pagelimit};
   }
   my $AutoSearch;
   if (Query->Param("AutoSearch")){
      $AutoSearch="addEvent(window,\"load\",DoSearch);\n";
   }
   my $name="tmpl/".$self->App.".search";

   my $d=<<EOF;
<script language="JavaScript">
function DoSearch()
{
   var d;
   document.forms[0].action='Result';
   document.forms[0].target='Result';
   document.forms[0].elements['FormatAs'].value='HtmlV01';
   document.forms[0].elements['UseLimitStart'].value='0';
   document.forms[0].elements['UseLimit'].value='$pagelimit';
   DisplayLoading(frames['Result'].document);
   window.setTimeout("document.forms[0].submit();",1);
   return;
}
function DoUpload()
{
   var d;
   document.forms[0].action='UploadFrame';
   document.forms[0].target='Result';
   document.forms[0].submit();
   return;
}
setEnterSubmit(document.forms[0],DoSearch);
$AutoSearch
</script>
EOF
   my $defaultsearch="";
   if ($param{nosearch}){
      my %search=$self->getSearchHash();
      foreach my $k (keys(%search)){
         $d.="<input type=hidden value=\"$search{$k}\" name=search_$k>";
      }
      return($d);
   }
   if ($self->getSkinFile($self->SkinBase()."/".$name)){
      $d.=$self->getParsedTemplate($name);
   }
   else{
      # autogen search template
      my @field=$self->getFieldList();
    
      my $searchframe="";
      my $extframe="";
      my $c=0;
      my $mainlines=$self->{MainSearchFieldLines};
      $mainlines=2 if (!defined($mainlines));
      my @searchfields=@field;

      my $idshifted=0;
      while(my $fieldname=shift(@searchfields)){
         my $fo=$self->getField($fieldname); 
         my $type=$fo->Type();
         next if (!$fo->UiVisible("SearchMask"));
         if (!$fo->searchable()){
            if ($type eq "Id"){
               if ($#searchfields!=-1){
                  push(@searchfields,$fieldname) if (!$idshifted);
                  $idshifted++;
                  next;
               }
            }
            else{
               next;
            }
         }
      #   next if (!($fo->searchable()) && $type ne "Id");
         $defaultsearch=$fieldname if ($fo->defsearch);
         my $work=\$searchframe;
         $work=\$extframe if ($c>=$mainlines*2);
         last if (!defined($fieldname));
         my $modulus=($c+1)%2;
         if ($modulus ==1){
            $$work.="<tr>";
         }
         my $c1="15%";
         my $c2="35%";
         my $cs="1";
         if ($fo->mainsearch()){
            $c2="95%";
            $cs="3";
         }
         $$work.="<td class=fname width=$c1>\%$fieldname(searchlabel)\%:</td>";
         $$work.="<td class=finput width=$c2 colspan=$cs>".
                 "\%$fieldname(search)\%</td>";
         if ($fo->mainsearch()){
            $c++;
         }
         if ($c+1 % 2 ==0){
            $$work.="</tr>";
         }
         $c++;
      }
      $searchframe.="</tr>" if (!($searchframe=~m/<\/tr>$/));

      $d.=$self->arrangeSearchData($searchframe,$extframe,$defaultsearch,%param);
      $self->ParseTemplateVars(\$d);
   }
   return($d);
}

sub arrangeSearchData
{
   my $self=shift;
   my $searchframe=shift;
   my $extframe=shift;
   my $defaultsearch=shift;
   my %param=@_;

   my $newbutton="";
   $newbutton="new," if ($param{allowNewButton});
   my $d=<<EOF;
<img width=450 border=0 height=1 src="../../../public/base/load/empty.gif"><div class=searchframe><table class=searchframe>$searchframe</table></div>
%StdButtonBar(search,analytic,$newbutton,defaults,reset,bookmark,print,extended,upload)%
<div style="width:100%;
            border-width:0px;
            margin:0px;
            padding:0px;
            display:none;visibility:hidden" id=ext>
<div class=extsearchframe><table class=extsearchframe>$extframe</table></div>
</div>
<script language="JavaScript">
setFocus("$defaultsearch");
</script>
EOF
   return($d);
}


sub Copy
{
   my ($self)=@_;

   my $copyfromid=Query->Param("CurrentIdToEdit");

   if ($copyfromid ne ""){
      $self->PrepairCopy($copyfromid,1);
      #print STDERR Query->Dumper();
   }
   return($self->New());
}

sub PrepairCopy
{
   my $self=shift;
   my $copyfromid=shift;
   my $firsttry=shift;
   my $copyfromrec={};
   my $copyinit={};

   $self->ResetFilter();
   $self->SecureSetFilter({$self->IdField->Name()=>$copyfromid});
   $self->SetCurrentView(qw(ALL));
   ($copyfromrec)=$self->getFirst();
   if ($self->isCopyValid($copyfromrec)){
      Query->Param("isCopyFromId"=>$copyfromid);
      Query->Delete("CurrentIdToEdit");
      Query->Delete($self->IdField->Name());
      foreach my $fo ($self->getFieldObjsByView([$self->getCurrentView()],
                                                oldrec=>$copyfromrec)){
         my $newval=$fo->copyFrom($copyfromrec);
         if (defined($newval)){
            $copyinit->{"Formated_".$fo->Name()}=$newval;
         }
      }
      $self->InitCopy($copyfromrec,$copyinit);
      foreach my $v (keys(%$copyinit)){
         next if (!defined($copyinit->{$v}));
         if (!defined(Query->Param($v))){
            Query->Param($v,$copyinit->{$v});
         }
      }
      Query->Delete($self->IdField->Name());
      Query->Delete("Formated_".$self->IdField->Name());
   }
   else{
      print($self->noAccess());
      return(undef);
   }
}

sub InitCopy
{
   my ($self,$copyfrom,$newrec)=@_;
}

sub InitNew    # Initialize Web New Form
{
   my ($self)=@_;
}

sub New
{
   my ($self)=@_;
   if (!$self->isWriteValid()){
      print($self->noAccess());
      return(undef);
   }
   if (!defined(my $op=Query->Param("OP"))){
      $self->InitNew();
   }
   $self->ProcessDataModificationOP();
   if (my $CopyFromId=Query->Param("isCopyFromId")){
      $self->PrepairCopy($CopyFromId);
   }

   if (Query->Param($self->IdField->Name()) ne ""){
      if (Query->Param("ModeSelectCurrentMode") eq "new"){
         Query->Delete("ModeSelectCurrentMode");
      }
      return($self->Detail());
   }
   my $output=new kernel::Output($self);
   if (!($output->setFormat("HtmlDetail",NewRecord=>1,WindowMode=>'New'))){
      msg(ERROR,"can't set output format 'HtmlDetail'");
      return();
   }
   my $page=$output->WriteToScalar(HttpHeader=>0);

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css',
                                   'kernel.App.Web.css',
                                   'mainwork.css',
                                   'Output.HtmlDetail.css',
                                   'kernel.filemgmt.css',
                                   'kernel.TabSelector.css'],
                           body=>1,form=>1,multipart=>'1');
   print("<style>body{margin:0;overflow:hidden;padding:0;".
         "border-width:0}</style>");
   my %param=(pages=>    [$self->getHtmlDetailPages("new",undef)],
              activpage  =>'new',
              tabwidth    =>"20%",
              page        =>$page,
             );
   print TabSelectorTool("ModeSelect",%param);
   print $self->HtmlBottom(body=>1,form=>1);
}

sub DeleteRec
{
   my ($self)=@_;
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css',
                                   'Output.HtmlDetail.css',
                                   'work.css',
                                   'kernel.App.Web.css'],
                           body=>1,form=>1,
                           title=>$self->T("Verification query"));
   my $id=Query->Param("CurrentIdToEdit");
   $self->ResetFilter();
   my $flt=undef;
   if (defined($id)){
      $flt={$self->IdField->Name()=>\$id};
      $self->SetFilter($flt);
   }
   if (defined($flt)){
      $self->SetCurrentView(qw(ALL));
      $self->ForeachFilteredRecord(sub{
                                      $self->ValidateDelete($_);
                                   });
   }
   if (Query->Param("FORCE")){
      my $error=1;
      if (defined($flt)){
         $error=0;
         $self->SetCurrentView(qw(ALL));
         my @recs;
         $self->ForeachFilteredRecord(sub{
                             push(@recs,$_);
                          });
         if (defined($id) && $#recs!=0){
            $error=1;
            $self->LastMsg(ERROR,"delete destination notfound or not unique");
         }
         else{
            foreach my $rec (@recs){
               if (!$self->SecureValidatedDeleteRecord($rec)){
                  $error=1;
               }
            }
         }
      }
      if (!$error){
         print(<<EOF);
<script language=JavaScript>
parent.hidePopWin(false);
parent.FinishDelete();
</script>
EOF
         return();
      }
   }
   printf("<form method=post><center>");
   printf("<table border=0 height=80%>");
   printf("<tr height=1%>");
   printf("<td align=center><br><br>");
   if (!grep(/^ERROR/,$self->LastMsg())){
      printf($self->T("Do you realy want delete record id %s ?"),$id);
   }
   printf("</td>");
   printf("</tr>");
   if ($self->LastMsg()!=0){
      printf("<tr height=1%>");
      printf("<td align=center>".
             "<div style=\"text-align:left;border-style:solid;".
             "border-width:1px;padding:3px;".
             "overflow:auto;height:50px;width:400px\">");
      print join("<br>",map({
                             if ($_=~m/^ERROR/){
                                $_="<font style=\"color:red;\">".$_.
                                   "</font>";
                             }
                             $_;
                            } $self->LastMsg()));
      printf("</div></td>");
      printf("</tr>");
   }
   printf("<tr>");
   printf("<td align=center valign=center>");
   printf("<table border=0>");
   printf("<tr>");
   if (!grep(/^ERROR/,$self->LastMsg())){
      printf("<td>");
      printf("<input type=submit name=FORCE ".
             " value=\" %s \" ".
             "style=\"margin-left:20px;margin-right:20px;width:150px\">",
             $self->T("yes"));
      printf("</td>");
      printf("<td>");
      printf("<input type=button ".
             "onclick=\"parent.hidePopWin(false);\" value=\" %s \" ".
             "style=\"margin-left:20px;margin-right:20px;width:150px\">",
             $self->T("no"));
      printf("</td>");
   }
   else{
      printf("<td>");
      printf("<input type=button ".
             "onclick=\"parent.hidePopWin(false);\" value=\" %s \" ".
             "style=\"margin-left:20px;margin-right:20px;width:150px\">",
             $self->T("cancel"));
      printf("</td>");
   }
   printf("</tr>");
   printf("</table>");
   printf("</td>");
   printf("</tr>");
   printf("</table>");
   print ($self->HtmlPersistentVariables(qw(CurrentIdToEdit)));
   printf("</from>");

}

sub NativMain
{
   my ($self)=@_;
   return($self->Main(nohead=>1,allowNewButton=>1));
}

sub NativResult
{
   my ($self)=@_;
   return($self->Main(nohead=>1,nosearch=>1));
}

sub MainWithNew
{
   my ($self)=@_;
   return($self->Main(allowNewButton=>1));
}

sub Main
{
   my ($self,%param)=@_;

   if (!$self->isViewValid()){
      print($self->noAccess());
      return(undef);
   }
   my $CurrentView=Query->Param("CurrentView");
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','mainwork.css',
                                   'kernel.App.Web.css'],
                           submodal=>1,
                           body=>1,form=>1,
                           title=>$self->T($self->Self,$self->Self));
   print ("<style>body{overflow:hidden}</style>");
   if ($param{nohead}){
      print <<EOF;
<script language=JavaScript src="../../../public/base/load/toolbox.js">
</script>
<script language=JavaScript src="../../../public/base/load/kernel.App.Web.js">
</script>
EOF
   }
   print("<table style=\"border-collapse:collapse;width:100%;height:100%\" ".
         "border=0 cellspacing=0 cellpadding=0>");
   if (!$param{nohead}){
      printf("<tr><td height=1%% style=\"padding:1px\" ".
             "valign=top>%s</td></tr>",$self->getAppTitleBar());
   }
   printf("<tr><td height=1%% style=\"padding:1px\">%s</td></tr>",
          $self->getParsedSearchTemplate(%param));
   my $welcomeurl="Welcome";
   if (!$self->can("Welcome")){
      my $mod=$self->Module();
      my $app=$self->App();
      if ($self->getSkinFile("$mod/tmpl/welcome.$app")){
         $welcomeurl="../load/tmpl/welcome.$app"; 
      }
      elsif ($self->getSkinFile("$mod/tmpl/welcome")){
         $welcomeurl="../load/tmpl/welcome"; 
      }
   }
   my $BookmarkName=Query->Param("BookmarkName");
   my $ForceOrder=Query->Param("ForceOrder");
   print(<<EOF);
<tr><td><iframe class=result id=result 
                name="Result" src="$welcomeurl"></iframe></td></tr>
</table>
<input type=hidden name=UseLimit value="10">
<input type=hidden name=UseLimitStart value="0">
<input type=hidden name=FormatAs value="HtmlV01">
<input type=hidden name=BookmarkName value="$BookmarkName">
<input type=hidden name=CurrentView value="$CurrentView">
<input type=hidden name=ForceOrder value="$ForceOrder">
EOF
   print $self->HtmlBottom(body=>1,form=>1);
}


sub getSearchHash
{
   my $self=shift;
   my %h=();
   %h=Query->MultiVars();

   my $idobj=$self->IdField();
   if (defined($idobj)){
      my $idname=$idobj->Name();
      if (defined($h{$idname})){
         return($idname=>[$h{$idname}]);
      }
   }
  # if (defined(Query->Param($idname))){
  #    my $idval=Query->Param($idname);
  #    $idval=~s/&quote;/"/g;
  #    return($idname=>[$idval]);
  # }
   foreach my $v (keys(%h)){
      if ($v=~m/^search_/ && $h{$v} ne ""){
         my $v2=$v;
         $v2=~s/^search_//;
         $h{$v2}=trim($h{$v});
         if (my ($webclip)=$h{$v2}=~m/\[\@(WebClip.*)\@\]/){
            my $nobj=getModuleObject($self->Config(),"base::note");
            my $userid=$self->getCurrentUserId();
            $nobj->SetFilter({creatorid=>\$userid,name=>\$webclip});
            $nobj->SetCurrentView(qw(comments));
            $h{$v2}=[];

            my ($cliprec,$msg)=$nobj->getFirst();
            if (defined($cliprec)){
               do{
                  push(@{$h{$v2}},$cliprec->{comments});
                  ($cliprec,$msg)=$nobj->getNext();
               } until(!defined($cliprec));
            }
         }
      }
      delete($h{$v});
   }
   return(%h);
}

#sub Welcome
#{
#   my $self=shift;
#   print $self->HttpHeader("text/html");
#   print $self->HtmlHeader(style=>['default.css','work.css'],
#                           body=>1,form=>1);
#   my $module=$self->Module();
#   my $appname=$self->App();
#   my $tmpl="tmpl/$appname.welcome";
#   my @detaillist=$self->getSkinFile("$module/".$tmpl);
#   if ($#detaillist!=-1){
#      print $self->getParsedTemplate($tmpl,{});
#   }
#   print $self->HtmlBottom(body=>1,form=>1);
#   return(0);
#}

sub Bookmark
{
   my $self=shift;
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css'],
                           title=>$self->T("... add a bookmark"),
                           body=>1,form=>1);
   my $autosearch=Query->Param("AutoSearch");
   my $replace=Query->Param("ReplaceBookmark");
   Query->Delete("ReplaceBookmark");
   my $bookmarkname=Query->Param("BookmarkName");
   if ($bookmarkname eq ""){
      $bookmarkname=$self->T($self->Self,$self->Self());
      $bookmarkname.=": ".$self->T("my search");
   }
   my $closewin="";
   my $dosave=0;

   if (Query->Param("SAVE")){
      Query->Delete("SAVE");
      $dosave=1;
   }

   Query->Delete("AutoSearch");
   my %qu=Query->MultiVars();
  # foreach my $sv (keys(%qu)){    # just do no cleaning - i think it's better
  #    next if ($qu{$sv} ne "" || $sv eq "search_cistatus");
  #    delete($qu{$sv});
  # }
   my $querystring=kernel::cgi::Hash2QueryString(%qu);
   $querystring="?".$querystring;
   my $srclink=$self->Self();
   $srclink=~s/::/\//g;
   my $bmsrclink="../../".$srclink."/Main$querystring&AutoSearch=$autosearch";
   my $clipsrclink=$ENV{SCRIPT_URI}."/../../../".$srclink."/Main$querystring";

   if ($dosave){
      my $bm=getModuleObject($self->Config,"base::userbookmark");
      my $target="_self";
      if ($replace){
         my $userid=$self->getCurrentUserId();
         $bm->SetFilter({name=>\$bookmarkname,userid=>\$userid});
         $bm->SetCurrentView(qw(ALL));
         $bm->ForeachFilteredRecord(sub{
                            $bm->ValidatedDeleteRecord($_);
                         });
      }
      if ($bm->SecureValidatedInsertRecord({name=>$bookmarkname,
                                            srclink=>$bmsrclink,
                                            target=>$target})){
         $closewin="parent.hidePopWin();";
      }
   }


   my $quest=$self->T("please copy this URL to your clipboard:");
   print(<<EOF);
<script language="JavaScript">
$closewin
function showUrl()
{
   var x;
   if (document.forms[0].elements['AutoSearch'].value==1){
       x=prompt("$quest:","$clipsrclink&AutoSearch=1");
   }
   else{
       x=prompt("$quest:","$clipsrclink");
   }
   if (x){
      parent.hidePopWin();
   }
}
</script>
EOF
   my $auto="<select name=AutoSearch>";
   $auto.="<option value=\"0\">".$self->T("no")."</option>";
   $auto.="<option value=\"1\"";
   $auto.=" selected" if ($autosearch);
   $auto.=">".$self->T("yes")."</option>";
   $auto.="</select>";
   my $repl="<select name=ReplaceBookmark>";
   $repl.="<option value=\"0\">".$self->T("no")."</option>";
   $repl.="<option value=\"1\"";
   $repl.=" selected" if ($replace);
   $repl.=">".$self->T("yes")."</option>";
   $repl.="</select>";
   my $BOOKM="<input type=text style=\"width:100%\" name=BookmarkName ".
             "value=\"$bookmarkname\">";

   print $self->getParsedTemplate("tmpl/kernel.bookmarkform",{skinbase=>'base',
                                    static=>{AUTOS=>$auto,BOOKM=>$BOOKM,
                                             REPL=>$repl}});
   #printf("Bookmark Handler");
   print("<input type=hidden name=SAVE value=\"1\">");
   print $self->HtmlPersistentVariables(qw(ALL));
   print $self->HtmlBottom(body=>1,form=>1);
   return(0);
}

sub ClearSaveQuery
{
   my $self=shift;
   my @var=Query->Param();
   my $id=$self->IdField->Name();

   foreach my $var (@var){
      if ((($var=~m/^Formated_.*$/ ||
            lc($var) eq $var) &&
           $var ne $id) || 
           $var eq "NewRecSelected" || 
           $var eq "CurrentFieldGroupToEdit"){
         Query->Delete($var);
      }
   }
}

sub finishCopy
{
   my $self=shift;
   my $oldid=shift;
   my $newid=shift;
   msg(INFO,"finishCopy: oldid=$oldid newid=$newid");
}

sub HandleSave
{
   my $self=shift;
   my $oldrec=undef;
   my $id=Query->Param("CurrentIdToEdit");
   my $idobj=$self->IdField();
   my $idname=$idobj->Name();
   my $flt=undef;
   #msg(INFO,"id=$id");
   if (defined($id) && $id ne ""){
      $id=~s/&quote;/"/g;
      $flt={$idname=>\$id};
      $self->SecureSetFilter($flt);
      $self->SetCurrentView(qw(ALL));
      my $msg;
      $self->SetCurrentOrder("NONE");
      ($oldrec,$msg)=$self->getOnlyFirst(qw(ALL));
      #$self->SetCurrentView();
   }
   my $newrec=$self->getWriteRequestHash("web",$oldrec);
   if ($self->LastMsg()!=0){
      return(undef);
   }
   if (defined($oldrec) && defined($newrec) && defined($newrec->{$idname})){
      if (!defined($self->{UseSqlReplace}) || $self->{UseSqlReplace}==0){
         delete($newrec->{$idname});
      }
   }

   if (!defined($newrec)){
      if ($self->LastMsg()==0){
         $self->LastMsg(ERROR,"unknown error in ".
                              "${self}::getWriteRequestHash()");
      }
      return(undef);
   }
   #
   # Delta save (for later storeing in Delta-Tab)
   #
   my $writeok=0;
   if (defined($oldrec)){
      if ($self->SecureValidatedUpdateRecord($oldrec,$newrec,$flt)){
         $writeok=1;
         if (ref($idobj->{dataobjattr}) eq "ARRAY"){ # id is a contact from 
                     # data fields - so the  id must be new calculated
                     # - the definition of each array field as datafield
                     # is needed
            my @newid;
            my @fobj=$self->getFieldObjsByView([qw(ALL)]);
            foreach my $field (@{$idobj->{dataobjattr}}){
               foreach my $fobj (@fobj){
                  if (defined($fobj->{dataobjattr}) &&
                      $field eq $fobj->{dataobjattr}){
                     push(@newid,'"'.effVal($oldrec,$newrec,$fobj->Name).'"');
                  }
               }
            }
            my $newid=join("-",@newid);
            Query->Param($self->IdField->Name()=>$newid);
         }
      }
   }
   else{
      my $newid=$self->SecureValidatedInsertRecord($newrec);
      if ($newid){
         $writeok=1;
         Query->Param($self->IdField->Name()=>$newid);
         if (Query->Param("isCopyFromId") ne ""){
            my $oldid=Query->Param("isCopyFromId");
            $self->finishCopy($oldid,$newid);
            Query->Delete("isCopyFromId");
         }
      }
   }
   if ($writeok){
      $self->ClearSaveQuery(); 
      Query->Delete("CurrentIdToEdit");
   }
   else{
      if ($self->LastMsg()==0){
         $self->LastMsg(ERROR,"unknown error in ${self}::Validate()");
      }
   }
}

sub HandleDelete
{
   my $self=shift;

   my $id=Query->Param("CurrentIdToEdit");
   my $flt=undef;
   if (defined($id)){
      $flt={$self->IdField->Name()=>\$id};
      $self->SetFilter($flt);
   }
   if (defined($flt)){
      $self->SetCurrentView(qw(ALL));
      $self->ForeachFilteredRecord(sub{
                               my $rec=$_;
                               if ($self->SecureValidatedDeleteRecord($rec)){
                                  if ($rec->{$self->IdField->Name()} eq $id){
                                     Query->Delete("CurrentIdToEdit");
                                  } 
                               }
                               else{
                                  $self->LastMsg(ERROR,
                                           "SecureValidatedDeleteRecord error");
                               }
                            });
   }
   else{
      $self->LastMsg(ERROR,"HandleDelete with no filter informations");
      return(0);
   }
   return(1);
}

sub ProcessDataModificationOP
{
   my $self=shift;

   my $op=Query->Param("OP");
   if (Query->Param("NewRecSelected")==1){
      $self->ClearSaveQuery
   }
   if ($op eq "cancel"){
      Query->Delete("OP");
      $self->ClearSaveQuery(); 
   }
   if ($op eq "save"){
      Query->Delete("OP");
      $self->HandleSave();
   }
   if ($op eq "delete"){
      Query->Delete("OP");
      $self->HandleDelete();
   }
   return($op);
}

sub HtmlDetail
{
   my $self=shift;
   my %param=@_;

   $self->ProcessDataModificationOP();
   my %flt=$self->getSearchHash();
   $self->ResetFilter();
   $self->SecureSetFilter(\%flt);
   my $output=new kernel::Output($self);
   $self->SetCurrentView(qw(ALL));
   $param{WindowMode}="Detail";
   $self->SetCurrentOrder("NONE");
   if (!($output->setFormat("HtmlDetail",%param))){
      msg(ERROR,"can't set output format 'HtmlDetail'");
      return();
   }
   $output->WriteToStdout(HttpHeader=>1);
}


sub Detail
{
   my $self=shift;
   my %param=@_;

   my %flt=$self->getSearchHash();
   $self->ResetFilter();
   $self->SecureSetFilter(\%flt);
   $self->SetCurrentOrder("NONE");
   my ($rec,$msg)=$self->getOnlyFirst(qw(ALL));

   my $cookievar="HtmlDetailPage_".$self->Self;
   $cookievar=~s/[:]+/_/g;

   my $p=Query->Param("ModeSelectCurrentMode");
   $p=$self->getDefaultHtmlDetailPage($cookievar) if ($p eq "");

   print $self->HttpHeader("text/html",
                           cookies=>Query->Cookie(-name=>$cookievar,
                                                  -path=>"/",
                                                  -value=>$p));
   print $self->HtmlHeader(style=>['default.css','mainwork.css',
                                   'kernel.TabSelector.css',
                                   '../../../static/lytebox/lytebox.css'],
                           body=>1,form=>1);
   if (!defined($rec)){
      print $self->getParsedTemplate("tmpl/kernel.notfound",{skinbase=>'base'});
      print $self->HtmlBottom(body=>1,form=>1);
      return();
   }
   my $idobj=$self->IdField();
   my $parentid;
   if (defined($idobj) && defined($rec)){
      $parentid=$idobj->RawValue($rec);
   }
   print $self->HtmlSubModalDiv();
   print "<script language=\"JavaScript\" ".
         "src=\"../../../public/base/load/toolbox.js\"></script>".
         "<script language=\"JavaScript\" ".
         "src=\"../../../public/base/load/subModal.js\"></script>\n";
   my $UserJavaScript=$self->getUserJavaScriptDiv($self->Self,$parentid);
   if ($UserJavaScript ne ""){
      print "<script language=\"JavaScript\" ".
            "src=\"../../../public/base/load/jquery.js\"></script>\n";
   }

   print("<script language=\"JavaScript\">");
   print("function setEditMode(m)");
   print("{");
   print("   this.SubFrameEditMode=m;");
   print("}");
   print("function TabChangeCheck()");
   print("{");
   print("if (this.SubFrameEditMode==1){return(DataLoseWarn());}");
   print("return(true);");
   print("}");
   print("</script>");

   my $page=$self->getHtmlDetailPageContent($p,$rec);

   my @WfFunctions=$self->getDetailFunctions($rec);
   my %param=(functions   =>\@WfFunctions,
              pages       =>[$self->getHtmlDetailPages($p,$rec)],
              activpage  =>$p,
              tabwidth    =>"20%",
              page        =>$page,
             );
   print TabSelectorTool("ModeSelect",%param);
   print "<script language=\"JavaScript\">".$self->getDetailFunctionsCode($rec).
          "</script>";

   print($UserJavaScript);
   print $self->HtmlBottom(body=>1,form=>1);
}

sub getUserJavaScript
{
   my $self=shift;
   my $parentobj=shift;
   my $parentid=shift;

   my $userid=$self->getCurrentUserId();
   my $precode="";
   my @flt;
   my $code;
   if ($parentobj ne ""){
      $precode.="var ParentObj=\"$parentobj\";\n";
      push(@flt,{creatorid=>\$userid,
                 parentobj=>[$parentobj,''],
                 name=>'UserJavaScript*'});
   }
   if ($parentobj ne "" && $parentid ne ""){
      $precode.="var ParentId=\"$parentid\";\n";
      push(@flt,{creatorid=>\$userid,
                 parentobj=>\$parentobj,
                 parentid=>\$parentid,
                 name=>'UserJavaScript*'});
   }

   my $code="";
   if ($#flt!=-1){
      my $note=getModuleObject($self->Config,"base::note");
      $note->ResetFilter();
      $note->SetFilter(\@flt);
      foreach my $rec ($note->getHashList(qw( name comments))){
         $code.=$rec->{comments};
      }
      $code=trim($code);
   }
   my $v=<<EOF;

function myFAQ(){
   \$("textarea[name=note]").val("Ich habe Sie der Gruppe \\"uploader\\" hinzugef�gt. Bitte befolgen Sie in jedem Fall die Hinweise im FAQ Artikel ...\\n http://xxxx/xxxxxxxxxxxxxxx/xxx.\\n\\n\\n I have add you to the group \\"uploader\\". Please read the instructions at ...\\nhttp://xfjhdsfas/xxxxxxx");

}

addToMenu({label:"- default FAQ f�r Upload guppen",func:myFAQ});
addToMenu({label:"- xxxxxxxxxxxxxxxxxxload guppen",func:myFAQ});
addToMenu({label:"- default Fxxxxxxxxxxxxxxxxxxen",func:myFAQ});
addToMenu({label:"- defxxxxxxxxxxxxxxxxxxd guppen",func:myFAQ});

EOF
#   $code.=$v;
   return($code);
}

sub getUserJavaScriptDiv
{
   my $self=shift;
   my $parentobj=shift;
   my $parentid=shift;

   my $d;
   my $code=$self->getUserJavaScript($parentobj,$parentid);
   if ($code ne ""){
      $d=<<EOF;
<div id=UserJavaScriptActivator>
</div>
<div id=UserJavaScript>
</div>
<script>
function addToMenu(m){
   var h=20;
   var o=document.createElement("span");
   \$(o).addClass("sublink");
   \$(o).html(m.label);
   \$(o).height(h);
   if (m.func){
      \$(o).click(m.func)
   }
   \$("#UserJavaScript").append(\$(o));
   \$("#UserJavaScript").height(\$("#UserJavaScript").height()+h);
   \$("#UserJavaScript").append(\$(document.createElement("br")));
}

\$(document).ready(function (){$code});
\$("#UserJavaScriptActivator").mouseover(function (){
   \$("#UserJavaScript").show("slow");
   \$("#UserJavaScript").mouseout(function (){
     setTimeout(function (){
        \$("#UserJavaScript").hide("slow");
        \$("#UserJavaScript").unbind("mouseout");
     },2000);
   });
});
</script>

EOF
   }
   return($d);
}


sub getDetailFunctionsCode
{
   my $self=shift;
   my $rec=shift;
   my $idname=$self->IdField->Name();
   my $id=$rec->{$idname};

   my $detailx=$self->DetailX();
   my $detaily=$self->DetailY();
   my $copyo="";
   my $UserCache=$self->Cache->{User}->{Cache};
   my $loginurl="../../../auth/".$self->Self."/Detail";
   $loginurl=~s/::/\//g;
   if (defined($UserCache->{$ENV{REMOTE_USER}})){
      $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
   }
   my $winsize="";
   if (defined($UserCache->{winsize}) && $UserCache->{winsize} ne ""){
      $winsize=$UserCache->{winsize};
   }
   if ($winsize eq ""){
      $copyo="openwin(\"Copy?CurrentIdToEdit=$id\",\"_blank\",".
          "\"height=$detaily,width=$detailx,toolbar=no,status=no,".
          "resizable=yes,scrollbars=auto\")";
   }
   else{
      $copyo="custopenwin(\"Copy?CurrentIdToEdit=$id\",\"$winsize\",$detailx)";
   }

   my $d=<<EOF;
function DetailPrint(){
   window.frames['HtmlDetailPage'].focus();
   window.frames['HtmlDetailPage'].print();
}
function DetailClose(){
   if (window.name=="work"){
      document.location.href="Welcome";
   }
   else{
//      if (this.SubFrameEditMode==1){
//         if (!DataLoseWarn()){
//            return;
//         }
//      }
      window.opener=self;
      window.open('','_parent','');
      window.close();
      if (!window.closed){
         document.location.href="Welcome";
      }
   }
}

function DetailDelete(id)
{
   showPopWin('DeleteRec?CurrentIdToEdit=$id',500,180,FinishDelete);
}
function DetailCopy(id)
{
   $copyo;
}
function DetailLogin()
{
   document.forms[0].action="$loginurl";
   document.forms[0].submit(); 
}
function FinishDelete(returnVal,isbreak)
{
   if (!isbreak){
      if (window.name=="work"){
         document.location.href="Welcome";
      }
      else{
         window.close();
      }
   }
}
function DetailHandleInfoAboSubscribe()
{
   showPopWin('HandleInfoAboSubscribe?CurrentIdToEdit=$id',590,300,
              FinishHandleInfoAboSubscribe);
}
function DetailHandleQualityCheck()
{
   openwin('HandleQualityCheck?CurrentIdToEdit=$id',"qc$id",
           "height=240,width=$detailx,toolbar=no,status=no,"+
           "resizable=yes,scrollbars=auto");
}
function FinishHandleInfoAboSubscribe(returnVal,isbreak)
{
   if (!isbreak){
      document.location.href=document.location.href;
   }
}

function checkEditmode(e) // this handling prevents klick on X in window
{
   if (window.SubFrameEditMode==1){
      window.SubFrameEditMode=0;
      e.returnValue=DataLoseQuestion();
   }
}
addEvent(window, "beforeunload",   checkEditmode);


EOF
   return($d);
}

sub getDetailFunctions
{
   my $self=shift;
   my $rec=shift;
   my @f=($self->T("DetailPrint")=>'DetailPrint');
   if ($ENV{REMOTE_USER} eq "anonymous"){
      push(@f,$self->T("DetailLogin")=>'DetailLogin');
   }
   push(@f,$self->T("DetailClose")=>'DetailClose');
   if (defined($rec) && $self->isDeleteValid($rec)){
     # my $idname=$self->IdField->Name();
     # my $id=$rec->{$idname};
      unshift(@f,$self->T("DetailDelete")=>"DetailDelete");
   }
   if (defined($rec) && $self->isCopyValid($rec)){
     # my $idname=$self->IdField->Name();
     # my $id=$rec->{$idname};
      unshift(@f,$self->T("DetailCopy")=>"DetailCopy");
   }
   if (defined($rec) && $self->can("HandleInfoAboSubscribe") && 
       $ENV{REMOTE_USER} ne "anonymous"){
      unshift(@f,$self->T("InfoAbo")=>"DetailHandleInfoAboSubscribe");
   }
   if (defined($rec) && $self->can("HandleQualityCheck") &&
       $ENV{REMOTE_USER} ne "anonymous" &&
       $self->isQualityCheckValid($rec)){
      unshift(@f,$self->T("QualityCheck")=>"DetailHandleQualityCheck");
   }
   return(@f);
}

########################################################################
#
# quality check methods
#

sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   my $mandator=$rec->{mandatorid};
   $mandator=[$mandator] if (ref($mandator) ne "ARRAY");
   push(@$mandator,0);  # for rules on any mandator
   my $compatible=$self->getQualityCheckCompat($rec);
   my $qc=$self->getPersistentModuleObject("base::qrule");
   $qc->SetFilter({target=>$compatible});
   my @reclist=$qc->getHashList(qw(id));
   my @idl=map({$_->{id}} @reclist);
   if ($#idl!=-1){
      my $qc=$self->getPersistentModuleObject("base::lnkqrulemandator");
      $qc->SetFilter({mandatorid=>$mandator,qruleid=>\@idl});
      my @reclist=$qc->getHashList(qw(id dataobj));
      return(1) if ($#reclist!=-1 && $self->Self() ne "base::workflow");
      my $found=0;
      foreach my $qrec (@reclist){
         if ($self->Self() eq "base::workflow"){
            if ($rec->{class} eq $qrec->{dataobj}){
               $found++;
               last;
            }
         }
      }
      
      return($found);
   }

   return(0);
}

sub getQualityCheckCompat
{
   my $self=shift;
   my $rec=shift;
   my $s=$self->Self;
   if ($s eq "base::workflow"){
      return([$rec->{class},$s]);
   }
   return([$self->Self,$self->SelfAsParentObject()]);
}

sub HandleQualityCheck
{
   my $self=shift;

   my $id=Query->Param("CurrentIdToEdit");
   my $qc=$self->getPersistentModuleObject("base::qrule");
   my $idname=$self->IdField->Name();
   if ($id ne "" && $idname ne ""){
      $self->ResetFilter();
      $self->SetFilter({$idname=>\$id});
      $self->SetCurrentOrder("NONE");
      my ($rec,$msg)=$self->getOnlyFirst(qw(ALL));
      $qc->setParent($self);
      print($qc->WinHandleQualityCheck($self->getQualityCheckCompat($rec),$rec));
   }
   else{
      print($self->noAccess());
   }
}
########################################################################





sub validateSearchQuery
{
   return(1);
}


sub UploadWelcome
{
   my $self=shift;
   my %param=@_;

   if (!$self->isUploadValid()){
      print($self->noAccess()); 
      return(undef); 
   }
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css',
                                   'kernel.App.Web.css',
                                   'upload.css',
                                    ],
                           body=>1,form=>1,
                           title=>'W5BaseV2-Upload');

   printf("<table width=100% height=100%><tr><td valign=center align=center>".
          "%s</td></tr></table>",
          $self->T("Please select file and start upload"));

   print $self->HtmlBottom(body=>1,form=>1);
}

sub Welcome
{
   my $self=shift;
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','mainwork.css'],
                           body=>1,form=>1);
   if ($self->T("WELCOME",$self->Self) ne "WELCOME"){
      my $recordimg=$self->getRecordImageUrl();
      my $welcome=$self->T("WELCOME",$self->Self);
      print(<<EOF);
<table width=100% height=60%>
<tr>
<td align=center valign=center>
<table border=0 cellspacing=5 cellpadding=5>
<tr>
<td valign=top>
<img src="$recordimg"
      style="border-width:1px;border-style:solid;solid;border-color:black">
</td>
<td valign=center>
<div style="border-width:1px;border-top-style:solid;border-bottom-style:solid;border-color:black;padding:3px;width:250px">$welcome</div>
</div>
</td>
</tr>
</table>
</td>
</tr>
</table>
EOF
   }
   else{
      my $module=$self->Module();
      my $appname=$self->App();
      my $tmpl="tmpl/$appname.welcome";
      my @detaillist=$self->getSkinFile("$module/".$tmpl);
      if ($#detaillist!=-1){
         print $self->getParsedTemplate($tmpl,{});
      }
   }
   print $self->HtmlBottom(body=>1,form=>1);
   return(0);
}



sub preUpload                              # pre processing interface
{
   my $self=shift;
   my $inp=shift;
   return(1);
}

sub postUpload
{
   my $self=shift;
   my $inp=shift;
   return(1);
}

sub prepUploadRecord                       # pre processing interface
{
   my $self=shift;
   my $newrec=shift;

   return(1);
}

sub translateUploadFieldnames              # translation interface
{
   my $self=shift;
   my @flistorg=@_;
   my @flistnew;

   my @fl=$self->getFieldObjsByView([qw(ALL)]);
   foreach my $fo (@fl){
      for(my $c=0;$c<=$#flistorg;$c++){
         if ($fo->Name eq $flistorg[$c]){
            $flistnew[$c]=$fo->Name;
         }
      }
   }
   for(my $c=0;$c<=$#flistorg;$c++){
      if (!defined($flistnew[$c])){
         foreach my $fo (@fl){
            if ($fo->Label eq $flistorg[$c]){
               $flistnew[$c]=$fo->Name;
            }
         }
      }
   }
   return(@flistnew);
}

sub CachedTranslateUploadFieldnames
{
   my $self=shift;
   my @flistorg=@_;
   my $C=$self->Context;
   $C->{UploadFieldTrans}={} if (!defined($C->{UploadFieldTrans}));
   my @flistnew=@flistorg;
   my %notr;
   for(my $c=0;$c<=$#flistorg;$c++){
      if (exists($C->{UploadFieldTrans}->{$flistorg[$c]})){
         $flistnew[$c]=$C->{UploadFieldTrans}->{$flistorg[$c]};
      }
      else{
         $notr{$flistorg[$c]}=$c;
      }
   }
   if (keys(%notr)){
      my @reqtr=keys(%notr);
      my @newtr=$self->translateUploadFieldnames(@reqtr);
      for(my $cc=0;$cc<=$#reqtr;$cc++){
         $flistnew[$notr{$reqtr[$cc]}]=$newtr[$cc];
         $C->{UploadFieldTrans}->{$reqtr[$cc]}=$newtr[$cc];
      }
   }
   return(@flistnew);
}

sub ProcessUploadRecord
{
   my $self=shift;
   my $rec=shift;
   my %param=@_;

   if ($param{debug}){
      foreach my $key (keys(%$rec)){
         my $val=$rec->{$key};
         $val=~s/\n/\\n/g;
         if (length($val) > 20){
            $val=substr($val,0,19)."...";
         }
         print msg(INFO,"  %-15s = %s","'".$key."'","'".$val."'");
      }
   }

   my $oldrec;
   my $flt;
   my $id;
   my $idobj=$self->IdField();
   if (defined($idobj)){
      my $idname=$idobj->Name();
      if (defined($rec->{$idname}) && !($rec->{$idname}=~m/^\s*$/)){
         $self->ResetFilter();
         $id=$rec->{$idname};
         $self->SetFilter({$idname=>\$id});
         $self->SetCurrentOrder("NONE");
         my ($chkoldrec,$msg)=$self->getOnlyFirst(qw(ALL));
         if (defined($chkoldrec)){
            $oldrec=$chkoldrec;
            $flt={$idname=>\$id};
            if ($param{debug}){
               print msg(INFO,"found current record ".
                              "and use this as oldrec");
            }
         }
      }
      delete($rec->{$idname}); # id field isn't valid in Write-Request!
   }
   my $newrec=$self->getWriteRequestHash("upload",$oldrec,$rec);
   if (!defined($newrec)){
      if ($self->LastMsg()){
         print join("\n",$self->LastMsg());
      }
      print msg(ERROR,$self->T("record data mismatch"));
      ${$param{countfail}}++ if (ref($param{countfail}) eq "SCALAR");
      return(1);
   }
   if (defined($oldrec)){
      if ($self->SecureValidatedUpdateRecord($oldrec,$newrec,$flt)){
         if ($self->LastMsg()){
            print join("\n",$self->LastMsg());
            print msg(ERROR,$self->T("record not update or update incomplete"));
            ${$param{countfail}}++ if (ref($param{countfail}) eq "SCALAR");
         }
         if ($param{debug}){
            print msg(INFO,"update record with id $id");
         }
         ${$param{countok}}++ if (ref($param{countok}) eq "SCALAR");
      }
      else{
         if ($self->LastMsg()){
            print join("\n",$self->LastMsg());
            print msg(ERROR,$self->T("record not updated"));
         }
         ${$param{countfail}}++ if (ref($param{countfail}) eq "SCALAR");
      }
   }
   else{
      my $newid=$self->SecureValidatedInsertRecord($newrec);
      if (!defined($newid)){
         if (!$self->LastMsg()){
            print msg(ERROR,"record not inserted - unknown error");
         }
         else{
            print join("\n",$self->LastMsg());
         }
         ${$param{countfail}}++ if (ref($param{countfail}) eq "SCALAR");
      }
      else{
         if ($self->LastMsg()){
            print join("\n",$self->LastMsg());
            print msg(ERROR,"record not inserted or insert incomplete");
            ${$param{countfail}}++ if (ref($param{countfail}) eq "SCALAR");
         }
         else{
            if ($param{debug}){
               print msg(INFO,"insert record at id $newid");
            }
            ${$param{countok}}++ if (ref($param{countok}) eq "SCALAR");
         }
      }
   }
   $self->LastMsg("");
   return(1);
}

sub Upload
{
   my $self=shift;
   my %param=@_;

   if (!$self->isUploadValid()){
      print($self->noAccess()); 
      return(undef); 
   }
   my $file=Query->Param("file");
   my $HistoryComments=Query->Param("HistoryComments");
   if (trim($HistoryComments) ne ""){
      $W5V2::HistoryComments=$HistoryComments;
   }
   my $countok=0;
   my $countfail=0;
   if (defined($file) && $file ne "" && ref($file) eq "Fh"){
      my @stat=stat($file);
      if ($stat[7]<=0){
         print $self->HttpHeader("text/plain");
         print msg(ERROR,"nix drin");
      }
      else{
         my $debug=0;
         $debug=1 if (defined(Query->Param("DEBUG") &&
                      (Query->Param("DEBUG") ne "")));
         print $self->HttpHeader("text/plain");
         $|=1;
         my $inp=new kernel::Input($self,debug=>$debug);
         $inp->SetInput($file);
         if ($inp->isFormatUseable()){
            my $lang=$self->Lang();
            my $p=$self->Self();
            $p=~s/::/\//g;
            print msg(INFO,"start upload processing width lang=%s at %s",
                           $lang,$p);
            if ($self->preUpload($inp)){
               $inp->SetCallback(sub{
                                   my $prec=shift;
                                   my $ptyp=shift;
                                   $ptyp=$p if (!defined($ptyp));
                                   $ptyp=~s/\//::/g;
                                   if ($ptyp eq $self->Self()){


                                      my $fldchk=1;
                                      foreach my $fieldname (keys(%$prec)){
                                         my $fobj=$self->getField($fieldname);
                                         if (!defined($fobj) || 
                                             !($fobj->Uploadable())){
                                            my $label=$fieldname;
                                            if (defined($fobj)){
                                               $label=$fobj->Label();
                                            }
                                            $self->LastMsg(ERROR,
                                                           'field "%s" is not '.
                                                           'allowed to be '.
                                                           'uploaded',
                                                           $label);
                                            $fldchk=0;
                                            last;
                                         }
                                      }
                                      if ($fldchk &&
                                          $self->prepUploadRecord($prec)){
                                         $self->ProcessUploadRecord($prec,
                                                    debug=>$debug,
                                                    countok=>\$countok,
                                                    countfail=>\$countfail);
                                      }
                                      else{
                                         $countfail++;
                                         print join("",$self->LastMsg());
                                      }
                                   }
                                   else{
                                      print msg(INFO,"unsupported record ".
                                                     "typ '%s'",$ptyp);
                                      $countfail++;
                                      return(undef);
                                   }
                                   $self->FullContextReset();
                                   return(1); 
                                 });
               $inp->Process();
               print msg(INFO,"end upload processing user $ENV{REMOTE_USER} ".
                              "(result: ok=$countok;fail=$countfail)");
            }
            $self->postUpload($inp);
         }
         else{
            print msg(ERROR,$self->T("can't interpret input format"));
         }
      }
   }
   else{
      print $self->HttpHeader("text/html");
      print $self->HtmlHeader(style=>['default.css','work.css',
                                      'kernel.App.Web.css',
                                      'upload.css',
                                       ],
                              body=>1,form=>1,
                              title=>'W5BaseV2-Upload');
     
      print("... gib hal a dadai o!");
     
      print $self->HtmlBottom(body=>1,form=>1);
   }
}


sub UploadFrame
{
   my $self=shift;
   my %param=@_;

   if (!$self->isUploadValid()){
      print($self->noAccess()); 
      return(undef); 
   }
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css',
                                   'kernel.App.Web.css',
                                   'upload.css',
                                    ],
                           js=>['OutputHtml.js'],
                           target=>'uploadresult',body=>1,
                           title=>'W5BaseV2-Upload');
   print("<form action=\"Upload\" enctype=\"multipart/form-data\" ".
         "method=POST onsubmit=\"PreventDoublePost();\">");
   my @fnames=();
   foreach my $field ($self->getFieldList()){
      my $fobj=$self->getField($field);
      next if (!$fobj->Uploadable());
      push(@fnames,$fobj->Name());
   }
   my $fnames=join(",",@fnames);

   print(<<EOF);
<script language=JavaScript>
function DownloadTemplate(format)
{
   parent.document.forms[0].elements['CurrentView'].value="($fnames)";
   var bk=DirectDownload(format,"uploadresult");
   parent.document.forms[0].elements['CurrentView'].value="";
   return(bk);
}
var isloading=1;
var oldscroll=0;
function SetButtonState(flag)
{
   var d=window.document;
   for(c=0;c<d.forms.length;c++){
      var f=d.forms[c];
      for(cc=0;cc<f.elements.length;cc++){
         if (f.elements[cc].type=="submit"){
            f.elements[cc].disabled=flag;
         }
      }
   }
}
function PreventDoublePost()
{
   var d=window.document;

   frames['uploadresult'].document.open();
   frames['uploadresult'].document.write("<pre>loading ...</pre>");
   isloading=1;
   SetButtonState(true);
   oldscroll=frames['uploadresult'].document.body.scrollTop;
   window.setTimeout('ScrollDown();',5);
   return(true);
}
function ScrollDown()
{ 
   frames['uploadresult'].document.
         getElementsByTagName("pre")[0].style.fontSize="11px";
   if (frames['uploadresult'].document.body.innerHTML.search("end upload")!=-1){
      isloading=0;
      window.setTimeout('SetButtonState(false);',1500);
   }
   if (oldscroll==frames['uploadresult'].document.body.scrollTop){
      var o=frames['uploadresult'].document.body.scrollTop;
      frames['uploadresult'].scrollBy(0,5);
      if ((frames['uploadresult'].document.body.scrollTop!=o &&
          isloading==0) ||
          isloading==1){
         window.setTimeout('ScrollDown();',5);
      }
   }
   else{
      window.setTimeout('ScrollDown();',3000);
   }
   oldscroll=frames['uploadresult'].document.body.scrollTop;
}
</script>
EOF
   print("<center><table border=0 width=100% height=100% cellpadding=5>");
   print("<tr><td align=center valign=top>");
   print("<table width=70% class=uploadframe border=0>");
   print("<tr><td>");
   print("<table width=100% cellspacing=0 cellpadding=0>");
   print("<tr><td><table width=100% border=0 ".
         "cellspacing=0 cellpadding=0><tr><td valign=top>");


   printf("<table><tr><td><b><u>%s:</u></b></td></tr>",$self->T("Upload Templates"));
   print("<tr><td align=center>");
   my @formats=(icon_xls=>'XlsV01',
                icon_xml=>'XMLV01');
               # icon_csv=>'CsvV01');
   while(my $ico=shift(@formats)){
      my $f=shift(@formats);
      print("<a target=_self href=JavaScript:DownloadTemplate(\"$f\")>");
      print("<img style=\"margin-left:20px;margin-right:20px\" ".
            "border=0 src=\"../../base/load/$ico.gif\">");
      print("</a>");
   }
   print("</td></tr></table>");
   my $w=20;
   if (!$self->IsMemberOf("admin")){
      $w=50;
   }

   print("</td><td width=$w% valign=bottom>"); ##############################

   printf("<table><tr><td><br></td></tr>");
   print("<tr><td align=center>");
   print("<input type=checkbox class=checkbox name=DEBUG>Debug");
   print("</td><tr>");
   print("<tr><td align=center>");
   printf("<input class=uploadbutton type=submit value=\"%s\" ".
         "></td></tr>",$self->T("start upload"));
   print("</td></tr>");

   print("</table>");

   print("</td>");
   if ($self->IsMemberOf("admin")){
      print("<td width=45% valign=bottom>"); ################################
      print("<table width=100% cellspacing=0 cellpadding=0>");
      print("<tr><td>History note:<br>".
            "<textarea style=\"width:100%\" ".
            "name=HistoryComments wrap=off rows=3 cols=10></textarea>");
      print("</td><tr></table>");
      print("</td>");
   }
   print("</tr>");
   print("</table></td>");
   print("</td></tr>");
   print("<tr><td>");
   print("<table width=100%>");
   printf("<tr><td><b><u>%s:</u></b></td></tr>",$self->T("Upload File"));
   print("<tr><td align=center><input size=55 type=file name=file></td></tr>");
   print("<tr><td>");
   print("<table width=100%>");
   printf("<tr><td><b><u>%s:</u></b></td></tr>",$self->T("Upload Result"));
   print("<tr><td>");
   print("<iframe id=uploadresult src=\"UploadWelcome\" name=uploadresult ".
         "style=\"width:100%\"></iframe>");
   print("</td></tr>");
   print("</table></td>");
   print("</td></tr>");
   print("</table>");
   print("</td></tr>");
   print("</table></center>");
   print $self->HtmlBottom(body=>1,form=>1);
}


sub Result
{
   my $self=shift;
   my %param=@_;
   $self->doFrontendInitialize();
   my $output=new kernel::Output($self);
   if ($self->validateSearchQuery()){
      if (!$param{ExternalFilter}){
         $self->ResetFilter();
         my %q=$self->getSearchHash();
         $self->SecureSetFilter(\%q);
         if ($self->LastMsg()>0){
            print $self->queryError();
            return();
         }
         $param{'currentFrontendFilter'}=\%q;
      }

      my $view=Query->Param("CurrentView");

      if (defined($param{ForceOrder})){
         my @o=split(/\s*,\s*/,$param{ForceOrder});
         $self->setCurrentOrder(@o);
         $param{'currentFrontendOrder'}=\@o;
      }
      else{
         my $order=Query->Param("ForceOrder");
         if ($order ne ""){
            my @o=split(/\s*,\s*/,$order);
            $self->setCurrentOrder(@o);
            $param{'currentFrontendOrder'}=\@o;
         }
      }


      my $format=Query->Param("FormatAs");
      msg(INFO,"FormatAs from query: $format");
      if (defined($param{FormatAs})){
         Query->Param("FormatAs"=>$param{FormatAs});
         $format=$param{FormatAs};
      }
      $format=~s/;-*//;  # this is a hack, to allow enveloped formats


      if ((!defined($format) || $format eq "")){
         Query->Param("FormatAs"=>"HtmlFormatSelector");
         $self->Limit(1);
      }
      my $format=Query->Param("FormatAs");
      msg(INFO,"----------------------------- Format: $format ".
               "-----------------------------\n");
      $param{WindowMode}="Result";
      
      if (!($output->setFormat($format,%param))){
         # can't set format
         return();
      }
      my $uselimit=Query->Param("UseLimit");
      my $uselimitstart=Query->Param("UseLimitStart");
      $uselimitstart=0 if (!defined($uselimitstart));
      if (defined($param{Limit})){
         $uselimit=$param{Limit};
      }
      if ($format eq "JSONP"){
         $self->Limit($uselimit,$uselimitstart,0);
      }
      else{
         if (!defined($uselimit) || $uselimit==0 || $format ne "HtmlV01"){
            $self->Limit(0);
         }
         else{
            $self->Limit($uselimit,$uselimitstart,$self->{UseSoftLimit});
         }
      }
      if (defined($param{CurrentView})){
         $self->SetCurrentView(@{$param{CurrentView}});
      }
      else{
         if ((!defined($view) || $view eq "" || $view eq "default")){
            Query->Param("CurrentView"=>"default");
         }
         $self->SetCurrentView($self->getDefaultView());
         my $currentview=Query->Param("CurrentView");
         $self->SetCurrentView($self->getFieldListFromUserview($currentview));
      }
      $output->WriteToStdout(HttpHeader=>1);
   }
   else{
      if ($self->LastMsg()){
         print($self->noAccess());
      }
   }
   return(0);
}

sub ListeditTabObjectSearch
{
   my $self=shift;
   my $resultname=shift;
   my $searchmask=shift;

   my $idname=$self->IdField()->Name();
   my $id=Query->Param($idname);
   my $CurrentView=Query->Param("CurrentView");
   if ($id eq ""){
      print $self->HttpHeader("text/plain");
      print ("ERROR: no id");
      return();
   }
   $self->ResetFilter();
   $self->SetFilter({$idname=>\$id}); 
   $self->SetCurrentOrder("NONE");
   my ($rec,$msg)=$self->getOnlyFirst(qw(ALL));
   if (!$self->isViewValid($rec,resultname=>$resultname)){
      print($self->noAccess());
      return(undef);
   }
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css',
                                   'Output.ListeditTabObject.css',
                                   'kernel.App.Web.css',
                                    ],
                           js=>['toolbox.js','kernel.App.Web.js'],
                           submodal=>1,
                           body=>1,form=>1,
                           title=>'W5BaseV1-System');
   print("<table class=HtmlWorkflowLink width=100% height=100% ".
         "border=0 cellspacing=0 cellpadding=0>");
   printf("<tr><td height=1%%>%s</td></tr>",$searchmask);
   my $welcomeurl="../../base/load/tmpl/empty";
   my $s=$self->Self();  # to allow individual views
   my $d=<<EOF;
<tr><td><iframe class=result name="Result" src="$welcomeurl"></iframe></td></tr>
</table>
<input type=hidden name=UseLimit value="50">
<input type=hidden name=UseLimitStart value="0">
<input type=hidden name=FormatAs value="HtmlV01">
<input type=hidden name=CurrentView value="$CurrentView">
<input type=hidden name=MyW5BaseSUBMOD value="$s">
<script language="JavaScript">
addEvent(window, "load", DoSearch);
function DoRemoteSearch(action,target,FormatAs,CurrentView,DisplayLoadingSet)
{
   var d;
   if (action){
      document.forms[0].action=action;
      document.forms[0].action="$resultname";
   }
   if (target){
      document.forms[0].target=target;
   }
   if (FormatAs){
      document.forms[0].elements['FormatAs'].value=FormatAs;
   }
   if (CurrentView){
      document.forms[0].elements['CurrentView'].value=CurrentView;
   }
   if (DisplayLoadingSet){
      DisplayLoading(frames['Result'].document);
   }
   document.forms[0].submit();
   return;
}
function DoSearch()
{
   var d;
   document.forms[0].action='$resultname';
   document.forms[0].target='Result';
   document.forms[0].elements['FormatAs'].value='HtmlV01';
   document.forms[0].elements['UseLimitStart'].value='0';
   document.forms[0].elements['UseLimit'].value='50';
  // DisplayLoading(frames['Result'].document);
   document.forms[0].submit();
   return;
}

</script>
EOF
   Query->Param("CurrentId"=>$id);
   $d.=$self->HtmlPersistentVariables(qw(CurrentId));
   $self->ParseTemplateVars(\$d);
   print $d;
   print $self->HtmlBottom(body=>1,form=>1);

}


sub findtemplvar
{
   my $self=shift;
   my ($opt,$vari,@param)=@_;

   return($self->SUPER::findtemplvar(@_));
}



######################################################################

1;
