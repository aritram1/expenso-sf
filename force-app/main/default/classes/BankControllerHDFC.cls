public with sharing class BankControllerHDFC {

    public static final String CLASS_NAME = 'BankControllerHDFC';

    // Process SMS for HDFC Savings Account
    public static SMS__c processForHDFCBankSA(SMS__c inputSMS) {
        SMS__c sms = inputSMS.clone(false, true);
        try {
            List<String> contentArray = sms.Content__c?.split(' ');

            // Credit 1
            if (sms.Content__c.contains('deposited')) {
                String amount = contentArray[2].replace(',', '');
                sms.amount__c = Decimal.valueOf(amount ?? '0');
                sms.Payment_Via__c = 'UPI';
                sms.beneficiary_name__c = Util.toCamelCase(sms.Content__c.split('for')[1].split('.Avl bal')[0].trim());
            }
        } catch (Exception e) {
            FinPlanLogger.logError(CLASS_NAME, 'processForHDFCBankSA', e, null);
        }
        return sms;
    }

    // Process SMS for HDFC Balance Update
    public static SMS__c processForHDFCBankSA_BalanceUpdate(SMS__c sms) {
        SMS__c smsOutput = sms.clone(false, true);
        try {
            if (sms.Content__c.contains('deposited')) {
                smsOutput.SA_Available_Balance__c = sms.Content__c.split('.Avl bal INR ')[1].split('. Cheque deposits')[0];
            }
        } catch (Exception e) {
            FinPlanLogger.logError(CLASS_NAME, 'processForHDFCBankSA_BalanceUpdate', e, null);
        }
        return smsOutput;
    }


    public static SMS__c processForHDFCBankRupayCC(SMS__c inputSMS){
        
        // Create a new writable instance of the platform event
        SMS__c sms = inputSMS.clone(false, true); // Util.cloneTransactionPE(inputSMS);     
        
        try{

            List<String> contentArray = new List<String>();
            contentArray = sms.Content__c?.split(' ');

            // debit 1
            if(sms.Content__c.contains('On HDFC Bank Card 2004')){
                String amount =  contentArray[1].replace('Rs.', '').replace(' ', '');
                sms.amount__c = Decimal.valueOf(amount ?? '0');
                sms.beneficiary_name__c = sms.Content__c.split('At')[1].split('by')[0];
                sms.Payment_Reference__c = sms.Content__c.toUpperCase().split('AT')[1].split('BY')[1].replace('UPI', '');
                if(sms.Content__c.toUpperCase().contains('UPI')){
                    sms.Payment_Via__c = 'UPI';
                }
            }
        }
        catch(Exception e){
            FinPlanLogger.logError(CLASS_NAME, 'processForHDFCBankRupayCC', e, null); // the last parameter is the entity Id, which is not available outside the loop
        }
        return sms;
    }
}