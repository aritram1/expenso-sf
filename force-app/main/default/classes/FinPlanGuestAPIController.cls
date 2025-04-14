@RestResource(urlMapping='/api/guest/sms/sync')
global with sharing class FinPlanGuestAPIController {

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
        } 
        catch (Exception e) {
            // Handle JSON parsing errors
            RestContext.response.statusCode = 400; // Bad Request
            RestContext.response.responseBody = Blob.valueOf('Invalid payload: ' + e.getMessage());
            return;
        }

        // Enrich the SMS__c records
        try {
            if (!smsRecords.isEmpty()) {

                System.debug('Before all=>' + smsRecords);

                System.enqueueJob(new QueueableEnrichAndUpsertSMS(smsRecords));
                RestContext.response.statusCode = 202; // Accepted
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

// request payload sample
// [
//     {
//         "Content__c": "Money Transfer:Rs 73.00 from HDFC Bank A/c **9560 on 01-01-24 to BISWAJIT DAS UPI: 400147226121 Not you Call 18002586161",
//         "Received_At__c": "2025-04-13T09:55:00.000Z",
//         "Device__c" : "CPH2413",
//         "Sender__c" : "AD-HDFCBK",
//         "Finance_Account__c" : "a03Qy00000CCLY2IAP"
//     },
//     {
//         "Content__c": "Amt Sent Rs.825.82 From HDFC Bank A/C *9560 To Jio Postpaid Bill Payment On 08-06 Ref 416092612564 Not You? Call 18002586161/SMS BLOCK UPI to 7308080808",
//         "Received_At__c": "2025-04-12T09:55:00.000Z",
//         "Device__c" : "CPH2413",
//         "Sender__c" : "AD-HDFCBK",
//         "Finance_Account__c" : "a03Qy00000CCLY2IAP"
//     }
// ]