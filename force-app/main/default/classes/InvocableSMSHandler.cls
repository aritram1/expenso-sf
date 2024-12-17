public with sharing class InvocableSMSHandler {

    public static final String CLASS_NAME = 'InvocableSMSHandler';

    // Invocable method that Flow or Process Builder can call
    @InvocableMethod(label='Update Beneficiary and Amount from SMS' description='Processes SMS records and delegates to SMSHandlerBank.')
    public static List<Transaction_Platform_Event__e> extractBeneficiaryAndAmountFromTransactionPE(List<Transaction_Platform_Event__e> txnPEList) {

        List<Transaction_Platform_Event__e> outputList = new List<Transaction_Platform_Event__e>();

        try{

            Map<String, Finance_Account__c> mapAccounts = getAccounts(txnPEList);

            
            // Ensure the list is not null or empty
            if (txnPEList == null || txnPEList.isEmpty()) {
                return null;
            }

            for(Transaction_Platform_Event__e txnPE : txnPEList){
            
                String accountName = mapAccounts.get(txnPE.Finance_Account__c).name;
                Transaction_Platform_Event__e txnPE1 = new Transaction_Platform_Event__e();

                if(accountName == 'HDFC SA'){
                    txnPE1 = SMSHandlerBank.processForHDFCBankSA(txnPE);
                }
                else if(accountName == 'ICICI SA'){
                    txnPE1 = SMSHandlerBank.processForICICIBankSA(txnPE);
                }
                else if(accountName == 'SBI SA'){
                    txnPE1 = SMSHandlerBank.processForSBIBankSA(txnPE);
                }
                else if(accountName == 'ICICI CC'){
                    txnPE1 = SMSHandlerBank.processForICICIBankCC(txnPE);   
                }
                else if(accountName == 'ICICI AMAZON CC'){
                    txnPE1 = SMSHandlerBank.processForICICIBankAmazonCC(txnPE);
                }
                else if(accountName == 'HDFC Rupay CC'){
                    txnPE1 = SMSHandlerBank.processForHDFCBankRupayCC(txnPE);
                }
                else if(accountName == 'Amazon Wallet'){
                    txnPE1 = SMSHandlerBank.processForAmazonWallet(txnPE);
                }
                // To be implemented
                // else if(accountName == 'Kuvera'){
                //     txnPE = SMSHandlerBank.processForAmazonWallet(txnPE);
                // }
                // else if(accountName == 'Coin'){
                //     txnPE = SMSHandlerBank.processForAmazonWallet(txnPE);
                // }
                // else if(accountName == 'Zerodha'){
                //     txnPE = SMSHandlerBank.processForAmazonWallet(txnPE);
                // }
                // else if(accountName == 'Smallcase'){
                //     txnPE = SMSHandlerBank.processForAmazonWallet(txnPE);
                // }

                // Fix the minor name differences for beneficiaries
                // This method does not have any DML, so we can use within a loop
                txnPE1 = BeneficiaryHandler.fixBeneficiaryName(txnPE1);

                outputList.add(txnPE1);
            }

            // Also update the beneficiary Name with beneficiary Id
            // This method contains a DML so we have to use it outside loop
            outputList = BeneficiaryHandler.updateBeneficiary(outputList);

        }
        catch(Exception e){
            FinPlanLogger.logError(CLASS_NAME, 'extractBeneficiaryAndAccount', e);
        }
        return outputList;
    }

    public static Map<String, Finance_Account__c> getAccounts(List<SMS__c> smsList) {
        Map<String, Finance_Account__c> allAccountsMap = new Map<String, Finance_Account__c>();
        List<String> allAccountIds = new List<String>();
        for(SMS__c sms : smsList) {
            if(sms.Finance_Account__c != null){
                allAccountIds.add(sms.Finance_Account__c);
            }
        }
        List<Finance_Account__c> allAccounts = [SELECT id, name from Finance_Account__c where id in :allAccountIds];
        
        for(Finance_Account__c fa : allAccounts){
            allAccountsMap.put(fa.id, fa);
        }
        return allAccountsMap;
    }
}