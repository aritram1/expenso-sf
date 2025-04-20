public without sharing class QueueableExtractBeneficiaryAndAmount implements Queueable, Database.AllowsCallouts {

    private List<SMS__c> smsRecords;

    public static final String CLASS_NAME = 'QueueableExtractBeneficiaryAndAmount';

    public QueueableExtractBeneficiaryAndAmount(List<SMS__c> smsRecords) {
        this.smsRecords = smsRecords;
    }

    public void execute(QueueableContext context) {
        try {
            System.debug('Before extractBeneficiaryAndAmountFromSMS: ' + smsRecords);

            // Extract Beneficiary and Amount
            Map<String, Finance_Account__c> mapAccounts = Util.getAllAccounts();
            smsRecords = Util.extractBeneficiaryAndAmountFromSMS(smsRecords, mapAccounts);
            smsRecords = Util.populateProcessedInfo(smsRecords);
            System.debug('After extractBeneficiaryAndAmountFromSMS: ' + smsRecords);

            // Upsert the enriched SMS__c records into the database
            upsert smsRecords External_Id__c;
        } 
        catch (Exception e) {
            System.debug('Error in QueueableExtractBeneficiaryAndAmount: ' + e.getStackTraceString());
            FinPlanLogger.logError(CLASS_NAME, 'execute', e, null); // the last parameter is the entity Id, which is not available outside the loop
        }
        finally{
            // Chain the next Queueable
            System.enqueueJob(new QueueableExtractBalanceInfo(smsRecords));
        }
    }
}