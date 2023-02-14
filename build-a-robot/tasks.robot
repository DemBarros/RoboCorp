*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Excel.Files
Library           RPA.PDF
Library           RPA.Tables
Library           RPA.FileSystem
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault


# The robot should read some data from a local vault. In this case, do not store sensitive data such as credentials in the vault. 
# The purpose is to verify that you know how to use the vault.
# The robot should be available in public GitHub repository.
# Store the local vault file in the robot project repository so that it does not require manual setup.
# It should be possible to get the robot from the public GitHub repository and run it without manual setup.

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    Dialog as progress indicator
    FOR    ${row}    IN    @{orders}
         Close the annoying modal
         Fill the form    ${row}
         Preview the robot
         Submit the order
         Store the receipt as a PDF file   ${row}[Order number]
         Take a screenshot of the robot     ${row}[Order number]
         Embed the robot screenshot to the receipt PDF file    ${row}[Order number] 
         Go to order another robot
    END
     Create a ZIP file of the receipts
     Finishing process

*** Keywords ***
Dialog as progress indicator
    Add text        Processing Orders... Please wait champs...   size=Large
    ${dialog}=     Show dialog    title=Please wait    on_top=${TRUE}
    set global variable    ${dialog}

Open the robot order website
    ${secret}  Get Secret    builtarobot
    Open Available Browser  ${secret}[site]    headless=True  # https://robotsparebinindustries.com/#/robot-order  headless=True

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${orders}=    Read table from CSV   orders.csv    header=True 
    log   tabelas ${orders.columns} 
    RETURN   ${orders}


Close the annoying modal
    Click Element    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]


Fill the form
    [Arguments]    ${order}

    Select From List By Value    //select[@name="head"]    ${order}[Head] 
    Click Element    //*[@id="id-body-${order}[Body]"]
    Input Text       //input[contains(@placeholder,'Enter the part number for the legs')]   ${order}[Legs]
    input text       //*[@id="address"]   ${order}[Address]

Preview the robot
    Click Element    //*[@id="preview"]

Submit the order
    Click Element    order
    ${error}  Run Keyword And Return Status    page should not contain element  //div[contains(@class,'alert alert-danger')]  
    run keyword if  '${error}'=='True'         No Operation
    ...  ELSE                                  Submit the order

Store the receipt as a PDF file
    [Arguments]    ${order}
    Wait Until Element Is Visible     id:order-completion
    ${link}  Get Element Attribute    id:order-completion    outerHTML  
    Html To Pdf    ${link}    ${OUTPUT_DIR}${/}${order}_receipt.pdf
    Set Global Variable    ${link}

Take a screenshot of the robot
    [Arguments]    ${order}
    ${screenshot}  Capture Element Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}${order}robot-preview.png 
    Set Global Variable    ${screenshot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${order}
    ${screenshot_add}   Create List   ${OUTPUT_DIR}${/}${order}robot-preview.png
    Add Files To Pdf    ${screenshot_add}    ${OUTPUT_DIR}${/}${order}_receipt.pdf  append=True  

Go to order another robot
        Click element      //button[contains(@id,'order-another')]  

 Create a ZIP file of the receipts
     Archive Folder With Zip    ${OUTPUT_DIR}${/}    ${OUTPUT_DIR}${/}receipts.zip  include=*.pdf  exclude=*.png
     Close dialog   ${dialog}

Finishing process
    Add text     Process finished   size=Large
    # Add text input  Name
    # ...  label=To finish this process, tell us Your name
    # ...  placeholder=Enter your name here
    # ${name}   Run dialog  title=Finish
