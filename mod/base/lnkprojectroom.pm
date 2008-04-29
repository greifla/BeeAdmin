package base::lnkprojectroom;
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
                label         =>'LinkID',
                dataobjattr   =>'lnkprojectroom.id'),
                                                 
      new kernel::Field::Link(
                name          =>'projectroomid',
                label         =>'ProjectroomID',
                dataobjattr   =>'lnkprojectroom.projectroom'),

      new kernel::Field::Text(
                name          =>'parentobj',
                label         =>'Parent-Object',
                dataobjattr   =>'lnkprojectroom.objtype'),

      new kernel::Field::Text(
                name          =>'parentobjname',
                label         =>'Parent-Object Name',
                htmlwidth     =>'50px',
                readonly      =>1,
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $parentobj=$current->{parentobj};
                   return($self->getParent->T($parentobj,$parentobj));
                },
                depend        =>['parentobj']),

      new kernel::Field::Text(
                name          =>'refid',
                label         =>'RefID',
                dataobjattr   =>'lnkprojectroom.objid'),


#      new kernel::Field::DynWebIcon(
#                name          =>'targetweblink',
#                searchable    =>0,
#                depend        =>['target','targetid'],
#                htmlwidth     =>'5px',
#                htmldetail    =>0,
#                weblink       =>sub{
#                   my $self=shift;
#                   my $current=shift;
#                   my $mode=shift;
#                   my $app=$self->getParent;
#
#                   my $targeto=$self->getParent->getField("target");
#                   my $target=$targeto->RawValue($current);
#
#                   my $targetido=$self->getParent->getField("targetid");
#                   my $targetid=$targetido->RawValue($current);
#                   my $img="<img ";
#                   $img.="src=\"../../base/load/directlink.gif\" ";
#                   $img.="title=\"\" border=0>";
#                   my $dest;
#                   if ($target eq "base::user"){
#                      $dest="../../base/user/Detail?userid=$targetid";
#                   }
#                   if ($target eq "base::grp"){
#                      $dest="../../base/grp/Detail?grpid=$targetid";
#                   }
#                   my $detailx=$app->DetailX();
#                   my $detaily=$app->DetailY();
#                   my $onclick="openwin(\"$dest\",\"_blank\",".
#                       "\"height=$detaily,width=$detailx,toolbar=no,status=no,".
#                       "resizable=yes,scrollbars=no\")";
#
#                   if ($mode=~m/html/i){
#                      return("<a href=javascript:$onclick>$img</a>");
#                   }
#                   return("-only a web useable link-");
#                }),


      new kernel::Field::Text(
                name          =>'comments',
                htmlwidth     =>'150',
                label         =>'Comments',
                dataobjattr   =>'lnkprojectroom.comments'),


      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnkprojectroom.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'lnkprojectroom.modifyuser'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnkprojectroom.srcsys'),
                                                 
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnkprojectroom.srcid'),
                                                 
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'lnkprojectroom.srcload'),
                                                 
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkprojectroom.createdate'),
                                                 
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkprojectroom.modifydate'),
                                                 
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'lnkprojectroom.editor'),
                                                 
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'lnkprojectroom.realeditor'),
   );
   $self->setDefaultView(qw(parentobj refid cdate editor));
   $self->setWorktable("lnkprojectroom");
   return($self);
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $parentobj=effVal($oldrec,$newrec,"parentobj");
   my $refid=effVal($oldrec,$newrec,"refid");
   if (!defined($parentobj) || $parentobj eq ""){
      $self->LastMsg(ERROR,"empty parent object");
      return(0);
   }
   if (!defined($refid) || $refid eq ""){
      $self->LastMsg(ERROR,"empty refid");
      return(0);
   }
   #
   # Security check
   #
   my $p=getModuleObject($self->Config,$parentobj);
   if (!defined($p)){ 
      $self->LastMsg(ERROR,"invalid parentobj '$parentobj'");
      return(0);
   }
   my $idname=$p->IdField->Name();
   my %flt=($idname=>\$refid);
   $p->SetFilter(\%flt);
   my @l=$p->getHashList(qw(ALL));
   if ($#l!=0){
      $self->LastMsg(ERROR,"invalid refid '$refid' in parent object '$parentobj'");
      return(0);
   }
   return(1) if ($self->IsMemberOf("admin"));

#   if ($self->isDataInputFromUserFrontend()){
#      my @write=$p->isWriteValid($l[0]);
#      if ($#write!=-1){
#         return(1) if (grep(/^ALL$/,@write));
#         foreach my $fo ($p->getFieldObjsByView(["ALL"],current=>$l[0])){
#            if ($fo->Type() eq "ContactLnk"){
#               my $grp=quotemeta($fo->{group});
#               $grp="default" if ($grp eq "");
#               return(1) if (grep(/^$grp$/,@write));
#            }
#         }
#      }
#   }
#   else{
#      return(1);
#   }
#   $self->LastMsg(ERROR,"no write access");
   return(0);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
#   return("default") if ($self->IsMemberOf("admin"));
   return("default");
}




1;
