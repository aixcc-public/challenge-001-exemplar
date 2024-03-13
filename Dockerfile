# This Dockerfile will build an image that, when run, will execute
# the exemplar test harness with data provided by the data files.
#
# The base docker image is pre-built during the competition to 
# support the pseudo-offline competition environment, as well 
# as reducing time spent on dependency installations.
#
# The location of the base docker image can be found in the CP's
# project.yaml, as well as the run script.
#
# Competitors are free to modify the docker image as desired;
# additions appended to this file can be manually built by running
#
#       docker build . -t cp-sandbox
#
# Additionally, the run.sh 'build' command will use the modified 
# Dockerfile for building, running, and testing.

###########################################
FROM ubuntu:22.04 as exemplar-cp-linux-base

# $BINS = directory to store build and run scripts
# $SRC  = directory to store source code
# $OUT  = directory to store build artifacts (harnesses, test binaries)
# $WORK = directory to store intermediate files
ENV BINS=/usr/local/sbin/   
ENV SRC=/src/
ENV OUT=/out/
ENV WORK=/work/

# Install necessary dependencies for the image
COPY exemplar_only/setup.sh $BINS/setup.sh
RUN $BINS/setup.sh

# Create directories
RUN mkdir $OUT
RUN mkdir $WORK
RUN mkdir $SRC

# Copy other internal files that will be used inside the image
COPY build.sh $BINS/build.sh
COPY exemplar_only/run_internal.sh $BINS/run_internal.sh
COPY exemplar_only/test_blob.py $BINS/test_blob.py

################################################
FROM exemplar-cp-linux:base as exemplar-cp-linux

# Competitors can add changes to default docker image here
