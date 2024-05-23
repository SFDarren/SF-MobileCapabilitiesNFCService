public with sharing class NFCController {
    @AuraEnabled
    public static String createVCF(String contactId) {
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
        System.debug(httpRequest);

        Http binding = new Http();
        HttpResponse httpResponse = binding.send(httpRequest);
        System.debug(httpResponse);
        while (httpResponse.getStatusCode() >= 300) {
            httpRequest.setEndpoint(httpResponse.getHeader('Location'));
            httpResponse = binding.send(httpRequest);
        }
        System.debug('location: ' +  httpResponse.getHeader('Location'));
        Blob image = httpResponse.getBodyAsBlob();
        String base64image = EncodingUtil.base64Encode(image);
        System.debug(base64image);
        
        Mobile_Capability__c mc = [ SELECT Id, Data__c FROM Mobile_Capability__c WHERE Id ='a00F900005EtgCHIAZ'];
        mc.Data__c = base64Image;
        update mc;
        // 
        // System.debug(URL.getOrgDomainURL().toExternalForm());
        // System.debug(URL.getOrgDomainURL().toExternalForm() + c.Image__c);
        String finalstr = 
            'BEGIN:VCARD\n' +
            'VERSION:4.0\n' +
            'N:' + c.LastName + ';' + c.FirstName + ';;' + c.Salutation + ';' + '\n' +
            'FN:' + c.Name + '\n' +
            'TITLE:' + c.Title + '\n' +
            'TEL;TYPE=WORK:' + c.MobilePhone + '\n'+
            // 'PHOTO;MEDIATYPE=image/jpeg:' + URL.getOrgDomainURL().toExternalForm() + c.Image__c + '\n\n' +
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

    private static MetadataService.MetadataPort createService() { 
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        // service.endpoint_x = 'callout:ApexMDAPI/services/Soap/m/38.0';
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = '{!$Credential.OAuthToken}'; 
        return service;     
    }

}
