#!/usr/bin/perl

use strict;
use warnings;

print "GUEST HOOK: " . join(' ', @ARGV). "\n";

# First argument is the vmid
my $vmid = shift;

# Second argument is the phase
my $phase = shift;

if ($phase eq 'post-start') {

    # Second phase 'post-start' will be executed after the guest
    # successfully started.

    print "$vmid started successfully.\n";

    my $bash_script = '/mnt/pve/chimera/snippets/hook_script_server.sh';

    system("bash $bash_script");

} else {
    die "got unknown phase '$phase'\n";
}

exit(0);