
# AIxCC Linux Kernel CP Exemplar Release 01

This Challenge Project Exemplar release aims to provide competitors with a Challenge Project that resembles the same structure and interface that will exist for all Challenge Projects during the competition.

This exemplar has been developed and tested with the following versions:
* Ubuntu 22.04.04 LTS
* Docker version 26.0.0

Note: The contents herein are subject to change, please pull and keep an eye out for future updates!

## What's in the release: 

`src/` - this is the source code for the challenge project, linux kernel 6.1.54 with the following modification:

1. CVE-2021-43267 reintroduced via changes to `net/tipc/crypto.c`
2. Added kunit tests for vulnerable function via changes to `net/tipc/crypto.c`, `net/tipc/tipc_test.c` 
3. Added an AIxCC specific harness in `test_harnesses/` folder.
4. Generated git history with commits that include the vulnerability, and benign commits

`run.sh` - a script that provides a CRS with a standardized interface to interact with the challenge project.

`build.sh` - a script that defines the build process for the challenge project.

`project.yaml` - a yaml document detailing many important aspects of the challenge project.

`exemplar_only/` - this folder contains supplementary information that is only provided with the exemplar release, this information should not be expected to be given during the competition.

1. `blobs/` - this folder contains a file called `sample_solve.bin` which when passed to the test harness should trigger the injected vulnerability.
2. `patches/` - this is folder that contains two example patches. 
    * `good_patch.diff` - removes the vulnerability and maintains functionality. 
    * `bad_patch.diff` - removes the vulnerability but does not maintain functionality. 
3. `gen_blob.py` - this is a helper script for users to generate binary blobs for the test harness provided.
4. _At time of competition, the following three items will be stored within a pre-built docker image that will be provided for each challenge project._
    * `run_internal.sh` - this is a script that runs within the docker environment to handle requests.
    * `setup.sh` - this is a dependency install script for building the docker image.
    * `test_blob.py` - this is a script to test received data blobs against target harnesses.

## Setup the Repository

To test the exemplar, first build the base docker image by running the following.

```bash
docker build . -t exemplar-cp-linux:base --target=exemplar-cp-linux-base
```

Once built, basic interactions with the container can be achieved via the `run.sh` script.

## Run Command Details

The `run.sh` script provides a standardized interface that will be consistent across all competition CPs.
Before building the software, you must pull the source from its source repository:

```bash
./run.sh pull_source
```

This command overwrites anything currently in the `src/` folder, allowing for fresh copies of the source code to be loaded.

### **Building**

```bash
./run.sh build [patch file]
```

The `build` command builds the challenge project with an optional generated patch file. 
The source code is built via the docker volume mounted to the `src/` folder. 
The test harness binaries are built and stored in the `out/` folder. And can be used for analysis. 

_**NOTE: the `build` command will build the current working state of `src/`, as well as any modifications to the Dockerfile. If you want to test a patch, it is advised you create a clean copy of the state with the `pull_source` command and a clean Dockerfile.**_

### **Running PoV**

```bash
./run.sh run_pov <blob_file> <harness_id>
``` 

The `run_pov` command runs the provided binary data blob file against the specified harness id.
Valid harness IDs are listed in the `project.yaml` file.

### **Running Tests**

```bash
./run.sh run_tests
```

The `run_tests` command runs the functionality tests within the challenge project.
As of now, the `run_tests` command will preserve the original state of the `src/` directory.

## Example Use-Cases

Let's say you want to pull the source code, build it as-is, and analyze the linux test binary and harness binary that results.

```bash
./run.sh pull_source
./run.sh build
file out/linux_test_harness
file src/arch/x86/boot/bzImage
```

You then run a data blob against the test harness to check sanitizer triggers. To test your own input data, replace the exemplar\_only binary with your own file.

```bash
./run.sh run_pov exemplar_only/blobs/sample_solve.bin linux_test_harness | grep -i 'pov\|trigger'
```

After verifying sanitizer triggers, you modify the source code directly via the `src/` directory, attempting to patch the vuln.

```bash
sed -i '2310,2312d' src/net/tipc/crypto.c
./run.sh build
./run.sh run_pov exemplar_only/blobs/sample_solve.bin linux_test_harness | grep -i 'pov\|trigger'
./run.sh run_tests
```

You find you removed the sanitizer trigger, but you failed the functionality tests. You create a better solution and generate a patch file. You pull a clean copy of the source to properly test the patch against the original source, and re-run the pov and functional tests. To test your own patches, replace the exemplar\_only patch with your own file.

```bash
./run.sh pull_source
./run.sh build exemplar_only/patches/good_patch.diff
./run.sh run_pov exemplar_only/blobs/sample_solve.bin linux_test_harness | grep -i 'pov\|trigger'
./run.sh run_tests
```

You have now generated a data blob that triggers a sanitizer when passed to the `linux_test_harness` harness, as well 
as a patch that remediates that vulnerability while passing functionality tests.

