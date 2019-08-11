#!/bin/bash
# Entry script to start Xvfb and set display
set -e

# Set sensible defaults for env variables that can be overridden while running
# the container
DEFAULT_LOG_LEVEL="DEBUG"
DEFAULT_RES="1680x1050x24"
DEFAULT_DISPLAY=":99"
DEFAULT_ROBOT="robot"

# Use default if none specified as env var
LOG_LEVEL=${LOG_LEVEL:-$DEFAULT_LOG_LEVEL}
RES=${RES:-$DEFAULT_RES}
DISPLAY=${DISPLAY:-$DEFAULT_DISPLAY}
ROBOT_MODE=${ROBOT_MODE:-$DEFAULT_ROBOT}

if [[ -n ${ROBOT_TESTS} ]];
then
  echo -e "\e[35mYour tests are starting with ${ROBOT_TESTS}\e[0m"
else
  echo -e "\e[31mError: Please specify the robot test or directory as env var ROBOT_TESTS\e[0m"
  exit 1
fi

if [[ -n ${ROBOT_LOGS} ]];
then
  echo -e "\e[35mLog will be posted here ${ROBOT_LOGS}\e[0m"
else
  echo -e "\e[31mError: Please specify the robot test or directory as env var ROBOT_LOGS\e[0m"
  exit 1
fi

if [[ -n ${WEBSITE} ]];
then
  REQUIRED_PARAMETERS+="-v WEBSITE:${WEBSITE} "
else
  echo -e "\e[31mError: Please specify the robot test or directory as env var WEBSITE\e[0m"
  exit 1
fi

if [[ -n ${LANGUAGE} ]];
then
  REQUIRED_PARAMETERS+="-v LANGUAGE:${LANGUAGE} "
else
  echo -e "\e[31mError: Please specify the robot test or directory as env var LANGUAGE\e[0m"
  exit 1
fi

# Process optional parameters passed to pybot/pabot
OPTIONAL_PARAMETERS=""

if [[ "${ROBOT_MODE}" == "pabot" ]];
then

    if [[ -n ${PABOT_LIB} ]];
    then
        OPTIONAL_PARAMETERS+="--${PABOT_LIB} "
    fi

    if [[ -n ${PABOT_RES} ]];
    then
        OPTIONAL_PARAMETERS+="--resourcefile ${PABOT_RES} "
    fi

    if [[ -n ${PABOT_PROC} ]];
    then
        OPTIONAL_PARAMETERS+="--processes ${PABOT_PROC} "
    fi

fi

if [[ -n ${ROBOT_VAR} ]];
then
    OPTIONAL_PARAMETERS+="--variablefile ${ROBOT_VAR} "
fi

if [[ -n ${ROBOT_RUN} ]];
then
    RERUN=$((ROBOT_RUN + 1))
else
    RERUN=2
fi


if [[ -n ${ROBOT_ITAG} ]];
then
    OPTIONAL_PARAMETERS+="-i ${ROBOT_ITAG} "
fi

if [[ -n ${ROBOT_NTAG} ]];
then
    OPTIONAL_PARAMETERS+="-n ${ROBOT_NTAG} "
fi

if [[ -n ${ROBOT_CTAG} ]];
then
    OPTIONAL_PARAMETERS+="-c ${ROBOT_CTAG} "
fi

if [[ -n ${ROBOT_ETAG} ]];
then
    OPTIONAL_PARAMETERS+="-e ${ROBOT_ETAG} "
fi

if [[ -n ${ROBOT_TEST} ]];
then
    OPTIONAL_PARAMETERS+="-t ${ROBOT_TEST} "
fi

if [[ -n ${ROBOT_SUITE} ]];
then
    OPTIONAL_PARAMETERS+="-s ${ROBOT_SUITE} "
fi

if [[ -n ${TIMEOUT} ]];
then
    OPTIONAL_PARAMETERS+="-v TIME_OUT:${TIMEOUT} "
fi

if [[ -n ${REMOTE_DESIRED} ]];
then
  OPTIONAL_PARAMETERS+="-v REMOTE_DESIRED:${REMOTE_DESIRED} "
fi

if [[ -n ${REMOTE_URL} ]];
then
  OPTIONAL_PARAMETERS+="-v REMOTE_URL:${REMOTE_URL} "
fi

if [[ -n ${TAG_CRITICAL} ]];
then
  TAG_CRITICAL="--critical"
fi

# Start Xvfb
echo -e "\e[34mStarting Xvfb on display ${DISPLAY} with res ${RES}\e[0m"
Xvfb ${DISPLAY} -ac -screen 0 ${RES} +extension RANDR &
export DISPLAY=${DISPLAY}

export ROBOT_SYSLOG_FILE=${ROBOT_LOGS}/syslog.txt
export ROBOT_SYSLOG_LEVEL=DEBUG

set +e
# Execute tests
if [[ "${ROBOT_MODE}" != "pabot" ]];
then

    echo -e "\e[34m"
    figlet Starting Test
    echo -e "\e[0m"
    echo -e "\e[34mExecuting robot tests at log level ${LOG_LEVEL}, parameters ${OPTIONAL_PARAMETERS}with robot\e[0m"
    echo -e "\e[36;4mCommand:\e[0m\e[36m robot --loglevel ${LOG_LEVEL} ${REQUIRED_PARAMETERS} ${OPTIONAL_PARAMETERS} --outputdir ${ROBOT_LOGS}-1 ${ROBOT_TESTS}\e[0m"
    robot  --loglevel ${LOG_LEVEL} ${REQUIRED_PARAMETERS} ${OPTIONAL_PARAMETERS} --outputdir ${ROBOT_LOGS}-1 ${ROBOT_TESTS}

    status=$?

    for ((value = 2 ; value <= ${RERUN} ; value++));
    do
        echo -e "\e[31m${status} test failed will attempt to re-run the test automatically.\e[0m"
        echo -e "\e[34mRe-running failed tests first attempt\e[0m"
        echo -e "\e[36;4mCommand:\e[0m\e[36m robot --loglevel ${LOG_LEVEL} ${REQUIRED_PARAMETERS} ${OPTIONAL_PARAMETERS} --rerunfailed ${ROBOT_LOGS}-$((value - 1))/output.xml --outputdir ${ROBOT_LOGS}-${value} ${ROBOT_TESTS}\e[0m"
        robot --loglevel ${LOG_LEVEL} ${REQUIRED_PARAMETERS} ${OPTIONAL_PARAMETERS} --rerunfailed ${ROBOT_LOGS}-$((value - 1))/output.xml --outputdir ${ROBOT_LOGS}-${value} ${ROBOT_TESTS}
        status=$?
    done

    if [[ $status -eq 0 ]];
    then
        echo -e "\e[32;5m"
        figlet Test Passed
        echo -e "\e[0m"
    else
        echo -e "\e[31;5m"
        figlet Test Failed
        echo -e "\e[0m"
    fi

    echo -e "\e[34mCombining the results. \e[0m"
    echo -e "\e[36;4mCommand:\e[0m\e[36m rebot --nostatusrc  --output ${ROBOT_LOGS}/output.xml --outputdir ${ROBOT_LOGS}/ --merge  ${ROBOT_LOGS}-*/output.xml\e[0m"
    echo -e "\e[32m"
    figlet -f digital Merging output Files

    yes | cp .${ROBOT_LOGS}-*/*.png .${ROBOT_LOGS}/

    rebot --nostatusrc  --output ./output.xml --outputdir ${ROBOT_LOGS}/ --merge  ${ROBOT_LOGS}-*/output.xml

    echo -e "\e[0m"

    string=${ROBOT_LOGS}
    if [[ $string == *"parallel"* ]]; then
        python ./suite/execution/parallel_wrapper/combine_results.py ${ROBOT_TEST}
    fi

else
    echo -e "\e[34m"
    figlet Starting Test
    echo -e "\e[0m"
    echo -e "\e[34mExecuting robot tests at log level ${LOG_LEVEL}, pabotlib and parameters ${OPTIONAL_PARAMETERS} with pabot\e[0m"
    echo -e "\e[36;4mCommand:\e[0m\e[36m pabot ${OPTIONAL_PARAMETERS}--loglevel ${LOG_LEVEL} --outputdir ${ROBOT_LOGS} ${ROBOT_TESTS}\e[0m"
    pabot ${OPTIONAL_PARAMETERS} ${REQUIRED_PARAMETERS} --loglevel ${LOG_LEVEL} --outputdir ${ROBOT_LOGS}-1 ${ROBOT_TESTS}
    status=$?

    for ((value = 2 ; value <= ${RERUN} ; value++));
    do
        if [[ $status -ne 0 ]];
        then
            echo -e "\e[31m${status} test failed will attempt to re-run the test automatically.\e[0m"
            echo -e "\e[34mRe-running failed tests first attempt\e[0m"
            echo -e "\e[36;4mCommand:\e[0m\e[36m pabot --loglevel ${LOG_LEVEL} ${REQUIRED_PARAMETERS} ${OPTIONAL_PARAMETERS} --rerunfailed ${ROBOT_LOGS}-$((value - 1))/output.xml --outputdir ${ROBOT_LOGS}-${value} ${ROBOT_TESTS}\e[0m"
            pabot --loglevel ${LOG_LEVEL} ${REQUIRED_PARAMETERS} ${OPTIONAL_PARAMETERS} --rerunfailed ${ROBOT_LOGS}-$((value - 1))/output.xml --outputdir ${ROBOT_LOGS}-${value} ${ROBOT_TESTS}
            status=$?
        fi
    done

    if [[ $status -eq 0 ]];
    then
        echo -e "\e[32;5m"
        figlet Test Passed
        echo -e "\e[0m"
    else
        echo -e "\e[31;5m"
        figlet Test Failed
        echo -e "\e[0m"
    fi

    echo -e "\e[34mCombining the results. \e[0m"
    echo -e "\e[36;4mCommand:\e[0m\e[36m rebot --nostatusrc  --output ${ROBOT_LOGS}/output.xml --outputdir ${ROBOT_LOGS}/ --merge  ${ROBOT_LOGS}-*/output.xml\e[0m"
    echo -e "\e[32m"
    figlet -f digital Merging output Files

    yes | cp ./suite${ROBOT_LOGS}-*/*.png .${ROBOT_LOGS}/

    rebot --nostatusrc  --output ./output.xml --outputdir ${ROBOT_LOGS}/ --merge  ${ROBOT_LOGS}-*/output.xml
    echo -e "\e[0m"
    python ./suite/execution/parallel_wrapper/combine_results.py ${ROBOT_TEST}
fi

# Stop Xvfb
kill -9 $(pgrep Xvfb)