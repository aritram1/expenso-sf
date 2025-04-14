@RestResource(urlMapping='/api/guest/sms/sync')
global with sharing class FinPlanGuestAPIController {
    
    // Constructor
    public FinPlanGuestAPIController() {
    }

    // POST method to handle incoming payload and create SMS__c records
    @HttpPost
    global static void syncSMSRecords() {
        // Parse the incoming JSON payload into a list of SMS__c objects
        List<SMS__c> smsRecords;
        try {
            if (RestContext.request.requestBody == null || String.isEmpty(RestContext.request.requestBody.toString())) {
                RestContext.response.statusCode = 400; // Bad Request
                RestContext.response.responseBody = Blob.valueOf('Request body is empty.');
                return;
            }
            String requestBody = RestContext.request.requestBody.toString();
            smsRecords = (List<SMS__c>) JSON.deserialize(requestBody, List<SMS__c>.class);
        } catch (Exception e) {
            // Handle JSON parsing errors
            RestContext.response.statusCode = 400; // Bad Request
            RestContext.response.responseBody = Blob.valueOf('Invalid payload: ' + e.getMessage());
            return;
        }

        // Enrich the SMS__c records
        try {
            if (!smsRecords.isEmpty()) {

                // for (SMS__c sms : smsRecords) {
                //     if (sms.Content__c != null) {
                //         sms.Content__c = sms.Content__c.replace('\n', '');
                //     }
                // }

                // Call the first enrichment method
                // smsRecords = InvocableBeneficiaryAmountUpdateHandler.extractBeneficiaryAndAmountFromSMS(smsRecords);

                // Call the second enrichment method
                // smsRecords = InvocableBalanceUpdateHandler.extractBalanceInfo(smsRecords);

                // Insert the enriched SMS__c records into the database
                insert smsRecords; 

                RestContext.response.statusCode = 201; // Created
                
                RestContext.response.responseBody = Blob.valueOf(JSON.serialize(smsRecords));
            } 
            else {
                RestContext.response.statusCode = 400; // Bad Request
                RestContext.response.responseBody = Blob.valueOf('Payload is empty.');
            }
        } 
        catch (DmlException dmlEx) {
            // Handle DML errors
            RestContext.response.statusCode = 500; // Internal Server Error
            RestContext.response.responseBody = Blob.valueOf('Error inserting records: ' + dmlEx.getStackTraceString());
        } 
        catch (Exception e) {
            // Handle other errors
            RestContext.response.statusCode = 500; // Internal Server Error
            RestContext.response.responseBody = Blob.valueOf('Error processing records: ' + e.getStackTraceString());
        }
    }
}