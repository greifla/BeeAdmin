package base::menu;
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
use kernel::MenuTree;
use kernel;
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
use base::workflow::mailsend;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);



sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'menuid',
                label         =>'W5BaseID',
                size          =>'10',
                dataobjattr   =>'menu.menuid'),
                                  
      new kernel::Field::Text(
                name          =>'fullname',
                htmlwidth     =>'180',
                label         =>'Fullname',
                dataobjattr   =>'menu.fullname'),

      new kernel::Field::Text(
                name          =>'target',
                label         =>'Target',
                dataobjattr   =>'menu.target'),

      new kernel::Field::Text(
                name          =>'prio',
                label         =>'Prio',
                dataobjattr   =>'menu.prio'),

      new kernel::Field::Text(
                name          =>'translation',
                label         =>'Translation',
                dataobjattr   =>'menu.translation'),

      new kernel::Field::Text(
                name          =>'func',
                label         =>'Function',
                dataobjattr   =>'menu.func'),

      new kernel::Field::Textarea(
                name          =>'param',
                label         =>'Parameters',
                dataobjattr   =>'menu.param'),

      new kernel::Field::Text(
                name          =>'config',
                label         =>'Config',
                dataobjattr   =>'menu.config'),

      new kernel::Field::Select(
                name          =>'useobjacl',
                label         =>'use Object ACL',
                htmleditwidth =>'20%',
                transprefix   =>'useobjacl.',
                default       =>'0',
                uivisible     =>'0',
                value         =>['0','1'],
                dataobjattr   =>'menu.useobjacl'),

      new kernel::Field::SubList(
                name          =>'acls',
                label         =>'Accesscontrol',
                subeditmsk    =>'subedit.menu',
                allowcleanup  =>1,
                group         =>'acl',
                vjoininhash   =>[qw(acltarget acltargetid aclmode)],
                vjointo       =>'base::menuacl',
                vjoinbase     =>{'aclparentobj'=>$self->Self()},
                vjoinon       =>['menuid'=>'refid'],
                vjoindisp     =>['acltargetname','aclmode']),

   );
   $self->{defaultlimit}=999999;
   $self->setDefaultView(qw(linenumber fullname target func config useobjacl));
   $self->setWorktable("menu");
   return($self);
}

sub DatabaseLowInit
{
   my $self=shift;

   my ($func,$p)=$self->extractFunctionPath();

   if ($self->Config->Param("W5BaseOperationMode") ne "readonly" &&
       $self->Config->Param("W5BaseOperationMode") ne "slave"){
      if ($func eq "root"){
         if (!$self->TableVersionValidate()){
            if (!($self->TableVersionChecker())){
               return(0);
            }
         }
      }
   }
   return($self->SUPER::DatabaseLowInit());
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/menu.jpg?".$cgi->query_string());
}
         

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $name=trim(effVal($oldrec,$newrec,"fullname"));
   if (!($name=~m/^[a-z0-9_\.\/\@\$:]+$/i) && $name ne ""){
      $self->LastMsg(ERROR,"invalid menu name '%s' specified",$name);
      return(0);
   }
   $newrec->{fullname}=$name;
   return(1);
}



sub ValidateCaches
{
   my $self=shift;

   return($self->SUPER::ValidateCaches());
}

sub isViewValid
{
   my $self=shift;
   my $oldrec=shift;
   return(qw(default header)) if (!defined($oldrec));
   return(qw(ALL));
}

sub isWriteValid
{
   my $self=shift;
   my $oldrec=shift;

   return(qw(default acls)) if (!defined($oldrec));
   return(qw(ALL)) if ($self->IsMemberOf("admin"));
   return(undef);
}

sub isDeleteValid
{
   my $self=shift;
   my $oldrec=shift;

   return(qw(ALL)) if ($self->IsMemberOf("admin"));
   return(undef);
}

sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $bak=$self->SUPER::FinishWrite($oldrec,$newrec);
   $self->InvalidateMenuCache();
   return($bak);
}

sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;
   my $bak=$self->SUPER::FinishDelete($oldrec);
   $self->InvalidateMenuCache();
   return($bak);
}



sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(),
          "root","mobile","menutop","menuframe","msel","TableVersionChecker",
          "LoginFail","IllegalTokenAccess");
}

#####################################################################
sub InitTableVersionChecker
{
    my $self=shift;
    if (!defined($self->{TableVersionDB})){
       my $db=new kernel::database($self,"w5base");
       if ($db->Connect()){
          $self->{TableVersionDB}=$db;
       }
       else{
          print $self->HttpHeader("text/html");
          print msg(ERROR,"can't connect to w5base DataObject");
          exit(1);
       }
    }
    return($self->{TableVersionDB});
}

sub TableVersionExists
{
   my $self=shift;

   my $db=$self->InitTableVersionChecker();
   my @l=$db->getHashList("show tables");
   my @tables=map({values(%$_)} @l);
   if (!grep(/^tableversion$/,@tables)){
      return(0);
   }
   return(1);
}

sub TableVersionProceedFile
{
   my $self=shift;
   my $rec=shift;
   my $mode=shift;

   my $db=$self->InitTableVersionChecker();
   if ($rec->{tventry} eq "no"){
      $db->do("insert into tableversion(filename) values('$rec->{filename}')");
   }
   my $workdb=new kernel::database($self,$rec->{dataobj});
   if (!$workdb->Connect()){
      $rec->{msg}="ERROR: ".$workdb->getErrorMsg(); 
      return(undef);
   }
   my $f=$self->Config->Param("INSTDIR");
   $f="$f/sql/$rec->{filename}";
   if (!open(F,"<$f")){
      $rec->{msg}="ERROR: can't open '$f'";
      return(undef);
   }
   if ($mode eq "set"){
      my $v=Query->Param("setline".$rec->{id});
      if ($v=~m/^\d+$/ && $v ne $rec->{linenumber}){
         $v=$rec->{lines} if ($v>$rec->{lines});
         if ($db->do("update tableversion set linenumber='$v' ".
                     "where id='$rec->{id}'")){
            $rec->{linenumber}=$v;
            $rec->{msg}="OK";
         }
      }
   }
   return(1) if ($mode ne "procced" && $mode ne "auto");
   return(2) if ( $rec->{linenumber} >= $rec->{lines});
   my $curline=0;
   my $cmdok=0;
   my $command="";
   while(my $l=<F>){
      chomp($l);
      $curline++;
      next if ($curline <= $rec->{linenumber});
      next if ($l=~/^\s*$/ || $l=~/^\s*#.*$/);
      $l=~s/^\s+/ /g;
      $command=$command.$l;
      if ($command=~/^.*;\s*$/){
         $command=~s/;\s*$//;
         printf STDERR ("[notice] W5Base dbtool '%s'\n",$command);
         if ($command=~m/^use \S+$/ || defined($workdb->do($command))){
            $cmdok++;
            $workdb->finish();
            $db->do("update  tableversion ".
                    "set linenumber='$curline' ".
                    "where filename='$rec->{filename}' ");
         }
         else{
            $rec->{msg}.=msg(ERROR,"Command '%s'",$command);
            $rec->{msg}.=msg(ERROR,"Line %s in file '%s'",
                                   $curline,$rec->{filename});
            $rec->{msg}.=msg(ERROR,"Database error: '%s'",
                                   $workdb->getErrorMsg());
          
            return(3);
         }
         $command="";
      }
   }
   $rec->{msg}="OK";
   $rec->{linenumber}=$curline;
   close(F);
   return(1);
}

sub TableVersionIsInconsistent
{
   my $self=shift;
   my %c=$self->TableVersionLoadSqlFileData();

   foreach my $rec (values(%c)){
      next if (!defined($rec->{dataobj}));
      return(1) if ($rec->{linenumber}<$rec->{lines});
   }
   return(0);
}

sub TableVersionLoadSqlFileData
{
   my $self=shift;
   my $db=$self->InitTableVersionChecker();
   my $instdir=$self->Config->Param("INSTDIR");
   my $pat="$instdir/sql/*/*.sql";
   my @sublist=glob($pat);
   my %c=();
   map({my $qi=quotemeta($instdir);
        $_=~s/^$instdir//;
        $_=~s/\/sql\///; $_=~s/\.pm$//;
        $c{$_}={filename=>$_};
       } @sublist);
   my @tv=$db->getHashList("select * from tableversion where id>0");

   foreach my $rec (values(%c)){
      $rec->{tventry}="no";
      $rec->{linenumber}=0;
      $rec->{readable}="no";
      $rec->{lines}=undef;
      $rec->{dataobj}=undef;
      map({
           if ($rec->{filename} eq $_->{filename}){
              $rec->{tventry}="yes";
              $rec->{linenumber}=$_->{linenumber};
              $rec->{id}=$_->{id};
              $rec->{linenumber}=0 if (!defined($rec->{linenumber}));
           }
          } @tv);
      if (open(F,"<$instdir/sql/$rec->{filename}")){
         my @l=<F>;
         if (my ($dataobj)=join("",@l)=~m/^use\s+([a-z0-9A-Z]+);$/m){
            $rec->{dataobj}=$dataobj;
         }
         $rec->{lines}=$#l+1;
         $rec->{readable}="yes";
         close(F);
      }
   }
   return(%c);
}

sub TableVersionModifications
{
   my $self=shift;
   my $buttons=
      "<input type=submit name=set value=\" force processed pointer values \">".
      "<input type=submit name=display ".
      "value=\" refresh full state list or continue\">".
      "<input type=submit name=do value=\" process outstanding operations \">";

   my $myrpcres=$self->W5ServerCall("rpcGetUniqueId");
   if (!defined($myrpcres) || $myrpcres->{exitcode}!=0){
      $buttons="<input type=submit name=display ".
               "value=\"no operations are posible - ".
               "W5Server is not available - refresh\">";
   }
   my $automodify=0;
   if ($self->Config->Param("W5BaseOperationMode") eq "automodify" ||
       $self->Config->Param("W5BaseOperationMode") eq "test"){
      $automodify=1;
   }
   my $op="<table border=0 style=\"table-layout:fixed;width:100%\"><tr><td>".
          "<table border=1>";
   my %c=$self->TableVersionLoadSqlFileData();
   my $errorcount=0;

   $op.="\n<tr>";
   $op.="<th>filename</th>";
   $op.="<th>dataobj</th>";
   $op.="<th>tventry</th>";
   $op.="<th>readable</th>";
   $op.="<th width=1%>processed</th>";
   $op.="<th>lines</th>";
   $op.="</tr>\n";
   my @order=sort({my $A=$a;
                   my $B=$b;
                   $A=~tr/[A-Z][a-z]/[a-z][A-Z]/;
                   $B=~tr/[A-Z][a-z]/[a-z][A-Z]/;
                   $A cmp $B} keys(%c));
   foreach my $sqlfile (@order){
      my $style;
      my $rec=$c{$sqlfile};
      my $bk=1;
      if (Query->Param("do") || Query->Param("set") ||
          $self->Config->Param("W5BaseOperationMode") eq "test"){
         next if (!defined($rec->{dataobj}));
         my $mode="auto";
         $mode="procced" if (Query->Param("do"));
         $mode="set" if (Query->Param("set"));
         $bk=$self->TableVersionProceedFile($rec,$mode);
      }
      if ($rec->{tventry} eq "yes"){
         $rec->{processed}="<input type=text name=setline$rec->{id} ".
                           "style=\"width:100%\" ".
                           "size=5 value=\"$rec->{linenumber}\">";
      }
      next if ($bk==2);
      if ($rec->{linenumber}<$rec->{lines} &&
          defined($rec->{dataobj})){
         $style="background:#e3acac";
      }
      $op.="\n<tr style=\"$style\">";
      $op.="<td>$rec->{filename}</td>";
      $op.="<td>$rec->{dataobj}</td>";
      $op.="<td>$rec->{tventry}</td>";
      $op.="<td>$rec->{readable}</td>";
      $op.="<td>$rec->{processed}</td>";
      $op.="<td>$rec->{lines}</td>";
      $op.="</tr>\n";
      if (defined($rec->{msg}) && $rec->{msg} ne "OK"){
         $op.="<tr><td colspan=6>".
              "<div class=pmsg style=\"width:650px;overflow:hidden\">".
              "<pre class=pmsg>$rec->{msg}</pre>".
              "</div></td></tr>";
         $errorcount++;
      }
      else{
         $op.="<tr><td></td><td colspan=5>$rec->{msg}</td></tr>";
      }
      last if ($bk==3);
   }
   $op.="\n</table>\n</td></tr>\n</table>\n";
   if ((Query->Param("do") || $automodify) && $errorcount==0){
      $buttons="<input type=submit value=\" OK \">";
   }
   return(1) if ($errorcount==0 && $automodify);
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(form=>1,body=>1);
   print $self->getParsedTemplate("tmpl/TableVersionModifications",{
                                   static=>{
                                       BUTTONS=>$buttons,
                                       OPERATIONS=>$op,
                                       LOGHEAD=>"",
                                           LOG=>"",
                                      LOGSTYLE=>""}
                                  });
   print $self->HtmlBottom(form=>1,body=>1);
   return(undef);
}

sub TableVersionCreate
{
   my $self=shift;
   my $db=$self->InitTableVersionChecker();
   my $style="nolog";
   my $errormsg;
   my $loghead="&nbsp;";
   if (Query->Param("do")){
      $style="log";
      $loghead="<font color=red>Database problem:</font>";
      my $cmd=<<EOF;
create table tableversion(
   id int(11) not null auto_increment,
   filename   varchar(128) not null,
   filedate   datetime not null,
   linenumber int(11) not null,
   primary key(id)
)
EOF
      if ($db->do($cmd)){
         $errormsg="OK\n";
         Query->Delete("do");
         return(0);
      }
      else{
         $errormsg=$db->getErrorMsg()."\nERROR in command:\n$cmd";
      }
   }
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css','TableVersion.css'],
                           form=>1,body=>1);
   print $self->getParsedTemplate("tmpl/TableVersionCreate",{
                                   static=>{
                                       LOGHEAD=>$loghead,
                                           LOG=>$errormsg,
                                      LOGSTYLE=>$style}
                                  });
   print $self->HtmlBottom(form=>1,body=>1);
   return(1);
}

sub TableVersionNeedAdmin
{
   my $self=shift;

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css','TableVersion.css'],
                           form=>1,body=>1);
   print $self->getParsedTemplate("tmpl/TableVersionNeedAdmin",{
                                  });
   print $self->HtmlBottom(form=>1,body=>1);
   return(0);
}

#
# TableVersionValidate checks only the TableVersion state
#
sub TableVersionValidate
{
   my $self=shift;
   if (!$self->TableVersionExists()){
      return(0);
   }
   if ($self->TableVersionIsInconsistent()){
      return(0);
   }
   return(1);
}

#
# TableVersionChecker is the interactive Frontend to handle 
# database modifications
#
sub TableVersionChecker
{
   my $self=shift;

   my $db=$self->InitTableVersionChecker();
   if (!$self->TableVersionExists()){
      return($self->TableVersionNeedAdmin()) if (!$self->IsMemberOf("admin"));
      return() if ($self->TableVersionCreate());
   }
   if ($self->TableVersionIsInconsistent()){
      if ($self->Config->Param("W5BaseOperationMode") eq "normal"||
          $self->Config->Param("W5BaseOperationMode") eq "dev" ||
          $self->Config->Param("W5BaseOperationMode") eq "online"){
         if (!$self->IsMemberOf("admin")){
            return($self->TableVersionNeedAdmin());
         }
      }
      return($self->TableVersionModifications());
   }
}
#####################################################################

sub root
{
   my $self=shift;
   my $sitename=$self->Config->Param("SITENAME");
   if ($sitename eq ""){
      $sitename=$self->Config->getCurrentConfigName();
   }
   my $fp=Query->Param("FunctionPath"); 
   $fp=~s/^\///;
   my @fp=split(/[\/]/,$fp);
   my $rootpath=Query->Param("RootPath");
   $fp=~s/\//./g;
   $fp=~s/"/./g;
   if ($fp ne ""){
      print $self->HttpHeader("text/html");
      print("<html><body onLoad=\"document.forms[0].submit();\">".
            "<form method=post action=${rootpath}root>");
      print("<input type=hidden name=menu value=\"$fp\">");
      foreach my $v (Query->Param()){ 
         next if ($v=~m/^DIRECT_/);
         next if ($v=~m/^search_/);
         next if ($v=~m/^AutoSearch$/);
         next if ($v=~m/^\S+[a-z]SUBMOD$/);
         next if ($v=~m/^OpenURL$/);
         Query->Delete($v);
      }
      print $self->HtmlPersistentVariables(qw(ALL));
      print("</form>");
      print("</body>");
      print("<script language=\"JavaScript\">window.focus();</script>");
      print("</html>");
   }
   else{
      if ($ENV{HTTP_UA_OS}=~m/Windows CE/){
         my $nomobileask=Query->Param("NOMOBILEASK");
         if ($nomobileask ne "1"){
            my $qf=getModuleObject($self->Config,"faq::QuickFind");
            my $mqf;
            if (defined($qf)){
               $mqf="\n<p>\n<anchor>Mobile WAP Interface\n".
                    "<go href=\"../../faq/QuickFind/mobileWAP\" ".
                    "method=\"post\">".
                    "\n<postfield name=\"NOMOBILEASK\" value=\"1\"/>\n".
                    "</go></anchor>\n</p>\n";
            }
            my $d=<<EOF;
<p align="center">W5Base Mobile Interface</p>
<p>please select operation mode:</p>
$mqf
<p><anchor>
  Classic HTML Interface
  <go href="root" method="post">
    <postfield name="NOMOBILEASK" value="1"/>
  </go>
</anchor></p>
EOF
            print $self->HttpHeader("text/vnd.wap.wml");
            print $self->Wap($d);
            print STDERR $self->Wap($d);
            return();
         }
      }
      print $self->HttpHeader("text/html");
      print $self->HtmlHeader(style=>['default.css'],
                              js=>'toolbox.js',
                              shorticon=>'icon_w5base.ico',
                              title=>$sitename);
      my $qs=kernel::cgi::Hash2QueryString(Query->MultiVars());
      $qs="?".$qs if ($qs ne "");
      my $menutopurl="${rootpath}menutop$qs";
      my $menu=Query->Param("menu");
      $menu="/".$menu if ($menu ne "");
      $menu=~s/\./\//g;
      Query->Delete("menu");
      my $qs=kernel::cgi::Hash2QueryString(Query->MultiVars());
      $qs="?".$qs if ($qs ne "");
      my $mselurl="${rootpath}msel$menu$qs";
      my $d=$self->getParsedTemplate("tmpl/menutopframe",{static=>
                                                {  rootpath=>$rootpath,
                                                   menutopurl=>$menutopurl,
                                                   mselurl=>$mselurl,
                                                }});
      print $d;
      print("<script language=\"JavaScript\">window.focus();</script>");
      print $self->HtmlBottom();
   }
}

sub mobile
{
   my $self=shift;
   my $sitename=$self->Config->Param("SITENAME");
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['jquery.mobile-1.1.1.min.css'],
                           js=>['jquery-1.7.1.min.js',
                                'jquery.mobile.1.1.1.min.js'],
                           title=>"Mobile - $sitename");
   my $ml=$self->_getMenuEntryFinalList(undef,"mobile");

   my $mainp="<div data-role=\"page\" id=\"mainpage\">";
   $mainp.="<div data-theme=\"a\" data-role=\"header\">";
   $mainp.="<h3>$sitename</h3>";
   $mainp.="</div>";

   $mainp.="<ul data-role=\"listview\" data-divider-theme=\"b\" ".
       "data-inset=\"true\">\n";
#   $mainp.="<li data-role=\"list-divider\" role=\"heading\">";
#   $mainp.="Main";
#   $mainp.="</li>";
   foreach my $mrec (sort({$a->{prio} <=> $b->{prio}} @$ml)){
      next if ($mrec->{fullname} eq "MyW5Base");
      next if ($mrec->{fullname} eq "Reporting");
      next if ($mrec->{fullname} eq "Tools");
      $mainp.="<li data-theme=\"c\">";
      $mainp.="<a href=\"#page$mrec->{menuid}\" data-transition=\"flow\">";
      $mainp.=$mrec->{label};
      $mainp.="</a></li>\n";
   } 
   $mainp.="</ul>";
   $mainp.="</div>\n";

   print $mainp;
   foreach my $mrec (@$ml){
      $self->_mobileShowSubMenu("mainpage",$sitename,$mrec);
   }
   print("</body></html>");
}

sub _mobileShowSubMenu
{
   my $self=shift;
   my $parentid=shift;
   my $sitename=shift;
   my $ment=shift;
   my $mt=$self->Cache->{Menu}->{Cache};

   my $mainp="<div data-role=\"page\" id=\"page$ment->{menuid}\">";
   $mainp.="<div data-theme=\"a\" data-role=\"header\">";

   $mainp.="<a data-role=\"button\" data-inline=\"true\" ".
           "href=\"#$parentid\" data-icon=\"arrow-u\" data-iconpos=\"left\">".
           "Back".
           "</a>";

   $mainp.="<a data-role=\"button\" data-inline=\"true\" ".
           "href=\"#mainpage\" data-icon=\"home\" data-iconpos=\"right\">".
           "Home".
           "</a>";

   $mainp.="<h3>$sitename</h3>";
   $mainp.="</div>";
   $mainp.="<br>";

   if ($ment->{target}=~m/::/){  # seems to be a data object
      my $target=$ment->{target};
      $target=~s/::/\//;
      $target="../../$target/mobile".$ment->{func};
      $mainp.="<a data-theme=\"b\" data-role=\"button\" href=\"$target\" ".
              "data-icon=\"arrow-r\" data-ajax=\"false\" ".
              "data-iconpos=\"right\">".  
              $ment->{label}."</a>";
      $mainp.="<hr>\n";
      $mainp.="<ul data-role=\"listview\" data-divider-theme=\"b\" ".
          "data-inset=\"true\">";
   }
   else{
      $mainp.="<ul data-role=\"listview\" data-divider-theme=\"b\" ".
          "data-inset=\"true\">";
      $mainp.="<li data-role=\"list-divider\" role=\"heading\">".
              $ment->{label}.
              "</li>";
   }
print STDERR ("msel=%s\n",Dumper($ment)) if ($ment->{fullname} eq "itil.system");;

  # printf STDERR ("fullname: %s\n",Dumper($ment));
   foreach my $mrec (@{$ment->{tree}}){
      $mainp.="<li data-theme=\"c\">";
      $mainp.="<a href=\"#page$mrec->{menuid}\" data-transition=\"flow\">";
      $mainp.=$mrec->{label};
      $mainp.="</a></li>\n";
   } 
   $mainp.="</ul>";
   $mainp.="</div>\n\n\n";
   print($mainp);

   foreach my $sment (@{$ment->{tree}}){
      $self->_mobileShowSubMenu("page$ment->{menuid}",$sitename,$sment);
   }
}

sub LoginFail
{
   my $self=shift;
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','menu.css']);
   print $self->getParsedTemplate("tmpl/LoginFail");
   print ("</html>");
}

sub IllegalTokenAccess
{
   my $self=shift;
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','menu.css']);
   print $self->getParsedTemplate("tmpl/IllegalTokenAccess");
   print ("</html>");
}

sub menuframe
{
   my $self=shift;
   my $fp=Query->Param("FunctionPath"); 
   $fp=~s/^\///;
   my @fp=split(/[\/\.]/,$fp);
   $fp=~s/\//./g;
   $fp=~s/"/./g;
   my $rootpath=Query->Param("RootPath");

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(target=>'msel',
                              js=>['wz_tooltip.js'],
                             base=>'',
                            prefix=>$rootpath,
                           style=>['default.css','menu.css']);
   my $m=$self->MenuTab($rootpath,$fp,
                        'JavaScript:SwitchMenuVisible() target=_self');
   my $menuframe=$self->getParsedTemplate("tmpl/menutmpl",{
                                       static=>{menutab=>$m,
                                                rootpath=>$rootpath}});
   print $menuframe;

   print ("</html>");
}

sub menutop
{
   my $self=shift;
   my $fp=Query->Param("FunctionPath"); 
   $fp=~s/^\///;
   my @fp=split(/[\/\.]/,$fp);
   my $rootpath="";
   foreach my $x (@fp){
      $rootpath.="../";
   }
   $fp=~s/\//./g;
   $fp=~s/"/./g;
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css',
                                   'kernel.App.Web.css'],
                           js=>['toolbox.js'],
                           body=>1,form=>1);
   my $operationmode=$self->Config->Param("W5BaseOperationMode");
   my $opmode=$operationmode;
   $opmode="" if ($opmode eq "normal");
   $opmode="<font color=darkred>$opmode</font>" if ($opmode eq "readonly");
   $opmode="OP-Mode: $opmode" if ($opmode ne "" && $opmode ne "online");
   $opmode="" if ($opmode eq "online");

   print $self->getParsedTemplate("tmpl/menuheader",{
                                   static=>{
                                       opmode=>$opmode,
                                       operationmode=>$operationmode,
                                       rootpath=>$rootpath
                                   }});
   print $self->HtmlBottom(body=>1,form=>1);
}

sub msel
{
   my $self=shift;
   my $mt=$self->Cache->{Menu}->{Cache};
   #printf STDERR ("fifi mtab=%s\n",Dumper($mt));
   my $fp=Query->Param("FunctionPath"); 
   my $originalMenuSelection=$fp;
   $fp=~s/^\///;
   my @fp=split(/[\/\.]/,$fp);
   my $rootpath=Query->Param("RootPath");
   $fp=~s/\//./g;
   $fp=~s/"/./g;

   my $wintitle="";
   if (defined($mt->{fullname}->{$fp})){
      my $m=$mt->{fullname}->{$fp};
      my @msub;
      my @mname;
      foreach my $subm (split(/\./,$fp)){
         push(@msub,$subm);
         my $tag=join(".",@msub);
         if (defined($mt->{fullname}->{$tag})){
            my $trtext=$self->T($tag,$mt->{fullname}->{$tag}->{translation});
            if ($trtext eq $tag && $trtext=~m/\./){
               $trtext=~s/^.*\.//;
            }
            push(@mname,$trtext);
         }
      }
      $wintitle=join(".",@mname);
      my $sitename=$self->Config->Param("SITENAME");
      if ($sitename eq ""){
         $sitename=$self->Config->getCurrentConfigName();
      }
      my $siteopmode;
      if ($wintitle ne "" && (($siteopmode)=$sitename=~m/\((.+)\)$/)){
         $wintitle=$siteopmode.":".$wintitle;
      }
   }

   my $fpfine=$fp;
   $fpfine=~s/\./\//g;
   $fpfine="/".$fpfine if (!($fpfine=~m/^\//));

   my %qu=Query->MultiVars();
   foreach my $sv (keys(%qu)){
      next if ($sv=~m/^DIRECT_/);
      next if ($sv=~m/^search_/);
      next if ($sv=~m/^AutoSearch$/);
      next if ($sv=~m/^\S+[a-z]SUBMOD$/);
      next if ($sv=~m/^OpenURL$/);
      delete($qu{$sv});
   }
   my $querystring=kernel::cgi::Hash2QueryString(%qu);

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css'],
                           base=>'',
                           prefix=>$rootpath);
   my $jsquerystring=$querystring;
   $jsquerystring="?".$jsquerystring if ($jsquerystring ne "");
   print (<<EOF);
<script language="JavaScript">
history.forward();
if (!(top.frames[0])){
   document.location.href='${rootpath}root$fpfine$jsquerystring';
   document.writeln("</form>");
   document.writeln("</base>");
   document.writeln("</html>");
}
else{
   if ("$wintitle"!=""){
      top.document.title="$wintitle";
   }
}
</script>
EOF
   print ("<frameset id=mselframe cols=\"200,*\" ".
          "framespacing=0 marginwidth=0 frameborder=0 border=0>\n");
   my $t2=$self->T("navigation area");
   print ("<frame marginwidth=0 marginheight=0 scrolling=auto ".
          "name=menuframe title=\"$t2\" ".
          "src=\"${rootpath}menuframe$fpfine\"></frame>\n");
   {
      my $currenturl="${rootpath}../../base/user/Main";
      my $openurl=Query->Param("OpenURL");
      if (($openurl=~m/^(http|https|news|telnet):/) ||
          ($openurl=~m/^\.\.\//)){
         Query->Delete("OpenURL");
         $currenturl=$openurl;
      }
      else{
         if (defined($mt->{fullname}->{$fp})){
            my $m=$mt->{fullname}->{$fp};
            my $target;
            if (defined($m->{acls}) && ref($m->{acls}) eq "ARRAY" &&
                ($#{$m->{acls}}==-1 ||
                 grep(/^read$/,$self->getCurrentAclModes($ENV{REMOTE_USER},
                                                     $m->{acls})))){
               $target=$self->targetUrl($m);
               #printf STDERR ("fifi read of $fp ok\n");
            }
            if (!defined($target)){
               #printf STDERR ("fifi read of $fp NOT ok\n");
            }
            if (defined($target)){
               if (($target=~m/^http[s]{0,1}:\/\//) ||
                   ($target=~m/^\/.*\/.*\?.*$/)){
                  $currenturl=$self->targetUrl($m);
               }
               else{
                  $currenturl=${rootpath}.$self->targetUrl($m);
               }
            }
            else{
               $currenturl=${rootpath}."IllegalTokenAccess";
            }
            my %forwardquery;
            foreach my $q (Query->Param()){
               next if (!($q=~m/^(OpenURL|search_|Auto|\S+[a-z]SUBMOD|DIRECT_)/));
               $forwardquery{$q}=[Query->Param($q)];
            }
            if (keys(%forwardquery)){
               $currenturl.="?" if (!($currenturl=~m/\?/));
               $currenturl.=kernel::cgi::Hash2QueryString(%forwardquery);
            }
         }
      }
      $currenturl.="?" if (!($currenturl=~m/\?/));
      $currenturl.="&".kernel::cgi::Hash2QueryString(         
         originalMenuSelection=>$originalMenuSelection 
      );
      my $t1=$self->T("data area");
      print ("<frame marginwidth=0 class=work marginheight=0 scrolling=auto ".
             "name=work title=\"$t1\" src=\"$currenturl\"></frame>\n");
   }
   print("</frameset>");
}


sub targetUrl
{
   my $self=shift;
   my $m=shift;

   my $target=$m->{target};
   #
   # target rewriting
   #
   # Pass 1: Module target
   if ($target=~m/^http[s]{0,1}:\/\//){
      my $tr=$m->{translation};
   }
   elsif ($target=~m/^tmpl\//){
      my $tr=$m->{translation};
      $tr=~s/::.*$//;
      $tr="base" if ($tr eq "");
      $target="../../$tr/load/$target";
   }
   elsif ($target=~m/^\/.*\/.*\?.*$/){
      $target="../../..$target";
   }
   elsif ($target=~m/::/){
      $target=~s/::/\//;
      $target="../../$target/".$m->{func};
   }
   # Pass 2: Template target
   my $param=$m->{param};
   $target.="?$param" if ($param ne "");
   return($target);
}



#####################################################################
#####################################################################
#####################################################################

sub MenuTab
{
   my $self=shift;
   my $rootpath=shift;
   my $active=shift;
   my $rootlink=shift;
   my $d="\n";
   
   $d.=kernel::MenuTree::BuildHtmlTree(
                     tree=>$self->_getMenuEntryFinalList($active,"normal"),
                     hrefclass=>'menulink',
                     rootlink =>$rootlink,
                     rootpath => $rootpath);
   return($d);
}

sub _getMenuEntryFinalList
{
   my $self=shift;
   my $active=shift;
   my $mode=shift;
   my $mt=$self->Cache->{Menu}->{Cache};

   my @mlist=();
   # Pass 1 Basis-Liste zusammenstellen
   foreach my $srcrec (values(%{$mt->{menuid}})){
      if (!defined($srcrec->{parent}) && $srcrec->{fullname} ne ""){
         my %clone=%{$srcrec};
         push(@mlist,\%clone);
      }
   }
   # Pass 2 unsichtbare Men�s herausfiltern
   my @modmlist=();
   foreach my $m (@mlist){
      next if ($m->{fullname}=~m/\$$/);
      if (grep(/^read$/,$self->getMenuAcl($ENV{REMOTE_USER},$m))){
         $self->processSubs($mt,$m,$active,$mode);
         push(@modmlist,$m);
      }
   }
   return(\@modmlist);
}

sub processSubs
{
   my $self=shift;
   my $mt=shift;
   my $m=shift;
   my $active=shift;
   my $mode=shift;
   my $rootpath=Query->Param("RootPath");


   my @subs=();
   foreach my $mid (@{$m->{subid}}){
      if ((substr($active,0,length($m->{fullname})+1) eq $m->{fullname}.'.' ||
          $active eq $m->{fullname}) || $mode eq "mobile"){
         my %clone=%{$mt->{menuid}->{$mid}};
         if ($#{$clone{acls}}==-1 || 
             grep(/^read$/,$self->getCurrentAclModes($ENV{REMOTE_USER},
                                                     $clone{acls}))){
                  push(@subs,\%clone);
            $self->processSubs($mt,\%clone,$active,$mode);
         }
      }
   }
   $m->{tree}=\@subs;
   delete($m->{tree}) if ($#{$m->{tree}}==-1);
   if ($m->{translation} ne ""){
      $m->{label}=$self->T($m->{fullname},$m->{translation});
   }
   else{
      $m->{label}=$m->{fullname};
      $m->{label}=~s/^.*\.//;
      $m->{label}=~s/_/ /g;
   }
   my $desc=$self->T($m->{fullname}.":Desc",$m->{translation});
   if ($desc ne $m->{fullname}.":Desc"){
      $m->{description}=$desc;
   }
   $m->{href}="${rootpath}msel/$m->{fullname}";
   $m->{active}=0;
   $m->{active}=1 if ($m->{fullname} eq $active);
   my $path=$m->{fullname};
   $path=~s/\./\//g;
   $m->{href}="${rootpath}msel/$path";
}



1;