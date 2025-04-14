public without sharing class QueueableEnrichAndUpsertSMS implements Queueable, Database.AllowsCallouts {

    private List<SMS__c> smsRecords;

    // Constructor to accept the SMS records
    public QueueableEnrichAndUpsertSMS(List<SMS__c> smsRecords) {
        this.smsRecords = smsRecords;
    }

    // Execute method for the Queueable
    public void execute(QueueableContext context) {
        try {
            System.debug('Before all=>' + smsRecords);

            // Call the first enrichment method
            smsRecords = Util.extractBeneficiaryAndAmountFromSMS(smsRecords);
            System.debug('after first smsRecords=>' + smsRecords);

            // Call the second enrichment method
            smsRecords = Util.extractBalanceInfo(smsRecords);
            System.debug('after second smsRecords=>' + smsRecords);

            // Call the third enrichment method
            smsRecords = Util.populateProcessedInfo(smsRecords);
            System.debug('after third smsRecords=>' + smsRecords);

            // Upsert the enriched SMS__c records into the database
            upsert smsRecords External_Id__c;

            System.debug('SMS records successfully enriched and inserted.');

        } 
        catch (DmlException dmlEx) {
            System.debug('DML Error inserting records: ' + dmlEx.getStackTraceString());
        } 
        catch (Exception e) {
            System.debug('Error processing records: ' + e.getStackTraceString());
        }
    }
}