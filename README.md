# Salesforce NFC Writer from Contact Record Page

> [!CAUTION]
> writes to NFC card, make sure you experiment on an empty card to prevent any irreversible changes

> [!NOTE]  
> For purpose of demonstrating NFCService API in lightning/mobileCapabilities, performance and UI was not the focus.

---

https://github.com/SFDarren/SF-MobileCapabilitiesNFCService/assets/150164849/cd638d0d-1bb4-42b7-a81b-5445a46ffebb

---

### Other Notes

- Place the nfcWriter lwc on a contact record page as it reads from contact information
- For contact image, go to Salesforce Classic | Document, and upload an image, naming it as `FirstName_LastName_Image` to allow apex to query dynamically based on contact's name
  - I marked it as externally available, but not sure if that is required.
- Utilising description field to store website & contact note (separated by newline), instead of creating new fields.
  
  <img width="525" alt="image" src="https://github.com/SFDarren/SF-MobileCapabilitiesNFCService/assets/150164849/5f573024-013f-4492-b46b-7c6b8ebcf381">
- I tried reading my TnG NFC card, but it wasn't able to read..








