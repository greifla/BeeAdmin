package base::MyW5Base::myefforts;
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
use kernel::MyW5Base;
use kernel::date;
use kernel::FlashChart;
@ISA=qw(kernel::MyW5Base kernel::FlashChart);

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
   $self->{DataObj}=getModuleObject($self->getParent->Config,
                                    "base::cistatus");  # dummy dataobject
   return(1);
}

sub getDefaultStdButtonBar
{
   my $self=shift;
   return('%StdButtonBar(bookmark,print,search)%');
}

sub isSelectable
{
   my $self=shift;

#   my $acl=$self->getParent->getMenuAcl($ENV{REMOTE_USER},
#                          "base::MyW5Base",
#                          func=>'Main',
#                          param=>'MyW5BaseSUBMOD=base::MyW5Base::wfmyjobs');
#   if (defined($acl)){
#      return(1) if (grep(/^read$/,@$acl));
#   }
   return(1);
}

sub Result
{
   my $self=shift;
   my $app=$self->getParent();

   print $app->HttpHeader("text/html"); 
   print $app->HtmlHeader(style=>['default.css','work.css',
                                   'kernel.App.Web.css','myw5base.css'],
                      js=>['toolbox.js',
                           'jquery.js',
                           '../../../static/open-flash-chart/js/swfobject.js'],
                      body=>1,form=>1,
                      title=>'my effort state');
   return("") if ($ENV{REMOTE_USER} eq "anonymous");

   my $tz=$app->UserTimezone();
   my $userid=$self->getParent->getCurrentUserId();
   $userid=-1 if (!defined($userid) || $userid==0);

   my $wa=getModuleObject($self->getParent->Config,"base::workflowaction");
   $wa->SetFilter({bookingdate=>">today-14d AND <now",
                   creatorid=>\$userid});
   $wa->SetCurrentOrder(qw(NONE));
   my %wfheadid;
   my %day;
   my $sumeff;
   my $sumtoday;
   my @now=Today_and_Now($tz);
   $wa->SetCurrentView(qw(wfheadid bookingdate effort));
   my ($rec,$msg)=$wa->getFirst();
   if (defined($rec)){
      do{
         $wfheadid{$rec->{wfheadid}}++;
         my $utime=Date_to_Time("GMT",$rec->{bookingdate});
         my @ldate=Time_to_Date($tz,$utime);
         my $day=sprintf("%04d-%02d-%02d",$ldate[0],$ldate[1],$ldate[2]);
         $day{$day}+=($rec->{effort}+0);
         $sumeff+=($rec->{effort}+0);
         if ($ldate[0]==$now[0] && $ldate[1]==$now[1] && $ldate[2]==$now[2]){
            $sumtoday+=($rec->{effort}+0);
         }
         #printf ("<pre>@ldate=%s</pre>\n",Dumper($rec));
         ($rec,$msg)=$wa->getNext();
      } until(!defined($rec));
   }
   my $wfcount=keys(%wfheadid);
   my $now=sprintf("%04d-%02d-%02d",$now[0],$now[1],$now[2]);
   my $data=[];
   my $xlabel=[];
   my @n=@now;
   my $wtcount=0;
   for(my $d=0;$d<=14;$d++){
      my $day=sprintf("%04d-%02d-%02d",$n[0],$n[1],$n[2]);
      my ($y,$m,$d)=$day=~m/^(\d+)-(\d+)-(\d+)$/;
      my $dow=Day_of_Week($n[0],$n[1],$n[2]);
      if ($dow==7 || $dow==6){
         unshift(@$xlabel,"-");
      }
      else{
         $wtcount++;
         unshift(@$xlabel,"$d.");
      }
      unshift(@$data,sprintf("%0.1f",$day{$day}/60.0));

      @n=Add_Delta_YMD($tz,$n[0],$n[1],$n[2],0,0,-1);
   }
   my $mwteff=sprintf("%.2f&nbsp;h&nbsp;",$sumeff/$wtcount/60);
   my $miteff=sprintf("%.2f&nbsp;h&nbsp;",$sumeff/14.0/60);
   $sumeff=sprintf("%.2f&nbsp;h&nbsp;",$sumeff/60);
   my $sumnoweff=sprintf("%.2f&nbsp;h&nbsp;",$sumtoday/60);

   my $user=getModuleObject($self->getParent->Config,"base::user");
   $user->SetFilter({userid=>\$userid});
   my ($usrrec)=$user->getOnlyFirst(qw(fullname));

   print("<center><table width=500>");
   printf("<tr><td align=center>".
          "<a class=h2 href=\"Result?MyW5BaseSUBMOD=base::MyW5Base::myefforts\">".
          "<h2>%s<br>\n%s</h2></a></td></tr>",
          $self->T("Effort statistics of the last 14 days of"),
          $usrrec->{fullname});
   print("<tr><td>");
   print  $self->buildChart("MyEffortChart",$data,
                      xlabel=>$xlabel,minymax=>1,
                      width=>500,height=>200, 
                      label=>$self->T("my documented efforts"));
   print("</td></tr>");
   print("<tr><td>");
   my $l1=$self->T("averanged work efforts/weekday");
   my $l2=$self->T("count weekdays");
   my $l3=$self->T("averanged work efforts/day");
   my $l4=$self->T("count workflows");
   my $l5=$self->T("sum efforts in the last 14 days");
   my $l6=$self->T("sum efforts today");
   my $condition=$self->T("condition");
   my $cond=Date_to_String("de",@now);
   print(<<EOF);
<table width=100% border=1 style="border-collapse:collapse">
<tr>
<td width=45% nowrap>$l1</td><td align=right width=40><b>$mwteff</b></td>
<td width=45% nowrap>$l2</td><td width=40 align=right>$wtcount&nbsp;</td></tr>
<tr>
<td nowrap>$l3</td><td align=right width=40>$miteff</td>
<td nowrap>$l4</td><td width=40 align=right>$wfcount&nbsp;</td></tr>
<tr><td nowrap>$l5</td><td align=right width=40 >$sumeff</td>
<td nowrap>$l6</td><td align=right width=40 >$sumnoweff</td></tr>
</table>
<input type=hidden name=MyW5BaseSUBMOD value="base::MyW5Base::myefforts">
<script language="JavaScript">
window.setTimeout(function(){document.forms[0].submit()},600000);
</script>
EOF
   print("</td></tr>");
   print("<tr><td align=right>$condition: $cond</td></tr>");
   print("</table>");
   print $app->HtmlBottom(body=>1,form=>1);
   return("");
}




1;
