package itil::appladv;
#  W5Base Framework
#  Copyright (C) 2012  Hartmut Vogler (it@guru.de)
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
use itil::appldoc;
@ISA=qw(itil::appldoc);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   $param{Worktable}='appladv';
   $param{doclabel}='-ADV';
   my $self=bless($type->SUPER::new(%param),$type);

   my $ic=$self->getField("isactive");
   $ic->{label}="active ADV";
   $ic->{translation}='itil::appladv';

   my @allmodules=$self->getAllPosibleApplModules();
   $self->{allModules}=[];
   while(my $k=shift(@allmodules)){
      shift(@allmodules);
      push(@{$self->{allModules}},$k);
   }


   $self->AddFields(
      new kernel::Field::Link(
                name          =>'databossid',
                dataobjattr   =>"appl.sem"),
                insertafter=>'mandator'
        
   );
   $self->AddFields(
      new kernel::Field::Link(
                name          =>'sem2id',
                dataobjattr   =>"appl.sem2"),
                insertafter=>'databossid'
        
   );
   $self->AddFields(
      new kernel::Field::Databoss(
                uploadable    =>0),
                insertafter=>'mandator'
        
   );

   $self->AddFields(
      new kernel::Field::SubList(
                name          =>'custcontract',
                label         =>'Customer Contract',
                weblinkto     =>'NONE',
                vjointo       =>'itil::lnkapplcustcontract',
                vjoinon       =>['srcparentid'=>'applid'],
                vjoindisp     =>['custcontract','custcontractcistatus'],
                vjoinbase     =>[{custcontractcistatusid=>'<=4'}],
                vjoininhash   =>['custcontract','custcontractid']),
                insertafter=>'name'
   );


   $self->AddFields(
      new kernel::Field::Select(
                name          =>'applmodules',
                label         =>'Application specific Modules',
                group         =>'advdef',
                vjoinconcat   =>",\n",
                multisize     =>'5',
                #value         =>$self->{allModules},
                getPostibleValues=>sub{
                   $self=shift;
                   return($self->getParent->getAllPosibleApplModules());
                },
                searchable    =>0,
                onRawValue    =>\&itil::appldoc::handleRawValueAutogenField,
                container     =>"additional"),

      new kernel::Field::Text(
                name          =>'contractmodules',
                label         =>'contract wide modules',
                group         =>'default',
                depend        =>'custcontract',
                htmldetail    =>0,
                readonly      =>1,
                searchable    =>0,
                onRawValue    =>\&itil::appldoc::handleRawValueAutogenField,
                container     =>"additional"),

      new kernel::Field::Select(
                name          =>'modules',
                label         =>'effectiv aktive modules',
                group         =>'default',
                vjoinconcat   =>",\n",
                getPostibleValues=>sub{
                   $self=shift;
                   return($self->getParent->getAllPosibleApplModules());
                },
                depend        =>['contractmodules','applmodules'],
                readonly      =>1,
                searchable    =>0,
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;

                   my $p=$self->getParent();
                   my $afld=$p->getField("applmodules");
                   my $l1=$afld->RawValue($current);
                   $l1=[split(/[;,]\s*/,$l1)] if (ref($l1) ne "ARRAY");
                   my $afld=$p->getField("contractmodules");
                   my $l2=$afld->RawValue($current);
                   $l2=[split(/[;,]\s*/,$l2)] if (ref($l2) ne "ARRAY");
                   my @modules=(@$l1,@$l2);
                   return(\@modules);
                }),

      new kernel::Field::Dynamic(
                name          =>'modulematrix',
                label         =>'Module Matrix',
                depend        =>['modules'],
                group         =>'advdef',
                searchable    =>0,
                fields        =>\&addModuleMatrix),

      new kernel::Field::Select(
                name          =>'normodelbycustomer',
                label         =>'customer NOR Model definiton wish',
                group         =>'nordef',
                allowempty    =>1,
                vjointo       =>'itil::itnormodel',
                vjoinon       =>['normodelbycustomerid'=>'id'],
                vjoindisp     =>'name',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                searchable    =>0),

      new kernel::Field::Link(
                name          =>'normodelbycustomerid',
                label         =>'customer NOR Model definiton wish ID',
                group         =>'nordef',
                searchable    =>0,
                onRawValue    =>\&itil::appldoc::handleRawValueAutogenField,
                container     =>"additional"),

      new kernel::Field::Select(
                name          =>'itnormodel',
                label         =>'NOR Model to use',
                group         =>'nordef',
                searchable    =>0,
                vjoinon       =>['itnormodelid'=>'id'],
                vjointo       =>'itil::itnormodel',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'itnormodelid',
                label         =>'NOR Model to use ID',
                group         =>'nordef',
                searchable    =>0,
                dataobjattr   =>"appladv.itnormodel"),

      new kernel::Field::Boolean(
                name          =>'processingpersdata',
                label         =>'processing of person related data',
                group         =>'nordef',
                searchable    =>0,
                useNullEmpty  =>1,
                onRawValue    =>\&itil::appldoc::handleRawValueAutogenField,
                container     =>"additional"),

      new kernel::Field::Boolean(
                name          =>'processingtkgdata',
                label         =>'processing of inventory or traffic data (TKG)',
                group         =>'nordef',
                searchable    =>0,
                useNullEmpty  =>1,
                onRawValue    =>\&itil::appldoc::handleRawValueAutogenField,
                container     =>"additional"),


      new kernel::Field::Boolean(
                name          =>'scddata',
                label         =>'processing of Sensitive Customer Data (SCD)',
                group         =>'nordef',
                useNullEmpty  =>1,
                searchable    =>0,
                onRawValue    =>\&itil::appldoc::handleRawValueAutogenField,
                container     =>"additional"),
   );


   foreach my $module (@{$self->{allModules}}){
      $self->AddGroup($module,translation=>'itil::ext::custcontractmod');
      $self->AddFields(
         new kernel::Field::Text(
                   name          =>$module."CountryRest",  # ISO 3166 k�rzel
                   label         =>"Country restriction",
                   group         =>$module,
                   extLabelPostfix=>": ".$module,
                   searchable    =>0,
                   onRawValue    =>\&itil::appldoc::handleRawValueAutogenField,
                   container     =>"additional"),
      );
   }



   return($self);
}

sub addModuleMatrix
{
   my $self=shift;
   my %param=@_;
   my @dyn=();
   my $p=$self->getParent();
   my $current=$param{current};
   return() if (!defined($current) || $current->{srcparentid} eq "");

   my $mfld=$p->getField("modules");
   my $curmod=$mfld->RawValue($current);
   
   my @modlist=$p->getAllPosibleApplModules();
   while (my $mod=shift(@modlist)){
      my $modname=shift(@modlist);
      my $st=0;
      if (in_array($mod,$curmod)){
         $st=1;
      }
      push(@dyn,$p->InitFields(
           new kernel::Field::Boolean(
              name       =>"MOD".$mod,
              label      =>$mod,
              align      =>'center',
              group      =>$self->{group},
              htmldetail =>0,
              readonly   =>1,
              onRawValue =>sub {
                               return("$st");
                            },
              ),
          ));
   }
   

   return(@dyn);
}



sub getAllPosibleApplModules
{
   my $self=shift;

   my $o=getModuleObject($self->Config,"finance::custcontractmod");

   my @l=$o->getPosibleModuleValues();
   my @d;
   foreach my $l (@l){
      push(@d,$l->{rawname},$l->{name});
   }
   return(@d);
}



sub autoFillAutogenField
{
   my $self=shift;
   my $fld=shift;
   my $current=shift;

   if ($fld->{name} eq "normodelbycustomer"){
      return("S");
   }
   if ($fld->{name} eq "processingpersdata"){
      return("1");
   }
   if ($fld->{name} eq "processingtkgdata"){
      return("0");
   }
   if ($fld->{name} eq "processingscddata"){
      return("0");
   }
   if ($fld->{name} eq "applmodules"){
      return(["MAppl","MSystemOS","MHardwareOS"]);
   }
   if ($fld->{name} eq "contractmodules"){
      my @modules;
      my $f=$self->getField("custcontract");
      my $d=$f->RawValue($current);

      my @contractid=();
      foreach my $crec (@{$d}){
         push(@contractid,$crec->{custcontractid});
      }
      
      my $o=getModuleObject($self->Config,
                            "finance::custcontract");
      $o->SetFilter({id=>\@contractid});
      foreach my $crec ($o->getHashList("modules")){
         foreach my $rawrec (@{$crec->{modules}}){
            push(@modules,$rawrec->{rawname});
         }
      }
      return(\@modules);
   }
   return($self->SUPER::autoFillAutogenField($fld,$current));
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $c=getModuleObject($self->Config,"base::isocountry");
   foreach my $k (keys(%$newrec)){
      if (defined($newrec->{$k}) &&
          ($k=~m/^.*CountryRest$/)){
         $newrec->{$k}=uc($newrec->{$k}); 
         my @l=split(/[,;\s]\s*/,$newrec->{$k});
         foreach my $lid (@l){
            if (!($c->getCountryEntryByToken(1,$lid))){
               $self->LastMsg(ERROR,"invalid country code");
               return(0);
            }
         }
         $newrec->{$k}=join(", ",sort(@l));
      }
   }

   return($self->SUPER::Validate($oldrec,$newrec,$origrec));
}




sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my @l=$self->SUPER::isViewValid($rec);

   if ($rec->{dstate}>=10){
      my @modules=($rec->{modules});
      @modules=@{$modules[0]} if (ref($modules[0]) eq "ARRAY");
      
      push(@l,"nordef","advdef",@modules);
   }
   return(@l);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   if ($rec->{dstate}<30){
      my @l;
      my @modules=($rec->{modules});
      @modules=@{$modules[0]} if (ref($modules[0]) eq "ARRAY");
      push(@l,"nordef","advdef",@modules);

      my $userid=$self->getCurrentUserId();
      return(@l) if ($rec->{databossid} eq $userid ||
                     $rec->{sem2id} eq $userid ||
                     $self->IsMemberOf("admin"));
      if ($rec->{responseteamid} ne ""){
         return(@l) if ($self->IsMemberOf($rec->{responseteamid}));
      }
   }
   return();
}



sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default advdef nordef),@{$self->{allModules}},qw(source qc));
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/appladv.jpg?".$cgi->query_string());
}

sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("itil::appladv");
}














1;
