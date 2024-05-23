public with sharing class NFCController {
    @AuraEnabled
    public static String createVCF(String contactId) {
        // Image__c is custom field for image file
        Contact c = [
            SELECT Id, Name, MobilePhone, Email, Title, Account.Name, Salutation, FirstName, LastName,
                    MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, Image__c 
            FROM Contact
            WHERE Id =: contactId
            LIMIT 1
        ] ?? null;
        if (c == null) {
            return '';
        }
       
        // If you don't care about contact photo, can remove all this
        // Dummy request to refresh token
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:LWC' + c.Image__c);
        req.setMethod('GET');
        HttpResponse res = h.send(req);

        // Convert Image__c to base64
        MetadataService.MetadataPort service = createService();   
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setMethod('GET');
        httpRequest.setHeader('Authorization', 'Bearer' + service.SessionHeader.sessionId );
        httpRequest.setEndpoint('callout:LWC' + c.Image__c);

        Http binding = new Http();
        HttpResponse httpResponse = binding.send(httpRequest);
        while (httpResponse.getStatusCode() >= 300) {
            httpRequest.setEndpoint(httpResponse.getHeader('Location'));
            httpResponse = binding.send(httpRequest);
        }
        Blob image = httpResponse.getBodyAsBlob();
        String base64image = EncodingUtil.base64Encode(image);
        

        // Here is the core part: hardcoded URL (lazy to create field) 
        // Remove PHOTO if not using contact photo
        String finalstr = 
            'BEGIN:VCARD\n' +
            'VERSION:4.0\n' +
            'N:' + c.LastName + ';' + c.FirstName + ';;' + c.Salutation + ';' + '\n' +
            'FN:' + c.Name + '\n' +
            'TITLE:' + c.Title + '\n' +
            'TEL;TYPE=WORK:' + c.MobilePhone + '\n'+
            'PHOTO;ENCODING=BASE64;TYPE=JPEG:' + base64Image + '\n\n' +
            'NOTE: I am a adept software developer proficient in JavaScript, and interested in all things tech related.\n' +
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
