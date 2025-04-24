
public with sharing class WalletControllerAmazonPay {
    
    public static final String CLASS_NAME = 'WalletControllerAmazonPay';
    
    public WalletControllerAmazonPay() {

    }

    public static SMS__c processForAmazonWallet(SMS__c inputSMS){
        SMS__c sms = inputSMS.clone(false, true); // Util.cloneTransactionPE(inputSMS); 
        return sms;
    }

    // public static SMS__c processForOthers(SMS__c sms, Map<String, Finance_Account__c> allBankAccountsMap){
        
    //     if(sms.content__c.toUpperCase().contains('AMAZON PAY')){
    //         sms.type__c = 'balance_update';
    //         sms.Balance_Update__c = true;
    //         sms.From_Account__c = allBankAccountsMap.get('AMAZON-WA').Id;
            
    //         if(sms.content__c.contains('added to Amazon Pay balance')){
    //             sms.SA_Available_Balance__c = sms.content__c.split(' ')[9];
    //             sms.amount_value__c = sms.content__c.split(' ')[1];
    //         }
    //         else if(sms.content__c.contains('added to Amazon Pay Wallet')){
    //             sms.SA_Available_Balance__c = sms.content__c.split(' ')[9];
    //             sms.amount_value__c = sms.content__c.split(' ')[1];
    //         }
    //         else if(sms.content__c.contains('Refund')){
    //             sms.SA_Available_Balance__c = sms.content__c.split(' ')[18];
    //             sms.amount_value__c = sms.content__c.split(' ')[7];
    //         }
    //     }

    //     // Copy of above, to be mde for Vodafone / Jio account
    //     // if(sms.content__c.toUpperCase().contains('AMAZON PAY')){
    //     //     sms.type__c = 'balance_update';
    //     //     sms.Balance_Update__c = true;
    //     //     sms.Finance__Account__c = allBankAccountsMap.get('AMAZON-WA').Id;
            
    //     //     if(sms.content__c.contains('added to Amazon Pay balance')){
    //     //         sms.SA_Available_Balance__c = sms.content__c.split(' ')[9];
    //     //         sms.amount_value__c = sms.content__c.split(' ')[1];
    //     //     }
    //     //     else if(sms.content__c.contains('added to Amazon Pay Wallet')){
    //     //         sms.SA_Available_Balance__c = sms.content__c.split(' ')[9];
    //     //         sms.amount_value__c = sms.content__c.split(' ')[1];
    //     //     }
    //     //     else if(sms.content__c.contains('Refund')){
    //     //         sms.SA_Available_Balance__c = sms.content__c.split(' ')[18];
    //     //         sms.amount_value__c = sms.content__c.split(' ')[7];
    //     //     }
    //     // }

    //     if((sms.amount_value__c != null) && (sms.amount_value__c.endsWith('.'))){
    //         sms.amount_value__c = sms.amount_value__c.substring(0, sms.amount_value__c.length() - 1);
    //     }
    //     if((sms.SA_Available_Balance__c != null) && sms.SA_Available_Balance__c.endsWith('.')){
    //         sms.SA_Available_Balance__c = sms.SA_Available_Balance__c.substring(0, sms.SA_Available_Balance__c.length() - 1);
    //     }

    //     return sms;
    // }
}