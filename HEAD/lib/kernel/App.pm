package kernel::App;
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
use kernel::date;
use kernel::TemplateParsing;
use XML::Smart;
use IO::File;
use kernel::Universal;
@ISA    = qw(kernel::Universal kernel::TemplateParsing);

sub new
{
   my $type=shift;
   my $self={@_};
   $self=bless($self,$type);

   return($self);
}
######################################################################
sub DataObj
{
   $_[0]->{DataObj}={} if (!defined($_[0]->{DataObj}));
   return($_[0]->{DataObj}->{$_[1]}) if (defined($_[1]));
   return($_[0]->{DataObj});
}



sub Module
{
   my $self=shift;
   return($self->{OrigModule}) if (exists($self->{OrigModule}));
   my $s=$self->Self();
   my ($module,$app)=$s=~m/^(.*)::(.*)$/;
   return($module);
}

sub App
{
   my $self=shift;
   my $s=$self->Self();
   my ($module,$app)=$s=~m/^(.*)::(.*)$/;
   return($app);
}

sub Config
{
   my ($self)=@_;

   return($self->{'Config'});
}

sub getPersistentModuleObject
{
   my $self=shift;
   my $label=shift;
   my $module=shift;

   $module=$label if (!defined($module) || $module eq "");
   if (!defined($self->{$label})){
      my $m=$self->ModuleObject($module);
      $self->{$label}=$m
   }
   if (defined($self->{$label})){
      $self->{$label}->ResetFilter();
   }
   return($self->{$label});
}

sub ModuleObject
{
   my $self=shift;
   my $name=shift;
   my $config=$self->Config;
   my $o=getModuleObject($config,$name);
   if (defined($o)){
      $o->setParent($self);
   }
   return($o);
}


sub W5ServerCall
{
   my $self=shift;
   my $method=shift;
   my @param=@_;

   if (!defined($self->Cache->{W5Server})){
      msg(ERROR,"no W5Server connection for call '%s'",$method);
      return(undef);
   }
   my $bk=$self->Cache->{W5Server}->Call($method,@param);
   return($bk);
}

sub W5ServerCallGetUniqueIdCached
{
   my $self=shift;

#
#  ToDo - Cached UniqeIDs generieren
#

#   my $res=$self->W5ServerCall("rpcGetUniqueId");
#   return($res) if (!defined($res));
#   my $retry=15;
#   while(!defined($res=$self->W5ServerCall("rpcGetUniqueId"))){
#      sleep(1);
#      last if ($retry--<=0);
#      msg(WARN,"W5Server problem for user $ENV{REMOTE_USER} ($retry)");
#   }
#   if (defined($res) && $res->{exitcode}==0){
#      $id=$res->{id};
#   }
#
#   my $bk=$self->Cache->{W5Server}->Call($method,@param);

}

sub getCurrentAclModes      # extracts the current acl 
{                           # (contrib to kernel::App::Web::AclControl)
   my $self=shift;
   my $useraccount=shift;
   my $acllist=shift;
   my $roles=shift;
   my $direction=shift;
   return(undef) if (ref($acllist) ne "ARRAY");
   
   my $userid;
   my $UserCache=$self->Cache->{User}->{Cache};
   if (defined($UserCache->{$useraccount})){
      $UserCache=$UserCache->{$useraccount}->{rec};
   }
   if (defined($UserCache->{tz})){
      $userid=$UserCache->{userid};
   }
   $direction="both" if (!defined($direction));
   my %grps=$self->getGroupsOf($useraccount,$roles,$direction);
   my %u=();
   foreach my $rec (@{$acllist}){
      if (defined($rec->{acltarget})){
         if ($rec->{acltarget} eq "base::user" &&
             $rec->{acltargetid} eq $userid){
            $u{$rec->{aclmode}}=1;
         } 
         if ($rec->{acltarget} eq "base::grp" &&
             grep(/^$rec->{acltargetid}$/,keys(%grps))){
            $u{$rec->{aclmode}}=1;
         } 
      } 
      if (defined($rec->{target})){  # to be compatible to contact object
         my $match=0;
         if ($rec->{target} eq "base::user" &&
             $rec->{targetid} eq $userid){
            $match=1;
         } 
         if ($rec->{target} eq "base::grp" &&
             grep(/^$rec->{targetid}$/,keys(%grps))){
            $match=1;
         } 
         if ($match && ref($rec->{roles}) eq "ARRAY"){
            foreach my $role (@{$rec->{roles}}){
               $u{$role}=1;
            }
         }
      } 
   }
   return(keys(%u));
}

sub ReadMimeTypes
{
   my $self=shift;
   my $mime=$self->Config->Param("MIMETYPES");

   if (!exists($self->{MimeType})){
      $self->{MimeType}={'msi'=>"Windows Installer Package"};
      if (open(F,"<$mime")){
         while(my $l=<F>){
            $l=~s/\s$//;
            next if ($l=~m/^\s*#.*$/);
            if (my ($t,$e)=$l=~m/^\s*(\S+)\s+(.+)$/){
               my @elist=split(/\s+/,$e);
               foreach my $e (@elist){
                  $self->{MimeType}->{$e}=$t;
               }
            }
         }
         close(F);
      }
      else{
         msg(ERROR,"can't open '$mime'");
      }
   }
}



sub getMandatorsOf
{
   my $self=shift;
   my $AccountOrUserID=shift;
   my @roles=@_;
   @roles=@{$roles[0]} if (ref($roles[0]) eq "ARRAY");
   my $userid;
   my $UserCache=$self->Cache->{User}->{Cache};
   if (defined($UserCache->{$AccountOrUserID})){
      $UserCache=$UserCache->{$AccountOrUserID}->{rec};
   }
   if (defined($UserCache->{userid})){
      $userid=$UserCache->{userid};
   }
   my %groups=$self->getGroupsOf($AccountOrUserID,
                                 [qw(REmployee 
                                     RBoss RBoss2 
                                     RMember RCFManager)],
                                 'both');
   my @grps=keys(%groups);
   my %m=();
  # my %m=map({($_=>1);}@grps);
   my $MandatorCache=$self->Cache->{Mandator}->{Cache};
   CHK: foreach my $mid (keys(%{$MandatorCache->{id}})){
      my $mc=$MandatorCache->{id}->{$mid};
      my $grpid=$mc->{grpid};
      $m{$grpid}=1 if (grep(/^$grpid$/,@grps));
      if (defined($mc->{contacts}) && ref($mc->{contacts}) eq "ARRAY"){
         foreach my $contact (@{$mc->{contacts}}){
            if ($contact->{target} eq "base::user"){
               next if ($contact->{targetid}!=$userid);
               my $mr=$contact->{roles};
               $mr=[$mr] if (ref($mr) ne "ARRAY");
               foreach my $chk (@roles){
                  if (grep(/^$chk$/,@{$mr})){
                     $m{$grpid}=1;
                     next CHK;
                  }
               }
            }
            if ($contact->{target} eq "base::grp"){
               my $g=$contact->{targetid};
               next if (!grep(/^$g$/,@grps));
               my $mr=$contact->{roles};
               $mr=[$mr] if (ref($mr) ne "ARRAY");
               foreach my $chk (@roles){
                  if (grep(/^$chk$/,@{$mr})){
                     $m{$grpid}=1;
                     next CHK;
                  }
               }
            }
         }
      }
   }

   return(keys(%m));
}

sub isMandatorReadable
{
   my $self=shift;
   my $mandatorid=shift;
   return(0) if ($mandatorid==0);
   my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
   if (!in_array(\@mandators,[$mandatorid])){
      return(0);
   }
   return(1);
}


sub getMembersOf
{
   my $self=shift;
   my $group=shift;
   my $roles=shift;
   my $direction=shift;
   $direction="down" if (!defined($direction));
   $group=[$group]      if (ref($group) ne "ARRAY");
   $roles=["RMember"]   if (!defined($roles));
   my %allgrp;
   my %userids;

   foreach my $directgrp (@$group){
      $self->LoadGroups(\%allgrp,$direction,$directgrp);
   }
   my $rolelink=$self->getPersistentModuleObject("getMembersOf",
                                                "base::lnkgrpuserrole");
   my @grpids=keys(%allgrp);
   $rolelink->SetFilter({grpid=>\@grpids,role=>$roles,
                         expiration=>">now OR [LEER]",    #to handle expiration
                         cistatusid=>[3,4]});
   map({$userids{$_->{userid}}++;} $rolelink->getHashList(qw(userid)));

   return(keys(%userids));
}


sub LoadGroups
{
   my $self=shift;
   my $allgrp=shift;
   my $direction=shift;
   my @grpids=@_;
   my $GroupCache=$self->Cache->{Group}->{Cache};

   foreach my $grp (@grpids){
      next if (!defined($grp));
      if (!defined($allgrp->{$grp})){
         $allgrp->{$grp}={
               fullname=>$GroupCache->{grpid}->{$grp}->{fullname},
               grpid=>$grp,
         };
         if ($direction eq "down" || $direction eq "both"){
            $self->LoadGroups($allgrp,$direction,
                       @{$GroupCache->{grpid}->{$grp}->{subid}});
         }
         if ($direction eq "up" || $direction eq "both"){
            $self->LoadGroups($allgrp,"up",
                       $GroupCache->{grpid}->{$grp}->{parentid});
         }
      }
   }
}

sub _LoadUserInUserCache
{
   my $self=shift;
   my $AccountOrUserID=shift;
   my $res=shift;              # result of rpcCacheQuery in Web Context

   return(0) if ($AccountOrUserID eq "");
   my $o=$self->Cache->{User}->{DataObj};
   if (!defined($o)){     # DataObj also filled in App/Web.pm !
      $o=$self->ModuleObject("base::user");
      $self->Cache->{User}={DataObj=>$o,Cache=>{}};
   }
   my $UserCache=$self->Cache->{User}->{Cache};
   if ($o){
         $o->SetCurrentView(qw(surname userid givenname posix groups tz lang
                               cistatusid secstate 
                               dialermode dialerurl dialeripref
                               email usersubst usertyp fullname));
         if ($AccountOrUserID=~m/^\d+$/){
            $o->SetFilter({userid=>\$AccountOrUserID});
         }
         else{
            $o->SetFilter({'accounts'=>[$AccountOrUserID]});
         }
         my ($rec,$msg)=$o->getFirst();
         if (defined($rec)){
            $UserCache->{$AccountOrUserID}->{rec}=$rec;
            if (defined($res)){   # only in Web-Context the state is stored
               $UserCache->{$AccountOrUserID}->{state}=$res->{state};
            }
            $UserCache->{$AccountOrUserID}->{atime}=time();
            if ($AccountOrUserID ne $rec->{userid}){
               $UserCache->{$rec->{userid}}=$UserCache->{$ENV{REMOTE_USER}};
            }
            return(1);
         }
   }
   return(0);
}

sub getInitiatorGroupsOf
{
   my $self=shift;
   my $AccountOrUserID=shift;

   my %groups=$self->getGroupsOf($AccountOrUserID,
                  [qw(REmployee RBoss RBackoffice RBoss2)],'direct');
   my $now=NowStamp("en");
   my %age;
   foreach my $grpid (keys(%groups)){
      my $cdate=$groups{$grpid}->{'cdate'};
      my $a=99999999999999;
      if ($cdate ne ""){
         if (my $duration=CalcDateDuration($cdate,$now,"GMT")){ 
            $a=$duration->{totalseconds};
            
         }
      }
      $age{$grpid}=$a;
   }
   my @grplist;
   foreach my $grpid (sort({$age{$a} <=> $age{$b}} keys(%groups))){
      push(@grplist,$grpid);
      push(@grplist,$groups{$grpid}->{fullname});
   }
   return(@grplist) if (wantarray());
   return($grplist[1]);
}


sub getGroupsOf
{
   my $self=shift;
   my $AccountOrUserID=shift;
   my $roles=shift;      # internel names of roles         (undef=RMember)
   my $direction=shift;  # up | down | both | direct       (undef=direct)

   $roles=["RMember"]   if (!defined($roles));
   $roles=[$roles]      if (ref($roles) ne "ARRAY");
   $direction="direct"  if (!defined($direction));

   my @directgroups=();
   my %allgrp=();

   my $UserCache=$self->Cache->{User}->{Cache};

   if (!defined($UserCache->{$AccountOrUserID})){
      $self->_LoadUserInUserCache($AccountOrUserID);
   }
   my %directgroupage;
   if (defined($UserCache->{$AccountOrUserID})){
      $UserCache=$UserCache->{$AccountOrUserID}->{rec};
      if (defined($UserCache->{groups}) && 
          ref($UserCache->{groups}) eq "ARRAY"){
         foreach my $role (@{$roles}){
            push(@directgroups,map({
                                    $directgroupage{$_->{grpid}}=$_->{cdate};
                                    $_->{grpid};
                                   } 
                                   grep({
                                          if (!defined($_->{roles})){
                                             $_->{roles}=[];
                                          }
                                          grep(/^$role$/,@{$_->{roles}});
                                        } 
                                        @{$UserCache->{groups}})));
         }
      }
   }
   foreach my $directgrp (@directgroups){
      $self->LoadGroups(\%allgrp,$direction,$directgrp);
   }
   #
   # Handle virtuell groups "anonymous" and "valid_user"
   #
   if (grep(/^RMember$/,@{$roles})){
      if ($ENV{REMOTE_USER} ne "anonymous" &&
          $ENV{REMOTE_USER} ne ""){
         $allgrp{-1}={name=>'valid_user',
                      fullname=>'valid_user',
                      grpid=>-1,
                      roles=>['RMember']
                     };
      }
      else{
         $allgrp{-2}={name=>'anonymous',
                      fullname=>'anonymous',
                      grpid=>-2,
                      roles=>['RMember']
                     };
      }
      my $ma=$self->Config->Param("MASTERADMIN");
      if ($ma ne "" && $ENV{REMOTE_USER} eq $ma){
         $allgrp{1}={name=>'admin',
                     fullname=>'admin',
                     grpid=>1,
                     roles=>['RMember']
                    };
      }
   }
   if ($direction eq "direct"){  # store age of relation for later use
      foreach my $directgrpid (keys(%directgroupage)){
         $allgrp{$directgrpid}->{cdate}=$directgroupage{$directgrpid};
      }
   }

   return(%allgrp);
}


sub ValidateGroupCache
{
   my $self=shift;
   my $multistate=shift;


   if (defined($self->Cache->{Group}->{state})){
      my $res={state=>$multistate};
      if (!defined($res->{state})){
         $res=$self->W5ServerCall("rpcCacheQuery","Group");
      }
      if (!defined($res)){
         msg(INFO,"W5ServerCall failed - cache for cwGroup cleared");
         delete($self->Cache->{Group});
      }
      elsif ($self->Cache->{Group}->{state} ne $res->{state}){
         msg(INFO,"cache for Group is invalid - ".
                  "cleared state='%s' rpcstate='%s'",
                  $self->Cache->{Group}->{state},
                  $res->{state});
         delete($self->Cache->{Group});
      }
      if (defined($self->Cache->{Group})){
         $self->Cache->{Group}->{atime}=time();
      }
   }
   if (!defined($self->Cache->{Group}->{Cache})){
      my $grp=$self->ModuleObject("base::grp");
      $grp->SetFilter({grpid=>'>-999999999'}); # prefend slow query entry
      $grp->SetCurrentView(qw(grpid fullname parentid subid));
      $grp->SetCurrentOrder("NONE");
      $self->Cache->{Group}->{Cache}=$grp->getHashIndexed(qw(grpid fullname));
      foreach my $grp (values(%{$self->Cache->{Group}->{Cache}->{grpid}})){
         if (!defined($grp->{subid})){
            $grp->{subid}=[];
         }
         if (defined($grp->{parentid})){
            my $p=$self->Cache->{Group}->{Cache}->{grpid}->{$grp->{parentid}};
            if (!defined($p->{subid})){
               $p->{subid}=[$grp->{grpid}];
            }
            else{
               push(@{$p->{subid}},$grp->{grpid});
            }
         }
      }
      my $res=$self->W5ServerCall("rpcCacheQuery","Group");
      if (defined($res)){
         $self->Cache->{Group}->{state}=$res->{state};
      }
   }
   return(1);
}


sub getTemplate
{
   my $self=shift;
   my $name=shift;
   my $skinbase=shift;
   my $mask;
   my $maskfound=0;
   my $filename;

   if (!($name=~m/\.js$/)){
      $skinbase=$self->SkinBase() if (!defined($skinbase));
      $name=$skinbase."/".$name;
    
      $filename=$self->getSkinFile($name);
   }
   else{
      my $instdir=$self->Config->Param("INSTDIR");
      $filename=$instdir."/lib/javascript/".$name;
   }

   if ( -r $filename ){
      if (open(F,"<$filename")){
         $maskfound=1;
         $mask=join('',<F>);
         close(F);
      }
   }
   if (!$maskfound){
      return(undef);
   }
   return($mask);
}

sub getParsedTemplate
{
   my $self=shift;
   my $name=shift;
   my $opt=shift;
   my $skinbase=$opt->{skinbase};
   my $mask=$self->getTemplate($name,$skinbase);
   if (defined($mask)){
      $self->ParseTemplateVars(\$mask,$opt);
   }
   else{
      $mask="<center><table bgcolor=red cellspacing=5 cellpadding=5>".
            "<tr><td><font face=\"Arial,Helvetica\">".
            "Template File '$name' not found<br>".
            "SKINDIR='".$self->getSkinDir()."'<br>".
            "SKIN='".join(": ",$self->getSkin())."'<br>".
            "</font></td></tr>".
            "</table></center>";
   }
   return($mask);
}

sub getDataObj
{
   my $self=shift;
   my $package=shift;
   my %modparam=();
   my $o;

   $modparam{'Config'}=$self->Config();
   eval("use $package;\$o=new $package(\%modparam);");
   if ($@ ne ""){
      msg(ERROR,"getDataObj: can't create '$package'");
      print STDERR $@;
      return(undef); 
   }
   $o->setParent($self);
   return($o);
}

sub getInstalledDataObjNames
{
   my $self=shift;
   my @names;

   my $instdir=$self->Config->Param("INSTDIR");
   @names=(glob($instdir."/mod/*/*.pm"),glob($instdir."/mod/*/workflow/*.pm"));
   map({$_=~s/^.*\/mod\///;
        $_=~s/\.pm$//;
        $_=~s/\//::/g;
        $_;} @names);

}

sub LoadTranslation
{
   my $self=shift;
   my $caller=shift;
   my $nodefaulttranslation=shift;
   my @calltag;
   my $tr={};

   if ($caller=~m/^kernel::/){
      if ($nodefaulttranslation){
         @calltag=("base/lang/$caller");
      }
      else{
         @calltag=("base/lang/translation","base/lang/$caller");
      }
   }
   else{
      my ($mod)=$caller=~m/^(\S+?)::/;
      if ($nodefaulttranslation){
         @calltag=("$mod/lang/$caller");
      }
      else{
         @calltag=("base/lang/translation","$mod/lang/translation",
                   "$mod/lang/$caller");
      }
   }
   foreach my $calltag (@calltag){
      $calltag=~s/::/./g;
      my $filename=$self->getSkinFile($calltag);
      if (defined($filename) && -r $filename){
         my $transcode="";
         if (open(F,"<$filename")){
            $transcode=join("",<F>);
            close(F);
         }
         my $trcode={};
         eval("\$trcode={$transcode};");
         msg(ERROR,"can't load transtable $filename\n%s",$@) if ($@ ne "");
         foreach my $key (keys(%{$trcode})){
            next if (ref($trcode->{$key}) ne "HASH");
            foreach my $lang (LangTable()){
               if (defined($trcode->{$key}->{$lang})){
                  $tr->{$lang}->{$key}=$trcode->{$key}->{$lang};
               }
            }
         }
      }
   }
   return($tr);
}


sub getSkinDir
{
   my $self=shift;

   my $skindir=$self->Config->Param('SKINDIR');
   if ($skindir eq ""){
      $skindir=$self->Config->Param("INSTDIR")."/skin";
   }
   return($skindir);
}


sub getSkin
{
   my $self=shift;
   my $lang=$self->Lang();

   my @skin=split(/:/,$self->Config->Param('SKIN'));
   $skin[0]="default"                  if ($skin[0] eq "");
   push(@skin,"default")               if (!grep(/^default$/,@skin));
   @skin=map({($_.".".$lang,$_)} @skin);
   return(@skin);
}

sub LowLevelLang
{
   my $self=shift;

   my @languages=LangTable();
   if (defined($ENV{HTTP_ACCEPT_LANGUAGE})){
      my %l;
      my $defq=1.0;
      my $lang;
      map({my ($q)=$_=~m/q=([\d\.]+)/;
                 if (!defined($q)){
                    $q=$defq;
                    $defq=$defq-0.1;
                 }
                 $_=~s/[;]{0,1}q=[\d\.]+[;]{0,1}//;
                 $l{$q}=$_;
                } split(/,/,$ENV{HTTP_ACCEPT_LANGUAGE}));
      foreach my $q (sort({$b<=>$a} keys(%l))){
         if (grep(/^$l{$q}$/,@languages)){
            $lang=$l{$q};
            last;
         }
         my $chk=$l{$q};
         $chk=~s/-.*$//;
         if (grep(/^$chk$/,@languages)){
            $lang=$chk;
            last;
         }
      }
      return($languages[0]) if (!defined($lang));
      return($lang);
   }
   my $envlang=lc($ENV{LANG});
   $envlang=~s/_.*$//;
   if (grep(/^$envlang$/,@languages)){
      return($envlang);
   }
   return("en") if ($ENV{LANG} eq "C");
   return(undef);
}

sub UserTimezone
{
   my $self=shift;

   my $utimezone="GMT";
   my $UserCache=$self->Cache->{User}->{Cache};
   if ($ENV{REMOTE_USER} ne ""){
      if (defined($UserCache->{$ENV{REMOTE_USER}})){
         $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
      }
      if (defined($UserCache->{tz})){
         $utimezone=$UserCache->{tz};
      }
   }
   return($utimezone);
}

sub Log
{
   my $self=shift;
   my $mode=shift;
   my $facility=lc(shift);
   return(undef) if ($facility eq "" || length($facility)>20);
   my $Cache=$self->Cache;
   if (!exists($Cache->{LogCache})){
      $Cache->{LogCache}={}; 
   }
   my $LogCache=$Cache->{LogCache};
   if (!exists($LogCache->{$facility})){
      $LogCache->{$facility}={};
      my @logfac=split(/\s*[,;]\s*/,lc($self->Config->Param("Logging")));
      if (grep(/^\+{0,1}$facility$/,@logfac)){
         my $target=$self->Config->Param("LogTarget");
         if ($target=~m/^\//){ # file logging
            $target=~s/\%f/$facility/g;
            my $oldumask=umask(0000);
            my $fh=new IO::File();
            if (! -f $target){
               msg(INFO,"try to create logfile '$target'");
               if ($fh->open(">$target")){
                  $fh->autoflush();
                  $LogCache->{$facility}->{file}=$target; 
                  $LogCache->{$facility}->{fh}=$fh; 
                  $fh->close();
               }
            }
            else{
               msg(INFO,"reopen logfile '$target'");
               if ($fh->open(">>$target")){
                  $fh->autoflush();
                  $LogCache->{$facility}->{file}=$target; 
                  $LogCache->{$facility}->{fh}=$fh; 
               }
            }
            if (! defined($LogCache->{$facility}->{fh})){
               msg(WARN,"fail to open logfile '$target' - $!");
            }
            umask($oldumask);
         }
      }
      else{
         if (!grep(/^-{0,1}$facility$/,@logfac)){
            $LogCache->{$facility}->{usemsg}=1; 
         }
      }
   }
   if (defined($LogCache->{$facility})){
      if (defined($LogCache->{$facility}) &&
          exists($LogCache->{$facility}->{usemsg})){
         msg($mode,@_);
      }
      if (defined($LogCache->{$facility}->{fh})){
         if (! -f $LogCache->{$facility}->{file}){
            close($LogCache->{$facility}->{fh});
            delete($LogCache->{$facility});
            msg(INFO,"logs close for facility '$facility'");
         }
         else{
            my $fout=*{$LogCache->{$facility}->{fh}};
            my $fout=$LogCache->{$facility}->{fh};
            my $txt=shift;
            if ($txt=~m/\%/ && $#_!=-1){
               $txt=sprintf($txt,@_);
            }
            $!=undef;
            foreach my $l (split(/[\r\n]+/,$txt)){
               print $fout (sprintf("%s [%d] %-6s %s\n",
                                    NowStamp(),$$,$mode,$l));
            }
#msg(DEBUG,"log done pid=$$ for $facility errno=$? $! fout=$fout");
            return(1);
         }
      }
   }
   return(undef);
}


sub Lang
{
   my $self=shift;

   if (defined($ENV{HTTP_FORCE_LANGUAGE})){
      return($ENV{HTTP_FORCE_LANGUAGE});
   }
   my @languages=LangTable();
   my $UserCache=$self->Cache->{User}->{Cache};
   if (defined($UserCache->{$ENV{REMOTE_USER}})){
      $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
   }
   
   if (defined($UserCache->{lang}) && grep(/^$UserCache->{lang}$/,@languages)){
      return($UserCache->{lang});
   }
   if (my $lowlang=$self->LowLevelLang()){
      return($lowlang);
   }
   if ($self->Config->Param("W5BaseOperationMode") eq "dev"){
      msg(INFO,"Warn: Lang(LANG)=%s not implemented! - ".
                     "using en caller=%s",join(",",caller(1)));
   }
   return("en");
}

sub LastMsg
{
   my $self=shift;
   my $type=shift;
   my $format=shift;
   my @p=@_;
   my $gc=globalContext();
   my $caller=caller();

   $gc->{LastMsg}=[] if (!exists($gc->{LastMsg}));
   if (defined($type)){
      if ($type eq ""){
         $gc->{LastMsg}=[];
      }
      else{
         msg(INFO,"LastMsg '%s' caller=$caller",$format);
         push(@{$gc->{LastMsg}},msg($type,$self->T($format,$caller),@p));
      }
   }
   else{
      if (wantarray()){
         return(@{$gc->{LastMsg}});
      }
   }
   return($#{$gc->{LastMsg}}+1);
}



sub getSkinFile
{
   my $self=shift;
   my $conftag=shift;
   my %param=@_;
   my $baseskindir=$self->getSkinDir();
   my @skin=$self->getSkin();
 
   $conftag=~s/\.\./\./g;              # security hack
   $conftag=~s/^\///g;                 # security hack

   my @filename=();
   if (defined($param{addskin})){
      unshift(@skin,$param{addskin});
   }
   my @skindir=($baseskindir);
   my $modpath=$self->Config->Param("MODPATH");
   if ($modpath ne ""){
      foreach my $path (split(/:/,$modpath)){
         $path.="/skin";
         my $qpath=quotemeta($path);
         unshift(@skindir,$path) if (!grep(/^$qpath$/,@skindir));
      }
   }

   foreach my $skindir (@skindir){
      foreach my $skin (@skin){
         my $chkname=$skindir."/".$skin."/".$conftag;
         #msg(INFO,"chkname='$chkname'");
         if ($conftag=~m/\*/){
            my @flist=glob($chkname);
            return(@flist) if ($#flist>=0);
         }
         else{
            if (-f $chkname){
               return($chkname);
            }
         }
      }
   }
   return();
}

sub T
{
   my $self=shift;
   my $txt=shift;
   my @module=@_;
   my $lang=$self->Lang();
   my @trtab;
   if ($#module==-1){
      $trtab[0]=(caller())[0];
   }
   else{
      @trtab=@module;
   }
   #printf STDERR ("TRANSLATE: $txt with $trtab\n");
   foreach my $trtab (@trtab){
      if ($trtab ne ""){
         if (!defined($W5V2::Translation->{tab}->{$trtab})){
            #msg(INFO,"load translation table for '$trtab'");
            if (exists($W5V2::Translation->{self})){
               $W5V2::Translation->{tab}->{$trtab}=
                         $W5V2::Translation->{self}->LoadTranslation($trtab,0);
            }
            else{
               $W5V2::Translation->{tab}->{$trtab}=
                         $self->LoadTranslation($trtab,0);
            }
         }
         if (exists($W5V2::Translation->{tab}->{$trtab}->{$lang}) &&
             exists($W5V2::Translation->{tab}->{$trtab}->{$lang}->{$txt})){
            return($W5V2::Translation->{tab}->{$trtab}->{$lang}->{$txt});
         }
      }
   }
   return($txt);
}

sub PreParseTimeExpression
{
   my $self=shift;
   my $val=shift;
   my $tz=shift;
   my $filename=shift;
   my $f=undef;

   ####################################################################
   # pre parser
   if ($val=~m/^currentmonth$/gi){
      my ($Y,$M,$D,$h,$m,$s)=Today_and_Now($tz); 
      my $max=Days_in_Month($Y,$M);
      $val="\">=$Y-$M-01 00:00:00\" AND \"<=$Y-$M-$max 23:59:59\"";
      $f=sprintf("%04d/%02d",$Y,$M);
   }
   elsif ($val=~m/^lastmonth$/gi){
      my ($Y,$M,$D,$h,$m,$s)=Today_and_Now($tz); 
      ($Y,$M,$D)=Add_Delta_YM($tz,$Y,$M,$D,0,-1);
      my $max=Days_in_Month($Y,$M);
      $val="\">=$Y-$M-01 00:00:00\" AND \"<=$Y-$M-$max 23:59:59\"";
      $f=sprintf("%04d-%02d",$Y,$M);
   }
   elsif ($val=~m/^nextmonth$/gi){
      my ($Y,$M,$D,$h,$m,$s)=Today_and_Now($tz); 
      ($Y,$M,$D)=Add_Delta_YM($tz,$Y,$M,$D,0,1);
      my $max=Days_in_Month($Y,$M);
      $val="\">=$Y-$M-01 00:00:00\" AND \"<=$Y-$M-$max 23:59:59\"";
      $f=sprintf("%04d/%02d",$Y,$M);
   }
   elsif ($val=~m/^currentmonth and lastmonth$/gi ||
          $val=~m/^lastmonth and currentmonth$/gi){
      my ($Y,$M,$D,$h,$m,$s)=Today_and_Now($tz); 
      my ($Y0,$M0,$D0)=Add_Delta_YM($tz,$Y,$M,$D,0,-1);
      my ($Y1,$M1,$D1)=($Y,$M,$D);
      my $max=Days_in_Month($Y1,$M1);
      $val="\">=$Y0-$M0-01 00:00:00\" AND \"<=$Y1-$M1-$max 23:59:59\"";
      $f=sprintf("%04d/%02d-%02d",$Y,$M,$M1);
   }
   elsif (my ($d)=$val=~m/^last\s+(\d+) months$/gi){
      my ($Y,$M,$D,$h,$m,$s)=Today_and_Now($tz); 
      my ($Y0,$M0,$D0)=Add_Delta_YM($tz,$Y,$M,$D,0,-1*$d);
      my ($Y1,$M1,$D1)=($Y,$M,$D);
      my $max=Days_in_Month($Y1,$M1);
      $val="\">=$Y0-$M0-01 00:00:00\" AND \"<=$Y1-$M1-$max 23:59:59\"";
      $f=sprintf("%04d/%02d-%02d",$Y,$M0,$M1);
   }
   elsif (my ($M,$Y)=$val=~m/^\((\d+)\/(\d+)\)$/gi){
      my $max;
      eval('$max=Days_in_Month($Y,$M);');
      if ($@ eq ""){
         $val="\">=$Y-$M-01 00:00:00\" AND \"<=$Y-$M-$max 23:59:59\"";
         $f=sprintf("%04d/%02d",$Y,$M);
      }
   }
   elsif (my ($q,$Y)=$val=~m/^\(q([1234])\/(\d+)\)$/gi){
      my ($m1,$m2)=(10,12);
      if ($q==1){
         $m1=1;$m2=3;
      }
      elsif($q==2){
         $m1=4;$m2=6;
      }
      elsif($q==3){
         $m1=7;$m2=9;
      }
      my $max;
      eval('$max=Days_in_Month($Y,$m2);');
      if ($@ eq ""){
         $val="\">=$Y-$m1-01 00:00:00\" AND \"<=$Y-$m2-$max 23:59:59\"";
         $f=sprintf("%04d/Q%d",$Y,$q);
      }
   }
   elsif (my ($h,$Y)=$val=~m/^\(h([12])\/(\d+)\)$/gi){
      my ($m1,$m2)=(7,12);
      if ($h==1){
         $m1=1;$m2=6;
      }
      my $max;
      eval('$max=Days_in_Month($Y,$m2);');
      if ($@ eq ""){
         $val="\">=$Y-$m1-01 00:00:00\" AND \"<=$Y-$m2-$max 23:59:59\"";
         $f=sprintf("%04d/H%d",$Y,$h);
      }
   }
   elsif (my ($Y,$M)=$val=~m/^\((\d{4})(\d{2})\)$/gi){
      my $max;
      eval('$max=Days_in_Month($Y,$M);');
      if ($@ eq ""){
         $val="\">=$Y-$M-01 00:00:00\" AND \"<=$Y-$M-$max 23:59:59\"";
         $f=sprintf("%04d/%02d",$Y,$M);
      }
   }
   elsif (my ($Y,$W)=$val=~m/^\((\d+)[CK]W(\d+)\)$/gi){
      my ($syear,$smon,$sday);
      eval('($syear,$smon,$sday)=Monday_of_Week($W,$Y);');
      if ($@ eq ""){
         $val="\">=$syear-$smon-$sday 00:00:00\" AND ".
              "\"<=$syear-$smon-$sday 23:59:59+7d\"";
         $f=sprintf("%04d/CW%02d",$Y,$W);
      }
   }
   elsif (my ($Y,$W)=$val=~m/^\((\d+)Q(\d+)\)$/gi){   # Quartal def is todo!
   #   my ($syear,$smon,$sday);   
   #   eval('($syear,$smon,$sday)=Monday_of_Week($W,$Y);');
   #   if ($@ eq ""){
   #      $val="\">=$syear-$smon-$sday 00:00:00\" AND ".
   #           "\"<=$syear-$smon-$sday 23:59:59+7d\"";
   #      $f=sprintf("%04d/CW%02d",$Y,$W);
   #   }
   }
   elsif (my ($Y)=$val=~m/^\((\d{4,4})\)$/gi){
      my $max;
      eval('$max=Days_in_Month($Y,12);');
      if ($@ eq ""){
         $val="\">=$Y-01-01 00:00:00\" AND \"<=$Y-12-$max 23:59:59\"";
         $f=sprintf("%04d/01-12",$Y);
      }
   }
   $$filename=$f if (ref($filename) eq "SCALAR");

   return($val);
}


sub ExpandTimeExpression
{
   my $self=shift;
   my $val=shift;
   my $format=shift;    # undef=stamp|de|en|DateTime
   my $srctimezone=shift;
   my $dsttimezone=shift;
   my %param=@_;
   my $result="";
   my ($Y,$M,$D,$h,$m,$s);
   my $found=0;
   my $fail=1;
   my $time;
   my $orgval=trim($val);
   if ($param{defhour} eq ""){
      $param{defhour}=0;
   }
   if ($param{defmin} eq ""){
      $param{defmin}=0;
   }
   if ($param{defsec} eq ""){
      $param{defsec}=0;
   }
   $dsttimezone="GMT" if (!defined($dsttimezone));
   $format="en" if (!defined($format));
   if (!defined($srctimezone)){
      $srctimezone=$self->UserTimezone();
   }
   ####################################################################
   my $monthbase=$self->T("monthbase");
   my $todaylabel=$self->T("today");
   my $nowlabel=$self->T("now");

   #msg(INFO,"ExpandTimeExpression for '$val'");
   if ($val=~m/^$nowlabel/gi){
      $val=~s/^$nowlabel//;
      ($Y,$M,$D,$h,$m,$s)=Today_and_Now($dsttimezone); 
      $found=1;
      $fail=0;
   }
   elsif ($val=~m/^$todaylabel/gi){
      $val=~s/^$todaylabel//;
      ($Y,$M,$D,undef,undef,undef)=Today_and_Now($srctimezone); 
      $h=$param{defhour};
      $m=$param{defmin};
      $s=$param{defsec};
      eval('$time=Mktime($srctimezone,$Y,$M,$D,$h,$m,$s);');
      ($Y,$M,$D,$h,$m,$s)=Localtime($dsttimezone,$time);
      $found=1;
      $fail=0;
   }
   elsif ($val=~m/^now/gi){
      $val=~s/^now//;
      ($Y,$M,$D,$h,$m,$s)=Today_and_Now($dsttimezone); 
      $found=1;
      $fail=0;
   }
   elsif ($val=~m/^today/gi){
      $val=~s/^today//;
      ($Y,$M,$D,undef,undef,undef)=Today_and_Now($srctimezone); 
      $h=$param{defhour};
      $m=$param{defmin};
      $s=$param{defsec};
      eval('$time=Mktime($srctimezone,$Y,$M,$D,$h,$m,$s);');
      ($Y,$M,$D,$h,$m,$s)=Localtime($dsttimezone,$time);
      $found=1;
      $fail=0;
   }
   elsif ($val=~m/^monthbase/gi){
      $val=~s/^monthbase//;
      ($Y,$M,undef,undef,undef,undef)=Today_and_Now($srctimezone); 
      $h=$param{defhour};
      $m=$param{defmin};
      $s=$param{defsec};
      $D=1;
      eval('$time=Mktime($srctimezone,$Y,$M,$D,$h,$m,$s);');
      ($Y,$M,$D,$h,$m,$s)=Localtime($dsttimezone,$time);
      $found=1;
      $fail=0;
   }
   elsif (($Y,$M,$D,$h,$m,$s)=$val=~
          m/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/){
      $val=~s/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})//;
      eval('$time=Mktime($srctimezone,$Y,$M,$D,$h,$m,$s);');
      if ($@ ne ""){
         $self->LastMsg(ERROR,"ilegal search expression '%s'",
                                         $orgval);
         return(undef);
      }
      
      ($Y,$M,$D,$h,$m,$s)=Localtime($dsttimezone,$time);
      $found=1;
      $fail=0;
   }
   elsif (($M,$Y)=$val=~/^(\d+)\/(\d+)/){
      $val=~s/^(\d+)\/(\d+)//;
      $Y+=2000 if ($Y<50);
      $Y+=1900 if ($Y>=50 && $Y<=99);
      $Y=1971 if ($Y<1971);
      $Y=2037 if ($Y>2037);
      eval('$time=Mktime($srctimezone,$Y,$M,1,0,0,0);');
      if ($@ ne ""){
         $self->LastMsg(ERROR,"ilegal month expression '%s'",
                                         $orgval);
         return(undef);
      }
      ($Y,$M,$D,$h,$m,$s)=Localtime($dsttimezone,$time);
      $found=1;
      $fail=0;
   }
   elsif (($Y,$M,$D,$h,$m,$s)=$val=~
          m/^(\d+)-(\d+)-(\d+)\s+(\d+):(\d+):(\d+)/){
      $val=~s/^(\d+)-(\d+)-(\d+)\s+(\d+):(\d+):(\d+)//;
      if (my ($srctz)=$val=~m/ ([A-Z]+)/){
         $val=~s/ ([A-Z])+//;
         $srctimezone=$srctz;
      }
      $Y+=2000 if ($Y<50);
      $Y+=1900 if ($Y>=50 && $Y<=99);
      $Y=1971 if ($Y<1971);
      $Y=2037 if ($Y>2037);
      eval('$time=Mktime($srctimezone,$Y,$M,$D,$h,$m,$s);');
      if ($@ ne ""){
         $self->LastMsg(ERROR,"ilegal expression '%s'",
                                         $orgval);
         return(undef);
      }
      
      ($Y,$M,$D,$h,$m,$s)=Localtime($dsttimezone,$time);
      $found=1;
      $fail=0;
   }
   elsif (($D,$M,$Y,$h,$m,$s)=$val=~
          m/^(\d+)\.(\d+)\.(\d+)\s+(\d+):(\d+):(\d+)/){
      $val=~s/^(\d+)\.(\d+)\.(\d+)\s+(\d+):(\d+):(\d+)//;
      $Y+=2000 if ($Y<50);
      $Y+=1900 if ($Y>=50 && $Y<=99);
      $Y=1971 if ($Y<1971);
      $Y=2037 if ($Y>2037);
      eval('$time=Mktime($srctimezone,$Y,$M,$D,$h,$m,$s);');
      if ($@ ne ""){
         $self->LastMsg(ERROR,"ilegal expression '%s'",
                                         $orgval);
         return(undef);
      }
      
      ($Y,$M,$D,$h,$m,$s)=Localtime($dsttimezone,$time);
      $found=1;
      $fail=0;
   }
   elsif (($D,$M,$Y,$h,$m)=$val=~
          m/^(\d+)\.(\d+)\.(\d+)\s+(\d+):(\d+)/){
      $val=~s/^(\d+)\.(\d+)\.(\d+)\s+(\d+):(\d+)//;
      $s=0;
      $Y+=2000 if ($Y<50);
      $Y+=1900 if ($Y>=50 && $Y<=99);
      $Y=1971 if ($Y<1971);
      $Y=2037 if ($Y>2037);
      eval('$time=Mktime($srctimezone,$Y,$M,$D,$h,$m,$s);');
      if ($@ ne ""){
         $self->LastMsg(ERROR,"ilegal expression '%s'",
                                         $orgval);
         return(undef);
      }
      ($Y,$M,$D,$h,$m)=Localtime($dsttimezone,$time);
      $found=1;
      $fail=0;
   }
   elsif (($D,$M,$Y)=$val=~m/^(\d+)\.(\d+)\.(\d+)/){
      $val=~s/^(\d+)\.(\d+)\.(\d+)//;
      $h=$param{defhour};
      $m=$param{defmin};
      $s=$param{defsec};
      $Y+=2000 if ($Y<50);
      $Y+=1900 if ($Y>=50 && $Y<=99);
      $Y=1971 if ($Y<1971);
      $Y=2037 if ($Y>2037);
      eval('$time=Mktime($srctimezone,$Y,$M,$D,$h,$m,$s);');
      if ($@ ne ""){
         msg(ERROR,$@);
         $self->LastMsg(ERROR,"ilegal time expression '%s' $Y-$M-$D $h:$m:$s",
                                         $orgval);
         return(undef);
      }
      ($Y,$M,$D,$h,$m,$s)=Localtime($dsttimezone,$time);
      $found=1;
      $fail=0;
   }
   elsif (($Y,$M,$D)=$val=~m/^(\d+)-(\d+)-(\d+)/){
      $val=~s/^(\d+)-(\d+)-(\d+)//;
      $h=$param{defhour};
      $m=$param{defmin};
      $s=$param{defsec};
      $Y+=2000 if ($Y<50);
      $Y+=1900 if ($Y>=50 && $Y<=99);
      $Y=1971 if ($Y<1971);
      $Y=2037 if ($Y>2037);
      eval('$time=Mktime($srctimezone,$Y,$M,$D,$h,$m,$s);');
      if ($@ ne ""){
         msg(ERROR,$@);
         $self->LastMsg(ERROR,"ilegal time expression '%s' $Y-$M-$D $h:$m:$s",
                                         $orgval);
         return(undef);
      }
      ($Y,$M,$D,$h,$m,$s)=Localtime($dsttimezone,$time);
      $found=1;
      $fail=0;
   }
   elsif (($h,$m,$s)=$val=~m/^(\d+):(\d+):(\d+)/){
      $val=~s/^(\d+):(\d+):(\d+)//;
      ($Y,$M,$D,undef,undef,undef)=Today_and_Now($srctimezone);
      eval('$time=Mktime($srctimezone,$Y,$M,$D,$h,$m,$s);');
      return(undef) if ($@ ne "");
      ($Y,$M,$D,$h,$m,$s)=Localtime($dsttimezone,$time);
      $found=1;
      $fail=0;
   }
   elsif (($h,$m)=$val=~m/^(\d+):(\d+)/){
      $val=~s/^(\d+):(\d+)//;
      ($Y,$M,$D,undef,undef,$s)=Today_and_Now($srctimezone);
      eval('$time=Mktime($srctimezone,$Y,$M,$D,$h,$m,$s);');
      return(undef) if ($@ ne "");
      ($Y,$M,$D,$h,$m,$s)=Localtime($dsttimezone,$time);
      $found=1;
      $fail=0;
   }


   while($found && !$fail){
      my $n;
      $found=0;
      if (($n)=$val=~m/^([\+-]\d+)h/){
         $val=~s/^([\+-]\d+)h//;
         ($Y,$M,$D,$h,$m,$s)=Add_Delta_YMDHMS($dsttimezone,$Y,$M,$D,$h,$m,$s,0,0,0,$n,0,0);
         $found=1;
      }
      elsif (($n)=$val=~m/^([\+-]\d+)M/){
         $val=~s/^([\+-]\d+)M//;
         ($Y,$M,$D)=Add_Delta_YM($dsttimezone,$Y,$M,$D,0,$n);
         $found=1;
      }
      elsif (($n)=$val=~m/^([\+-]\d+)Y/){
         $val=~s/^([\+-]\d+)Y//;
         ($Y,$M,$D)=Add_Delta_YM($dsttimezone,$Y,$M,$D,$n,0);
         $found=1;
      }
      elsif (($n)=$val=~m/^([\+-]\d+)m/){
         $val=~s/^([\+-]\d+)m//;
         ($Y,$M,$D,$h,$m,$s)=Add_Delta_YMDHMS($dsttimezone,$Y,$M,$D,$h,$m,$s,0,0,0,0,$n,0);
         $found=1;
      }
      elsif (($n)=$val=~m/^([\+-]\d+)d/){
         $val=~s/^([\+-]\d+)d//;
         ($Y,$M,$D,$h,$m,$s)=Add_Delta_YMDHMS($dsttimezone,$Y,$M,$D,$h,$m,$s,0,0,$n,0,0,0);
         $found=1;
      }
      elsif (($n)=$val=~m/^([\+-]\d+)s/){
         $val=~s/^([\+-]\d+)s//;
         ($Y,$M,$D,$h,$m,$s)=Add_Delta_YMDHMS($dsttimezone,$Y,$M,$D,$h,$m,$s,0,0,0,0,0,$n);
         $found=1;
      }
      elsif ($val=~m/^\s*$/){
         $val=~s/^\s*$//;
         $found=1;
         last;
      }
      else{
         $fail=1;
      }
   }
   if ($fail || $val ne "" || $found==0){
      if ($orgval ne ""){
         $self->LastMsg(ERROR,"can't interpret time expression '%s'",
                                            $orgval);
      }
      return(undef);
   }
   if (wantarray()){
      return($Y,$M,$D,$h,$m,$s);
   }
   return(Date_to_String($format,$Y,$M,$D,$h,$m,$s,$dsttimezone));
}


sub LoadSubObjs
{
   my $self=shift;
   my $extender=shift;
   my $hashkey=shift;
   $hashkey="SubDataObj" if (!defined($hashkey));
   if (!defined($self->{$hashkey})){
      my $instdir=$self->Config->Param("INSTDIR");
      my @path=($instdir);
      my @pat;
      my $modpath=$self->Config->Param("MODPATH");
      if ($modpath ne ""){
         foreach my $path (split(/:/,$modpath)){
            my $qpath=quotemeta($path);
            unshift(@path,$path) if (!grep(/^$qpath$/,@path));
         }
      }
      my @sublist;
      my @disabled;

      foreach my $path (@path){
         my $pat="$path/mod/*/$extender/*.pm";
         if ($extender=~m/\//){
            $pat="$path/mod/*/$extender.pm";
         }
         unshift(@sublist,glob($pat)); 
         unshift(@disabled,glob($pat.".DISABLED")); 
      }

      @sublist=map({my $qi=quotemeta($instdir);
                    $_=~s/^$qi//;
                    $_=~s/\/mod\///; 
                    $_;
                   } @sublist);

      @disabled=map({my $qi=quotemeta($instdir);
                    $_=~s/^$qi//;
                    $_=~s/\/mod\///; 
                    $_=~s/\.DISABLED//; 
                    $_."/" if (!($_=~m/\.pm$/));
                    $_;
                   } @disabled);

      foreach my $dis (@disabled){
         @sublist=grep(!/^$dis/,@sublist);
      }
    
      @sublist=map({$_=~s/\.pm$//;
                    $_=~s/\//::/g;
                    $_;
                   } @sublist);
      my $p;
      $p=$self->getParent->Self if (defined($self->getParent()));
      foreach my $modname (@sublist){
         my $o=$self->ModuleObject($modname);
         if (defined($o)){
            if (!$o->can("setParent")){
               msg(ERROR,"cant call setParent on $o");
            }
            $o->setParent($self);
            $self->{$hashkey}->{$modname}=$o;
            if ($o->can("Init")){
               if (!$o->Init()){
                  delete($self->{$hashkey}->{$modname});
                  $self->{"Inactiv".$hashkey}->{$modname}=$modname;
               }
            }
         }
         else{
            msg(ERROR,"can't load $hashkey '%s' in '%s'",$modname,$self);
            printf STDERR ("%s\n",$@);
         }
      }
      my $inactiv="";
      my $activ="";
      if (keys(%{$self->{$hashkey}})){
         $activ=sprintf(" activ=%s",join(", ",keys(%{$self->{$hashkey}}))); 
      }
      if (keys(%{$self->{"Inactiv".$hashkey}})){
         $activ=sprintf(" inactiv=%s",
                        join(", ",keys(%{$self->{"Inactiv".$hashkey}}))); 
      }
      if ($activ ne "" || $inactiv ne ""){
         #msg(INFO,"LoadSubObjs($self - $hashkey): $activ$inactiv");
      }
   }
   return(keys(%{$self->{$hashkey}}));
}


sub LoadSubObjsOnDemand
{
   my $self=shift;
   my $extender=shift;
   my $hashkey=shift;
   $hashkey="SubDataObj" if (!defined($hashkey));
   if (!defined($self->{$hashkey})){
      my $instdir=$self->Config->Param("INSTDIR");
      my @path=($instdir);
      my @pat;
      my $modpath=$self->Config->Param("MODPATH");
      if ($modpath ne ""){
         foreach my $path (split(/:/,$modpath)){
            my $qpath=quotemeta($path);
            unshift(@path,$path) if (!grep(/^$qpath$/,@path));
         }
      }
      my @sublist;
      my @disabled;

      foreach my $path (@path){
         my $pat="$path/mod/*/$extender/*.pm";
         if ($extender=~m/\//){
            $pat="$path/mod/*/$extender.pm";
         }
         unshift(@sublist,glob($pat)); 
         unshift(@disabled,glob($pat.".DISABLED")); 
      }

      @sublist=map({my $qi=quotemeta($instdir);
                    $_=~s/^$qi//;
                    $_=~s/\/mod\///; 
                    $_;
                   } @sublist);

      @disabled=map({my $qi=quotemeta($instdir);
                    $_=~s/^$qi//;
                    $_=~s/\/mod\///; 
                    $_=~s/\.DISABLED//; 
                    $_."/" if (!($_=~m/\.pm$/));
                    $_;
                   } @disabled);

      foreach my $dis (@disabled){
         @sublist=grep(!/^$dis/,@sublist);
      }
    
      @sublist=map({$_=~s/\.pm$//;
                    $_=~s/\//::/g;
                    $_;
                   } @sublist);
      my $p;
      $p=$self->getParent->Self if (defined($self->getParent()));
      foreach my $modname (@sublist){
          my $o;
          tie($o,'SubModulHandler',$modname,$self);
          $self->{$hashkey}->{$modname}=$o;
      }
   }
   return(keys(%{$self->{$hashkey}}));
}




package SubModulHandler;
require Tie::Scalar;
use strict;
use vars qw(@ISA);

@ISA = qw(Tie::Scalar);

sub TIESCALAR
{
   my $type=shift;
   my $name=shift;
   my $parent=shift;
   my $self=bless({parent=>$parent,name=>$name},$type);
   return($self);
}



sub FETCH
{
   my $self=shift;
   if (!exists($self->{obj})){
      $self->{obj}=$self->{parent}->ModuleObject($self->{name});
      return(undef) if (!defined($self->{obj}));
      if (defined($self->{obj})){
         if ($self->{obj}->can("setParent")){
            $self->{obj}->setParent($self->{parent});
         }
         if ($self->{obj}->can("Init")){
            if (!$self->{obj}->Init()){
               $self->{obj}=undef;
            }
         }
      }
   }
   return($self->{obj});
}










######################################################################
1;
