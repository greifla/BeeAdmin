package base::QuickFind::location;
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
   my $stag=shift;
   my $tag=shift;
   my $searchtext=shift;
   my %param=@_;

   my @l;
   if (grep(/^ci$/,@$stag) &&
       (!defined($tag) || grep(/^$tag$/,qw(location standort)))){
      my $flt=[{name=>"*$searchtext*", cistatusid=>"<=5"}];
      if ($searchtext=~m/^\d+$/){
         $flt=[{id=>\"$searchtext",cistatusid=>"<=5"}];
      }
      my $dataobj=getModuleObject($self->getParent->Config,"base::location");
      $dataobj->SetFilter($flt);
      my $limit=10;
      $dataobj->Limit($limit+1);
      my $c=0;
      foreach my $rec ($dataobj->getHashList(qw(name location))){
         my $dispname=$rec->{name};
         $c++;
         if ($c<=$limit){
            push(@l,{group=>$self->getParent->T("base::location",
                                                "base::location"),
                     id=>$rec->{id},
                     parent=>$self->Self,
                     name=>$dispname});
         }
         else{
            push(@l,{group=>$self->getParent->T("base::location","base::location"),
                     id=>undef,
                     parent=>$self->Self,
                     name=>"..."});
            last;
         }
      }
   }
   return(@l);
}

sub QuickFindDetail
{
   my $self=shift;
   my $id=shift;
   my $htmlresult="?";

   my $dataobj=getModuleObject($self->getParent->Config,"base::location");
   $dataobj->SetFilter({id=>\$id});
   my @fl=qw(label address1 location);
   my ($rec,$msg)=$dataobj->getOnlyFirst(@fl);

   $dataobj->ResetFilter();
   $dataobj->SecureSetFilter([{id=>\$id}]);
   my ($secrec,$msg)=$dataobj->getOnlyFirst(qw(id));

   if (defined($rec)){
      $htmlresult="";
      if (defined($secrec)){
         $htmlresult.=$self->addDirectLink($dataobj,{search_id=>$id});
      }
      $htmlresult.="<table>";
      my @l=@fl;
      foreach my $v (@l){
         if ($rec->{$v} ne ""){
            my $name=$dataobj->getField($v)->Label();
            my $data=$dataobj->findtemplvar({current=>$rec,mode=>"HtmlDetail"},
                                         $v,"formated");
            $htmlresult.="<tr><td nowrap valign=top width=1%>$name:</td>".
                         "<td valign=top>$data</td></tr>";
         }
      }
      $htmlresult.="</table>";
   }
   return($htmlresult);
}



1;
