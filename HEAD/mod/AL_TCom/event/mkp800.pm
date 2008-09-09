package AL_TCom::event::mkp800;
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


   $self->RegisterEvent("mkp800","mkp800");
   return(1);
}

sub mkp800
{
   my $self=shift;
   my %param=@_;
   my $app=$self->getParent;
   my @monthlist;
   my $xlsexp={};

   #
   # ACHTUNG: Die Monatsgrenze f�r P800 Reports ist GMT und nicht CET!!!
   #
   $ENV{LANG}="de";
   $param{timezone}="GMT" if (!defined($param{timezone}));
   if (defined($param{month})){
      if (my ($sM,$sY)=$param{month}=~m/^(\d+)\/(\d+)$/){
         $sM=undef if ($sM<1);
         $sM=undef if ($sM>12);
         $sY=undef if ($sY<2000);
         $sY=undef if ($sY>2100);
         if (!defined($sM) || !defined($sY)){
            msg(ERROR,"illegal month $param{month}");
            return({exicode=>1});
         }
         my $eM=$sM-1;
         my $eY=$sY;
         if ($eM==1){
            $sM=12;
            $sY=$eY-1;
         }
         @monthlist=(sprintf("%02d/%04d",$eM,$eY),$param{month});
      }
      elsif (defined($param{month})){
         msg(ERROR,"illegal month $param{month}");
         return({exicode=>1});
      }
   }
   else{
      my ($year,$month,$day, $hour,$min,$sec) = Today_and_Now("GMT");
      my $eM=$month;
      my $eY=$year;
      my $sM=$month-1;
      my $sY=$year;
      if ($eM==1){
         $sM=12;
         $sY=$eY-1;
      }
      @monthlist=(sprintf("%02d/%04d",$sM,$sY),
                  sprintf("%02d/%04d",$month,$year));
   }
   my $bflexxp800=getModuleObject($self->Config,"tsbflexx::p800sonder");

   my %p800special=();
   foreach my $month (@monthlist){
      my ($sM,$sY)=$month=~m/^(\d+)\/(\d+)$/;
      my $eM=$sM+1;
      my $eY=$sY;
      if ($sM==12){
         $eM=1;
         $eY=$sY+1;
      }
      my $start=$month;
      my $end=sprintf("%02d/%04d",$eM,$eY);
      my $starttime=$app->ExpandTimeExpression($start,"en",$param{timezone});
      my $endtime=$app->ExpandTimeExpression($end."-1s","en",$param{timezone});

     
      msg(DEBUG,"Report : $start\n");
      msg(DEBUG,"Report start ($start): >=$starttime\n");
      msg(DEBUG,"Report end   ($end): <=$endtime\n");
      
      my $wf=getModuleObject($self->Config,"base::workflow");
      $wf->SetCurrentOrder("NONE");
      $wf->SetCurrentView(qw(id name affectedcontractid 
                                     affectedcontract
                                     affectedapplicationid
                                     wffields.tcomcodrelevant
                                     wffields.tcomcodcause
                                     wffields.tcomexternalid
                                     wffields.tcomcodcomments
                                     affectedapplication
                             headref class step stateid eventend
                             srcid srcsys));
      $wf->SetFilter(eventend=>"\">=$starttime\" AND \"<=$endtime\"",
                     class=>[grep(/^AL_TCom::.*$/,keys(%{$wf->{SubDataObj}}))]);
      #$wf->SetFilter({srcid=>"CHM00283030"});
      my %nocontract=();
      my %p800=();
      my ($rec,$msg)=$wf->getFirst();
      if (defined($rec)){
         do{
            if (ref($rec->{affectedcontractid}) eq "ARRAY" &&
                $rec->{tcomcodrelevant} eq "yes" &&
                $rec->{stateid}>=17 ){
               $self->processRec($start,\%p800,$rec);
               $self->processRecSpecial($start,\%p800special,$rec,
                                        $xlsexp,$bflexxp800,$monthlist[1]);
            }
            else{
               if (defined($rec->{srcid})){
                  $nocontract{$rec->{srcid}}=1;
               }
            }
            ($rec,$msg)=$wf->getNext();
         } until(!defined($rec));
      }
     
      my $now=$app->ExpandTimeExpression("now","en","CET");
      my $contr=getModuleObject($self->Config,"itil::custcontract");
      $contr->SetFilter(cistatusid=>[3,4]);
      foreach my $contrrec ($contr->getHashList(qw(id))){
         $p800{$contrrec->{id}}={} if (!defined($p800{$contrrec->{id}}));
      }
      my $appl=getModuleObject($self->Config,"itil::appl");
      foreach my $cid (keys(%p800)){
         my $rec=$p800{$cid};
         $contr->ResetFilter;
         $contr->SetFilter(id=>\$cid);
         my ($contrrec,$msg)=$contr->getOnlyFirst(qw(ALL));
         next if (!defined($contrrec)); 
         $rec->{affectedapplicationid}=[];
         $rec->{affectedapplication}=[];
         if (ref($contrrec->{applications}) eq "ARRAY"){
            foreach my $apprec (@{$contrrec->{applications}}){
               if (defined($apprec->{applid})){
                  push(@{$rec->{affectedapplicationid}},$apprec->{applid});
               }
               if (defined($apprec->{appl})){
                  push(@{$rec->{affectedapplication}},$apprec->{appl});
               }
            }
         }
         $rec->{p800_app_applicationcount}=$#{$rec->{affectedapplicationid}}+1; 
         foreach my $applid (@{$rec->{affectedapplicationid}}){
            $appl->SetFilter(id=>\$applid);
            my ($arec,$msg)=$appl->getOnlyFirst("interfaces","systems");
            if (defined($arec) && defined($arec->{interfaces}) &&
                ref($arec->{interfaces}) eq "ARRAY"){
               foreach my $irec (@{$arec->{interfaces}}){
                  $rec->{p800_app_interfacecount}++;
               }
            }
            if (defined($arec) && defined($arec->{systems}) &&
                ref($arec->{systems}) eq "ARRAY"){
               foreach my $srec (@{$arec->{systems}}){
                  $rec->{p800_sys_count}++;
               }
            }
         }
         $rec->{srcsys}=$self->Self;
         $rec->{srcid}="${start}-".$cid;
         $rec->{class}='AL_TCom::workflow::P800';
         $rec->{step}='AL_TCom::workflow::P800::dataload';
         $rec->{stateid}=1;
         $rec->{createdate}=$now;
         $rec->{srcload}=$now;
         $rec->{closedate}=undef;
         $rec->{eventstart}=$starttime;
         $rec->{eventend}=$endtime;
         $rec->{openuser}=undef;
         $rec->{affectedcontractid}=[$contrrec->{id}];
         $rec->{affectedcontract}=[$contrrec->{name}];
         $rec->{name}="P800 - $start - ".$contrrec->{name};
         foreach my $v (qw(p800_app_changecount_customer
                           p800_app_change_customerwt
                           p800_app_incidentwt
                           p800_app_changewt
                           p800_sys_count
                           p800_app_applicationcount p800_app_interfacecount
                           p800_app_changecount p800_app_incidentcount
                           p800_app_specialcount p800_app_speicalwt 
                           p800_app_customerwt
                        )){
            $rec->{$v}=0 if (!defined($rec->{$v}));
         } 
         if ($contrrec->{fullname} ne ""){
            $rec->{name}.=" - ".$contrrec->{fullname};
         }
     
         $wf->SetCurrentView(qw(ALL));
         $wf->SetFilter({srcsys=>\$rec->{srcsys},
                         srcid=>\$rec->{srcid}});
         my $idfname=$wf->IdField()->Name();
         my $found=0;
         $wf->ForeachFilteredRecord(sub{
               my $oldrec=$_;
               $found++;
               if ($oldrec->{stateid}<20){
                  $wf->ValidatedUpdateRecord($oldrec,$rec,
                                               {$idfname=>$oldrec->{$idfname}});
               }
         });
         if (!$found){
            my $id=$wf->ValidatedInsertRecord($rec);
         }
      }
      my $srcsys=$self->Self;
      $wf->SetFilter(srcsys=>\$srcsys,srcid=>"$start-*",
                     srcload=>"\"<$now\"",stateid=>\'1',
                     class=>\'AL_TCom::workflow::P800',
                     step=>\'AL_TCom::workflow::P800::dataload');
      $wf->ForeachFilteredRecord(sub{
          $wf->ValidatedDeleteRecord($_);
      });
      if (defined($monthlist[1]) && $month eq $monthlist[1]){
         foreach my $cid (keys(%{$p800special{$month}})){
            my $rec=$p800special{$month}->{$cid};
            $contr->ResetFilter;
            $contr->SetFilter(id=>\$cid);
            my ($contrrec,$msg)=$contr->getOnlyFirst(qw(ALL));
            next if (!defined($contrrec)); 
            $rec->{affectedapplicationid}=[];
            $rec->{affectedapplication}=[];
            if (ref($contrrec->{applications}) eq "ARRAY"){
               foreach my $apprec (@{$contrrec->{applications}}){
                  if (defined($apprec->{applid})){
                     push(@{$rec->{affectedapplicationid}},$apprec->{applid});
                  }
                  if (defined($apprec->{appl})){
                     push(@{$rec->{affectedapplication}},$apprec->{appl});
                  }
               }
            }
            $rec->{srcsys}=$self->Self;
            $rec->{srcid}="${start}-".$cid."-special";
            $rec->{class}='AL_TCom::workflow::P800special';
            $rec->{step}='AL_TCom::workflow::P800special::dataload';
            $rec->{stateid}=21;
            $rec->{createdate}=$now;
            $rec->{srcload}=$now;
            $rec->{closedate}=$now;

            my $rstart=$app->ExpandTimeExpression("$month+19d-1M","en",
                                                  $param{timezone});
            my $rend=$app->ExpandTimeExpression("$month+19d-1s","en",
                                                $param{timezone});
      
            $rec->{eventstart}=$rstart;
            $rec->{eventend}=$rend;
            $rec->{openuser}=undef;
            $rec->{affectedcontractid}=[$contrrec->{id}];
            $rec->{affectedcontract}=[$contrrec->{name}];
            $rec->{name}="P800 Sonderleistung - $start - ".$contrrec->{name};
            foreach my $v (qw(p800_app_speicalwt 
                           )){
               $rec->{$v}=0 if (!defined($rec->{$v}));
            } 
            if ($contrrec->{fullname} ne ""){
               $rec->{name}.=" - ".$contrrec->{fullname};
            }
           
            $wf->SetCurrentView(qw(ALL));
            $wf->SetFilter({srcsys=>\$rec->{srcsys},
                            srcid=>\$rec->{srcid}});
            my $idfname=$wf->IdField()->Name();
            my $found=0;
            $wf->ForeachFilteredRecord(sub{
                  my $oldrec=$_;
                  $found++;
                  $wf->ValidatedUpdateRecord($oldrec,$rec,
                                              {$idfname=>$oldrec->{$idfname}});
            });
            if (!$found){
               my $id=$wf->ValidatedInsertRecord($rec);
            }

         }
         my $srcsys=$self->Self;
         $wf->SetFilter(srcsys=>\$srcsys,srcid=>"$start-*",
                        srcload=>"\"<$now\"",stateid=>\'21',
                        class=>\'AL_TCom::workflow::P800special',
                        step=>\'AL_TCom::workflow::P800special::dataload');
         $wf->ForeachFilteredRecord(sub{
             $wf->ValidatedDeleteRecord($_);
         });
         $self->xlsFinish($xlsexp,$month);  # stores the xls export in webfs
         $self->bflexxFinish($bflexxp800,$now,$month); 
      }
   }
   return({exitcode=>0});
}

sub processRec
{
   my $self=shift;
   my $start=shift;
   my $p800=shift;
   my $rec=shift;


   msg(DEBUG,"process %s srcid=%s",$rec->{id},$rec->{srcid});
   for(my $c=0;$c<=$#{$rec->{affectedcontractid}};$c++){
      my $cid=$rec->{affectedcontractid}->[$c];
      $p800->{$cid}={} if (!defined($p800->{$cid}));
      if (!defined($rec->{headref}->{tcomworktime})){
          $rec->{headref}->{tcomworktime}=[0]; 
      }
      if (!defined($rec->{headref}->{tcomworktimespecial})){
          $rec->{headref}->{tcomworktimespecial}=[0]; 
      }
      if (ref($rec->{headref}->{tcomworktime}) eq "ARRAY"){
         $rec->{headref}->{tcomworktime}=$rec->{headref}->{tcomworktime}->[0]; 
      }
      if (ref($rec->{headref}->{tcomworktimespecial}) eq "ARRAY"){
         $rec->{headref}->{tcomworktimespecial}=
                 $rec->{headref}->{tcomworktimespecial}->[0]; 
      }
      if ($rec->{class}=~m/::change$/){
         $p800->{$cid}->{p800_app_changecount}++;
         $p800->{$cid}->{p800_app_changewt}+=$rec->{headref}->{tcomworktime};
         if (ref($rec->{headref}->{tcomcodchangetype}) ne "ARRAY"){
            $rec->{headref}->{tcomcodchangetype}=[];
         }
         if ($rec->{headref}->{tcomcodchangetype}->[0] eq "customer"){
            if ($rec->{tcomcodcause} ne "std"){
               $p800->{$cid}->{p800_app_changecount_customer}+=1;
               $p800->{$cid}->{p800_app_customerwt}+=
                               $rec->{headref}->{tcomworktime};
               $p800->{$cid}->{p800_app_change_customerwt}+=
                               $rec->{headref}->{tcomworktime};
            }
         }
      }
      if ($rec->{class}=~m/::diary$/ || $rec->{class}=~m/::businesreq$/){
         if ($rec->{tcomcodcause} ne "std"){
            $p800->{$cid}->{p800_app_specialcount}++;
            $p800->{$cid}->{p800_app_speicalwt}+=
                           $rec->{headref}->{tcomworktime};
            $p800->{$cid}->{p800_app_customerwt}+=
                           $rec->{headref}->{tcomworktime};
         }
         if (ref($rec->{headref}->{tcomcodchangetype}) ne "ARRAY"){
            $rec->{headref}->{tcomcodchangetype}=[];
         }
      }
      if ($rec->{class}=~m/::incident$/){
         $p800->{$cid}->{p800_app_incidentcount}++;
         $p800->{$cid}->{p800_app_incidentwt}+=$rec->{headref}->{tcomworktime};
         if ($rec->{tcomcodcause} ne "std"){
            $p800->{$cid}->{p800_app_speicalwt}+=
                                   $rec->{headref}->{tcomworktimespecial};
         }
      }
   }
}


sub processRecSpecial
{
   my $self=shift;
   my $start=shift;
   my $p800=shift;
   my $rec=shift;
   my $xlsexp=shift;
   my $bflexxp800=shift;
   my $specialmon=shift;

   msg(DEBUG,"special process %s:%s end=%s",
              $rec->{id},$rec->{srcid},$rec->{eventend});
   if ((my ($eY,$eM,$eD,$eh,$em,$es)=$rec->{eventend}=~
          m/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/)){
      my ($wY,$wM,$wD,$wh,$wm,$ws)=($eY,$eM,$eD,$eh,$em,$es);
      eval('($wY,$wM,$wD)=Add_Delta_YMD("GMT",$wY,$wM,$wD,0,1,-19);');
      if ($@ eq ""){
         my $mon=sprintf("%02d/%04d",$wM,$wY);
         return(undef) if ($mon ne $specialmon);
         msg(DEBUG,"report month =%s",$mon);
         if ($rec->{class}=~m/::incident$/){
            $rec->{headref}->{specialt}=$rec->{headref}->{tcomworktimespecial};
         }
         if ($rec->{class}=~m/::diary$/ || $rec->{class}=~m/::businesreq$/){
            $rec->{headref}->{specialt}=$rec->{headref}->{tcomworktime};
         }
         if ($rec->{class}=~m/::change$/){
            if ($rec->{headref}->{tcomcodchangetype}->[0] eq "customer"){
               $rec->{headref}->{specialt}=$rec->{headref}->{tcomworktime};
            }
         }
         if ($rec->{tcomcodcause} ne "std"){
            $self->xlsExport($xlsexp,$rec,$mon,$eY,$eM,$eD);
            $self->bflexxExport($bflexxp800,$rec,$mon,$eY,$eM,$eD);
            for(my $c=0;$c<=$#{$rec->{affectedcontractid}};$c++){
               my $cid=$rec->{affectedcontractid}->[$c];
               my $wt=$rec->{headref}->{specialt};
               if ($wt>0){
                  $p800->{$mon}={} if (!defined($p800->{$mon}));
                  $p800->{$mon}->{$cid}={} if (!defined($p800->{$mon}->{$cid}));
                  msg(DEBUG,"report special process $cid");
                  $p800->{$mon}->{$cid}->{p800_app_speicalwt}+=$wt;
                  if (!defined($p800->{$mon}->{$cid}->{additional})){
                     $p800->{$mon}->{$cid}->{additional}={wfheadid=>[],
                                                          srcid=>[]};
                  }
                  push(@{$p800->{$mon}->{$cid}->{additional}->{wfheadid}},
                       $rec->{id});
                  push(@{$p800->{$mon}->{$cid}->{additional}->{srcid}},
                       $rec->{srcid}) if ($rec->{srcid} ne "");
               }
            }
         }
      }
   }
}


sub bflexxFinish
{
   my $self=shift;
   my $bflexxp800=shift;
   my $now=shift;
   my $repmon=shift;

   my $opobj=$bflexxp800->Clone();
   if (my ($m,$y)=$repmon=~m/^(\d+)\/(\d{4})/){
      $repmon=sprintf("%04d%02d",$y,$m);
   }
   $bflexxp800->ResetFilter(); 
   $bflexxp800->SetFilter(srcload=>"\"<$now\"",month=>\$repmon);
   $bflexxp800->ForeachFilteredRecord(sub{
       $opobj->ValidatedDeleteRecord($_);
   });

}

sub bflexxExport
{
   my $self=shift;
   my $bflexxp800=shift;
   my $rec=shift;
   my $repmon=shift;
   my ($wY,$wM,$wD)=@_;


   if (defined($bflexxp800)){
      my $ag=$rec->{affectedapplication};
      $ag=[$ag] if (!ref($ag) eq "ARRAY");
      my $vert=$rec->{affectedcontract};
      $vert=[$vert] if (!ref($vert) eq "ARRAY");

      my $cause=$rec->{tcomcodcause};
      $cause=join(", ",@$cause) if (ref($cause) eq "ARRAY");

      my $comments=$rec->{tcomcodcomments};
      $comments=join("\n",@$comments) if (ref($comments) eq "ARRAY");

      my $extid=$rec->{tcomexternalid};
      $extid=join("\n",@$extid) if (ref($extid) eq "ARRAY");

      my $specialt=$rec->{headref}->{specialt};
      $specialt=join(", ",@$specialt) if (ref($specialt) eq "ARRAY");

      if (my ($m,$y)=$repmon=~m/^(\d+)\/(\d{4})/){
         $repmon=sprintf("%04d%02d",$y,$m);
      }

      my $newrec={name=>$rec->{name},
                  eventend=>$rec->{eventend},
                  w5baseid=>$rec->{id},
                  tcomworktime=>$specialt,
                  tcomcodcause=>$cause,
                  tcomcodcomments=>$comments,
                  tcomexternalid=>$extid,
                  appl=>join(", ",@$ag),
                  custcontract=>join(", ",@$vert),
                  srcload=>NowStamp("en"),
                  srcid=>$rec->{srcid},
                  month=>$repmon,
                  srcsys=>$rec->{srcsys}};
      $bflexxp800->ValidatedInsertOrUpdateRecord($newrec,
                                              {w5baseid=>\$newrec->{w5baseid}});
   }
}


sub xlsExport
{
   my $self=shift;
   my $xlsexp=shift;
   my $rec=shift;
   my $repmon=shift;
   my ($wY,$wM,$wD)=@_;

   if (!defined($xlsexp->{xls})){
      if (!defined($xlsexp->{xls}->{state})){
         eval("use Spreadsheet::WriteExcel::Big;");
         $xlsexp->{xls}->{state}="bad";
         if ($@ eq ""){
            $xlsexp->{xls}->{filename}="/tmp/out.$$.xls";
            $xlsexp->{xls}->{workbook}=Spreadsheet::WriteExcel::Big->new(
                                                  $xlsexp->{xls}->{filename});
            if (defined($xlsexp->{xls}->{workbook})){
               $xlsexp->{xls}->{state}="ok";
               $xlsexp->{xls}->{worksheet}=$xlsexp->{xls}->{workbook}->
                                           addworksheet("P800 Sonderleistung");
               $xlsexp->{xls}->{format}->{default}=$xlsexp->{xls}->{workbook}->
                                                   addformat(text_wrap=>1,
                                                             align=>'top');
               $xlsexp->{xls}->{format}->{header}=$xlsexp->{xls}->{workbook}->
                                                   addformat(text_wrap=>1,
                                                             align=>'top',
                                                             bold=>1);
               $xlsexp->{xls}->{line}=0;
               my $ws=$xlsexp->{xls}->{worksheet};

               $ws->write($xlsexp->{xls}->{line},0,
                          "Tag.Monat.Jahr (GMT)",
                          $xlsexp->{xls}->{format}->{header});
               $ws->set_column(0,0,17);

               $ws->write($xlsexp->{xls}->{line},1,
                          "AG-Name",
                          $xlsexp->{xls}->{format}->{header});
               $ws->set_column(1,1,40);

               $ws->write($xlsexp->{xls}->{line},2,
                          "Vertrag Nr.",
                          $xlsexp->{xls}->{format}->{header});
               $ws->set_column(2,2,20);

               $ws->write($xlsexp->{xls}->{line},3,
                          "ID im Quellsystem",
                          $xlsexp->{xls}->{format}->{header});
               $ws->set_column(3,3,18);

               $ws->write($xlsexp->{xls}->{line},4,
                          "Ist Sunden",
                          $xlsexp->{xls}->{format}->{header});
               $ws->set_column(4,4,12);

               $ws->write($xlsexp->{xls}->{line},5,
                          "T�tigkeit",
                          $xlsexp->{xls}->{format}->{header});
               $ws->set_column(5,5,30);

               $ws->write($xlsexp->{xls}->{line},6,
                          "Beschreibung",
                          $xlsexp->{xls}->{format}->{header});
               $ws->set_column(6,6,140);

               $ws->write($xlsexp->{xls}->{line},7,
                          "ExternalID",
                          $xlsexp->{xls}->{format}->{header});
               $ws->set_column(7,7,18);

               $xlsexp->{xls}->{line}++;
            }
         }
         
      }
   }
   if (defined($xlsexp->{xls}) && $rec->{headref}->{specialt}>0){
      my $ag=$rec->{affectedapplication};
      $ag=[$ag] if (!ref($ag) eq "ARRAY");
      my $vert=$rec->{affectedcontract};
      $vert=[$vert] if (!ref($vert) eq "ARRAY");
      my $ws=$xlsexp->{xls}->{worksheet};
      my $srcid=$rec->{srcid};
      $srcid=$rec->{id} if ($srcid eq "");
      $ws->write($xlsexp->{xls}->{line},0,
           sprintf("%02d.%02d.%04d",$wD,$wM,$wY),
           $xlsexp->{xls}->{format}->{default});
      $ws->write($xlsexp->{xls}->{line},1,
           join(", ",@$ag),
           $xlsexp->{xls}->{format}->{default});
      $ws->write($xlsexp->{xls}->{line},2,
           join(", ",@$vert),
           $xlsexp->{xls}->{format}->{default});
      $ws->write($xlsexp->{xls}->{line},3,
           $srcid,
           $xlsexp->{xls}->{format}->{default});
      $ws->write($xlsexp->{xls}->{line},4,
           $rec->{headref}->{specialt}/60,
           $xlsexp->{xls}->{format}->{default});

      my $cause=$rec->{headref}->{tcomcodcause};
      $cause=join("",@$cause) if (ref($cause) eq "ARRAY");
      $cause=$self->getParent->T($cause,"AL_TCom::lib::workflow");
      $ws->write($xlsexp->{xls}->{line},5,$cause,
           $xlsexp->{xls}->{format}->{default});
      my $name=$rec->{name};
      if ($self->getParent->Config->Param("UseUTF8")){
         $name=utf8($name)->latin1();
      }
      $ws->write($xlsexp->{xls}->{line},6,$name,
           $xlsexp->{xls}->{format}->{default});

      my $extid=$rec->{headref}->{tcomexternalid};
      $extid=join("",@$extid) if (ref($extid) eq "ARRAY");
      $ws->write($xlsexp->{xls}->{line},7,
           $extid,
           $xlsexp->{xls}->{format}->{default});

      $xlsexp->{xls}->{line}++;
   }
}


sub xlsFinish
{
   my $self=shift;
   my $xlsexp=shift;
   my $repmon=shift;

   if (defined($xlsexp->{xls}) && $xlsexp->{xls}->{state} eq "ok"){
      $xlsexp->{xls}->{workbook}->close(); 
      my $file=getModuleObject($self->Config,"base::filemgmt");
      $repmon=~s/\//./g;
      my $filename=$repmon.".xls";
      if (open(F,"<".$xlsexp->{xls}->{filename})){
         my $dir="TSI-Connect/Konzernstandard-Sonderleistungen";
         $file->ValidatedInsertOrUpdateRecord({name=>$filename,
                                               parent=>$dir,
                                               file=>\*F},
                                              {name=>\$filename,
                                               parent=>\$dir});
      }
      else{
         msg(ERROR,"can't open $xlsexp->{xls}->{filename}");
      }
   }
}


1;
