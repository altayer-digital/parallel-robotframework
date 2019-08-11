*** Settings ***
Library    Selenium2Library
Library    Collections
Library    DebugLibrary
Library    String
Library    FakerLibrary
Library    OperatingSystem
Library    XvfbRobot
Library    RequestsLibrary
Library    ../../execution/lib/CustomLib.py

Variables  ./selectors/common.py

*** Variables ***

${BROWSER}                        chrome
${BROWSER_SELECTOR}               mac_chrome
${PLATFORM_SELECTOR}              mac
${DEFAULT_WINDOWS_VERSION}        10
${DEFAULT_MAC_VERSION}            Sierra
${REMOTE_DESIRED}                 ${false}
${SELENIUM_TIMEOUT}               10 seconds
${IS_IE}                          ${false}
${REMOTE_SESSION}                 get session id
${WEBSITE}                        google
${WEBSITE_URL}                    https://www.google.com
${BSUser}                         USERNAME
${AccessKey}                      ACCESSKEY
${REMOTE_URL}                     http://${BSUser}:${AccessKey}@hub.browserstack.com:80/wd/hub
${LANGUAGE}                       ${EMPTY}
${COUNTRY}                        ${EMPTY}
${TEST NAME}                      NONE
${SUITE NAME}                     NONE
${TMP_PATH}                       /tmp
${TIME_OUT}                       single

${t_xmin}  4s
${t_min}   10s
${t_mid}   20s
${t_max}   30s
${t_xmax}  60s

*** Keywords ***

Open Browser And Setup
    [Documentation]  Open browser with parameters
    ${final_url}=  generate website url  ${LANGUAGE}    ${WEBSITE}
    ${WEBSITE_URL}  Set Variable  ${final_url}
    @{parts}  split string  ${suite_name}  .

    ${temp_xmin}=   get timeout    ${TIME_OUT}     xmin
    ${temp_min}=   get timeout    ${TIME_OUT}     min
    ${temp_mid}=   get timeout    ${TIME_OUT}     mid
    ${temp_max}=   get timeout    ${TIME_OUT}     max
    ${temp_xmax}=   get timeout    ${TIME_OUT}     xmax

    set global variable  ${t_xmin}    ${temp_xmin}
    set global variable  ${t_min}   ${temp_min}
    set global variable  ${t_mid}   ${temp_mid}
    set global variable  ${t_max}   ${temp_max}
    set global variable  ${t_xmax}   ${temp_xmax}

    &{mac_chrome}  Create Dictionary  platform=MAC  browserName=chrome  resolution=1280x1024  project=${WEBSITE}  browser_version=61  name=[Test-name: @{parts}[3] - ${test_name}]  browserstack.debug=true  browserstack.networkLogs=true  browserstack.geoLocation=${LANGUAGE}

    set tags  ${BROWSER_SELECTOR}
    run keyword if  '${BROWSER_SELECTOR}'=='mac_chrome'   Open Chrome Browser  ${WEBSITE_URL}  remote_url=${REMOTE_URL}    browser=&{mac_chrome}[browserName]  desired_capabilities=&{mac_chrome}
    ...  ELSE  Open Browser   ${WEBSITE_URL}  remote_url=${False}  browser=${BROWSER}

    run keyword and ignore error  Maximize Browser Window
    run keyword and ignore error  Close Pop-up
    Set Selenium Timeout  ${SELENIUM_TIMEOUT}
    wait until page contains element  &{home_logo}[${WEBSITE}]  ${t_max}

Open Chrome Browser
    [Arguments]  ${site}  ${remote_url}  ${browser}  ${desired_capabilities}
    ${remote_url}=  run keyword if  ${REMOTE_DESIRED} == ${False}   Local settings for Chrome   ${site}
    ...     ELSE    set variable  ${remote_url}
    run keyword if  ${REMOTE_DESIRED} == ${True}   Open Browser  ${site}  remote_url=${remote_url}  browser=${browser}  desired_capabilities=${desired_capabilities}
    run keyword if  ${REMOTE_DESIRED} == ${True}    Get Build And Session Id And Print It On Console

Get Build And Session Id And Print It On Console
    ${REMOTE_SESSION}=    Selenium2Library.get session id
    ${build_id}=  get_browser_stack_build_id  ${BSUser}  ${AccessKey}
    log to console   ${\n}Browser Stack Session: https://automate.browserstack.com/builds/${build_id}/sessions/${remote_session}

Local Settings For Chrome
    [Arguments]  ${site}
    Start Virtual Display    1920    1080
    ${options}  Evaluate  sys.modules['selenium.webdriver'].ChromeOptions()  sys, selenium.webdriver
    Call Method  ${options}  add_argument  --no-sandbox
    ${prefs}    Create Dictionary    download.default_directory=${TMP_PATH}
    Call Method    ${options}    add_experimental_option    prefs    ${prefs}
    Create Webdriver    Chrome    chrome_options=${options}
    go to  ${site}
    [Return]  ${EMPTY}

Go To Link
    [Arguments]  ${link}
    go to  ${WEBSITE_URL}/${link}
    wait until page contains element  &{logo}[${WEBSITE}]   ${t_min}
    sleep  2s

Go Back and Wait
    go back
    wait until page contains element  &{logo}[${WEBSITE}]   ${t_min}
    sleep  2s

Save Screenshot
    [Arguments]  ${index}=1
    ${testname}=     replace string      ${test_name}     _-_     -
    Capture Page Screenshot    screenshots${/}${testname}-${index}.png
    File Should Exist    results/screenshots${/}${testname}-${index}.png

Close Pop-up
    sleep  2s
    click element   ${pop_up_dismiss}


