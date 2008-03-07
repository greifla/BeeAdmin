package base::user;
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
use kernel;
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
use DateTime::TimeZone;
use base::workflow::mailsend;
use kernel::CIStatusTools;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::CIStatusTools);



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

      new kernel::Field::Text(
                name          =>'fullname',
                htmlwidth     =>'280',
                group         =>'name',
                readonly =>
                   sub{
                      my $self=shift;
                      return(1);
                    #  return(1) if (!$self->getParent->IsMemberOf("admin"));
                    #  return(0);
                   },
                label         =>'Fullname',
                dataobjattr   =>'user.fullname'),

      new kernel::Field::Select(
                name          =>'usertyp',
                label         =>'Usertyp',
                htmleditwidth =>'100px',
                default       =>'extern',
                value         =>[qw(extern service user function)],
                dataobjattr   =>'user.usertyp'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                group         =>'name',
                readonly      =>
                   sub{
                      my $self=shift;
                      my $rec=shift;
                      return(1) if (defined($rec) && 
                                    $rec->{cistatusid}>2 &&
                                    !$self->getParent->IsMemberOf("admin"));
                      return(0);
                   },
                label         =>'CI-State',
                vjointo       =>'base::cistatus',
                vjoineditbase =>{id=>">0"},
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Select(
                name          =>'perscistatus',
                htmleditwidth =>'40%',
                readonly      =>
                   sub{
                      my $self=shift;
                      my $rec=shift;
                      return(1) if (defined($rec) && 
                                    !$self->getParent->IsMemberOf("admin"));
                      return(0);
                   },
                label         =>'CI-State',
                vjointo       =>'base::cistatus',
                vjoineditbase =>{id=>">0"},
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'user.cistatus'),

      new kernel::Field::SubList(
                name          =>'accounts',
                label         =>'Accounts',
                allowcleanup  =>1,
                group         =>'userro',
                vjointo       =>'base::useraccount',
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>['account','cdate'],
                vjoininhash   =>['account','userid']),

      new kernel::Field::Id(
                name          =>'userid',
                label         =>'W5BaseID',
                size          =>'10',
                group         =>'userro',
                dataobjattr   =>'user.userid'),
                                  
      new kernel::Field::Text(
                name          =>'givenname',
                readonly      =>sub{
                                   my $self=shift;
                                   my $current=shift;
                                   if ($current->{usertyp} ne "service"){
                                      return(0);
                                   }
                                   return(1);
                                },
                group         =>'name',
                label         =>'Givenname',
                dataobjattr   =>'user.givenname'),
                                  
      new kernel::Field::Text(
                name          =>'surname',
                group         =>'name',
                depend        =>['usertyp'],
                readonly      =>sub{
                                   my $self=shift;
                                   my $current=shift;
                                   if ($current->{usertyp} ne "function"){
                                      return(0);
                                   }
                                   return(1);
                                },
                label         =>'Surname',
                dataobjattr   =>'user.surname'),

      new kernel::Field::Text(
                name          =>'office_mobile',
                group         =>'office',
                label         =>'Mobile-Phonenumber',
                dataobjattr   =>'user.office_mobile'),

      new kernel::Field::Text(
                name          =>'office_phone',
                group         =>'office',
                label         =>'Phonenumber',
                dataobjattr   =>'user.office_phone'),

      new kernel::Field::Text(
                name          =>'office_street',
                group         =>'office',
                label         =>'Street',
                dataobjattr   =>'user.office_street'),

      new kernel::Field::Text(
                name          =>'office_zipcode',
                group         =>'office',
                label         =>'ZIP-Code',
                dataobjattr   =>'user.office_zipcode'),

      new kernel::Field::Text(
                name          =>'office_location',
                group         =>'office',
                label         =>'Location',
                dataobjattr   =>'user.office_location'),

      new kernel::Field::Text(
                name          =>'office_facsimile',
                group         =>'office',
                label         =>'FAX-Number',
                dataobjattr   =>'user.office_facsimile'),

      new kernel::Field::Text(
                name          =>'office_elecfacsimile',
                group         =>'office',
                label         =>'electronical FAX-Number',
                dataobjattr   =>'user.office_elecfacsimile'),

      new kernel::Field::Number(
                name          =>'office_persnum',
                group         =>'office',
                label         =>'Personal-Number',
                dataobjattr   =>'user.office_persnum'),

      new kernel::Field::Text(
                name          =>'private_street',
                group         =>'private',
                label         =>'Street',
                dataobjattr   =>'user.private_street'),

      new kernel::Field::Text(
                name          =>'private_zipcode',
                group         =>'private',
                label         =>'ZIP-Code',
                dataobjattr   =>'user.private_zipcode'),

      new kernel::Field::Text(
                name          =>'private_location',
                group         =>'private',
                label         =>'Location',
                dataobjattr   =>'user.private_location'),

      new kernel::Field::Text(
                name          =>'private_facsimile',
                group         =>'private',
                label         =>'FAX-Number',
                dataobjattr   =>'user.private_facsimile'),

      new kernel::Field::Text(
                name          =>'private_elecfacsimile',
                group         =>'private',
                label         =>'electronical FAX-Number',
                dataobjattr   =>'user.private_elecfacsimile'),

      new kernel::Field::Text(
                name          =>'private_mobile',
                group         =>'private',
                label         =>'Mobile-Phonenumber',
                dataobjattr   =>'user.private_mobile'),

      new kernel::Field::Text(
                name          =>'private_phone',
                group         =>'private',
                label         =>'Phonenumber',
                dataobjattr   =>'user.private_phone'),

      new kernel::Field::Select(
                name          =>'tz',
                label         =>'Timezone',
                group         =>'userparam',
                value         =>['CET','GMT',DateTime::TimeZone::all_names()],
                dataobjattr   =>'user.timezone'),

      new kernel::Field::Select(
                name          =>'lang',
                label         =>'Language',
                htmleditwidth =>'50%',
                group         =>'userparam',
                value         =>['',LangTable()],
                dataobjattr   =>'user.lang'),

      new kernel::Field::Select(
                name          =>'pagelimit',
                label         =>'Pagelimit',
                unit          =>'Entrys',
                htmleditwidth =>'50px',
                group         =>'userparam',
                value         =>[qw(10 15 20 30 40 50 100)],
                default       =>'20',
                dataobjattr   =>'user.pagelimit'),

      new kernel::Field::Email(
                name          =>'email',
                label         =>'E-Mail',
                dataobjattr   =>'user.email'),

      new kernel::Field::Text(
                name          =>'posix',
                label         =>'POSIX-Identifier',
                group         =>'userro',
                readonly      =>1,
                dataobjattr   =>'user.posix_identifier'),

      new kernel::Field::Select(
                name          =>'winsize',
                label         =>'Window-Size',
                htmleditwidth =>'50%',
                group         =>'userparam',
                value         =>['','normal','large'],
                container     =>'options'),

      new kernel::Field::Boolean(
                name          =>'allowifupdate',
                group         =>'userparam',
                label         =>'allow automatic updates by interfaces',
                dataobjattr   =>'user.allowifupdate'),

      new kernel::Field::Container(
                name          =>'options',
                dataobjattr   =>'user.options'),

      new kernel::Field::File(
                name          =>'picture',
                label         =>'picture',
                group         =>'picture',
                dataobjattr   =>'user.picture'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'userro',
                label         =>'Creator',
                dataobjattr   =>'user.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'userro',
                label         =>'Owner',
                dataobjattr   =>'user.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'userro',
                label         =>'Editor',
                dataobjattr   =>'user.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'userro',
                label         =>'RealEditor',
                dataobjattr   =>'user.realeditor'),

      new kernel::Field::CDate(
                name          =>'cdate',
                label         =>'Creation-Date',
                group         =>'userro',
                dataobjattr   =>'user.createdate'),
                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                label         =>'Modification-Date',
                group         =>'userro',
                dataobjattr   =>'user.modifydate'),

      new kernel::Field::Date(
                name          =>'lastlogon',
                group         =>'userro',
                searchable    =>0,
                depend        =>["accounts"],
                onRawValue    =>\&getLastLogon,
                label         =>'Last-Logon'),

      new kernel::Field::Text(
                name          =>'lastlang',
                group         =>'userro',
                depend        =>["accounts"],
                onRawValue    =>\&getLastLogon,
                searchable    =>0,
                label         =>'Last-Lang'),

      new kernel::Field::SubList(
                name          =>'groups',
                label         =>'Groups',
                group         =>'groups',
                subeditmsk    =>'subedit.user',
                allowcleanup  =>1,
                vjointo       =>'base::lnkgrpuser',
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>['group','roles'],
                vjoininhash   =>['group','grpid','roles']),

      new kernel::Field::SubList(
                name          =>'roles',
                label         =>'Roles',
                group         =>'roles',
                htmldetail    =>'0',
                subeditmsk    =>'subedit.user',
                vjointo       =>'base::lnkgrpuser',
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>['lineroles'],
                vjoininhash   =>['lineroles']),

      new kernel::Field::SubList(
                name          =>'usersubst',
                label         =>'Substitiutions',
                allowcleanup  =>1,
                group         =>'usersubst',
                subeditmsk    =>'subedit.user',
                vjointo       =>'base::usersubst',
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>['dstaccount','active','cdate']),

      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'comments', 
                label         =>'Comments',
                dataobjattr   =>'user.comments'),

   );
   $self->{CI_Handling}={uniquename=>"fullname",
                         uniquesize=>255};
   $self->setWorktable("user");
   $self->LoadSubObjs("user");
   $self->setDefaultView(qw(fullname cistatus usertyp));
   return($self);
}

sub getLastLogon
{
   my $self=shift;
   my $current=shift;
   my $name=$self->Name();
   my $userid=$current->{userid};
   if (!defined($self->getParent->Context->{LogonData}->{$userid})){
      my $accounts=$self->getParent->getField("accounts");
      my $l=$accounts->RawValue($current);
      my @accounts=grep(!/^\s*$/,map({$_->{account}} @$l));
      return(undef) if ($#accounts==-1);
      my $ul=$self->getParent->getPersistentModuleObject("ul",
                                                         "base::userlogon");
      $ul->SetFilter({account=>\@accounts});
      $ul->Limit(1);
      my ($ulrec,$msg)=$ul->getOnlyFirst(qw(logondate lang));
      if (defined($ulrec)){
         $self->getParent->Context->{LogonData}->{$userid}=$ulrec;
      }
   }
   if (defined($self->getParent->Context->{LogonData}->{$userid})){
      my $ulrec=$self->getParent->Context->{LogonData}->{$userid};
      return($ulrec->{logondate}) if ($name eq "lastlogon");
      return($ulrec->{lang}) if ($name eq "lastlang");
   }
   return("");
}



sub FrontendInitialize
{
   my $self=shift;
   $self->AddOperator("mailsend",
      new base::workflow::mailsend(to=>['email'],
                                   subject=>'Testmail',
                                   cc=>'xx@y',
                                   bcc=>'yy@cc',
                                   from=>'yy@cc',
                                   data=>'xxxx...',
                                   attachment=>\&new,
                                   )
   );
   $self->AddOperator("mailsendfifi",
      new base::workflow::mailsend(to=>"null\@null.com",
                                   subject=>'Testmail',
                                   cc=>'xx@y',
                                   bcc=>'yy@cc',
                                   from=>'yy@cc',
                                   data=>'xxxx...',
                                   attachment=>\&new,
                                   )
   );

   return($self->SUPER::FrontendInitialize());
}



sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $wrgroups=shift;

   my $usertyp=effVal($oldrec,$newrec,"usertyp");
   if (!$self->IsMemberOf("admin")){
      if (!defined($oldrec)){
         if ($usertyp eq "" || $usertyp eq "user"){
            $self->LastMsg(ERROR,"you are not autorized to create these ".
                                 "usertyp");
            return(0);
         }
      }
   }
   my $userid=$self->getCurrentUserId();
   if (defined($oldrec) && $oldrec->{userid}==$userid){
      delete($newrec->{cistatusid});
   }
   else{
      if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
         return(0);
      }
   }
   return($self->SUPER::SecureValidate($oldrec,$newrec,$wrgroups));
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $cistatusid=effVal($oldrec,$newrec,"cistatusid");
   if (!defined($cistatusid)){
      $newrec->{cistatusid}=1;
   } 
   my $usertyp=effVal($oldrec,$newrec,"usertyp");
   $newrec->{surname}="FMB" if ($usertyp eq "function");
   if ($usertyp eq "service"){
      $newrec->{givenname}="";
   }
   if ((defined($newrec->{surname}) ||
        defined($newrec->{givenname}) ||
        defined($newrec->{email}) ||
        !defined($oldrec))){
      my $fullname="";
      my $givenname=effVal($oldrec,$newrec,"givenname");
      my $surname=effVal($oldrec,$newrec,"surname");
      my $email=effVal($oldrec,$newrec,"email");
      $fullname.=$surname;
      $fullname.=", " if ($fullname ne "" && $givenname ne "");
      $fullname.=$givenname;
      if ($email ne ""){
         $email=" (".$email.")" if ($fullname ne "");
         $fullname.=$email;
      }
      $newrec->{fullname}=$fullname;
   }
   if (effVal($oldrec,$newrec,"fullname")=~m/^\s*$/){
      $self->LastMsg(ERROR,"invalid fullname");
      return(0);
   }
   if ($usertyp eq "service"){
      my $email=effVal($oldrec,$newrec,"email");
      $newrec->{fullname}="service: ".$newrec->{fullname};
   }
   my $fullname=effVal($oldrec,$newrec,"fullname");
   msg(INFO,"fullname=$fullname");
   if ($fullname eq ""){
      $self->LastMsg(ERROR,"invalid given or resulted fullname");
      return(0);
   }
   if (defined($newrec->{posix})){
      $newrec->{posix}=undef if ($newrec->{posix} eq "");
      if (my $posix=effVal($oldrec,$newrec,"posix")){
         if (!($posix=~m/^[a-z,0-9,_,-]+$/)){
            $self->LastMsg(ERROR,"invalid posix identifier specified");
            return(0); 
         }
      }
   }
   if (defined($newrec->{email})){
      $newrec->{email}=undef if ($newrec->{email} eq "");
   }
   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   if (exists($newrec->{picture})){
      if ($newrec->{picture} ne ""){
         no strict;
         my $f=$newrec->{picture};
         seek($f,0,SEEK_SET);
         my $pic;
         my $buffer;
         my $size=0;
         while (my $bytesread=read($f,$buffer,1024)) {
            $pic.=$buffer;
            $size+=$bytesread;
            if ($size>10240){
               $self->LastMsg(ERROR,"picure to large");
               return(0);
            }
         }
         $newrec->{picture}=$pic;
      }
      else{
         $newrec->{picture}=undef;
      }
   }


   return(1);
}

sub FinishWrite
{  
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   $self->InvalidateCache($oldrec) if (defined($oldrec));
   $self->ValidateUserCache();
   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   return(1);
}

sub InvalidateCache
{
   my $self=shift;
   my $oldrec=shift;
   if (ref($oldrec->{accounts}) eq "ARRAY"){
      foreach my $rec (@{$oldrec->{accounts}}){
         $self->InvalidateUserCache($rec->{account});
      }
   }
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default","header") if (!defined($rec));
   my @pic;
   my $userid=$self->getCurrentUserId();
   #if ($userid eq $rec->{userid} || $self->IsMemberOf("admin")){
   #   push(@pic,"picture");
   #}
   if ($self->IsMemberOf("admin")){
      push(@pic,"picture","roles");
   }
   if ($rec->{usertyp} eq "extern"){
      return(qw(header name default comments userro office private));
   }  
   if ($rec->{usertyp} eq "function"){
      if ($self->IsMemberOf("admin")){
         return(qw(header name default comments userro));
      }
     return(qw(header name default comments));
   }  
   if ($rec->{usertyp} eq "service"){
      return(qw(header name default comments groups usersubst userro userparam));
   }  
   return(@pic,
          qw(default name office private userparam groups userro usersubst 
             header));
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if (!defined($rec));
   return(undef) if (!defined($rec));
   if ($self->IsMemberOf("admin")){
      return(qw(default name office private userparam groups usersubst 
                comments header picture));
   }
   my $userid=$self->getCurrentUserId();
   if ($userid eq $rec->{userid} ||
       ($rec->{creator}==$userid && $rec->{cistatusid}<3)){
      return("name","userparam","office","private","usersubst");
   }
   return(undef);
}

sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();

   return(1) if ($rec->{creator}==$userid && $rec->{cistatusid}<3);

   return(1) if ($self->IsMemberOf("admin"));
   return(0);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $rec=shift;
   my $userid="user";
   if (defined($rec)){
      $userid=$rec->{userid} if ($rec->{userid} ne "");
   }
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/userpic/$userid.jpg?".$cgi->query_string());
}



sub ValidateDelete
{
   my $self=shift;
   my $rec=shift;

   return(1);
}

sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;
   $self->InvalidateCache($oldrec) if (defined($oldrec));
   if (!$self->HandleCIStatus($oldrec,undef,%{$self->{CI_Handling}})){
      return(0);
   }
   my $infoabo=getModuleObject($self->Config,"base::infoabo");
   if (defined($infoabo)){
      my $idname=$self->IdField->Name();
      my $id=$oldrec->{$idname};
      $infoabo->SetFilter({'userid'=>\$id});
      $infoabo->SetCurrentView(qw(ALL));
      $infoabo->ForeachFilteredRecord(sub{
                         $infoabo->ValidatedDeleteRecord($_);
                      });
   }
   return($self->SUPER::FinishDelete($oldrec));
}

sub getValidWebFunctions
{  
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(), qw(MyDetail)); 
}

sub MyDetail
{
   my ($self)=@_;
   my $userid="?";
   my $UserCache=$self->Cache->{User}->{Cache};
   if (defined($UserCache->{$ENV{REMOTE_USER}})){
      $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
   }
   if (defined($UserCache->{userid})){
      $userid=$UserCache->{userid};
   }
   Query->Param("userid"=>$userid);
   return($self->Detail());
}


sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","name","picture","default","office","private",
          "userparam","groups");
}


#sub isQualityCheckValid
#{
#   return(1);
#}





1;
