package kernel::Output::JpgV01;
#  W5Base Framework
#  Copyright (C) 2007  Holm Basedow (holm@blauwaerme.de)
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
use kernel::Formater;
use File::Path;
use LWP::Simple qw(getstore);
@ISA    = qw(kernel::Formater);

sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}

sub IsModuleSelectable
{
   my $self=shift;

   printf STDERR ("fifi in jpg IsModuleSelectable $self\n");
   eval("use DTP;");
   if ($@ ne ""){
      return(0);
   }
   eval("use Archive::Zip qw( :ERROR_CODES :CONSTANTS );");
   if ($@ ne ""){
      return(0);
   }
   return(1);
}
sub getRecordImageUrl
{
   return("../../../public/base/load/icon_jpg.gif");
}
sub Label
{
   return("Output to JPG");
}
sub Description
{
   return("Writes the data in a JPG Image.");
}

sub MimeType
{
   return("application/zip");
}

sub getDownloadFilename
{
   my $self=shift;

   return($self->SUPER::getDownloadFilename().".zip");
}

sub getHttpHeader
{  
   my $self=shift;
   my $app=$self->getParent->getParent();
   my $d="";
   $d.="Content-type:".$self->MimeType()."\n\n";
   return($d);
}

sub Init
{
   my $self=shift;
   my ($fh)=@_;
   $|=1;
   my ($id,$res);
   binmode($$fh);
   my $dtp;
   eval('use DTP::jpg;$dtp=new DTP::jpg();$self->{zip}=new Archive::Zip();');
   if ($@ eq ""){
      $self->{dtp}=$dtp;
   }
   if (defined($res=$self->getParent->getParent->W5ServerCall("rpcGetUniqueId")) &&
      $res->{exitcode}==0){
      $id=$res->{id};
   }
   $self->{dtp}->{_Layout}->{dir}="/tmp/tmp.$id.jpg";
   mkdir($self->{dtp}->{_Layout}->{dir});
   $self->{dtp}->{_Layout}->{tempfile}=$self->{dtp}->{_Layout}->{dir}."/doc%04d";
}

sub Format
{
   printf STDERR ("fifi format \n\n\n");
}

sub ProcessLine
{
   my ($self,$fh,$viewgroups,$rec,$recordview,$fieldbase,$lineno,$msg)=@_;
   my $app=$self->getParent->getParent();
   my $view=$app->getCurrentViewName();
   my @view=$app->getCurrentView();
   my $editgroups=[$app->isWriteValid($rec)];
   my $headerval="";
   my $H="";
   my $s=$self->getParent->getParent->T($self->getParent->getParent->Self,
                                        $self->getParent->getParent->Self);

   if (my $f=$self->getParent->getParent->getField("fullname")){
      $headerval=quoteHtml($f->RawValue($rec));
   }
   elsif (my $f=$self->getParent->getParent->getField("name")){
      $headerval=quoteHtml($f->RawValue($rec));
   }
   else{
      $headerval='%objecttitle%';
   }
   $self->{dtp}->NewPage(format=>'A4');
   $self->{dtp}->WriteLine($s.": ".$headerval,
                           border        =>1,
                           color         =>'white',
                           background    =>'SteelBlue');

   my %font=(font       => "Helvetica",
             color      => "black");

   foreach my $fo (@{$recordview}){
      next if ($fo->Type() eq "Link");
      next if ($fo->Type() eq "Interface");
      next if ($fo->Type() eq "Container");
      my $name=$fo->Name();
      my $label=$fo->Label();
      my $data="undef";

      if ($fo->can("getLineSubListData")){
         $data=$fo->getLineSubListData($rec,"DTP".lc($self->modeName()));
      }else{
         $data=$app->findtemplvar({viewgroups => $viewgroups,
                                   fieldbase  => $fieldbase,
                                   current    => $rec,
                                   mode       => "DTP".lc($self->modeName()),
                                  },$name,"formated");

      }
      $self->{dtp}->WriteLine([$label,$data],
                              %font,
                              fontsize      =>8,
                              bold          =>[1,0],
                              width         =>[120,undef],
                              border        =>0.5,
                              color         =>'black',
                              background    =>'snow2');
   }
}

sub Finish
{
   my $self=shift;
   my $dirhandler=$self->{dtp}->{_Layout}->{dir};
   $self->{dtp}->GetDocument($self->{dtp}->{_Layout}->{tempfile});
   my $dir_member = $self->{zip}->addTree($dirhandler);   
   eval('
   unless ( $self->{zip}->writeToFileNamed("$dirhandler/pics.zip") == AZ_OK )
   {
      die("ERROR: write error zipfile error=$?");
   }
   ');
   if (open(F,"<$dirhandler/pics.zip")){
      my $buf;
      while(sysread(F,$buf,8192)){
         print STDOUT $buf;
      }
      close(F);
   }else{
      printf STDERR ("ERROR: can't open $dirhandler/pics.zip\n");
   }
   rmtree("$dirhandler");
   return();
}

1;
