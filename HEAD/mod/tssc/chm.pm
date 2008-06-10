package tssc::chm;
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
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                htmlwidth     =>'1%',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'changenumber',
                sqlorder      =>'desc',
                label         =>'Change No.',
                htmlwidth     =>'20',
                align         =>'left',
                dataobjattr   =>'cm3rm1.numberprgn'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Brief Description',
                ignorecase    =>1,
                dataobjattr   =>'cm3rm1.brief_description'),

      new kernel::Field::Text(
                name          =>'status',
                label         =>'Status',
                htmlwidth     =>20,
                dataobjattr   =>'cm3rm1.status'),

      new kernel::Field::Text(
                name          =>'softwareid',
                htmlwidth     =>'100px',
                ignorecase    =>1,
                label         =>'SoftwareID',
                dataobjattr   =>'cm3rm1.program_name'),

      new kernel::Field::Text(
                name          =>'deviceid',
                htmlwidth     =>'100px',
                ignorecase    =>1,
                label         =>'DeviceID',
                dataobjattr   =>'cm3rm1.logical_name'),

      new kernel::Field::SubList(
                name          =>'software',
                label         =>'Software',
                group         =>'software',
                htmlwidth     =>'300px',
                vjointo       =>'tssc::chm_software',
                vjoinon       =>['changenumber'=>'changenumber'],
                vjoindisp     =>[qw(name)]),

      new kernel::Field::SubList(
                name          =>'device',
                label         =>'Device',
                group         =>'device',
                htmlwidth     =>'300px',
                vjointo       =>'tssc::chm_device',
                vjoinon       =>['changenumber'=>'changenumber'],
                vjoindisp     =>[qw(name)]),

      new kernel::Field::SubList(
                name          =>'approvalsreq',
                label         =>'Approvals Required',
                htmlwidth     =>'200px',
                group         =>'approvals',
                vjointo       =>'tssc::chm_approvereq',
                vjoinon       =>['changenumber'=>'changenumber'],
                vjoindisp     =>[qw(name)]),

      new kernel::Field::SubList(
                name          =>'approved',
                label         =>'Approved Groups',
                htmlwidth     =>'200px',
                group         =>'approvals',
                vjointo       =>'tssc::chm_approvedgrp',
                vjoinon       =>['changenumber'=>'changenumber'],
                vjoindisp     =>[qw(name)]),

      new kernel::Field::Date(
                name          =>'cdate',
                timezone      =>'CET',
                label         =>'Created',
                dataobjattr   =>'cm3rm1.orig_date_entered'),

      new kernel::Field::Date(
                name          =>'plannedstart',
                timezone      =>'CET',
                label         =>'Planed Start',
                dataobjattr   =>'cm3rm1.planned_start'),

      new kernel::Field::Date(
                name          =>'plannedend',
                timezone      =>'CET',
                label         =>'Planed End',
                dataobjattr   =>'cm3rm1.planned_end'),

      new kernel::Field::Duration(
                name          =>'plannedduration',
                label         =>'Planed Duration',
                depend        =>[qw(plannedstart plannedend)]),

      new kernel::Field::Textarea(
                name          =>'description',
                label         =>'Description',
                searchable    =>0,
                vjointo       =>'tssc::chm_description',
                vjoinconcat   =>"\n",
                vjoinon       =>['changenumber'=>'changenumber'],
                vjoindisp     =>'description'),

      new kernel::Field::Textarea(
                name          =>'fallback',
                label         =>'Fallback',
                searchable    =>0,
                vjointo       =>'tssc::chm_fallback',
                vjoinconcat   =>"\n",
                vjoinon       =>['changenumber'=>'changenumber'],
                vjoindisp     =>'fallback'),

      new kernel::Field::Textarea(
                name          =>'resources',
                label         =>'Resources',
                searchable    =>0,
                dataobjattr   =>'cm3ra43.resources'),

      new kernel::Field::Text(
                name          =>'priority',
                group         =>'status',
                group         =>'status',
                label         =>'Pritority',
                dataobjattr   =>'cm3rm1.priority'),

      new kernel::Field::Text(
                name          =>'impact',
                group         =>'status',
                label         =>'Business Impact',
                dataobjattr   =>'cm3rm1.impact'),

      new kernel::Field::Text(
                name          =>'urgency',
                group         =>'status',
                label         =>'Urgency',
                dataobjattr   =>'cm3rm1.urgency'),

      new kernel::Field::Text(
                name          =>'reason',
                group         =>'status',
                label         =>'Reason',
                dataobjattr   =>'cm3rm1.reason'),

      new kernel::Field::Text(
                name          =>'category',
                group         =>'status',
                label         =>'Category',
                dataobjattr   =>'cm3rm1.category'),

      new kernel::Field::Text(
                name          =>'risk',
                group         =>'status',
                label         =>'Risk',
                dataobjattr   =>'cm3rm1.risk_assessment'),

      new kernel::Field::Text(
                name          =>'type',
                group         =>'status',
                label         =>'Type',
                dataobjattr   =>'cm3rm1.class_field'),

      new kernel::Field::Text(
                name          =>'approvalstatus',
                group         =>'status',
                label         =>'Approval Status',
                dataobjattr   =>'cm3rm1.approval_status'),

      new kernel::Field::Text(
                name          =>'currentstatus',
                group         =>'status',
                label         =>'Current Status',
                dataobjattr   =>'cm3rm1.status'),

      new kernel::Field::Text(
                name          =>'approvalstatus',
                group         =>'status',
                label         =>'Approval Status',
                dataobjattr   =>'cm3rm1.approval_status'),

      new kernel::Field::Date(
                name          =>'sysmodtime',
                group         =>'status',
                timezone      =>'CET',
                label         =>'SysModTime',
                dataobjattr   =>'cm3rm1.sysmodtime'),

      new kernel::Field::Date(
                name          =>'createtime',
                depend        =>['status'],
                group         =>'close',
                timezone      =>'CET',
                label         =>'Create time',
                dataobjattr   =>'cm3rm1.orig_date_entered'),

      new kernel::Field::Date(
                name          =>'closetime',
                depend        =>['status'],
                group         =>'close',
                timezone      =>'CET',
                label         =>'Closeing time',
                dataobjattr   =>'cm3rm1.close_time'),

      new kernel::Field::Text(
                name          =>'closecode',
                group         =>'close',
                label         =>'Close Code',
                dataobjattr   =>'cm3rm1.close_code_accept'),

      new kernel::Field::Text(
                name          =>'srcid',
                label         =>'Extern Change ID',
                dataobjattr   =>'cm3rm1.ex_number'),

      new kernel::Field::Date(
                name          =>'workstart',
                depend        =>['status'],
                group         =>'close',
                timezone      =>'CET',
                label         =>'Work Start',
                dataobjattr   =>'cm3rm1.work_start'),

      new kernel::Field::Date(
                name          =>'workend',
                depend        =>['status'],
                group         =>'close',
                timezone      =>'CET',
                label         =>'Work End',
                dataobjattr   =>'cm3rm1.work_end'),

      new kernel::Field::Text(
                name          =>'workduration',
                depend        =>['status'],
                group         =>'close',
                label         =>'Work Duration',
                dataobjattr   =>'cm3rm1.work_duration'),

      new kernel::Field::Import($self,
                vjointo       =>'tssc::chm_closingcomments',
                vjoinon       =>['changenumber'=>'changenumber'],
                vjoinconcat   =>"\n",
                group         =>"close",
                depend        =>['status'],
                fields        =>['closingcomments']),

      new kernel::Field::Text(
                name          =>'assignarea',
                group         =>'contact',
                label         =>'Assign Area',
                dataobjattr   =>'cm3rm1.assigned_area'),

      new kernel::Field::Text(
                name          =>'customer',
                group         =>'contact',
                label         =>'Customer',
                dataobjattr   =>'cm3rm1.misc4'),

      new kernel::Field::Text(
                name          =>'requestedby',
                group         =>'contact',
                label         =>'Requested By',
                dataobjattr   =>'cm3rm1.requested_by'),

      new kernel::Field::Text(
                name          =>'assignedto',
                uppersearch   =>1,
                group         =>'contact',
                label         =>'Assigned To',
                dataobjattr   =>'cm3rm1.assigned_to'),

      new kernel::Field::Text(
                name          =>'coordinator',
                uppersearch   =>1,
                group         =>'contact',
                label         =>'Coordinator',
                dataobjattr   =>'cm3rm1.coordinator'),

      new kernel::Field::Text(
                name          =>'editor',
                group         =>'contact',
                label         =>'Editor',
                dataobjattr   =>'cm3rm1.sysmoduser'),

      new kernel::Field::Text(
                name          =>'addgrp',
                sqlorder      =>"none",
                group         =>'contact',
                label         =>'Additional Groups',
                dataobjattr   =>'cm3rm1.additional_groups'),

   );

   $self->setDefaultView(qw(linenumber changenumber 
                            plannedstart plannedend 
                            status name));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tssc"));
   return(@result) if (defined($result[0]) eq "InitERROR");

   $self->{use_distinct}=0;
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getDetailBlockPriority                # posibility to change the block order
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),qw(status contact));
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/chm.jpg?".$cgi->query_string());
}

sub getSqlFrom
{
   my $self=shift;
   my $from="cm3rm1,cm3ra43";
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where="(cm3rm1.lastprgn='t' or cm3rm1.lastprgn is null) and ".
             "cm3rm1.numberprgn=cm3ra43.numberprgn(+)";
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
   if ($st ne "closed" && $st ne "rejected" && $st ne "resolved"){
      return(qw(contact default status header software device approvals));
   }
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

sub getHtmlDetailPages
{
   my $self=shift;
   my ($p,$rec)=@_;

   return($self->SUPER::getHtmlDetailPages($p,$rec),
          "VisualView"=>$self->T("Visual-View"));
}

sub getHtmlDetailPageContent
{
   my $self=shift;
   my ($p,$rec)=@_;
   return($self->SUPER::getHtmlDetailPageContent($p,$rec)) if ($p ne "VisualView");
   my $page;
   my $idname=$self->IdField->Name();
   my $idval=$rec->{$idname};
   
   if ($p eq "VisualView"){
      Query->Param("$idname"=>$idval);
      $idval="NONE" if ($idval eq "");

      my $q=new kernel::cgi({});
      $q->Param("$idname"=>$idval);
      my $urlparam=$q->QueryString();

      $page="<iframe style=\"width:100%;height:100%;border-width:0;".
            "padding:0;margin:0\" class=HtmlDetailPage name=HtmlDetailPage ".
            "src=\"VisualView?$urlparam\"></iframe>";
   }
   $page.=$self->HtmlPersistentVariables($idname);
   return($page);
}


sub getValidWebFunctions
{
   my $self=shift;

   return($self->SUPER::getValidWebFunctions(@_),"VisualView");
}


sub VisualView
{
   my $self=shift;

   my %flt=$self->getSearchHash();
   $self->ResetFilter();
   $self->SecureSetFilter(\%flt);
   my ($rec,$msg)=$self->getOnlyFirst(qw(ALL));

   print $self->HttpHeader();
   print $self->HtmlHeader(
                           style=>['default.css',
                             'work.css',
                             '../../../public/tssc/load/visual-view.css']);
#
   print("<body class=fullview><form>");
   print $self->BuildVisualView($rec);
   print("</form></body></html>");
}

sub BuildVisualView
{
   my $self=shift;
   my $rec=shift;
   my $d;

   my $label="CR# ";
   if ($rec->{changenumber} ne ""){
      $label.=$rec->{changenumber};
      $label.=" - ";
   }


   if ($rec->{risk} ne ""){
      $label.=$rec->{risk};
   }
   else{
      $label.="<font color=red>MISSING RISK</font>";
   }
   $label.=" - ";


   if ($rec->{impact} ne ""){
      $label.=$rec->{impact};
   }
   else{
      $label.="<font color=red>MISSING IMPACT</font>";
   }
   $label.=" - ";


   if ($rec->{type} ne ""){
      $label.=$rec->{type};
   }
   else{
      $label.="<font color=red>MISSING TYPE</font>";
   }
   $label.=" - ";

   if ($rec->{reason} ne ""){
      $label.=$rec->{reason};
   }
   else{
      $label.="<font color=red>MISSING REASON</font>";
   }
   $label.=" - ";
   my $templparam={WindowMode=>"HtmlDetail",current=>$rec};

   my $starttime=$self->findtemplvar($templparam,"plannedstart","detail");
   my $endtime=$self->findtemplvar($templparam,"plannedend","detail");
   my $requestedby=$self->findtemplvar($templparam,"requestedby","detail");

   my $gr="#75D194";
   my $rd="#F28C8C";
   my $bl="#B9C5F5";

   my $aprcol="";
   my $crscol="";
   my $bg="bgcolor";
   $aprcol="$bg=\"$gr\"" if (lc($rec->{approvalstatus}) eq "approved");
   $crscol="$bg=\"$bl\"" if (lc($rec->{currentstatus}) eq "work in progress");
   


   $d=<<EOF;
<div class=label>$label</div>
<table style="border-bottom-style:none">
<tr>
<td width=80>Start:</td>
<td>$starttime</td>
</tr>
<tr>
<td width=80>End:</td>
<td>$endtime</td>
</tr>
</table>

<table style="border-bottom-style:none">
<tr>
<td width=80><u>Auftraggeber:</u><br>&nbsp;</td>
<td width=107 $crscol>CR-Status:<br>
<b>$rec->{currentstatus}</b></td>
<td width=100 $aprcol>Approval:<br>
<b>$rec->{approvalstatus}</b></td>
<td>Owner:<br>
<b>$requestedby</b></td>
<td width=200>Assigned Group:<br>
<b>$rec->{assignedto}</b></td>
</tr>
</table>

<table><tr>
<td width=80><u>Change-Mgr:</u><br>&nbsp;</td>
<td>Group:<br>
<b>$rec->{coordinator}</b></td>
<td>Released by:<br>
<b>??</b></td>
<td>Completion Code:</td>
</tr>
</table>

<table style="margin-top:10px">
<tr>
<td>
  <table class=noborder>
    <tr>
     <td class=noborder align=right width=20%><b>Customer:</b></td>
     <td class=noborder>$rec->{customer}</td>
     <td class=noborder align=right width=20%><b>Ext. Change ID:</b></td>
     <td class=noborder>$rec->{srcid}</td>
    </tr>
    <tr>
     <td class=noborder align=right width=20%><b>Reason:</b></td>
     <td class=noborder>$rec->{reason}</td>
     <td class=noborder align=right width=20%><b>Project:</b></td>
     <td class=noborder>??</td>
    </tr>
    <tr>
     <td class=noborder align=right width=20%><b>Risk:</b></td>
     <td class=noborder>$rec->{risk}</td>
     <td class=noborder align=right width=20%><b>Int. Order:</b></td>
     <td class=noborder>??</td>
    </tr>
    <tr>
     <td class=noborder align=right width=20%><b>Req. Customer:</b></td>
     <td class=noborder>??</td>
     <td class=noborder align=right width=20%><b>&nbsp;</b></td>
     <td class=noborder>&nbsp;</td>
    </tr>
  </table>
</td>
</tr><tr>
<tr>
<td>Brief-Description:<br>
<b>$rec->{name}</b>
<img class=printspacer style="float:left" border=0
     src="../../../public/base/load/empty.gif" width=500 height=1>
</td>
</tr>
<tr>
<td><b><u>Description:</b></u><br>
<table style=\"width:100%;table-layout:fixed;padding:0;margin:0\">
<tr><td style="min-height:50px">
<pre class=multilinetext>$rec->{description}</pre>
</td></tr></table>
</td>
</tr>
<tr>
<td><b><u>Backout Method:</b></u><br>
<table style=\"width:100%;table-layout:fixed;padding:0;margin:0\">
<tr><td style="min-height:50px">
<pre class=multilinetext>$rec->{fallback}</pre>
</td></tr></table>
</td>
</tr>
</table>

EOF
   return($d);
}

sub getDefaultHtmlDetailPage
{
   my $self=shift;
   my $cookievar=shift;

   my $d=Query->Cookie($cookievar);
   $d="StandardDetail" if ($d eq "");
   return($d);
}






1;
