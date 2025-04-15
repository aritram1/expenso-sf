public with sharing class BankControllerSBI {

    public static final String CLASS_NAME = 'BankControllerSBI';

    public BankControllerSBI() {

    }

    // Process SMS for SBI Savings Account
    public static SMS__c processForSBIBankSA(SMS__c inputSMS) {
        SMS__c sms = inputSMS.clone(false, true);
        try {
            List<String> contentArray = sms.Content__c?.split(' ');

            // Credit 1
            if (sms.Content__c.contains('Your a/c no. XXXXXXXX6414 is credited by')) {
                String amount = contentArray[9].replace(',', '').replace('Rs.', '');
                sms.Amount__c = Decimal.valueOf(amount ?? '0');
                sms.beneficiary_name__c = Util.toCamelCase(sms.Content__c.split('by')[2].split('(')[0].trim());
                if (sms.Content__c.contains('IMPS')) {
                    sms.Payment_Via__c = 'IMPS';
                    sms.Payment_Reference__c = sms.Content__c.split('IMPS Ref no')[1].split(')')[0].trim();
                }
            }
            // Debit 1
            else if (sms.Content__c.contains('Your a/c no. XXXXXXXX6414 is debited for')) {
                String amount = contentArray[9].replace(',', '').replace('Rs.', '');
                sms.Amount__c = Decimal.valueOf(amount ?? '0');
                sms.beneficiary_name__c = Util.toCamelCase(sms.Content__c.split('and')[1].split('credited')[0].trim());
            }
        } catch (Exception e) {
            FinPlanLogger.logError(CLASS_NAME, 'processForSBIBankSA', e, null);
        }
        return sms;
    }

    // Process SMS for SBI Balance Update
    public static SMS__c processForSBIBankSA_BalanceUpdate(SMS__c sms) {
        SMS__c smsOutput = sms.clone(false, true);
        try {
            if (sms.Content__c.contains('Your a/c no. XXXXXXXX6414 is credited by')) {
                smsOutput.SA_Available_Balance__c = sms.Content__c.split('Avl Bal Rs ')[1].split('.-')[0].replace(',', '');
            }
        } catch (Exception e) {
            FinPlanLogger.logError(CLASS_NAME, 'processForSBIBankSA_BalanceUpdate', e, null);
        }
        return smsOutput;
    }
}