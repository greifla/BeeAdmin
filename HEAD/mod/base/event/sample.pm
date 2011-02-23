package base::event::sample;
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


   $self->RegisterEvent("wiwTest","wiwTest");
   $self->RegisterEvent("wftest","wftest");
   $self->RegisterEvent("memtest","memtest");
   $self->RegisterEvent("filecheck","filecheck");
   $self->RegisterEvent("test","test");
   $self->RegisterEvent("sample","SampleEvent1");
   $self->RegisterEvent("sample1","SampleEvent1",timeout=>180);
   $self->RegisterEvent("timeoutcheck","TimeOutError",timeout=>5);
   $self->RegisterEvent("sample","SampleEvent2");
   $self->RegisterEvent("sample2","SampleEvent2");
   $self->RegisterEvent("sample3","SampleEvent3");
   $self->RegisterEvent("MyTime","SampleEvent2");
   $self->RegisterEvent("long","base::event::sample::SampleEvent1");
   $self->RegisterEvent("long","SampleEvent3");
   $self->RegisterEvent("LongRunner","LongRunner");
   $self->RegisterEvent("loadsys","loadsys");
   $self->RegisterEvent("testmail1","TestMail1");
   $self->RegisterEvent("testmail2","TestMail2");
   $self->CreateIntervalEvent("MyTime",10);
   return(1);
}

sub LongRunner
{
   my $self=shift;

   for(my $c=0;$c<20;$c++){
      msg(DEBUG,"LonRunner Loop $c");
      sleep(1);
   }
   return({exitcode=>0,msg=>'ok'});
}

sub test
{
   my $self=shift;
   my $wf=getModuleObject($self->Config,"base::workflow");








#   msg(INFO,"WfRec=%s",Dumper($WfRec->{additional}));
#   my %newadd=%{$WfRec->{additional}};
#   delete($newadd{xxo});
#   $newadd{ServiceCenterState}="released";
#   $newadd{ServiceCenterState}="confirmed";
#   $newadd{ServiceCenterState}="closed";
#   $wf->Store($WfRec,{additional=>\%newadd});



   return({exitcode=>0,msg=>'ok'});
}

sub filecheck
{
   my $self=shift;
   if (-f "/tmp/file"){
      return({exitcode=>0,msg=>'ok'});
   }
   return({exitcode=>1,msg=>'file not found'});
   
}

sub TimeOutError
{
   my $self=shift;

   sleep(10);
   return({exitcode=>0,msg=>'ok'});
}

sub TestMail1
{
   my $self=shift;

   my $wf=getModuleObject($self->Config,"base::workflow");
   my $r=$wf->Store(12295216960002,{mandator=>['AL T-Com','xx',mandatorid=>44]});
   return({msg=>'shit'});
}

sub TestMail2
{
   my $self=shift;

   my $wf=getModuleObject($self->Config,"base::workflow");
   if (my $id=$wf->Store(undef,{
          class    =>'base::workflow::mailsend',
          step     =>'base::workflow::mailsend::dataload',
          name     =>'eine Mail vom Testevent1 mit ����',
          emailto  =>'vogler.hartmut@xxxxxxxxxxxxxm',
          emailfrom=>'"Vogler, Hartmut" <>',
          emailtext=>["Dies ist der\n 1. Text",'dies der 2.','und der d 100 Zeichen: 12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890ritte'],
          emailhead=>['Head1','Head2 mal ein gaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaanz langer Text1234567345624354357246357832','Head3'],
          emailtstamp=>['01.01.2000 14:14:00',undef,'02.02.2000 01:01:01'],
          emailprefix=>['sued/xxxxxx.hartmut',undef,'nobody'],
         })){
      my $r=$wf->Store($id,step=>'base::workflow::mailsend::waitforspool');
      return({msg=>'versandt'});
   }
   return({msg=>'shit'});
}

sub SampleEvent1
{
   my $self=shift;
   my $p=$self;

   msg(DEBUG,"Start(Event1): ... sleep no");
   my $now=NowStamp("en");
   msg(DEBUG,"DATE now=".$now);
   msg(DEBUG,"DATE ExpandTimeExpression (default)=".
             $p->ExpandTimeExpression($now));
   msg(DEBUG,"DATE ExpandTimeExpression (CET)=".
             $p->ExpandTimeExpression($now,undef,"GMT","CET"));
   msg(DEBUG,"DATE ExpandTimeExpression (CET,de)=".
             $p->ExpandTimeExpression($now,"de","GMT","CET"));
   msg(DEBUG,"DATE ExpandTimeExpression (CET,RFC822)=".
             $p->ExpandTimeExpression($now,"RFC822","GMT","CET"));
   msg(DEBUG,"DATE ExpandTimeExpression (UTC,RFC822)=".
             $p->ExpandTimeExpression($now,"RFC822","GMT","UTC"));
   msg(DEBUG,"DATE ExpandTimeExpression (CET,stamp)=".
             $p->ExpandTimeExpression($now,"stamp","GMT","CET"));




   msg(DEBUG,"End  (Event1):");
   return({msg=>'heinz',exitcode=>0});
}


sub wftest
{
   my $self=shift;

   eval("use Time::HiRes qw( usleep time clock);");
   foreach my  $mod (qw(base::user base::grp base::workflow)){
      my $st=Time::HiRes::time();
      msg(DEBUG,"Start(wftest\@$mod): %lf",$st);
      my $o=getModuleObject($self->Config,$mod);
      if (defined($o)){
         my $en=Time::HiRes::time();
         my $t=$en-$st;
         msg(DEBUG,"End(wftest\@$mod):%lf   = op:%lf",$en,$t);
      }
   }


   return({exitcode=>0});
}


sub memtest
{
   my $self=shift;

   msg(DEBUG,"Start(memtest):");
   eval("use GTop;"); 
   msg(DEBUG,"W5V2::Cache=%s\n",join(",",keys(%{$W5V2::Cache->{w5base2}})));
   msg(DEBUG,"W5V2::Context=%s\n",join(",",keys(%{$W5V2::Context})));
   my $g0=GTop->new->proc_mem($$);
   for(my $cc=0;$cc<50;$cc++){ 
      my $g1=GTop->new->proc_mem($$);
      for(my $c=0;$c<10000;$c++){ 
         my $e=NowStamp("en");
      }
      my $g=GTop->new->proc_mem($$);
      msg(DEBUG,"loop=%02d mem=".$g->vsize." total=%d loopdelta=%d\n",$cc,$g-$g0,$g-$g1);
   }
   msg(DEBUG,"End  (memtest):");
   msg(DEBUG,"W5V2::Context=%s\n",join(",",keys(%{$W5V2::Context})));
   msg(DEBUG,"W5V2::Cache=%s\n",join(",",keys(%{$W5V2::Cache->{w5base2}})));
   return({exitcode=>0});
}


sub SampleEvent2
{
   my $self=shift;

   my $user=getModuleObject($self->Config,"tsacinv::system");
   msg(DEBUG,"user=$user");
   msg(DEBUG,"Start(Event2):");
   my $n=$user->CountRecords();
   msg(DEBUG,"End(Event2): n=$n");
   return({exitcode=>-1});
}

sub wiwTest
{
   my $self=shift;

   my $st=Time::HiRes::time();
   msg(DEBUG,"Start(wiwTest): %lf",$st);
   my $user=getModuleObject($self->Config,"tswiw::user");
   msg(DEBUG,"ModuleFound(wiwTest) \@ sec %lf",Time::HiRes::time()-$st);
   $user->SetFilter({surname=>'Vog*',givenname=>'*mut'});
   msg(DEBUG,"CountStart(wiwTest) \@ sec %lf",Time::HiRes::time()-$st);
   my $n=$user->CountRecords();
   msg(DEBUG,"End(wiwTest) \@ sec %lf",Time::HiRes::time()-$st);
   return({exitcode=>0});
}

sub SampleEvent3
{
   my $self=shift;
   my $sec=shift;
   my $this="SampleEvent3";
   $sec=3 if (!defined($sec));

   msg(DEBUG,"Start(Event3) config=%s",$self->Config);
   for(my $c=0;$c<$sec;$c++){
      msg(DEBUG,"Wait(Event3): ... sleep 1");sleep(1);
      $self->ipcStore("working at $c");
   }
   msg(DEBUG,"End  (Event3): self=$self ipc=$self->{ipc}");
   return({result=>"jo"});
}

sub loadsys
{
   my $self=shift;
   my $name=shift;
   my $res={};

   my $sys=getModuleObject($self->Config,"itil::system");
   if (!$sys->Ping()){
      return({msg=>'ping failed to dataobject '.$sys->Self(),exitcode=>1});
   }



   $sys->SetFilter({name=>$name});
   my @l=$sys->getHashList(qw(systemid assetassetid systemname));
printf STDERR ("res=%s\n",Dumper(\@l));
   $res=$l[0]->{assetassetid};


   return($res); 
}





1;
