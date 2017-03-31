#!/usr/bin/perl
#  W5Base Framework Main-Programm
#  Copyright (C) 2002-2017  Hartmut Vogler (it@guru.de)
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

my %SHELLENV;
BEGIN{
   %SHELLENV=(%ENV);
}

use strict;
use FindBin ;
use IO::Handle;
use IO::File;
use CGI::Fast(qw(:standard));
eval('use Proc::ProcessTable;');  # try to load Proc::ProcessTabel if exists


*CORE::GLOBAL::die = sub { require Carp; Carp::confess };
if (CGI::Fast->can("file_handles")){
   CGI::Fast->file_handles({
      fcgi_error_file_handle  => new IO::Handle(),
   });
}

$W5V2::INSTDIR="/opt/w5base" if (!defined($W5V2::INSTDIR));

if (defined(&{FindBin::again})){
   FindBin::again();
   $W5V2::INSTDIR="$FindBin::Bin/..";
}
foreach my $path ("$W5V2::INSTDIR/mod","$W5V2::INSTDIR/lib"){
   my $qpath=quotemeta($path);
   unshift(@INC,$path) if (!grep(/^$qpath$/,@INC));
}
do "$W5V2::INSTDIR/lib/kernel/App/Web.pm";
print STDERR ("ERROR: $@\n") if ($@ ne "");

while(my $fastreq=new CGI::Fast()){
   for my $ev (keys(%SHELLENV)){  # Restore Enviroment
       if (($ev=~m/^(CLASSPATH|JAVA_HOME|PATH|LD_LIBRARY_PATH)$/) ||
           ($ev=~m/^PERL/) ||
           ($ev=~m/^W5/) ||
           ($ev=~m/^(ORA|NLS|TNS)/) ||
           ($ev=~m/^DB2/)){
          $ENV{$ev}=$SHELLENV{$ev};
       }
   }
   $W5V2::OperationContext="WebFrontend";
   $W5V2::InvalidateGroupCache=0;
   $W5V2::HistoryComments=undef;
   $W5V2::CurrentFastCGIRequest=$fastreq;
   my ($configname)=$ENV{'SCRIPT_NAME'}=~m#/(.+)/(bin|auth|public|cookie)#;
   kernel::App::Web::RunWebApp($W5V2::INSTDIR,$configname);
   if (defined($Proc::ProcessTable::VERSION)){
      my $pt=new Proc::ProcessTable();
      my %info = map({$_->pid =>$_} @{$pt->table});
      my $rss=$info{$$}->rss;
      if ($rss>250000000){  # 250 MB Resources
         printf STDERR ("cleanup perl process due size limitation %d\n",$rss);
         exit(0);
      }
   }
}
