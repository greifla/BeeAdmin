package kernel::Output::XlsV01;
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
use base::load;
use kernel::Output::HtmlSubList;
@ISA    = qw(kernel::Formater);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}

sub IsModuleSelectable
{
   eval("use Spreadsheet::WriteExcel::Big;");
   if ($@ ne ""){
      return(0);
   }
   return(1);
}
sub getRecordImageUrl
{
   return("../../../public/base/load/icon_xls.gif");
}
sub Label
{
   return("Output to XLS");
}
sub Description
{
   return("Writes the data in Excel/XLS Format.");
}

sub MimeType
{
   return("application/vnd.ms-excel");
}

sub getDownloadFilename
{
   my $self=shift;

   return($self->SUPER::getDownloadFilename().".xls");
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
   $self->{filename}="/tmp/tmp.$$.xls";
   $|=1;
   binmode($$fh);
   eval("use Spreadsheet::WriteExcel::Big;");
   if ($@ eq ""){
      $self->{'workbook'}=Spreadsheet::WriteExcel::Big->new($self->{filename});
   }
   $self->{'worksheet'}=$self->{'workbook'}->addworksheet(
                                           'W5Base');
   $self->{'format'}={};
   $self->{'maxlen'}=[];
   $self->{xlscollindex}={};
   $self->{maxcollindex}=0;

   return($self->SUPER::Init(@_));
}

sub Format
{
   my $self=shift;
   my $name=shift;
   return($self->{format}->{$name}) if (exists($self->{format}->{$name}));

   my $format;
   if ($name eq "default"){
      $format=$self->{'workbook'}->addformat(text_wrap=>1,align=>'top');
   }
   elsif ($name eq "date.de"){
      $format=$self->{'workbook'}->addformat(align=>'top',
                                          num_format => 'dd.mm.yyyy HH:MM:SS');
   }
   elsif ($name eq "date.en"){
      $format=$self->{'workbook'}->addformat(align=>'top',
                                          num_format => 'yyyy-mm-dd HH:MM:SS');
   }
   elsif ($name eq "longint"){
      $format=$self->{'workbook'}->addformat(align=>'top',num_format => '#');
   }
   elsif ($name eq "header"){
      $format=$self->{'workbook'}->addformat();
      $format->copy($self->Format("default"));
      $format->set_bold();
   } 
   elsif (my ($precsision)=$name=~m/^number\.(\d+)$/){
      $format=$self->{'workbook'}->addformat();
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

sub ProcessLine
{
   my ($self,$fh,$viewgroups,$rec,$recordview,$fieldbase,$lineno,$msg)=@_;
   my $app=$self->getParent->getParent();
   my $d;
   my @cell=();
   my @cellobj=();
   foreach my $fo (@{$recordview}){
      next if ($fo->Type() eq "Link");
      next if ($fo->Type() eq "Interface");
      next if ($fo->Type() eq "Container");
      my $name=$fo->Name();
      if (!defined($self->{xlscollindex}->{$name})){
         $self->{xlscollindex}->{$name}=$self->{maxcollindex};
         $self->{maxcollindex}++;
      }
      my $data="undef";
      if ($fo->UiVisible("XlsV01",current=>$rec)){ 
         if ($fo->can("getLineSubListData")){
            $data=$fo->getLineSubListData($rec,"xls");
         }
         else{
            $data=$app->findtemplvar({viewgroups=>$viewgroups,
                                      fieldbase=>$fieldbase,
                                      current=>$rec,
                                      mode=>$self->modeName(),
                                     },$name,"formated");
            #if ($self->getParent->getParent->Config->Param("UseUTF8")){
            #   $data=utf8($data);
            #   $data=$data->latin1();
            #}
         }
      }
      else{
         $data="-";
      }
      $data=~s/\r\n/\n/g;
      $cell[$self->{xlscollindex}->{$name}]=$data;
      $cellobj[$self->{xlscollindex}->{$name}]=$fo;
      foreach my $subline (split(/\n/,$data)){
         if (length($subline)>
             $self->{'maxlen'}->[$self->{xlscollindex}->{$name}]){
            $self->{'maxlen'}->[$self->{xlscollindex}->{$name}]=
                                                      length($subline);
         }
      }
   }
   for(my $cellno=0;$cellno<=$#cell;$cellno++){
      my $field=$cellobj[$cellno];
      my $data=$cell[$cellno];
      if (defined($data)){
         my $format=$field->getXLSformatname($data);
         #printf STDERR ("fifi: field=%s format=%s data=%s\n",$field->Name(),
         #               $format,$data);
         if ($format=~m/^date\./){
            $self->{'worksheet'}->write_date_time($lineno,$cellno,$data,
                                                  $self->Format($format));
         }
         else{
            $data="'".$data if ($data=~m/^=/);
            $self->{'worksheet'}->write($lineno,$cellno,$data,
                                        $self->Format($format));
         }
      }
   }
   return(undef);
}

sub ProcessHead
{
   my ($self,$fh,$rec,$msg)=@_;
   my @view=@{$self->{fieldobjects}};

   for(my $cellno=0;$cellno<=$#view;$cellno++){
      #next if (!($view[$cellno]->UiVisible()));   # ist nicht mehr notwendig
      next if ($view[$cellno]->Type() eq "Interface");
      next if ($view[$cellno]->Type() eq "Container");
      my $xlscellno=$self->{xlscollindex}->{$view[$cellno]->Name()};
      my $label=$view[$cellno]->Label();
      my $format="header";
      if (length($label)>$self->{'maxlen'}->[$cellno]){
         $self->{'maxlen'}->[$xlscellno]=length($label);
      }
      $self->{'worksheet'}->write(0,$xlscellno,$label,
                                  $self->Format($format));
      { # column width calculation
         my $xlswidth;
         if (defined($view[$cellno]->htmlwidth())){
            $xlswidth=$view[$cellno]->htmlwidth()*0.3;
         }
         if (defined($view[$cellno]->xlswidth())){
            $xlswidth=$view[$cellno]->xlswidth();
         }
         if (!defined($xlswidth)){
            $xlswidth=$self->{'maxlen'}->[$xlscellno]*1.2;
         }
         $xlswidth=15 if (defined($xlswidth) && $xlswidth<15);
         if (defined($xlswidth)){
            $self->{'worksheet'}->set_column($xlscellno,$xlscellno,$xlswidth);
         }
      }
   }

   return(undef);
}

sub Finish
{
   my ($self,$fh)=@_;
   $self->{'workbook'}->close();

   $self->{'workbook'}->close();
   if (open(F,"<$self->{filename}")){
      my $buf;
      while(sysread(F,$buf,8192)){
         print STDOUT $buf;
      }
      close(F);
   }
   else{
      printf STDERR ("ERROR: can't open $self->{filename}\n");
   }
   unlink($self->{filename});
   return();
}

1;
