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
Variables  ./config.py

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

    &{config}  Create Dictionary
    ...     platform=${PLATFORM}
    ...     browserName=${BROWSER}
    ...     resolution=${RESOLUTION}
    ...     project=${WEBSITE}
    ...     browser_version=${BROWSER_VERSION}
    ...     name=[Test-name: @{parts}[3] - ${test_name}]
    ...     browserstack.debug=${BROWSER_DEBUG}
    ...     browserstack.networkLogs=${BROWSER_NETWORK}

    run keyword if  '${CONFIG_SELECTOR}' == 'main_config'
    ...     Open Chrome Browser  ${WEBSITE_URL}  remote_url=${REMOTE_URL}
    ...     browser=&{config}[browserName]
    ...     desired_capabilities=&{config}
    ...     ELSE     ${WEBSITE_URL}  remote_url=${False}  browser=${BROWSER}

    run keyword and ignore error  Maximize Browser Window
    run keyword and ignore error  Close Pop-up
    Set Selenium Timeout  ${SELENIUM_TIMEOUT}
    wait until page contains element  &{home_logo}[${WEBSITE}]  ${t_max}

Open Chrome Browser
    [Documentation]
    ...     Open browser with parameters

    [Arguments]  ${site}  ${remote_url}  ${browser}  ${desired_capabilities}
    ${remote_url}=  run keyword if  ${REMOTE_DESIRED} == ${False}   local settings for chrome   ${site}
    ...     ELSE    set variable  ${remote_url}

    run keyword if  ${REMOTE_DESIRED} == ${True}   open browser  ${site} 
    ...     remote_url=${remote_url}
    ...     browser=${browser}
    ...     desired_capabilities=${desired_capabilities}

    run keyword if  ${REMOTE_DESIRED} == ${True}    Print BS Session URL

Print BS Session URL
    [Documentation]
    ...     Gets build snd session id and print it on console

    ${REMOTE_SESSION}=    SeleniumLibrary.get session id
    ${build_id}=  get browser stack build id  ${BSUser}  ${AccessKey}
    log to console   ${\n}Browser Stack Session: https://automate.browserstack.com/builds/${build_id}/sessions/${remote_session}

Local Settings For Chrome
    [Documentation]
    ...     This keyword is used to run test in local docker chrome browser

    [Arguments]  ${site}
    Start Virtual Display    1920    1080
    ${options}  Evaluate  sys.modules['selenium.webdriver'].ChromeOptions()  sys, selenium.webdriver
    call method  ${options}  add_argument  --no-sandbox
    ${prefs}    create dictionary    download.default_directory=${TMP_PATH}
    call method    ${options}    add_experimental_option    prefs    ${prefs}
    create webdriver    Chrome    chrome_options=${options}

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


