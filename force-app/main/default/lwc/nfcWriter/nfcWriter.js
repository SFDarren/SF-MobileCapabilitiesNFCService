import { LightningElement, api } from 'lwc';
import { createRecord, getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getNfcService, getBiometricsService } from 'lightning/mobileCapabilities';
import { reduceErrors } from 'c/utils'
import { ShowToastEvent} from 'lightning/platformShowToastEvent'
import createLink from '@salesforce/apex/DocumentController.createLink'
import createVCF from '@salesforce/apex/NFCController.createVCF'

export default class NfcReader extends LightningElement {
    @api recordId;
    
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
}

