import { LightningElement, api } from 'lwc';
import { createRecord, getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getNfcService, getBiometricsService } from 'lightning/mobileCapabilities';
import { reduceErrors } from 'c/utils'
import { ShowToastEvent} from 'lightning/platformShowToastEvent'
import createVCF from '@salesforce/apex/NFCController.createVCF'

export default class NfcReader extends LightningElement {
    @api recordId;
    
    nfcService
    biometricsService
    showToastEvent
    @api invoke() {
        this.nfcService = getNfcService();
        this.biometricsService = getBiometricsService();
        this.showToastEvent = new ShowToastEvent();
        this.handleWriteClick();
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
            this.showToastEvent = {
                title: 'Problem initiating biometricsService',
                variant: 'error'
            }
            this.dispatchEvent(this.showToastEvent)        
        }
    }

    async handleWriteClick() {
        let isUser = await this.verifyUser();
        if (isUser && this.nfcService.isAvailable()) {
            let url = ''
            try {
                url = await createVCF({ contactId: this.recordId })
            } catch(error) {
                this.showToastEvent = {
                    title: 'Error creating Virtual Contact File',
                    message: reduceErrors(error),
                    variant: 'error',
                }
                this.dispatchEvent(this.showToastEvent)
            }
            const linkRecord = await this.nfcService.createUriRecord(url)
            const payload = [linkRecord] 
            const options = {
              "instructionText": "Hold your phone near the tag to write.",
              "successText": "Tag written successfully!"
            };
            this.nfcService.write(payload, options).then(() => {
                this.showToastEvent = {
                    title: 'Tag written successfully!',
                    variant: 'success',
                }
                this.dispatchEvent(this.showToastEvent)
            }).catch((error) => {
                this.showToastEvent = {
                    title: 'Error code: ' + error.code,
                    message: error.message,
                    variant: 'error'
                }
                this.dispatchEvent(this.showToastEvent)
            });
        }
    }   

    /* async handleReadClick() {
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
    } */
}

