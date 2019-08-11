*** Settings ***

Resource   general_web_keywords.robot
Variables  ./text/${WEBSITE}_${LANGUAGE}.py
Variables  ./selectors/${WEBSITE}.py

*** Keywords ***

Verify language
    ${lang_flag}  run keyword and return status    page should contain  ${page_lang_verify}
    run keyword if  '${lang_flag}' == '${false}'   Change Language

Change Language
    click link  xpath=//a[text()='${language_text}']

Verify No Result Found
    wait until page contains  ${no_result_text}

Go to Search Result by Enter
    [Arguments]  ${value_to_search}=${search_term}
    wait until page contains element  ${search_input_field}
    run keyword if  '${value_to_search}'!=''  Press Key  ${search_input_field}  ${value_to_search}
    Press Key  ${search_input_field}  \\13

Verify Result
    wait until element is visible  ${verify_search_page}
    page should contain  ${verify_result_text}

Search
    [Arguments]  ${value_to_search}=${search_term}
    wait until page contains element  ${search_input_field}
    input text   ${search_input_field}   ${value_to_search}

First word for search
    @{split_name}  Split String  ${long_search_term}
    ${first_word}   set variable  @{split_name}[0]
    [Return]  ${first_word}

Verify Result is not Refined
    wait until page contains element  ${first_search_suggestion_field}  ${t_max}
    ${first_result}=    Get Text  ${first_search_suggestion_field}
    ${word_cleaned}=    Remove String     ${first_result}   '
    should not be true  '${long_search_term}' in '${word_cleaned}'

Enter rest of the search
    @{split_name}  Split String  ${long_search_term}
    ${count}=   get length  ${split_name}
    ${word}  set variable  ''
    :FOR  ${INDEX}  IN RANGE  1  ${count}
    \   ${word}   set variable  @{split_name}[${INDEX}]
    \   press key  ${search_input_field}  ${space}${word}
    sleep  3s

Verify Result are Refined
    wait until page contains element  ${first_search_suggestion_field}  ${t_max}
    ${first_result}=    Get Text  ${first_search_suggestion_field}
    ${word_cleaned}=    Remove String     ${first_result}   '
    should be true  '${long_search_term}' in '${word_cleaned}'
