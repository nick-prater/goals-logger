package NPB::Log;

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
