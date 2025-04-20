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
            smsRecords = Util.populateProcessedInfo(smsRecords);
            System.debug('After extractBalanceInfo: ' + smsRecords);
            
            // Upsert the enriched SMS__c records into the database
            upsert smsRecords External_Id__c;
        } 
        catch (Exception e) {
            System.debug('Error in QueueableExtractBalanceInfo: ' + e.getStackTraceString());
            FinPlanLogger.logError(CLASS_NAME, 'execute', e, null); // the last parameter is the entity Id, which is not available outside the loop
        }
        finally{
            // Chain the next Queueable
            System.enqueueJob(new QueueablePopulateProcessedInfo(smsRecords));
        }
    }
}