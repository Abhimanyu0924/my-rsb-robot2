*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             Collections
Library             RPA.Dialogs
Library             OperatingSystem
Library             RPA.Desktop
Library             RPA.JavaAccessBridge
Library             RPA.RobotLogListener
Library             RPA.Robocorp.Vault


*** Variables ***
${url}              https://robotsparebinindustries.com/#/robot-order
${img_folder}       ${CURDIR}${/}image_files
${pdf_folder}       ${CURDIR}${/}pdf_files
${output_folder}    ${CURDIR}${/}output
${orders_file}      ${CURDIR}${/}orders.csv
${zip_file}         ${output_folder}${/}pdf_archive.zip
${csv_url}          https://robotsparebinindustries.com/orders.csv


*** Tasks ***
Order robot from RobotSpareBin Industries Inc
    Directory Cleanup
    Get The Program Author Name From Our Vault
    ${username}=    Get The User Name

    open the robot order website
    ${orders}=    Get Orders
    FOR    ${ROW}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${ROW}
        Wait Until Keyword Succeeds    10X    2sec    Preview the robots
        Wait Until Keyword Succeeds    10X    2sec    Submit the order
        ${orderid}    ${img_filename}=    Take a screen shot of robot
        ${PDF_filename}=    Store the receipt as a PDF file    ORDER_NUMBER=${order_id}
        Embed the robot screenshot to the receipt PDF file    IMG_FILE=${img_filename}    PDF_FILE=${PDF_filename}
        Go to order another robot
    END
    Create a Zip File of the Receipts
    Log out and close the Browser
    Display the success dialog    USER_NAME=${username}


*** Keywords ***
open the robot order website
    Open Available Browser    ${url}

Directory Cleanup
    Create Directory    ${output_folder}
    Create Directory    ${img_folder}
    Create Directory    ${pdf_folder}
    Empty Directory    ${img_folder}
    Empty Directory    ${pdf_folder}

Get Orders
    Download    url=${csv_url}    target_file=${orders_file}    overwrite=true
    ${table}=    Read table from CSV    path=${orders_file}
    RETURN    ${table}

Close the annoying modal
    Set Local Variable    ${btn_yep}    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[2]
    Wait And Click Button    ${btn_yep}

Fill the form
    [Arguments]    ${myrow}
    Set Local Variable    ${order_no}    ${myrow}[Order number]
    Set Local Variable    ${head}    ${myrow}[Head]
    Set Local Variable    ${body}    ${myrow}[Body]
    Set Local Variable    ${legs}    ${myrow}[Legs]
    Set Local Variable    ${address}    ${myrow}[Address]

    Set Local Variable    ${input_head}    //*[@id="head"]
    Set Local Variable    ${input_body}    body
    Set Local Variable    ${input_legs}    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input
    Set Local Variable    ${input_address}    //*[@id="address"]
    Set Local Variable    ${btn_preview}    //*[@id="preview"]
    Set Local Variable    ${btn_order}    //*[@id="order"]
    Set Local Variable    ${img_preview}    //*[@id="robot-preview-image"]

    Wait Until Element Is Visible    ${input_head}
    Wait Until Element Is Enabled    ${input_head}
    Select From List By Value    ${input_head}    ${head}

    Wait Until Element Is Enabled    ${input_body}
    Select Radio Button    ${input_body}    ${body}

    Wait Until Element Is Enabled    ${input_legs}
    Input Text    ${input_legs}    ${legs}

    Wait Until Element Is Enabled    ${input_address}
    Input Text    ${input_address}    ${address}

Preview the robots
    Set Local Variable    ${btn_preview}    //*[@id="preview"]
    Set Local Variable    ${img_preview}    //*[@id="robot-preview-image"]
    Click Button    ${btn_preview}
    Wait Until Element Is Visible    ${img_preview}

Submit the order
    Set Local Variable    ${btn_order}    //*[@id="order"]
    Set Local Variable    ${lbl_receipt}    //*[@id="receipt"]

    Mute Run On Failure    page should contain Element

    Click Button    ${btn_order}
    page should contain element    ${lbl_receipt}

Take a screen shot of robot
    Set Local Variable    ${lbl_orderid}    xpath://html/body/div/div/div[1]/div/div[1]/div/div/p[1]
    Set Local Variable    ${img_robot}    //*[@id="robot-preview-image"]
    Wait Until Element Is Visible    ${img_robot}
    Wait Until Element Is Visible    ${lbl_orderid}

    ${orderid}=    Get Text    //*[@id="receipt"]/p[1]
    Set Local Variable    ${fully_qualified_img_filename}    ${img_folder}${/}${orderid}.png
    Sleep    2sec
    Log To Console    Capturing Screenshot to    ${fully_qualified_img_filename}
    Capture Element Screenshot    ${img_robot}    ${fully_qualified_img_filename}
    RETURN    ${orderid}    ${fully_qualified_img_filename}

Go to order another robot
    Set Local Variable    ${btn_order_another_robot}    //*[@id="order-another"]
    Click Button    ${btn_order_another_robot}

Log out and close the Browser
    Close Browser

Create a Zip File of the Receipts
    Archive Folder With ZIP    ${pdf_folder}    ${zip_file}    overwrite=true    include=*.pdf

Store the receipt as a PDF file
    [Arguments]    ${ORDER_NUMBER}
    Wait Until Element Is Visible    //*[@id="receipt"]
    Log To Console    printing ${ORDER_NUMBER}
    ${order_receipt_html}=    Get Element Attribute    //*[@id="receipt"]    outerHTML
    Set Local Variable    ${fully_qualified_pdf_filename}    ${pdf_folder}${/}${ORDER_NUMBER}.pdf
    Html To Pdf    content=${order_receipt_html}    output_path=${fully_qualified_pdf_filename}
    RETURN    ${fully_qualified_pdf_filename}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${IMG_FILE}    ${PDF_FILE}
    Log To Console    Printing Embedding image ${IMG_FILE} in pdf file ${PDF_FILE}
    Open Pdf    ${PDF_FILE}
    @{myfiles}=    Create List    ${IMG_FILE}:x=0,y=0
    Add Files To PDF    ${myfiles}    ${PDF_FILE}    ${True}

Get The Program Author Name From Our Vault
    Log To Console    Getting Secret from our Vault
    ${secret}=    Get Secret    mysecrets
    Log    ${secret}[whowrotethis] wrote this program for you    console=yes

Get The User Name
    Add heading    Robocorp spare bin Industries welcome you.
    Add text input    myname    label=Write your name here    placeholder=Give me some input here
    ${result}=    Run dialog
    RETURN    ${result.myname}

Display the success dialog
    [Arguments]    ${USER_NAME}
    Add icon    Success
    Add heading    Your orders have been processed
    Add text    Dear ${USER_NAME} - all orders have been processed. Have a nice day!
    Run dialog    title=Success
