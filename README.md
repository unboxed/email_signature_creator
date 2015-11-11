# Email signature creator for Mail.app

###Script to set a HTML email signature in Mail.app

Before doing anything the script will:

 - Check that the os version is 10.10
 - There is at least 1 Mail account

**If either of these checks fails the script will exit**

The script will then ask the for 4 things (for the new template):

 - Full name
 - Email address
 - Mobile number (Optional)
 - Twitter username (Optional)

It doesn't currently consider the South African office/mobile number
conversion but wouldn't too much to cater for that as well.

It will then use Mail to write a placeholder signature file
Then replace the placeholder signature with the HTML email signature

Thanks go to http://seesolve.com/words/2013/06/installing-html-email-signatures-for-multiple-users for an explanation of how this should work.

Authors:

 - Oskar Pearson <oskar.pearson@unboxedconsulting.com>
 - Anson Kelly <anson.kelly@unboxedconsulting.com>

## Packaging the script as an OSX application
 - Open the script with AppleScript Editor
 - Click File | Export
 - In the dialog;
   - Input file name
   - File Format (Application)
   - Don't Code Sign
   - Save

 - You should now have a packaged application code and can double click to execute
