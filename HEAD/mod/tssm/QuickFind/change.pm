package tssc::QuickFind::change;
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

sub ExtendStags
{
   my $self=shift;
   my $stags=shift;
   if ($ENV{REMOTE_USER} ne "anonymous"){
      push(@$stags,"citsscchm","T-Systems ServiceCenter Change");
   }
}

sub CISearchResult
{
   my $self=shift;
   my $stag=shift;
   my $tag=shift;
   my $searchtext=shift;
   my %param=@_;

   my @l;
   if (grep(/^citsscchm$/,@$stag)){
      my @searchtext=grep(/^CHM\d+$/,
                          grep(!/^\s*$/,split(/[\s;,]+/,$searchtext)));
      if ($#searchtext>10){
         @searchtext=$searchtext[1..10];
      }
      my $flt=[{changenumber=>\@searchtext}];
      my $tschm=getModuleObject($self->getParent->Config,"tssc::chm");
      $tschm->SetFilter($flt);
      foreach my $rec ($tschm->getHashList(qw(changenumber name))){
         my $dispname=$rec->{changenumber}.": ".$rec->{name};
         push(@l,{group=>$self->getParent->T("tssc::chm","tssc::chm"),
                  id=>$rec->{changenumber},
                  parent=>$self->Self,
                  name=>$dispname});
      }
      my $flt=[{srcid=>\@searchtext}];
      my $wf=getModuleObject($self->getParent->Config,"base::workflow");
      $wf->SetFilter($flt);
      foreach my $rec ($wf->getHashList(qw(id srcid name))){
         my $dispname=$rec->{srcid}.": ".$rec->{name};
         push(@l,{group=>"W5Base Replikation: ".
                         $self->getParent->T("base::workflow","base::workflow"),
                  id=>$rec->{id},
                  parent=>$self->Self,
                  name=>$dispname});
      }
   }
   return(@l);
}

sub QuickFindDetail
{
   my $self=shift;
   my $id=shift;
   my $htmlresult="?";

   if ($id=~m/^\d{10,15}$/){
      my $wf=getModuleObject($self->getParent->Config,"base::workflow");
      $wf->SetFilter({id=>\$id});
      my @l=qw(id name srcid srcload);
      my ($rec,$msg)=$wf->getOnlyFirst(@l);
      $wf->ResetFilter();
      $wf->SecureSetFilter([{id=>\$id}]);
      my ($secrec,$msg)=$wf->getOnlyFirst(@l);
     
      if (defined($rec)){
         $htmlresult="";
         if (defined($secrec)){
            $htmlresult.=$self->addDirectLink($wf,{id=>$id});
         }
         $htmlresult.="<table>\n";
         foreach my $v (@l){
            if ($rec->{$v} ne ""){
               my $name=$wf->getField($v)->Label();
               my $data=$wf->findtemplvar({current=>$rec,
                                                  mode=>"HtmlDetail"},
                                            $v,"formated");
               $htmlresult.="<tr><td nowrap valign=top width=1%>$name:</td>".
                            "<td valign=top>$data</td></tr>\n";
            }
         }
      }
   }
   else{
      my $tschm=getModuleObject($self->getParent->Config,"tssc::chm");
      $tschm->SetFilter({changenumber=>\$id});
      my @l=qw(changenumber name);
      my ($rec,$msg)=$tschm->getOnlyFirst(@l);
      $tschm->ResetFilter();
      if ($tschm->SecureSetFilter([{changenumber=>\$id}])){
         my ($secrec,$msg)=$tschm->getOnlyFirst(qw(changenumber));
     
         if (defined($rec)){
            $htmlresult="";
            if (defined($secrec)){
               $htmlresult.=$self->addDirectLink($tschm,
                                                 {search_changenumber=>$id});
            }
            $htmlresult.="<table>\n";
            foreach my $v (@l){
               if ($rec->{$v} ne ""){
                  my $name=$tschm->getField($v)->Label();
                  my $data=$tschm->findtemplvar({current=>$rec,
                                                     mode=>"HtmlDetail"},
                                               $v,"formated");
                  $htmlresult.="<tr><td nowrap valign=top width=1%>$name:</td>".
                               "<td valign=top>$data</td></tr>\n";
               }
            }
         }
      }
      else{
         my $msg=$tschm->findtemplvar({},"LASTMSG","formated");
         $htmlresult=$msg;
      }
   }
   return($htmlresult);
}



1;
