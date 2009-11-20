package kernel::Field::SubList;
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
use Data::Dumper;
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->{_permitted}->{forwardSearch}=1;
   $self->{Sequence}=0;
   return($self);
}

sub vjoinobjInit
{
   my $self=shift;
   $self->vjoinobj->ResetFilter();
   if (defined($self->{vjoinbase})){
      $self->vjoinobj->SetNamedFilter("VJOINBASE",$self->{vjoinbase});
   }
}

sub EditProcessor
{
   my $self=shift;
   my $id=shift;
   my $seq=Query->Param("Seq");
   my $field=Query->Param("Field");
   my $app=$self->getParent();
   print $app->HttpHeader("text/html");
   print $app->HtmlHeader(style=>['default.css','work.css',
                                   'kernel.App.Web.css','Output.HtmlV01.css',
                                   'Output.HtmlSubList.css'],
                           body=>1,form=>1,
                           title=>'W5BaseV1-System');

   my $dfield=$app->getField($field);
   $dfield->vjoinobjInit();
   my %forceparam=$app->getForceParamForSubedit($id,$dfield);
   foreach my $v (keys(%forceparam)){
      Query->Param($v=>$forceparam{$v});
   }
   $dfield->vjoinobj->HandleSubListEdit(subeditmsk=>$dfield->{subeditmsk});

   $app->SetFilter({$app->IdField->Name()=>$id});
   $app->SetCurrentView($field);
   my ($rec,$msg)=$app->getFirst();
   if (defined($rec)){
      #$dfield->{subeditmsk}="sublistedit" if (!defined($dfield->{subeditmsk}));
      print $dfield->FormatedResult($rec,"HtmlSubListEdit");
   }
   else{
      print (msg(ERROR,"problem msg=$msg rec=$rec id=$rec idfield=%s",
                       $app->IdField->Name()));
   }
   print ($app->HtmlPersistentVariables(
                  qw(RefFromId Seq OP Field CurrentIdToEdit NewRecSelected)));
   print $app->HtmlBottom(body=>1,form=>1);

}

sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my %param=@_;
   my $app=$self->getParent;
   my $idfield=$app->IdField();
   my $id=$idfield->RawValue($current);
   my $name=$self->Name();
   $self->{Sequence}++;
   my $readonly=$self->readonly($current);
   if ($mode eq "edit" && !$readonly){
      my $h=$self->getParent->DetailY()-80;
      return(<<EOF);
<iframe id=iframe.sublist.$name.$self->{Sequence}.$id 
        src="EditProcessor?RefFromId=$id&Field=$name&Seq=$self->{Sequence}"
        style="width:99%;height:${h}px;border-style:solid;border-width:1px;">
</iframe>
EOF

   }
   if ($mode eq "HtmlDetail" || ($mode eq "edit" && $readonly)){
      $param{nodetaillink}=1 if ($self->{nodetaillink});
      return(<<EOF) if ($self->{async}==1 && $app->can('AsyncSubListView'));
<div id=div.sublist.$name.$self->{Sequence}.$id class=sublist>
<p style="height:50px">Loading asyncron data from $self->{joinobj}...</p>
</div>
<iframe id=iframe.sublist.$name.$self->{Sequence}.$id 
        src="AsyncSubListView?RefFromId=$id&Field=$name&Seq=$self->{Sequence}"
        style="display:none">
</iframe>
EOF
      my $d=$self->getSubListData($current,"HtmlDetail",%param);
      if ($d ne ""){
         if ($self->forwardSearch){
            my $target=$self->{vjointo};
            my $dstflt=$self->{vjoinon}->[1];
            my $src=$app->getField($self->{vjoinon}->[0])->RawValue($current);
            my $dstflt=$self->{vjoinon}->[1];
            $target=~s/::/\//g;
            $target="../../$target/NativResult?".
                    "AutoSearch=1&search_$dstflt=".quoteQueryString($src);
            my $vjoinbaseok=1;
            if (defined($self->{vjoinbase})){
               $vjoinbaseok=0;
               if (ref($self->{vjoinbase}) eq "ARRAY" &&
                   $#{$self->{vjoinbase}}==0){
                  if (ref($self->{vjoinbase}->[0]) eq "HASH"){
                     foreach my $k (keys(%{$self->{vjoinbase}->[0]})){
                         my $v=$self->{vjoinbase}->[0]->{$k};
                         $v=$$v if (ref($v) eq "SCALAR");
                         $target.="&search_$k=".quoteQueryString($v);
                     }
                     $vjoinbaseok=1;
                  } 
               }
            }
            if ($vjoinbaseok){ 
               my $cmd="parent.showPopWin('$target',null,null);";
               #my $cmd="alert('$target');";
               $d.="<div class=directsublist>".
                   "<img border=0 onclick=\"$cmd\" ".
                   "src=\"../../../public/base/load/directlink.gif\">".
                   "</div>";
            }
         }
      }
      return($d);
   }
   return("unknown mode '$mode'");
}

sub FormatedResult
{
   my $self=shift;
   my $current=shift;
   my $FormatAs=shift;
   my %param=@_;


   return($self->getSubListData($current,$FormatAs,%param));
}

sub getLineSubListData
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $app=$self->getParent;

   if (defined($self->{vjointo})){
      my $srcfield=$app->getField($self->{vjoinon}->[0]);
      if (!defined($srcfield)){
         msg(ERROR,"can't find field '$self->{vjoinon}->[0]'  in $app");
         return("undefined");
      }
      my $srcval=$srcfield->RawValue($current);
      my $loadfield=$self->{vjoinon}->[1];
      $self->vjoinobjInit();
      $self->vjoinobj->SetFilter({$self->{vjoinon}->[1]=>$srcval});
      my @view=@{$self->{vjoindisp}};
      if (defined($self->{'vjoindisp'.$mode})){
         if (!ref($self->{'vjoindisp'.$mode}) eq "ARRAY"){
            $self->{'vjoindisp'.$mode}=[$self->{'vjoindisp'.$mode}];
         }
         @view=@{$self->{'vjoindisp'.$mode}};
      }
      my $d="";
      foreach my $rec ($self->vjoinobj->getHashList(@view)){
         $d.="\n" if ($d ne "" && $#view>0); # if there is only one field, it
         foreach my $field (@view){          # isn't need to use linefeeds
            $d.="; " if ($d ne "" && !($d=~m/\n$/));
            my $da=$rec->{$field};
            $da=~s/[\n\r;]/ /g;
            $d.=$da;
         }
      }
      return($d);
   }
   return("ERROR: Data-Source not available");
}

sub getSubListData
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my %param=@_;
   my $app=$self->getParent;

   if (defined($self->{vjointo})){
      my $srcfield=$app->getField($self->{vjoinon}->[0]);
      if (!defined($srcfield)){
         msg(ERROR,"can't find field '$self->{vjoinon}->[0]'  in $app");
         return("undefined");
      }
      my $srcval=$srcfield->RawValue($current);
      my $loadfield=$self->{vjoinon}->[1];
      $self->vjoinobjInit();
      $self->vjoinobj->ResetFilter();
      if (defined($self->{vjoinbase})){
         my $base=$self->{vjoinbase};
         if (ref($base) eq "HASH"){
            $base=[$base];
         }
         $self->vjoinobj->SetNamedFilter("BASE",@{$base});
      }
      $self->vjoinobj->SetFilter({$self->{vjoinon}->[1]=>$srcval});

      my @view=@{$self->{vjoindisp}};
      if (defined($self->{'vjoindisp'.$mode})){
         if (!ref($self->{'vjoindisp'.$mode}) eq "ARRAY"){
            $self->{'vjoindisp'.$mode}=[$self->{'vjoindisp'.$mode}];
         }
         @view=@{$self->{'vjoindisp'.$mode}};
      }

      $self->vjoinobj->SetCurrentView(@view);
      $param{parentfield}=$self->Name();
      return($self->vjoinobj->getSubList($current,$mode,%param));
   }
   return("ERROR: Data-Source not available");
}

sub RawValue
{
   my $self=shift;
   my $current=shift;
   my $app=$self->getParent;

   if (exists($current->{$self->Name()})){
      return($current->{$self->Name()});
   }
   if (defined($self->{vjointo})){

      my $srcfield=$app->getField($self->{vjoinon}->[0]);
      my $srcval=$srcfield->RawValue($current);
      my $loadfield=$self->{vjoinon}->[1];
      $self->vjoinobjInit();
      if (defined($self->{vjoinbase})){
         my $base=$self->{vjoinbase};
         if (ref($base) eq "HASH"){
            $base=[$base];
         }
         $self->vjoinobj->SetNamedFilter("BASE",@{$base});
      }
      $self->vjoinobj->SetFilter({$self->{vjoinon}->[1]=>$srcval});
      my @view=($self->{vjoindisp});
      @view=@{$self->{vjoindisp}} if (ref($self->{vjoindisp}) eq "ARRAY");
      if (defined($self->{vjoininhash})){
         @view=($self->{vjoininhash});
         if (ref($self->{vjoininhash}) eq "ARRAY"){
            @view=@{$self->{vjoininhash}};
         }
      }
      my $res=$self->vjoinobj->getHashList(@view);
      $current->{$self->Name()}=$res;
      return($res);
   }
   return(undef);
}



sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;

   my $idfield=$self->getParent->IdField()->Name();
   my $id=$oldrec->{$idfield};
   if (defined($self->{allowcleanup}) && $self->{allowcleanup}==1){
      my $srcval=$oldrec->{$self->{vjoinon}->[0]};
      my $loadfield=$self->{vjoinon}->[1];
      $self->vjoinobjInit();
      if (defined($self->{vjoinbase})){
         my $base=$self->{vjoinbase};
         if (ref($base) eq "HASH"){
            $base=[$base];
         }
         $self->vjoinobj->SetNamedFilter("BASE",@{$base});
      }
      $self->vjoinobj->SetFilter({$self->{vjoinon}->[1]=>$srcval});
      $self->vjoinobj->SetCurrentView(qw(ALL));
      $self->vjoinobj->ForeachFilteredRecord(sub{
                         $self->vjoinobj->ValidatedDeleteRecord($_);
                      });
   }
   return(undef);
}

sub copyFrom
{
   my $self=shift;
   my $oldrec=shift;
   return(undef);
}

sub Uploadable
{
   my $self=shift;

   return(0);
}  

sub extendPageHeader
{
   my $self=shift;
   my $mode=shift;
   my $current=shift;
   my $curPageHeadRef=shift;
   if ($mode eq "Detail" || ($mode=~m/^html/i)){
      if (!($$curPageHeadRef=~m/^<script id=sortabletable /)){
         $$curPageHeadRef.=
              "<script id=sortabletable language=\"JavaScript\" ".
              "src=\"../../base/load/sortabletable.js\"></script>\n";
      }
   }
}


   
   









1;
