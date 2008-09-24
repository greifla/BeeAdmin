package base::event::cleanup;
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


   $self->RegisterEvent("CleanupWorkflows","CleanupWorkflows");
   $self->RegisterEvent("CleanupLnkGrpUser","LnkGrpUser");
   return(1);
}



sub CleanupWorkflows
{
   my $self=shift;
   my $wf=getModuleObject($self->Config,"base::workflow");


   foreach my $stateid (qw(16 17 10)){
      $wf->SetFilter({stateid=>\$stateid,
                      class=>"*::diary",
                      mdate=>'<now-56d'});
      $wf->SetCurrentView(qw(id closedate stateid class));
      $wf->SetCurrentOrder(qw(NONE));
      $wf->Limit(100);
      my $c=0;
      
      my ($rec,$msg)=$wf->getFirst();
      if (defined($rec)){
         do{
            msg(INFO,"process $rec->{id} class=$rec->{class}");
            if (1){
               if ($wf->Action->StoreRecord($rec->{id},"wfautofinish",
                   {translation=>'base::workflowaction'},"",undef)){
                  my $closedate=$rec->{closedate};
                  $closedate=NowStamp("en") if ($closedate eq "");
                  printf STDERR ("info: fifi autoclose wfid=$rec->{id}\n");
                
                  $wf->UpdateRecord({stateid=>21,closedate=>$closedate},
                                    {id=>\$rec->{id}});
                  $wf->StoreUpdateDelta({id=>$rec->{id},
                                         stateid=>$rec->{stateid}},
                                        {id=>$rec->{id},
                                         stateid=>21});
               }
            }
            ($rec,$msg)=$wf->getNext();
         } until(!defined($rec));
      }
   }


}

sub LnkGrpUser
{
   my $self=shift;

   my $lnk=getModuleObject($self->Config,"base::lnkgrpuser");
   my $nowstamp=NowStamp("en");
   $lnk->SetFilter({expiration=>"<\"$nowstamp\""});
   my $oldcontext=$W5V2::OperationContext;
   $W5V2::OperationContext="Kernel";

   foreach my $lrec ($lnk->getHashList(qw(ALL))){
      my $dur=CalcDateDuration($lrec->{expiration},$nowstamp);
      my $days=$dur->{totalseconds}/86400;
      if ($days>56){           # das muss irgenwann mal rein
         # sofort l�schen
      }
      elsif($days>30){
         if ($lrec->{alertstate} ne "red"){
            $lnk->ValidatedUpdateRecord($lrec,{alertstate=>'red',
                                               editor=>$lrec->{editor},
                                               roles=>$lrec->{roles},
                                               realeditor=>$lrec->{realeditor},
                                               mdate=>$lrec->{mdate}},
                                       {lnkgrpuserid=>\$lrec->{lnkgrpuserid}});
         }
         # l�schen wenn alertstate=red
         {
            # red setzen
         }
      }
      elsif($days>14){
         if ($lrec->{alertstate} ne "orange"){
            $lnk->ValidatedUpdateRecord($lrec,{alertstate=>'orange',
                                               editor=>$lrec->{editor},
                                               roles=>$lrec->{roles},
                                               realeditor=>$lrec->{realeditor},
                                               mdate=>$lrec->{mdate}},
                                       {lnkgrpuserid=>\$lrec->{lnkgrpuserid}});
         }
         # orange setzen und mail verschicken
      } 
      else{
         # yellow setzen und mail verschicken
         if ($lrec->{alertstate} ne "yellow"){
            $lnk->ValidatedUpdateRecord($lrec,{alertstate=>'yellow',
                                               editor=>$lrec->{editor},
                                               realeditor=>$lrec->{realeditor},
                                               roles=>$lrec->{roles},
                                               mdate=>$lrec->{mdate}},
                                       {lnkgrpuserid=>\$lrec->{lnkgrpuserid}});
         }
      }
      
     # msg(INFO,Dumper($lrec));
     # msg(INFO,Dumper($dur));
   }
   $W5V2::OperationContext=$oldcontext;

#   my $wf=getModuleObject($self->Config,"base::workflow");
#   if (my $id=$wf->Store(undef,{
#          class    =>'base::workflow::mailsend',
#          step     =>'base::workflow::mailsend::dataload',
#          name     =>'eine Mail vom Testevent1 mit ����',
#          emailtext=>'Hallo Welt'
#         })){
#      my $r=$wf->Store($id,step=>'base::workflow::mailsend::waitforspool');
#      return({msg=>'versandt'});
#   }
   return({msg=>'shit'});
}




1;
