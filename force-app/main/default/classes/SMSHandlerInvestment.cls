public with sharing class SMSHandlerInvestment {

    // public static SMS__c processForInvestments(SMS__c sms, Map<String, Investment__c> allInvestmentsMap, String investmentCode){
        
    //     sms.Related_To_Investment__c = true;
        
    //     if(investmentCode == 'NSE'){
    //         sms = processForNSE(sms, allInvestmentsMap);
    //     }
    //     else if(investmentCode == 'EPF'){
    //         sms = processForEPF(sms, allInvestmentsMap);
    //     }
    //     else if(investmentCode == 'NPS'){
    //         sms = processForNPS(sms, allInvestmentsMap);
    //     }
    //     else if(investmentCode == 'ITDCPC'){
    //         sms = processForTax(sms, allInvestmentsMap);
    //     }
    //     else if(sms.Investment_Type__c == 'PPF'){
    //         sms = processForPPF(sms, allInvestmentsMap);
    //     }
    //     // else if(sms.Sender__c.contains('PPF')){

    //     // }
    //     return sms;
    // }

    // public static SMS__c processForTax(SMS__c sms, Map<String, Investment__c> allInvestmentsMap){
    //     sms.type__c = 'income_tax';
    //     return sms;
    // }

    // public static SMS__c processForPPF(SMS__c sms, Map<String, Investment__c> allInvestmentsMap){
    //     sms.type__c = 'ppf';
    //     sms.amount_value__c = sms.content__c.split(' ')[5];
    //     sms.INV_Available_Balance__c = sms.content__c.split('Avl Bal INR')[1].split('-')[0].replace(',', '').trim();
    //     sms.beneficiary__c = 'PPF';
    //     return sms;
    // }

    // public static SMS__c processForNSE(SMS__c sms, Map<String, Investment__c> allInvestmentsMap){
    //     List<String> contentArray = sms.content__c?.split(' ');
    //     return sms;
    // }

    // public static SMS__c processForEPF(SMS__c sms, Map<String, Investment__c> allInvestmentsMap){
    //     List<String> contentArray = sms.content__c?.split(' ');
    //     if(sms.content__c.contains('your passbook balance against')){
    //         sms.Investment_Type__c = 'EPF';
    //         sms.type__c = 'epf';
    //         sms.amount_value__c = contentArray[12].replace(',', '').replace('/', '').replace('-', '');
            
    //         sms.INV_Available_Balance__c = contentArray[8].replace(',', '').replace('/', '').replace('-', '');
    //         if(String.isNotBlank(sms.INV_Available_Balance__c) && sms.INV_Available_Balance__c.endsWith('.')){
    //             sms.INV_Available_Balance__c = sms.INV_Available_Balance__c.substring(0, sms.INV_Available_Balance__c.length() - 1);
    //         }
    //         // The beneficiary can come in sms in two formats
    //         // 1 : 092023 (i.e. in MMYYYY format)
    //         // OR
    //         // 2 : Sep-23 (i.e. in MMM-YY format)
    //         String datePeriod = contentArray[16];
    //         if(datePeriod.isNumeric() && datePeriod.length() == 6){
    //             datePeriod = datePeriod.substring(0, 2) + '-' + datePeriod.substring(4, 6);
    //             // datePeriod = datePeriod.substring(0, 2) + '/' + datePeriod.substring(2, 6);
    //         }
    //         else{
    //             String m = datePeriod.split('-')[0];
    //             String y = datePeriod.split('-')[1];
    //             // String y = '20' + datePeriod.split('-')[1];
    //             datePeriod = m + '-' + y;
    //         }
    //         sms.Beneficiary__c = 'EPF For ' + datePeriod;
    //     }
    //     return sms;
    // }

    // public static SMS__c processForNPS(SMS__c sms, Map<String, Investment__c> allInvestmentsMap){
    //     List<String> contentArray = sms.content__c?.split(' ');
    //     if(sms.content__c.startsWith('Investment value in NPS Tier I (PRAN-XX8815)')){
    //         sms.Investment_Type__c = 'NPS';
    //         sms.type__c = 'balance_update';
    //         sms.INV_Available_Balance__c = contentArray[12].replace(',', '');
    //         if(sms.INV_Available_Balance__c.endsWith('.')){ // if there is a dot in the end, remove it
    //             sms.INV_Available_Balance__c = sms.INV_Available_Balance__c.substring(0, sms.INV_Available_Balance__c.length() - 1);
    //         }
    //     }
    //     else if(sms.content__c.startsWith('Investment value in Tier I (PRAN XX8815)')){
    //         sms.Investment_Type__c = 'NPS';
    //         sms.type__c = 'balance_update';
    //         sms.INV_Available_Balance__c = contentArray[13].replace(',', '');
    //         if(sms.INV_Available_Balance__c.endsWith('.')){ // if there is a dot in the end, remove it
    //             sms.INV_Available_Balance__c = sms.INV_Available_Balance__c.substring(0, sms.INV_Available_Balance__c.length() - 1);
    //         }
    //         sms.Related_To_Investment__c = true;
    //     }
    //     return sms;
    // }
}