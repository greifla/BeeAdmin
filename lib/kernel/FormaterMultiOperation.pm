package kernel::FormaterMultiOperation;
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
@ISA    = qw(kernel::Formater);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}

sub getRecordImageUrl
{
   my $self=shift;

   return("../../../public/base/load/icon_actor.gif");
}
sub Label
{
   my $self=shift;

   return("multi op:".$self->Self);
}
sub Description
{
   my $self=shift;

   return("Description of ".$self->Self);
}

sub MimeType
{
   return("text/html");
}

sub IsModuleDownloadable
{
   return(0);
}

sub getHttpHeader
{  
   my $self=shift;
   my $d="";
   $d.=$self->getParent->getParent->HttpHeader($self->MimeType());

   return($d);
}

sub Validate
{
   my $self=shift;

   return(1);
}

sub ProcessHead
{
   my ($self,$fh)=@_;
   my $app=$self->getParent->getParent();
   my $view=$app->getCurrentViewName();
   my @view;
   if (ref($self->{fieldobjects}) eq "ARRAY"){
      @view=@{$self->{fieldobjects}};
   }

   my $d="";
   $d.=$app->HtmlHeader(form=>1,body=>1,
                        style=>[qw(default.css MultiAct.css)]);
   if ($self->{FAIL}){
      $self->getParent->getParent->LastMsg(ERROR,
          $self->getParent->getParent->T("some operations failed",
                                         'kernel::Output::MultiDelete'));
   }
   $d.=<<EOF;
<script language="JavaScript">
var allon=false;
function MarkAll()
{
   for(var i = 0; i < document.forms.length; i++) {
      for(var e = 0; e < document.forms[i].length; e++){
         if(document.forms[i].elements[e].className == "ACT") {
            document.forms[i].elements[e].checked=!allon;
         }
      }
   }
   allon=!allon;
}
</script>
EOF
   $d.=$self->MultiOperationHeader($app);
   my $lastmsg="&nbsp;"; 
   if ($self->getParent->getParent->LastMsg()){
      $lastmsg="<font color=red>".
               join("<br>",$self->getParent->getParent->LastMsg())."</font>";
   }
   $d.="$lastmsg<br>";
   $d.=$self->Context->{MultiActor};

   foreach my $v (Query->Param()){
      next if ($v=~m/^search_.*$/);
      next if ($v=~m/^FormatAs$/);
      next if ($v=~m/^CurrentView$/);
      Query->Delete($v);
   }
   $d.=$app->HtmlPersistentVariables(qw(ALL));

   $d.="<table class=data width=100%>";
   $d.="<tr><th width=1%>".
       "<input type=button OnClick=MarkAll() value=\"X\" ".
       "style=\"width:100%;height:100%\"></th>";
   for(my $c=0;$c<=$#{$self->{fieldobjects}};$c++){
      my $fo=$self->{fieldobjects}->[$c];
      my $label=$fo->Label();
      $d.="<th>$label</th>";
   }
   $d.="</tr>";
}

sub MultiOperationHeader
{
   my $self=shift;
   my $d="";

   return($d);
}




sub MultiOperationActionOn
{
   my $self=shift;
   my $app=shift;

   return(1);
}

sub ProcessLine
{
   my ($self,$fh,$viewgroups,$rec,$msg)=@_;
   my $app=$self->getParent->getParent();
   my @view=$app->getFieldObjsByView([$app->getCurrentView()],
                                     current=>$rec);
   my $d="";
   my $idfield=$app->IdField();

   $d.="<tr>";
   my $idtag="ACT:".$idfield->RawValue($rec);
   my $class="line";
   my $marker="<input class=ACT type=checkbox name=$idtag>";
   my $tag=Query->Param($idtag);
   my $fail=0;
   my $lastmsg;
   if ($tag ne ""){
      $fail=1;
      my ($id)=$idtag=~m/^ACT:(.+)$/;
      if ($id ne ""){
         $fail=0;
         if ($self->Context->{DO}){
            $fail=1;
            if ($self->Context->{VALID}){
               if ($self->MultiOperationActionOn($app,$id)){
                  $fail=0;
               }
            }
         }
      }
      if ($app->LastMsg()){
         $lastmsg=join("<br>\n",$app->LastMsg());
         $app->LastMsg("");
         $self->{FAIL}++;
         $fail++;
         $marker="<input class=ACT checked type=checkbox name=$idtag>";
      }
      if (!$fail){
         Query->Delete($idtag);
         $class="lineok";
         $marker="&nbsp;";
      }
      else{
         $class="linefail";
      }
   }
   if ($fail==1 && $lastmsg eq ""){
      $lastmsg="ERROR: ".
               $self->getParent->getParent->T("unknown or recurring problem",
                                              'kernel::Output::MultiInfoabo');
      $marker="<input class=ACT checked type=checkbox name=$idtag>";
   }
   my $rowspan=1;
   $rowspan=2 if ($fail>0);
   $d.="<tr class=$class>".
       "<td align=center valign=top rowspan=$rowspan>$marker</td>";
   for(my $cc;$cc<=$#view;$cc++){
      my $fo=$view[$cc];
      my $fieldname=$fo->Name();
      my $fulldata=$app->findtemplvar({viewgroups=>$viewgroups,
                                      current=>$rec,
                                      WindowMode=>"HtmlResult"
                                     },$fieldname,
                                        "formated");
      $fulldata=join("\n",map({
                                my $bk=$_;
                                if (ref($_) eq "HASH"){
                                   $bk=join("; ",values(%{$_}));
                                }
                                $bk;
                              }@$fulldata)) if (ref($fulldata) eq "ARRAY");
      $fulldata="&nbsp;" if ($fulldata eq "");
      $fulldata=~s/\n/<br>/g;
      $d.="<td>".$fulldata."</td>";
   }
   $d.="</tr>";
   if ($rowspan==2){
      $d.=sprintf("<tr><td colspan=%d><b>".
                  "<font color=darkred>$lastmsg</font></b></td></tr>",$#view+1);
   }
   return($d);
}

sub MultiOperationActionOn
{
   my $self=shift;
   my $app=shift;
   my $id=shift;

   return(1);
}

sub Init
{
   my $self=shift;

   if (Query->Param("DO") ne ""){
      $self->Context->{DO}=1;
   }
   $self->Context->{VALID}=$self->Validate();
}



sub ProcessBottom
{
   my ($self,$fh,$rec,$msg)=@_;
   my $d;
   my $app=$self->getParent->getParent();

   $d.="</table>";
   $self->Context->{MultiActor}=$self->MultiOperationActor($app);
   $d.=$self->Context->{MultiActor};
   $d.=$app->HtmlBottom(form=>1,body=>1);
   delete($self->Context->{opobj});
   $self->MultiOperationBottom($app);
   return($d);
}

sub MultiOperationActor
{
   my $self=shift;
   my $app=shift;
   my $text=shift;
   $text="Start Operation" if ($text eq "");

   return("<center><input class=button name=DO type=submit ".
          "value=\"$text\"></center>");
}

sub MultiOperationBottom
{
   my $self=shift;
   my $app=shift;

   return(1);
}

1;
