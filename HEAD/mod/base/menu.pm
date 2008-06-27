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
use Data::Dumper;
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
      new kernel::Field::Linenumber(name     =>'linenumber',
                                    label      =>'No.'),

      new kernel::Field::Id(       name       =>'menuid',
                                   label      =>'W5BaseID',
                                   size       =>'10',
                                   dataobjattr=>'menu.menuid'),
                                  
      new kernel::Field::Text(     name       =>'fullname',
                                   htmlwidth  =>'180',
                                   label      =>'Fullname',
                                   dataobjattr=>'menu.fullname'),

      new kernel::Field::Text(     name       =>'target',
                                   label      =>'Target',
                                   dataobjattr=>'menu.target'),

      new kernel::Field::Text(     name       =>'prio',
                                   label      =>'Prio',
                                   dataobjattr=>'menu.prio'),

      new kernel::Field::Text(     name       =>'translation',
                                   label      =>'Translation',
                                   dataobjattr=>'menu.translation'),

      new kernel::Field::Text(     name       =>'func',
                                   label      =>'Function',
                                   dataobjattr=>'menu.func'),

      new kernel::Field::Textarea( name       =>'param',
                                   label      =>'Parameters',
                                   dataobjattr=>'menu.param'),

      new kernel::Field::Text(     name       =>'config',
                                   label      =>'Config',
                                   dataobjattr=>'menu.config'),

      new kernel::Field::Select(   name       =>'useobjacl',
                                   label      =>'use Object ACL',
                                   htmleditwidth=>'20%',
                                   transprefix   =>'useobjacl.',
                                   default    =>'0',
                                   uivisible  =>'0',
                                   value      =>['0','1'],
                                   dataobjattr=>'menu.useobjacl'),

      new kernel::Field::SubList(   name       =>'acls',
                                    xsearchable =>0,
                                    label      =>'Accesscontrol',
                                    subeditmsk =>'subedit.menu',
                                    allowcleanup=>1,
                                    group      =>'acl',
                                    vjoininhash=>[qw(acltarget 
                                                     acltargetid 
                                                     aclmode)],
                                    vjointo    =>'base::menuacl',
                                    vjoinbase=>{'aclparentobj'=>$self->Self()},
                                    vjoinon    =>['menuid'=>'refid'],
                                    vjoindisp  =>['acltargetname','aclmode']),

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
   if ($func eq "root"){
      if (!$self->TableVersionValidate()){
         $self->TableVersionChecker();
         return(0);
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

   return(qw(default)) if (!defined($oldrec));
   return(qw(ALL));
   return(undef);
}

sub isDeleteValid
{
   my $self=shift;
   my $oldrec=shift;

   return(qw(ALL));
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
          "root","menutop","menuframe","msel","TableVersionChecker",
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
         if ($command=~m/^use \S+$/ || $workdb->do($command)){
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
   my @tv=$db->getHashList("select * from tableversion");

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
   foreach my $sqlfile (sort(keys(%c))){
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
   return(undef) if ($errorcount==0 && $automodify);
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css',
                                   'TableVersion.css'],
                           form=>1,body=>1);
   print $self->getParsedTemplate("tmpl/TableVersionModifications",{
                                   static=>{
                                       BUTTONS=>$buttons,
                                       OPERATIONS=>$op,
                                       LOGHEAD=>"",
                                           LOG=>"",
                                      LOGSTYLE=>""}
                                  });
   print $self->HtmlBottom(form=>1,body=>1);
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
         next if ($v=~m/^search_/);
         next if ($v=~m/^AutoSearch$/);
         next if ($v=~m/^OpenURL$/);
         Query->Delete($v);
      }
      print $self->HtmlPersistentVariables(qw(ALL));
      print("</form>");
      print("</body>");
      print("</html>");
   }
   else{
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
      print $self->HtmlBottom();
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
   my $mt=$self->Cache->{Menu}->{Cache};

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(target=>'msel',
                              js=>['wz_tooltip.js'],
                             base=>'',
                            prefix=>$rootpath,
                           style=>['default.css','menu.css']);
   my $m=$self->MenuTab($rootpath,$mt,$fp,'JavaScript:SwitchMenuVisible() target=_self');
   print $self->getParsedTemplate("tmpl/menutmpl",{
                                       static=>{menutab=>$m,
                                                rootpath=>$rootpath}});
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
                           body=>1,form=>1);

   print $self->getParsedTemplate("tmpl/menuheader",{});
   print $self->HtmlBottom(body=>1,form=>1);
}

sub msel
{
   my $self=shift;
   my $mt=$self->Cache->{Menu}->{Cache};
   #printf STDERR ("fifi mtab=%s\n",Dumper($mt));
   my $fp=Query->Param("FunctionPath"); 
   $fp=~s/^\///;
   my @fp=split(/[\/\.]/,$fp);
   my $rootpath=Query->Param("RootPath");
   $fp=~s/\//./g;
   $fp=~s/"/./g;
   my $fpfine=$fp;
   $fpfine=~s/\./\//g;
   $fpfine="/".$fpfine if (!($fpfine=~m/^\//));

   my %qu=Query->MultiVars();
   foreach my $sv (keys(%qu)){
      next if ($sv=~m/^search_/);
      next if ($sv=~m/^AutoSearch$/);
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
</script>
EOF
   print ("<frameset id=mselframe cols=\"200,*\" ".
          "framespacing=0 marginwidth=0 frameborder=0 border=0>\n");
   print ("<frame marginwidth=0 marginheight=0 scrolling=auto ".
          "name=menuframe src=\"${rootpath}menuframe$fpfine\"></frame>\n");
   {
      my $currenturl="${rootpath}../../base/user/Main";
      if (my $openurl=Query->Param("OpenURL")){
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
               if ($target=~m/^http[s]{0,1}:\/\//){
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
               next if (!($q=~m/^(search_|Auto)/));
               $forwardquery{$q}=[Query->Param($q)];
            }
            if (keys(%forwardquery)){
               $currenturl.="?" if (!($currenturl=~m/\?/));
               $currenturl.=kernel::cgi::Hash2QueryString(%forwardquery);
            }
         }
      }
      print ("<frame marginwidth=0 class=work marginheight=0 scrolling=auto ".
             "name=work src=\"$currenturl\"></frame>\n");
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
   my $mt=shift;
   my $active=shift;
   my $rootlink=shift;
   my $d="\n";
   #$d="<xmp>".Dumper($mt)."</xmp>";
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
         $self->processSubs($mt,$m,$active);
         push(@modmlist,$m);
      }
   }
#printf STDERR ("l=%s\n",Dumper($mt));
   $d.=BuildHtmlTree(tree     => \@modmlist,
                     hrefclass=>'menulink',
                     rootlink =>$rootlink,
                     rootpath => $rootpath);
   return($d);
}

sub processSubs
{
   my $self=shift;
   my $mt=shift;
   my $m=shift;
   my $active=shift;
   my $rootpath=Query->Param("RootPath");


   my @subs=();
   foreach my $mid (@{$m->{subid}}){
      if (substr($active,0,length($m->{fullname})+1) eq $m->{fullname}.'.' ||
          $active eq $m->{fullname}){
         my %clone=%{$mt->{menuid}->{$mid}};
         if ($#{$clone{acls}}==-1 || 
             grep(/^read$/,$self->getCurrentAclModes($ENV{REMOTE_USER},
                                                     $clone{acls}))){
                  push(@subs,\%clone);
            $self->processSubs($mt,\%clone,$active);
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
