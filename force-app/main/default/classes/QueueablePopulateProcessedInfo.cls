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

            // Also upsert the Transaction__c records
            upsertTransactions(smsRecords);

        } 
        catch (Exception e) {
            System.debug('Error in QueueablePopulateProcessedInfo: ' + e.getStackTraceString());
            FinPlanLogger.logError(CLASS_NAME, 'execute', e, null); // the last parameter is the entity Id, which is not available outside the loop
        }
        finally {
            System.debug('Inside finally block of process completion queueable');
        }
    }

    public static void upsertTransactions(List<SMS__c> smsRecords) {
        List<Transaction__c> transactionsToUpsert = new List<Transaction__c>();
        List<Finance_Account__c> financeAccountsToUpdate = new List<Finance_Account__c>();
        for (SMS__c sms : smsRecords) {
            if (sms.Create_Transaction__c == true) {
                Transaction__c txn = new Transaction__c();
                txn.External_Id__c = sms.External_Id__c;
                txn.SMS__c = sms.Id;
                txn.Amount__c = sms.Amount__c;
                txn.Type__c = sms.Type__c; // Assuming Type__c is derived from SMS
                txn.Transaction_Date__c = sms.Transaction_Date__c;
                txn.Beneficiary__c = sms.Beneficiary__c;
                txn.Finance_Account__c = sms.Finance_Account__c;
                txn.Beneficiary_Name__c = sms.Beneficiary_Name__c;
                txn.Payment_Reference__c = sms.Payment_Reference__c;
                txn.Payment_Via__c = sms.Payment_Via__c;
                // txn.Investment__c = sms.Investment__c;
                // txn.Related_Contact__c = sms.Related_Contact__c;
                transactionsToUpsert.add(txn);
            }
            if(sms.Balance_Update__c == true){
                Finance_Account__c financeAccount = new Finance_Account__c();
                financeAccount.Id = sms.Finance_Account__c;
                if(sms.SA_Available_Balance__c != null){
                    financeAccount.SA_Last_Balance__c = Decimal.valueOf(sms.SA_Available_Balance__c);
                }
                if(sms.CC_Available_Balance__c != null){
                    financeAccount.CC_Available_Limit__c = Decimal.valueOf(sms.CC_Available_Balance__c);
                }
                financeAccountsToUpdate.add(financeAccount);
            }
        }
        if (!transactionsToUpsert.isEmpty()) {
            upsert transactionsToUpsert External_Id__c;
        }
        if (!financeAccountsToUpdate.isEmpty()) {
            update financeAccountsToUpdate;
        }
        System.debug('Upserted Transactions: ' + transactionsToUpsert);
        System.debug('Updated Finance Accounts: ' + financeAccountsToUpdate);
    }
}