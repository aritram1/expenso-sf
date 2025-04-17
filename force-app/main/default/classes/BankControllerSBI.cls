public with sharing class BankControllerSBI {

    public static final String CLASS_NAME = 'BankControllerSBI';

        // This method enriches the sms record if it's from SBI
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static SMS__c processForSBIBankSA(SMS__c inputSMS){
        
        // Create a new writable instance of the platform event
        SMS__c sms = inputSMS.clone(false, true); // Util.cloneTransactionPE(inputSMS); 
        
        try{

            List<String> contentArray = new List<String>();
            contentArray = sms.Content__c?.split(' ');
            
            // credit 1
            if(sms.Content__c.contains('Your a/c no. XXXXXXXX6414 is credited by')){
                String amount =  contentArray[9].replace(',' , '').replace('Rs.', '');
                sms.Amount__c = Decimal.valueOf(amount ?? '0');

                String modifiedContent = sms.Content__c.replace('(', 'START_BRACKET').replace(')', 'END_BRACKET');
                sms.beneficiary_name__c = modifiedContent.split('by')[2].split('START_BRACKET')[0];
                sms.beneficiary_name__c = Util.toCamelCase(sms.beneficiary_name__c); // convert to camel case for better readability
                if(modifiedContent.contains('IMPS')){
                    sms.Payment_Via__c = 'IMPS';
                    sms.Payment_Reference__c = modifiedContent.split('START_BRACKET')[1].split('END_BRACKET')[0].replace('IMPS Ref no', '').trim();
                }
            }
            // credit 2
            else if(sms.Content__c.startsWith('Your A/C XXXXX816414 has credit')){
                String amount =  sms.Content__c.split('of Rs ')[1].split(' on ')[0].replace(',', '');
                sms.Amount__c = Decimal.valueOf(amount ?? '0');

                if(sms.Content__c.contains('IMPS')) { 
                    sms.Payment_Via__c = 'IMPS'; 
                }
                sms.beneficiary_name__c = sms.Content__c.split(' of Rs ')[0].split('has credit for')[1];
            }
            // credit 3
            else if(sms.Content__c.startsWith('Your A/C XXXXX816414 has credit for')){
                sms.beneficiary_name__c = sms.Content__c.split(' of Rs ')[0].split('has credit for ')[1].trim();
                sms.beneficiary_name__c = sms.Content__c.split(' of Rs ')[1].split(' on ')[0].replace(',', '').trim();

            }
            // debit 1
            else if(sms.Content__c.contains('Your a/c no. XXXXXXXX6414 is debited for')){
                String amount =  contentArray[9].replace(',' , '').replace('Rs.', '');
                sms.Amount__c = Decimal.valueOf(amount ?? '0');

                sms.beneficiary_name__c = sms.Content__c.split('and')[1].split('credited')[0].trim();
                sms.beneficiary_name__c = Util.toCamelCase(sms.beneficiary_name__c); // convert to camel case for better readability
            }
            // debit 2
            else if(sms.Content__c.startsWith('Dear Customer, Your A/C XXXXX816414 has a debit')){
                String amount =  contentArray[12].replace(',', '');
                sms.Amount__c = Decimal.valueOf(amount ?? '0');

                sms.beneficiary_name__c = 'SBI Internal Transfer';
            }
            // debit via yono app
            else if(sms.Content__c.contains('Your A/C XXXXX816414 Debited INR')){
                String amount =  contentArray[5].replace(',', '');
                sms.Amount__c = Decimal.valueOf(amount ?? '0');

                sms.beneficiary_name__c = sms.Content__c.split('Avl Balance INR')[0].split('Transferred to')[1].trim();
                if(sms.beneficiary_name__c.endsWith('.')){
                    sms.beneficiary_name__c = sms.beneficiary_name__c.substring(0, sms.beneficiary_name__c.length()-1);
                }
                sms.beneficiary_name__c = Util.toCamelCase(sms.beneficiary_name__c); // convert to camel case for better readability
                sms.Payment_Via__c = 'IMPS';
            }
            // atm withdrawal
            else if(sms.Content__c.contains('withdrawn at SBI ATM')){
                String amount =  contentArray[3].replace(',' , '').replace('Rs.', '');
                sms.Amount__c = Decimal.valueOf(amount ?? '0');

                sms.Payment_Via__c = 'ATM';
                sms.beneficiary_name__c = 'SBI ATM withdrawal';
                sms.beneficiary_name__c = Util.toCamelCase(sms.beneficiary_name__c); // convert to camel case for better readability
                sms.Payment_Reference__c = contentArray[15];
                if(sms.Payment_Reference__c.endsWith('.')){
                    sms.Payment_Reference__c = sms.Payment_Reference__c.substring(0, sms.Payment_Reference__c.length()-1);
                }
            }
        }
        catch(Exception e){
            FinPlanLogger.logError(CLASS_NAME, 'processForHDFCBankSA', e, null); // the last parameter is the entity Id, which is not available outside the loop
        }
        return sms;
    }
    // End method
    
    // Processes SMS for SBI Bank Savings Account
    public static SMS__c processForSBIBankSA_BalanceUpdate(SMS__c sms) {
        SMS__c smsOutput = new SMS__c();

        try {
            if (sms.Content__c.contains('Your a/c no. XXXXXXXX6414 is credited by')) {
                smsOutput.SA_Available_Balance__c = sms.Content__c.split('Avl Bal Rs ')[1].split('.-')[0].replace(',', '');
            } else if (sms.Content__c.startsWith('Dear Customer, Your A/C XXXXX816414 has a debit')) {
                smsOutput.SA_Available_Balance__c = sms.Content__c.split('Avl Bal Rs ')[1].split('.-')[0].replace(',', '');
            } else if(sms.Content__c.startsWith('Your A/C XXXXX816414 has credit')){
                smsOutput.SA_Available_Balance__c = sms.Content__c.split('Avl Bal Rs ')[1].split('.-')[0].replace(',' ,'');
            } else if(sms.Content__c.startsWith('Dear Customer, Your A/C XXXXX816414 has a debit')){
                smsOutput.SA_Available_Balance__c = sms.Content__c.split('Avl Bal Rs ')[1].split('.-')[0].replace(',', '');
            } else if(sms.Content__c.contains('Your A/C XXXXX816414 Debited INR')){
                smsOutput.SA_available_balance__c = sms.Content__c.split('Avl Balance INR')[1].split('-')[0].replace(',', '');

            } else if(sms.Content__c.contains('withdrawn at SBI ATM')){
                smsOutput.SA_available_balance__c = sms.Content__c.split(' ')[18].replace('Rs.', '');
                if(smsOutput.SA_available_balance__c.endsWith('.')){
                    smsOutput.SA_available_balance__c = smsOutput.SA_available_balance__c.substring(0, smsOutput.SA_available_balance__c.length()-1);
                }
            }
        } catch (Exception e) {
            FinPlanLogger.logError(CLASS_NAME, 'InvocableBalanceUpdateHandler.processForSBIBankSA', e, null); // the last parameter is the entity Id, which is not available outside the loop
        }

        return smsOutput;
    }
}