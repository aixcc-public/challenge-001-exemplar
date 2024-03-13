#!/bin/bash
# This script allows arguments to be inputed to orchestrate different tasks.
# Run the Proof of Vulnerability (PoV), apply a patch, re-make the kernel, test functionality, re-validate against santizer

CMD_NAME=$1
BLOB_FILE=$2
HARNESS_FILE=$3

run_pov () {
	echo "Running the PoV"
	if /usr/local/sbin/test_blob.py --blob_bin $BLOB_FILE --harness_id $HARNESS_FILE; then
        echo "SUCCESS: POV executed as intended"
        POV_STATUS="SUCCESS"
    else
        echo "FAILURE: POV did not execute as intended"
        POV_STATUS="FAILURE"
    fi
}

test_functionality() {
    echo "Checking patch for functionality"

    # copy to temp location to maintain state in /src volume
    cp -r /src /tmp/src-test
    cd /tmp/src-test
    if make ARCH=um mrproper; ./tools/testing/kunit/kunit.py run tipc-example | grep -q "\[PASSED\]"; then
        echo "SUCCESS: Patched kernel passed functionality tests!"
        FUNC_TEST_STATUS="SUCCESS"
    else
        echo "FAILURE: Patched kernel did not pass functionality tests!"
        FUNC_TEST_STATUS="FAILURE"
    fi
    cd -
}

case ${CMD_NAME,,} in
	"pov")
        if [ -f $BLOB_NAME ]; then
            run_pov
        else
            echo "Invalid input, blob file not found: $BLOB_LOCATION$BLOB_NAME"
        fi
		;;
    "run_tests")
        test_functionality
        ;;
	 *) 
		echo "Invalid input. Usage:"
        echo "    run_internal.sh pov        BINARY_BLOB HARNESS_ID"
        echo "    run_internal.sh run_tests"
		;;
esac


