public without sharing class QueueablePopulateProcessedInfo implements Queueable, Database.AllowsCallouts {

    public static final String CLASS_NAME = 'QueueablePopulateProcessedInfo';
    
    private List<SMS__c> smsRecords;

    public QueueablePopulateProcessedInfo(List<SMS__c> smsRecords) {
        this.smsRecords = smsRecords;
    }

    public void execute(QueueableContext context) {
        try {
            System.debug('Before populateProcessedInfo: ' + smsRecords);

            // Populate Processed Info
            smsRecords = Util.populateProcessedInfo(smsRecords);
            System.debug('After populateProcessedInfo: ' + smsRecords);

            // Upsert the enriched SMS__c records into the database
            upsert smsRecords External_Id__c;

            System.debug('SMS records successfully enriched and upserted.');
        } 
        catch (Exception e) {
            System.debug('Error in QueueablePopulateProcessedInfo: ' + e.getStackTraceString());
            FinPlanLogger.logError(CLASS_NAME, 'extractBalanceInfo', e, null); // the last parameter is the entity Id, which is not available outside the loop
        }
    }
}