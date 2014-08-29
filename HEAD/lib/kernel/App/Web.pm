package kernel::App::Web;
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
use vars qw(@EXPORT @ISA);
use kernel;
use kernel::date;
use kernel::cgi;
use kernel::config;
use kernel::database;
use kernel::App;
use kernel::App::Web::Listedit;
use RPC::Smart::Client;
use Crypt::DES;
use HTTP::Date;
use Fcntl qw(O_CREAT O_TRUNC O_RDWR);
use Safe;
use Exporter;
@EXPORT = qw(&RunWebApp &W5Server);
@ISA    = qw(kernel::App Exporter);


sub RunWebApp
{
   my ($instdir,$configname)=@_;

   binmode(STDOUT,':raw');
   binmode(STDERR,':raw');

   #printf STDERR ("WebDav=%s\n",Dumper(\%ENV));
   my $cgi=new kernel::cgi();
   #msg(INFO,"query=%s",Dumper(scalar($cgi->MultiVars())));
   my $MOD=$cgi->UrlParam("MOD");
   my $objectkey=$ENV{'SCRIPT_NAME'}.":".$MOD;

   if (!exists($W5V2::ObjCache{$objectkey})){
      my $o=getModuleObject($instdir,$configname,$MOD);
      if (!defined($o)){
         print("Content-type:text/plain\n\n");
         print(msg(ERROR,"can't create DataObject '$MOD'"));
         return(undef);
      }
      $W5V2::ObjCache{$objectkey}=$o;
   }
   my $statedir=$W5V2::ObjCache{$objectkey}->Config->Param("LogState");
   my $havestate=undef;
   if ($statedir ne "" && -d $statedir ){
      my $f;
      $havestate="$statedir/$$.pid";
      if (sysopen($f,$havestate,O_RDWR|O_CREAT|O_TRUNC)){
         my $s="$ENV{'REMOTE_USER'};$MOD;".time().";\n";
         my $nb=length($s);
         if (syswrite($f,$s,$nb)!=$nb){
            close($f);
            unlink($havestate);
            sysmsg(ERROR,"error while write to statefile $havestate");
            $havestate=undef;
         }
         else{
            close($f);
         }
      }
      else{
         $havestate=undef;
      }
   }
   my $opmode=$W5V2::ObjCache{$objectkey}->Config->Param("W5BaseOperationMode");
   if (($opmode=~m/^offline/) || ($opmode=~m/^maintenance/)){
      return($W5V2::ObjCache{$objectkey}->DisplayMaintenanceWindow());
   }
   return if (!$W5V2::ObjCache{$objectkey}->InitRequest(cgi=>$cgi));

   my $bk=$W5V2::ObjCache{$objectkey}->Run();
   if ($havestate ne ""){
      unlink($havestate);
   }
   return($bk);
}

sub DisplayMaintenanceWindow
{
   my $self=shift;
   my $file=$ENV{SCRIPT_URI};
   $file=~s/^.*\///;
   my $skindir=$self->Config->Param("INSTDIR")."/skin/";
   my $skin="default";
   $skin="default.de" if ($self->LowLevelLang() eq "de");
   my ($opmode)=$self->Config->Param("W5BaseOperationMode");
   my ($ref)=$opmode=~m/^.*:(.*)$/;
   if ($file eq "MaintenanceIcon.jpg" ||
       $file eq "MaintenanceLogo.jpg"){
      if (open(F,"<$skindir/default/base/img/$file")){
         print("Content-type:image/jpg\n\n");
         print join("",<F>);
         close(F);
      }
      return(undef);
   }
   else{
      if (open(F,"<$skindir/$skin/base/tmpl/MaintenanceWelcome.html")){
         print("Content-type:text/html; charset=ISO-8895-1\n\n");
         my $d=join("",<F>);
         my $sitename=$self->Config->Param("SITENAME");
         $d=~s/\%SITENAME\%/$sitename/g;
         $ref="" if (!defined($ref));
         $d=~s/\%REF\%/$ref/g;
         print $d;
         close(F);
      }
      else{
         print("Content-type:text/plain\n\n");
         print("Sorry, W5Base is in maintenance mode.");
         return(undef);
      }
   }

   return(undef);
}

sub getValidWebFunctions
{
   my ($self)=@_;

   return(qw(Main mobileMain));
}


sub isFunctionValid
{
   my ($self,$func)=@_;

   return(1) if (grep(/^$func$/,$self->getValidWebFunctions()));
   return(0);
}


sub extractFunctionPath
{
   my $self=shift;

   my $func=Query->UrlParam("FUNC");

   if (my ($f,$p)=$func=~m/^([^\/]+)(\/.*)$/){
      my $rp="";
      if ($p=~m/\/$/){
         $rp="../";
         #$p=~s/\///;
      }
      my $fp=$p;
      Query->Param("FunctionPath"=>$p);
      my @flist=grep(!/^\.$/,grep(!/^$/,split(/\//,$p)));
      my @l=map({".."} @flist);
      if ($#l!=-1){
         $rp.=join("/",@l)."/";
      }
      Query->Param("RootPath"=>$rp);
      #printf STDERR ("fifi Function=%s FunctionPath=%s RootPath=%s\n",
      #           $func,Query->Param("FunctionPath"),Query->Param("RootPath"));
      return($f,$p);
   }
   
   return($func);
}

sub Run
{
   my ($self)=@_;
   my @valid_functions=qw(Main);
   my ($shortself)=$self=~m/^(.+)=/;
   my ($func,$p)=$self->extractFunctionPath();

   if ($self->isFunctionValid($func)){
      if ($self->can($func)){
         return($self->$func());
      }
      else{
         print $self->HttpHeader("text/plain");
         print msg(ERROR,"call '$func' allowed, but not defined in $shortself");
         return(1);
      }
   }
   print $self->HttpHeader("text/plain");
   print msg(ERROR,"invalid function call '$func' to $shortself");
   return(1);
}

sub W5Server
{
   return($W5V2::W5Server);
}



sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}

######################################################################

sub InitRequest
{
   my $self=shift;
   my $configname=$self->Config->getCurrentConfigName();
   my %p=@_;

   $W5V2::Query=$p{'cgi'};
   $W5V2::Context={};
   $W5V2::W5Server=undef;
   # maybee this is not needed
   #if (!defined(%W5V2::Translation)){
   #   #printf STDERR ("reset translation\n");
   #   %W5V2::Translation=();
   #}
   if (!defined($W5V2::Translation{"$self"})){
      #printf STDERR ("reset clear translation for $self\n");
      $W5V2::Translation{"$self"}={self=>$self,tab=>{}};
   }
   $W5V2::Translation=$W5V2::Translation{"$self"};
   
   if (!exists($self->Cache->{W5Server})){
      my %ClientParam;
      $ClientParam{'PeerAddr'}=$self->Config->Param("W5SERVERHOST");
      $ClientParam{'PeerPort'}=$self->Config->Param("W5SERVERPORT");
      $self->Cache->{W5Server}=new RPC::Smart::Client(%ClientParam);
      $self->Cache->{W5Server}->Connect();
   }
   if (exists($self->Cache->{W5Server})){
      $W5V2::W5Server=$self->Cache->{W5Server};
   }
   return(0) if (!$self->DatabaseLowInit());
   if (defined($self->Cache->{W5Base})){
      if ($self->Self() ne "base::load"){
         my $db=$self->Cache->{W5Base};
         my $now=NowStamp();
         my $loghour=substr($now,0,10);
         my $user=$ENV{REMOTE_USER};
         my $site=$ENV{SCRIPT_URI};
         if ($ENV{REMOTE_USER} ne ""){
            $site=~s/\/auth\/.*?$/\//;
         }
         else{
            $site=~s/\/public\/.*?$/\//;
         }
         my $lang="en";
         if ($self->LowLevelLang() eq ""){
            $ENV{HTTP_ACCEPT_LANGUAGE}="en";
         }
         $lang=$self->Lang();

         $user="anonymous" if ($user eq "");
         if ($self->Config->Param("W5BaseOperationMode") eq "readonly"){
            msg(INFO,"user '$user' logon from '$ENV{REMOTE_ADDR}'");
         }
         else{
            my $fldlst="account,loghour,logondate,logonbrowser,".
                       "logonip,lang,site";
            my $vallst="'$user','$loghour','$now',".
                       "'$ENV{HTTP_USER_AGENT}','$ENV{REMOTE_ADDR}','$lang',".
                       "'$site'"; 
            my $cmd="replace delayed into userlogon";
            $cmd.=" ($fldlst)";
            $cmd.=" values($vallst)";
            if (lc($db->DriverName()) eq "oracle"){
               $cmd="MERGE INTO userlogon a ".
                    "USING (select '$loghour' loghour,
                                   '$user' account from dual) b ".
                    "ON (a.loghour=b.loghour and a.account=b.account) ".
                    "WHEN NOT MATCHED THEN ".
                    "INSERT ($fldlst) VALUES ($vallst) ".
                    "WHEN MATCHED THEN ".
                    "UPDATE SET loghour='$loghour',logondate='$now'";
            }
            $db->do($cmd); 
         }
      }
   }
   if ($W5V2::OperationContext eq "W5Server"){
      $self->Cache->{User}={Cache=>{
                         $ENV{REMOTE_USER}=>{userid=>1,tz=>'GMT',lang=>'en'}}};
   }
   else{
      if (!defined($self->Cache->{User}) || 
          !defined($self->Cache->{User}->{DataObj})){
         my $o=getModuleObject($self->Config,"base::user");
         $self->Cache->{User}={DataObj=>$o,Cache=>{}};
      }
   }
   $ENV{REMOTE_USER}="anonymous" if (!defined($ENV{REMOTE_USER}) || 
                                     $ENV{REMOTE_USER} eq "");
   return(1) if ($self->Self eq "base::load");
   return(1) if ($self->Self eq "base::msg");
   ######################
   # hier mu� das User-Maskieren rein
   #
   $ENV{REAL_REMOTE_USER}=$ENV{REMOTE_USER};
   my $substuser=Query->Cookie("remote_user");
   if ($ENV{REMOTE_USER} ne "anonymous" &&
       defined($substuser) && $substuser ne $ENV{REAL_REMOTE_USER}){
      $self->ValidateCaches();
      my $usermask=getModuleObject($self->Config,"base::usermask");
      my @l=$usermask->isSubstValid($ENV{REAL_REMOTE_USER},$substuser);
      if ($#l==0){
         $ENV{REMOTE_USER}=$substuser;
      }
      else{
         msg(ERROR,"illegal request to mask $ENV{REAL_REMOTE_USER} as %s in %s",
                   $substuser,$self->Self);
      }
   }
   $self->Log(INFO,"query","$ENV{REMOTE_USER} %s query:%s",
                   $self->Self,Query->QueryString());
   ######################
   return($self->ValidateCaches());
}

sub DatabaseLowInit
{
   my $self=shift;

   if (!defined($self->Cache->{W5Base})){
      my $db=new kernel::database($self,"w5base");
      if (!defined($db)){
         printf("Content-type: text/plain\n\n%s","Database object error");
      }
      else{
         my ($dbh,$msg)=$db->Connect();
         if ($db->dbname() eq "w5base"){
            $self->Cache->{W5Base}=$db;
         }
         if (!defined($dbh) || !$db->isConnected()){
            printf("Content-type: text/plain\n\n%s","DB Connect: ".$msg);
            return(0);
         }
      }
   }
   return(1);
}


sub getAppDirectLink
{
   my $self=shift;

   return('Main');
}


sub getAppTitleBar
{
   my $self=shift;
   my %param=@_;
   my $d="";

   my $prefix=$param{prefix};

   my $user=$ENV{REMOTE_USER};
   my $onclick=" id=LoggedInAs onclick=\"UserMask();\" ";
   if ($ENV{REMOTE_USER} ne $ENV{REAL_REMOTE_USER} &&
       $ENV{REMOTE_USER} ne "anonymous"){
      $user.=" (".$self->T("authenticated as")." ".$ENV{REAL_REMOTE_USER}.")";
      
   }
   if ($ENV{REMOTE_USER} eq "anonymous"){
      $onclick=" ";
   }
   $param{title}=$self->T($self->Self,$self->Self) if (!defined($param{title}));

   my $titleonclick="";
   if ($self->can("ModuleObjectInfo")){
      $titleonclick="onclick=\"ModuleObjectInfo();return(false);\" ".
                    "id=ModuleObjectInfo";
   }
   my $titlebar=sprintf("<tr class=TitleBar><td nowrap align=left>".
                 "<div $titleonclick ".
                 "style=\"margin:0;padding:0;padding-left:5px;".
                 "text-overflow:ellipsis;overflow:hidden;width:380px\">".
                 "<a class=TitleBarLink target=_top ".
                 "href='".$self->getAppDirectLink()."'>".
                 "%s</a>&nbsp;</div></td>".
                 "<td align=right nowrap><div $onclick ".
                 "style=\"margin:0;padding:0;padding-right:5px;".
                 "margin-left:10px;\">%s</div>".
                 "</td></tr>",$param{title},
                                    $self->T("Logged in as")." ".$user);
   $d=<<EOF;
<table id=TitleBar width=100% height=15 border=0 cellspacing=0 cellpadding=0>
$titlebar
</table>
<script type="text/javascript" 
        language=JavaScript 
        src="$prefix../../../public/base/load/toolbox.js">
</script>
<script type="text/javascript" 
        language=JavaScript 
        src="$prefix../../../public/base/load/kernel.App.Web.js">
</script>
<script language="JavaScript">
function RestartApp(retVal,isbreak)
{
   if (!isbreak){
      if (window.parent){
         window.parent.document.location.href=
                window.parent.document.location.href;
      }
   }
}
function UserMask()
{
   showPopWin('$prefix../../base/usermask/Main',500,200,RestartApp);
}
function ModuleObjectInfo()
{
   showPopWin('${prefix}ModuleObjectInfo',580,400);
}
</script>
EOF
   return($d);
}


sub Empty
{
   my $self=shift;
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','mainwork.css'],
                           body=>1,form=>1);
   print $self->HtmlBottom(body=>1,form=>1);
   return(0);
}


sub getHtmlContextMenu
{
   my $self=shift;
   my $name=shift;
   my @contextMenu=@_;

   my $contextMenu;
   if ($#contextMenu!=-1){
      $contextMenu="<div id=\"contextMenu_$name\" "
                   ."class=\"context_menu\">";
      $contextMenu.="<table cellspacing=\"1\" cellpadding=\"2\" ".
                    "border=\"0\">";
      while(my $label=shift(@contextMenu)){
         my $link=shift(@contextMenu);
         $contextMenu.="\n<tr>";
         $contextMenu.="<td class=\"std\" ".
                       "onMouseOver=\"this.className='active';\" ".
                       "onMouseOut=\"this.className='std';\">";
         $contextMenu.="<div onMouseUp=\"$link\">$label</div>";
         $contextMenu.="</td></tr>";
      }
      $contextMenu.="\n</table>";
      $contextMenu.="</div>";
   }
   return($contextMenu);
}


sub ValidateCaches
{
   my $self=shift;

   my $res=$self->W5ServerCall("rpcMultiCacheQuery",$ENV{REMOTE_USER});
   $res={} if (!defined($res));
   return(0) if (!$self->ValidateMenuCache($res->{Menu}));
   return(0) if (!$self->ValidateUserCache($res->{User}));
   return(0) if (!$self->ValidateGroupCache($res->{Group}));
   return(0) if (!$self->ValidateMandatorCache($res->{Mandator}));

   my $UserCache=$self->Cache->{User}->{Cache};
   if ($ENV{REMOTE_USER} ne "anonymous" && #locked account check
       defined($UserCache->{$ENV{REMOTE_USER}}) &&
       defined($UserCache->{$ENV{REMOTE_USER}}->{rec}->{cistatusid})){ 
      if ($UserCache->{$ENV{REMOTE_USER}}->{rec}->{cistatusid}!=4){
         if (Query->Param("MOD") eq "base::interface"){
            printf("Status: 403 Forbidden - ".
                   "account needs to be activated with web browser\n");
            printf("Content-type: text/xml\n\n".
                   "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
            return(0);
         }
         else{
            if ($UserCache->{$ENV{REMOTE_USER}}->{rec}->{cistatusid}==3){
               if (!$self->GTCverification()){
                  return(0);
               }
               $self->ValidateUserCache($res->{User});
               return(1);
            }
            print("Content-type:text/plain;charset=ISO-8895-1\n\n");
            printf(msg(ERROR,$self->T("access for user '\%s' to W5Base ".
                             "Framework rejected")),$ENV{REMOTE_USER});
            printf(msg(INFO,$self->T("possible reasons are a locked account ".
                            "or an incorrect contact definition")));
            printf(msg(INFO,$self->T("please contact the admins if you think,".
                            " this isn't purposed")));
            return(0);
         }
      }
      if ($#{$UserCache->{$ENV{REMOTE_USER}}->{rec}->{ipacl}}!=-1){
         if (!in_array($UserCache->{$ENV{REMOTE_USER}}->{rec}->{ipacl},
              $ENV{REMOTE_ADDR})){
            if (Query->Param("MOD") eq "base::interface"){
               printf("Status: 403 Forbidden - ".
                      "your ip $ENV{REMOTE_ADDR} is not allowed in ipacl ".
                      "for $ENV{REMOTE_USER}\n");
               printf("Content-type: text/xml\n\n".
                      "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
               return(0);
            }
            else{
               print("Content-type:text/plain;charset=ISO-8895-1\n\n");
               printf(msg(ERROR,$self->T("access for user '\%s' to W5Base ".
                                "Framework rejected")),$ENV{REMOTE_USER});
               printf(
                  msg(INFO,$self->T("your client ip is rejected by ipacl")));
               return(0);
            }
         }
      }
   }

   return(1);
}

sub GTCverification
{
   my $self=shift;
   my $gtc=$self->getParsedTemplate("tmpl/gtc",{skinbase=>'base'});
   if (Query->Param("GTCSURE") eq "OK"){
      my $txt=Query->Param("GTCTEXT");
      $txt=~s/\r\n/\n/g;
      if (trim($txt) eq trim($gtc)){
         my $userid=$self->getCurrentUserId();
         my $user=getModuleObject($self->Config(),"base::user");
         $user->SetFilter({userid=>\$userid,cistatusid=>\'3'});
         my ($urec)=$user->getOnlyFirst(qw(ALL));
         if (defined($urec)){
            my $gtcdate=NowStamp("en");
            if ($user->ValidatedUpdateRecord($urec,{cistatusid=>'4',
                                                    gtcack=>$gtcdate,
                                                    gtctxt=>$txt},
                                             {userid=>\$userid})){
               msg(INFO,"activation of user account $userid ok");
               my $currenturl=$ENV{SCRIPT_URI};
               $currenturl=~
                  s/\/(auth|public)\/.*/\/auth\/base\/menu\/msel\/MyW5Base/;
               $self->HtmlGoto($currenturl);
               return(0);
            }
                                                    
         }
      }
      else{
         $self->LastMsg(ERROR,"gtc text has not been accepted unmodified");
      }
   }
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css'],
                           body=>1,form=>1,
                           title=>'W5Base - GTC verification');
   print ("<input type=hidden name=GTCSURE value=''>");
   my $sitename=$self->Config->Param("SITENAME");
   my $suremsg=$self->T("You are sure, you will accept the completly GTC's ".
                        "and have understood all consequences?");
   my $nomsg=$self->T("Without accepted GTC's, no access could be granted!");
   print(<<EOF);
<script language="JavaScript">
function GTC_accept()
{
   if (confirm("$suremsg")){
      document.forms[0].elements['GTCSURE'].value="OK";
      document.forms[0].submit();
   }
}
function GTC_decline()
{
  alert("$nomsg");
}
// framebreaker
if (top.location != self.location) {
    top.location = self.location.href
}

</script>
EOF
   print $self->getParsedTemplate("tmpl/gtcform",{
                          static=>{
                                gtc=>$gtc,
                                SITENAME=>$sitename
                          },
                          translation=>'base::gtcform',
                          skinbase=>'base'
                           });

   print $self->HtmlBottom(body=>1,form=>1);
   return(0);
}


sub InvalidateGroupCache
{
   my $self=shift;

   delete($self->Cache->{Group}->{Cache});
   $self->W5ServerCall("rpcCacheInvalidate","Group");
   msg(INFO,"rpcCacheInvalidate Group global");
}

sub InvalidateMandatorCache
{
   my $self=shift;

   delete($self->Cache->{Group}->{Cache});
   $self->W5ServerCall("rpcCacheInvalidate","Mandator");
   msg(INFO,"rpcCacheInvalidate Mandator global");
}

sub InvalidateMenuCache
{
   my $self=shift;

   delete($self->Cache->{Group}->{Cache});
   $self->W5ServerCall("rpcCacheInvalidate","Menu");
   msg(INFO,"rpcCacheInvalidate Menu global");
}

sub InvalidateUserCache
{
   my $self=shift;
   my $user=shift;

   my $UserCache=$self->Cache->{User}->{Cache};
   delete($UserCache->{$user});
   $self->W5ServerCall("rpcCacheInvalidate","User",$user);
   if ($user ne ""){
      msg(INFO,"rpcCacheInvalidate User for user '%s'",$user);
   }
   else{
      msg(INFO,"rpcCacheInvalidate User global");
   }
}


sub ValidateMandatorCache
{
   my $self=shift;
   my $multistate=shift;

   if (defined($self->Cache->{Mandator}->{state})){
      my $res={state=>$multistate};
      if (!defined($res->{state})){
         $res=$self->W5ServerCall("rpcCacheQuery","Mandator");
      }
      if (!defined($res)){
         msg(INFO,"W5ServerCall failed - cache for cwMandator cleared");
         delete($self->Cache->{Mandator});
      }
      elsif ($self->Cache->{Mandator}->{state} ne $res->{state}){
         msg(INFO,"cache for Mandator is invalid - ".
                  "cleared state='%s' rpcstate='%s'",
                  $self->Cache->{Mandator}->{state},
                  $res->{state});
         delete($self->Cache->{Mandator});
      }
      if (defined($self->Cache->{Mandator})){
         $self->Cache->{Mandator}->{atime}=time();
      }
   }
   if (!defined($self->Cache->{Mandator}->{Cache})){
      #printf STDERR ("-------------- Mandators loaded --------------\n");
      my $mandator=getModuleObject($self->Config,"base::mandator");
      $mandator->SetFilter({id=>'>-999999999'}); # prefend slow query entry
      $mandator->SetCurrentView(qw(grpid name cistatusid contacts additional));
      $mandator->SetCurrentOrder("NONE");
      $self->Cache->{Mandator}->{Cache}=$mandator->getHashIndexed("id","grpid");
      $self->Cache->{Mandator}->{DataObj}=$mandator;
      my $ca=$self->Cache->{Mandator}->{Cache};
      foreach my $id (keys(%{$ca->{id}})){
         my $mc=$ca->{id}->{$id};
         if (ref($mc->{additional}) ne "HASH"){
            my %h=Datafield2Hash($mc->{additional});
            $mc->{additional}=\%h;
         }
      }
      my $res=$self->W5ServerCall("rpcCacheQuery","Mandator");
      if (defined($res)){
         $self->Cache->{Mandator}->{state}=$res->{state};
      }
   }
   return(1);
}


sub ValidateMenuCache
{
   my $self=shift;
   my $multistate=shift;

   if (defined($self->Cache->{Menu}->{state})){
      my $res={state=>$multistate};
      if (!defined($res->{state})){
         $res=$self->W5ServerCall("rpcCacheQuery","Menu");
      }
      if (!defined($res)){
         msg(INFO,"W5ServerCall failed - cache for cwMenu cleared");
         delete($self->Cache->{Menu});
      }
      elsif ($self->Cache->{Menu}->{state} ne $res->{state}){
         msg(INFO,"cache for Menu is invalid - ".
                  "cleared state='%s' rpcstate='%s'",
                  $self->Cache->{Menu}->{state},
                  $res->{state});
         delete($self->Cache->{Menu});
      }
      if (defined($self->Cache->{Menu})){
         $self->Cache->{Menu}->{atime}=time();
      }
   }
   if (!defined($self->Cache->{Menu}->{Cache})){
      #printf STDERR ("-------------- Menus loaded --------------\n");
      my $menuacl=getModuleObject($self->Config,"base::menuacl");
      $menuacl->SetFilter({aclparentobj=>\'base::menu'});
      $menuacl->SetCurrentView(qw(refid acltarget acltargetid aclmode));
      $menuacl->SetCurrentOrder(qw(NONE));
      my $acls=$menuacl->getHashIndexed("refid");
      my $menu=getModuleObject($self->Config,"base::menu");
      my $configname=$self->Config->getCurrentConfigName();
      $menu->SetCurrentView(qw(prio menuid fullname config target 
                               parent param func translation subid));
      $menu->SetFilter({config=>\$configname});
      $self->Cache->{Menu}->{Cache}=$menu->getHashIndexed(qw(menuid fullname));
      $self->Cache->{Menu}->{DataObj}=$menu;
      my $ca=$self->Cache->{Menu}->{Cache};
      foreach my $menu (values(%{$self->Cache->{Menu}->{Cache}->{menuid}})){
         if (!defined($menu->{subid})){
            $menu->{subid}=[];
         }
         next if ($menu->{fullname} eq "");
         my ($p)=$menu->{fullname}=~m/^(\S+)\..+?/;
         my $macls=$acls->{refid}->{$menu->{menuid}};
         if (ref($macls) ne "ARRAY"){
            if (defined($macls)){
               $macls=[$macls];
            }
            else{
               $macls=[];
            }
         }
         $menu->{acls}=$macls;
         next if ($p eq "");
         $menu->{parent}=$p;
         if (defined($ca->{fullname}->{$p})){
            my $p=$ca->{fullname}->{$p};
            $menu->{parent}=$p;
            if (!defined($p->{subid})){
               $p->{subid}=[$menu->{menuid}];
            }
            else{
               push(@{$p->{subid}},$menu->{menuid});
            }
         }
      }
      my $res=$self->W5ServerCall("rpcCacheQuery","Menu");
      if (defined($res)){
         $self->Cache->{Menu}->{state}=$res->{state};
      }
      $self->RefreshMenuTable() if ($self->can("RefreshMenuTable"));
   }
   return(1);
}


sub getMenuAcl
{
   my $self=shift;
   my $account=shift;
   my @acl;
   if (ref($_[0]) eq "HASH"){  # call on menu hash reference
      if ($#{$_[0]->{acls}}==-1){
         @acl=("read");
      }
      else{
         @acl=$self->getCurrentAclModes($account,$_[0]->{acls});
      }
   }
   else{
      my $menucache=$self->Cache->{Menu}->{Cache};
      return(undef) if (!defined($menucache));
      #printf STDERR ("fifi %s\n",Dumper($menucache));
      my %a=();
      my $target=shift;
      my %param=@_;
      my $found=0;
      foreach my $m (values(%{$menucache->{menuid}})){
         next if ($m->{target} ne $target); 
         next if (defined($param{func}) && 
                  ((!ref($param{func}) && $m->{func} ne $param{func}) ||
                   (ref($param{func}) eq "ARRAY" &&
                    !in_array($param{func},$m->{func})))); 
         next if (defined($param{param}) && $m->{param} ne $param{param}); 
         $found=1;
         if (ref($m->{acls}) eq "ARRAY" && $#{$m->{acls}}==-1){
            $a{read}=1;
         }
         else{
            my @l=$self->getCurrentAclModes($account,$m->{acls});
            map({$a{$_}=1} @l);
         }
      }
      return(undef) if (!$found);
      @acl=keys(%a);
   }
   if (wantarray()){
      return(@acl);
   }
   return(\@acl);
}



sub RefreshMenuTable
{
   my $self=shift;

   $self->{MenuIsChanged}=0;
   $self->{CompareMenu}={};
   if (defined($self->Cache->{Menu}->{Cache})){
      $self->{CompareMenu}=$self->Cache->{Menu}->{Cache};
   }
   
   #printf STDERR ("----------= Start register Modules -----\n");
   $self->LoadSubObjs("menu","SubMenuObj");
   #printf STDERR ("----------= Ende  register Modules -----\n");
   if ($self->{MenuIsChanged}){
      $self->InvalidateMenuCache();
      $self->ValidateMenuCache();
      $self->{MenuIsChanged}=0;
   }
   delete($self->{SubMenuObj});
}



sub ValidateUserCache
{
   my $self=shift;
   my $multistate=shift;

   my $UserCache=$self->Cache->{User}->{Cache};
   if ($W5V2::OperationContext eq "W5Server"){
      $UserCache->{$ENV{REMOTE_USER}}={};
   }
   if (defined($UserCache->{$ENV{REMOTE_USER}}) &&
       $ENV{REMOTE_USER} ne "anonymous"){
      my $res={state=>$multistate};
      if (!defined($res->{state})){
         $res=$self->W5ServerCall("rpcCacheQuery","User",$ENV{REMOTE_USER});
      }
      if (!defined($res)){
         msg(INFO,"W5ServerCall failed - cache for $ENV{REMOTE_USER} cleared");
         delete($UserCache->{$ENV{REMOTE_USER}});
      }
      elsif ($UserCache->{$ENV{REMOTE_USER}}->{state} ne $res->{state} ||
             !defined($UserCache->{$ENV{REMOTE_USER}}->{state})){
         #msg(INFO,"cache for $ENV{REMOTE_USER} is invalid - ".
         #         "cleared state='%s' rpcstate='%s'",
         #         $UserCache->{$ENV{REMOTE_USER}}->{state},
         #         $res->{state});
         delete($UserCache->{$ENV{REMOTE_USER}});
      }
      if (defined($UserCache->{$ENV{REMOTE_USER}})){
         $UserCache->{$ENV{REMOTE_USER}}->{atime}=time();
      }
   }
   if ($ENV{REMOTE_USER} eq "anonymous"){
      $UserCache->{$ENV{REMOTE_USER}}->{rec}={};
      $UserCache->{$ENV{REMOTE_USER}}->{state}=1;
      $UserCache->{$ENV{REMOTE_USER}}->{atime}=time();
   }
   if ($W5V2::OperationContext ne "W5Server" &&   # do not load cache as W5Srv
       !defined($UserCache->{$ENV{REMOTE_USER}})){
      my $res=$self->W5ServerCall("rpcCacheQuery","User",$ENV{REMOTE_USER});
      my $o=$self->Cache->{User}->{DataObj};
      if ($o){
         if ($self->_LoadUserInUserCache($ENV{REMOTE_USER},$res)){
            return(1);
         }
         else{
            return($self->HandleNewUser());
         }
      }
      else{
         return(0);
      }
   }
   return(1);
}

sub HandleNewUser
{
   my $self=shift;

   if (Query->Param("MOD") eq "base::interface"){
      printf("Status: 403 Forbidden - ".
             "account needs to be activated with web browser\n");
      printf("Content-type: text/xml\n\n".
             "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
      return(0);
   }
   if ($self->Config->Param("W5BaseOperationMode") eq "readonly" ||
       $self->Config->Param("W5BaseOperationMode") eq "slave"){
      my $msg="account '$ENV{REMOTE_USER}' ".
              "needs to be activated in master system";
     # printf("Status: 403 Forbitten - $msg");
      printf("Content-type: text/html\n\n");
      printf("<html><body><h1>$msg</h1></body></html>");
      return(0);
   }

   my $ua=getModuleObject($self->Config,"base::useraccount");
   $ua->SetFilter({'account'=>[$ENV{REMOTE_USER}]});
   $ua->SetCurrentView(qw(account userid requestemail requestemailwf));
   my ($uarec,$msg)=$ua->getFirst();
   if (!defined($uarec)){
      $ua->ValidatedInsertRecord({account=>$ENV{REMOTE_USER}});
      ($uarec,$msg)=$ua->getFirst();
      if (!defined($uarec)){
         if ($self->LastMsg()==0){
            $self->LastMsg(ERROR,"unknown problem while creating account '%s'",
                           $ENV{REMOTE_USER});
         }
         print("Content-type:text/plain\n\n".
               join("\n",$self->LastMsg()));
         return(0);
      }
   }
   if (!defined($uarec->{userid})){
      if (defined(Query->Param("verify"))){
         my $code=Query->Param("code");
         if ($code==$uarec->{requestemailwf}){
            my $user=getModuleObject($self->Config,"base::user");
            my $useremail=getModuleObject($self->Config,"base::useremail");
            my $uerec;
            $user->SetFilter({emails=>$uarec->{requestemail}});
            $user->SetCurrentView(qw(ALL));
            my ($urec,$msg)=$user->getFirst();
            if (!defined($urec)){  # now check, if email is in useremail set
               $useremail->SetFilter({email=>$uarec->{requestemail}});
               $useremail->SetCurrentView(qw(ALL));
               ($uerec,$msg)=$useremail->getFirst();
               if (defined($uerec)){
                  if ($uerec->{userid} eq ""){
                     $useremail->ValidatedDeleteRecord($uerec);
                     $uerec=undef;
                  }
                  $user->ResetFilter();
                  $user->SetFilter({userid=>\$uerec->{userid}});
                  $user->SetCurrentView(qw(ALL));
                  ($urec,$msg)=$user->getFirst();
               }
            }
            if (defined($urec)){
               if (defined($uerec) && $uerec->{cistatusid}>4){ #marked addresses
                  print $self->HttpHeader("text/html");
                  print $self->HtmlHeader(style=>['default.css','work.css'],
                                       body=>1,form=>1,action=>$ENV{SCRIPT_URI},
                                       refresh=>5,
                                       title=>'W5Base - account verification');
                  print $self->getParsedTemplate("tmpl/accountverificationdeny",
                        { static=>{ 
                               email=>$uarec->{requestemail},
                               account=>$ENV{REMOTE_USER}},
                         translation=>'base::accountverification',
                         skinbase=>'base'
                        });
                  return(0);
               }
               $ua->ValidatedUpdateRecord($uarec,{userid=>$urec->{userid},
                                                  requestemailwf=>undef},
                                   {account=>$ENV{REMOTE_USER}});
               #
               # update user record because the user is inactive or
               # it already exists as an external user
               #
               my $updrec={usertyp=>'user',creator=>$urec->{userid}};
               $updrec->{cistatusid}=3 if ($urec->{cistatusid}<4);
               if ($urec->{gtctxt} eq ""){ # if no gtc act - we request it
                  $updrec->{cistatusid}=3;
               }
               
               $user->ValidatedUpdateRecord($urec,$updrec,
                                   {userid=>\$urec->{userid}});
               if (defined($uerec)){
                  $useremail->ValidatedUpdateRecord($uerec,{cistatusid=>4},
                                   {id=>\$uerec->{id}});
               }
            }
            else{
               my $userid=undef;
               my $res;
               if (defined($res=$self->W5ServerCall("rpcGetUniqueId")) &&
                   $res->{exitcode}==0){
                  $userid=$res->{id};
               }
               my $id;
               if (defined($userid)){
                  $id=$user->ValidatedInsertRecord(
                                    {email=>$uarec->{requestemail},
                                     userid=>$userid,
                                     allowifupdate=>1,
                                     owner=>$userid,
                                     creator=>$userid,
                                     cistatusid=>3});
               }
               if (!defined($id)){
                  printf("Content-type:text/plain\n\n".
                         "ERROR: can't insert User\n");
                  return(0);
               }
               else{
                  $ua->ValidatedUpdateRecord($uarec,{userid=>$id},
                                   {account=>$ENV{REMOTE_USER}});
               }
            }
            $user->SetFilter({accounts=>\$ENV{REMOTE_USER}});
            my ($urec,$msg)=$user->getFirst();
            if (defined($uarec)){
               print $self->HttpHeader("text/html");
               print $self->HtmlHeader(style=>['default.css','work.css'],
                                       body=>1,form=>1,action=>$ENV{SCRIPT_URI},
                                       title=>'W5Base - account verification');
               print $self->getParsedTemplate("tmpl/accountverificationok",{
                                      static=>{ 
                                            email=>$uarec->{requestemail},
                                            account=>$ENV{REMOTE_USER}},
                                      translation=>'base::accountverification',
                                      skinbase=>'base'
                                       });
               my %p=(eventname=>'UserVerified',
                      spooltag=>'UserVerified-'.$ENV{REMOTE_USER},
                      redefine=>'1',
                      retryinterval=>600,
                      firstcalldelay=>30,
                      eventparam=>$ENV{REMOTE_USER},
                      userid=>11634953080001);
               $self->W5ServerCall("rpcCallSpooledEvent",%p);
             #  $self->W5ServerCall("rpcCallEvent","UserVerified",
             #                      $ENV{REMOTE_USER});
               $self->W5ServerCall("rpcCacheInvalidate","User",
                                   $ENV{REMOTE_USER});
               return(1);
            }
            else{
               $self->LastMsg(ERROR,"verification failed - unknown error");
            }
         }
         else{
            $self->LastMsg(ERROR,"the verification code is not correct");
         }
      }
      if (defined(Query->Param("correction"))){
         $ua->ValidatedUpdateRecord($uarec,{requestemailwf=>undef},
                                   {account=>$ENV{REMOTE_USER}});
         ($uarec,$msg)=$ua->getFirst();
      }
      if (defined(Query->Param("save"))){
         my $em=Query->Param("email");
         my $id;
         if ($ua->ValidatedUpdateRecord($uarec,{requestemail=>$em},
                                        {account=>$ENV{REMOTE_USER}})){
            my $res;
            if (defined($res=$self->W5ServerCall("rpcGetUniqueId")) &&
                $res->{exitcode}==0){
               $id=$res->{id};
            }
            if (defined($id)){
               my $wf=getModuleObject($self->Config,"base::workflow");
               my $subject=$self->T("MSG400",'base::accountverification').
                           " ".$ENV{REMOTE_USER};
               my $sitename=$self->Config->Param("SITENAME");
               if ($sitename ne ""){
                  $subject=$sitename.": ".$subject;
               }
               my $currenturl=$ENV{SCRIPT_URI};
               $currenturl=~
                  s/\/(auth|public)\/.*/\/auth\/base\/menu\/msel\/MyW5Base/;
               my $fromemail=$em;
               my $uobj=getModuleObject($self->Config,"base::user");
               $uobj->SetFilter({cistatusid=>\'4',isw5support=>\'1'});
               my ($urec)=$uobj->getOnlyFirst(qw(email));
               if (ref($urec) eq "HASH" && $urec->{email} ne ""){
                  $fromemail=$urec->{email};
               }

               if ($id=$wf->Store(undef,{
                      id       =>$id,
                      class    =>'base::workflow::mailsend',
                      step     =>'base::workflow::mailsend::dataload',
                      name     =>$subject,
                      emailfrom=>$fromemail,
                      emailto  =>$em,
                      emailtext=>$self->getParsedTemplate(
                                   "tmpl/accountverificationmail",
                                   { static=>{ email=>$em,
                                               id=>$id,
                                               initialsite=>$ENV{SERVER_NAME},
                                               currenturl=>$currenturl,
                                               account=>$ENV{REMOTE_USER}
                                             },
                                     translation=>'base::accountverification',
                                     skinbase=>'base'
                                   }),
                     })){
                  my %d=(step=>'base::workflow::mailsend::waitforspool');
                  my $r=$wf->Store($id,%d);
                  $ua->ValidatedUpdateRecord($uarec,{requestemailwf=>$id},
                                             {account=>$ENV{REMOTE_USER}});
               }
            }
         }
         ($uarec,$msg)=$ua->getFirst();
         msg(INFO,"  ---------------------------------------------------".
                  "---------------------------");
         msg(INFO,"  --- Account request code %s has been sent to '%s' ".
                  "---",$id,$ENV{REMOTE_USER});
         msg(INFO,"  ---------------------------------------------------".
                  "---------------------------");
      }
      my $em=$uarec->{requestemail};
      if (defined(Query->Param("email"))){
         $em=Query->Param("email"); 
      }
      print $self->HttpHeader("text/html");
      print $self->HtmlHeader(style=>['default.css','work.css'],
                              body=>1,form=>1,
                              title=>'W5Base - account verification');
      if (!defined($uarec->{requestemailwf})){
         if ($self->Config->Param("W5BaseOperationMode") eq "test"){
            print $self->getParsedTemplate("tmpl/accountverificationtestmode",{
                                     static=>{ email=>$em,
                                               account=>$ENV{REMOTE_USER}},
                                     translation=>'base::accountverification',
                                     skinbase=>'base'
                                      });
         }
         else{
            print $self->getParsedTemplate("tmpl/accountverification",{
                                     static=>{ email=>$em,
                                               account=>$ENV{REMOTE_USER}},
                                     translation=>'base::accountverification',
                                     skinbase=>'base'
                                      });
         }
      }
      else{
         print $self->getParsedTemplate("tmpl/accountverificationwait",{
                                     static=>{ email=>$em },
                                     translation=>'base::accountverification',
                                     skinbase=>'base'
                                      });
      }
      print("\n<script type=\"text/javascript\" language=\"JavaScript\">".
            "if (top.location != self.location){".
            "top.location=self.location.href;".
            "}</script>\n");

      print $self->HtmlBottom(body=>1,form=>1);
      return(0);
   }
   return(0);
}

sub getCurrentUserId
{
   my $self=shift;
   my $userid;
   return(undef) if ($W5V2::OperationContext eq "W5Server");
   return(undef) if ($W5V2::OperationContext eq "QualityCheck");
   my $UserCache=$self->Cache->{User}->{Cache};
   if (defined($UserCache->{$ENV{REMOTE_USER}})){
      $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
   }
   if (defined($UserCache->{tz})){
      $userid=$UserCache->{userid};
   }
   $userid="-2" if (!defined($userid));  # Securiy Fix - for not logged in
   return($userid);                      # -2 is also groupid of group anonymous
}


sub getCurrentSecState
{
   my $self=shift;
   return(4) if ($W5V2::OperationContext eq "W5Server" ||
                 $W5V2::OperationContext eq "W5Replicate" ||
                 $W5V2::OperationContext eq "Kernel"); # return max sec level
   my $secstate=1;
   my $UserCache=$self->Cache->{User}->{Cache};
   if (defined($UserCache->{$ENV{REMOTE_USER}})){
      $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
   }
   if (defined($UserCache->{tz})){
      $secstate=$UserCache->{secstate};
   }
   return($secstate);
}



sub IsMemberOf
{
   my $self=shift;
   my $group=shift;      # fullname or group id
   my $roles=shift;      # internel names of roles         (undef=RMember)
   my $direction=shift;  # up | down | both | direct       (undef=direct)

   $roles=["RMember"]   if (!defined($roles));
   $roles=[$roles]      if (ref($roles) ne "ARRAY");
   $direction="direct"  if (!defined($direction));
   $group="admin"       if (!defined($group));
   $group=[$group]      if (ref($group) ne "ARRAY");

   if ((grep(/^valid_user$/,@$group) ||
        grep(/^-1$/,@$group)) &&
       in_array($roles,'RMember')){
      return(1) if ($ENV{REMOTE_USER} ne "" &&
                    $ENV{REMOTE_USER} ne "anonymous");
   }
   if ((grep(/^anonymous$/,@$group) ||
       grep(/^-2$/,@$group)) &&
       in_array($roles,'RMember')){
      return(1) if ($ENV{REMOTE_USER} eq "" ||
                    $ENV{REMOTE_USER} eq "anonymous");
   }
   if (grep(/^admin$/,@$group)){
      my $ma=$self->Config->Param("MASTERADMIN");
      if ($ma ne "" && $ENV{REMOTE_USER} eq $ma){
         return(1);
      }
   }
   my %grps=$self->getGroupsOf($ENV{REMOTE_USER},$roles,$direction);



   foreach my $grp (values(%grps)){
      foreach my $chkgrp (@$group){
         return(1) if ($chkgrp=~m/^\d+$/ && $chkgrp==$grp->{grpid});
         return(1) if ($chkgrp eq $grp->{fullname});
      }
   }
   return(undef);
}





sub SkinBase
{
   my $self=shift;

   return($self->Module);
}

sub HttpHeader
{
   my ($self,$content,%param)=@_;
   my $d="";

   if ( !defined($param{'cache'}) || $param{'cache'} < 1){
      $d.=sprintf("Cache-Control: no-cache\n");
      $d.=sprintf("Cache-Control: no-store\n");
      $d.=sprintf("Cache-Control: max-age=1\n");
   }
   else{
      $d.=sprintf("Cache-Control: max-age=%d\n",$param{'cache'});
      $d.=sprintf("Expires: %s\n",HTTP::Date::time2str(time + $param{'cache'}));
   }
   #$d.=sprintf("Last-Modified: %s\n",HTTP::Date::time2str(time-1));
   my $disp;
   if (defined($param{'attachment'}) && $param{'attachment'}==1){
      $disp="attachment";
   }
   else{
      $disp="inline";
   }
   if (defined($param{'inline'}) && $param{'inline'}==1){
      $disp="inline";
   }
   if (defined($param{'cookies'})){
      my $c=$param{'cookies'};
      $c=[$c] if (ref($c) ne "ARRAY");
      foreach my $cc (@$c){
         $d.="Set-Cookie: ".$cc."\n";
      }
   }
   if (defined($param{'filename'})){
      my $f=$param{'filename'};
      $f=~s/^.*\\//g;
      $disp.="; " if ($disp ne "");
      $disp.="filename=\"$f\"";
      $d.="Content-Name: $f\n";
      $d.="Content-Disposition: $disp\n";   # seems to be needed for chrome
   }                                        # in attachment mode
   else{
      if ($disp ne "inline"){
         $d.="Content-Disposition: $disp\n";
      }
   }
   my $charset="";
   $charset=";charset=ISO-8895-1" if ($content eq "text/html" || 
                                      $content eq "text/plain");
   $charset=";charset=$param{charset}" if (defined($param{charset}));
   $d.=sprintf("Content-type: %s$charset\n\n",$content);
   #if ($param{'cache'}){
   #   msg(INFO,$d);
   #}
   return($d);
}

sub mobileMain
{
   my $self=shift;
   my $d="";

   $d.=$self->HttpHeader("text/html");
   $d.="this is mobile Main for $self";
   $d.=$self->HtmlBottom(body=>1,form=>1);
   print($d);
   return;
}

sub noAccess
{
   my $self=shift;
   my $extinfo=shift;
   my %param=@_;
   my $d;

   $d.=$self->HttpHeader("text/html");
   $d.=$self->HtmlHeader(style=>['default.css','work.css'],
                         body=>1,form=>1,
                         title=>"No Access to ".$self->Self);
   msg(ERROR,"user '%s' has been tried to access $self whitout access",
       $ENV{REMOTE_USER});
   $d.=$self->getParsedTemplate("tmpl/kernel.noaccess",
                                  { skinbase=>'base',
                                    static=>{extinfo=>$extinfo}});
   $d.=$self->HtmlBottom(body=>1,form=>1);
   return($d);
}

sub queryError
{
   my $self=shift;
   my $extinfo=shift;
   my %param=@_;
   my $d;

   $d.=$self->HttpHeader("text/html");
   $d.=$self->HtmlHeader(style=>['default.css','work.css'],
                         body=>1,form=>1,
                         title=>"No Access to ".$self->Self);
   $d.=$self->getParsedTemplate("tmpl/kernel.queryerror",
                                  { skinbase=>'base',
                                    static=>{extinfo=>$extinfo}});
   $d.=$self->HtmlBottom(body=>1,form=>1);
   return($d);
}

sub HtmlGoto
{
   my $self=shift;
   my $target=shift;
   my %param=@_;
   print $self->HttpHeader("text/html");
   print <<EOF;
<!DOCTYPE HTML>
<html>
<head><title>... redirecting ...</title></head>
<body onload=document.forms[0].submit()>
<form method=post action="$target">
EOF
   if (defined($param{post})){
      foreach my $k (%{$param{post}}){
         printf("<input type=hidden name=$k value=\"%s\">",$param{post}->{$k});
      }
   }
   print <<EOF;
</form></body></html>
EOF
}


sub HtmlHeader
{
  my ($self,%param)=@_;
  my $d="";
  my $lang=$self->Lang();
  my $altlang="en";
  $altlang="de" if ($lang eq "en");

  my $langtag="lang=\"$lang\" altlang=\"$altlang\"";


  $d.=<<EOF;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html $langtag>
<head>
<script type="text/javascript" language="JavaScript">
var CURLANG="$lang";
var ALTLANG="$altlang";
</script>
EOF

   #my $RootPath=Query->Param("RootPath");
   #if (defined($RootPath) && !defined($param{base})){
   #   $param{base}=$RootPath;
   #}
   if (defined($param{'style'})){
      my @style=$param{'style'};
      @style=@{$param{'style'}} if (ref($param{'style'}) eq "ARRAY");
      foreach my $style (@style){
         my $name=$style;
         $style="public/base/load/$style" if (!($style=~m/^public\//));
         $d.="<link rel=stylesheet type=\"text/css\" ".
             "href=\"$param{prefix}$param{base}../../../$style\">".
             "\n";
      }
   }
   if ($param{submodal}){
      $param{'js'}=[] if (!defined($param{'js'}));
      if (!grep(/^toolbox.js$/,@{$param{'js'}})){
         push(@{$param{'js'}},"toolbox.js");
      }
      if (!grep(/^subModal.js$/,@{$param{'js'}})){
         push(@{$param{'js'}},"subModal.js");
      }
   }
   
   if (defined($param{'js'})){
      my @js=$param{'js'};
      @js=@{$param{'js'}} if (ref($param{'js'}) eq "ARRAY");
      foreach my $js (@js){
         my $jsname="$js";
         if (!($jsname=~m/^(http|https):/)){
            $jsname="$param{prefix}$param{base}../../../public/base/load/$js";
         }
         $d.="<script language=\"JavaScript\"  ".
             "type=\"text/javascript\" src=\"$jsname\"></script>\n";
      }
   }
   $d.="<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />";
   if (defined($param{'shorticon'})){
      my $shorticon=$param{'shorticon'};
      $d.="<link rel=\"shortcut icon\" ".
          "href=\"$param{prefix}$param{base}../../../public/base/".
          "load/$shorticon\" type=\"image/x-icon\">\n";
      $d.="<link rel=\"icon\" ".
          "href=\"$param{prefix}$param{base}../../../public/base/".
          "load/$shorticon\" type=\"image/x-icon\">\n";
   }
   my $charset="ISO-8859-1";
   $charset=$param{charset} if (defined($param{charset}));
   $d.="<meta http-equiv=\"content-type\" ".
       "content=\"text/html; charset=$charset\">";
   if (defined($param{'title'})){
      $d.="\n<title>";
      $d.=$param{'title'};
      $d.="</title>\n";
   }
   $d.="\n<script language=\"JavaScript\" type=\"text/javascript\">\n";
   $d.="function DataLoseWarn(){\n";
   $d.="return(confirm(\"".
        $self->T("With this action, it is possible to lose data!").
       "\"));\n";
   $d.="}\n";
   $d.="function DataLoseQuestion(){\n";
   $d.="return(\"".
        $self->T("With this action, it is possible to lose data!").
       "\");\n";
   $d.="}\n";
   $d.="</script>\n\n";
   if (defined($param{'refresh'})){
      $d.="<meta http-equiv=\"refresh\" content=\"$param{'refresh'}\">";
   }
   if (defined($param{target}) || defined($param{base})){
      $d.="<base";
      $d.=" target=\"$param{target}\"" if ($param{target});
      $d.=" href=\"$param{base}\"" if ($param{base} && $param{base} ne "");
      $d.=">";
   }
   $d.="</head>\n";
   if ($param{body} || defined($param{onunload})){
      $d.="<body";
      if (defined($param{onload})){
         $d.=" OnLoad=\"$param{onload}\"" if ($param{onload} ne "");
      }
      if (defined($param{onunload})){
         $d.=" onUnload=\"$param{onunload}\"";
      }
      $d.=">";
   }
   if ($param{submodal}){
      $d.=$self->HtmlSubModalDiv();
   }

   if ($param{form}){
      my $enctype="";
      $enctype="enctype=\"multipart/form-data\"" if ($param{multipart});
      $d.="<form id=\"$param{form}\" method=\"post\" $enctype";
      $d.=" onSubmit=\"if (this.SubmitCheck){return(this.SubmitCheck());}else{return(true);}\"";
     # $d.=" onSubmit=\"if (SubmitCheck){return(SubmitCheck())}".
     #     "else{return(true)}\""; # scheint bei IE nicht zu tun
      if (exists($param{action})){
         $d.=" action=\"$param{action}\"";
      }
      if (exists($param{formtarget})){
         $d.=" target=\"$param{formtarget}\"";
      }
      $d.=">";
   }
#   $d.="<form method=\"post\">";
   return($d);
}

sub Wap
{
   my $self=shift;
   my $d=shift;
   my %param=@_;

   return('<?xml version="1.0"?>'."\n".
          '<!DOCTYPE wml PUBLIC "-//WAPFORUM//DTD WML 1.1//EN" '.
          '"http://www.wapforum.org/DTD/wml_1.1.xml">'."\n".
          "<wml><card id=\"1\"><form>\n".$d."</form></card></wml>\n");
}

sub HtmlReply
{
   my $self=shift;
   my $code=shift;
   my $msg=shift;
   my $d="";
   $d.="Status: $code\n";
   $d.="Content-Type: text/plain\n\n";
   $d.="ERROR: " if ($code ne "200");
   $d.=$code." ".$msg;
   return($d);
}

sub HtmlSubModalDiv
{
   my $self=shift;
   my %param=@_;
   my $docallback="false";
   $docallback="true" if ($param{docallback});
   my $d=<<EOF;
<div id="popupMask">&nbsp;</div>
<div id="popupContainer">
   <div id="popupInner" >
      <div id="TitleBar" class="TitleBar">
         <div id="popupTitle"></div>
         <div id="popupControls">
            <img src="$param{prefix}../../../public/base/load/subModClose.gif" 
                 onclick="hidePopWin(true,true);" />
         </div>
      </div>
      <div id=popupData style="visible:hidden;display:none"></div>
      <iframe src="$param{prefix}../../../public/base/msg/loading" 
              style="background-color:transparent;width:100%" 
              scrolling="auto" 
              frameborder="0" allowtransparency="true" 
              class=popupFrame 
              id="popupFrame" name="popupFrame" ></iframe>
   </div>
</div>
EOF
   return($d);
}

sub HtmlBottom
{
   my ($self,%param)=@_;
   my $d="";

   $d.="</form>" if ($param{form});
   $d.="</body>" if ($param{body});
   $d.="</html>";
   return($d);
}

sub HtmlFrameset
{
   my $self=shift;
   my $param={};
   $param=shift if (ref($_[0]) eq "HASH");
   my $d="<frameset";
   $d.=sprintf(" border=\"%d\"",$param->{border});
   $d.=" rows=\"$param->{rows}\"" if (exists($param->{rows}));
   $d.=" cols=\"$param->{cols}\"" if (exists($param->{cols}));
   $d.=">".join("",@_)."</frameset>";
   return($d);
}

sub HtmlPersistentVariables
{
   my $self=shift;
   my @list=@_;
   @list=Query->Param() if ($#list==0 && $list[0] eq "ALL");
   my $d="\n<!------- HtmlPersistentVariables ------------->\n";
   foreach my $var (@list){
      my @val=Query->Param($var);
      @val=("") if ($#val==-1);
      foreach my $val (@val){
         $val=~s/"/&quot;/g;
         $d.="<input type=hidden name=$var id=$var value=\"$val\">\n";
      }
   }
   $d.="<!--------------------------------------------->\n";
   return($d);
}

sub HtmlFrame
{
   my $self=shift;
   my $param={};
   $param=shift if (ref($_[0]) eq "HASH");
   my $src=shift;
   my $name=shift;
   my $d="<frame";
   $name=$src if ($name eq "");
   $d.=" src=\"$src\"" if (defined($src)); 
   $d.=" name=\"$name\"" if (defined($name)); 
   $d.=" scrolling=\"$param->{scrolling}\"" if (exists($param->{scrolling})); 
   return($d.">");
}


sub findtemplvar
{
   my $self=shift;
   my ($opt,$var,@param)=@_;

   sub AddButton
   {
      my $d=shift;
      my $href=shift;
      my $text=shift;
      my $class=shift;
       
      $class="button" if (!defined($class));
      $$d.="<input class=$class type=button value=\"".$self->T($text)."\"".
           "onclick=\"$href;\">";
   }
   if ($var eq "LASTMSG"){
      my $d="";
      $d.="<div class=lastmsg>" if ($param[0] ne "RAW");
      if ($self->LastMsg()){
         $d.=join("<br>\n",map({
                            if ($_=~m/^ERROR/){
                               $_="<font style=\"color:red;\">".$_.
                                  "</font>";
                            }
                            if ($_=~m/^WARN/){
                               $_="<font style=\"color:#F67E59;\">".$_.
                                  "</font>";
                            }
                            if ($_=~m/^OK/){
                               $_="<font style=\"color:darkgreen;\">".$_.
                                  "</font>";
                            }
                            $_;
                           } $self->LastMsg()));
      }
      $d.="&nbsp;</div>" if ($param[0] ne "RAW");
      return($d);
   }
   elsif ($var eq "SUPPORTINFO"){
      my $u=getModuleObject($self->Config,"base::user");
      my $d="";
      my $mode="html";
      $mode="html" if (in_array(\@param,"html"));
      $mode="text" if (in_array(\@param,"text"));
      if (defined($u)){
         $u->SetFilter({cistatusid=>\'4',isw5support=>\'1'});
         my ($urec)=$u->getOnlyFirst(qw(email office_phone));
         if (defined($urec)){
            if ($urec->{email} ne ""){
               if ($mode eq "html"){
                  $d.="Support: <a href=\"mailto:$urec->{email}\" ".
                      "class=supportinfo>$urec->{email}</a>";
               }
               if ($mode eq "text"){
                  $d.="Mail: $urec->{email} ";
               }
            }
            $d.="&nbsp;&nbsp;" if ($d ne "" && $mode eq "html");
            $d.="  " if ($d ne "" && $mode eq "text");
            if ($urec->{office_phone} ne ""){
               if ($mode eq "html"){
                  $d.="1st Level Support Phone: <a  class=supportinfo ".
                      "href=\"callto:$urec->{office_phone}\">".
                      "$urec->{office_phone}</a>";
               }
               if ($mode eq "text"){
                  $d.="Phone: ".
                      "$urec->{office_phone}";
               }
            }
            $d.="&nbsp;&nbsp;" if ($d ne "" && $mode eq "html");
            $d.="  " if ($d ne "" && $mode eq "text");
         }
      }
      return($d);
   }
   elsif ($var eq "GLOBALHELP"){
      my $tags=$param[0];
      my $searchtext=$param[1];
      my $url=$param[2];
      my $icon=$param[3];
      if ($icon eq ""){
         $icon="../../../public/base/load/help.gif";
      }
      if ($url eq ""){
         $url="../../faq/QuickFind/globalHelp";
      }
      $tags=~s/ /,/g;
      my %param;
      $param{'searchtext'}=$searchtext if ($searchtext ne "");
      $param{'stags'}=$tags if ($tags ne "");
      if ($param{'searchtext'} ne ""){
         $param{'AutoSearch'}=1;
      }
      my $qs=kernel::cgi::Hash2QueryString(%param);

      my $onclick="openwin('$url?$qs','_help',".
                  "'height=570,width=680,toolbar=no,status=no,".
                  "resizable=yes,scrollbars=auto');return(false);";
      return("<a href=\"http://find.telekom.de\" ".
             "class=sublink onclick=\"$onclick\" ".
             "title=\"globalHelp\" alt=\"globalHelp\">".
             "<img border=0 alt=\"Help Icon\" src=\"$icon\"></a>");
   }
   elsif ($var eq "StdButtonBar"){
      my $d="<div class=buttonframe>";
      $d.="<table class=buttonframe><tr>";
      $d.="<td width=1% valign=top>";
      $d.="</td>";
      $d.="<td valign=center>";
      { # for sublist edit template parsing
         my $id=Query->Param("CurrentIdToEdit");
         if ($id eq ""){
            if (grep(/^subadd$/,@param)){
               AddButton(\$d,"DoSubListEditAdd()","Add");
            }
         }
         else{
            if (grep(/^subsave$/,@param)){
               AddButton(\$d,"DoSubListEditSave()","Save");
            }
            if (grep(/^subdelete$/,@param)){
               AddButton(\$d,"DoSubListEditDelete()","Delete");
            }
            if (grep(/^subcancel$/,@param)){
               AddButton(\$d,"DoSubListEditCancel()","Cancel");
            }
         }
      }
      if (grep(/^search$/,@param)){
         AddButton(\$d,"DoSearch()","Search");
      }
      if (grep(/^analytic$/,@param)){
         if ($self->can("getAnalytics")){
            my @l=$self->getAnalytics();
            while(my $f=shift(@l)){
               my $n=shift(@l);
               AddButton(\$d,"DoAnalytic('$f')",$n);
            }
         }
      }
      if (grep(/^save$/,@param)){
         AddButton(\$d,"DoSave()","Save");
      }
      if (grep(/^preview$/,@param)){
         AddButton(\$d,"DoPreview()","Preview");
      }
      if (grep(/^delete$/,@param)){
         AddButton(\$d,"DoDelete()","Delete");
      }
      if (grep(/^extended$/,@param)){
         AddButton(\$d,"SwitchExt()","Extended");
      }
      if (grep(/^bookmark$/,@param)){
         if ($self->Config->Param("W5BaseOperationMode") ne "readonly"){
            AddButton(\$d,"DoBookmark()","Bookmark");
         }
      }
      if (grep(/^print$/,@param)){
         AddButton(\$d,"DoPrint()","Print");
      }
      if (grep(/^reset$/,@param)){
         my $msg=$self->T("This operation clears all fields in the ".
                          "searchmask.\\n Click cancel, if you don't ".
                          "want to do this.");
         $msg=~s/'/\\'/g;
         AddButton(\$d,"DoResetMask('$msg')","Reset Search");
      }
      if (grep(/^upload$/,@param)){
         if ($self->Config->Param("W5BaseOperationMode") ne "readonly"){
            if ($self->can("isUploadValid") && $self->isUploadValid()){
               if ($self->IsMemberOf(["admin","uploader"])){
                  AddButton(\$d,"DoUpload()","Upload");
               }
            }
         }
      }
      if (grep(/^new$/,@param)){
         AddButton(\$d,"DoNewWin()","New");
      }
      if (grep(/^deputycontrol$/,@param) ||
          grep(/^teamviewcontrol$/,@param) ||
          grep(/^exviewcontrol$/,@param)){
         my $oldval=Query->Param("EXVIEWCONTROL");
         $d.="<select name=EXVIEWCONTROL>";
         if (grep(/^exviewcontrol$/,@param)||
             grep(/^teamviewcontrol$/,@param)){
            $d.="<option value=\"\" ".
                ">&lt; ".$self->T("select dataview")." &gt;</option>";
         }
         else{
            $d.="<option value=\"\" ".
                ">&lt; ".$self->T("select deputy control")." &gt;</option>";
         }
         if (grep(/^deputycontrol$/,@param)){
            $d.="<option value=\"ADDDEP\"";
            $d.=" selected" if ($oldval eq "ADDDEP");
            $d.=">".$self->T('include deputy data')."</option>";
            $d.="<option value=\"DEPONLY\"";
            $d.=" selected" if ($oldval eq "DEPONLY");
            $d.=">".$self->T('list only records as deputy')."</option>";
         }
         if (grep(/^exviewcontrol$/,@param)){
            $d.="<option value=\"CUSTOMER\"";
            $d.=" selected" if ($oldval eq "CUSTOMER");
            $d.=">".$self->T('list records for me as customer')."</option>";
         }
         if (grep(/^teamviewcontrol$/,@param)){
            $d.="<option value=\"TEAM\"";
            $d.=" selected" if ($oldval eq "TEAM");
            $d.=">".$self->T('list records of my organisational area').
                "</option>";
         }
         if (grep(/^teamusercontrol$/,@param)){
            my $userid=$self->getCurrentUserId(); 
            my %g=$self->getGroupsOf($userid, [orgRoles()], 'direct');
            my $u=getModuleObject($self->Config,"base::lnkgrpuser");
            $u->SetFilter({grpid=>[keys(%g)],usertyp=>\'user'});
            my %u;
            foreach my $rec ($u->getHashList(qw(user userid))){
               my $uname=$rec->{user};
               $uname=~s/\s*\(.*\)$//;
               $u{$uname}=$rec->{userid};
            }
            foreach my $u (sort(keys(%u))){
               $d.="<option value=\"COLLEGE:$u{$u}\"";
               $d.=" selected" if ($oldval eq "COLLEGE:$u{$u}");
               $d.=">".$self->T('Colleague').": ".$u.
                   "</option>";
            }
         }
         $d.="</select>";
      }
      $d.="</td>";
      $d.="</tr></table>";
      $d.="</div>";
      return($d);
   }
   elsif ($self->can("DataObj_findtemplvar")){
      my $res=$self->DataObj_findtemplvar(@_);
      return($res) if (defined($res));
   }
   my $qvar=quotemeta($var);
   if (grep(/^$qvar$/,Query->Param())){
      return(Query->Param($var));
   }
   #return("unknown-vari:$var");
   return($self->SUPER::findtemplvar(@_));
}


sub InitWorkflow
{
   my $self=shift;

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css'],
                           body=>1,form=>1,
                           title=>'W5BaseV1-System');
   my $wfname=Query->Param("WorkflowName");
   if (defined($self->{Operator}->{$wfname})){
      print("call InitWorkflow<br>");
      $self->{Operator}->{$wfname}->InitWorkflow();
      print("<br>");
      print("<input type=submit>");
   }
   else{
      print("Unknown Workflow<br>");
   }
   #print $self->HtmlPersistentVariables(qw(WorkflowClass));
   print $self->HtmlBottom(body=>1,form=>1);

}


######################################################################

1;