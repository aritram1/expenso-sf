@RestResource(urlMapping='/api/sms/create')

global with sharing class CreateMessagesAPI {

    public static String className = 'CreateMessagesAPI';

    @HttpPost
    global static void createMessages() {

        Map<String, Object> responseBody = new Map<String, Object>();
        RestContext.response.addHeader('Content-Type', 'application/json');
        
        try {
            
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

            // Upsert the sms records from payload
            upsert smsRecords External_Id__c;
            
            // Upsert the sms records again but with enriched data
            System.enqueueJob(new QueueableEnrichAndUpsertSMS(smsRecords));
            System.debug('SMS records successfully enriched and inserted.');

            // Set a successful response
            res.statusCode = 200;

            responseBody.put('success', true);
            responseBody.put('message', 'Successfully upserted ' + smsRecords.size() + ' records.');
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseBody));
        } 
        catch (Exception e) {
            FinPlanLogger.logError(className, 'createMessages', e, null); // the last parameter is the entity Id, which is not applicable here, since it is outside the loop
            RestContext.response.statusCode = 500;

            responseBody.put('success', false);
            responseBody.put('message', e.getStackTraceString());
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseBody));
        }
    }
}