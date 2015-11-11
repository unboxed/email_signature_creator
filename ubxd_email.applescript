(*
    Do not change anything below here
*)

global mailSignatureFile
global mailSignatureFilePosix
global okButton
set supportedOsVersion to "10.10"
set okButton to "OK"
set cancelButton to "Cancel"
set placeholderText to "PlaceHolder - To be replaced"
set emailSignatureName to "AutoSignature"

on replaceText(find, replace, subject)
  set prevTIDs to text item delimiters of AppleScript
  set text item delimiters of AppleScript to find
  set subject to text items of subject

  set text item delimiters of AppleScript to replace
  set subject to "" & subject
  set text item delimiters of AppleScript to prevTIDs

  return subject
end replaceText

on displayError(msg)
  display dialog msg buttons {okButton} default button okButton with icon stop with title "Error"
end displayError

--------------------------------------------------------------------------------
-- Check the OS version is supported
--------------------------------------------------------------------------------
if (system version of (system info) does not start with supportedOsVersion) then
  displayError("This code only works on OS verson " & supportedOsVersion & ".*")
  return
end if

--------------------------------------------------------------------------------
-- Check that Mail has at least 1 Account setup
--------------------------------------------------------------------------------
set mailboxCountComplete to false
tell application "Mail"
  if (count of accounts) is greater than 0 then
    set mailboxCountComplete to true
  end if
  quit
end tell

if not mailboxCountComplete then
  displayError("There are no Mail accounts setup. Please set up a Mail account first")
  return
end if

--------------------------------------------------------------------------------
-- Ask the user for their full name
--------------------------------------------------------------------------------
repeat

  try
    set fullName to text returned of (display dialog "What is your full name? (eg John Smith)" default answer "")

    if length of fullName > 0 then
      exit repeat
    end if

  on error number -128
    return
  end try

end repeat


--------------------------------------------------------------------------------
-- Ask the user for their email address
--------------------------------------------------------------------------------
repeat

  try
    set emailAddress to text returned of (display dialog "What is your email address? (eg myemail@world.com)" default answer "")

    if length of emailAddress > 0 then
      exit repeat
    end if

  on error number -128
    return
  end try

end repeat


--------------------------------------------------------------------------------
-- Ask the user for their mobile number
--------------------------------------------------------------------------------
try
  set mobileNumber to text returned of (display dialog "What is your mobile number? (Leave blank if you don't know)

Preferred Format: 07700 900 111" default answer "")

  -- Add uk prefix of +44
  if length of mobileNumber > 0 and the first character of mobileNumber is not "+" then
    set mobileNumber to text 2 thru (length of mobileNumber) of mobileNumber
    set mobileNumber to "+44 " & mobileNumber
  end if

on error number -128
  return
end try

--------------------------------------------------------------------------------
-- Ask the user for their twitter username - its optional
--------------------------------------------------------------------------------

try
  set twitterHandle to text returned of (display dialog "What is your twitter username? (Eg. @unboxed - its optional)" default answer "")
  set twitterTemplate to ""

  if length of twitterHandle > 0 then
    set twitterTemplate to "
     <p style=\"margin: 0; font-size: 11px;\">
      <a style=\"color: #282828; text-decoration: none;\" href=\"https://twitter.com/intent/follow?screen_name=\"" & twitterHandle & "\">" & twitterHandle & "</a>
         </p>
      "
  end if

on error number -128
  return
end try

--------------------------------------------------------------------------------
-- Declare signature template
--------------------------------------------------------------------------------
set companyDisplayName to "Unboxed"
set websiteUrl to "https://unboxed.co/"
set websiteDisplayName to "unboxed.co"
set officeLandlineNumber to "+44 20 7183 4250"
set emailSignature to "
      <div style=\"font-family: HelveticaNeue-Light, arial; padding: 10px 0; color: #282828;\">
        <h3 style=\"color: #5D5D5D; font-size: 19px; font-weight: normal; margin: 0; text-transform: lowercase;\">" & fullName & "</h3>
        <p style=\"margin: 0; font-size: 12px; color: #901499;\">
          <a style=\"color: #901499; text-decoration: none;\" href=\"mailto:" & emailAddress & "\">" & emailAddress & "</a>
        </p>
        <p style=\"margin: 0; font-size: 11px;\">" & mobileNumber & "</p>
        <p style=\"margin: 0; font-size: 11px;\">" & officeLandlineNumber & "</p>
        " & twitterTemplate & "
        <h3 style=\"font-size: 20px; font-weight: normal; margin: 30px 0 0 0; text-transform: lowercase;\">
          <a style=\"color: #901499; text-decoration: none;\" href=\"" & websiteUrl & "\">" & companyDisplayName & "</a>
        </h3>
        <p style=\"margin: 0 0 6px 0; font-size: 13px; line-height: 11px;\">
          <a style=\"color: #282828; text-decoration: none;\" href=\"" & websiteUrl & "\">" & websiteDisplayName & "</a>
        </p>
      </div>
  "


--------------------------------------------------------------------------------
-- Delete any existing signature, and then create a new placeholder signature
--------------------------------------------------------------------------------
try
  tell application "Mail"
    activate
  end tell
on error
  display dialog "Error activating Mail" buttons {okButton} default button okButton cancel button okButton with title "Exit"
end try
delay 5
try
  log "Deleting existing signature..."
  tell application "Mail"
    delete (every signature whose name is emailSignatureName)
  end tell
  log ".. deleted"
  delay 3
on error errmsg
  displayError("Error deleting existing signature: " & errmsg)
  return
end try


--------------------------------------------------------------------------------
-- Create placeholder signature in Mail
-- We let Mail create the signature file so the formatting is correct for that version of Mail
--------------------------------------------------------------------------------
try
  log "Creating Placeholder Signature..."
  tell application "Mail"
    set newSig to make new signature with properties {name:emailSignatureName, content:"PlaceHolder"}
    set content of newSig to placeholderText
    set selected signature to emailSignatureName
    delay 1
    tell application "System Events" to keystroke "," using command down
    delay 3
    tell application "System Events" to keystroke "w" using command down
    tell application "Mail"
      quit
    end tell
  end tell
  log "... placeholder created"
on error errmsg
  displayError(errmsg)
  return
end try
log "Waiting for mail to exit"

delay 5

--------------------------------------------------------------------------------
-- Find the latest mail signature file with finder, now that things have been saved
--------------------------------------------------------------------------------
try
  tell application "Finder"

    -- Different versions of Mail store the signatures in different folders. Grrr.
    set signaturePath to ((path to library folder from user domain) as text) & "Mobile Documents:com~apple~mail:Data:MailData:Signatures:"

    if not (exists signaturePath) then
      set signaturePath to ((path to library folder from user domain) as text) & "Mail:V2:MailData:Signatures:"
    end if

    if not (exists signaturePath) then
      set signaturePath to ((path to library folder from user domain) as text) & "Mail:MailData:Signatures:"
    end if

    set mailSignatureFile to item 1 of reverse of (sort (every file of alias signaturePath whose name ends with ".mailsignature") by modification date) as alias
    set mailSignatureFilePosix to POSIX path of mailSignatureFile

  end tell
on error errmsg
  displayError(errmsg)
  return
end try

--------------------------------------------------------------------------------
-- Replace the placeholder text in the signature file with our proper unboxed template
--------------------------------------------------------------------------------
try

  set the mailSignatureOpenFile to open for access mailSignatureFilePosix with write permission
  set signatureText to read mailSignatureOpenFile
  set signatureText to get replaceText(placeholderText, emailSignature, signatureText)
  set eof mailSignatureOpenFile to 0
  write signatureText to mailSignatureOpenFile starting at 0
  close access mailSignatureOpenFile

on error errmsg
  displayError(errmsg)
  return
end try
display dialog "It worked!

Emails sent from Mail should now have your new signature" buttons {okButton} default button okButton with title "Exit" with icon note giving up after 30
