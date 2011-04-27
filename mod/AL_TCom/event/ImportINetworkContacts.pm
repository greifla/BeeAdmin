package AL_TCom::event::ImportINetworkContacts;
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
use Time::HiRes qw( usleep);
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


   $self->RegisterEvent("ImportINetworkContacts",
                        "ImportINetworkContacts",timeout=>300);
   return(1);
}

sub ImportINetworkContacts
{
   my $self=shift;
   my %param=@_;
#   if (in_array(\@_,"nonotify")){
#      $param{nonotify}=1;
#   }

   my $wsuser=$self->Config->Param("WEBSERVICEUSER");
   my $wspass=$self->Config->Param("WEBSERVICEPASS");
   my $wsproxy=$self->Config->Param("WEBSERVICEPROXY");
   $wsuser=$wsuser->{inetwork} if (ref($wsuser) eq "HASH");
   $wspass=$wspass->{inetwork} if (ref($wspass) eq "HASH");
   $wsproxy=$wsproxy->{inetwork} if (ref($wsproxy) eq "HASH");
   $self->{'problems'}={};

   if ($wsuser eq ""){
      return({exitcode=>0,msg=>'ok - no web service account data'});
   }
   my %state;



   #use SOAP::Lite +trace=>'all';
   eval('use SOAP::Lite;');


   my $appl=getModuleObject($self->getParent->Config(),"itil::appl");
 #  $appl->SetNamedFilter("DBASE",{name=>"Flex* EKI* IT-Base*"});
   $appl->SetFilter({customer=>"DTAG DTAG.TDG DTAG.TDG.*",cistatusid=>"<=5"});
   my @idl=$appl->getHashList(qw(id name opmode));

   eval('
   sub SOAP::Transport::HTTP::Client::get_basic_credentials { 
       return $wsuser => $wspass;
   }
   ');

   my @msglist;


   my $n=0;
   foreach my $arec (@idl){
      usleep(200000);
      $n++;
      msg(DEBUG,"check applid $arec->{name}");

      my $inetwxmlns="http://tempuri.org/";

      my $method = SOAP::Data->name('GetSMforApplication')->prefix('ns');

      my @SOAPparam;
      push(@SOAPparam,SOAP::Data->name("QueryName")
           ->type("")->prefix('ns')->value("w5baseid"));
      push(@SOAPparam,SOAP::Data->name("QueryValue")
           ->type("")->prefix('ns')->value($arec->{id}));



      my $soap=SOAP::Lite->uri($inetwxmlns)->proxy($wsproxy)
                         ->on_action(sub{'"'.$inetwxmlns.$_[1].'"'});
      $soap->serializer->register_ns($inetwxmlns,'ns');

      my $res;
      eval('$res=$soap->call($method=>@SOAPparam);'); 
      if (!defined($res) || ($@=~m/Connection refused/)){
         msg(ERROR,"can not connect to ".$wsproxy);
         return({exitcode=>10,
                 msg=>'can not connect to INetwork - Connection refused'});
      }

      if ($res->fault){
         $self->Log(ERROR,"trigger","INetwork: ".$res->fault->{faultstring});
         return({exitcode=>2,msg=>"check on id $arec->{id} results: ".
                                  $res->fault->{faultstring}});
      }
      my $indata=$res->result();
      if (ref($indata) eq "HASH" && exists($indata->{SMAppData})){
printf STDERR ("fifi ref=%s\n",ref($indata->{SMAppData}));
         if (ref($indata->{SMAppData}) eq "HASH"){
            $self->processRecord($indata->{SMAppData});
         }
         else{
            $self->{problems}->{"701".NowStamp()}=
            "Invalid response from I-Network for '$arec->{name}' ($arec->{id})";
         }
      }
      else{
         if ($arec->{opmode} eq "" || $arec->{opmode} eq "prod"){
            $self->{problems}->{"801".NowStamp()}=
            "'$arec->{name}' ($arec->{id}/$arec->{opmode}) ".
            "not found in IN";
         }
      }
   }
   if ($param{nonotify} ne "1" && keys(%{$self->{problems}})){
      my $msg=join("\n",map({"* ".$self->{problems}->{$_}}
                            sort(keys(%{$self->{problems}}))));
      my $act=getModuleObject($self->Config,"base::workflowaction");
      $act->Notify(ERROR,"Problems while I-Network import",
                   "Found  problems ".
                   "while import I-Network informations!\n\n".$msg,
                   emailfrom=>'"I-Network to Darwin" <>',
                   emailto=>['11697377440001'], # I-Network service user
                   adminbcc=>1,
                  );
   }
   return({exitcode=>0,msg=>"ok - checked $n records"});
}

sub processRecord
{
   my $self=shift;
   my $d=shift;

   my $userid=$self->getContactEntryId({
          email=>UTF8toLatin1($d->{'smEmail'}),
          surname=>UTF8toLatin1($d->{'smSurname'}),
          givenname=>UTF8toLatin1($d->{'smGivenname'}),
          office_location=>UTF8toLatin1($d->{'smLocation'}),
          office_phone=>UTF8toLatin1($d->{'smPhone'}),
          usertyp=>'extern',
          comments=>'automatic contact import from I-Network',
          allowifupdate=>'1',
          cistatusid=>'4'});

   my $w5baseid=$d->{'w5baseId'};
   my $w5basename=$d->{'w5baseAppname'};
   my $inname=$d->{'inetworkAppname'};
   my $inid=$d->{'inetworkId'};

   print Dumper($d);

#
   my $appl=getModuleObject($self->Config,"TCOM::custappl");

   $appl->SetFilter({id=>\$w5baseid});
   my ($arec,$msg)=$appl->getOnlyFirst(qw(id name wbvid 
                                          custname custnameid));
   if (!defined($arec)){
      $self->{problems}->{"900".NowStamp()}=
          "Application '$w5basename' ($w5baseid) not found in w5base";
      return(undef);
   }

   if (lc($arec->{name}) ne lc($w5basename)){
      $self->{problems}->{"901".NowStamp()}=
          "W5base Appname ($w5basename) does not match IN-Name $arec->{name}";
      return(undef);
   }

   if ($arec->{wbvid} ne $userid ||
       $arec->{custname} ne $inname ||
       $arec->{custnameid} ne "IN:$inid"){
      if (!$appl->ValidatedUpdateRecord($arec,{
             wbvid=>$userid,
             custname=>$inname,
             custnameid=>"IN:$inid"
         },{id=>\$w5baseid})){
         $self->{problems}->{"902".NowStamp()}=
             "Appname ($w5basename) fail to update data";
         return(undef);
      }
   }
   return(1);
}


sub getContactEntryId
{
   my $self=shift;
   my $d=shift;

   if (!($d->{'email'}=~m/^\S+\@\S+$/)){
      $self->{problems}->{"100".lc($d->{'email'})}=
          "Invalid smEmail '$d->{'email'}'";
      return(undef);
   }

   my $user=getModuleObject($self->Config,"base::user");
   $user->SetFilter({email=>$d->{'email'}});
   my ($urec,$msg)=$user->getOnlyFirst(qw(userid));
   if (!defined($urec)){
      my $chk=$d->{'email'};
      $chk=~s/\@.*/\@*/;
printf STDERR ("fifi check=$chk\n");exit(1);
      $user->ResetFilter();
      $user->SetFilter({email=>$chk});
      my ($urec,$msg)=$user->getOnlyFirst(qw(userid));
      if (defined($urec)){
           $self->{problems}->{"100".lc($d->{'email'})}=
               "auto create '$d->{'email'}' failed - similar contact exists";
         return(undef);
      }

      if (($d->{'email'}=~m/^\S+$/) &&
          ($d->{'surname'}=~m/\S{2}/) &&
          ($d->{'givenname'}=~m/\S{2}/) &&
          ($d->{'office_location'}=~m/\S{2}/) &&
          ($d->{'office_phone'}=~m/\S{2}/)){
         my $userid=$user->ValidatedInsertRecord($d);
         if ($userid ne ""){
           $self->{problems}->{"102".lc($d->{'email'})}=
               "New created contact email '$d->{'email'}'";
            return($userid);
         }
      }
      else{
        $self->{problems}->{"101".lc($d->{'email'})}=
            "Incomplete Contact for new contact at email '$d->{'email'}'";
      }


      $self->{problems}->{"100".lc($d->{'email'})}=
          "W5Base Contact with email '$d->{'email'}' does not exists";
      return(undef);
   }
   return($urec->{userid});
}




1;
