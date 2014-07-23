package base::W5Server::Enrichment;
use strict;
use IO::Select;
use IO::Socket;
use kernel;
use kernel::date;
use kernel::W5Server;
use FileHandle;
use POSIX;
use vars (qw(@ISA));
@ISA=qw(kernel::W5Server);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub process
{
   my $self=shift;

   while(1){
      $self->EnrichmentCollector();
      sleep(600);
   }
}

sub EnrichmentCollector
{
   my $self=shift;
 
   my $qrule=getModuleObject($self->Config,"base::qrule");

   POSIX::nice(15); # process AutoDiscovery in lowest process priority

   #######################################################################
   #
   #  Unix-Socket command reader
   #
   my $statepath=$self->Config->Param("W5ServerState");
   my $socket_path=$statepath."/enrichment.sock";
   unlink($socket_path);
   my $main_socket=IO::Socket::UNIX->new(Local => $socket_path,
                                Type      => SOCK_STREAM,
                                Listen    => 5 );
   my $readable_handles = new IO::Select();
   $readable_handles->add($main_socket);
   my @slot=(undef,undef,undef,undef,undef,undef,undef);
   $self->{task}=[];
   my %cons=();
   my $last_taskCreator=0;
   $self->{console}=\%cons;
   my %SrvStat=(start=>time(),tasklist=>$self->{task});
   while (1) {  #Infinite loop
       if (!$qrule->Ping()){
          sleep(120); # etwas warten - dann sollte die DB wieder da sein
          die("lost connection to database - Restart needed");
       }
       my ($newsock)=IO::Select->select($readable_handles,undef,undef,1);
       $SrvStat{loopcount}++;
       $SrvStat{consolen}=keys(%cons);
       $self->slotHandler(\%SrvStat,\@slot);  # executes tasks if is space 
       foreach my $sock (@$newsock) {         # in slots
           if ($sock == $main_socket) {
               my $new_sock = $sock->accept();
               $readable_handles->add($new_sock);
               $cons{$new_sock}={handle=>$new_sock};
           } else {
               my $buf = <$sock>;
               if ($buf) {
                   my $command=$buf;
                   $command=~s/\s*$//;
                   $self->processConsoleCommand(\%SrvStat,
                                                \%cons,$sock,$command);
               } else {
                   delete($cons{$sock});
                   $readable_handles->remove($sock);
                   close($sock);
               }
           }
       }   
       if ($last_taskCreator==0 ||
           $last_taskCreator<time()-30){  # call taskCreator every half minute
          $self->taskCreator(\%SrvStat);     
          $last_taskCreator=time();
       }
   }
   #######################################################################
}

sub processConsoleCommand
{
   my $self=shift;
   my $reporter=shift;
   my $cons=shift;
   my $client=shift;
   my $command=shift;
   my $reportjob=$reporter->{reportjob};

   if ($command eq ""){
   }
   elsif ($command eq "uptime"){
      printf $client ("uptime: %d\n",$reporter->{start});
   }
   elsif ((my $module)=$command=~m/^run\s+(\S+)$/){
      if (exists($reportjob->{Reporter}->{$module})){
         $self->addTask($module);
         $reportjob->{Reporter}->{$module}->{lastrun}=NowStamp("en");
         printf $client ("OK\n"); 
      }
      else{
         printf $client ("ERROR: Invalid module name '%s'\n",$module); 
      }
   }
   #elsif ($command eq "exit"){
   #   close($client);
   #}
   elsif ($command eq "status"){
      my %d=%$reporter;
      delete($d{reportjob});
      my $d=Dumper(\%d);
      $d=~s/^.*?{/{/;
      printf $client ("status: %s\n",$d);
      printf $client ("Loaded modules:\n");
      foreach my $module (sort(keys(%{$reportjob->{Reporter}}))){
         printf $client ("- %s\n",$module);
      }
   }
   elsif ($command eq "shutdown"){
      $self->Shutdown();
      exit(0);
   }
   else{
      printf $client ("ERROR: unkown command '%s'\n",$command);
   }

}


sub taskCreator
{
   my $self=shift;
   my $SrvStat=shift;

   if (!defined($self->{toDoPipe})){
      $self->{toDoPipe}=[];
   }

   my $todo=$self->{toDoPipe};

   $self->broadcast("call taskCreator");

   if ($#{$todo}<50){
      msg(DEBUG,"starting QualityCheck");
      my $lnkq=getModuleObject($self->Config,"base::lnkqrulemandator");
      my $qrule=getModuleObject($self->Config,"base::qrule");

      my %dataobjtoenrich=$lnkq->LoadQualityActivationLinks();

      ######################################################################
      # Filter out QualityRules with no enrichment handler
      foreach my $dataobj (sort(keys(%dataobjtoenrich))){
         $self->broadcast("check candidat: $dataobj");
         my @enrichRules=();
         foreach my $mandatorid (keys(%{$dataobjtoenrich{$dataobj}})){
            foreach my $qn (keys(%{$dataobjtoenrich{$dataobj}->{$mandatorid}})){
               if (!($qrule->{qrule}->{$qn}->can("qenrichRecord"))){
                  delete($dataobjtoenrich{$dataobj}->{$mandatorid}->{$qn});
               }
            }
            if (!keys(%{$dataobjtoenrich{$dataobj}->{$mandatorid}})){
               delete($dataobjtoenrich{$dataobj}->{$mandatorid});
            }
         }
         if (!keys(%{$dataobjtoenrich{$dataobj}})){
            delete($dataobjtoenrich{$dataobj});
         }
      }
      ######################################################################

      $self->broadcast("candidats are:".Dumper(\%dataobjtoenrich));

      foreach my $dataobj (sort(keys(%dataobjtoenrich))){
         foreach my $mandatorid (keys(%{$dataobjtoenrich{$dataobj}})){
            my $o=getModuleObject($self->Config,$dataobj);
            if (defined($o)){
               my $idfield=$o->IdField();
               if (defined($idfield)){
                  my $idname=$idfield->Name();
                  my $flt={lastqenrich=>['<now-24h',undef]};
                  if ($mandatorid>0 && defined($o->getField("mandatorid"))){
                     $flt->{mandatorid}=\$mandatorid;
                  }
                  if ($o->getField("cistatusid")){
                     $flt->{cistatusid}=[3,4,5];
                  }
                  $o->SetFilter($flt);
                  $o->SetCurrentView("lastqenrich","mdate",$idname);
                  $o->Limit(50);
                  my ($rec,$msg)=$o->getFirst(unbuffered=>1);
                  if (defined($rec)){
                     do{
                        my $param={qrules=>[
                                      keys(%{$dataobjtoenrich{$dataobj}->{$mandatorid}})
                                   ],
                                   idname=>$idname};
                        push(@{$todo},{
                           name=>$dataobj."::".$rec->{$idname},
                           dataobj=>$dataobj,
                           id=>$rec->{$idname},
                           stdout=>[],stderr=>[],
                           param=>$param,
                           requesttime=>time()
                        });
                        ($rec,$msg)=$o->getNext();
                     }until(!defined($rec));
                  }
               }
            }
         }
      }
   }



   while($#{$self->{task}}<100 && $#{$todo}!=-1){
      my $todorec=shift(@{$todo});
      my $param={};
      push(@{$self->{task}},$todorec);
   }







#   my $todo=$self->{systems};
#
#   if ($#{$todo}==-1){
#      my $sys=getModuleObject($self->Config,"itil::system");
#      $sys->SetFilter({cistatusid=>[3,4]});
#      #$sys->Limit(200,0,0);
#      my @l=$sys->getVal(qw(id));
#      @{$self->{systems}}=@l;
#   }
#   while($#{$self->{task}}<100 && $#{$todo}!=-1){
#      my $system=shift(@{$todo});
#      my $param={};
#      push(@{$self->{task}},{name=>"itil::system::$system",
#                             dataobj=>"itil::system",
#                             id=>$system,
#                             stdout=>[],stderr=>[],
#                             param=>$param,
#                             requesttime=>time()});
#
#   }
}

#sub addTask
#{
#   my $self=shift;
#   my $name=shift;
#   my $param=shift;
#
#   $param->{maxstderr}=128 if (!exists($param->{maxstderr}));
#   $param->{maxstdout}=128 if (!exists($param->{maxstdout}));
#   if ($#{$self->{task}}<100){  # max 100 task in queue
#      $self->broadcast("receive a new task request for $name");
#      push(@{$self->{task}},{name=>$name,stdout=>[],stderr=>[],
#                             param=>$param,
#                             requesttime=>time()});
#      return(1);
#   }
#   return(0);
#}


sub Shutdown
{
   my $self=shift;

}


sub handleSlotIO
{
   my $self=shift;
   my $reporter=shift;
   my $slot=shift;

   while(1){
      my $readedlines=0;
      my $s=new IO::Select();
      $s->add($slot->{stdout});
      $s->add($slot->{stderr});
      my @ready=$s->can_read(0);
      for(my $c=0;$c<=$#ready;$c++){
         my $fh=$ready[$c];
         my $line=<$fh>;
         if ($line){
            $line=~s/\s*$//;
            my $taskname=$slot->{task}->{name};
            if ($fh eq $slot->{stdout}){
               $self->stdout($line,$slot->{task},$reporter);
               $readedlines++;
            }
            if ($fh eq $slot->{stderr}){
               $self->stderr($line,$slot->{task},$reporter);
               $readedlines++;
            }
         }
      }
      last if (!$readedlines);
   }
}







sub slotHandler
{
   my $self=shift;
   my $SrvStat=shift;
   my $slot=shift;

   $SrvStat->{runningJobs}=0;
   $SrvStat->{maxSlots}=$#{$slot}+1;
   $SrvStat->{usedSlots}=0;
   $SIG{CHLD}='DEFAULT';
   for(my $c=0;$c<=$#{$slot};$c++){
      if (defined($slot->[$c])){
         $SrvStat->{usedSlots}++;
         $self->handleSlotIO($SrvStat,$slot->[$c]);
         my $pid=$slot->[$c]->{pid};
         if ((my $sysexitcode=waitpid($pid,WNOHANG))>0){
            my $sig=$?>>8;
            $slot->[$c]->{task}->{waitpidresult}=$sysexitcode; 
            $slot->[$c]->{task}->{exitcode}=$sig; 
            my $module=$slot->[$c]->{task}->{name};
            $self->broadcast("Finish ".$module." slot $c at PID $pid($sig)");
            $self->broadcast("result:".
                             join("\n",@{$slot->[$c]->{task}->{stderr}}));
            $slot->[$c]=undef;
         }
         else{
            if (kill(0,$pid)){
               $SrvStat->{runningJobs}++;
            }
            else{
              # my $module=$slot->[$c]->{task}->{name};
               $self->broadcast("seltsam $pid scheint tot zu sein");
              # my $SrvStatmodules=$SrvStat->{reportjob}->{Reporter};
              # $SrvStatmodules->{$module}->Finish($slot->[$c]->{task},
              #                                     $SrvStat);
               $slot->[$c]=undef;
            }
         }
         
      }
      else{
         my $task=shift(@{$self->{task}});    # load next task from queue
         if (defined($task)){
            $slot->[$c]={task=>$task};
            my ($rSTDERR,$newSTDERR);
            pipe($rSTDERR,$newSTDERR);
            my ($rSTDOUT,$newSTDOUT);
            pipe($rSTDOUT,$newSTDOUT);
            $slot->[$c]->{stdout}=$rSTDOUT;
            $slot->[$c]->{stderr}=$rSTDERR;
            my $pid=fork();                   # fork the task 
            if ($pid==0){
               $|=1;
               close(STDIN);
               $SIG{PIPE}='DEFAULT';
               $SIG{INT}='DEFAULT';
               $SIG{TERM}='DEFAULT';
               $SIG{QUIT}='DEFAULT';
               $SIG{HUP}='DEFAULT';
               $SIG{CHLD}='DEFAULT';

               open(STDERR, ">&".fileno($newSTDERR));
               open(STDOUT, ">&".fileno($newSTDOUT));
               for(my $cc=3;$cc<254;$cc++){  # ensure, that all 
                  POSIX::close($cc);       # filehandles are closed
               }
               $0.="(".$task->{name}.")";
               my $bk=$self->processEnrichment($task->{dataobj},
                                               $task->{id},
                                               $task->{param});
               if (defined($bk) && $bk>0){
               #   printf STDERR ("existcode:$bk\n");
                  exit($bk);
               }
               exit(0);
            }
            else{
               $self->broadcast("starting job $task->{name} at ".
                                "slot $c on pid $pid");
               $slot->[$c]->{pid}=$pid;
               $SrvStat->{jobcount}++
            }
         }
      }
   }
}


sub stdout              # will be called on stdout line output
{
   my $self=shift;
   my $line=shift;
   my $task=shift;
   my $reporter=shift;
   push(@{$task->{stdout}},$line);
   if (defined($task->{param}->{maxstdout})){
      if ($#{$task->{stdout}}>$task->{param}->{maxstdout}){
         shift(@{$task->{stdout}});
      }
   }
   #printf STDERR ("%s(OUT):%s\n",$self->Self,$line);
}

sub stderr             # will be called on stderr line output
{
   my $self=shift;
   my $line=shift;
   my $task=shift;
   my $reporter=shift;
   if (!($line=~m/^INFO:/)){
      push(@{$task->{stderr}},$line);
      if (defined($task->{param}->{maxstderr})){
         if ($#{$task->{stderr}}>$task->{param}->{maxstderr}){
            shift(@{$task->{stderr}});
         }
      }
   }
}



sub processEnrichment
{
   my $self=shift;
   my $dataobj=shift;
   my $id=shift;
   my $param=shift;

   my $idname=$param->{idname};
   my $rec;

   printf STDERR ("fifi $dataobj -> $id\n");
   my $obj=getModuleObject($self->Config,$dataobj);
   if (defined($obj) && $idname ne ""){
      $obj->SetFilter({$idname=>\$id});
      my ($rec)=$obj->getOnlyFirst(qw(ALL));
      my $qr=getModuleObject($self->Config,"base::qrule");

      foreach my $qrulename (@{$param->{qrules}}){
         my $qrule=$qr->{qrule}->{$qrulename};
         my $oldcontext=$W5V2::OperationContext;
         $W5V2::OperationContext="Enrichment";
         my $dataModified=0;
         if ($qrule->can("qenrichRecord")){
           $dataModified=$qrule->qenrichRecord($obj,$rec,$param);
         }
         $W5V2::OperationContext=$oldcontext;
         if ($dataModified){ # reload rec is a ToDo
            my $reloadedRec=$qr->reloadRec($obj,$rec);
            if (!defined($reloadedRec)){
               msg(ERROR,"reloadRec error after enrichment");
               return();
            }
            $rec=$reloadedRec;
         }
      }

      $obj->ValidatedUpdateRecord($rec,{lastqenrich=>NowStamp("en"),
                                        mdate=>$rec->{mdate}},
                                  {$idname=>\$id});
   }

   return(0);



   my $add=getModuleObject($self->Config,"itil::autodiscdata");
   my $ade=getModuleObject($self->Config,"itil::autodiscengine");
   if (defined($add) && defined($ade)){ # itil:: seems to be installed
      $ade->SetFilter({localdataobj=>\$dataobj});
      foreach my $engine ($ade->getHashList(qw(ALL))){
         my $rk;
         $rk="systemid"     if ($dataobj eq "itil::system");
         $rk="swinstanceid" if ($dataobj eq "itil::swinstance");
         $add->SetFilter({$rk=>\$rec->{id},engine=>\$engine->{name}});
         my ($oldadrec)=$add->getOnlyFirst(qw(ALL));
         # check age of oldadrec - if newer then 24h - use old one
            # todo

         my $ado=getModuleObject($self->Config,$engine->{addataobj});
         if (!exists($rec->{$engine->{localkey}})){
            # autodisc key data does not exists in local object
            msg(ERROR,"preQualityCheckRecord failed for $dataobj ".
                      "local key $engine->{localkey} does not exists");
            next;
         }
         if (defined($ado)){  # check if autodisc object name is OK
            my $adokey=$ado->getField($engine->{adkey});
            if (defined($adokey)){ # check if autodisc key is OK
               my $adfield=$add->getField("data");
               $ado->SetFilter({
                  $engine->{adkey}=>\$rec->{$engine->{localkey}}
               });
               my ($adrec)=$ado->getOnlyFirst(qw(ALL));
               if (defined($adrec)){
                  if ($ado->Ping()){
                     $adrec->{xmlstate}="OK";
                     my $adxml=hash2xml({xmlroot=>$adrec});
                     if (!defined($oldadrec)){
                        $add->ValidatedInsertRecord({engine=>$engine->{name},
                                                     $rk=>$rec->{id},
                                                     data=>$adxml});
                     }
                     else{
                        my $upd={data=>$adxml};
                        my $chk=$adfield->RawValue($oldadrec);
                        if (trim($upd->{data}) eq trim($chk)){  # wird verm.
                           delete($upd->{data});    # sein, da XML im Aufbau
                           $upd->{mdate}=$oldadrec->{mdate}; # dynamisch ist
                        }
                        $add->ValidatedUpdateRecord($oldadrec,$upd,{
                           engine=>\$engine->{name},
                           $rk=>\$rec->{id}
                        });
                     }
                  }
               }
            }
            $ado->{DB}->Disconnect();
         }
         else{
            msg(ERROR,"preQualityCheckRecord failed for $dataobj ".
                      "while load AutoDisc($engine->{name}) object ".
                       $engine->{addataobj});
         }
         sleep(1); # reduce process load
      }
   }
   # now qrule based enrichment
}

sub broadcast
{
   my $self=shift;
   my $msg=shift;

   foreach my $cons (values(%{$self->{console}})){
      my $h=$cons->{handle};
      printf $h ("%s: %s\n",NowStamp("en"),$msg);
   }
}




sub reload
{
   my $self=shift;
   $self->{doForceCleanup}++;
}










1;


