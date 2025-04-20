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
            smsRecords = Util.populateProcessCompletionInfo(smsRecords);
            System.debug('After populateProcessCompletionInfo: ' + smsRecords);

            // Upsert the enriched SMS__c records into the database
            upsert smsRecords External_Id__c;
        } 
        catch (Exception e) {
            System.debug('Error in QueueablePopulateProcessedInfo: ' + e.getStackTraceString());
            FinPlanLogger.logError(CLASS_NAME, 'execute', e, null); // the last parameter is the entity Id, which is not available outside the loop
        }
        finally{
            System.debug('Inside finally block of process completion queueable');
        }
    }
}