package itil::QuickFind::appl;
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
use kernel::QuickFind;
@ISA=qw(kernel::QuickFind);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   return($self);
}

sub CISearchResult
{
   my $self=shift;
   my $searchtext=shift;
   my %param=@_;

   my $flt=[{name=>"*$searchtext*"},{systems=>"$searchtext"}];
   if ($searchtext=~m/^\d{3,20}$/){
      push(@$flt,{conumber=>\"$searchtext"});
   }
   my $appl=getModuleObject($self->getParent->Config,"itil::appl");
   $appl->SetFilter($flt);
   my @l;
   foreach my $rec ($appl->getHashList(qw(name customer))){
      my $dispname=$rec->{name};
      if ($rec->{customer} ne ""){
         $dispname.=' @ '.$rec->{customer};
      }
      push(@l,{group=>$self->getParent->T("itil::appl","itil::appl"),
               id=>$rec->{id},
               parent=>$self->Self,
               name=>$dispname});
   }
   return(@l);
}

sub QuickFindDetail
{
   my $self=shift;
   my $id=shift;
   my $htmlresult="?";

   my $appl=getModuleObject($self->getParent->Config,"itil::appl");
   $appl->SetFilter({id=>\$id});
   my ($rec,$msg)=$appl->getOnlyFirst(qw(delmgr delmgr2 conumber cistatus 
                                         sem sem2 tsm tsm2 description));
   $appl->ResetFilter();
   $appl->SecureSetFilter([{id=>\$id}]);
   my ($secrec,$msg)=$appl->getOnlyFirst(qw(id));

   if (defined($rec)){
      $htmlresult="";
      if (defined($secrec)){
         $htmlresult.=$self->addDirectLink($appl,search_id=>$id);
      }
      $htmlresult.="<table>";
      my @l=qw(sem sem2 delmgr delmgr2 tsm tsm2);
      foreach my $v (@l){
         if ($rec->{$v} ne ""){
            my $name=$appl->getField($v)->Label();
            my $data=$appl->findtemplvar({current=>$rec,mode=>"HtmlDetail"},
                                         $v,"formated");
            $htmlresult.="<tr><td nowrap valign=top width=1%>$name:</td>".
                         "<td valign=top>$data</td></tr>";
         }
      }
      my $desclabel=$appl->getField("description")->Label();
      my $desc=$rec->{description};
      $desc=~s/\n/<br>\n/g;
    
      $htmlresult.="</table>";
      $htmlresult.="<table><tr><td><div style=\"height:60px;overflow:auto;color:gray\">".
                   "<font color=black>$desclabel:</font><div>$desc".
                   "</div></div></td></tr></table>";
   }
   return($htmlresult);
}



1;
