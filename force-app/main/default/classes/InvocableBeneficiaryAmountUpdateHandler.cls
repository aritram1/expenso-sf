public with sharing class InvocableBeneficiaryAmountUpdateHandler {

    public static final String CLASS_NAME = 'InvocableBeneficiaryAmountUpdateHandler';

    // Invocable method that Flow or Process Builder can call
    @InvocableMethod(label='Update Beneficiary and Amount from SMS' description='Processes SMS records and delegates to SMSProcessor.')
    public static List<SMS__c> extractBeneficiaryAndAmountFromSMS(List<SMS__c> smsList) {

        List<SMS__c> result = new List<SMS__c>();

        try {
            // Ensure the list is not null or empty
            if (smsList == null || smsList.isEmpty()) {
                return null;
            }

            Map<String, Finance_Account__c> mapAccounts = Util.getAccounts(smsList);

            for (SMS__c sms : smsList) {
                String accountName = mapAccounts.get(sms.Finance_Account__c).Name.toUpperCase();
                SMS__c processedSMS = new SMS__c();

                if (accountName == 'HDFC SA') {
                    processedSMS = SMSProcessor.processForHDFCBankSA(sms);
                } else if (accountName == 'ICICI SA') {
                    processedSMS = SMSProcessor.processForICICIBankSA(sms);
                } else if (accountName == 'SBI SA') {
                    processedSMS = SMSProcessor.processForSBIBankSA(sms);
                } else if (accountName == 'ICICI CC') {
                    processedSMS = SMSProcessor.processForICICIBankCC(sms);
                } else if (accountName == 'ICICI AMAZON CC') {
                    processedSMS = SMSProcessor.processForICICIBankAmazonCC(sms);
                } else if (accountName == 'HDFC Rupay CC') {
                    processedSMS = SMSProcessor.processForHDFCBankRupayCC(sms);
                } else if (accountName == 'Amazon Wallet') {
                    processedSMS = SMSProcessor.processForAmazonWallet(sms);
                }
                // To be implemented, if required
                // else if(accountName == 'Kuvera'){
                //     processedSMS = SMSProcessor.processFor***(sms);
                // }
                // else if(accountName == 'Coin'){
                //     processedSMS = SMSProcessor.processFor***(sms);
                // }
                // else if(accountName == 'Zerodha'){
                //     processedSMS = SMSProcessor.processFor***(sms);
                // }
                // else if(accountName == 'Smallcase'){
                //     processedSMS = SMSProcessor.processFor***(sms);
                // }

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
    
}