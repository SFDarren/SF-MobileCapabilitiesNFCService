import { LightningElement, api, wire } from 'lwc';
import { createRecord, getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getNfcService, getBiometricsService } from 'lightning/mobileCapabilities';
import { reduceErrors } from 'c/utils'
import { ShowToastEvent} from 'lightning/platformShowToastEvent'
import createLink from '@salesforce/apex/DocumentController.createLink'
import NAME_FIELD from '@salesforce/schema/Contact.Name';
import EMAIL_FIELD from '@salesforce/schema/Contact.Email';
import PHONE_FIELD from '@salesforce/schema/Contact.MobilePhone';
import TITLE_FIELD from '@salesforce/schema/Contact.Title';
import STREET_FIELD from '@salesforce/schema/Contact.MailingStreet'
import POSTALCODE_FIELD from '@salesforce/schema/Contact.MailingPostalCode'
import CITY_FIELD from '@salesforce/schema/Contact.MailingCity'
import COUNTRY_FIELD from '@salesforce/schema/Contact.MailingCountry'
import STATE_FIELD from '@salesforce/schema/Contact.MailingState'
import createVCF from '@salesforce/apex/NFCController.createVCF'

const FIELDS = [NAME_FIELD, PHONE_FIELD, TITLE_FIELD, EMAIL_FIELD, POSTALCODE_FIELD, CITY_FIELD, COUNTRY_FIELD, STATE_FIELD]

export default class NfcReader extends LightningElement {
    @api recordId;
    @wire(getRecord, {recordId: '$recordId', fields: FIELDS })
    record
    
    text;

    nfcService
    biometricsService
    connectedCallback() {
        this.nfcService = getNfcService();
        this.biometricsService = getBiometricsService();
    }
    
    async verifyUser() {
        if (this.biometricsService.isAvailable()) {
            const options = {
                permissionRequestBody: "Required to confirm device ownership.",
                additionalSupportedPolicies: ['PIN_CODE']
            }
            const result = await this.biometricsService.checkUserIsDeviceOwner(options);
            return result;
        } else {
            this.text = 'Problem initiating Biometrics service'
        }
    }
    
    async handleReadClick() {
        let isUser = await this.verifyUser();
        if (isUser && this.nfcService.isAvailable()) {
            const options = {
                "instructionText": "Hold your phone near the tag to read.",
                "successText": "Tag read successfuly!"
            }
            this.nfcService.read(options).then(result => {
                // result is [NFCMessage]
                this.text = JSON.stringify(result[0].records.map(record => record.parsed), null, 2)
            }).catch(error => {
                this.text = error.message;
            })
        } else {
            this.text = 'Problem initiating NFC service.'
        }
    }

    async handleWriteClick() {
        let isUser = await this.verifyUser();
        if (isUser && this.nfcService.isAvailable()) {
            let url = ''
            try {
                url = await createVCF({ contactId: this.recordId })
            } catch(error) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error creating VCF',
                    message: reduceErrors(error),
                    variant: 'error'
                }))
            }
            const linkRecord = await this.nfcService.createUriRecord(url)
            const payload = [linkRecord] 
            const options = {
              "instructionText": "Hold your phone near the tag to write.",
              "successText": "Tag written successfully!"
            };
            this.nfcService.write(payload, options)
              .then(() => {
                this.text = "Tag written successfully!";
              })
              .catch((error) => {
                // Handle errors
                this.text = 'Error code: ' + error.code + '\nError message: ' + error.message;
              });
        }
    }

    async createWritePayload() {
        const nameRecord = await this.nfcService.createTextRecord({text: getFieldValue(this.record.data, NAME_FIELD), langId: "en"});
        this.text = JSON.stringify(nameRecord)
        const phoneRecord = await this.nfcService.createTextRecord({text: getFieldValue(this.record.data, PHONE_FIELD), langId: "en"});
        this.text = JSON.stringify(phoneRecord)
        const emailRecord = await this.nfcService.createUriRecord(`mailto:${getFieldValue(this.record.data, EMAIL_FIELD)}`);
        this.text = JSON.stringify(emailRecord)
        const addressRecord = await this.nfcService.createTextRecord({text: `${this.getAddress()}`, langId: "en"});
        this.text = JSON.stringify(addressRecord)
        const titleRecord = await this.nfcService.createTextRecord({text: getFieldValue(this.record.data, TITLE_FIELD), langId: "en"});
        this.text = JSON.stringify(titleRecord)
        return [nameRecord, phoneRecord, emailRecord, addressRecord, titleRecord];
    }

    getAddress() {
        const street = getFieldValue(this.record.data, STREET_FIELD);
        const city = getFieldValue(this.record.data, CITY_FIELD);
        const country = getFieldValue(this.record.data, COUNTRY_FIELD);
        const postalCode = getFieldValue(this.record.data, POSTALCODE_FIELD);
        return `${street},
        ${postalCode} ${city},
        ${country}`
    }
}

