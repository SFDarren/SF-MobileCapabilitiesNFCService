public with sharing class NFCController {
    @AuraEnabled
    public static String createVCF(String contactId) {
        Contact c = [
            SELECT Id, Name, MobilePhone, Email, Title, Account.Name, Salutation, FirstName, LastName,
                    MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry
            FROM Contact
            WHERE Id =: contactId
            LIMIT 1
        ] ?? null;
        if (c == null) {
            return '';
        }

        // If you don't care about contact photo, can remove all this
        // Name the photos FirstName_LastName_Image to query dynamically
        // can have flow to automate this ^
        Document d = [
            SELECT Id, Body
            FROM Document
            WHERE DeveloperName =: String.join(c.Name.split(' '), '_') + '_Image'
            LIMIT 1
        ] ?? null;
        String base64Image = d != null ? EncodingUtil.base64Encode(d.Body) : '';

        // Here is the core part: hardcoded URL (lazy to create field) 
        // Remove PHOTO if not using contact photo
        String finalstr = 
            'BEGIN:VCARD\n' +
            'VERSION:4.0\n' +
            'N:' + c.LastName + ';' + c.FirstName + ';;' + c.Salutation + ';' + '\n' +
            'FN:' + c.Name + '\n' +
            'TITLE:' + c.Title + '\n' +
            'TEL;TYPE=WORK:' + c.MobilePhone + '\n';

        finalstr += base64Image != '' ? ('PHOTO;ENCODING=BASE64;TYPE=JPEG:' + base64Image + '\n\n') : '';

        finalstr = finalstr +
            'NOTE: I am an adept software developer proficient in JavaScript, and interested in all things tech related.\n' +
            'URL:https://darrenseet.com\n' +
            'ADR;TYPE=WORK:;;' + c.MailingStreet + ';' + c.MailingCity + ';' + c.MailingState + ';' + c.MailingPostalCode + ';' + c.MailingCountry + '\n' +
            'EMAIL;TYPE=WORK:' + c.Email + '\n'+
            'ORG:' + c.Account.Name + '\n' +
            'END:VCARD';

        ContentVersion cv = new ContentVersion();
        cv.Title = 'ContactCard file'; 
        cv.PathOnClient = 'ContactCard.vcf'; 
        cv.VersionData = Blob.valueOf(finalstr); 

        insert cv;

        ContentDistribution cd = new ContentDistribution();
        cd.Name = 'Test';
        cd.ContentVersionId = cv.id;
        cd.PreferencesAllowViewInBrowser= true;
        cd.PreferencesLinkLatestVersion=true;
        cd.PreferencesNotifyOnVisit=false;
        cd.PreferencesPasswordRequired=false;
        cd.PreferencesAllowOriginalDownload= true;
        insert cd;

        cd = [SELECT ContentDownloadUrl FROM ContentDistribution WHERE ID =: cd.Id];
        return cd.ContentDownloadUrl;
    }

    // Not useful if you don't care about photo
    private static MetadataService.MetadataPort createService() { 
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        // service.endpoint_x = 'callout:ApexMDAPI/services/Soap/m/38.0';
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = '{!$Credential.OAuthToken}'; 
        return service;     
    }

}
