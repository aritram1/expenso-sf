public with sharing class BeneficiaryHandler {


    public static List<Transaction_Platform_Event__e> updateBeneficiary(List<Transaction_Platform_Event__e> outputList){
        
        List<Beneficiary__c> insertBeneficiaryList = new List<Beneficiary__c>();

        List<String> allBeneficiaryNames = new List<String>();
        for(Transaction_Platform_Event__e txnPE : outputList){
            allBeneficiaryNames.add(txnPE.beneficiary__c);
        }
        List<Beneficiary__c> allBeneficiaries = [SELECT Id, Name from Beneficiary__c where name in :allBeneficiaryNames];
        Map<String, Beneficiary__c> allBeneficiariesMap = new Map<String, Beneficiary__c>();
        for(Transaction_Platform_Event__e txnPE : outputList){
            if(allBeneficiariesMap.containsKey(txnPE.Beneficiary__c)){
                Beneficiary__c existing = allBeneficiariesMap.get(txnPE.Beneficiary__c);
                txnPE.Beneficiary__c = existing.Id;
            }
            else{
                Beneficiary__c newBeneficiary = new Beneficiary__c();
                newBeneficiary.Name = txnPE.beneficiary_name__c;
                insert newBeneficiary;
                txnPE.Beneficiary__c = newBeneficiary.Id;
                // TB done later - Optimization - 1
                // insertBeneficiaryList.add(newBeneficiary);
            }
        }
        // TB done later - Optimization - 2
        // insert insertListBeneficiary;

        return outputList;
    }

    // This method fixes if there is any typo in beneficiary name or some abbreviations are missed
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // public static SMS__c fixBeneficiaryName(SMS__c sms, Map<String, Beneficiary__c> allBeneficiariesMap){

    //     if(String.isNotEmpty(sms.beneficiary__c) && String.isNotBlank(sms.beneficiary__c)){ // may be we are overchecking here :P

    //         // If the name contains a dash (-), use specific fixes
    //         if(sms.beneficiary__c.contains('-') && !sms.beneficiary__c.contains('a/c linked to')){
    //             List<String> allEntries = sms.beneficiary__c.split('-');
    //             if(sms.beneficiary__c.toUpperCase().contains('CONCENTRIX')){
    //                 sms.beneficiary__c = 'Concentrix';
    //             }
    //             else if(sms.beneficiary__c.toUpperCase().contains('YESB0000001')){
    //                 sms.beneficiary__c = 'Transferwise';
    //             }
    //             else{
    //                 // take the last entry
    //                 sms.beneficiary__c = allEntries[allEntries.size() - 1].trim();
    //             }
    //         }

    //         // Correct the beneficiary names from the list of all beneficiaries in the System
    //         String beneficiaryNameUpperCase = sms.beneficiary__c.toUpperCase();
    //         for(String beneficiaryExternalId : allBeneficiariesMap.keySet()){
    //             if(beneficiaryExternalId.toUpperCase().contains(beneficiaryNameUpperCase)){
    //                 Beneficiary__c beneficiaryRecord = allBeneficiariesMap.get(beneficiaryExternalId);
    //                 sms.beneficiary__c = beneficiaryRecord.Name;
    //                 sms.beneficiary_Type__c = beneficiaryRecord.Type__c;
    //                 break;
    //             }
    //             // else{
    //             //     sms.beneficiary__c = 'Other';
    //             //     sms.beneficiary_Type__c = 'Other';
    //             // }
    //         }

    //         // Some scenarios where we require to check by using contain and not having a direct match in names
    //         if(sms.beneficiary__c.toUpperCase().contains('NFS*')){ // NFS = National Financial Switch (NFS), A Leading ATM Network
    //             sms.beneficiary__c = 'ICICI ATM Withdrawal';
    //         }
    //         else if(sms.beneficiary__c.toUpperCase().contains('INFOBIL')){
    //             // If the bill is paid in Aug month, the bill is generated for July month
    //             // So 1 month is deducted from Transaction_date__c during calculation below
    //             String timeFrame = Datetime.newInstance(sms.Transaction_Date__c.addMonths(-1), Time.newInstance(0, 0, 0, 0)).format('MMM-yy'); // CC Bill 
    //             sms.beneficiary__c = 'ICICI CC Bill for ' + timeFrame;
    //         }
    //         // Investment related beneficiary names
    //         else if(sms.beneficiary__c.toUpperCase().contains('CBDT')){
    //             sms.Related_To_Investment__c = true;
    //             sms.Investment_Type__c = 'Advance Tax';
    //         }
    //         else if(sms.beneficiary__c.toUpperCase().startsWith('INDIANCLEARINGCORP')){
    //             sms.Related_To_Investment__c = true;
    //             sms.Investment_Type__c = 'NPS';
    //         }
    //         // Clean up VPA and A/c related beneficiary names
    //         else if(sms.beneficiary__c.contains('a/c linked to VPA')){
    //             sms.beneficiary__c = sms.beneficiary__c.replace('a/c linked to VPA', '')?.trim();
    //         }
    //         else if(sms.beneficiary__c.toUpperCase().startsWith('VPA')){
    //             sms.beneficiary__c = sms.beneficiary__c.replace('Vpa ', '').replace('VPA ', '')?.trim();
    //         }
    //         else if(sms.beneficiary__c.contains('A/c Linked to mobile No')){
    //             sms.beneficiary__c = sms.beneficiary__c.replace('A/c Linked to mobile No', 'UPI @')?.trim();
    //         }

    //     }

    //     return sms;

    // }
}