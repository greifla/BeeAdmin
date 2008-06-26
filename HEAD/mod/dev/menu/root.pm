package dev::menu::root;
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
use Data::Dumper;
use kernel;
use kernel::MenuRegistry;
@ISA=qw(kernel::MenuRegistry);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub Init
{
   my $self=shift;

   $self->RegisterObj("Tools.dev",
                      "tmpl/welcome",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("Tools.dev.sqlparser",
                      "http://www.orafaq.com/cgi-bin/sqlformat/pp/utilities/sqlformatter.tpl",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("Tools.dev.io",
                      "base::interface",
                      func=>'io',
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.dev.color",
                      "tmpl/ColorTool",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("Tools.dev.yui",
                      "../../../static/yui/index.html",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("Tools.dev.tinymce",
                      "../../../static/tinymce/docs/installing.html",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("Tools.dev.firebug",
                      "http://www.getfirebug.com/docs.html",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("Tools.dev.selfhtml",
                      "http://de.selfhtml.org/",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("Tools.dev.cssforyou",
                      "http://www.css4you.de/",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("Tools.dev.env",
                      "base::env",
                      defaultacl=>['admin']);

   $self->RegisterObj("Tools.dev.tztest",
                      "base::tztest",
                      defaultacl=>['admin']);

   $self->RegisterObj("Tools.dev.texttranslation",
                      "base::TextTranslation",
                      defaultacl=>['valid_user']);
   
   return($self);
}



1;
