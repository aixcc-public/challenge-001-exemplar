#!/usr/bin/env python3

import datetime
import getopt
import json
import os
import shutil
import subprocess
import sys
import time
import traceback

from time import sleep

KERNEL_PATH="/src/arch/x86/boot/bzImage"
SANITIZER="KASAN"
TRIGGER="KASAN: slab-out-of-bounds"
VIRTME_MODS="/src/.virtme_mods"

def displayHelp():
    print('test_blob.py --blob_bin <blob_bin> --harness_id <harness_id>')

# Beginning of main
def main(argv):

    d = datetime.datetime.now().strftime("%Y-%m-%d_%H:%M:%S")
    print("Start of test: {}".format(d))

    blob_bin = None
    harness_id = None
    try:
        opts, args = getopt.getopt(argv, "h:", ["blob_bin=", "harness_id="])
    except getopt.GetoptError:
        print('ERROR: parseOptions failed.')
        displayHelp()
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            displayHelp()
            sys.exit()
        elif opt in ("--blob_bin"):
            blob_bin = arg
        elif opt in ("--harness_id"):
            harness_id = arg

    if blob_bin is None:
        print('ERROR: no blob binary.')
        displayHelp()
        sys.exit(2)

    if not (os.path.isfile(blob_bin) and os.access(blob_bin, os.R_OK)):
        print('ERROR: binary blob file does not exist or is not readable.')
        displayHelp()
        sys.exit(2)

    if harness_id is None:
        print('ERROR: no harness identifier.')
        displayHelp()
        sys.exit(2)

    if not (os.path.isfile(harness_id) and os.access(harness_id, os.R_OK)):
        print('ERROR: harness with supplied id does not exist or is not readable.')
        displayHelp()
        sys.exit(2)
    
    vulnBinaryFN=harness_id
    testVulnArgs=blob_bin
    kernelFN=KERNEL_PATH

    # Delete any pre-existing vulnerability script file
    vulnFN=vulnBinaryFN+".sh"
    if os.path.isfile(vulnFN):
        os.remove(vulnFN)

    # Create the vulnerability script file that calls the vulnBinaryFN with testVulnArgs
    try:
        vulnFile = open(vulnFN, 'w')
        vulnFile.write("#!/bin/bash\n")
        vulnFile.write(vulnBinaryFN+" "+testVulnArgs+"\n")
        vulnFile.close()
        os.chmod(vulnFN, 0o550)
    except Exception:
        print("Exception:\n %s", traceback.format_exc())
        print("ERROR: failed to write vulnerability script file '{}'.".format(vulnFN))
        sys.exit(2)


    print("virtme-run --verbose --show-boot-console --kimg {} --memory 2G --mods=auto --script-sh {} >> stdoutData 2> stderrData".format(kernelFN, vulnFN))

    stdoutData = ""
    stderrData = ""
    try:
        result = subprocess.run(['virtme-run', '--verbose', '--show-boot-console', '--kimg', kernelFN, "--memory", "2G", "--mods=auto", "--script-sh", vulnFN],
                                capture_output = True, timeout=240)
        # Get the stdout data as a string
        stdoutData = result.stdout.decode("utf-8")
        # Get the stderr data as a string
        stderrData = result.stderr.decode("utf-8")

        if os.path.isfile(vulnFN):
            os.remove(vulnFN)
        if os.path.isdir(VIRTME_MODS):
            shutil.rmtree(VIRTME_MODS)

    except subprocess.TimeoutExpired as timeErr:
        print("WARNING: Timeout in virtme-run")
        os.system('killall /usr/bin/qemu-system-x86_64')

        # Try to get the stdout and stderr data as a string
        if timeErr.stdout is not None:
            stdoutData = timeErr.stdout.decode("utf-8")
        if timeErr.stderr is not None:
            stderrData = timeErr.stderr.decode("utf-8")

        if os.path.isfile(vulnFN):
            os.remove(vulnFN)
        if os.path.isdir(VIRTME_MODS):
            shutil.rmtree(VIRTME_MODS)

    except Exception:
        print("Unexpected Exception:\n %s", traceback.format_exc())

        if os.path.isfile(vulnFN):
            os.remove(vulnFN)
        if os.path.isdir(VIRTME_MODS):
            shutil.rmtree(VIRTME_MODS)

        sys.exit(2)

    logTestData = True
    success_status = 0

    if TRIGGER in stderrData:
        print("TRIGGERED: Sanitizer triggered: {}".format(TRIGGER))
    elif "KASAN" in stderrData:
        print("WARNING: Exemplar vuln triggered {} unexpectedly.".format("KASAN"))
    elif "KFENCE" in stderrData:
        print("WARNING: Exemplar vuln triggered {} unexpectedly.".format("KFENCE"))
    elif "UBSAN" in stderrData:
        print("WARNING: Exemplar vuln triggered {} unexpectedly.".format("UBSAN"))
    else:
        print("NO TRIGGER: No sanitizer was triggered with {}".format(vulnBinaryFN))
        
    if logTestData:
        print("===== VM stdout data begin =====")
        print(stdoutData)
        print("===== VM stderr data begin =====")
        print(stderrData)
        print("===== VM output data end =====")

    d = datetime.datetime.now().strftime("%Y-%m-%d_%H:%M:%S")
    print("Test complete: {}".format(d))

    return success_status

if __name__ == "__main__":

    exit_status=0

    try:
        exit_status = main(sys.argv[1:])
    except Exception:
        print("Unexpected Exception:\n %s", traceback.format_exc())
        os.system('killall /usr/bin/qemu-system-x86_64')
        exit_status=2

    sys.exit(exit_status)
 
