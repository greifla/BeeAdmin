package itil::workflow::eventnotify;
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
use kernel::WfClass;
@ISA=qw(kernel::WfClass);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{history}=[qw(insert modify delete)];

   return($self);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/workflow-diary.jpg?".$cgi->query_string());
}

sub Init
{  
   my $self=shift;

   $self->AddGroup("eventnotifystat",
                   translation=>'itil::workflow::eventnotify');
   $self->AddGroup("eventnotifyinternal",
                   translation=>'itil::workflow::eventnotify');
   $self->AddGroup("eventnotify",
                   translation=>'itil::workflow::eventnotify');
   $self->AddGroup("alteventnotify",
                   translation=>'itil::workflow::eventnotify');
   $self->AddGroup("eventnotifyshort",
                   translation=>'itil::workflow::eventnotify');

   return(1);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (defined($oldrec) && $oldrec->{eventstatnature} ne "" &&
       exists($newrec->{eventstatnature}) &&
       $newrec->{eventstatnature} eq ""){
      $self->LastMsg(ERROR,"can't clear eventstatnature from defined state");
      return(0);
   }


   return($self->SUPER::Validate($oldrec,$newrec));
}


sub ValidateCreate
{
   my $self=shift;
   my $newrec=shift;
   return(1);
}
sub getDynamicFields
{  
   my $self=shift;
   my %param=@_;
   my $class;

   return($self->InitFields(
      new kernel::Field::Date(
                name          =>'eventstartofevent',
                translation   =>'itil::workflow::eventnotify',
                group         =>'eventnotifyshort',
                label         =>'Event Start',
                alias         =>'eventstart'),

      new kernel::Field::Date(    
                name          =>'eventendexpected',
                translation   =>'itil::workflow::eventnotify',
                group         =>'eventnotifyshort',
                label         =>'expected event end',
                container     =>'headref'),

      new kernel::Field::Date(
                name          =>'eventendofevent',
                translation   =>'itil::workflow::eventnotify',
                group         =>'eventnotifyshort',
                label         =>'Event End',
                alias         =>'eventend'),

      new kernel::Field::KeyText( 
                name          =>'affectedapplication',
                translation   =>'itil::workflow::base',
                vjointo       =>'itil::appl',
                vjoinon       =>['affectedapplicationid'=>'id'],
                vjoindisp     =>'name',
                keyhandler    =>'kh',
                container     =>'headref',
                group         =>'eventnotifyshort',
                depend        =>['eventmode'],
                uivisible     =>\&calcVisibility,
                label         =>'Affected Application'),

      new kernel::Field::KeyText( 
                name          =>'affectedapplicationid',
                htmldetail    =>0,
                translation   =>'itil::workflow::base',
                searchable    =>0,
                keyhandler    =>'kh',
                container     =>'headref',
                group         =>'eventnotifyshort',
                uivisible     =>\&calcVisibility,
                depend        =>['eventmode'],
                label         =>'Affected Application ID'),

      new kernel::Field::KeyText( 
                name          =>'affectedlocation',
                translation   =>'itil::workflow::base',
                vjointo       =>'base::location',
                vjoinon       =>['affectedlocationid'=>'id'],
                vjoindisp     =>'name',
                keyhandler    =>'kh',
                container     =>'headref',
                group         =>'eventnotifyshort',
                uivisible     =>\&calcVisibility,
                depend        =>['eventmode'],
                label         =>'Affected Location'),

      new kernel::Field::KeyText( 
                name          =>'affectedlocationid',
                htmldetail    =>0,
                translation   =>'itil::workflow::base',
                searchable    =>0,
                keyhandler    =>'kh',
                container     =>'headref',
                group         =>'eventnotifyshort',
                uivisible     =>\&calcVisibility,
                depend        =>['eventmode'],
                label         =>'Affected Location ID'),

      new kernel::Field::Select(
                name          =>'affectedroom',
                translation   =>'itil::workflow::base',
                container     =>'headref',
                group         =>'eventnotifyshort',
                getPostibleValues=>\&calcRooms,
                multisize     =>10,
                uivisible     =>\&calcVisibility,
                depend        =>['eventmode'],
                label         =>'Affected Room'),

      new kernel::Field::Select(  
                name          =>'affectednetwork',
                vjointo       =>'itil::network',
                vjoindisp     =>'name',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['affectednetworkid'=>'id'],
                group         =>'eventnotifyshort',
                uivisible     =>\&calcVisibility,
                depend        =>['eventmode'],
                label         =>'Networkarea'),

      new kernel::Field::Link(
                name          =>'affectednetworkid',
                container     =>'headref',
                label         =>'NetworkareaID'),

      new kernel::Field::KeyText(  
                name          =>'affectedbusinessprocess',
                vjointo       =>'itil::businessprocess',
                vjoindisp     =>'selector',
                keyhandler    =>'kh',
                container     =>'headref',
                multiple      =>0,
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['affectedbusinessprocessid'=>'id'],
                group         =>'eventnotifyshort',
                uivisible     =>\&calcVisibility,
                depend        =>['eventmode'],
                label         =>'Businessprocess'),

      new kernel::Field::Text(  
                name          =>'affectedbusinessprocessname',
                container     =>'headref',
                multiple      =>0,
                group         =>'eventnotifyshort',
                uivisible     =>\&calcVisibility,
                htmldetail    =>0,
                depend        =>['eventmode'],
                label         =>'Businessprocess label'),

      new kernel::Field::Text(
                name          =>'affecteditemprio',
                container     =>'headref',
                group         =>'eventnotifyshort',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       exists($param{current}->{affecteditemprio})){
                      my $o=$self->getParent->getField("affecteditemprio");
                      my $d=$param{current}->{affecteditemprio};
                      return(1) if ($d ne "");
                   }
                   return(0);
                },
                searchable    =>0,
                label         =>'Affected Item Prio'),

      new kernel::Field::Select(
                name          =>'affectedregion',
                translation   =>'itil::workflow::eventnotify',
                container     =>'headref',
                value         =>[qw( 
                                     EVregion.unknown
                                     EVregion.nord
                                     EVregion.sued
                                     EVregion.ost
                                     EVregion.west
                                     EVregion.germany
                                     EVregion.internet
                                 )],
                group         =>'eventnotifyshort',
                uivisible     =>\&calcVisibility,
                depend        =>['eventmode'],
                label         =>'Affected Region'),

      new kernel::Field::KeyText( 
                name          =>'affectedcustomer',
                translation   =>'itil::workflow::base',
                vjointo       =>'base::grp',
                vjoinon       =>['affectedcustomerid'=>'grpid'],
                vjoindisp     =>'name',
                keyhandler    =>'kh',
                container     =>'headref',
                uivisible     =>\&calcVisibility,
                group         =>'affected',
                label         =>'Affected Customer'),

      new kernel::Field::KeyText( 
                name          =>'affectedcustomerid',
                htmldetail    =>0,
                searchable    =>0,
                translation   =>'itil::workflow::base',
                keyhandler    =>'kh',
                container     =>'headref',
                group         =>'affected',
                uivisible     =>\&calcVisibility,
                label         =>'Affected Customer ID'),

      new kernel::Field::Textarea(
                name          =>'eventdesciption',
                translation   =>'itil::workflow::eventnotify',
                group         =>'eventnotify',
                label         =>'Whats happend',
                alias         =>'detaildescription'),

      new kernel::Field::Textarea(
                name          =>'eventreason',
                translation   =>'itil::workflow::eventnotify',
                group         =>'eventnotify',
                label         =>'Event reason',
                container     =>'headref'),

      new kernel::Field::Textarea(
                name          =>'eventimpact',
                translation   =>'itil::workflow::eventnotify',
                group         =>'eventnotify',
                label         =>'Impact for customer',
                container     =>'headref'),

      new kernel::Field::Textarea(
                name          =>'shorteventelimination',
                xlswidth      =>'45',
                translation   =>'itil::workflow::eventnotify',
                group         =>'eventnotify',
                label         =>'Action for short event elimination',
                container     =>'headref'),

      new kernel::Field::Textarea(
                name          =>'longeventelimination',
                xlswidth      =>'45',
                translation   =>'itil::workflow::eventnotify',
                group         =>'eventnotify',
                label         =>'Action for long event elimination',
                container     =>'headref'),

      new kernel::Field::Textarea(
                name          =>'eventaltdesciption',
                dlabelpref    =>\&LangPrefix,
                translation   =>'itil::workflow::eventnotify',
                group         =>'alteventnotify',
                label         =>'Whats happend',
                container     =>'headref'),

      new kernel::Field::Textarea(
                name          =>'eventaltreason',
                dlabelpref    =>\&LangPrefix,
                translation   =>'itil::workflow::eventnotify',
                group         =>'alteventnotify',
                label         =>'Event reason',
                container     =>'headref'),

      new kernel::Field::Textarea(
                name          =>'eventaltimpact',
                dlabelpref    =>\&LangPrefix,
                translation   =>'itil::workflow::eventnotify',
                group         =>'alteventnotify',
                label         =>'Impact for customer',
                container     =>'headref'),

      new kernel::Field::Textarea(
                name          =>'altshorteventelimination',
                dlabelpref    =>\&LangPrefix,
                translation   =>'itil::workflow::eventnotify',
                group         =>'alteventnotify',
                label         =>'Action for short event elimination',
                container     =>'headref'),

      new kernel::Field::Textarea(
                name          =>'altlongeventelimination',
                dlabelpref    =>\&LangPrefix,
                translation   =>'itil::workflow::eventnotify',
                group         =>'alteventnotify',
                label         =>'Action for long event elimination',
                container     =>'headref'),

      new kernel::Field::Select(
                name          =>'eventlang',
                translation   =>'itil::workflow::eventnotify',
                group         =>'eventnotifyinternal',
                default       =>'de',
                value         =>['de','de-en','en-de','en'],
                htmleditwidth =>'150px',
                label         =>'Event notification language',
                container     =>'headref'),

      new kernel::Field::Select(
                name          =>'eventsla',
                translation   =>'itil::workflow::eventnotify',
                group         =>'eventnotifyinternal',
                transprefix   =>'boolean.',
                htmleditwidth =>'150px',
                default       =>'0',
                value         =>['0','1'],
                label         =>'Event is in SLA online time',
                container     =>'headref'),

      new kernel::Field::Text(
                name          =>'eventstaticmailsubject',
                xlswidth      =>'15',
                translation   =>'itil::workflow::eventnotify',
                group         =>'eventnotifyinternal',
                label         =>'static mail subject',
                container     =>'headref'),

      new kernel::Field::TextDrop(
                name          =>'eventstaticemailgroup',
                label         =>'static additional notify distribution list',
                AllowEmpty    =>1,
                group         =>'eventnotifyinternal',
                vjointo       =>'base::grp',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['eventstaticemailgroupid'=>'grpid'],
                vjoindisp     =>'fullname',
                altnamestore  =>'eventstaticemailgroupname'),

      new kernel::Field::Link (
                name          =>'eventstaticemailgroupid',
                group         =>'eventnotifyinternal',
                container     =>'headref'),

      new kernel::Field::Link (
                name          =>'eventstaticemailgroupname',
                group         =>'eventnotifyinternal',
                container     =>'headref'),

      new kernel::Field::Textarea(
                name          =>'eventinternalslacomments',
                translation   =>'itil::workflow::eventnotify',
                group         =>'eventnotifyinternal',
                label         =>'Arguments, if not SLA relevant',
                container     =>'headref'),

      new kernel::Field::Textarea(
                name          =>'eventinternalcomments',
                translation   =>'itil::workflow::eventnotify',
                group         =>'eventnotifyinternal',
                label         =>'Internal comments',
                container     =>'headref'),

      new kernel::Field::Select(
                name          =>'eventstatnature',
                translation   =>'itil::workflow::eventnotify',
                group         =>'eventnotifystat',
                value         =>['',
                                 'EVn.info',
                                 'EVn.performance',
                                 'EVn.partial',
                                 'EVn.totalfail'],
                label         =>'Event nature',
                container     =>'headref'),

      new kernel::Field::Select(
                name          =>'eventstattype',
                translation   =>'itil::workflow::eventnotify',
                group         =>'eventnotifystat',
                getPostibleValues=>\&FgetPosibleEventStatType,
                label         =>'Event type',
                container     =>'headref'),

      new kernel::Field::Select(
                name          =>'eventstatreason',
                translation   =>'itil::workflow::eventnotify',
                group         =>'eventnotifystat',
                value         =>['',
                                 'EVr.application',
                                 'EVr.changetsi',
                                 'EVr.changecust',
                                 'EVr.architecture',
                                 'EVr.reseller',
                                 'EVr.thirdparty',
                                 'EVr.interface',
                                 'EVr.technically',
                                 'EVr.hardwaredef',
                                 'EVr.human',
                                 'EVr.humanuser',
                                 'EVr.inanalyse',
                                 'EVr.other'],
                label         =>'Event reason',
                container     =>'headref'),

      new kernel::Field::Select(
                name          =>'eventstatclass',
                translation   =>'itil::workflow::eventnotify',
                group         =>'eventnotifystat',
                label         =>'Event class',
                default       =>'1',
                htmleditwidth =>'100px',
                value         =>['1',
                                 '2',
                                 '3',
                                 '4',
                                 '5'],
                container     =>'headref'),

      new kernel::Field::Select(
                name          =>'eventmode',
                translation   =>'itil::workflow::eventnotify',
                group         =>'state',
                value         =>['EVk.appl',
                                 'EVk.net',
                                 'EVk.bprocess',
                                 'EVk.infraloc'],
                label         =>'Eventnotification Mode',
                container     =>'headref'),

      new kernel::Field::Link (
                name          =>'initiatorgroupid',
                container     =>'headref'),

      new kernel::Field::Text (
                name          =>'initiatorgroup',
                htmldetail    =>0,
                searchable    =>0,
                container     =>'headref'),
   ));
}

sub getPosibleEventStatType
{
   my $self=shift;
   my @l;

   foreach my $int ('',
                    qw(EVt.application EVt.database EVt.middleware EVt.os
                       EVt.hardware EVt.human EVt.hardware-st 
                       EVt.infrastructure EVt.inanalyse EVt.other
                       EVt.unknown)){
      push(@l,$int,$self->getParent->T($int,$self->{translation}));
   }

   return(@l);
}

sub getAdditionalMainButtons
{
   my $self=shift;
   my $WfRec=shift;
   return("");
}

sub AdditionalMainProcess
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   return(-1);
}

sub FgetPosibleEventStatType
{
   my $self=shift;
   return($self->getParent->getPosibleEventStatType(@_));
}

sub LangPrefix
{
   my $self=shift;
   my %param=@_;
   my $pref="";
   if (defined($param{current})){
      if (defined($param{current}->{eventlang}) &&
          $param{current}->{eventlang}=~m/-/){
         my ($altlang)=$param{current}->{eventlang}=~m/^.*-(.*)$/;
         return($altlang.": ");
      }
   }

   return($pref);
}


sub calcVisibility
{
   my $self=shift;
   my $mode=shift;
   my %param=@_;
   my $rec=$param{current};
   my $name=$self->Name();

   return(1) if (!defined($rec));
   if ($rec->{headref}->{eventmode}->[0] eq "EVk.infraloc"){
      return(1) if ($name eq "affectedlocation");
      return(1) if ($name eq "affectedlocationid");
      return(1) if ($name eq "affectedroom");
   }
   if ($rec->{headref}->{eventmode}->[0] eq "EVk.appl"){
      return(1) if ($name eq "affectedapplication");
      return(1) if ($name eq "affectedapplicationid");
      return(1) if ($name eq "affectedcustomer");
      return(1) if ($name eq "affectedcustomerid");
   }
   if ($rec->{headref}->{eventmode}->[0] eq "EVk.net"){
      return(1) if ($name eq "affectednetwork");
      return(1) if ($name eq "affectednetworkid");
      return(1) if ($name eq "affectedregion");
   }
   if ($rec->{headref}->{eventmode}->[0] eq "EVk.bprocess"){
      return(1) if ($name eq "affectedbusinessprocess");
   }
   return(0);
}

sub activateMailSend
{
   my $self=shift;
   my $WfRec=shift;
   my $wf=shift;
   my $id=shift;
   my $newmailrec=shift;
   my $action=shift;

   my %d=(step=>'base::workflow::mailsend::waitforspool',
          emailsignatur=>'EventNotification');
   $self->linkMail($WfRec->{id},$id);
   if (my $r=$wf->Store($id,%d)){
      return(1);
   }
   return(0);
}

sub calcRooms
{
   my $self=shift;
   my $rec=shift;
   my $mode=shift;
   my %room=();
   if (defined($rec)){
      my @l;
      foreach my $room (@{$rec->{headref}->{affectedroom}}){
         $room{$room}=1;
      }
   }
   foreach my $q (Query->Param("Formated_affectedroom")){
       $room{$q}=1 if ($q ne "");
   }
   $room{'*'}=1;
   my $locationid=Query->Param("Formated_affectedlocationid");
   my $asset=getModuleObject($self->getParent->Config,"itil::asset");
   $asset->SetFilter({locationid=>\$locationid});
   my @roomrec=$asset->getHashList(qw(DISTINCT room));
   foreach my $roomrec (@roomrec){
      $room{$roomrec->{room}}=1 if ($roomrec->{room} ne "");
   }
   my @l;
   map({push(@l,$_,$_)} sort(keys(%room)));

   return(@l);
}



sub IsModuleSelectable
{
   my $self=shift;
   my $acl;

   $acl=$self->getParent->getMenuAcl($ENV{REMOTE_USER},
                          "base::workflow",
                          func=>'New',
                          param=>'WorkflowClass=itil::workflow::eventnotify');
   if (defined($acl)){
      return(1) if (grep(/^read$/,@$acl));
   }
   return(1) if ($self->getParent->IsMemberOf("admin"));
   return(0);
}

sub InitWorkflow
{
   my $self=shift;
   return(undef);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getParent->getCurrentUserId();
   my @grps=qw(state header eventnotifystat eventnotify 
               eventnotifyshort);
   my $fo=$self->getField("wffields.eventlang",$rec);
   if (defined($fo)){
      my $lang=$fo->RawValue($rec);
      if ($lang=~m/-/){
         push(@grps,"alteventnotify");
      }
   }

   my %inmmgr=$self->getGroupsOf($userid,'RINManager','both');

   # if (is in mandator)
   my $mandators=$rec->{mandatorid};
   $mandators=[$rec->{mandatorid}] if (!ref($rec->{mandatorid}) eq "ARRAY");
   my $mandatorok=0;
   my @mymandators=$self->getMandatorsOf($ENV{REMOTE_USER},"direct"); 
   push(@mymandators,keys(%inmmgr));
   foreach my $mid (@$mandators){
      if (grep(/^$mid$/,@mymandators)){
         $mandatorok=1;
         last;
      }
   }
   if ($mandatorok || $rec->{owner}==$userid){
      push(@grps,"eventnotifyinternal","affected");
      push(@grps,"history"); # maybe
      push(@grps,"relations"); # maybe
      push(@grps,"flow"); # maybe
   }

#printf STDERR ("fifi mandators=%s\n",Dumper($rec->{mandatorid}));
#printf STDERR ("fifi mymandators=%s\n",Dumper(\@mymandators));

   return(@grps);
}

sub getDetailBlockPriority                # posibility to change the block order
{  
   my $self=shift;
   return("eventnotifyshort","eventnotify","alteventnotify","eventnotifystat",
          "eventnotifyinternal","flow","affected","relations","state");
}


sub isWriteValid
{
   my $self=shift;
   my $WfRec=shift;
   return(1) if (!defined($WfRec));
   my @grplist=("eventnotify","alteventnotify","eventnotifystat",
             "eventnotifyinternal","relations");

   my $teammember=0;
   if (defined($WfRec->{initiatorgroupid})){
      my $gid=$WfRec->{initiatorgroupid};
      if (ref($gid) ne "ARRAY"){
         $gid=[$gid];
      }
      @$gid=grep(!/^\s*$/,@$gid);
      if ($#{$gid}!=-1){
         my %groups=$self->getGroupsOf($ENV{REMOTE_USER},
                                       [qw(REmployee RApprentice RFreelancer 
                                           RBoss RBoss2)],'direct');
         foreach my $mygid (keys(%groups)){
            if (grep(/^$mygid$/,@$gid)){
               $teammember++;
            }
         }
      }
   }



   if (($WfRec->{state}<=20 &&
       $self->getParent->getCurrentUserId()==$WfRec->{openuser}) ||
        $self->IsIncidentManager($WfRec) ||
        $teammember!=0 ||
        $self->getParent->IsMemberOf("admin")){
      return(@grplist);
   }
   return(undef);
}

sub getStepByShortname
{
   my $self=shift;
   my $shortname=shift;
   my $WfRec=shift;

   return("itil::workflow::eventnotify::".$shortname);
}

sub isMarkDeleteValid
{
   my $self=shift;
   my $WfRec=shift;
   if ($self->getParent->IsMemberOf("admin") || 
       $self->IsIncidentManager($WfRec)){
      return(1);
   }

   return(0);
}


sub getNextStep
{
   my $self=shift;
   my $currentstep=shift;
   my $WfRec=shift;

   if($currentstep eq "itil::workflow::eventnotify::finish"){
      return($self->getStepByShortname("finish",$WfRec)); 
   }
   elsif($currentstep=~m/^.*::workflow::eventnotify::askmode$/){
      my $mode=Query->Param("Formated_eventmode");
      if ($mode eq "EVk.infraloc"){
         return($self->getStepByShortname("askloc",$WfRec)); 
      }
      if ($mode eq "EVk.appl"){
         return($self->getStepByShortname("askappl",$WfRec)); 
      }
      if ($mode eq "EVk.net"){
         return($self->getStepByShortname("asknet",$WfRec)); 
      }
      if ($mode eq "EVk.bprocess"){
         return($self->getStepByShortname("askbprocess",$WfRec)); 
      }
      return(undef);
   }
   elsif($currentstep=~m/^.*::workflow::eventnotify::askloc$/){
      return($self->getStepByShortname("askroom",$WfRec)); 
   }
   elsif($currentstep=~m/^.*::workflow::eventnotify::askroom$/){
      return($self->getStepByShortname("dataload",$WfRec)); 
   }
   elsif($currentstep=~m/^.*::workflow::eventnotify::askappl$/){
      return($self->getStepByShortname("dataload",$WfRec)); 
   }
   elsif($currentstep=~m/^.*::workflow::eventnotify::asknet$/){
      return($self->getStepByShortname("dataload",$WfRec)); 
   }
   elsif($currentstep=~m/^.*::workflow::eventnotify::askbprocess$/){
      return($self->getStepByShortname("dataload",$WfRec)); 
   }
   elsif($currentstep=~m/^.*::workflow::eventnotify::copydata$/){
      return($self->getStepByShortname("main",$WfRec)); 
   }
   elsif($currentstep=~m/^.*::workflow::eventnotify::dataload$/){
      return($self->getStepByShortname("main",$WfRec)); 
   }
   elsif($currentstep=~m/^.*::workflow::eventnotify::sendcustinfo$/){
      return($self->getStepByShortname("main",$WfRec)); 
   }
   elsif($currentstep=~m/^.*::workflow::eventnotify::sendmgmtinfo$/){
      return($self->getStepByShortname("main",$WfRec)); 
   }
   elsif($currentstep eq ""){
      return($self->getStepByShortname("askmode",$WfRec)); 
   }
   return(undef);
}

sub isOptionalFieldVisible
{
   my $self=shift;
   my $mode=shift;
   my %param=@_;
   my $name=$param{field}->Name();

   return(1) if ($name eq "relations");
   return(1) if ($name eq "prio");
   return(1) if ($name eq "name");
   return(1) if ($name eq "shortactionlog");
   return(1) if ($name eq "detaildescription");
   return(0);
}

sub getPosibleRelations
{
   my $self=shift;
   my $WfRec=shift;
   return("itil::workflow::eventnotify"=>'consequenceof',
          "itil::workflow::eventnotify"=>'info');
}


sub IsIncidentManager
{
   my $self=shift;
   my $WfRec=shift;
   my $mandator=$WfRec->{mandatorid};
   $mandator=[$mandator] if (!ref($mandator) eq "ARRAY");
   return(1) if ($self->getParent->IsMemberOf($mandator,"RINManager","down"));
   return(1) if ($self->getParent->IsMemberOf("admin"));
   if (defined($WfRec->{affectedapplicationid}) &&
       ref($WfRec->{affectedapplicationid}) eq "ARRAY" &&
       $#{$WfRec->{affectedapplicationid}}!=-1){
      my $appl=$self->getParent->getPersistentModuleObject("itil::appl");
      $appl->ResetFilter();
      $appl->SetFilter({id=>$WfRec->{affectedapplicationid}});
      foreach my $ag ($appl->getHashList(qw(businessteamid))){
         if ($ag->{businessteamid}!=0 &&
             $self->getParent->IsMemberOf($ag->{businessteamid},
                                          "RINManager","down")){
            return(1);
         }
      }
   }




   return(0);
}

sub getPosibleActions
{
   my $self=shift;
   my $WfRec=shift;
   my $app=$self->getParent;
   my $userid=$self->getParent->getCurrentUserId();
   my @l=();


   my $teammember=0;
   if (defined($WfRec->{initiatorgroupid})){
      my $gid=$WfRec->{initiatorgroupid};
      if (ref($gid) ne "ARRAY"){
         $gid=[$gid];
      }
      @$gid=grep(!/^\s*$/,@$gid);
      if ($#{$gid}!=-1){
         my %groups=$self->getGroupsOf($ENV{REMOTE_USER},
                                       [qw(REmployee RApprentice RFreelancer 
                                           RBoss RBoss2)],'direct');
         foreach my $mygid (keys(%groups)){
            if (grep(/^$mygid$/,@$gid)){
               $teammember++;
            }
         }
      }
   }


   if (($WfRec->{state}<21 && 
       $WfRec->{openuser}==$userid) || 
       $teammember!=0 || 
        $self->IsIncidentManager($WfRec) ||
        $self->getParent->IsMemberOf(["admin","admin.workflow"])){
      push(@l,"addnote");
      push(@l,"timemod");
      if ($WfRec->{eventend} ne ""){
         push(@l,"wfclose");
      }
   }
   if ($WfRec->{state}>=21){
      if (
       # $self->IsIncidentManager($WfRec) ||
          $self->getParent->IsMemberOf(["admin","w5base.workflow.admin"])){
         push(@l,"reactivate");
      }
   }
   push(@l,"sendcustinfo") if ($self->IsIncidentManager($WfRec));
   msg(INFO,"valid operations=%s",join(",",@l));

   return(@l);
}

sub allowAutoScroll
{
   return(0);
}


sub isCopyValid
{
   my $self=shift;
   my $WfRec=shift;

   return($self->IsModuleSelectable());

}


sub getDetailFunctionsCode
{
   my $self=shift;
   my $rec=shift;
   my $wfclass=$self->Self();
   my $d;
   if (defined($rec)){
      my $idname=$self->IdField->Name();
      my $id=$rec->{$idname};
      $d=<<EOF;
function WorkflowCopy()
{
   custopenwin("Copy?CurrentIdToEdit=$id","",640);
}
EOF
   }
   return($self->SUPER::getDetailFunctionsCode($rec).$d);
}  

sub InitCopy
{
   my ($self,$copyfrom,$copyinit)=@_;
   
   my $appl=$copyinit->{Formated_affectedapplication};
   $copyinit->{Formated_appl}=$appl;
   $copyinit->{WorkflowStep}=[qw(itil::workflow::eventnotify::copydata)];
   $copyinit->{WorkflowClass}=$self->Self();
}


sub getNotifyDestinations
{
   my $self=shift;
   my $mode=shift;    # "custinfo" | "mgmtinfo"
   my $WfRec=shift;
   my $emailto=shift;

   if ($mode eq "custinfo"){
      my $ia=getModuleObject($self->Config,"base::infoabo");
      if ($WfRec->{eventmode} eq "EVk.appl"){ 
         my $applid=$WfRec->{affectedapplicationid};
         $applid=[$applid] if (ref($applid) ne "ARRAY");
         my $appl=getModuleObject($self->Config,"itil::appl");
         $appl->SetFilter({id=>$applid});

         # new target calculation code from itil::appl
         foreach my $rec ($appl->getHashList(qw(wfdataeventnotifytargets))){
            foreach my $email (@{$rec->{wfdataeventnotifytargets}}){
               $emailto->{$email}++;
            }
         }
      }
      elsif ($WfRec->{eventmode} eq "EVk.net"){ 
         my $netid=$WfRec->{affectednetworkid};
         $netid=[$netid] if (ref($netid) ne "ARRAY");
         my $net=getModuleObject($self->Config,"itil::network");
         $net->SetFilter({id=>$netid});
         $ia->LoadTargets($emailto,'*::network',\'eventnotify',$netid);
      }
      elsif ($WfRec->{eventmode} eq "EVk.bprocess"){ 
         my $bprocid=$WfRec->{affectedbusinessprocessid};
         $bprocid=[$bprocid] if (ref($bprocid) ne "ARRAY");
         my $bproc=getModuleObject($self->Config,"itil::businessprocess");
         $bproc->SetFilter({id=>$bprocid});
         $ia->LoadTargets($emailto,'*::businessprocess',\'eventnotify',
                          $bprocid);
         foreach my $rec ($bproc->getHashList(qw(wfdataeventnotifytargets))){
            foreach my $email (@{$rec->{wfdataeventnotifytargets}}){
               $emailto->{$email}++;
            }
         }
      }
      elsif ($WfRec->{eventmode} eq "EVk.infraloc"){ 
         my $locid=$WfRec->{affectedlocationid};
         $locid=[$locid] if (ref($locid) ne "ARRAY");
         $ia->LoadTargets($emailto,'*::location',\'eventnotify',$locid);
      }
      else{
         return(undef);
      }
   }
   if ($mode eq "mgmtinfo"){

   }
   if ($WfRec->{eventstaticemailgroupid} ne ""){
      my @mem=$self->getParent->getMembersOf($WfRec->{eventstaticemailgroupid},
                                             ['RMember']);
      my $user=getModuleObject($self->Config,"base::user");
      $user->SetFilter({userid=>\@mem,usertyp=>['user','extern']});
      $user->SetCurrentView(qw(email)); 
      my ($rec,$msg)=$user->getFirst();
      if (defined($rec)){
         do{
            $emailto->{$rec->{email}}++;
            ($rec,$msg)=$user->getNext();
         } until(!defined($rec));
      }
   }



   return(undef);
}


sub getNotifyCountLabel
{
   my $self=shift;
   my $WfRec=shift;
   my $sendcustinfocount=shift;

   my $state="Ereignis";
   if ($WfRec->{stateid} == 17){
     $state=$self->getParent->T("finish info",
                                "itil::workflow::eventnotify");
   }elsif ($sendcustinfocount > 0){
     $state=$sendcustinfocount.". ".
            $self->getParent->T("follow info",
                                "itil::workflow::eventnotify");
   }else{
     $state=$self->getParent->T("first information",
                                "itil::workflow::eventnotify");
   }
   return($state);
}


sub getNotificationSubject 
{
   my $self=shift;
   my $WfRec=shift;
   my $action=shift;
   my $sendcustinfocount=shift;
   my $subjectlabel=shift;
   my $failclass=shift;
   my $state=$self->getNotifyCountLabel($WfRec,$sendcustinfocount);

   my $afcust=$WfRec->{affectedcustomer}->[0]; # only first customer 
   my $subject="EK ".$WfRec->{eventstatclass};
   my $prio="";
   if ($WfRec->{affecteditemprio} ne ""){
      if ($WfRec->{affecteditemprio}==1){   # Aussage von Hr. Weidner
         $prio="Top ";
      }
   }
   my $subject2=" / ? / $state Incident / ".$afcust." / $prio ? /";
   if ($WfRec->{eventmode} eq "EVk.appl"){ 
      my $ag="";
      foreach my $appl (@{$WfRec->{affectedapplication}}){
         $ag.="; " if ($ag ne "");
         $ag.=$appl;
      }
      $subject2=" / $ag / $state Incident / ".$afcust." / $prio".
                $self->getParent->T("Application")." /";
   }
   if ($WfRec->{eventmode} eq "EVk.net"){ 
      $subject2=" / IP-Net / $state Incident / DTAG.T-Home / ".
                $self->getParent->T("Networkarea")." /";
   }
   if ($WfRec->{eventmode} eq "EVk.bprocess"){ 
      my $bp=$WfRec->{affectedbusinessprocess};
      if (ref($WfRec->{affectedbusinessprocess})){
         $bp=$WfRec->{affectedbusinessprocess}->[0];
      }
      $bp=~s/\@/ \/ /g;
      $subject2=" / ".$self->getParent->T("Businessprocess").
                " / $state Incident / $bp / ";
   }
   if ($WfRec->{eventmode} eq "EVk.infraloc"){ 
      my $loc=$WfRec->{affectedlocation};
      $loc=$WfRec->{affectedlocation}->[0] if (ref($WfRec->{affectedlocation}));
      $subject2=" / $loc / $state / $prio".
                $self->getParent->T("Location")." / ";
   }
   if ($action eq "rootcausei" && $WfRec->{eventmode} eq "EVk.appl"){
      my $ag="";
      foreach my $appl (@{$WfRec->{affectedapplication}}){
         $ag.="; " if ($ag ne "");
         $ag.=$appl;
      }
      $subject2=" / $ag / ".$self->getParent->T("rootcause analysis").
                " / $afcust / $prio".$self->getParent->T("Application").
                " /";
   }
   if ($action eq "rootcausei" && $WfRec->{eventmode} eq "EVk.infraloc"){
      my $loc=$WfRec->{affectedlocation};
      $loc=$WfRec->{affectedlocation}->[0] if (ref($WfRec->{affectedlocation}));
      $subject2=" / $loc / ".$self->getParent->T("rootcause analysis").
                " / $prio".$self->getParent->T("Location")." /";
   }
   if ($action eq "rootcausei" && $WfRec->{eventmode} eq "EVk.net"){
      my $net=$WfRec->{affectednetwork};
      $net=$WfRec->{affectednetwork}->[0] if (ref($WfRec->{affectednetwork}));
      $subject2=" / $net / ".$self->getParent->T("rootcause analysis").
                " / ".$self->getParent->T("Networkarea")." /";
   }
   if ($action eq "rootcausei" && $WfRec->{eventmode} eq "EVk.bprocess"){
      my $bp=$WfRec->{affectedbusinessprocess};
      if (ref($WfRec->{affectedbusinessprocess})){
         $bp=$WfRec->{affectedbusinessprocess}->[0];
      }
      $bp=~s/\@/ \/ /g;
      $subject2=" / $bp / ".$self->getParent->T("rootcause analysis").
                " / ".$self->getParent->T("Businessprocess")." /";
   }
   $subject.=$subject2;
   $subject.=" ID:".$WfRec->{id};
   return($subject);
}


sub getNotificationSkinbase
{
   my $self=shift;
   my $WfRec=shift;
   return('base');
}

sub getSalutation
{
   my $self=shift;
   my $WfRec=shift;
   my $action=shift;
   my $salutation;
   my $st;
   my $eventstat=$WfRec->{stateid};
   my $eventstart=$WfRec->{eventstartofevent};
   my $utz=$self->getParent->UserTimezone();
   my $creationtime=$self->getParent->ExpandTimeExpression(
                                                  $eventstart,"de","UTC",$utz);
   if ($WfRec->{eventmode} eq "EVk.infraloc" && $eventstat==17){
      my $loc=$WfRec->{affectedlocation};
      $loc=$WfRec->{affectedlocation}->[0] if (ref($WfRec->{affectedlocation}));
      $salutation=sprintf($self->T("SALUTATION02.close"),$loc);
   }elsif($WfRec->{eventmode} eq "EVk.infraloc"){
      my $loc=$WfRec->{affectedlocation};
      $loc=$WfRec->{affectedlocation}->[0] if (ref($WfRec->{affectedlocation}));
      $salutation=sprintf($self->T("SALUTATION02.open"),$loc);
   }elsif ($WfRec->{eventmode} eq "EVk.appl" && $eventstat==17){
      my $ag="";
      foreach my $appl (@{$WfRec->{affectedapplication}}){
         $ag.="; " if ($ag ne "");
         $ag.=$appl;
      }
      $ag="\"$ag\"";
      if (length($ag) > 16){
          $ag="<br>$ag";
      }
      $salutation=sprintf($self->T("SALUTATION03.close"),$ag);
   }elsif($WfRec->{eventmode} eq "EVk.appl"){
      my $ag="";
      foreach my $appl (@{$WfRec->{affectedapplication}}){
         $ag.="; " if ($ag ne "");
         $ag.=$appl;
      }
      $ag="\"$ag\"";
      if (length($ag) > 16){
          $ag="<br>$ag";
      }
      $salutation=sprintf($self->T("SALUTATION03.open"),$ag,$creationtime);
   }elsif ($WfRec->{eventmode} eq "EVk.net" && $eventstat==17){
      $salutation=sprintf($self->T("SALUTATION04.close"));
   }elsif($WfRec->{eventmode} eq "EVk.net"){   
      $salutation=sprintf($self->T("SALUTATION04.open"));
   }elsif ($WfRec->{eventmode} eq "EVk.bprocess" && $eventstat==17){
      my $bp=$WfRec->{affectedbusinessprocessname};
      $salutation=sprintf($self->T("SALUTATION05.close"),$bp);
   }elsif($WfRec->{eventmode} eq "EVk.bprocess"){   
      my $bp=$WfRec->{affectedbusinessprocessname};
      $salutation=sprintf($self->T("SALUTATION05.open"),$bp);
   }
   if ($action eq "rootcausei"){
      $salutation=sprintf($self->T("SALUTATION10"));
   }
   return($salutation);
}
 

sub generateMailSet
{
   my $self=shift;
   my ($WfRec,$action,$sendcustinfocount,
       $eventlang,$additional,$emailprefix,$emailpostfix,
       $emailtext,$emailsep,$emailsubheader,$emailsubtitle,
       $subject,$allowsms,$smstext)=@_;
   my @emailprefix=();
   my @emailpostfix=();
   my @emailtext=();
   my @emailsep=();
   my @emailsubheader=();
   my @emailsubtitle=();

   $$allowsms=0;
   $$smstext="";

   my $eventlango=$self->getField("wffields.eventlang",$WfRec);
   $$eventlang=$eventlango->RawValue($WfRec) if (defined($eventlango));

   my $baseurl;
   if ($ENV{SCRIPT_URI} ne ""){
      $baseurl=$ENV{SCRIPT_URI};
      $baseurl=~s#/auth/.*$##;
   }
   my @smsfields=qw(wffields.eventmode wffields.eventstatclass);
   my @baseset=qw(wffields.eventstartofevent wffields.eventendofevent
                  wffields.eventstatclass);
   push(@baseset,qw(wffields.affectedregion));
   if ($WfRec->{eventmode} eq "EVk.appl"){
      push(@baseset,"affectedapplication");
      push(@baseset,"wffields.affectedcustomer");
      push(@smsfields,"affectedapplication");
   }
   if ($WfRec->{eventmode} eq "EVk.infraloc"){
      push(@baseset,"wffields.affectedlocation");
      push(@baseset,"wffields.affectedroom");
      push(@smsfields,"wffields.affectedlocation");
   }
   if ($WfRec->{eventmode} eq "EVk.net"){
      push(@baseset,"wffields.affectednetwork");
      push(@smsfields,"wffields.affectednetwork");
   }
   if ($WfRec->{eventmode} eq "EVk.bprocess"){
      push(@baseset,"wffields.affectedbusinessprocess");
      push(@baseset,"wffields.affectedbusinessprocessname");
      push(@baseset,"wffields.affectedcustomer");
      push(@smsfields,"wffields.affectedbusinessprocess");
   }
   push(@smsfields,qw(wffields.eventstartofevent wffields.eventendofevent
                      wffields.eventimpact));


   my @sets=([@baseset,qw(  
                          wffields.eventimpact
                          wffields.eventreason 
                          wffields.shorteventelimination
                         )],
             [@baseset,qw(
                          wffields.eventaltimpact
                          wffields.eventaltreason 
                          wffields.altshorteventelimination
                         )]);
   my @eventlanglist=split(/-/,$$eventlang);
   for(my $langno=0;$langno<=$#eventlanglist;$langno++){
      my $lang=$eventlanglist[$langno];
      my $line=0;
      my $mailsep=0;
      $mailsep="$lang:" if ($#emailsep!=-1); 
      $ENV{HTTP_FORCE_LANGUAGE}=$lang;
      my $state=$self->getNotifyCountLabel($WfRec,$sendcustinfocount);
      my @fields=@{shift(@sets)};

      if ($langno==0){
         foreach my $field (@smsfields){
            my $fo=$self->getField($field,$WfRec);
            if (defined($fo)){
               my $v=$fo->FormatedResult($WfRec,"ShortMsg");
               if ($v ne ""){
                  if ($field=~m/(eventstatclass)/){
                     $$smstext.="$state: EK$v - ";
                  }
                  elsif ($field=~m/(eventstartofevent)/){
                     $$smstext.=$self->T("Start").": ".$v."\n";
                  }
                  elsif ($field=~m/(eventendofevent)/){
                     $$smstext.=$self->T("End").":  ".$v."\n";
                  }
                  elsif ($field=~m/(eventimpact)/){
                   #  zweizeilen Verfahren auf Anweisung von Hr. Pavez entf.
                   #  my @a=split(/\n/,$v);
                   #  $v=join("\n",splice(@a,0,2));
                   #  $v=~s/^\s*//;
                   #  $v=~s/\s*$//;
                     my @a=map({$_=~s/^\s*//s;$_=~s/\s*$//s;$_;}
                     grep(!/^\s*$/,split(/(\[\d+\.\d+\.\d+\s+\d+:\d+\])/,$v)));
                     if ($#a<=1){
                        @a=($v);
                     } 
                     $v=join("\n",splice(@a,0,2));
                     $$smstext.=$v."\n";
                  }
                  else{
                     $$smstext.=$v."\n";
                  }
               }
            }
         }
      }

      foreach my $field (@fields){
         my $fo=$self->getField($field,$WfRec);
         my $sh=0;
         $sh=" " if ($field eq "wffields.eventaltdesciption" ||
                     $field eq "wffields.eventdesciption");
         if (defined($fo)){
            my $v=$fo->FormatedResult($WfRec,"HtmlMail");
            if ($v ne ""){
               if ($field eq "wffields.eventstatclass" &&
                   $v eq "1" || $v eq "2"){
                  $$allowsms=1
               }
              # if ($baseurl ne "" && $line==0){
              #    my $ilang="?HTTP_ACCEPT_LANGUAGE=$lang";
              #    my $imgtitle=$self->getParent->T("current state of workflow",
              #                                     "base::workflow");
              #    push(@emailpostfix,
              #         "<img title=\"$imgtitle\" class=status border=0 ".
              #         "src=\"$baseurl/public/base/workflow/".
              #         "ShowState/$WfRec->{id}$ilang\">");
              # }
              # else{
                  push(@emailpostfix,"");
              # }
               push(@emailprefix,$fo->Label().":");
               my $data=$v;
               $data=~s/</&lt;/g;
               $data=~s/>/&gt;/g;
               push(@emailtext,$data);
               push(@emailsubheader,$sh);
               push(@emailsep,$mailsep);
               $line++;
               $mailsep=0;
            }
         }
      }
      my $rel=$self->getField("relations",$WfRec);
      my $reldata=$rel->ListRel($WfRec->{id},"mail",{name=>\'consequenceof'});
      push(@emailprefix,$rel->Label().":");
      push(@emailtext,$reldata);
      push(@emailsubheader,0);
      push(@emailsep,0);
      push(@emailpostfix,"");
   }
   my $wf=$self->getParent();
   my $ssfld=$wf->getField("wffields.eventstaticmailsubject",$WfRec);
   if (defined($ssfld)){
      my $sstext=$ssfld->RawValue($WfRec);
      if ($sstext ne ""){
         $$subject=$sstext;
      }
   }

   delete($ENV{HTTP_FORCE_LANGUAGE});

   @$emailprefix=@emailprefix;
   @$emailpostfix=@emailpostfix;
   @$emailtext=@emailtext;
   @$emailsep=@emailsep;
   @$emailsubheader=@emailsubheader;
   @$emailsubtitle=@emailsubtitle;
}



#######################################################################
package itil::workflow::eventnotify::askmode;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
use Data::Dumper;
@ISA=qw(kernel::WfStep);

sub generateStoredWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my @steplist=@_;
   my $d=<<EOF;
<tr>
<td class=fname width=30%>%eventmode(label)%:</td>
<td class=finput>%eventmode(storedworkspace)%</td>
</tr>
EOF

   return($self->SUPER::generateStoredWorkspace($WfRec,@steplist).$d);
}


sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   my @steplist=Query->Param("WorkflowStep");
   pop(@steplist);
   my $StoredWorkspace=$self->SUPER::generateStoredWorkspace($WfRec,@steplist);

   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
$StoredWorkspace
<tr>
<td class=fname width=30%>%eventmode(label)%:</td>
<td class=finput>%eventmode(detail)%</td>
</tr>
</table>
<script language="JavaScript">
setFocus("Formated_eventmode");
setEnterSubmit(document.forms[0],"NextStep");
</script>
EOF
   $templ.=$self->getParent->getParent->HtmlPersistentVariables(
            qw( Formated_affectedapplication));



   return($templ);
}


sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if ($action eq "NextStep"){
      my $eventmode=Query->Param("Formated_eventmode");
     # if ($eventmode ne "EVk.appl"){
     #    $self->LastMsg(ERROR,"invalid eventmode '%s'",$eventmode);
     #    return(0);
     # }
   }
   return($self->SUPER::Process($action,$WfRec));
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;
   return(340);
}

#######################################################################
package itil::workflow::eventnotify::asknet;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
use Data::Dumper;
@ISA=qw(kernel::WfStep);

sub generateStoredWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my @steplist=@_;
   my $d=<<EOF;
<tr>
<td class=fname width=20%>%mandator(label)%:</td>
<td class=finput>%mandatorid(storedworkspace)%</td>
</tr>
<tr>
<td class=fname width=20%>%affectednetwork(label)%:</td>
<td class=finput>%affectednetwork(storedworkspace)%</td>
</tr>
<tr>
<td class=fname width=20%>%affectedregion(label)%:</td>
<td class=finput>%affectedregion(storedworkspace)%</td>
</tr>
EOF

   return($self->SUPER::generateStoredWorkspace($WfRec,@steplist).$d);
}


sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   my @steplist=Query->Param("WorkflowStep");
   pop(@steplist);
   my $StoredWorkspace=$self->SUPER::generateStoredWorkspace($WfRec,@steplist);

   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
$StoredWorkspace
<tr>
<td class=fname width=20%>%mandator(label)%:</td>
<td class=finput>%mandatorid(detail,mode3)%</td>
</tr>
<tr>
<td class=fname width=20%>%affectednetwork(label)%:</td>
<td class=finput>%affectednetwork(detail)%</td>
</tr>
<tr>
<td class=fname width=20%>%affectedregion(label)%:</td>
<td class=finput>%affectedregion(detail)%</td>
</tr>
</table>
EOF
   return($templ);
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

 #  if ($action eq "NextStep"){
 #     my $eventmode=Query->Param("Formated_eventmode");
 #     my $fo=$self->getField("affectedapplication");
 #     my $foval=Query->Param("Formated_".$fo->Name());
 #     if (!$fo->Validate($WfRec,{$fo->Name=>$foval})){
 #        $self->LastMsg(ERROR,"unknown error") if (!$self->LastMsg()); 
 #        return(0);
 #     }
 #  }
   return($self->SUPER::Process($action,$WfRec));
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;
   return(340);
}

#######################################################################
package itil::workflow::eventnotify::askbprocess;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
use Data::Dumper;
@ISA=qw(kernel::WfStep);

sub generateStoredWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my @steplist=@_;
   my $d=<<EOF;
<tr>
<td class=fname width=20%>%affectedbusinessprocess(label)%:</td>
<td class=finput>%affectedbusinessprocess(storedworkspace)%</td>
</tr>
EOF

   return($self->SUPER::generateStoredWorkspace($WfRec,@steplist).$d);
}


sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   my @steplist=Query->Param("WorkflowStep");
   pop(@steplist);
   my $StoredWorkspace=$self->SUPER::generateStoredWorkspace($WfRec,@steplist);

   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
$StoredWorkspace
<tr>
<td class=fname width=20%>%affectedbusinessprocess(label)%:</td>
<td class=finput>%affectedbusinessprocess(detail)%</td>
</tr>
</table>
EOF
   return($templ);
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if ($action eq "NextStep"){
      my $eventmode=Query->Param("Formated_eventmode");
      my $fo=$self->getField("affectedbusinessprocess");
      my $foval=Query->Param("Formated_".$fo->Name());
      if ($foval=~m/^\s*$/){
         $self->LastMsg(ERROR,"no businessprocess specified"); 
         return(0);
      }
      if (!$fo->Validate($WfRec,{$fo->Name=>$foval})){
         $self->LastMsg(ERROR,"unknown error") if (!$self->LastMsg()); 
         return(0);
      }
   }
   return($self->SUPER::Process($action,$WfRec));
}



sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;
   return(340);
}

#######################################################################
package itil::workflow::eventnotify::askappl;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub generateStoredWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my @steplist=@_;
   my $d=<<EOF;
<tr>
<td class=fname width=20%>%affectedapplication(label)%:</td>
<td class=finput>%affectedapplication(storedworkspace)%</td>
</tr>
EOF

   return($self->SUPER::generateStoredWorkspace($WfRec,@steplist).$d);
}


sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   my @steplist=Query->Param("WorkflowStep");
   pop(@steplist);
   my $StoredWorkspace=$self->SUPER::generateStoredWorkspace($WfRec,@steplist);

   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
$StoredWorkspace
<tr>
<td class=fname width=20%>%affectedapplication(label)%:</td>
<td class=finput>%affectedapplication(detail)%</td>
</tr>
</table>
<script language="JavaScript">
setFocus("Formated_affectedapplication");
setEnterSubmit(document.forms[0],"NextStep");
</script>
EOF
   return($templ);
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if ($action eq "NextStep"){
      my $eventmode=Query->Param("Formated_eventmode");
      my $fo=$self->getField("affectedapplication");
      my $foval=Query->Param("Formated_".$fo->Name());
      if ($foval=~m/^\s*$/){
         $self->LastMsg(ERROR,"no application specified"); 
         return(0);
      }
      if (!$fo->Validate($WfRec,{$fo->Name=>$foval})){
         $self->LastMsg(ERROR,"unknown error") if (!$self->LastMsg()); 
         return(0);
      }
   }
   return($self->SUPER::Process($action,$WfRec));
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;
   return(340);
}

#######################################################################
package itil::workflow::eventnotify::askloc;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
use Data::Dumper;
@ISA=qw(kernel::WfStep);

sub generateStoredWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my @steplist=@_;
   my $d=<<EOF;
<tr>
<td class=fname width=20%>%mandator(label)%:</td>
<td class=finput>%mandatorid(storedworkspace)%</td>
</tr>
<tr>
<td class=fname width=20%>%affectedlocation(label)%:</td>
<td class=finput>%affectedlocation(storedworkspace)%</td>
</tr>
EOF

   return($self->SUPER::generateStoredWorkspace($WfRec,@steplist).$d);
}


sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   my @steplist=Query->Param("WorkflowStep");
   pop(@steplist);
   my $StoredWorkspace=$self->SUPER::generateStoredWorkspace($WfRec,@steplist);

   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
$StoredWorkspace
<tr>
<td class=fname width=20%>%mandator(label)%:</td>
<td class=finput>%mandatorid(detail,mode3)%</td>
</tr>
<tr>
<td class=fname width=20%>%affectedlocation(label)%:</td>
<td class=finput>%affectedlocation(detail)%</td>
</tr>
</table>
EOF
   return($templ);
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if ($action eq "NextStep"){
      my $eventmode=Query->Param("Formated_eventmode");
      my $fo=$self->getField("affectedlocation");
      my $foval=Query->Param("Formated_".$fo->Name());
      if ($foval=~m/^\s*$/){
         $self->LastMsg(ERROR,"no location specified");
         return(0);
      }
      if (!$fo->Validate($WfRec,{$fo->Name=>$foval})){
         $self->LastMsg(ERROR,"unknown error") if (!$self->LastMsg()); 
         return(0);
      }
   }
   return($self->SUPER::Process($action,$WfRec));
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;
   return(340);
}

#######################################################################
package itil::workflow::eventnotify::askroom;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
use Data::Dumper;
@ISA=qw(kernel::WfStep);

sub generateStoredWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my @steplist=@_;
   my $d=<<EOF;
<tr>
<td class=fname valign=to width=20%>%affectedroom(label)%:</td>
<td class=finput>%affectedroom(storedworkspace)%</td>
</tr>
EOF

   return($self->SUPER::generateStoredWorkspace($WfRec,@steplist).$d);
}


sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   my @steplist=Query->Param("WorkflowStep");
   pop(@steplist);
   my $StoredWorkspace=$self->SUPER::generateStoredWorkspace($WfRec,@steplist);

   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
$StoredWorkspace
<tr>
<td class=fname valign=top width=20%>%affectedroom(label)%:</td>
<td class=finput>%affectedroom(detail)%</td>
</tr>
</table>
EOF
   return($templ);
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if ($action eq "NextStep"){
      my $affectedroom=Query->Param("Formated_affectedroom");
      if ($affectedroom=~m/^\s*$/){
         $self->LastMsg(ERROR,"no room selected");
         return(0);
      }
#      if ($eventmode ne "EVk.appl"){
#         return(0);
#      }
   }
   return($self->SUPER::Process($action,$WfRec));
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;
   return(340);
}

#######################################################################
package itil::workflow::eventnotify::dataload;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   my @steplist=Query->Param("WorkflowStep");
   pop(@steplist);
   my $StoredWorkspace=$self->SUPER::generateStoredWorkspace($WfRec,@steplist);
   my $t=<<EOF;
Mit dem n�chsten Schritt wird die Ereignisinformation "erzeugt". In 
Abh�ngigkeit zum gew�hlten Ereignis-Modus werden dann u.U. automatisch
bestimmte Personengruppen als "Vorabinformation" �ber dieses Ereignis
informiert.
EOF

   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
$StoredWorkspace
<tr>
<td class=fname valign=top width=20%>%eventstatnature(label)%:</td>
<td class=finput>%eventstatnature(detail)%</td>
</tr>
<tr>
<td class=fname valign=top width=20%>%eventstartofevent(label)%:</td>
<td class=finput>%eventstartofevent(detail)%</td>
</tr>
<tr>
<td class=fname valign=top width=20%>%eventendexpected(label)%:</td>
<td class=finput>%eventendexpected(detail)%</td>
</tr>
<tr>
<td class=fname valign=top width=20%>%eventdesciption(label)%:</td>
<td class=finput>%eventdesciption(detail)%</td>
<tr><td colspan=2>
<div class=Question>
$t
</div>
</td>
</tr>
</table>
EOF
   return($templ);
}


sub nativProcess
{
   my $self=shift;
   my $action=shift;
   my $h=shift;
   my $step=shift;
   my $WfRec=shift;
   my $actions=shift;


   if ($action eq "NextStep"){
      $h->{closedate}=undef;
      if ($h->{eventdesciption} eq "test"){
         # test mode autofill all nessasary data to send messages
         $h->{eventdesciption}="Dies ist eine Test Ergeinismeldung (Lang1)\n".
                               "Zeile2\n".
                               "Zeile3\n\n".
                               "Zeile4 nach Leerzeile";
         $h->{eventreason}="Dies ist die Ereignisursache in der ".
                           "Prim�rsprache der Ereignisinfo. Diese Zeile ".
                           "ist bewust sehr lange gew�hlt, damit ".
                           "sichergestellt ist, dass ein Zeilenumbruch ".
                           "erfolgen mu�. Es sind gleichzeitig div. ".
                           "Sonderzeichen in diesem Text vorhanden";
         $h->{eventimpact}="Ein Test kann traditionell keinerlei ".
                           "Auswirkungen f�r den Kunden haben.\n";
         $h->{shorteventelimination}="Bei einem Test sind keine ".
                                     "kurzfristigen Ma�nahmen zur Service".
                                     "widerherstellung notwendig und ".
                                     "sinnvoll.";
         $h->{eventstatclass}="2";
         $h->{eventstatreason}="EVr.other";
         $h->{eventstattype}="EVt.unknown";

      }

      my $eventlang;
      $eventlang=$self->getParent->Lang() if ($eventlang eq "");
      $eventlang="en" if ($eventlang eq "");
      $h->{eventlang}=$eventlang;

      my %groups=$self->getGroupsOf($ENV{REMOTE_USER},
                                    [qw(REmployee RApprentice RFreelancer 
                                        RBoss RBoss2)],'direct');
      my @grpids=keys(%groups);
      if ($#grpids!=-1){
         $h->{initiatorgroupid}=\@grpids;
         $h->{initiatorgroup}=[map({$groups{$_}->{fullname}} @grpids)];
      }
      if ($h->{eventmode} eq "EVk.infraloc"){
         my $loc=$h->{affectedlocation};
         $loc=$h->{affectedlocation}->[0] if (ref($h->{affectedlocation}));
         $h->{name}=$self->getParent->T("Location-notification:")." ".$loc;
         if (!$self->getParent->ValidateCreate($h)){
            return(0);
         }
      #   if ($h->{affectedlocationid} ne ""){
      #      $h->{affectedlocationid}=[$h->{affectedlocationid}];
      #   }
         my %affectedlocation;
         my %affectedlocationid;
         if ($h->{affectedlocationid} ne ""){
            my %affectedcustomer;
            my %affectedcustomerid;
            my $affecteditemprio;
            my $l=getModuleObject($self->getParent->getParent->Config,
                                     "base::location");
            $l->SetFilter({id=>$h->{affectedlocationid},cistatusid=>"<=4"});
            foreach my $lrec ($l->getHashList(qw(contacts cistatus id name))){
               $affectedlocationid{$lrec->{id}}++; 
               $affectedlocation{$lrec->{name}}++; 
               if (ref($lrec->{contacts}) eq "ARRAY"){
                  foreach my $crec (@{$lrec->{contacts}}){
                     my $roles=$crec->{roles};
                     $roles=[$roles] if (ref($roles) ne "ARRAY");
                     if ($crec->{target} eq "base::grp"){
                        if (grep(/^staffloc$/,@$roles)){
                           $affectedcustomer{$crec->{targetname}}++;
                           $affectedcustomerid{$crec->{targetid}}++;
                           if (my ($prio)=$crec->{comments}=~m/Prio(\d+)/){
                              if (!defined($affecteditemprio) ||
                                  $affecteditemprio>$prio){
                                 $affecteditemprio=$prio;
                              }
                           }
                        }
                     }
                  }
               }
            }
            if (defined($affecteditemprio)){
               $h->{affecteditemprio}=$affecteditemprio;
            }
            if (keys(%affectedcustomerid)){
               $h->{affectedcustomerid}=[keys(%affectedcustomerid)];
            }
            if (keys(%affectedcustomer)){
               $h->{affectedcustomer}=[keys(%affectedcustomer)];
            }
         }
         return(0) if (!keys(%affectedlocationid));
      }
      elsif ($h->{eventmode} eq "EVk.appl"){
         my $app=$h->{affectedapplication};
         if (ref($h->{affectedapplication})){
            $app=$h->{affectedapplication}->[0];
         }
         if ($h->{eventstatclass} eq ""){
            if ($h->{eventstatnature} eq "EVn.info"){
               $h->{eventstatclass}=4;
            }
         }
         my $appl=getModuleObject($self->getParent->getParent->Config,
                                  "itil::appl");
         $appl->SetFilter({cistatusid=>"<5",id=>$h->{affectedapplicationid}});
         my ($arec,$msg)=$appl->getOnlyFirst(qw(name customer customerid 
                                                mandator mandatorid conumber
                                                responseteam businessteam
                                                eventlang customerprio
                                                custcontracts id));
         if (defined($arec)){
            $app=$arec->{name};
            $h->{affectedapplicationid}=[$arec->{id}];   
            $h->{affectedapplication}=[$arec->{name}];   
            $h->{mandatorid}=[$arec->{mandatorid}];   
            $h->{mandator}=[$arec->{mandator}];   
            $h->{involvedbusinessteam}=[$arec->{businessteam}];
            $h->{involvedresponseteam}=[$arec->{businessteam}];
            $h->{involvedcostcenter}=[$arec->{conumber}];
            $h->{eventlang}=$arec->{eventlang};
            $h->{affecteditemprio}=$arec->{customerprio};
            my @custcontract;
            my @custcontractid;
            if (!$self->getParent->ValidateCreate($h)){
               return(0);
            }
            foreach my $contr (@{$arec->{custcontracts}}){
               push(@custcontract,$contr->{custcontract});
               push(@custcontractid,$contr->{custcontractid});
            }
            if ($#custcontractid!=-1){
               $h->{affectedcontract}=\@custcontract;
               $h->{affectedcontractid}=\@custcontractid;
            }
            else{
               delete($h->{affectedcontract});
               delete($h->{affectedcontractid});
            }
            if ($arec->{customer} ne ""){
               $h->{affectedcustomer}=[$arec->{customer}];
               $h->{affectedcustomerid}=[$arec->{customerid}];
            }
            else{
               delete($h->{affectedcustomer});
               delete($h->{affectedcustomerid});
            }
         }
         else{
            $self->getParent->LastMsg(ERROR,"invalid or inactive application");
            return(0);
         }
         $h->{name}=$self->getParent->T("Application-notification:").
                    " ".$app;
      }
      elsif ($h->{eventmode} eq "EVk.net"){
         my $region=$self->getParent->T($h->{affectedregion},
                                        $self->getParent->Self);
         $h->{name}=$self->getParent->T("Network-notification:").
                    " ".$self->T($region,"itil::workflow::eventnotify");
         if (!$self->getParent->ValidateCreate($h)){
            return(0);
         }
      }
      elsif ($h->{eventmode} eq "EVk.bprocess"){
         my $p=$h->{affectedbusinessprocess};
         $h->{name}=$self->getParent->T("Process-notification:")." ".$p;
         my $bp=getModuleObject($self->getParent->getParent->Config,
                                  "itil::businessprocess");
         if (ref($h->{affectedbusinessprocess})){
            $p=$h->{affectedbusinessprocess}->[0];
         }
         if ($h->{eventstatclass} eq ""){
            if ($h->{eventstatnature} eq "EVn.info"){
               $h->{eventstatclass}=4;
            }
         }
         $bp->SetFilter({cistatusid=>"<5",id=>$h->{affectedbusinessprocessid}});
         my ($prec,$msg)=$bp->getOnlyFirst(qw(name customer customerid 
                                              mandator mandatorid fullname
                                              eventlang customerprio
                                              custcontracts id));
         if (defined($prec)){
          #  $app=$arec->{name};
            $h->{affectedbusinessprocessname}=$prec->{fullname};   
            $h->{mandatorid}=[$prec->{mandatorid}];   
            $h->{mandator}=[$prec->{mandator}];   
            $h->{eventlang}=$prec->{eventlang};
            if (!$self->getParent->ValidateCreate($h)){
               return(0);
            }
            if ($prec->{customer} ne ""){
               $h->{affectedcustomer}=[$prec->{customer}];
               $h->{affectedcustomerid}=[$prec->{customerid}];
            }
            else{
               delete($h->{affectedcustomer});
               delete($h->{affectedcustomerid});
            }
         }
         else{
            $self->getParent->LastMsg(ERROR,
                      "invalid or inactive businessprocess");
            return(0);
         }
      }
      else{
         $self->getParent->LastMsg(ERROR,"invalid eventmode '$h->{eventmode}'");
         return(0);
      }
      if ($h->{eventstart} eq ""){
         $self->getParent->LastMsg(ERROR,"invalid event start");
         return(0);
      }
      $h->{step}=$self->getNextStep() if ($h->{step} eq "");
      if (!$self->StoreRecord($WfRec,$h)){
         return(0);
      }
      return(1);
   }
   return(0);
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if ($action eq "NextStep"){
      if (my $h=$self->getWriteRequestHash("web")){
         $h->{stateid}=1;
         $h->{eventstart}=Query->Param("Formated_eventstartofevent");
         $h->{eventend}=undef;
         if (Query->Param("Formated_eventmode") ne ""){
            $h->{eventmode}=Query->Param("Formated_eventmode");
         }
         if (Query->Param("Formated_eventendofevent") ne ""){
            $h->{eventend}=Query->Param("Formated_eventendofevent");
         }
         return($self->nativProcess("NextStep",$h,$self->Self,$WfRec,$actions));
      }
      return(0);
   }
   return($self->SUPER::Process($action,$WfRec));
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(340);
}

#######################################################################
package itil::workflow::eventnotify::copydata;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(itil::workflow::eventnotify::dataload);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   Query->Param("Formated_eventstartofevent"=>'now');

   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
<tr>
<td class=fname width=20%>%eventstartofevent(label)%:</td>
<td class=finput>%eventstartofevent(detail)%</td>
</tr>
</table>
EOF
   return($templ);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;
   $newrec->{name}=1;


   return(1);
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if ($action eq "NextStep"){
      my $isCopyFromId=Query->Param("isCopyFromId");
      my $wf=$self->getParent->getParent;
      $wf->ResetFilter();
      $wf->SetFilter({id=>\$isCopyFromId});
      my ($crec,$msg)=$wf->getOnlyFirst(qw(ALL));
      my $h=$self->getWriteRequestHash("web");
      if (defined($crec)){
         foreach my $cvar (qw(mandatorid mandator affectedapplication affectedapplicationid affectedlocation affectedlocationid affectedroom affectednetwork affectednetworkid affectedregion affectedcustomer affectedcustomerid eventdesciption eventreason eventimpact shorteventelimination longeventelimination eventaltdesciption eventaltreason eventaltimpact altshorteventelimination altlongeventelimination eventlang eventsla eventstaticmailsubject eventstaticemailgroupid eventinternalslacomments eventinternalcomments eventstatnature eventstattype eventstatreason eventstatclass eventmode affectedbusinessprocess affectedbusinessprocessid)){
            if (defined($crec->{$cvar})){
               $h->{$cvar}=$crec->{$cvar};
            }
         }
      }
      $h->{stateid}=1;
      $h->{eventstart}=NowStamp("en");
      $h->{eventend}=undef;
      $h->{closedate}=undef;
      return($self->nativProcess($action,$h,$self->getNextStep(),
                                 $WfRec,$actions));
   }
   return($self->SUPER::Process($action,$WfRec));
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(280);
}

#######################################################################
package itil::workflow::eventnotify::main;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
use Data::Dumper;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   my ($Dscust,$Dsmgmt,$Dwfclose,$Dnote,$Daddnote,
       $Dtimemod);
   $Dscust="disabled" if (!$self->ValidActionCheck(0,$actions,"sendcustinfo"));
   $Dsmgmt="disabled" if (!$self->ValidActionCheck(0,$actions,"sendmgmtinfo"));
   $Daddnote="disabled"  if (!$self->ValidActionCheck(0,$actions,"addnote"));
   $Dwfclose="disabled"  if (!$self->ValidActionCheck(0,$actions,"wfclose"));
   $Dtimemod="disabled"  if (!$self->ValidActionCheck(0,$actions,"timemod"));
   $Dnote="readonly"     if ($Daddnote eq "disabled");
   my $t1=$self->T("Add Note to flow");
   my $t2=$self->T("Send a customert notification");
   my $t3=$self->T("Send a management notification");

   my $addButtons=$self->getParent->getAdditionalMainButtons($WfRec,$actions);

   my $t6=$self->T("Close Workflow");
   my $t7=$self->T("Modify event timespan");
   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100% height=110>
<tr><td align=center valign=top>
<textarea name=note $Dnote 
          onkeydown=\"textareaKeyHandler(this,event);\" 
          style=\"width:100%;height:50\"></textarea>
<table border=0 width=100% cellspacing=0 cellpadding=0>
<tr>
<td align=center>
<input type=submit name=addnote $Daddnote value="$t1" 
       class=workflowbutton>
</td>
</tr>
</table>
</td>
<td width=1% valign=top>
<input type=submit $Dtimemod
       class=workflowbutton name=timemod value="$t7">
$addButtons
</td>
</tr>
<tr>
<td>
<table width=100% border=0>
<tr>
<td align=center>
<input type=submit $Dscust 
       class=workflowbutton name=sendcustinfo value="$t2">
</td>
<td align=center>
<input type=submit $Dsmgmt 
       class=workflowbutton name=sendmgmtinfo value="$t3">
</td>
</table>
</td>
<td>
<input type=submit $Dwfclose
       class=workflowbutton name=wfclose value="$t6">
</td>
</tr>
</table>
EOF
   return($templ);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   foreach my $v (qw(name)){
      if ((!defined($oldrec) || exists($newrec->{$v})) && $newrec->{$v} eq ""){
         $self->LastMsg(ERROR,"field '%s' is empty",
                        $self->getField($v)->Label());
         return(0);
      }
   }

   return(1);
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   my $mainprocess=$self->getParent->AdditionalMainProcess($action,$WfRec,$actions);
   return($mainprocess) if ($mainprocess!=-1);

   if (!defined($action) && Query->Param("addnote")){
      my $note=Query->Param("note");
      if ($note=~m/^\s*$/){
         $self->LastMsg(ERROR,"nix drin");
         return(0);
      }
      $note=trim($note);
      my $effort=Query->Param("Formated_effort");
      if ($self->getParent->getParent->Action->StoreRecord(
          $WfRec->{id},"note",
          {translation=>'itil::workflow::eventnotify'},$note,$effort)){
         my $newstateid=4;
         $newstateid=$WfRec->{stateid} if ($WfRec->{stateid}>4);
         $self->StoreRecord($WfRec,{stateid=>$newstateid});
         Query->Delete("WorkflowStep");
         return(1);
      }
      return(0);
   }
   if (!defined($action) && Query->Param("sendcustinfo")){
      return(undef) if (!$self->ValidActionCheck(1,$actions,"sendcustinfo"));
      my @WorkflowStep=Query->Param("WorkflowStep");
      push(@WorkflowStep,"itil::workflow::eventnotify::sendcustinfo");
      Query->Param("WorkflowStep"=>\@WorkflowStep);
      return(0);
   }
   if (!defined($action) && Query->Param("timemod")){
      return(undef) if (!$self->ValidActionCheck(1,$actions,"timemod"));
      my @WorkflowStep=Query->Param("WorkflowStep");
      push(@WorkflowStep,"itil::workflow::eventnotify::timemod");
      Query->Param("WorkflowStep"=>\@WorkflowStep);
      return(0);
   }
   if (!defined($action) && Query->Param("wfclose")){
      return(undef) if (!$self->ValidActionCheck(1,$actions,"wfclose"));
      my @WorkflowStep=Query->Param("WorkflowStep");
      push(@WorkflowStep,$self->getParent->getStepByShortname('prewfclose',
                                                              $WfRec));
      Query->Param("WorkflowStep"=>\@WorkflowStep);
      return(0);
   }
   return($self->SUPER::Process($action,$WfRec));
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(140);
}

sub getPosibleButtons
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my %p=$self->SUPER::getPosibleButtons($WfRec);
   delete($p{PrevStep});
   delete($p{NextStep});
   return()   if (!$self->ValidActionCheck(0,$actions,"BreakWorkflow"));
   return(%p);
}

#######################################################################
package itil::workflow::eventnotify::sendcustinfo;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
use Data::Dumper;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my @email=@{$self->Context->{CurrentTarget}};
   my $emaillang=();
   my @emailprefix=();
   my @emailpostfix=();
   my @emailtext=();
   my @emailsep=();
   my @emailsubheader=();
   my @emailsubtitle=();
   my $smsallow=();
   my $smstext=();
   my %additional=();
   my $subject;

   my $id=$WfRec->{id};
   my $app=$self->getParent->getParent();
   $app->Action->ResetFilter();
   $app->Action->SetFilter({wfheadid=>\$id});
   my @l=$app->Action->getHashList(qw(cdate name));
   my $sendcustinfocount=0;
   foreach my $arec (@l){
      $sendcustinfocount++ if ($arec->{name} eq "sendcustinfo");
   }

   $self->getParent->generateMailSet($WfRec,"sendcustinfo",$sendcustinfocount,
                    \$emaillang,\%additional,
                    \@emailprefix,\@emailpostfix,\@emailtext,\@emailsep,
                    \@emailsubheader,\@emailsubtitle,
                    \$subject,\$smsallow,\$smstext);
   return($self->generateNotificationPreview(emailtext=>\@emailtext,
                                             emailprefix=>\@emailprefix,
                                             emailsep=>\@emailsep,
                                             subject=>$subject,
                                             emailsubheader=>\@emailsubheader,
                                             emailsubtitle=>\@emailsubtitle,
                                             to=>\@email));
}

sub getPosibleButtons
{  
   my $self=shift;
   my $WfRec=shift;
   my %b=$self->SUPER::getPosibleButtons($WfRec);
   my %em=();
   $self->getParent->getNotifyDestinations("custinfo",$WfRec,\%em);
   my @email=sort(keys(%em));
   $self->Context->{CurrentTarget}=\@email;
   delete($b{NextStep}) if ($#email==-1);
   delete($b{BreakWorkflow});

   return(%b);
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if ($action eq "NextStep"){
      return(undef) if (!$self->ValidActionCheck(1,$actions,"sendcustinfo"));

      #
      # check for needed values bevor sendcustinfo (REQ:11937530250003)
      # eventstatclass has been added by request (REQ:011946102560002)
      # eventnature has been added by request (REQ:12009961770002)
      foreach my $chkvar (qw(eventimpact eventstatclass
                             shorteventelimination 
                             eventreason eventstatnature)){
         if ($WfRec->{$chkvar}=~m/^\s*$/){
            my $fobj=$self->getField($chkvar);
            my $msg=sprintf($self->getParent->T("no value in field '\%s'"),
                    $fobj->Label());
            $self->LastMsg(ERROR,$msg);
            return(undef);
         }
      }

      my %em=();
      $self->getParent->getNotifyDestinations("custinfo",$WfRec,\%em);
      my @emailto=sort(keys(%em));
      my $id=$WfRec->{id};
      $self->getParent->getParent->Action->ResetFilter();
      $self->getParent->getParent->Action->SetFilter({wfheadid=>\$id});
      my @l=$self->getParent->getParent->Action->getHashList(qw(cdate name));
      my $sendcustinfocount=0;
      foreach my $arec (@l){
         $sendcustinfocount++ if ($arec->{name} eq "sendcustinfo");
      }
      my $wf=getModuleObject($self->Config,"base::workflow");
      my $eventlang;
      my @emailprefix=();
      my @emailpostfix=();
      my @emailtext=();
      my @emailsep=();
      my @emailsubheader=();
      my @emailsubtitle=();
      my $smsallow=();
      my $smstext=();

      my $eventlango=$self->getField("wffields.eventlang",$WfRec);
      $eventlang=$eventlango->RawValue($WfRec) if (defined($eventlango));
      my @langlist=split(/-/,$eventlang);
      my %headtext=();
      my $altheadtext="";
      my $subjectlabel;


      my $id=$WfRec->{id};
      my $app=$self->getParent->getParent();
      $app->Action->ResetFilter();
      $app->Action->SetFilter({wfheadid=>\$id});
      my @l=$app->Action->getHashList(qw(cdate name));
      my $sendcustinfocount=0;
      foreach my $arec (@l){
         $sendcustinfocount++ if ($arec->{name} eq "sendcustinfo");
      }

      my $failclass=$WfRec->{eventstatclass};
      my $subject="Subject";
      my $salutation="Sehr geehte Damen und Herren";
      my $altsalutation=$salutation;
      my $workflowlabel="Eventnotification";
      my $altworkflowlabel="Eventnotification";
      for(my $cl=0;$cl<=$#langlist;$cl++){
         $ENV{HTTP_FORCE_LANGUAGE}=$langlist[$cl];
         if ($cl==0){
            $subject=$self->getParent->getNotificationSubject($WfRec,
                                  "sendcustinfo",$sendcustinfocount,
                                  $subjectlabel,$failclass);
            $salutation=$self->getParent->getSalutation($WfRec,$action);
            $workflowlabel=$self->T("Eventnotification",
                                    'itil::workflow::eventnotify');
         }
         else{
            $altsalutation=$self->getParent->getSalutation($WfRec,$action);
            $altworkflowlabel=$self->T("Eventnotification",
                                       'itil::workflow::eventnotify');
         }
         my $ht;
         $subjectlabel="first information";
         my $ht=$self->T($subjectlabel,'itil::workflow::eventnotify');
         if ($sendcustinfocount>0){
            $subjectlabel="follow info";
            $ht=$sendcustinfocount.". ".$self->T($subjectlabel,
                                             'itil::workflow::eventnotify');
         }
         if ($WfRec->{eventendofevent} ne ""){ 
            $subjectlabel="finish info";
            $ht=$self->T($subjectlabel,'itil::workflow::eventnotify');
         }
         delete($ENV{HTTP_FORCE_LANGUAGE});
         $headtext{"headtextPAGE".$cl}=$ht;
      }
#   elsif ($variname eq "HEADCOLOR"){
#      my $val=$self->findtemplvar("referenz_failend");
#      my $failclass=$self->findtemplvar("referenz_failclass"); 
#      if ($val ne ""){
#         return("green");
#      }
#      if ($failclass eq "1" || $failclass eq "2"){
#         return("red");
#      }
#      if ($failclass eq "3" || $failclass eq "4" || $failclass eq "5"){
#         return("yellow");
#      }
#      return("red");
#   }

      my $eventstat=$WfRec->{stateid};
      my $failcolor="blue";
      my $utz=$self->getParent->getParent->UserTimezone();
      my $creationtime=$self->getParent->getParent->ExpandTimeExpression('now',
                                                               "de",$utz,$utz);
      if ($eventstat==17){
         $failcolor="limegreen";
      }elsif ($failclass==1 || $failclass==2){
         $failcolor="red";
      }elsif ($failclass==3 || $failclass==4 || $failclass==5){
         $failcolor="yellow";
      }
      my $id=$WfRec->{id};
      my $app=$self->getParent->getParent();
      $app->Action->ResetFilter();
      $app->Action->SetFilter({wfheadid=>\$id});
      my @l=$app->Action->getHashList(qw(cdate name));
      my $sendcustinfocount=0;
      foreach my $arec (@l){
         $sendcustinfocount++ if ($arec->{name} eq "sendcustinfo");
      }

      my %additional=(headcolor=>$failcolor,eventtype=>'Event',    
                      %headtext,headid=>$id,
                      salutation=>$salutation,
                      altsalutation=>$altsalutation,
                      workflowlabel=>$workflowlabel,
                      altworkflowlabel=>$altworkflowlabel,
                      creationtime=>$creationtime);
      $self->getParent->generateMailSet($WfRec,$action,$sendcustinfocount,
                       \$eventlang,\%additional,
                       \@emailprefix,\@emailpostfix,\@emailtext,\@emailsep,
                       \@emailsubheader,\@emailsubtitle,
                       \$subject,\$smsallow,\$smstext);
      #
      # calc from address
      #
      my $emailfrom="unknown\@w5base.net";
      my @emailcc=();
      my $uobj=$self->getParent->getPersistentModuleObject("base::user");
      my $userid=$self->getParent->getParent->getCurrentUserId(); 
      $uobj->SetFilter({userid=>\$userid});
      my ($userrec,$msg)=$uobj->getOnlyFirst(qw(email));
      if (defined($userrec) && $userrec->{email} ne ""){
         $emailfrom=$userrec->{email};
         my $qemailfrom=quotemeta($emailfrom);
         if (!grep(/^$qemailfrom$/,@emailto)){
            push(@emailcc,$emailfrom);
         }
      }
      
      #
      # load crator in cc
      #
      if ($WfRec->{openuser} ne ""){
         $uobj->SetFilter({userid=>\$WfRec->{openuser}});
         my ($userrec,$msg)=$uobj->getOnlyFirst(qw(email));
         if (defined($userrec) && $userrec->{email} ne ""){
            my $e=$userrec->{email};
            my $qemailfrom=quotemeta($e);
            if (!grep(/^$qemailfrom$/,@emailto) &&
                !grep(/^$qemailfrom$/,@emailcc)){
               push(@emailcc,$e);
            }
         }
      }
      my $newmailrec={
             class    =>'base::workflow::mailsend',
             step     =>'base::workflow::mailsend::dataload',
             name     =>$subject,
             emailtemplate  =>'eventnotification',
             skinbase       =>$self->getParent->getNotificationSkinbase($WfRec),
             emailfrom      =>$emailfrom,
             emailto        =>\@emailto,
             emailcc        =>\@emailcc,
             emaillang      =>$eventlang,
             emailprefix    =>\@emailprefix,
             emailpostfix   =>\@emailpostfix,
             emailtext      =>\@emailtext,
             allowsms       =>$smsallow,
             smstext        =>$smstext,
             emailsep       =>\@emailsep,
             emailsubheader =>\@emailsubheader,
             emailsubtitle  =>\@emailsubtitle,
             additional     =>\%additional
            };
      if (my $id=$wf->Store(undef,$newmailrec)){
         if ($self->getParent->activateMailSend($WfRec,$wf,$id,
                                                $newmailrec,$action)){
            if ($wf->Action->StoreRecord(
                $WfRec->{id},"sendcustinfo",
                {translation=>'itil::workflow::eventnotify'},
                "$sendcustinfocount. notification",undef)){
               Query->Delete("WorkflowStep");
               return(1);
            }
         }
      }
      else{
         return(0);
      }
      return(1);
   }
   return($self->SUPER::Process($action,$WfRec));
}

sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(300);
}

#######################################################################
package itil::workflow::eventnotify::timemod;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);


sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   my @steplist=Query->Param("WorkflowStep");
   pop(@steplist);
   my $t=<<EOF;
Wenn Sie bei Ereignisende keinen Zeitpunkt eingeben, so wird
der Workflow als "in Bearbeitung" markiert. Ist ein Zeitpunkt
bekannt, so wird der Workflow als "geschlossen" markiert.
EOF

   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
<tr>
<td class=fname valign=top width=20%>%eventstartofevent(label)%:</td>
<td class=finput>%eventstart(detail)%</td>
</tr>
<tr>
<td class=fname valign=top width=20%>%eventendexpected(label)%:</td>
<td class=finput>%eventendexpected(detail)%</td>
</tr>
<tr>
<td class=fname valign=top width=20%>%eventendofevent(label)%:</td>
<td class=finput>%eventend(detail)%</td>
</tr>
<tr><td colspan=2>
<div class=Question>
$t
</div>
</td>
</tr>
</table>
EOF
   return($templ);
}


sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $note=Query->Param("note");

   if ($action eq "NextStep"){
      return(undef) if (!$self->ValidActionCheck(1,$actions,"timemod"));
      my $h=$self->getWriteRequestHash("web",{class=>$self->getParent->Self});
      if ($h->{eventstart} eq ""){
         $self->LastMsg(ERROR,"invalid event start"); 
         return(0);
      }
      if ($h->{eventendexpected} ne ""){
         my $dur=CalcDateDuration($h->{eventstart},
                                  $h->{eventendexpected});
         if ($dur->{totalseconds}<=0){
            $self->LastMsg(ERROR,"invalid expected event end"); 
            return(0);
         }
      }
      if ($h->{eventend} ne ""){
         my $dur=CalcDateDuration($h->{eventstart},
                                  $h->{eventend});
         if ($dur->{totalseconds}<=0){
            $self->LastMsg(ERROR,"invalid event end"); 
            return(0);
         }
         $h->{stateid}=17;
      }
      else{
         $h->{stateid}=4;
      }
      my $newstep=$WfRec->{step};
      if ($self->getParent->StoreRecord($WfRec,$newstep,$h)){
         if ($self->getParent->getParent->Action->StoreRecord(
             $WfRec->{id},"wfmodeventtime",
             {translation=>'itil::workflow::eventnotify'},"")){
            Query->Delete("WorkflowStep");
            return(1);
         }
         return(0);
      }
   }
   return($self->SUPER::Process($action,$WfRec));
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(220);
}

sub getPosibleButtons
{
   my $self=shift;
   my $WfRec=shift;
   my %p=$self->SUPER::getPosibleButtons($WfRec);
   delete($p{BreakWorkflow});
   return(%p);
}


#######################################################################
package itil::workflow::eventnotify::prewfclose;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);


sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   my @steplist=Query->Param("WorkflowStep");
   pop(@steplist);
   my $t=<<EOF;
Mit dem n�chsten Schritt beenden Sie den Workflow. Es sind dann
keinerlei Nacharbeiten mehr m�glich.
EOF

   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
<tr><td colspan=2>
<div class=Question>
$t
</div>
</td>
</tr>
</table>
EOF
   return($templ);
}


sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $note=Query->Param("note");

   if ($action eq "NextStep"){
      return(undef) if (!$self->ValidActionCheck(1,$actions,"wfclose"));
      my $h=$self->getWriteRequestHash("web",{class=>$self->getParent->Self});
      $h->{stateid}=21;
      my $newstep=$self->getParent->getStepByShortname("wfclose",$WfRec);
      $h->{step}=$newstep;
      if ($self->getParent->StoreRecord($WfRec,$newstep,$h)){
         if ($self->getParent->getParent->Action->StoreRecord(
             $WfRec->{id},"wfclose",
             {translation=>'itil::workflow::eventnotify'},"")){
            Query->Delete("WorkflowStep");
            return(1);
         }
         return(0);
      }
   }
   return($self->SUPER::Process($action,$WfRec));
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(220);
}

sub getPosibleButtons
{
   my $self=shift;
   my $WfRec=shift;
   my %p=$self->SUPER::getPosibleButtons($WfRec);
   delete($p{BreakWorkflow});
   if ($WfRec->{eventstatclass} eq "" ||
       $WfRec->{eventstatnature} eq ""){
      delete($p{NextStep});
   }
   return(%p);
}


#######################################################################
package itil::workflow::eventnotify::wfclose;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   my ($Dreact);
   $Dreact="disabled"    if (!$self->ValidActionCheck(0,$actions,"reactivate"));
   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100% height=50>
<tr><td width=50% align=center>
<input type=submit $Dreact 
       class=workflowbutton name=reactivate value="reaktivieren">
</td>
</tr> 
</table>
EOF
   return($templ);
}




sub getPosibleButtons
{
   return();
}

sub getWorkHeight
{
   return(80);
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if (!defined($action) && Query->Param("addsup")){
      return(undef) if (!$self->ValidActionCheck(1,$actions,"addsup"));
      my @WorkflowStep=Query->Param("WorkflowStep");
      push(@WorkflowStep,"itil::workflow::eventnotify::addsup");
      Query->Param("WorkflowStep"=>\@WorkflowStep);
      return(0);
   }
   if (!defined($action) && Query->Param("reactivate")){
      return(undef) if (!$self->ValidActionCheck(1,$actions,"reactivate"));
      if ($self->StoreRecord($WfRec,{
                                step=>'itil::workflow::eventnotify::main',
                                fwdtarget=>undef,
                                fwdtargetid=>undef,
                                closedate=>undef,
                                stateid=>17})){
         if ($self->getParent->getParent->Action->StoreRecord(
             $WfRec->{id},"reactivate", 
             {translation=>'itil::workflow::eventnotify'},undef)){
            Query->Delete("WorkflowStep");
            return(1);
         }
         return(0);
      }
      return(0);
   }
   return(0);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;


   return(1);
}





1;
