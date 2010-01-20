package base::grp;
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
use kernel::CIStatusTools;
@ISA=qw(kernel::App::Web::HierarchicalList kernel::DataObj::DB kernel::CIStatusTools);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=3;
   my $self=bless($type->SUPER::new(%param),$type);

   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'grpid',
                label         =>'W5BaseID',
                size          =>'10',
                group         =>'source',
                dataobjattr   =>'grp.grpid'),
                                  
      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Fullname',
                readonly      =>1,
                htmlwidth     =>'300px',
                size          =>'40',
                dataobjattr   =>'grp.fullname'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                size          =>'20',
                dataobjattr   =>'grp.name'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoineditbase =>{id=>">0"},
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'grp.cistatus'),


      new kernel::Field::Text(
                name          =>'description',
                label         =>'Description',
                dataobjattr   =>'grp.description'),

      new kernel::Field::SubList(
                name          =>'users',
                subeditmsk    =>'subedit.group',
                label         =>'Users',
                group         =>'users',
                forwardSearch =>1,
                vjointo       =>'base::lnkgrpuser',
                vjoinon       =>['grpid'=>'grpid'],
                vjoindisp     =>['user','userweblink','roles'],
                vjoininhash   =>['userid','email','user','usertyp','roles']),

      new kernel::Field::TextDrop(
                name          =>'parent',
                AllowEmpty    =>1,
                label         =>'Parentgroup',
                vjointo       =>'base::grp',
                vjoinon       =>['parentid'=>'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'misc',
                label         =>'Comments',
                dataobjattr   =>'grp.comments'),

      new kernel::Field::PhoneLnk(
                name          =>'phonenumbers',
                searchable    =>0,
                label         =>'Phonenumbers',
                group         =>'phonenumbers',
                vjoinon       =>['grpid'=>'refid'],
                vjoinbase     =>[{'parentobj'=>\'base::grp'}],
                subeditmsk    =>'subedit'),

      new kernel::Field::Boolean(
                name          =>'is_org',
                label         =>'organisational Organisation',
                htmlhalfwidth =>1,
                group         =>'grptype',
                dataobjattr   =>'is_org'),

      new kernel::Field::Boolean(
                name          =>'is_line',
                label         =>'organisational Line',
                htmlhalfwidth =>1,
                group         =>'grptype',
                dataobjattr   =>'is_line'),

      new kernel::Field::Boolean(
                name          =>'is_depart',
                label         =>'organisational Department',
                htmlhalfwidth =>1,
                group         =>'grptype',
                dataobjattr   =>'is_depart'),

      new kernel::Field::Boolean(
                name          =>'is_resort',
                label         =>'organisational Resort',
                htmlhalfwidth =>1,
                group         =>'grptype',
                dataobjattr   =>'is_resort'),

      new kernel::Field::Boolean(
                name          =>'is_team',
                label         =>'organisational Team',
                htmlhalfwidth =>1,
                group         =>'grptype',
                dataobjattr   =>'is_team'),

      new kernel::Field::Boolean(
                name          =>'is_orggroup',
                label         =>'organisational Subunit',
                htmlhalfwidth =>1,
                group         =>'grptype',
                dataobjattr   =>'is_orggroup'),

      new kernel::Field::FileList(
                name          =>'attachments',
                parentobj     =>'base::grp',
                label         =>'Attachments',
                group         =>'attachments'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'grp.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'grp.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'grp.srcload'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'grp.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'grp.createuser'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'grp.createdate'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'grp.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'grp.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'grp.realeditor'),

      new kernel::Field::Link(
                name          =>'parentid',
                label         =>'ParentID',
                dataobjattr   =>'grp.parentid'),

      new kernel::Field::Link(
                name          =>'lastknownbossemail',
                label         =>'last Known Boss E-Mailaddesses',
                dataobjattr   =>'grp.lastknownbossemail'),

      new kernel::Field::SubList(
                name          =>'subunits',
                subeditmsk    =>'subedit.group',
                label         =>'Subunits',
                group         =>'subunits',
                vjointo       =>'base::grp',
                vjoinbase     =>{'cistatusid'=>"<6"},
                vjoinon       =>['grpid'=>'parentid'],
                vjoindisp     =>['name','cistatus'],
                vjoininhash   =>['grpid','name','fullname']),

      new kernel::Field::QualityText(),
      new kernel::Field::QualityState(),
      new kernel::Field::QualityOk(),
      new kernel::Field::QualityLastDate(
                dataobjattr   =>'grp.lastqcheck'),

   );
   $self->{PhoneLnkUsage}=\&PhoneUsage;
   $self->{CI_Handling}={uniquename=>"fullname",
                         altname=>'name',
                         activator=>["admin","admin.base.grp"],
                         uniquesize=>255};

   $self->setWorktable("grp");
   $self->setDefaultView(qw(fullname cistatus editor description grpid));
   $self->{locktables}="grp write,contact write,lnkgrpuser write,wfhead write, ".
                       "wfkey write, wfaction write";
   return($self);
}

sub PhoneUsage
{
   my $self=shift;
   my $current=shift;
   my @codes=qw(phoneMISC phoneONCALL phoneHOTLINE);
   my @l;
   foreach my $code (@codes){
      push(@l,$code,$self->T($code));
   }
   return(@l);

}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}




sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(),qw(TreeCreate));
}

sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $wrgroups=shift;

   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   return($self->SUPER::SecureValidate($oldrec,$newrec,$wrgroups));
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $cistatus=effVal($oldrec,$newrec,"cistatusid");
   if (defined($newrec->{name}) || !defined($oldrec)){
      trim(\$newrec->{name});
      $newrec->{name}=~s/[\.\s]/_/g;
      my $chkname=$newrec->{name};
      if ($cistatus==6 || $oldrec->{cistatusid}==6){
         $chkname=~s/\[.*?\]$//g;
      }
      if ($chkname eq "" || !($chkname=~m/^[\@\(\)a-zA-Z0-9_-]+$/)){
         $self->LastMsg(ERROR,"invalid groupname '\%s' specified",
                        $newrec->{name});
         return(undef);
      }
   }
   $newrec->{cistatusid}=4 if (!defined($oldrec) && $cistatus==0);
   if (!$self->SUPER::Validate($oldrec,$newrec,$origrec)){
      return(0);
   }
   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   return(1);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/grp.jpg?".$cgi->query_string());
}

sub getValidWebFunctions
{
   my $self=shift;

   return($self->SUPER::getValidWebFunctions(@_),"TeamView");
}

sub getHtmlDetailPages
{
   my $self=shift;
   my ($p,$rec)=@_;

   return($self->SUPER::getHtmlDetailPages($p,$rec),
          "TView"=>$self->T("Team View"));
}

sub getHtmlDetailPageContent
{
   my $self=shift;
   my ($p,$rec)=@_;
   return($self->SUPER::getHtmlDetailPageContent($p,$rec)) if ($p ne "TView");
   my $page;
   my $idname=$self->IdField->Name();
   my $idval=$rec->{$idname};

   if ($p eq "TView"){
      Query->Param("$idname"=>$idval);
      $idval="NONE" if ($idval eq "");

      my $q=new kernel::cgi({});
      $q->Param("$idname"=>$idval);
      my $urlparam=$q->QueryString();
      $page="<link rel=\"stylesheet\" ".
            "href=\"../../../static/lytebox/lytebox.css\" ".
            "type=\"text/css\" media=\"screen\" />";

      $page.="<iframe style=\"width:100%;height:100%;border-width:0;".
            "padding:0;margin:0\" class=HtmlDetailPage name=HtmlDetailPage ".
            "src=\"TeamView?$urlparam\"></iframe>";
   }
   $page.=$self->HtmlPersistentVariables($idname);
   return($page);
}

sub getGrpDiv
{
   my $self=shift;
   my $grec=shift;
   my $d;
   $d.="<div class=groupicon>";
   my $img=$self->getRecordImageUrl($grec);
   my $desc=$grec->{description}; 
   my $comm=$grec->{comments}; 
 
   $d.="<table width=100%>".
       "<tr><td width=1%><img class=groupicon src=\"$img\"></td>".
       "<td valign=top align=left><u>$desc</u><br>$comm</td></tr></table>";

   
   $d.="</div>";
   return($d);
}

sub getUserDiv
{
   my $self=shift;
   my $user=shift;
   my $usrec=shift;
   my $urec=shift;
   my $d;
   my $name;
   $d.="<div class=\"usericon\">";
   my $img=$user->getRecordImageUrl($urec);
   $d.="<img class=usericon src=\"$img\"><br>";

   
   $name.=$urec->{surname};
   $name.=", " if ($name ne "");
   $name.=$urec->{givenname};
   $name=$urec->{email} if ($name=~m/^\s*$/);
   
   $d.=$name."</div>";
   return($d);
}

sub TeamView   # erster Versuch der Teamview
{
   my $self=shift;

   my %flt=$self->getSearchHash();
   $self->ResetFilter();
   $self->SecureSetFilter(\%flt);
   my ($rec,$msg)=$self->getOnlyFirst(qw(ALL));


   print $self->HttpHeader();
   print $self->HtmlHeader(
                           title=>"TeamView",
                           js=>['toolbox.js'],
                           style=>['default.css','work.css',
                                   'kernel.App.Web.css',
                                   'public/base/load/grpteamview.css']);
   if (defined($rec)){
      my $employee;
      my $boss;
      if (ref($rec->{users}) eq "ARRAY"){
         my $user=getModuleObject($self->Config,"base::user");
         foreach my $usrec (sort({$a->{user} cmp $b->{user}} 
                                 @{$rec->{users}})){
            $user->ResetFilter();
            $user->SetFilter({userid=>\$usrec->{userid},cistatusid=>"<=4"});
            my ($urec,$msg)=$user->getOnlyFirst(qw(ALL));
            if ($usrec->{usertyp} ne "service" && defined($urec)){
               if (grep(/^RBoss$/,@{$usrec->{roles}})){
                  $boss.=$self->getUserDiv($user,$usrec,$urec);
               }
               else{
                  if (grep(/^REmployee$/,@{$usrec->{roles}})){
                     $employee.=$self->getUserDiv($user,$usrec,$urec);
                  }
               }
            }
         }
      }
      my $group=$self->getGrpDiv($rec);
      my $cleardiv="<div style=\"clear:both\"></div>";
      print "<div class=topframe>$rec->{fullname}$cleardiv</div>";
      print "<div class=groupframe>$group$boss$cleardiv</div>";
      print "<div class=userframe>$employee$cleardiv</div>";
   }
   print $self->HtmlBottom(body=>1,form=>1);
}




sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;

   return(0) if ($rec->{grpid}==1);
   return(0) if ($rec->{grpid}==-1);
   return(0) if ($rec->{grpid}==-2);
   return(0) if (!grep(/^default$/,$self->isWriteValid($rec)));
   return($self->SUPER::isDeleteValid($rec));
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   
   return(qw(header default source)) if (!defined($rec) || 
                                  (defined($rec->{grpid}) && $rec->{grpid}<=0));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   my $userid=$self->getCurrentUserId();
   return(qw(default)) if (!defined($rec));
   return("default") if ($rec->{cistatusid}<3 && ($rec->{creator}==$userid ||
                         $self->IsMemberOf($self->{CI_Handling}->{activator})));

   return(qw(default)) if (!defined($rec) && $self->IsMemberOf("admin"));
   return(undef) if ($rec->{grpid}<=0);
   return(qw(default users phonenumbers 
             misc grptype attachments)) if ($self->IsMemberOf("admin"));
   if (defined($rec)){
      my $grpid=$rec->{grpid};
      if ($self->IsMemberOf([$grpid],"RAdmin","down")){
         return(qw(users phonenumbers misc attachments));
      }
      if ($self->IsMemberOf([$grpid],["RBoss","RBoss2"],"direct")){
         return(qw(phonenumbers misc grptype attachments));
      }
   }
   return(undef);
}

sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

  # $self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}});
   $self->NotifyOnCIStatusChange($oldrec,$newrec);
   my $bak=$self->SUPER::FinishWrite($oldrec,$newrec);
   $self->InvalidateGroupCache();
   return($bak);
}

sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;
   my $bak=$self->SUPER::FinishDelete($oldrec);

   $self->InvalidateGroupCache();
   if (!$self->HandleCIStatus($oldrec,undef,%{$self->{CI_Handling}})){
      return(0);
   }
   return($self->SUPER::FinishDelete($oldrec));
}

sub ValidateDelete
{
   my $self=shift;
   my $rec=shift;

   if (ref($rec->{users}) eq "ARRAY" &&
       $#{$rec->{users}}!=-1){
      $self->LastMsg(WARN,"group has members!");
   }
   my $grpid=$rec->{grpid};
   if ($grpid ne ""){
      my $chk=getModuleObject($self->Config,"base::menuacl");
      $chk->SetFilter({acltarget=>\'base::grp',
                       acltargetid=>\$grpid});
      my ($chkrec,$msg)=$chk->getOnlyFirst(qw(refid));
      if (defined($chkrec)){
         $self->LastMsg(WARN,"group has references in menu acl!");
      }
      my $chk=getModuleObject($self->Config,"base::lnkcontact");
      $chk->SetFilter({target=>\'base::grp',
                       targetid=>\$grpid});
      my ($chkrec,$msg)=$chk->getOnlyFirst(qw(refid));
      if (defined($chkrec)){
         $self->LastMsg(WARN,"group has references in contact links!");
      }
   }

   return(1);
}


sub getDetailBlockPriority                # posibility to change the block order
{
   my $self=shift;
   return(qw(header default users subunits phonenumbers grptype 
             misc attachments));
}


sub TreeCreate
{
   my $self=shift;
   my $tree=shift;
   my @log=();
   my $createid=0;

   if (!defined($tree)){
      if (!$self->IsMemberOf("admin")){
         print($self->noAccess());
         return(undef);
      }
   }
   $self->LastMsg(INFO,"TreeCreate $tree") if (defined($tree));
   my $createname;
   my $doit=0;
   if (!defined($tree)){
      $createname=Query->Param("createname");
      $doit=1 if (Query->Param("DOIT"));
   }
   else{
      $doit=1;
      $createname=$tree;
   }
   if (defined($createname) && $createname ne "" && $doit){
      my $g=getModuleObject($self->Config,"base::grp");
      $self->LastMsg(INFO,"request to create $createname") if (!defined($tree));
      my @grp=split(/\./,trim($createname));
      my $parentgrp="";
      my $fullname="";
      foreach my $grp (@grp){
         my $parentis="";
         my %parentgrp=();
         $fullname=$grp;
         if ($parentgrp ne ""){
            $fullname=$parentgrp.".".$grp;
            %parentgrp=(parent=>$parentgrp);
         }
         $parentis=" parent is $parentgrp" if ($parentgrp ne "");
         if (!defined($tree)){
            $self->LastMsg(INFO,"try create $fullname$parentis");
         }
         $g->ResetFilter();
         $g->SetFilter({fullname=>\$fullname});
         my ($grprec,$msg)=$g->getOnlyFirst(qw(ALL));
         if (!defined($grprec)){
            my $grpid;
            if ($tree){
               $grpid=$g->ValidatedInsertRecord({
                          name=>$grp,
                          cistatusid=>4,
                          %parentgrp});
            }
            else{
               $grpid=$g->SecureValidatedInsertRecord({
                          name=>$grp,
                          cistatusid=>4,
                          %parentgrp});
            }
            if ($grpid){
               $self->LastMsg(OK,"insert of $grp as $grpid OK");
               if ($createname eq $fullname){
                  $createid=$grpid;
               }
            }
            else{
               $self->LastMsg(ERROR,"insert of $grp failed");
               last;
            }
         }
         else{
            $createid=$grprec->{grpid};
         }

         $parentgrp.="." if ($parentgrp ne "");
         $parentgrp.=$grp;
      }
   } 
   if ($createname eq "" && !defined($tree) && $doit){
      $self->LastMsg(ERROR,"no group name spcified");
   }


   if (!defined($tree)){
      print $self->HttpHeader("text/html");
      print $self->HtmlHeader(style=>['default.css','work.css',
                                      'kernel.App.Web.css'],
                              static=>{createname=>$createname},
                              body=>1,form=>1,
                              title=>"TreeCreate");
      print $self->getParsedTemplate("tmpl/minitool.grp.treecreate",
                           {
                             static=>{xxx=>'yyy'},
                           });
      print $self->HtmlBottom(body=>1,form=>1);

   }
   return($createid);
}

sub HandleInfoAboSubscribe
{
   my $self=shift;
   my $id=Query->Param("CurrentIdToEdit");
   my $ia=$self->getPersistentModuleObject("base::infoabo");
   if ($id ne ""){
      $self->ResetFilter();
      $self->SetFilter({grpid=>\$id});
      my ($rec,$msg)=$self->getOnlyFirst(qw(fullname));
      print($ia->WinHandleInfoAboSubscribe({},
                      $self->SelfAsParentObject(),$id,$rec->{fullname},
                      "base::staticinfoabo",undef,undef));
   }
   else{
      print($self->noAccess());
   }
}


sub getParentGroupIdByType
{
   my $self=shift;
   my $grpid=shift;
   my $type=shift;
   my @flags=qw(org line depart resort team orggroup);
   my @fields=qw(parentid grpid fullname);

   return(undef) if ($grpid eq "");
   return(undef) if (!grep(/^$type$/,@flags));
   foreach my $flag (@flags){
      push(@fields,"is_".$flag);
   }
   if (exists($self->Cache->{getParentGroupIdByType}->{$grpid.".".$type})){
      return($self->Cache->{getParentGroupIdByType}->{$grpid.".".$type});
   }

   $self->SetFilter({grpid=>\$grpid});
   my ($grec,$msg)=$self->getOnlyFirst(@fields);
   if (defined($grec)){
      if ($grec->{"is_".$type}){
         $self->Cache->{getParentGroupIdByType}->{$grpid.".".$type}=
                       $grec->{grpid};
         return($grec->{grpid});
      }
      my $parentid=$grec->{parentid};
      if ($parentid ne ""){
         return($self->getParentGroupIdByType($parentid,$type));
      }
   }
   return(undef);

}







1;
