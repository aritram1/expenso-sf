@RestResource(urlMapping='/SynchronizeMessagesAPI/')

global with sharing class SychronizeMessagesAPI {

    public static String className = 'SychronizeMessagesAPI';

    @HttpPost
    global static void sychronizeMessages() {
        try {
            
            // Delete the existing records
            deleteExistingRecords();

            // Parse the incoming JSON body into a list of SMS__c records
            RestRequest req = RestContext.request;
            RestResponse res = RestContext.response;

            String requestBody = req.requestBody.toString();
            List<SMS__c> smsRecords = (List<SMS__c>) JSON.deserialize(requestBody, List<SMS__c>.class);

            // Validate the input
            if (smsRecords == null || smsRecords.isEmpty()) {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf('Error: No SMS records provided.');
                return;
            }

            List<SMS_Platform_Event__e> eventsToPublish = new List<SMS_Platform_Event__e>();

            for (SMS__c sms : smsRecords) {
                // Map fields from SMS__c to SMS_Platform_Event__e
                SMS_Platform_Event__e platformEvent = new SMS_Platform_Event__e(
                    Content__c = sms.Content__c,
                    Original_Content__c = sms.Original_Content__c,
                    Sender__c = sms.Sender__c,
                    Received_At__c = sms.Received_At__c,
                    Device__c = sms.Device__c,
                    External_Id__c = sms.External_Id__c,
                    Created_From__c = 'Sync'
                );
                // EventBus.publish(platformEvent); // firing the events from within the loop (done to maintain the order)
                eventsToPublish.add(platformEvent);
            }

            // Publish the platform events
            if (!eventsToPublish.isEmpty()) {
                EventBus.publish(eventsToPublish);
            }

            // Set a successful response
            res.statusCode = 200;
            res.responseBody = Blob.valueOf('Successfully published ' + eventsToPublish.size() + ' platform events.');
        } 
        catch (Exception e) {
            FinPlanLogger.logError(className, 'sychronizeMessages', e, null); // the last parameter is the entity Id, which is not applicable here, since it is outside the loop
            RestContext.response.statusCode = 500;
            RestContext.response.responseBody = Blob.valueOf('Error processing SMS records: ' + e.getMessage());
        }
    }


    global static void deleteExistingRecords() {
        
        // List of object API names
        List<String> objectApiNames = new List<String>{
            'SMS__c',
            'Transaction__c',
            'Beneficiary__c',	
            'FlowInterview',
            'System_Log__c'
        };

        // Loop through the objects, query and delete records
        for (String objectApiName : objectApiNames) {
            List<SObject> records = Database.query('SELECT Id FROM ' + objectApiName);
            if (!records.isEmpty()) {
                delete records;
                Database.emptyRecycleBin(records);
            }
        }

    }
}