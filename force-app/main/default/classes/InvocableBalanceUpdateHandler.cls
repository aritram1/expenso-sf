public with sharing class InvocableBalanceUpdateHandler {

    public static final String CLASS_NAME = 'InvocableBalanceUpdateHandler.';

    // Invocable method that Flow or Process Builder can call
    @InvocableMethod(label='Extracts Balance Information' description='Processes SMS record and extracts balance')
    public static List<SMS__c> extractBalanceInfo(List<SMS__c> smsList) {

        List<SMS__c> outputList = new List<SMS__c>();

        try {
            Map<String, Finance_Account__c> mapAccounts = Util.getAccounts(smsList);

            // Ensure the list is not null or empty
            if (smsList == null || smsList.isEmpty()) {
                return null;
            }

            for (SMS__c sms : smsList) {
                String accountName = mapAccounts.get(sms.Finance_Account__c).Name.toUpperCase();
                SMS__c smsOutput = new SMS__c();

                if (accountName == 'HDFC SA') {
                    smsOutput = SMSProcessor.processForHDFCBankSA_BalanceUpdate(sms);
                } else if (accountName == 'ICICI SA') {
                    smsOutput = SMSProcessor.processForICICIBankSA_BalanceUpdate(sms);
                } else if (accountName == 'SBI SA') {
                    smsOutput = SMSProcessor.processForSBIBankSA_BalanceUpdate(sms);
                } else if (accountName == 'ICICI CC') {
                    smsOutput = SMSProcessor.processForICICIBankCC_BalanceUpdate(sms);
                } else if (accountName == 'ICICI AMAZON CC') {
                    smsOutput = SMSProcessor.processForICICIBankAmazonCC_BalanceUpdate(sms);
                }
                // To be implemented, if required
                // else if(accountName == 'Kuvera'){
                //     smsOutput = SMSProcessor.SMSProcessor.processFor***_BalanceUpdate(sms);
                // }
                // else if(accountName == 'Coin'){
                //     smsOutput = SMSProcessor.SMSProcessor.processFor***_BalanceUpdate(sms);
                // }
                // else if(accountName == 'Zerodha'){
                //     smsOutput = SMSProcessor.SMSProcessor.processFor***_BalanceUpdate(sms);
                // }
                // else if(accountName == 'Smallcase'){
                //     smsOutput = SMSProcessor.SMSProcessor.processFor***_BalanceUpdate(sms);
                // }
                outputList.add(smsOutput);
            }

        } catch (Exception e) {
            FinPlanLogger.logError(CLASS_NAME, 'extractBalanceInfo', e);
        }
        return outputList;
    }
}