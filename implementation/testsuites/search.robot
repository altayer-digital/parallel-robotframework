*** Settings ***
Resource    ../resources/main_keywords.robot
Test Setup      Open Browser And Setup
Test Teardown   Close All Browsers

*** Test Cases ***

Search with Invalid input
  [Documentation]
  ...  - User should not be able to find any items by a search like "noitemswiththiskeyword".
  ...  - user should see such text "not found" on this page.
  [Tags]  search  smoke

  Verify language
  Go to Search Result by Enter   ${no_result_term}
  Verify No Result Found

Search with Keyword and Verify result page
  [Documentation]  User should be able to search for result by using "Enter" and verify result page.
  [Tags]  search  smoke

  Go to Search Result by Enter
  Verify Result

Search with follow up words after initial search
  [Documentation]  User will enter another word for better search result,
  ...  - Search result should follow user and provide more precise results
  [Tags]  search  smoke

  ${first_word}=    First word for search
  Search  ${first_word}
  Verify Result is not Refined
  Enter rest of the search
  Verify Result are Refined

