#!/bin/sh

#PLI=+loadvpi=../pli/ide/pli_ide.so:vpi_compat_bootstrap
PLI=+loadvpi=../pli/mmc/pli_mmc.so:vpi_compat_bootstrap

cver $PLI +incdir+../rtl run-disk.v

