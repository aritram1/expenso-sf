public without sharing class QueueablePopulateFinanceAccount implements Queueable, Database.AllowsCallouts {

    public static final String CLASS_NAME = 'QueueablePopulateFinanceAccount';
    
    private List<SMS__c> smsRecords;

    public QueueablePopulateFinanceAccount(List<SMS__c> smsRecords) {
        this.smsRecords = smsRecords;
    }

    public void execute(QueueableContext context) {
        try {
            System.debug('Before populateFinanceAccountFromSMS: ' + smsRecords);

            // Populate the Finance Account Id
            Map<String, Finance_Account__c> mapAccounts = Util.getAllAccounts();
            smsRecords = Util.populateFinanceAccountFromSMS(smsRecords, mapAccounts);
            System.debug('After populateFinanceAccountFromSMS: ' + smsRecords);

            // Upsert the enriched SMS__c records into the database
            upsert smsRecords External_Id__c;
        } 
        catch (Exception e) {
            System.debug('Error in QueueablePopulateFinanceAccount: ' + e.getStackTraceString());
            FinPlanLogger.logError(CLASS_NAME, 'execute', e, null); // the last parameter is the entity Id, which is not available outside the loop
        }
        finally{
            // Chain the next Queueable
            System.enqueueJob(new QueueableExtractBeneficiaryAndAmount(smsRecords));
        }
    }
}