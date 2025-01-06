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
                String accountNameInUpperCase = mapAccounts.get(sms.Finance_Account__c).Name.toUpperCase();
                SMS__c smsOutput = new SMS__c();

                try {
                    switch on accountNameInUpperCase {
                        when 'HDFC SA' {
                            smsOutput = SMSProcessor.processForHDFCBankSA_BalanceUpdate(sms);
                        }
                        when 'ICICI SA' {
                            smsOutput = SMSProcessor.processForICICIBankSA_BalanceUpdate(sms);
                        }
                        when 'SBI SA' {
                            smsOutput = SMSProcessor.processForSBIBankSA_BalanceUpdate(sms);
                        }
                        when 'ICICI CC' {
                            smsOutput = SMSProcessor.processForICICIBankCC_BalanceUpdate(sms);
                        }
                        when 'ICICI AMAZON CC' {
                            smsOutput = SMSProcessor.processForICICIBankAmazonCC_BalanceUpdate(sms);
                        }
                        // To be implemented, if required
                        // when 'KUVERA' {
                        //     smsOutput = SMSProcessor.SMSProcessor.processFor***_BalanceUpdate(sms);
                        // }
                        // when 'COIN' {
                        //     smsOutput = SMSProcessor.SMSProcessor.processFor***_BalanceUpdate(sms);
                        // }
                        // when 'ZERODHA' {
                        //     smsOutput = SMSProcessor.SMSProcessor.processFor***_BalanceUpdate(sms);
                        // }
                        // when 'SMALLCASE' {
                        //     smsOutput = SMSProcessor.SMSProcessor.processFor***_BalanceUpdate(sms);
                        // }
                    }
                }
                catch(Exception e){
                    FinPlanLogger.logError(CLASS_NAME, 'extractBalanceInfo', e, sms); 
                }
                outputList.add(smsOutput);
            }

        } catch (Exception e) {
            FinPlanLogger.logError(CLASS_NAME, 'extractBalanceInfo', e, null); // the last parameter is the entity Id, which is not available outside the loop
        }
        return outputList;
    }
}