# SPDX-License-Identifier: GPL-2.0-only

package Zimbra::DB::DB;

use strict;

#############

my $MYSQL = "mysql";
my $DB_USER = "zimbra";
my $DB_PASSWORD = "zimbra";
my $database = "zimbra";
my $ZMLOCALCONFIG = "/opt/zimbra/bin/zmlocalconfig";

if ($^O !~ /MSWin/i) {
    $DB_PASSWORD = `$ZMLOCALCONFIG -s -m nokey zimbra_mysql_password`;
    chomp $DB_PASSWORD;
    $DB_USER = `$ZMLOCALCONFIG -m nokey zimbra_mysql_user`;
    chomp $DB_USER;
    $MYSQL = "/opt/zimbra/bin/mysql";
}

sub getDatabase() {
    return $database;
}

sub setDatabase($) {
    $database = shift();
}

sub getMailboxIds() {
    return runSql("SELECT id FROM mailbox ORDER BY id");
}

sub runSql(@) {
    my ($script, $logSql) = @_;

    if (! defined($logSql)) {
	$logSql = 1;
    }

    # Write the last script to a text file for debugging
    # open(LASTSCRIPT, ">lastScript.sql") || die "Could not open lastScript.sql";
    # print(LASTSCRIPT $script);
    # close(LASTSCRIPT);

    if ($logSql) {
	Zimbra::DB::DB::log($script);
    }

    # Run the mysql command and redirect output to a temp file
    my $tempFile = "/tmp/mysql.out.$$";
    my $command = "$MYSQL --user=$DB_USER --password=$DB_PASSWORD " .
        "--database=$database --batch --skip-column-names";
    open(MYSQL, "| $command > $tempFile") || die "Unable to run $command";
    print(MYSQL $script);
    close(MYSQL);

    if ($? != 0) {
        die "Error while running '$command'.";
    }

    # Process output
    open(OUTPUT, $tempFile) || die "Could not open $tempFile";
    my @output;
    while (<OUTPUT>) {
        s/\s+$//;
        push(@output, $_);
    }

    unlink($tempFile);
    return @output;
}

sub log
{
    print scalar(localtime()), ": ", @_, "\n";
}

1;
