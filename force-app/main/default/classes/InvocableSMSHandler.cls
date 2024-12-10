public with sharing class InvocableSMSHandler {

    // Invocable method that Flow or Process Builder can call
    @InvocableMethod(label='Update Beneficiary and Amount from SMS' description='Processes SMS records and delegates to SMSHandlerBank.')
    public static List<Transaction_Platform_Event__e> extractBeneficiaryAndAccount(List<Transaction_Platform_Event__e> txnPEList) {
        
        List<Transaction_Platform_Event__e> outputList = new List<Transaction_Platform_Event__e>();

        try{

        Map<String, Finance_Account__c> mapAccounts = new Map<String, Finance_Account__c>();
            
            mapAccounts = getAccounts(txnPEList);
            
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
                outputList.add(txnPE1);
            }

            // Also update the beneficiary Name with beneficiary Id
            outputList = BeneficiaryHandler.updateBeneficiary(outputList);

        }
        catch(Exception e){
            FinPlanLogger.logError('extractBeneficiaryAndAccount', e);
        }
        return outputList;
    }

    public static Map<String, Finance_Account__c> getAccounts(List<Transaction_Platform_Event__e> txnPEList) {
        Map<String, Finance_Account__c> allAccountsMap = new Map<String, Finance_Account__c>();
        List<String> allAccountIds = new List<String>();
        for(Transaction_Platform_Event__e pe : txnPEList) {
            if(pe.Finance_Account__c != null){
                allAccountIds.add(pe.Finance_Account__c);
            }
        }
        List<Finance_Account__c> allAccounts = [SELECT id, name from Finance_Account__c where id in :allAccountIds];
        
        for(Finance_Account__c fa : allAccounts){
            allAccountsMap.put(fa.id, fa);
        }
        return allAccountsMap;
    }
}