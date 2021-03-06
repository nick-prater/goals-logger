package NPB::Log;

=head1 AUTHOR

Nick Prater

=head1 LICENCE

This file is part of GOALS-logger, a broadcast audio logging system.

Copyright (C) 2012 NP Broadcast Limited.

GOALS-logger is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

GOALS-logger is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with GOALS-logger.  If not, see <http://www.gnu.org/licenses/>.

=cut


use warnings;
use strict;
use Log::Log4perl;
use Log::Dispatch::File;
use FileHandle;

my $appender;


sub configure_logging {

        my $log_file = shift;
        my $log = Log::Log4perl::get_logger("");
        $log->level($Log::Log4perl::DEBUG);

        $appender = Log::Log4perl::Appender->new(
                "Log::Dispatch::File",
                filename => $log_file,
                mode     => "append",
                name     => "main_log",
        );

        my $log_layout = Log::Log4perl::Layout::PatternLayout->new(
                "%d %m%n"
        );

        $appender->layout($log_layout);
        $log->add_appender($appender);

#        # Redirect STDOUT and STDERR to our log file
#        # This caters for modules that don't use Log4perl
#        open STDOUT, ">>$log_file" or warn  "Couldn't open Log File $log_file: $!";
#        open STDERR, ">>&STDOUT"   or print "Couldn't redirect STDERR: $!\n";
#        STDERR->autoflush;
#        STDOUT->autoflush;

        return $log;
}


1;
