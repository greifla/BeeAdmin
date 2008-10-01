package base::event::wfstatmail;
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
use kernel::Event;
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub Init
{
   my $self=shift;


   $self->RegisterEvent("wfstatmail","SendMyJobs");
   return(1);
}

sub SendMyJobs
{
   my $self=shift;

   my $user=getModuleObject($self->Config,"base::user");
   my $flt={usertyp=>\'user',cistatusid=>\'4'};
   $flt->{fullname}="vogl* bichler* *hanno.ernst*";
   $user->SetFilter($flt);
   $user->SetCurrentView(qw(userid fullname email accounts));
   my $wf=getModuleObject($self->Config,"base::MyW5Base::wfmyjobs");
   $wf->setParent($self);

   my $userlang="de";
   my $now=NowStamp("en");
   my $baseurl=$self->Config->Param("EventJobBaseUrl");
   my ($urec,$msg)=$user->getFirst();
   if (defined($urec)){
      do{
         if (ref($urec->{accounts}) eq "ARRAY" &&
             $#{$urec->{accounts}}>0){
            my $accounts=join(", ",map({$_->{account}} @{$urec->{accounts}}));
            $wf->ResetFilter();
            $wf->SetFilter({userid=>$urec->{userid}});
            my @l=$wf->getHashList(qw(stateid mdate id name nature));
            my @emailtext;
            my @emailpostfix;
            my @emailprefix;
            my $wfcount=0;
            foreach my $wfrec (@l){
               msg(INFO,"l=%s",Dumper($wfrec));
               my $imgtitle=$wfrec->{name};
               my $wfheadid=$wfrec->{id};
               my $dur=CalcDateDuration($wfrec->{mdate},$now,"GMT");
               printf STDERR ("d=%s\n",Dumper($dur));
               my $emailprefix;
               my $color="black";
               my $bold1="";
               my $bold0="";
               if ($dur->{days}>1){
                  $wfcount++;
                  if ($wfrec->{stateid}<17){
                     if ( ($wfrec->{prio}<3 && $dur->{days}>3) ||
                          ($wfrec->{prio}<6 && $dur->{days}>14) ||
                          ($dur->{days}>30)){
                        $color="red";
                     }
                     if ($dur->{days}>60){
                        $bold1="<b>";
                        $bold0="</b>";
                     }
                  }
                  my $msg=$self->T("unbearbeitet\nseit \%d Tagen");
                  $msg=~s/\n/<br>/g;
                       
                  $emailprefix=
                      sprintf("<div style=\"padding:2px;color:$color\">".
                               "$bold1$msg$bold0</div>",$dur->{days});
                  push(@emailprefix,$emailprefix);
                  if ($baseurl ne ""){
                     my $lang="?HTTP_ACCEPT_LANGUAGE=$userlang";
                     my $imgtitle="current state of workflow";
                     my $emailpostfix=
                            "<img title=\"$imgtitle\" class=status border=0 ".
                            "src=\"$baseurl/public/base/workflow/ShowState/".
                            "$wfheadid$lang\">";
                     push(@emailpostfix,$emailpostfix);
                  }
                  my $wfname=$wfrec->{name};
                  if ($baseurl ne ""){
                     $wfname.="\n".$baseurl."/auth/base/workflow/ById/".
                              $wfheadid;
                  }
                  push(@emailtext,$wfname);
               }
            }
            if ($baseurl ne ""){
               $self->sendNotify(emailtext=>\@emailtext,
                                 emailpostfix=>\@emailpostfix,
                                 emailprefix=>\@emailprefix,
                                 additional=>{contact=>$urec->{fullname},
                                              wfcount=>$wfcount,
                                              accounts=>$accounts,
                                              baseurl=>$baseurl,
                                             },
                                 emailto=>$urec->{email});
            }
         }
         ($urec,$msg)=$user->getNext();
      }until(!defined($urec));
   }

   return({msg=>'shit'});
}


sub sendNotify
{
   my $self=shift;
   my $wf=getModuleObject($self->Config,"base::workflow");
   my %rec=@_;

   $rec{class}='base::workflow::mailsend';
   $rec{step}='base::workflow::mailsend::dataload';
   $rec{name}='upcoming Job notification';
   $rec{emailtemplate}='wfstatmail';
   $rec{emailcc}=['hartmut.vogler@t-systems.com'];
   #       emaillang     =>$lang,

   if (my $id=$wf->Store(undef,\%rec)){
      my $r=$wf->Store($id,step=>'base::workflow::mailsend::waitforspool');
  }


}

1;
