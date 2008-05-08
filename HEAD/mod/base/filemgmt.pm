package base::filemgmt;
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
use kernel::App::Web::HierarchicalList;
use kernel::DataObj::DB;
use kernel::Field;
use Data::Dumper;
use Fcntl qw(SEEK_SET);
use File::Temp(qw(tmpfile));
@ISA=qw(kernel::App::Web::HierarchicalList kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Id(       name       =>'fid',
                                   label      =>'W5BaseID',
                                   size       =>'10',
                                   dataobjattr=>'filemgmt.fid'),
                                  
      new kernel::Field::Text(     name       =>'fullname',
                                   label      =>'Fullname',
                                   readonly   =>1,
                                   htmlwidth  =>'300px',
                                   size       =>'40',
                                   dataobjattr=>'filemgmt.fullname'),

      new kernel::Field::File(     name       =>'file',
                                   onDownloadUrl=>sub{
                                      my $self=shift;
                                      my $current=shift;
                                      if ($current->{realfile} eq ""){
                                         return(undef);
                                      }
                                      return("load/".$current->{fid}); 
                                   },
                                   label      =>'Fileentry'),

      new kernel::Field::Text(     name       =>'name',
                                   label      =>'Name',
                                   size       =>'20',
                                   dataobjattr=>'filemgmt.name'),

      new kernel::Field::TextDrop( name       =>'parent',
                                   label      =>'Directory',
                                   vjointo    =>'base::filemgmt',
                                   vjoinon    =>['parentid'=>'fid'],
                                   xvjoinbase  =>['realfile'=>\''],
                                   vjoindisp  =>'fullname'),


      new kernel::Field::Select(   name       =>'inheritrights',
                                   label      =>'inherit rights',
                                   value      =>[qw(1 0)],
                                   transprefix=>'boolean.',
                                   dataobjattr=>'filemgmt.inheritrights'),

      new kernel::Field::Text(     name       =>'parentobj',
                                   htmldetail =>0,
                                   label      =>'parent Object',
                                   htmlwidth  =>'90',
                                   dataobjattr=>'filemgmt.parentobj'),

      new kernel::Field::Text(     name       =>'parentrefid',
                                   group      =>'source',
                                   label      =>'parent Referenz ID',
                                   htmlwidth  =>'110',
                                   readonly   =>1,
                                   dataobjattr=>'filemgmt.parentrefid'),

      new kernel::Field::Text(     name       =>'entrytyp',
                                   readonly   =>1,
                                   group      =>'state',
                                   default    =>'dir',
                                   label      =>'Entry-Type',
                                   dataobjattr=>'filemgmt.entrytyp'),

      new kernel::Field::Text(     name       =>'contenttype',
                                   readonly   =>1,
                                   group      =>'state',
                                   label      =>'Content-Type',
                                   dataobjattr=>'filemgmt.contenttype'),

      new kernel::Field::Text(     name       =>'contentsize',
                                   readonly   =>1,
                                   group      =>'state',
                                   label      =>'Content-Size',
                                   dataobjattr=>'filemgmt.contentsize'),

      new kernel::Field::Text(     name       =>'contentstate',
                                   readonly   =>1,
                                   group      =>'state',
                                   onRawValue =>\&getState,
                                   depend     =>['realfile','contenttype',
                                                 'entrytyp'],
                                   label      =>'Content-State'),

      new kernel::Field::Textarea( name       =>'comments',
                                   label      =>'Comments',
                                   dataobjattr=>'filemgmt.comments'),

      new kernel::Field::SubList(   name       =>'acls',
                                    xsearchable=>0,
                                    label      =>'Accesscontrol',
                                    subeditmsk =>'subedit.file',
                                    allowcleanup=>1,
                                    group      =>'acl',
                                    vjoininhash=>[qw(acltarget 
                                                     acltargetid 
                                                     aclmode)],
                                    vjointo    =>'base::fileacl',
                                    vjoinbase=>{'aclparentobj'=>$self->Self()},
                                    vjoinon    =>['fid'=>'refid'],
                                    vjoindisp  =>['acltargetname','aclmode']),

      new kernel::Field::Text(     name       =>'srcsys',
                                   group      =>'source',
                                   label      =>'Source-System',
                                   dataobjattr=>'filemgmt.srcsys'),

      new kernel::Field::Text(     name       =>'srcid',
                                   group      =>'source',
                                   label      =>'Source-Id',
                                   dataobjattr=>'filemgmt.srcid'),

      new kernel::Field::Date(     name       =>'srcload',
                                   group      =>'source',
                                   label      =>'Last-Load',
                                   dataobjattr=>'filemgmt.srcload'),

      new kernel::Field::MDate(    name       =>'mdate',
                                   group      =>'source',
                                   label      =>'Modification-Date',
                                   dataobjattr=>'filemgmt.modifydate'),

      new kernel::Field::CDate(    name       =>'cdate',
                                   group      =>'source',
                                   label      =>'Creation-Date',
                                   dataobjattr=>'filemgmt.createdate'),

      new kernel::Field::Owner(    name       =>'owner',
                                   group      =>'source',
                                   label      =>'Owner',
                                   dataobjattr=>'filemgmt.owner'),

      new kernel::Field::Editor(   name       =>'editor',
                                   group      =>'source',
                                   label      =>'Editor',
                                   dataobjattr=>'filemgmt.editor'),

      new kernel::Field::RealEditor(name      =>'realeditor',
                                   group      =>'source',
                                   label      =>'RealEditor',
                                   dataobjattr=>'filemgmt.realeditor'),

      new kernel::Field::Link(     name       =>'parentid',
                                   label      =>'ParentID',
                                   dataobjattr=>'filemgmt.parentid'),

      new kernel::Field::Text(     name       =>'realfile',
                                   group      =>'source',
                                   label      =>'Realfile',
                                   readonly   =>1,
                                   dataobjattr=>'filemgmt.realfile'),


 #     new kernel::Field::SubList(  name       =>'users',
 #                                  label      =>'Users',
 #                                  group      =>'userro',
 #                                  vjointo    =>'base::lnkgrpuser',
 #                                  vjoinon    =>['grpid'=>'grpid'],
 #                                  vjoindisp  =>['user','roles']),
   );
   $self->setWorktable("filemgmt");
   $self->setDefaultView(qw(fullname contentsize parentobj entrytyp editor));
   $self->{PathSeperator}="/";
   $self->{locktables}="filemgmt write,fileacl write";
   return($self);
}

sub getState
{
   my $self=shift;
   my $current=shift;
   my $app=$self->getParent;
   my $config=$app->Config->getCurrentConfigName();
   my $w5root=$app->Config->Param("W5DOCDIR");
   $w5root.="/" if (!($w5root=~m/\/$/));
   my $state="bad";
   $state="ok" if ( $current->{entrytyp} eq "dir");
   $state="ok" if ( -f "${w5root}$config/$current->{realfile}" &&
                    -r "${w5root}$config/$current->{realfile}");
   $state="ok" if ( -f "${w5root}$config/$current->{realfile}");

   return($state);
}

#sub getSqlFrom
#{
#   my $self=shift;
#   my $from="filemgmt left outer join fileacl ".
#            "on filemgmt.fid=fileacl.refid and ".
#            "fileacl.aclparentobj='base::filemgmt'";
#   return($from);
#}
#
#
#
#sub SecureSetFilter
#{
#   my $self=shift;
##   if (!$self->IsMemberOf("admin")){
#      my $userid;
#      my $UserCache=$self->Cache->{User}->{Cache};
#      if (defined($UserCache->{$ENV{REMOTE_USER}})){
#         $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
#      }
#      if (defined($UserCache->{tz})){
#         $userid=$UserCache->{userid};
#      }
#      my %groups=$self->getGroupsOf($ENV{REMOTE_USER},'RMember','both');
#      return($self->SUPER::SecureSetFilter([{owner=>\$userid},
#                                            {aclmode=>['write','read'],
#                                             acltarget=>\'base::user',
#                                             acltargetid=>[$userid]},
#                                            {aclmode=>['write','read'],
#                                             acltarget=>\'base::grp',
#                                             acltargetid=>[keys(%groups)]},
#                                            {acltargetid=>[undef]},
#                                            ],@_));
##   }
#   return($self->SUPER::SecureSetFilter(@_));
#}



sub SecureSetFilter
{
   my $self=shift;
   my %flt=();
   %flt=(parentobj=>undef) if (!$self->IsMemberOf("admin"));
   return($self->SUPER::SecureSetFilter(\%flt,@_));
}


sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(),"load","browser","Empty",
          "WebRefresh","WebUpload","WebCreateDir","WebDAV");
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   if (!defined($oldrec)){
      if ($newrec->{parentobj} eq ""){
         $newrec->{parentobj}="base::filemgmt";
         $newrec->{parentrefid}="0";
      }
      $newrec->{parentid}=undef if (!exists($newrec->{parentid}) ||
                                     $newrec->{parentid}==0);
     # if ($newrec->{parentrefid} ne ""){
     #     
     # }
   }
   else{
      delete($newrec->{parentobj});
      delete($newrec->{parentrefid});
   }
   if (defined($newrec->{parentid})){
      my $chkfm=getModuleObject($self->Config,"base::filemgmt");
      $chkfm->SetFilter({fid=>[$newrec->{parentid}],entrytyp=>\'dir'});
      my ($prec)=$chkfm->getOnlyFirst("fid");
      if (!defined($prec)){
         $self->LastMsg(ERROR,"invalid parentid specified");
         return(undef);
      }
   }
   
   if (defined($newrec->{name}) || !defined($oldrec)){
      trim(\$newrec->{name});
      $newrec->{name}=~s/^.*[\\\/]//;
      $newrec->{name}=UTF8toLatin1($newrec->{name});
      if ($newrec->{name} eq "" ||
          $newrec->{name} eq "W5Base" ||
          $newrec->{name} eq "auth" ||
          $newrec->{name} eq "public" ||
          $newrec->{name}=~m/["'`]/ ||
          !($newrec->{name}=~m/^[[:graph:]������� ]+$/i)){
         $self->LastMsg(ERROR,"invalid filename '%s' specified",
                        $newrec->{name});
         return(undef);
      }
   }

   if (defined($newrec->{file}) && $newrec->{file} ne ""){
      if (!defined($oldrec) || $newrec->{realfile} eq "" ||
          $oldrec->{realfile} eq ""){
         my $res;
         my $id;
         if (defined($res=$self->W5ServerCall("rpcGetUniqueId")) &&
             $res->{exitcode}==0){
            $id=$res->{id};
         }
         else{
            msg(ERROR,"InsertRecord: W5ServerCall returend %s",Dumper($res));
            $self->LastMsg(ERROR,"W5Server problem - can't get unique id - ".
                          "please contact the admin");
            return(undef);
         }
         $id=~tr/[0-9]/[a-z]/;
         my ($f,$d3,$d2,$d1)=$id=~m/^(.*)(\S\S)(\S\S)(\S\S)$/;
         $newrec->{realfile}="$d1/$d2/$d3/$f";
      }
      my $realfile=$newrec->{realfile};
      $realfile=$oldrec->{realfile} if (!defined($realfile));
      my $context=$self->Context();
      {
         no strict;
         my $f=$newrec->{file};
         msg(INFO,"got filetransfer request ref=$f");
         if (ref($f) eq "MIME::Entity"){
            $f=$newrec->{file}->open("r");
         }
         msg(INFO,"cleared filetransfer request ref=$f");
         my $bk=seek($f,0,SEEK_SET);
         seek($f,0,SEEK_SET);
         if (!$self->StoreFilehandle($f,$realfile,"preview")){
            $self->LastMsg(ERROR,"can't store file");
            return(undef);
         }
         $context->{CurrentFileHandle}=$f;
      }
      my ($size,$atime,$mtime,$ctime,$blksize,$blocks);
      my $f=$newrec->{file};
      if (ref($newrec->{file}) eq "MIME::Entity"){
         $f=$newrec->{file}->open("r");
         while(<$f>){};
         $size=$f->tell();
         $f->seek(0,0);
      }
      else{
         (undef,undef,undef,undef,undef,undef,undef,
          $size,$atime,$mtime,$ctime,$blksize,$blocks)=stat($f);
      }
      if (!defined($f) || $size<=0){
         $self->LastMsg(ERROR,sprintf($self->T("invalid file upload '%s($size)'"),$f));
         return(undef);
      }
      my $filename=$f;
      if (ref($newrec->{file}) eq "MIME::Entity"){
         $filename=$newrec->{file}->head()->get("Content-Disposition");
         ($filename)=$filename=~m/filename=\"(.+)\"/;
      }
      $filename=~s/^.*[\/\\]//;
      if (!defined($newrec->{name}) || $newrec->{name} eq ""){
         $newrec->{name}=$filename;
      }
      if (length($newrec->{name})>80){
         $self->LastMsg(ERROR,"filename '%s' to long",$newrec->{name});
         return(undef);
      }
      $newrec->{contentsize}=$size;
      if (!defined($newrec->{contenttype}) || $newrec->{contenttype} eq ""){
         my $i=Query->UploadInfo($f);
         $newrec->{contenttype}=$i->{'Content-Type'};
      }
      if (!defined($newrec->{contenttype}) || $newrec->{contenttype} eq ""){
         $self->ReadMimeTypes();
         my ($ext)=$newrec->{name}=~/\.([a-z,0-9]{1,4})$/;
         if (defined($ext) && $ext ne ""){
            if (defined($self->{MimeType}->{lc($ext)})){
               $newrec->{contenttype}=$self->{MimeType}->{lc($ext)};
            }
         }
         if ($newrec->{contenttype} eq ""){
            $newrec->{contenttype}="application/octect-bin";
         }
      }
      $newrec->{entrytyp}='file';
   }
   if ($newrec->{file} eq "" && !defined($oldrec)){
      $newrec->{entrytyp}='dir' if (!defined($newrec->{entrytyp}));
   }

   return($self->SUPER::Validate($oldrec,$newrec,$origrec));
}

sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;

   my $g=getModuleObject($self->Config,"base::filemgmt");
   my $grpid=$rec->{fid};
   $g->SetFilter({"parentid"=>\$grpid});
   my @l=$g->getHashList(qw(fid));
   if ($#l!=-1){
      return(undef);
   }
   return($self->isWriteValid($rec));
}

sub checkacl
{
   my $self=shift;
   my $rec=shift;
   my $mode=shift;

   my $userid=$self->getCurrentUserId();
   my $fm=$self->getPersistentModuleObject("base::filemgmt");
   my $context=$self->Context();
   $context->{aclmode}={} if (!defined($context->{aclmode}));
   $context=$context->{aclmode};
   if (!defined($context->{$rec->{fid}}->{$mode})){
      # acl des eigenen Records laden und im context abspeichern
      # Achtung: Die ACL's der parents m�ssen recursiv nach oben
      # ber�cksichtig werden

      my @fid=($rec->{fid});
      my $workrec=$rec;
      $context->{$workrec->{fid}}=$workrec;
      while(defined($workrec)){
         last if (!$workrec->{inheritrights});
         if (defined($workrec->{parentid})){
            my $parentid=$workrec->{parentid};
            if (!defined($context->{$parentid})){
               $fm->ResetFilter();
               $fm->SetFilter({fid=>\$parentid});
               ($workrec)=$fm->getOnlyFirst(qw(parentid acls  
                                               parentobj parentrefid
                                               inheritrights));
               $context->{$parentid}=$workrec if (defined($workrec));
            }
            unshift(@fid,$parentid);
            $workrec=$context->{$parentid};
         }
         else{
            last;
         }
      }
      my $foundro=0;
      my $foundrw=0;
      my $foundad=0;
      my $isadmin=$self->IsMemberOf("admin");
      foreach my $fid (@fid){
         if (!defined($context->{$fid}->{$mode})){
            my $issubofdata=0;
            if ($context->{$fid}->{parentobj} ne "" &&
                $context->{$fid}->{parentobj} ne "base::filemgmt" &&
                !defined($context->{$fid}->{parentid})){
               $issubofdata=1;
            }
            if ($isadmin){
               $foundad=1;
               $foundrw=1;
               $foundro=1;
            }
            else{
               if (ref($context->{$fid}->{acls}) eq "ARRAY"){
                  my $aclsfound=0;
                  foreach my $acl (@{$context->{$fid}->{acls}}){
                     $aclsfound++;
                     if (($acl->{acltarget} eq "base::user" &&
                          $acl->{acltargetid} eq $userid) ||
                         ($acl->{acltarget} eq "base::grp" &&
                          $self->IsMemberOf($acl->{acltargetid},undef,"both"))){
                        if ($acl->{aclmode} eq "admin"){
                           $foundad=1;
                        }
                        if ($acl->{aclmode} eq "write"||
                            $acl->{aclmode} eq "admin"){
                           $foundrw=1;
                        }
                        if ($acl->{aclmode} eq "read" ||
                            $acl->{aclmode} eq "write"||
                            $acl->{aclmode} eq "admin"){
                           $foundro=1;
                        }
                     }
                  }
                  if ($issubofdata && !$aclsfound){
                     $foundad=0;
                     $foundrw=0;
                     $foundro=1;
                  }
               }
            }
            $context->{$fid}={'read'=>$foundro,'write'=>$foundrw,
                              'admin'=>$foundad};
         }
         return(1) if ($context->{$fid}->{$mode});
      } 
   }
   return($context->{$rec->{fid}}->{$mode});

}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return(qw(header default)) if (!defined($rec));

   if (defined($rec)){
      return(qw(ALL)) if ($self->checkacl($rec,"read"));
   }
   return(undef);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
#   return(undef) if (!defined($rec));
   return(qw(default)) if (!defined($rec));
   return(qw(default acl)) if ($self->checkacl($rec,"write"));
   return(qw(default acl)) if ($self->IsMemberOf("admin"));
   return(undef);
}

sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $bak=$self->SUPER::FinishWrite($oldrec);

   my $context=$self->Context();
   if (defined($context->{CurrentFileHandle})){
      my $f=$context->{CurrentFileHandle};
      my $realfile=effVal($oldrec,$newrec,"realfile");
      if (!$self->StoreFilehandle($f,$realfile)){
         return(undef);
      }
   }

   return($bak);
}

sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;
   my $bak=$self->SUPER::FinishDelete($oldrec);

   $self->RemoveFile($oldrec);
   return($bak);
}

sub sendFile
{
   my $self=shift;
   my $id=shift;
   my $inline=shift;
   my $config=$self->Config->getCurrentConfigName();
   my $w5root=$self->Config->Param("W5DOCDIR");

   my ($rec,$msg);
   if (defined($id) && $id ne ""){
      $self->ResetFilter();
      $self->SetFilter({fid=>$id});
      $self->SetCurrentView(qw(ALL));
      ($rec,$msg)=$self->getFirst();
   }
   if (defined($rec)){
      my %param=();
      printf STDERR ("rec=%s\n",Dumper($rec));
      my $contenttype="application/octet-bin";
      $param{filename}="file.bin";
      $contenttype=$rec->{contenttype} if ($rec->{contenttype} ne "");
      $param{filename}=$rec->{name} if ($rec->{name} ne ""); 
      $param{attachment}=!($inline); 
      $param{cache}=10; 
      my $realfile="$w5root/$config/$rec->{realfile}";
      if (open(F,"<$realfile")){
         print $self->HttpHeader($contenttype,%param);
         print join("",<F>);
         return();
      }
   }
   print $self->HttpHeader("text/html");
   printf("Not found FunctionPath=%s<br>\n",Query->Param("FunctionPath"));  
}

sub load
{
   my $self=shift;
   my @fp=split(/\//,Query->Param("FunctionPath"));  
   my $inline=0;
   while($#fp>0){
      if ($fp[0] eq "inline"){
         $inline=1;
      }
      shift(@fp);
   }
   my $id=$fp[0];
   $self->sendFile($id,$inline);
}

sub RemoveFile
{
   my $self=shift;
   my $rec=shift;
   my $config=$self->Config->getCurrentConfigName();
   my $w5root=$self->Config->Param("W5DOCDIR");

   my $f=$w5root."/".$config."/".$rec->{realfile};
   msg(DEBUG,"try to unlink %s",$f);
   if (-f $f ){
      unlink($f);
   }
}


sub StoreFilehandle
{
   my $self=shift;
   my $fh=shift;
   my $filename=shift;
   my $mode=shift;
   my $config=$self->Config->getCurrentConfigName();
   my $w5root=$self->Config->Param("W5DOCDIR");
   my $dir=$w5root;
   umask(0);
   if (! -d $dir){
      msg(ERROR,"W5DOCDIR='$dir' does not exists");
      return(undef);
   }
   my @path=split(/\//,$filename);
   unshift(@path,$config);
   for(my $sub=0;$sub<$#path;$sub++){
      $dir.="/" if (!($dir=~m/\/$/));
      $dir.=$path[$sub];
      if (! -d $dir){
         msg(INFO,"dir='$dir'");
         if (!mkdir($dir)){
            msg(ERROR,"can't mkdir dir='$dir' - $?, $!");
            return(undef);
         }
      }
   } 
   my $realfile="$w5root/$config/$filename";
   if ($mode eq "preview"){
      if (!open(F,">$realfile")){
         msg(ERROR,"can't open for write file='$realfile'");
         return(undef);
      }
      close(F);
      unlink($realfile);
      return(1);
   }
   return(undef) if (!open(F,">$realfile"));
   my $buffer;
   while (my $bytesread=read($fh,$buffer,1024)) {
      print F $buffer;
   }
   close(F);
   return(1);
}


sub browser
{
   my $self=shift;
   my ($func,$p)=$self->extractFunctionPath();
   my $rootpath=Query->Param("RootPath");
   my $prefix=Query->Param("RootPath");
   my $header=$self->HttpHeader("text/html");
   $header.=$self->HtmlHeader(style=>['default.css','mainwork.css',
                                      'kernel.filemgmt.css',
                                      'kernel.filemgmt.browser.css'],
                              js=>['toolbox.js','subModal.js'],
                              form=>1,
                              prefix=>$prefix,
                              title=>"WebFS: ".$p);
   $header.=$self->HtmlSubModalDiv(prefix=>$prefix);
   my $bar=$self->getAppTitleBar(prefix=>$prefix,title=>'WebFS: '.$p);
   $rootpath.="/" if ($rootpath eq "..");
   $rootpath.="./" if ($rootpath eq "");
   if ($ENV{REQUEST_METHOD} eq "PUT"){
      msg(INFO,"request upload over PUT to '$p' by '$ENV{REMOTE_USER}'");
      if ($p=~m/\/$/){
         print(msg(ERROR,"unable to PUT directory '$p'"));
         return(undef);
      }
      my ($path,$file);
      my $target=$self->FindTarget($p);
      if (defined($target)){
         $path=$p;
         $file=$ENV{HTTP_CONTENT_NAME};
         if ($target->{entrytyp} eq "dir" && $file ne ""){
            msg(INFO,"store '$file' in '$path'");
         }
         else{
            $target=undef;
         }
      }
      if (!defined($target)){
         ($path,$file)=$p=~m/^(.*)\/(.*)$/;
         $path="/" if ($path eq "");
         $target=$self->FindTarget($path);
      }
      printf STDERR ("target=$path file=$file res=%s\n",Dumper($target));
      #return(undef);
      if (!defined($target)){
         my @p=split(/\//,$path);
         my $pdir="/";
         my $dir="";
         foreach my $sub (@p){
            next if ($sub eq "");
            $dir.="/$sub";
            $target=$self->FindTarget($dir);
            if (!defined($target)){
               my $ptarget=$self->FindTarget($pdir);
               if (defined($ptarget)){
                  my $actionok=0;
                  $actionok=1 if ($self->checkacl($ptarget,"write"));
                  $actionok=1 if ($self->IsMemberOf("admin"));
                  printf STDERR ("try to create $dir in $pdir\n");
                  last if (!$actionok);
                  my %rec=(name=>$sub,parent=>$ptarget->{fullname},
                           entrytyp=>'dir');
                  if (!($self->ValidatedInsertRecord(\%rec))){
                     msg(ERROR,"can't create dir $sub in $pdir");
                     last;
                  }
               }
            }
            $pdir=$dir;
         }
         $target=$self->FindTarget($path);
         if (!defined($target)){
            print("Status: 404\n");
            print($self->HttpHeader("text/plain"));
            print(msg(ERROR,"unable to find directory '$path'"));
            return(undef);
         }
      }
      my $actionok=0;
      $actionok=1 if ($self->checkacl($target,"write"));
      $actionok=1 if ($self->IsMemberOf("admin"));
      if (!$actionok){
         print("Status: 401\n");
         print($self->HttpHeader("text/plain"));
         print(msg(ERROR,"not allowed to PUT in directory '$path'"));
         return(undef);
      }

      my $clength = $ENV{'CONTENT_LENGTH'};
      #if (!$clength) { &reply(500, "Content-Length missing ($clength)"); }

      # Read the content itself
      my $toread = $clength;
      my $t=tmpfile();
      while ($toread > 0)
      {
          my $data;
          my $nread = read(STDIN, $data, $clength);
          last if (!$nread);
          syswrite($t,$data,$nread);
          #printf STDERR ("fifi nread=$nread data=$data\n");
      }
      seek($t,0,SEEK_SET);
      my %rec=(name=>$file,file=>$t);
      my %flt=(name=>\$file);
      $path=~s/^\///;
      if ($path ne ""){
         $rec{parent}=$path;
         $flt{parent}=\$path;
      }
      print($self->HttpHeader("text/plain"));
      if ($self->ValidatedInsertOrUpdateRecord(\%rec,\%flt)){
         $file=$ENV{HTTP_CONTENT_NAME} if ($ENV{HTTP_CONTENT_NAME} ne "");
         printf("%-6s %s\n","OK:","stored '$file' in '$p'");
      }
      else{
         printf("%-6s %s\n","ERROR:","$p not stored");
      }
      close($t);
      return(undef); 
   }
   my $target=$self->FindTarget($p,'*');
   if (!defined($target) && $p=~m/\/index.html$/){
      $p=~s/index.html$//;
      $target=$self->FindTarget($p,'*');
   }
   if (defined($target)){
      if ($p ne "/" && $p ne "" && !defined($self->isViewValid($target))){
         print($header);
         print("<div class=message>"); 
         printf("ERROR: ".$self->T("no access to '%s'"),$p);
         print("</div>"); 
         return(undef);
      }
      if ($target->{entrytyp} eq "file"){
         if ($target->{contenttype} eq "text/html" ||
             $target->{contenttype} eq "image/gif" ||
             $target->{contenttype} eq "image/jpeg" ||
             $target->{contenttype} eq "text/plain"){
            $self->sendFile($target->{fid},1);
         }
         else{
            $self->sendFile($target->{fid});
         }
        # print($header);
        # printf("Path=$p<br>");
        # printf("<a href=\"$up\">..</a><br>");
        # printf("sending file ...");
      } 
      else{
         my $fm=$self->getPersistentModuleObject("base::filemgmt");
         my $op=Query->Param("OP");
         my @oldval=Query->Param("fid");
         if ($op eq "delete" && $#oldval!=-1){
            Query->Delete("fid");
            Query->Delete("OP");
            $op=undef;
            $fm->SetFilter({'parentid'=>[$target->{fid}],fid=>\@oldval});
            $fm->SetCurrentView(qw(ALL));
            $fm->ForeachFilteredRecord(sub{
                                          $fm->ValidatedDeleteRecord($_);
                                       });
         }
         $fm->ResetFilter();
         $fm->SetFilter({parentid=>[$target->{fid}],
                         parentobj=>[undef,'base::filemgmt']});
         my @fl=$fm->getHashList(qw(ALL));
         my $up="index.html";
         if (defined($target->{fid})){
            $up="../index.html" if ($p=~m/\/$/);
         }
         my $qparam="";
         $qparam="parentid=$target->{fid}" if (defined($target->{fid}));
         my $page="<table style=\"table-layout:fixed\" ".
                  "width=100% height=100% border=0 ".
                  "cellspacing=0 cellpadding=0>";
         $page.="<tr height=1%><td valign=top>$bar</td></tr>";
         my $fileicon="<div class=fileimage>".
                      "<img border=0 ".
                      "src=\"$prefix../../base/load/filemgmt_generic.gif\">".
                      "</div>";
         my $diricon ="<div class=fileimage>".
                      "<img border=0 ".
                      "src=\"$prefix../../base/load/filemgmt_dir.gif\">".
                      "</div>";
         my $topicon ="<div class=fileimage>".
                      "<img border=0 ".
                      "src=\"$prefix../../base/load/filemgmt_top.gif\">".
                      "</div>";
         my $list="<div id=filelist>";
         if ($p ne "/" && $p ne "/index.html" && $p ne ""){
            $list.="<div class=fileline>".
                   "<a class=filelink href=\"$up\">${diricon}".
                   "<div class=filename>..</div></a></div>";
         }
         else{
            $list.="<div class=fileline>".
                   "<div style=\"float:none;\">${topicon}</div>".
                   "<div class=filename>&nbsp;</div></a></div>";
         }
         foreach my $fl (sort({$a->{entrytyp} cmp $b->{entrytyp}} 
                              sort({$a->{name} cmp $b->{name}} @fl))){
            if ($self->isViewValid($fl)){
               my $post="";
               my $prefix="";
               $prefix="browser/" if ($p eq "");
               $post="/index.html" if ($fl->{entrytyp} eq "dir");
               my $codedname=quoteQueryString($fl->{name});
               my $img=$fileicon;
               $img=$diricon if ($fl->{entrytyp} eq "dir");
               my $name="<div class=filename>$fl->{name}</div>";
               my $select="<div class=fileselect>";
               if ($op eq "delete"){
                  $select.="<input name=fid value=$fl->{fid} ".
                           "type=checkbox class=multiselect";
                  if (grep(/^$fl->{fid}$/,@oldval)){ 
                     $select.=" checked";
                  }
                  $select.=">";
               }
               $select.="</div>";
               $list.=sprintf("<div class=fileline>$select<a class=filelink ".
                              "href=\"$prefix%s$post\">%s%s</a></div>\n",
                              $codedname,$img,$name);
            }
         }
         my $actionok=0;
         $actionok=1 if ($self->checkacl($target,"write"));
         $actionok=1 if ($self->IsMemberOf("admin"));
         $list.="</div>";
         $page.="<tr id=listtr><td id=listtd valign=top>$list</td>";
         $page.="</table>";
         $page.="<input id=OP type=hidden name=OP ".
                "value=\"".Query->Param("OP")."\">";
         $page.="</form></body>";
         my $LRefresh=$self->T("Refresh");
         my $LUploadFiles=$self->T("Upload files");
         my $LDeleteFiles=$self->T("Delete");
         my $LCreateDir=$self->T("Create directory");
         my $LChangeRights=$self->T("Modify rights");
         $page.=<<EOF;
<div id=actionlist
     style="position:absolute;width:200px;
            right:0px;top:19px;display:none;visible:hidden">
<div class=actionlist>
<ul class=actionlist>
<li><a class=action href="JavaScript:Refresh()">$LRefresh</a><br>
<li><a class=action href="JavaScript:UploadFiles()">$LUploadFiles</a><br>
<li><a class=action href="JavaScript:DeleteFiles()">$LDeleteFiles</a><br>
<li><a class=action href="JavaScript:CreateDir()">$LCreateDir</a></a>
<li><a class=action href="JavaScript:ChangeRights()">$LChangeRights</a></a>
<!--
<li><a class=action href="JavaScript:MoveFiles()">Move</a>
<li><a class=action href="JavaScript:Rename()">Rename</a><br><br>
<li><a class=action href="JavaScript:DirectoryInformations()">Directory Informations</a>
-->
</ul>
</div>
</div>
<script language="JavaScript">
var list=document.getElementById("filelist");
var listtd=document.getElementById("listtd");
var listtr=document.getElementById("listtr");
var action=document.getElementById("actionlist");
list.style.height=listtr.offsetHeight+"px";
list.style.overflow="auto";

if (document.location.href.match('^http[s]{0,1}://') && $actionok==1){
   list.style.width=(listtr.offsetWidth-200)+"px";
   action.style.visible="visible";
   action.style.display="block";
}

function Refresh()
{
   return(RestartApp());
}

function UploadFiles()
{
   showPopWin('$prefix../../base/filemgmt/WebUpload?$qparam',
              500,100,RestartApp);

}
function CreateDir()
{
   showPopWin('$prefix../../base/filemgmt/WebCreateDir?$qparam',
              500,100,RestartApp);

}
function ChangeRights()
{
   showPopWin('$prefix../../base/filemgmt/EditProcessor?'+
              'Field=acls&RefFromId=$target->{fid}',
              500,300,RestartApp);

}
function DeleteFiles()
{
   var op=document.getElementById("OP");
   op.value="delete";
   document.forms[0].submit();

}

function RestartApp(returnVal,isbreak)
{
   if (!isbreak){
      document.location.href=document.location.href;
   }
}
</script>
EOF
         $page.="</html>";
         print $header.$page;
      }
   }
   else{
      print($header);
      print("<div class=message>"); 
      printf($self->T("ERROR: the requested path '%s' does not exists"),$p);
      print("</div>"); 
   }
}

sub FindTarget
{
   my $self=shift;
   my $p=shift;
   my $entrytyp=shift;
   $p=~s/^\///;
   my @param=split(/\//,$p);

   $entrytyp=\"dir" if (!defined($entrytyp));
  
   my $rec={}; 
   my $parentid=undef;

   return({fid=>undef,entrytyp=>'dir'}) if ($#param==-1);

   while(my $dir=shift(@param)){
      $self->ResetFilter();
      $self->SetFilter({parentid=>[$parentid],name=>\$dir,entrytyp=>$entrytyp,
                        parentobj=>[undef,'base::filemgmt']});
      my ($currec,$msg)=$self->getOnlyFirst(qw(ALL));
      if (!defined($currec)){
         return(undef);
      }
      $rec=$currec;
      $parentid=$rec->{fid};
   }

   return($rec);
}


sub WebRefresh
{
   my $self=shift;

}

sub WebUpload
{
   my $self=shift;
   my $parentid=Query->Param("parentid");

   my $header=$self->HttpHeader("text/html");
   $header.=$self->HtmlHeader(style=>['default.css','mainwork.css',
                                      'kernel.filemgmt.css',
                                      'kernel.filemgmt.browser.css'],
                              form=>1,multipart=>1,
                              js=>['toolbox.js','subModal.js'],
                              title=>"WebFS: File-Upload");
   my $msg;
   my $js="";
   if (Query->Param("do")){
      my %q=();
      $q{file}=Query->Param("file");
      $q{parentid}=Query->Param("parentid");
      if ($self->ValidatedInsertRecord(\%q)){
         $msg="<font color=green>OK</font>";
         $js="<script language=\"JavaScript\">parent.RestartApp()</script>";
      }
      else{
         $msg="<font color=red>".join("",$self->LastMsg())."</font>";
      }
   }
   print $header;
   print("<table width=100% style=\"table-layout:fixed\" ".
         "height=100% border=0>");
   print("<tr height=1%><td width=50>Datei:</td>");
   print("<td><input size=50 type=file name=file></td></tr>");
   print("<tr><td colspan=2 valign=center align=center>".
         "<input type=submit name=do style=\"width:200px\" ".
         "value=\"Upload\"></td></tr>");
   printf("<tr height=1%><td colspan=2 nowrap>".
          "<div class=LastMsg style=\"overflow:hidden\">%s&nbsp;</div>".
          "</td></tr>",$msg);
   print("</table>$js");
   print($self->HtmlPersistentVariables(qw(parentid)));
   print("</form></body></html>");
}

sub WebCreateDir
{
   my $self=shift;
   my $parentid=Query->Param("parentid");


   my $header=$self->HttpHeader("text/html");
   $header.=$self->HtmlHeader(style=>['default.css','mainwork.css',
                                      'kernel.filemgmt.css',
                                      'kernel.filemgmt.browser.css'],
                              form=>1,multipart=>1,
                              js=>['toolbox.js','subModal.js'],
                              title=>"WebFS: Dir-Create");
   my $msg;
   my $js="";
   if (Query->Param("do")){
      my %q=();
      $q{entrytyp}='dir';
      $q{name}=Query->Param("name");
      if (defined(Query->Param("parentid"))&&
          Query->Param("parentid") ne ""){
         $q{parentid}=Query->Param("parentid");
      }
      if ($self->ValidatedInsertRecord(\%q)){
         $msg="<font color=green>OK</font>";
         $js="<script language=\"JavaScript\">parent.RestartApp()</script>";
      }
      else{
         $msg="<font color=red>".join("",$self->LastMsg())."</font>";
      }
   }
   print $header;
   my $ct=$self->T("Create directory");
   my $d=<<EOF;
<table width=100% style="table-layout:fixed" height=100% border=0>
<tr height=1%><td width=120>Verzeichnisname:</td>
<td><input size=55 type=text name=name></td></tr>
<tr><td colspan=2 valign=center align=center>
<input type=submit name=do style="width:200px" value="$ct"></td></tr>
<tr height=1%><td colspan=2>${msg}&nbsp;</td></tr>
</table>
$js
<script language="JavaScript">
setEnterSubmit(document.forms[0],"do");
setFocus("name");
</script>
EOF
   print($d.$self->HtmlPersistentVariables(qw(parentid)));
   print("</form></body></html>");
}

sub WebDAV
{
   my $self=shift;
   printf STDERR ("fifi request=%s URI=%s $ENV{REMOTE_USER}\n",$ENV{REQUEST_METHOD},
                                             $ENV{REQUEST_URI});
   printf("Content-Type: text/xml\n\n".
          "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
   print <<EOF if ($ENV{REQUEST_URI} eq "/WebDAV");
<D:multistatus xmlns:D="DAV:">

<D:response xmlns:lp1="DAV:" xmlns:lp2="http://apache.org/dav/props/">
<D:href>/WebDAV/</D:href>
<D:propstat>
<D:prop>
<lp1:resourcetype><D:collection/></lp1:resourcetype>
<D:getcontenttype>httpd/unix-directory</D:getcontenttype>
</D:prop>
<D:status>HTTP/1.1 200 OK</D:status>
</D:propstat>
</D:response>
</D:multistatus>
EOF


#
#   print(<<EOF);
#<?xml version="1.0" encoding="UTF-8"?>
#<D:multistatus xmlns:D="DAV:">
#
#<D:response xmlns:lp1="DAV:" xmlns:lp2="http://apache.org/dav/props/">
#  <D:href>/lenya/blog/authoring/entries/2003/08/24/peanuts/</D:href>
#  <D:propstat>
#    <D:prop>
#      <lp1:resourcetype>
#          <D:collection/>
#      </lp1:resourcetype>
#      <D:getcontenttype>httpd/unix-directory</D:getcontenttype>
#    </D:prop>
#    <D:status>HTTP/1.1 200 OK</D:status>
#  </D:propstat>
#</D:response>
#
#</D:multistatus>
#EOF
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/filefolder.jpg?".$cgi->query_string());
}



1;
