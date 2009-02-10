package base::w5stat::wfrepjob;
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
use kernel::Universal;
use kernel::date;
use File::Temp;
@ISA=qw(kernel::Universal);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   return($self);
}



sub processDataInit
{
   my $self=shift;
   my $dstrange=shift;
   my %param=@_;
   my $count;

   msg(INFO,"processDataInit in $self");
   my $wfrepjob=getModuleObject(
                $self->getParent->Config,"base::workflowrepjob");
   $self->{RJ}=[];
   foreach my $repjob ($wfrepjob->getHashList(qw(ALL))){
      push(@{$self->{RJ}},$repjob);
   }
   if (!defined($self->{SSTORE})){
      eval("use Spreadsheet::WriteExcel::Big;");
      if ($@ eq ""){
         $self->{SSTORE}={};
      }
   }
}


sub processData
{
   my $self=shift;
   my $dstrange=shift;
   my %param=@_;
   my $count;

   #######################################################################
   if ($param{currentmonth} eq $dstrange){
      my $wf=getModuleObject($self->getParent->Config,"base::workflow");
      $param{DataObj}=$wf;
      my $wfw=$wf->Clone();
      msg(INFO,"starting collect of base::workflow set0 ".
               "- all modified $dstrange");
      $wf->SetFilter({mdate=>">monthbase-1M-2d AND <now"});
      $wf->Limit(540);
      $wf->SetCurrentView(qw(ALL));
      $wf->SetCurrentOrder("NONE");
     
      msg(INFO,"getFirst of base::workflow set0");$count=0;
      my ($rec,$msg)=$wf->getFirst(unbuffered=>1);
      if (defined($rec)){
         do{
            $self->getParent->processRecord('base::workflow::stat',
                                            $dstrange,$rec,%param);
            $count++;
            ($rec,$msg)=$wf->getNext();
         } until(!defined($rec));
      }
      msg(INFO,"FINE of base::workflow set0 $count records");
   }
}

sub processRecord
{
   my $self=shift;
   my $module=shift;
   my $month=shift;
   my $rec=shift;
   my %param=@_;

   if ($module eq "base::workflow::stat"){
      return(undef) if (!exists($self->{SSTORE}));
      msg(INFO,"workflow id=$rec->{id} month=$month");
#      msg(INFO,"         class=$rec->{class}");
      foreach my $repjob (@{$self->{RJ}}){
         if ($self->matchJob($repjob,$rec)){
            my $reftime=$rec->{eventend};
            #############################################################
            #
            # Period berechnen
            my ($Y,$M,$D)=$self->getParent->ExpandTimeExpression(
                                "$reftime-$repjob->{mday}d-1s",
                                undef,"GMT","GMT");
            my $period=sprintf("%04d%02d",$Y,$M);
            ($Y,$M,$D)=Add_Delta_YMD("GMT",$Y,$M,1,0,-1,0);
            my $period1=sprintf("%04d%02d",$Y,$M);

            if ($period eq $param{currentmonth}||
                $period1 eq $param{currentmonth}){
               $self->storeWorkflow($repjob,$rec,$period,\%param);
            }
         }
      }
   }
}

sub matchAttribute
{
   my $repjob=shift;
   my $WfRec=shift;
   my $flt=shift;
   my $attr=shift;

   if ($repjob->{$flt} ne ""){
      if (!($repjob->{$flt}=~m#^/#)){
         return(0) if ($repjob->{$flt} ne $WfRec->{$attr});
      }
      else{
         my $orgflt=$repjob->{$flt};
         my $flt=$orgflt;
         $flt=~s/^\///;
         $flt=~s/\/[i]{0,1}$//;
         #$flt=quotemeta($flt);
         if ($orgflt=~m/i$/){
            return(0) if (!($WfRec->{$attr}=~m/$flt/i));
         }
         else{
            return(0) if (!($WfRec->{$attr}=~m/$flt/));
         }
      }
   }
   return(1);
}


sub matchJob
{
   my $self=shift;
   my $repjob=shift;
   my $WfRec=shift;

   return(0) if (!matchAttribute($repjob,$WfRec,'fltclass','class'));
   return(0) if (!matchAttribute($repjob,$WfRec,'fltstep','step'));
   return(0) if (!matchAttribute($repjob,$WfRec,'fltname','name'));
   return(0) if (!matchAttribute($repjob,$WfRec,'fltdesc','detaildescription'));

   return(1);
}

sub storeWorkflow
{
   my $self=shift;
   my $repjob=shift;
   my $WfRec=shift;
   my $period=shift;
   my $param=shift;
   my $ss=$self->{SSTORE};
   return(undef) if (!defined($self->{SSTORE}));

   my $wbslot=$repjob->{targetfile};
   my $sheetn=$repjob->{name};

   my $slot;
   if (!exists($ss->{$period}->{$wbslot})){
      $ss->{$period}->{$wbslot}={}; 
      $slot=$ss->{$period}->{$wbslot}; 
      my $fh=new File::Temp();
      $slot->{fh}=$fh;
      $slot->{'workbook'}->{o}=Spreadsheet::WriteExcel::Big->new($fh->filename);
      $slot->{'workbook'}->{targetfile}=$repjob->{targetfile};
   }
   $slot=$ss->{$period}->{$wbslot};
#      printf STDERR ("fifi workbook=$slot->{'workbook'}\n");
   if (!exists($slot->{sheet}->{$sheetn." Detail"})){
      $slot->{sheet}->{$sheetn." Detail"}->{o}=
                      $slot->{'workbook'}->{o}->addworksheet($sheetn." Detail");
      $slot->{sheet}->{$sheetn." Detail"}->{line}=1;
   }
   my $sheet=$slot->{sheet}->{$sheetn." Detail"};

   my $fields=["srcid","eventstart","eventend","name"];

   for(my $col=0;$col<=$#{$fields};$col++){
      $ENV{HTTP_FORCE_LANGUAGE}="de";
      my $fieldname=$fields->[$col];
      my $fobj=$param->{DataObj}->getField($fieldname,$WfRec);
      my $data=$fobj->FormatedResult($WfRec,"XlsV01");
      my $format=$fobj->getXLSformatname($data);
#      printf STDERR ("fobj of $fieldname = $fobj v=$v\n");

      if ($format=~m/^date\./){
         $sheet->{'o'}->write_date_time($sheet->{line},$col,$data,
                                               $self->Format($slot,$format));
      }
      else{
         $data="'".$data if ($data=~m/^=/);
         $sheet->{'o'}->write($sheet->{line},$col,$data,
                                     $self->Format($slot,$format));
      }
      delete($ENV{HTTP_FORCE_LANGUAGE});
   }
   $sheet->{line}++;
   

#   if (!exists($ss->{$wbslot}));


   msg(INFO,"store $WfRec->{id}:'$WfRec->{name}'");

   return(1);
}


sub Format
{
   my $self=shift;
   my $slot=shift;
   my $name=shift;
   my $wb=$slot->{workbook};
   return($wb->{format}->{$name}) if (exists($wb->{format}->{$name}));

   my $format;
   if ($name eq "default"){
      $format=$wb->{o}->addformat(text_wrap=>1,align=>'top');
   }
   elsif ($name eq "date.de"){
      $format=$wb->{o}->addformat(align=>'top',
                                          num_format => 'dd.mm.yyyy HH:MM:SS');
   }
   elsif ($name eq "date.en"){
      $format=$wb->{o}->addformat(align=>'top',
                                          num_format => 'yyyy-mm-dd HH:MM:SS');
   }
   elsif ($name eq "longint"){
      $format=$wb->{o}->addformat(align=>'top',num_format => '#');
   }
   elsif ($name eq "header"){
      $format=$wb->{o}->addformat();
      $format->copy($self->Format("default"));
      $format->set_bold();
   }
   elsif (my ($precsision)=$name=~m/^number\.(\d+)$/){
      $format=$wb->{o}->addformat();
      $format->copy($self->Format("default"));
      my $xf="#";
      if ($precsision>0){
         $xf="0.";
         for(my $c=1;$c<=$precsision;$c++){$xf.="0";};
      }
      $format->set_num_format($xf);
   }
   if (defined($format)){
      $self->{format}->{$name}=$format;
      return($self->{format}->{$name});
   }
   print STDERR msg(WARN,"XLS: setting format '$name' as 'default'");
   return($self->Format("default"));
}



sub processDataFinish
{
   my $self=shift;
   my $dstrange=shift;
   my %param=@_;
   my $count;

   my $ss=$self->{SSTORE};
   return(undef) if (!defined($self->{SSTORE}));

   msg(INFO,"processDataFinish in $self");

   foreach my $period (keys(%{$ss})){
      foreach my $wbslot (keys(%{$ss->{$period}})){
         my $slot=$ss->{$period}->{$wbslot};
         $slot->{workbook}->{o}->close();
         my $file=getModuleObject($self->getParent->Config,"base::filemgmt");
         my ($dir,$filename)=$slot->{'workbook'}->{targetfile}=~
            m/^(.*)\/([^\/]+)\.xls$/i;
         $dir=~s/^\///;
         if ($filename eq ""){
            msg(ERROR,"invalid target filename ".
                      "$slot->{'workbook'}->{targetfile}");
         }
         else{ 
            foreach my $dstfile ("$filename.Cur.xls","$filename.$period.xls"){
               printf STDERR ("fifi filename=$dstfile dir=$dir\n");
               if (open(F,"<".$slot->{fh}->filename)){
                  if (!($file->ValidatedInsertOrUpdateRecord(
                               {name=>$dstfile, parent=>$dir,file=>\*F},
                               {name=>\$dstfile,parent=>\$dir}))){
                     msg(ERROR,"fail to store ".
                               "$slot->{'workbook'}->{targetfile}");
                  }
                  close(F);
               }
               else{
                  printf STDERR ("ERROR: can't open $self->{filename}\n");
               }
           
           
            }
         }
         unlink($slot->{fh}->filename);
      }
   }

   

   delete($self->{SSTORE});
}

1;
