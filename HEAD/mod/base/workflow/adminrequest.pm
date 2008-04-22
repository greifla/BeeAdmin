package base::workflow::adminrequest;
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
use base::workflow::request;
@ISA=qw(base::workflow::request);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub IsModuleSelectable
{
   my $self=shift;
   my %env=@_;

   return(1);
}

sub getDefaultContractor
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   return('admin');
}

sub getPosibleActions
{
   my $self=shift;
   my $WfRec=shift;
   my $app=$self->getParent;
   my $userid=$self->getParent->getCurrentUserId();
   my $isadmin=$self->getParent->IsMemberOf("admin");
   my $stateid=$WfRec->{stateid};


   return("transform",$self->SUPER::getPosibleActions($WfRec));
}





sub getStepByShortname
{
   my $self=shift;
   my $shortname=shift;
   my $WfRec=shift;

   if ($shortname eq "dataload"){
      return("base::workflow::adminrequest::".$shortname);
   }
   return("base::workflow::request::".$shortname);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/workflow_admin.jpg?".$cgi->query_string());
}


#######################################################################
package base::workflow::adminrequest::dataload;
use vars qw(@ISA);
use kernel;
@ISA=qw(base::workflow::request::dataload);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   my $oldval=Query->Param("Formated_prio");
   $oldval="5" if (!defined($oldval));
   my $d="<select name=Formated_prio>";
   my @l=("high"=>3,"normal"=>5,"low"=>8);
   while(my $n=shift(@l)){
      my $i=shift(@l);
      $d.="<option value=\"$i\"";
      $d.=" selected" if ($i==$oldval);
      $d.=">".$self->T($n,"base::workflow")."</option>";
   }
   $d.="</select>";


   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
<tr>
<td class=fname width=20%>%name(label)%:</td>
<td class=finput>%name(detail)%</td>
</tr>
<tr>
<td class=fname valign=top width=20%>%detaildescription(label)%:</td>
<td class=finput>%detaildescription(detail)%</td>
</tr>
<tr>
<td class=fname width=20%>%prio(label)%:</td>
<td class=finput>$d</td>
</tr>
</table>
EOF
   return($templ);
}

sub addInitialParameters
{
   my $self=shift;
   my $newrec=shift;
   my $conumber=$self->getParent->Config->Param("W5BASEADMINCONUMBER");
   if ($conumber ne ""){
      my $co=getModuleObject($self->getParent->Config,"finance::costcenter");
      if (defined($co)){
         $co->SetFilter({name=>\$conumber,cistatusid=>\'4'});
         my ($corec)=$co->getOnlyFirst(qw(id));
         if (!defined($corec)){
            $self->getParent->LastMsg(ERROR,
             "invalid CO-Number for admin requests - please contact the admin");
            return(0);
         }
         $newrec->{conumber}=$conumber;
      }
   }
   return(1);
}




sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return("200");
}

1;
