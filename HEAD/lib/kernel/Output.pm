package kernel::Output;
#  W5Base Framework
#  Copyright (C) 2002  Hartmut Vogler (hartmut.vogler@epost.de)
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
#
use vars qw(@ISA);
use strict;
use kernel;
use kernel::Formater;
use kernel::Universal;
use Fcntl 'SEEK_SET';

@ISA=qw(kernel::Universal);

sub new
{
   my $type=shift;
   my $parent=shift;
   my $self=bless({},$type);

   $self->setParent($parent);

   return($self);
}

sub Format
{
   my $self=shift;
   return($self->{Format});
}

sub setFormat
{
   my $self=shift;
   my $format=shift;
   my %opt=@_;
   my $o;
   $format=~s/[\.\/:]//g;
   $self->{download}=0;
   if (my ($f)=$format=~m/^>(.*)$/){
      $format=$f;
      $self->{download}=1;
   }
   if (defined($opt{DETAILFUNCTIONS})){
      $self->{DETAILFUNCTIONS}=$opt{DETAILFUNCTIONS};
   }
   if ($opt{NewRecord}==1){
      $self->{NewRecord}=1;
   }
   if ($opt{ignViewValid}==1){
      $self->{ignViewValid}=1;
   }
   else{
      $self->{ignViewValid}=0;
   }
   $format=~s/;.*//;
   $format=~s/[^a-z0-9:_]//gi;
   eval("use kernel::Output::$format;".
        "\$o=new kernel::Output::$format(\$self,\%opt);");
   if ($@ eq ""){
      $self->{Format}=$o;
      return(1);
   }
   my $emsg=$@;
   msg(ERROR,"can't load formater '%s'\n%s",$format,$emsg);

   return(0);
}



sub getView
{
   my $self=shift;
   return($self->getParent->getCurrentView());
}

sub DisplayFormatSelector
{
   my $self=shift;

}

sub getLinenumber
{
   my $self=shift;
   return($self->getParent->Context->{Linenumber});
}

sub getFirst
{
   my $self=shift;

   my ($rec,$msg)=$self->getParent->getFirst();

   return($rec,$msg);
}

sub getNext
{
   my $self=shift;

   my ($rec,$msg)=$self->getParent->getNext();

   return($rec,$msg);
}


sub WriteToStdout
{
   my $self=shift;
   my %param=@_;
   $self->getParent->Context->{Linenumber}=0;
   my $app=$self->getParent();
   local *TMP;

   #binmode(STDOUT);   # test 24.07.2008 by hv
   $self->Format->prepareParent($app,\%param);
   open(TMP, "+>", undef);
   my $fh=\*TMP;
   my ($rec,$msg);
   if (!$self->{NewRecord} && $self->Format->isRecordHandler()){
      ($rec,$msg)=$self->getFirst();
   }
   else{
      $rec=undef;
      if ($self->{NewRecord}){
         $app->SetCurrentView(qw(ALL));
      }
   }
   #my @baseview=$app->getFieldObjsByView([$app->getCurrentView()]);
   #for(my $c=0;$c<=$#baseview;$c++){
   #   my $field=$baseview[$c];
   #   my $name=$field->Name();
   #   push(@{$self->Format->{fieldobjects}},$field);
   #   $self->Format->{fieldkeys}->{$name}=$#{$self->Format->{fieldobjects}};
   #}
   my @baseview=();
   if (defined($rec) || $self->{NewRecord} ||
       (!$self->Format->isRecordHandler())){
      my $d=$self->Format->Init(\$fh,\@baseview);
      syswrite($fh,$d) if (defined($d));
      do{
         if (!exists($app->{'SoftFilter'}) ||
              &{$app->{'SoftFilter'}}($app,$rec)){
            my @viewgroups=qw(ALL);
            if (!$self->{ignViewValid}){
               @viewgroups=$app->isViewValid($rec,
                                             format=>$self->Format->Self());
            }
            if ($#viewgroups!=-1 && defined($viewgroups[0]) && 
                $viewgroups[0] ne "0"){
               $app->Context->{Linenumber}++;
               my @recordview=$app->getFieldObjsByView(
                                   [$app->getCurrentView()],
                                    current=>$rec,
                                    output=>$self->Format->Self());
               my $fieldbase={};
               map({$fieldbase->{$_->Name()}=$_} @recordview);
               foreach my $fo (@recordview){
                  my $name=$fo->Name();
                  if (!defined($self->Format->{fieldkeys}->{$name})){
                     push(@{$self->Format->{fieldobjects}},$fo);
                     $self->Format->{fieldkeys}->{$name}=
                                         $#{$self->Format->{fieldobjects}};
                  }
               }
               my $d=$self->Format->ProcessLine(\$fh,\@viewgroups,$rec,
                                                \@recordview,$fieldbase,
                                $self->getParent->Context->{Linenumber},$msg);
               if (defined($d)){
                  if (utf8::is_utf8($d)){
                  #   $d=~s/[\x{2013}\x{2022}]/?/g;
                     $d=UTF8toLatin1($d);
                  }
                  syswrite($fh,$d);
               }
            }
            else{
               $self->Context->{CurrentLimit}++; # fix to handel isViewValid
            }                                    # denied of a record
         }
         if ($self->{NewRecord} || (!$self->Format->isRecordHandler())){
            $rec=undef;
         }
         else{
            ($rec,$msg)=$self->getNext();
         }
      }until(!defined($rec));
      my $d=$self->Format->ProcessBottom(\$fh,undef,$msg,\%param);
      $msg=undef;
      syswrite($fh,$d) if (defined($d));
      if ($param{HttpHeader}){
         syswrite($fh,$self->Format->getHttpFooter());
      }
   }
   if ($msg ne ""){
      if ($self->getParent->can("HttpHeader")){
         print $app->HttpHeader("text/plain");
         printf("%s",$msg);
      }
      close(TMP);
      close($fh);
      return(); 
   }
   if ($app->Context->{Linenumber}==0){
      print $self->Format->getEmpty(HttpHeader=>$param{HttpHeader});
      close(TMP);
      close($fh);
      return();
   }
   if ($param{HttpHeader}){
      print STDOUT ($self->Format->DownloadHeader().
                    $self->Format->getHttpHeader());
   }
   my $d=$self->Format->ProcessHead(\$fh,undef,$msg,\%param);
   $self->Format->Finish(\$fh,%param);
   print STDOUT ($d) if (defined($d));
   sysseek($fh,0,SEEK_SET);
   my $buffer;
   while(my $nread=sysread($fh,$buffer,8192)){
      print STDOUT $buffer;
   }
   close(TMP);
   close($fh);
}

sub WriteToScalar    # ToDo: viewgroups implementation
{
   my $self=shift;
   my %param=@_;
   my $app=$self->getParent();
   local *TMP;

   $self->Format->prepareParent($app,\%param);
   open(TMP, "+>", undef);
   my $fh=\*TMP;

   my ($rec,$msg);
   if (!$self->{NewRecord} && $self->Format->isRecordHandler()){
      ($rec,$msg)=$self->getFirst();
   }
   else{
      $rec=undef;
      $self->getParent->SetCurrentView(qw(ALL));
   }

   $self->getParent->Context->{Linenumber}=0;
   $self->Format->{fieldobjects}=[];
   $self->Format->{fieldkeys}={};
   my @baseview=$app->getFieldObjsByView([$app->getCurrentView()]);
   for(my $c=0;$c<=$#baseview;$c++){
      my $field=$baseview[$c];
      my $name=$field->Name();
      push(@{$self->Format->{fieldobjects}},$field);
      $self->Format->{fieldkeys}->{$name}=$#{$self->Format->{fieldobjects}};
   }
   if (defined($rec) || $self->{NewRecord} ){
      my $d=$self->Format->Init(\$fh,\@baseview);
      syswrite(TMP,$d) if (defined($d));
      if ($param{HttpHeader}){
         syswrite(TMP,$self->Format->DownloadHeader().
                      $self->Format->getHttpHeader());
      }
      do{
         if (!exists($app->{'SoftFilter'}) ||
              &{$app->{'SoftFilter'}}($app,$rec)){
            my @viewgroups=qw(ALL);
            if (!$self->{ignViewValid}){
               @viewgroups=$app->isViewValid($rec,
                                             format=>$self->Format->Self());
            }
            if ($#viewgroups!=-1 && defined($viewgroups[0]) && 
                $viewgroups[0] ne "0"){
               $self->getParent->Context->{Linenumber}++;
               my @recordview=$app->getFieldObjsByView(
                              [$app->getCurrentView()],
                               current=>$rec,
                               output=>$self->Format->Self());
               my $fieldbase={};
               map({$fieldbase->{$_->Name()}=$_} @recordview);
               foreach my $fo (@recordview){
                  my $name=$fo->Name();
                  if (!defined($self->Format->{fieldkeys}->{$name})){
                     push(@{$self->Format->{fieldobjects}},$fo);
                     $self->Format->{fieldkeys}->{$name}=
                                         $#{$self->Format->{fieldobjects}};
                  }
               }
               my $d=$self->Format->ProcessLine(\$fh,\@viewgroups,$rec,
                            \@recordview,$fieldbase,
                            $app->Context->{Linenumber},$msg); 
               syswrite(TMP,$d) if (defined($d));
            }
         }
         if ($self->{NewRecord} || (!$self->Format->isRecordHandler())){
            $rec=undef;
         }
         else{
            ($rec,$msg)=$self->getNext();
         }
      }until(!defined($rec));
      my $d=$self->Format->ProcessBottom(\$fh,undef,$msg,\%param);
      syswrite(TMP,$d) if (defined($d));

      if ($param{HttpHeader}){
         syswrite(TMP,$self->Format->getHttpFooter());
      }
   }
   if ($msg ne "" && $self->Format->{DisableMsg}!=1){
      close(TMP);
      close($fh);
      return($msg); 
   }
   if ($app->Context->{Linenumber}==0){
      close(TMP);
      close($fh);
      return("");
   }
   my $bk="";
   my $d=$self->Format->ProcessHead(\$fh,undef,$msg,\%param);
   $self->Format->Finish(\$fh,%param);
   $bk.=$d if (defined($d));
   sysseek($fh,0,SEEK_SET);
   my $buffer;
   while(my $nread=sysread($fh,$buffer,8192)){
      $bk.=$buffer;
   }
   close(TMP);
   close($fh);
   return($bk);
}


1;
