package article::product;
#  W5Base Framework
#  Copyright (C) 2013  Hartmut Vogler (it@guru.de)
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
                htmlwidth     =>'10px',
                label         =>'No.'),


      new kernel::Field::Id(
                name          =>'id',
                label         =>'W5BaseID',
                sqlorder      =>'none',
                group         =>'source',
                dataobjattr   =>'artproduct.id'),

      new article::product::Field::Text(
                name          =>'fullname',
                label         =>'full Productname',
                htmldetail    =>0,
                readonly      =>1,
                multilang     =>1,
                dataobjattr   =>'artproduct.frontlabel'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Productname',
                htmldetail    =>0,
                readonly      =>1,
                multilang     =>1,
                dataobjattr   =>'artproduct.frontlabel'),

      new kernel::Field::Textarea(
                name          =>'frontlabel',
                label         =>'Product label',
                htmlheight    =>50,
                dataobjattr   =>'artproduct.frontlabel'),

      new kernel::Field::Select(
                name          =>'pclass',
                label         =>'Product class',
                selectfix     =>1,
                readonly      =>sub{
                   my $self=shift;
                   my $current=shift;
                   return(1) if (defined($current));
                   return(0);
                },
                htmleditwidth =>'100px',
                value         =>['simple','bundle'],
                dataobjattr   =>'artproduct.pclass'),

      new kernel::Field::Text(
                name          =>'pvariant',
                label         =>'Product variant',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current})){
                      return(1);
                   }
                   return(0);
                },
                readonly      =>sub{
                   my $self=shift;
                   my $current=shift;
                   return(1) if (defined($current) && 
                                 $current->{pvariant} eq "standard");
                   return(0);
                },
                selectfix     =>1,
                dataobjattr   =>'artproduct.variant'),

      new kernel::Field::TextDrop(
                name          =>'variantof',
                label         =>'variant of',
                depend        =>['variantofid'],
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current})){
                      return(1) if ($param{current}->{variantofid} ne "");
                   }
                   return(0);
                },
                vjointo       =>'article::product',
                vjoinon       =>['variantofid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Interface(
                name          =>'variantofid',
                label         =>'VariantOf-Id',
                dataobjattr   =>'artproduct.variantof'),

      new kernel::Field::TextDrop(
                name          =>'catalog',
                label         =>'Catalog',
                readonly      =>1,
                vjointo       =>'article::catalog',
                vjoinon       =>['catalogid'=>'id'],
                vjoineditbase =>{cistatusid=>"<=5"},
                vjoindisp     =>'fullname'),


      new kernel::Field::Select(
                name          =>'category1',
                label         =>'Category',
                vjointo       =>'article::category',
                vjoinon       =>['category1id'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'category1id',
                label         =>'CategoryID',
                dataobjattr   =>'artproduct.artcategory1'),

      new kernel::Field::Number(
                name          =>'posno1',
                label         =>'Position Number',
                width         =>'1%',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current})){
                      return(0) if ($param{current}->{variantofid} ne "");
                   }
                   return(1);
                },
                searchable    =>0,
                htmleditwidth =>'40px',
                precision     =>0,
                dataobjattr   =>'artproduct.posno1'),

      new kernel::Field::Textarea(
                name          =>'description',
                label         =>'Description',
                dataobjattr   =>'artproduct.description'),

      new kernel::Field::Textarea(
                name          =>'variantdescription',
                group         =>'variantspecials',
                label         =>'variant specials',
                dataobjattr   =>'artproduct.variantdesc'),

      new kernel::Field::Contact(
                name          =>'productmgr',
                vjoineditbase =>{'cistatusid'=>[3,4,5],
                                 'usertyp'=>[qw(extern user)]},
                AllowEmpty    =>1,
                group         =>'mgmt',
                label         =>'Product Manager',
                vjoinon       =>'productmgrid'),

      new kernel::Field::Link(
                name          =>'productmgrid',
                group         =>'mgmt',
                dataobjattr   =>'artproduct.productmgr'),

      new kernel::Field::Date(
                name          =>'orderable_from',
                group         =>'mgmt',
                label         =>'orderable from',
                dataobjattr   =>'artproduct.orderable_from'),

      new kernel::Field::Date(
                name          =>'orderable_to',
                label         =>'orderable to',
                group         =>'mgmt',
                dataobjattr   =>'artproduct.orderable_to'),

      new kernel::Field::File(
                name          =>'logo_small',
                label         =>'logo_small',
                searchable    =>0,
                group         =>'mgmtlogosmall',
                uploadable    =>0,
                dataobjattr   =>'artproduct.logo_small'),

      new kernel::Field::File(
                name          =>'logo_large',
                label         =>'logo_large',
                searchable    =>0,
                group         =>'mgmtlogolarge',
                uploadable    =>0,
                dataobjattr   =>'artproduct.logo_large'),

      new kernel::Field::Number(
                name          =>'costonce',
                label         =>'cost once',
                precision     =>2,
                width         =>'50',
                group         =>'cost',
                dataobjattr   =>'artproduct.cost_once'),

      new kernel::Field::Number(
                name          =>'costday',
                label         =>'cost day',
                precision     =>2,
                width         =>'50',
                group         =>'cost',
                dataobjattr   =>'artproduct.cost_day'),

      new kernel::Field::Number(
                name          =>'costmonth',
                label         =>'cost month',
                precision     =>2,
                width         =>'50',
                group         =>'cost',
                dataobjattr   =>'artproduct.cost_month'),

      new kernel::Field::Number(
                name          =>'costyear',
                precision     =>2,
                width         =>'50',
                label         =>'cost year',
                group         =>'cost',
                dataobjattr   =>'artproduct.cost_year'),

      new kernel::Field::Number(
                name          =>'costperuse',
                label         =>'cost peruse',
                precision     =>2,
                width         =>'50',
                group         =>'cost',
                dataobjattr   =>'artproduct.cost_peruse'),

      new kernel::Field::Text(
                name          =>'produnit',
                label         =>'product unit',
                group         =>'cost',
                dataobjattr   =>'artproduct.produnit'),

      new kernel::Field::Select(
                name          =>'billinterval',
                label         =>'bill interval',
                value         =>['PERMONTH','PERYEAR'],
                group         =>'cost',
                dataobjattr   =>'artproduct.billinterval'),
        
      new kernel::Field::Link(
                name          =>'subparentid',
                label         =>'id for all sub elements/products',
                readonly      =>1,
                dataobjattr   =>'if (artproduct.variantof is null,'.
                                'artproduct.id,artproduct.variantof)'),

      new kernel::Field::SubList(
                name          =>'directproductelements',
                label         =>'direct Productelements',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current})){
                      return(1) if ($param{current}->{pclass} eq "simple");
                   }
                   return(0);
                },
                group         =>'productelements',
                vjointo       =>'article::lnkelementprod',
                vjoinon       =>['subparentid'=>'productid'],
                vjoindisp     =>['delivelement']),

      new kernel::Field::SubList(
                name          =>'allproductelements',
                label         =>'all Productelements',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current})){
                      return(1) if ($param{current}->{pclass} eq "bundle");
                   }
                   return(0);
                },
                group         =>'productelements',
                vjointo       =>'article::lnkelement',
                vjoinon       =>['subparentid'=>'productid'],
                vjoindisp     =>['delivelement']),

      new kernel::Field::SubList(
                name          =>'subproducts',
                label         =>'Subproducts',
                group         =>'subproducts',
                vjointo       =>'article::lnkprodprod',
                vjoinon       =>['subparentid'=>'pproductid'],
                vjoindisp     =>['product']),

      new kernel::Field::SubList(
                name          =>'variants',
                label         =>'Variants',
                group         =>'variants',
                vjointo       =>'article::product',
                vjoinon       =>['id'=>'variantofid'],
                vjoindisp     =>['fullname']),

      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'mgmt',
                label         =>'Comments',
                dataobjattr   =>'artproduct.comments'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'artproduct.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'artproduct.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'artproduct.createdate'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'artproduct.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'artproduct.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'artproduct.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'artproduct.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'artproduct.realeditor'),

      new kernel::Field::Link(
                name          =>'sectarget',
                noselect      =>'1',
                dataobjattr   =>'lnkcontact.target'),

      new kernel::Field::Link(
                name          =>'sectargetid',
                noselect      =>'1',
                dataobjattr   =>'lnkcontact.targetid'),

      new kernel::Field::Link(
                name          =>'secroles',
                noselect      =>'1',
                dataobjattr   =>'lnkcontact.croles'),

      new kernel::Field::Link(
                name          =>'databossid',
                noselect      =>'1',
                dataobjattr   =>'artcatalog.databoss'),

      new kernel::Field::Link(
                name          =>'mandatorid',
                noselect      =>'1',
                dataobjattr   =>'artcatalog.mandator'),
                                  
      new kernel::Field::Link(
                name          =>'catalogid',
                dataobjattr   =>'artcatalog.id')
                                  
   );
   $self->{history}=[qw(insert modify delete)];
   $self->setDefaultView(qw(category1  
                            fullname description cdate));
   $self->setWorktable("artproduct");
   return($self);
}


sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->IsMemberOf([qw(admin w5base.article.admin)],"RMember")){
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
                          [orgRoles(),qw(RMember RODManager RODManager2 
                                         RODOperator
                                         RAuditor RMonitor)],"both");
      my @grpids=keys(%grps);

      my $userid=$self->getCurrentUserId();
      my @addflt=(
                 {sectargetid=>\$userid,sectarget=>\'base::user',
                  secroles=>"*roles=?write?=roles* *roles=?admin?=roles* ".
                            "*roles=?read?=roles* *roles=?order?=roles*"},
                 {sectargetid=>\@grpids,sectarget=>\'base::grp',
                  secroles=>"*roles=?write?=roles* *roles=?admin?=roles* ".
                            "*roles=?read?=roles* *roles=?order?=roles*"}
                );
      if ($ENV{REMOTE_USER} ne "anonymous"){
         push(@addflt,
            {mandatorid=>\@mandators},
            {databossid=>\$userid}
         );
      }
      push(@flt,\@addflt);
   }
   return($self->SetFilter(@flt));
}



sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/article/load/product.jpg?".$cgi->query_string());
}


sub getSqlFrom
{
   my $self=shift;
   my $from="artproduct ".
      "left outer join artcategory on artproduct.artcategory1=artcategory.id ".
      "left outer join artcatalog on artcategory.artcatalog=artcatalog.id ".
      "left outer join lnkcontact on lnkcontact.parentobj='article::catalog' ".
      "and artcategory.id=lnkcontact.refid";
   return($from);
}





sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","variantspecials",
          "cost","mgmt","variants",
          "subproducts",
          "productelements",
          "mgmtlogosmall","mgmtlogolarge","source");
}

sub isCopyValid
{
   my $self=shift;
   my $rec=shift;
   return(0) if (!defined($rec));
   return(1);
}


sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $bak=$self->SUPER::FinishWrite($oldrec,$newrec);
   if (!$bak){
      my $id=effVal($oldrec,$newrec,"id");
    #  my $p=getModuleObject($self->Config,"article::product");
      my $p=$self;
      $self->ResetFilter();
      $p->SetFilter({variantofid=>\$id});
      my @l=$p->getHashList(qw(ALL));
      if ($#l!=-1){
         $p->ResetFilter();
         foreach my $subrec (@l){
            my $id=$subrec->{id};
            $p->ValidatedUpdateRecordTransactionless(
                   $subrec,{mdate=>NowStamp("en")},{id=>\$id});
         }
         $p->RoolbackTransaction();
      }
   }
   return($bak);
}








sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   if (!defined($oldrec) && $newrec->{pvariant} eq ""){
      $newrec->{pvariant}="standard";
   }
   my $variantofid=effVal($oldrec,$newrec,"variantofid");
   if ($variantofid ne ""){
      if (effVal($oldrec,$newrec,"pvariant") eq "standard"){
         $self->LastMsg(ERROR,"variant standard is not allowed if ".
                              "product is a variant of an other ones");
         return(undef);
      }
      my $p=getModuleObject($self->Config,"article::product");
      $p->SetFilter({id=>\$variantofid});
      my ($prec,$msg)=$p->getOnlyFirst(qw(ALL));
      # Werte die immer vom "Parent" übernommen werden
      foreach my $pfld (qw(category1id frontlabel pclass description)){
         if (!defined($oldrec) ||
             $oldrec->{$pfld} ne $prec->{$pfld}){
            $newrec->{$pfld}=$prec->{$pfld};
         }
      }
      if (!defined($oldrec)){
         # Werte die nur Initial vom Parent übernommen werden
         foreach my $pfld (qw(productmgrid)){
            if (!defined($oldrec) ||
                $oldrec->{$pfld} ne $prec->{$pfld}){
               $newrec->{$pfld}=$prec->{$pfld};
            }
         }
      }
   }
   else{
      if (defined($oldrec->{variantofid})){
         $newrec->{variantofid}=undef;
      }
   }

   my %checkcategories;
   if (!defined($oldrec)){
      if (!defined($newrec->{productmgrid}) ||
          $newrec->{productmgrid} eq ""){
         my $userid=$self->getCurrentUserId();
         $newrec->{productmgrid}=$userid;
      }
      if ($newrec->{category1id} eq ""){
         $self->LastMsg(ERROR,"missing primary category");
         return(0);
      }
      else{
         $checkcategories{$newrec->{category1id}}++;
      }
   }
   my $category1id=effVal($oldrec,$newrec,"category1id");
   $checkcategories{$category1id}++ if ($category1id ne "");

   my $cat=getModuleObject($self->Config,"article::category");
   my $c=getModuleObject($self->Config,"article::catalog");
   my @checkcategories=keys(%checkcategories);
   if ($#checkcategories==-1){
      $self->LastMsg(ERROR,"missing categories");
      return(0);
   }
   my $wrok=$#checkcategories;
   foreach my $categoryid (@checkcategories){
      $cat->ResetFilter();
      $cat->SetFilter({id=>\$categoryid});
      my $catalogid=$cat->getVal("catalogid");
      if ($catalogid ne ""){
         if (!$c->isCatalogWriteValid($catalogid)){
            $wrok--;
         }
      }
   }
   if ($wrok!=0){
      $self->LastMsg(ERROR,"no nesassary write access to category");
      return(0);
   }






   if (exists($newrec->{logo_small})){   # laden des small Logos
      if ($newrec->{logo_small} ne ""){
         no strict;
         my $f=$newrec->{logo_small};
         seek($f,0,SEEK_SET);
         my $pic;
         my $buffer;
         my $size=0;
         while (my $bytesread=read($f,$buffer,1024)) {
            $pic.=$buffer;
            $size+=$bytesread;
            if ($size>100240){
               $self->LastMsg(ERROR,"picure to large");
               return(0);
            }
         }
         $newrec->{logo_small}=$pic;
      }
      else{
         $newrec->{logo_small}=undef;
      }
   }

   if (exists($newrec->{logo_large})){   # laden des small Logos
      if ($newrec->{logo_large} ne ""){
         no strict;
         my $f=$newrec->{logo_large};
         seek($f,0,SEEK_SET);
         my $pic;
         my $buffer;
         my $size=0;
         while (my $bytesread=read($f,$buffer,1024)) {
            $pic.=$buffer;
            $size+=$bytesread;
            if ($size>100240){
               $self->LastMsg(ERROR,"picure to large");
               return(0);
            }
         }
         $newrec->{logo_large}=$pic;
      }
      else{
         $newrec->{logo_large}=undef;
      }
   }


   my $name=effVal($oldrec,$newrec,"frontlabel");
   if ($name=~m/^\s$/){
      $self->LastMsg(ERROR,"invalid name '\%s' specified",
                     $name);
      return(undef);
   }
   return(1);
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default","mgmt") if (!defined($rec));
   my @l=("header","default","history","mgmt",
          "mgmtlogosmall","mgmtlogolarge",
          "cost","productelements","source");
   if ($rec->{pvariant} eq "standard"){
      push(@l,"variants");
   }
   else{
      push(@l,"variantspecials");
   }
   push(@l,"subproducts") if ($rec->{pclass} eq "bundle");
   return(@l);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   return("default") if (!defined($rec));

   my @wrgroups=qw(default mgmt mgmtlogosmall mgmtlogolarge);

   if (defined($rec) && $rec->{variantofid}){
      @wrgroups=grep(!/^default$/,@wrgroups);
   }

   push(@wrgroups,"cost") if (defined($rec));

   if (defined($rec) && $rec->{pvariant} eq "standard"){
      push(@wrgroups,"variants");
   }
   else{
      push(@wrgroups,"variantspecials");
   }
   push(@wrgroups,"subproducts") if ($rec->{pclass} eq "bundle" &&
                                     $rec->{pvariant} eq "standard");
   push(@wrgroups,"productelements") if ($rec->{pclass} eq "simple");

   return(@wrgroups) if (!defined($rec));

   my $catalogid=$rec->{catalogid};
   if ($catalogid ne ""){
      my $c=getModuleObject($self->Config,"article::catalog");
      if ($c->isCatalogWriteValid($catalogid)){
         return(@wrgroups);
      }
   }




   return(undef);
}


package article::product::Field::Text;
use strict;
use vars qw(@ISA);
use kernel;
use kernel::Field;
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);

   return($self);
}

sub getBackendName
{
   my $self=shift;
   my $mode=shift;
   my $db=shift;

   if (($mode=~m/^where/) || $mode eq "select"){
      my $id=$self->getParent->getField("id");
      my $id_attr=$id->getBackendName($mode,$db);
      my $name=$self->getParent->getField("name");
      my $name_attr=$name->getBackendName($mode,$db);
      my $pclass=$self->getParent->getField("pclass");
      my $pclass_attr=$pclass->getBackendName($mode,$db);
      my $pvariant=$self->getParent->getField("pvariant");
      my $pvariant_attr=$pvariant->getBackendName($mode,$db);

      my $f="concat(trim(cast($id_attr as char(20))),\": \"".
            ",$pclass_attr,\" - \",".
            "$name_attr,\": \",$pvariant_attr)";

      return($f);
   }
   return($self->SUPER::getBackendName($mode,$db));
}







1;
