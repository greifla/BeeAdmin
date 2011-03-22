package base::workprocessitem;
#  W5Base Framework
#  Copyright (C) 2011  Hartmut Vogler (it@guru.de)
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
use finance::lib::Listedit;
@ISA=qw(finance::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   #$param{MainSearchFieldLines}=5;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{use_distinct}=0;
   $self->{noHtmlTableSort}=1;



   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                searchable    =>0,
                label         =>'W5BaseID',
                dataobjattr   =>'workprocessitem.id'),

      new kernel::Field::Text(
                name          =>'workprocessid',
                htmldetail    =>0,
                label         =>'WorkprocessID',
                dataobjattr   =>'workprocessitem.workprocess'),

      new kernel::Field::Text(
                name          =>'orderkey',
                htmldetail    =>0,
                label         =>'Order Key',
                dataobjattr   =>'workprocessitem.orderkey'),

      new kernel::Field::Text(
                name          =>'itemno',
                label         =>'Item No.',
                dataobjattr   =>'workprocessitem.orderpos'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Item label',
                dataobjattr   =>'workprocessitem.name'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'workprocessitem.comments'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'workprocessitem.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'workprocessitem.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'workprocessitem.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'workprocessitem.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'workprocessitem.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'workprocessitem.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'workprocessitem.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'workprocessitem.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'workprocessitem.realeditor'),
   

   );
   $self->{history}=[qw(modify delete)];
   $self->{CI_Handling}={uniquename=>"name",
                         activator=>["admin","admin.base.workprocessitem"],
                         uniquesize=>80};
   $self->setDefaultView(qw(mandator name cistatus mdate));
   $self->setWorktable("workprocessitem");
   return($self);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),
          qw(default misc source));
}




sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/workprocessitem.jpg?".$cgi->query_string());
}



sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(1);
}


sub isWorkprocessWriteable
{
   my $self=shift;
   my $showmsg=shift;
   my $workprocessid=shift;

   if ($workprocessid eq ""){
      $self->LastMsg(ERROR,"invalid workprocess id") if ($showmsg);
      return(0);
   }
   my $wp=getModuleObject($self->Config,"base::workprocess");
   $wp->SetFilter({id=>\$workprocessid});
   my ($wprec,$msg)=$wp->getOnlyFirst(qw(ALL));
   if (!defined($wprec)){
      $self->LastMsg(ERROR,"invalid workprocess reference") if ($showmsg);
      return(0);
   }
   my @l=$wp->isWriteValid($wprec);
   if (!in_array(\@l,['items','ALL'])){

      $self->LastMsg(ERROR,"no write access to workprocess") if ($showmsg);
      return(0);
   }
   return(1);

}




sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;


   my $workprocessid=effVal($oldrec,$newrec,"workprocessid");
   return(0) if (!$self->isWorkprocessWriteable(1,$workprocessid));

   my $itemno=effVal($oldrec,$newrec,"itemno");
   if (!$itemno=~m/^(\d{1,3})(\.\d{1,3}){0,3}$/){
      $self->LastMsg(ERROR,"invalid item no");
      return(0);
   }
   my @itemno=split(/\./,$itemno);
   if ($itemno[0]<1){
      $self->LastMsg(ERROR,"invalid major item no");
      return(0);
   }
   for(my $c=0;$c<=$#itemno;$c++){
      if ($itemno[$c]>999){
         $self->LastMsg(ERROR,"invalid sub item no - max allowed 999");
         return(0);
      }
   }
   my $orderkey="";
   for(my $c=0;$c<=5;$c++){
      $orderkey.=sprintf("%03d",$itemno[$c]);
   }
   if (exists($newrec->{itemno})){
      $newrec->{orderkey}=$orderkey;
   }
   


   return(1);
}

sub initSqlOrder
{
   my $self=shift;

   return(qw(workprocess orderkey));
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   return("default") if (!defined($rec));
   return("default") if ($self->isWorkprocessWriteable(1,$rec->{workprocessid}));
   return();
}


1;
