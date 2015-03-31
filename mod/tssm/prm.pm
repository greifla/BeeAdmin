package tssm::prm;
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
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Linenumber(
                htmlwidth     =>'1%',
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'problemnumber',
                label         =>'Problem No.',
                uppersearch   =>1,
                searchable    =>1,
                htmlwidth     =>'20',
                align         =>'left',
                dataobjattr   =>'rootcausem1.id'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Brief Description',
                ignorecase    =>1,
                dataobjattr   =>'rootcausem1.brief_description'),

      new kernel::Field::Text(
                name          =>'status',
                label         =>'Status',
                htmlwidth     =>100,
                dataobjattr   =>'rootcausem1.status'),

      new kernel::Field::Textarea(
                name          =>'description',
                label         =>'Description',
                searchable    =>0,
                dataobjattr   =>'rootcausem1.description'),

      new kernel::Field::Text(
                name          =>'creator',
                uppersearch   =>1,
                group         =>'contact',
                label         =>'Creator',
                dataobjattr   =>'rootcausem1.opened_by'),

      new kernel::Field::Date(
                name          =>'cdate',
                sqlorder      =>'desc',
                timezone      =>'CET',
                label         =>'Created',
                dataobjattr   =>'rootcausem1.open_time'),

      new kernel::Field::Date(
                name          =>'sysmodtime',
                timezone      =>'CET',
                label         =>'SysModTime',
                dataobjattr   =>'rootcausem1.sysmodtime'),

      new kernel::Field::Text(
                name          =>'impact',
                group         =>'status',
                label         =>'Business Impact',
                dataobjattr   =>'rootcausem1.impact'),

      new kernel::Field::Text(
                name          =>'category',
                group         =>'status',
                label         =>'Category',
                dataobjattr   =>'rootcausem1.category'),

##      new kernel::Field::Select(
##                name          =>'analysetype',
##                group         =>'status',
##                value         =>["",1,2],
##                transprefix   =>'ANAT.',
##                label         =>'Analyse type',
##                dataobjattr   =>'rootcausem1.analyse_type'),

##      new kernel::Field::Select(
##                name          =>'solutiontype',
##                group         =>'status',
##                value         =>["",1,2],
##                transprefix   =>'SOLT.',
##                label         =>'Solution type',
##                dataobjattr   =>'rootcausem1.solution_type'),

##      new kernel::Field::Text(
##                name          =>'subcat1',
##                group         =>'status',
##                htmldetail    =>\&onlyIfFilled,
##                label         =>'Sub Category 1',
##                dataobjattr   =>'rootcausem1.subcat1'),

##      new kernel::Field::Text(
##                name          =>'subcat2',
##                group         =>'status',
##                label         =>'Sub Category 2',
##                htmldetail    =>\&onlyIfFilled,
##                dataobjattr   =>'rootcausem1.subcat2'),

##      new kernel::Field::Text(
##                name          =>'subcat3',
##                group         =>'status',
##                htmldetail    =>\&onlyIfFilled,
##                label         =>'Sub Category 3',
##                dataobjattr   =>'rootcausem1.subcat3'),

      new kernel::Field::Text(
                name          =>'priority',
                group         =>'status',
                label         =>'Pritority',
                dataobjattr   =>'rootcausem1.priority_code'),

##      new kernel::Field::Text(
##                name          =>'urgency',
##                group         =>'status',
##                label         =>'Urgency',
##                dataobjattr   =>'rootcausem1.urgency'),

      new kernel::Field::Text(
                name          =>'triggeredby',
                group         =>'status',
                label         =>'Triggered by',
                dataobjattr   =>'rootcausem1.tsi_triggered_by'),

##      new kernel::Field::Text(
##                name          =>'softwareid',
##                htmldetail    =>\&onlyIfFilled,
##                label         =>'SoftwareID',
##                dataobjattr   =>'rootcausem1.sw_name'),

      new kernel::Field::Text(
                name          =>'deviceid',
                htmldetail    =>\&onlyIfFilled,
                label         =>'DeviceID',
                dataobjattr   =>'rootcausem1.logical_name'),

##      new kernel::Field::Text(
##                name          =>'sysname',
##                htmldetail    =>\&onlyIfFilled,
##                label         =>'Systemname',
##                dataobjattr   =>'rootcausem1.tsi_main_ci_system_name'),

##      new kernel::Field::Text(
##                name          =>'location',
##                uppersearch   =>1,
##                htmldetail    =>\&onlyIfFilled,
##                label         =>'Location',
##                dataobjattr   =>'rootcausem1.location_name'),

      new kernel::Field::Date(
                name          =>'createtime',
                depend        =>['status'],
                group         =>'close',
                timezone      =>'CET',
                label         =>'Create time',
                dataobjattr   =>'rootcausem1.open_time'),

      new kernel::Field::Date(
                name          =>'closetime',
                depend        =>['status'],
                group         =>'close',
                timezone      =>'CET',
                label         =>'Closeing time',
                dataobjattr   =>'rootcausem1.close_time'),

      new kernel::Field::Duration(  
                name          =>'workduration',
                group         =>'close',
                label         =>'Work Duration',
                depend        =>[qw(createtime closetime)]),

      new kernel::Field::Textarea(
                name          =>'workarraound',
                label         =>'Workaround',
                group         =>'close',
                searchable    =>0,
                dataobjattr   =>'rootcausem1.workaround'),

##      new kernel::Field::Text(
##                name          =>'solutiontype',
##                group         =>'close',
##                label         =>'Solution Type',
##                dataobjattr   =>'rootcausem1.solution_type'),

##      new kernel::Field::Select(
##                name          =>'closetype',
##                group         =>'close',
##                label         =>'Close Type',
##                transprefix   =>'closetype.',
##                value         =>[qw(1 2 3)],
##                dataobjattr   =>'rootcausem1.close_type'),

##      new kernel::Field::Link(
##                name          =>'closetypeid',
##                group         =>'close',
##                label         =>'Close Type',
##                dataobjattr   =>'rootcausem1.close_type'),

      new kernel::Field::Textarea(
                name          =>'cause',
                label         =>'Cause',
                group         =>'close',
                searchable    =>0,
                dataobjattr   =>'rootcausea1.root_cause'),

      new kernel::Field::Textarea(
                name          =>'solution',
                label         =>'Solution',
                group         =>'close',
                searchable    =>0,
                dataobjattr   =>'rootcausem1.resolution'),

#      new kernel::Field::SubList(
#                name          =>'relations',
#                label         =>'Relations',
#                group         =>'relations',
#                vjointo       =>'tssm::lnk',
#                vjoinon       =>['problemnumber'=>'src'],
#                vjoininhash   =>['dst'],
#                vjoindisp     =>[qw(dst dstname)]),

##      new kernel::Field::Text(
##                name          =>'homeassignment',
##                uppersearch   =>1,
##                group         =>'contact',
##                label         =>'Homeassignment',
##                dataobjattr   =>'rootcausem1.home_assignment'),

      new kernel::Field::Text(
                name          =>'editor',
                uppersearch   =>1,
                group         =>'contact',
                label         =>'Editor',
                dataobjattr   =>'rootcausem1.sysmoduser'),

      new kernel::Field::Text(
                name          =>'assignedto',
                uppersearch   =>1,
                group         =>'contact',
                label         =>'Assignment',
                dataobjattr   =>'rootcausem1.assignment'),

##      new kernel::Field::Text(
##                name          =>'assignedtouser',
##                uppersearch   =>1,
##                group         =>'contact',
##                label         =>'Assigned worker',
##                dataobjattr   =>'rootcausem1.assigned_to'),

   );
   $self->{use_distinct}=0;
   $self->setDefaultView(qw(linenumber cdate problemnumber status name));
   return($self);
}

sub SetFilterForQualityCheck
{
   my $self=shift;
   my $stateparam=shift;
   my @view=@_;
   return(undef);
}

sub onlyIfFilled
{
   my $self=shift;
   my $mode=shift;
   my %param=@_;
   return(0) if ($param{current}->{$self->Name()} eq "");
   return(1);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tssm"));
   return(@result) if (defined($result[0]) eq "InitERROR");

   return(1) if (defined($self->{DB}));
   return(0);
}

sub initSearchQuery
{
   my $self=shift;

   if (!defined(Query->Param("search_sysmodtime"))){
      Query->Param("search_sysmodtime"=>'>now-7d');
   }
}





sub getRecordImageUrl
{
    my $self=shift;
    my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
    return("../../../public/itil/load/prm.jpg?".$cgi->query_string());
}
                  

sub getDetailBlockPriority                # posibility to change the block order
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),qw(status relations contact));
}



sub getSqlFrom
{
   my $self=shift;
   my $from="dh_rootcausem1 rootcausem1";
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where="";
   return($where);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my $st;
   if (defined($rec)){
      $st=$rec->{status};
   }
   #if ($st ne "closed" && $st ne "rejected"){
   #   return(qw(contact default status header software device));
   #}
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}


1;
