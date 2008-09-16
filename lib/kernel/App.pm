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
use Data::Dumper;
use XML::Smart;
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
      my $config=$self->Config();
      my $m=getModuleObject($config,$module);
      $self->{$label}=$m
   }
   $self->{$label}->ResetFilter();
   return($self->{$label});
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
      if ($rec->{acltarget} eq "base::user" &&
          $rec->{acltargetid} eq $userid){
         $u{$rec->{aclmode}}=1;
      } 
      if ($rec->{acltarget} eq "base::grp" &&
          grep(/^$rec->{acltargetid}$/,keys(%grps))){
         $u{$rec->{aclmode}}=1;
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
   my $account=shift;
   my @roles=@_;
   @roles=@{$roles[0]} if (ref($roles[0]) eq "ARRAY");
   my $userid;
   my $UserCache=$self->Cache->{User}->{Cache};
   if (defined($UserCache->{$account})){
      $UserCache=$UserCache->{$account}->{rec};
   }
   if (defined($UserCache->{userid})){
      $userid=$UserCache->{userid};
   }
   my %groups=$self->getGroupsOf($account,[qw(REmployee RBoss RBoss2 RMember)],
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

sub getMembersOf
{
   my $self=shift;
   my $group=shift;
   my $roles=shift;
   my $direction="down";
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


sub getGroupsOf
{
   my $self=shift;
   my $user=shift;
   my $roles=shift;      # internel names of roles         (undef=RMember)
   my $direction=shift;  # up | down | both | direct       (undef=direct)

   $roles=["RMember"]   if (!defined($roles));
   $roles=[$roles]      if (ref($roles) ne "ARRAY");
   $direction="direct"  if (!defined($direction));

   my @directgroups=();
   my %allgrp=();

   my $UserCache=$self->Cache->{User}->{Cache};
   if (defined($UserCache->{$user})){
      # user not cached! - there are a todo!
   }
   if (defined($UserCache->{$user})){
      $UserCache=$UserCache->{$user}->{rec};
      if (defined($UserCache->{groups}) && 
          ref($UserCache->{groups}) eq "ARRAY"){
         foreach my $role (@{$roles}){
            push(@directgroups,map({$_->{grpid}} 
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
      my $grp=getModuleObject($self->Config,"base::grp");
      $grp->SetCurrentView(qw(grpid fullname parentid subid));
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

sub LoadSubObjs
{
   my $self=shift;
   my $extender=shift;
   my $hashkey=shift;
   $hashkey="SubDataObj" if (!defined($hashkey));
   if (!defined($self->{$hashkey})){
      my $instdir=$self->Config->Param("INSTDIR");
      my $pat="$instdir/mod/*/$extender/*.pm";
      if ($extender=~m/\//){
         $pat="$instdir/mod/*/$extender.pm";
      }
      my @sublist=glob($pat); 
      @sublist=map({my $qi=quotemeta($instdir);
                    $_=~s/^$instdir//;
                    $_=~s/\/mod\///; 
                    $_;
                   } @sublist);

    
      my @disabled=glob("$instdir/mod/*.DISABLED"); 
      @disabled=map({my $qi=quotemeta($instdir);
                    $_=~s/^$instdir//;
                    $_=~s/\/mod\///; 
                    $_=~s/\.DISABLED//; 
                    $_."/" if (!($_=~m/\.pm$/));
                   } @disabled);
      foreach my $dis (@disabled){
         @sublist=grep(!/^$dis/,@sublist);
      }
    
      @sublist=map({$_=~s/\.pm$//;
                    $_=~s/\//::/g;
                    $_;
                   } @sublist);
      foreach my $modname (@sublist){
         my $o=getModuleObject($self->Config,$modname);
         if (defined($o)){
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
   if (grep(/^$ENV{LANG}$/,@languages)){
      return($ENV{LANG});
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
   my $skindir=$self->getSkinDir();
   my @skin=$self->getSkin();
 
   $conftag=~s/\.\./\./g;              # security hack
   $conftag=~s/^\///g;                 # security hack

   my @filename=();
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
      if (!defined($W5V2::Translation->{tab}->{$trtab})){
         msg(INFO,"load translation table for '$trtab'");
         $W5V2::Translation->{tab}->{$trtab}=
                          $W5V2::Translation->{self}->LoadTranslation($trtab,0);
      }
      if (exists($W5V2::Translation->{tab}->{$trtab}->{$lang}) &&
          exists($W5V2::Translation->{tab}->{$trtab}->{$lang}->{$txt})){
         return($W5V2::Translation->{tab}->{$trtab}->{$lang}->{$txt});
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
   my $result="";
   my ($Y,$M,$D,$h,$m,$s);
   my $found=0;
   my $fail=1;
   my $time;
   my $orgval=trim($val);
   $dsttimezone="GMT" if (!defined($dsttimezone));
   $format="en" if (!defined($format));
   if (!defined($srctimezone)){
      $srctimezone=$self->UserTimezone();
   }
   ####################################################################
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
      $h=0;
      $m=0;
      $s=0;
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
      $h=0;
      $m=0;
      $s=0;
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
      $h=0;
      $m=0;
      $s=0;
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
      $h=0;
      $m=0;
      $s=0;
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







######################################################################
1;
