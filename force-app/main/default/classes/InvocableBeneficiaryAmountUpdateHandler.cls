public with sharing class InvocableBeneficiaryAmountUpdateHandler {

    public static final String CLASS_NAME = 'InvocableBeneficiaryAmountUpdateHandler';

    // Invocable method that Flow or Process Builder can call
    @InvocableMethod(label='Update Beneficiary and Amount from SMS' description='Processes SMS records and delegates to SMSHandlerBank.')
    public static List<SMS__c> extractBeneficiaryAndAmountFromSMS(List<SMS__c> smsList) {

        List<SMS__c> result = new List<SMS__c>();

        try {
            // Ensure the list is not null or empty
            if (smsList == null || smsList.isEmpty()) {
                return null;
            }

            Map<String, Finance_Account__c> mapAccounts = getAccounts(smsList);

            for (SMS__c sms : smsList) {
                String accountName = mapAccounts.get(sms.Finance_Account__c).Name;
                SMS__c processedSMS = new SMS__c();

                if (accountName == 'HDFC SA') {
                    processedSMS = SMSHandlerBank.processForHDFCBankSA(sms);
                } else if (accountName == 'ICICI SA') {
                    processedSMS = SMSHandlerBank.processForICICIBankSA(sms);
                } else if (accountName == 'SBI SA') {
                    processedSMS = SMSHandlerBank.processForSBIBankSA(sms);
                } else if (accountName == 'ICICI CC') {
                    processedSMS = SMSHandlerBank.processForICICIBankCC(sms);
                } else if (accountName == 'ICICI AMAZON CC') {
                    processedSMS = SMSHandlerBank.processForICICIBankAmazonCC(sms);
                } else if (accountName == 'HDFC Rupay CC') {
                    processedSMS = SMSHandlerBank.processForHDFCBankRupayCC(sms);
                } else if (accountName == 'Amazon Wallet') {
                    processedSMS = SMSHandlerBank.processForAmazonWallet(sms);
                }

                // Fix the minor name differences for beneficiaries
                // This method does not have any DML, so we can use it within a loop
                processedSMS = BeneficiaryHandler.fixBeneficiaryName(processedSMS);

                result.add(processedSMS);
            }

            // Also update the beneficiary Name with beneficiary Id
            // This method contains a DML so we have to use it outside the loop
            result = BeneficiaryHandler.updateBeneficiary(result);

        } catch (Exception e) {
            FinPlanLogger.logError(CLASS_NAME, 'extractBeneficiaryAndAmountFromSMS', e);
        }
        return result;
    }

    public static Map<String, Finance_Account__c> getAccounts(List<SMS__c> smsList) {
        Map<String, Finance_Account__c> allAccountsMap = new Map<String, Finance_Account__c>();
        List<String> allAccountIds = new List<String>();

        for (SMS__c sms : smsList) {
            if (sms.Finance_Account__c != null) {
                allAccountIds.add(sms.Finance_Account__c);
            }
        }

        List<Finance_Account__c> allAccounts = [
            SELECT Id, Name
            FROM Finance_Account__c
            WHERE Id IN :allAccountIds
        ];

        for (Finance_Account__c fa : allAccounts) {
            allAccountsMap.put(fa.Id, fa);
        }
        return allAccountsMap;
    }
}
