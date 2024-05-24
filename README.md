# Salesforce NFC Writer from Contact Record Page

!!!writes to NFC card, make sure you experiment on an empty card to prevent any irreversible changes


## Notes

- Place the nfcWriter lwc on a contact record page.
- for purpose of demonstrating mobile capabilities
- url in contact card is hardcoded for demo purposes. Can create a new field on contact to store

## Instructions

For contact image, go to Salesforce Classic | Document
Then upload an image, name it as FirstName_LastName_Image (to allow apex to query dynamically)
I marked it as externally available, but not sure if that is required.
