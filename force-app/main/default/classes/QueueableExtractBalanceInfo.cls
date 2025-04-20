public without sharing class QueueableExtractBalanceInfo implements Queueable, Database.AllowsCallouts {

    public static final String CLASS_NAME = 'QueueableExtractBalanceInfo';
    
    private List<SMS__c> smsRecords;

    public QueueableExtractBalanceInfo(List<SMS__c> smsRecords) {
        this.smsRecords = smsRecords;
    }

    public void execute(QueueableContext context) {
        try {
            System.debug('Before extractBalanceInfo: ' + smsRecords);

            // Extract Balance Info
            smsRecords = Util.extractBalanceInfo(smsRecords);
            System.debug('After extractBalanceInfo: ' + smsRecords);
            
            // Upsert the enriched SMS__c records into the database
            upsert smsRecords External_Id__c;

            // Chain the next Queueable
            System.enqueueJob(new QueueablePopulateProcessedInfo(smsRecords));
        } 
        catch (Exception e) {
            System.debug('Error in QueueableExtractBalanceInfo: ' + e.getStackTraceString());
            FinPlanLogger.logError(CLASS_NAME, 'extractBalanceInfo', e, null); // the last parameter is the entity Id, which is not available outside the loop
        }
    }
}