#line 1 "sub main::SNMPload_1_0_healthy"
package main; sub SNMPload_1_0_healthy {
    return (&StatusASSP() !~ /not healthy/io);
}
