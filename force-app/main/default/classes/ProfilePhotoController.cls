public with sharing class ProfilePhotoController {

    // Get latest image from ContentDocumentLink
    @AuraEnabled
    public static String getProfileImage(Id recordId) {

        if (recordId == null) {
            return null;
        }

        if (!Schema.sObjectType.ContentDocumentLink.isAccessible()) {
            return null;
        }

        List<ContentDocumentLink> files = [
            SELECT ContentDocument.LatestPublishedVersionId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
            WITH SECURITY_ENFORCED
            ORDER BY ContentDocument.CreatedDate DESC
            LIMIT 1
        ];

        if (files.isEmpty()) {
            return null;
        }

        return '/sfc/servlet.shepherd/version/download/' +
            files[0].ContentDocument.LatestPublishedVersionId;
    }


    //Upload profile photo
    @AuraEnabled
    public static void uploadProfilePhoto(Id recordId, String fileName, String base64Data){

        if (recordId == null || String.isBlank(base64Data)) {
            return;
        }

        if(fileName == null || 
       !(fileName.toLowerCase().endsWith('.jpg') || 
         fileName.toLowerCase().endsWith('.jpeg') ||
         fileName.toLowerCase().endsWith('.svg') || 
         fileName.toLowerCase().endsWith('.png'))) {

        throw new AuraHandledException('Only JPG, PNG, JPEG or SVG files allowed');
    }

        // CRUD check → ContentVersion create
        if (!Schema.sObjectType.ContentVersion.isCreateable()) {
            throw new AuraHandledException('No permission to upload file');
        }

        Blob body = EncodingUtil.base64Decode(base64Data);

        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.PathOnClient = fileName;
        cv.VersionData = body;
        insert cv;

        // get ContentDocumentId
        Id contentDocumentId = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
            WITH SECURITY_ENFORCED
        ].ContentDocumentId;

        // CRUD check → ContentDocumentLink create
        if (!Schema.sObjectType.ContentDocumentLink.isCreateable()) {
            throw new AuraHandledException('No permission to link file');
        }

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = recordId;
        cdl.ContentDocumentId = contentDocumentId;
        cdl.ShareType = 'V';
        insert cdl;
    }
}