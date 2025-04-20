public without sharing class QueueableEnrichAndUpsertSMS implements Queueable, Database.AllowsCallouts {

    public static final String CLASS_NAME = 'QueueableEnrichAndUpsertSMS';
    
    private List<SMS__c> smsRecords;
    // Separate records into insert and update lists
    List<SMS__c> recordsToInsert = new List<SMS__c>();
    List<SMS__c> recordsToUpdate = new List<SMS__c>();

    // Constructor to accept the SMS records
    public QueueableEnrichAndUpsertSMS(List<SMS__c> smsRecords) {
        this.smsRecords = smsRecords;
    }

    // Execute method for the Queueable
    public void execute(QueueableContext context) {
        try {
            System.debug('Before all=>' + smsRecords);
            System.enqueueJob(new QueueablePopulateFinanceAccount(smsRecords));
        }
        catch (Exception e) {
            System.debug('Error processing records: ' + e.getStackTraceString());
            FinPlanLogger.logError(CLASS_NAME, 'extractBalanceInfo', e, null); // the last parameter is the entity Id, which is not available outside the loop
        }
    }



    // Execute method for the Queueable
    // public void execute(QueueableContext context) {
    //     try {
    //         System.debug('Before all=>' + smsRecords);

    //         // Call the first enrichment method
    //         // Populate the Finance Account Id
    //         Map<String, Finance_Account__c> mapAccounts = Util.getAllAccounts();
    //         smsRecords = Util.populateFinanceAccountFromSMS(smsRecords, mapAccounts);
    //         System.debug('after first smsRecords=>' + smsRecords);

    //         System.enqueueJob(QueueableEnrichAndUpsertSMS);

    //         // Call the second enrichment method
    //         smsRecords = Util.extractBeneficiaryAndAmountFromSMS(smsRecords, mapAccounts);
    //         System.debug('after second smsRecords=>' + smsRecords);
            
    //         // Call the third enrichment method
    //         smsRecords = Util.extractBalanceInfo(smsRecords);
    //         System.debug('after third smsRecords=>' + smsRecords);
    //         // Call the last enrichment method
    //         smsRecords = Util.populateProcessedInfo(smsRecords);
    //         System.debug('after last smsRecords=>' + smsRecords);

    //         // Upsert the enriched SMS__c records into the database
    //         upsert smsRecords External_Id__c;
    //         // upsertSMSRecords(smsRecords);

    //         System.debug('SMS records successfully enriched and inserted.');

    //     } 
    //     catch (DmlException dmlEx) {
    //         System.debug('DML Error inserting records: ' + dmlEx.getStackTraceString());
    //     } 
    //     catch (Exception e) {
    //         System.debug('Error processing records: ' + e.getStackTraceString());
    //     }
    // }

    // // Fallback method when upsert method is not working in Salesforce
    // public static void upsertRecords(List<SMS__c> smsList){
        
    //     if (smsList == null || smsList.isEmpty()) {
    //         return;
    //     }

    //     // Query existing records based on External_Id__c
    //     Map<String, SMS__c> existingRecordsMap = new Map<String, SMS__c>();
        
    //     List<String> externalIdList = new List<String>();
    //     for(SMS__c sms : smsList){
    //         externalIdList.add(sms.External_Id__c);
    //     }
    //     for (SMS__c existingRecord : [SELECT Id, External_Id__c FROM SMS__c WHERE External_Id__c IN :externalIdList]){
    //         existingRecordsMap.put(existingRecord.External_Id__c, existingRecord);
    //     }

    //     for (SMS__c sms : smsList) {
    //         if (existingRecordsMap.containsKey(sms.External_Id__c)) {
    //             SMS__c existingRecord = existingRecordsMap.get(sms.External_Id__c);
    //             sms.Id = existingRecord.Id; // Set the Id for update
    //             recordsToUpdate.add(sms);
    //         } 
    //         else {
    //             recordsToInsert.add(sms);
    //         }
    //     }

    //     // Perform DML operations
    //     if (!recordsToInsert.isEmpty()) {
    //         insert recordsToInsert;
    //     }
    //     if (!recordsToUpdate.isEmpty()) {
    //         update recordsToUpdate;
    //     }

    // }
}