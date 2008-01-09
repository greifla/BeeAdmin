package base::note;
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
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                uivisible     =>0,
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'postitnote.id'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Label',
                dataobjattr   =>'postitnote.name'),

      new kernel::Field::Text(
                name          =>'comments',
                label         =>'Note',
                dataobjattr   =>'postitnote.comments'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'postitnote.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'postitnote.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'postitnote.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'postitnote.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'postitnote.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'postitnote.realeditor'),

   );
   $self->setDefaultView(qw(linenumber name groupname cistatus cdate mdate));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5base"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   $self->setWorktable("note");
   return(1);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $name=trim(effVal($oldrec,$newrec,"name"));
   if ($name=~m/\s/i){
      $self->LastMsg(ERROR,"invalid sitename '%s' specified",$name); 
      return(undef);
   }
   $newrec->{'name'}=$name;
   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec) && $self->IsMemberOf("admin"));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if ($self->IsMemberOf("admin"));
   return(undef);
}


sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(Actor Display),$self->SUPER::getValidWebFunctions());
}

sub Display
{
   my $self=shift;
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css'],
                           form=>1,body=>1,
                           title=>"W5Notes");
   print("<style>body,form,html{background:#FDFBD6;overflow:hidden}</style>");
   printf("<textarea style=\"width:100%;height:98px;background-color:#FDFBD6;border-style:none\">xxx</textarea>");

   print $self->HtmlBottom(body=>1,form=>1);
}

sub Actor
{
   my ($self)=@_;

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','mainwork.css',
                                   'kernel.TabSelector.css'],
                           js=>['toolbox.js'],
                           form=>1,body=>1,
                           title=>"W5Notes");
   if ($self->IsMemberOf("admin")){
      print "<a class=ModeSelectFunctionLink href=\"JavaScript:addPostIt(10,10)\">Add</a>";
      print "&bull;<a class=ModeSelectFunctionLink href=\"JavaScript:hidePrivate()\">Hide</a>";
      print "&bull;<a class=ModeSelectFunctionLink href=\"JavaScript:showPrivate()\">Show</a>";
   }
   print(<<EOF);
<div id="headcode" style="display:none;visible:hidden">
<div style="width:100%;height:20px;background:yellow">
PostIt
</div>
</div>
<script language="JavaScript">
function addPostIt(x,y,id)
{
   if (id==""){
      id="xx";
   }
   if (parent.activateAni){
      var div = parent.document.createElement('div');
      var h=document.getElementById("headcode");
      div.innerHTML=h.innerHTML+
                    "<iframe frameborder=0 style=\\"border-style:none;\\" "+
                    "src=\\"../../base/note/Display?id="+id+"\\" "+
                    "width=100% height=100></iframe>";
      div.style.background="#FDFBD6";
      div.style.position="absolute";
      div.style.overflow="hidden";
      div.style.border="solid 1px";
      div.style.left=x+"px";
      div.style.top=y+"px";
      div.style.width="160px";
      div.style.height="120px";
      div.id=id;
      var postit=parent.document.getElementById("PostIT");
      if (!postit){
         alert("postit not found");
      }
      postit.appendChild(div);
      parent.activateAni(div.id);
   }
}
function showPublic()
{
   var postit=parent.document.getElementById("PostIT");
   postit.style.display="block";
   postit.style.visibility="visible";
}
function hidePublic()
{
   var postit=parent.document.getElementById("PostIT");
   postit.style.display="none";
   postit.style.visibility="hidden";

}
function showPrivate()
{

}
function hidePrivate()
{

}
function activatePostits()
{
 //  addPostIt(200,40,"postit123");
 //  addPostIt(350,50,"postit456");

}
addEvent(window, "load", activatePostits);

</script>
EOF
   print $self->HtmlBottom(body=>1,form=>1);
}








1;
