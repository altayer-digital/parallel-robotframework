## Details:


The python parallel executor was created from forking TestDoc module of robotframework. Previously robotframework didn’t has the capability of executing test parallel at testcase level. We used TestDoc module to create a wrapper for parallel execution which is shared in the test, as well.

Details can be find: https://github.com/robotframework/robotframework/blob/master/doc/userguide/src/SupportingTools/Testdoc.rst

Lastly for the docker based serialized execution of the test you can find more details here: https://github.com/altayer-digital/Robotframework-Docker

## Installation

Build Docker

```
docker build -t web-automation-docker .
```

## Running Tests

To run execute `./runners/run_tests.sh`

Customize `run_tests.sh` for your own need

```
docker run --rm \
           -e USERNAME="Hammad Ahmed" \
           --net=host \
           -e ROBOT_TESTS=./suite   \
           -e ROBOT_LOGS=Result_Folder_Name   \
           -e ROBOT_TEST=Test_Name \
           -e WEBSITE=Website_Name   \
           -e LANGUAGE=Language   \
           -e REMOTE_DESIRED=True_or_False   \
           -e PABOT_PROC=Number_of_Process      \
           -e ROBOT_ITAG=Tags_to_Execute   \
           -e ROBOT_RUN=Number_of_Retries
           -v "$PWD/execution/scripts":/execution/scripts \
           -v "$PWD/results":/results \
           -v "$PWD/":/suite \
           --security-opt seccomp:unconfined \
           --shm-size "256M" \
           web-automation-docker
```

## Parallel Tests

Pre-requiste:

For Mac:

Install Python:

```
brew install python
```

Install Requirements:

```bash
pip install -r requirements.txt
```
Example: 

```bash
 ./runners/parallel_run.sh
```

Explanation Below:

```bash
python ./execution/parallel_wrapper/executor.py  \
    --include TAGS_TO_INCLUDE \
    --exclude TAGS_TO_EXCLUDE \
    --test TEST_NAME \
    --suite SUITE_NAME \
    DIRECTORY_PATH \
    LOG_PATH \
    WEBSITE_NAME   \
    LANGUAGE   \
    REMOTE_DESIRED   \
    NUMBER_OF_RETRIES  \
    TAG_TO_BE_CRITICAL \
    TIME_OUT_RATIO \
    BATCH_OF_TEST \
    DOCKER_NAME
```


## Tag List

When using tags on the projects you can select tags from below.

Search
Smoke
