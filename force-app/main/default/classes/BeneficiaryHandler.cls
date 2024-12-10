public with sharing class BeneficiaryHandler {


    public static List<Transaction_Platform_Event__e> updateBeneficiary(List<Transaction_Platform_Event__e> outputList){
        
        List<Beneficiary__c> insertBeneficiaryList = new List<Beneficiary__c>();

        List<String> allBeneficiaryNames = new List<String>();
        for(Transaction_Platform_Event__e txnPE : outputList){
            // allBeneficiaryNames.add(txnPE.beneficiary_c);
            if(String.isNotEmpty(txnPE.Beneficiary_name__c) && String.isNotBlank(txnPE.Beneficiary_name__c)){
                String beneficiaryNameUpperCase = txnPE.Beneficiary_name__c.toUpperCase();
                allBeneficiaryNames.add(beneficiaryNameUpperCase);            
            }
        }
        List<Beneficiary__c> allBeneficiaries = [SELECT Id, Name from Beneficiary__c where name in :allBeneficiaryNames];
        Map<String, Beneficiary__c> allBeneficiariesMap = new Map<String, Beneficiary__c>();
        
        for(Beneficiary__c b : allBeneficiaries){
            // String beneficiaryNameUpperCase = b.name.toUpperCase();
            allBeneficiariesMap.put(b.name.toUpperCase(), b);
        }
        
        
        for(Transaction_Platform_Event__e txnPE : outputList){
            if(String.isNotEmpty(txnPE.Beneficiary_name__c) && String.isNotBlank(txnPE.Beneficiary_name__c)){
                String beneficiaryNameUpperCase = txnPE.Beneficiary_name__c.toUpperCase();
                if(allBeneficiariesMap.containsKey(beneficiaryNameUpperCase)){
                    Beneficiary__c existing = allBeneficiariesMap.get(beneficiaryNameUpperCase);
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
        }
        // TB done later - Optimization - 2
        // insert insertListBeneficiary;

        return outputList;
    }

    // This method fixes if there is any typo in beneficiary name or some abbreviations are missed
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static Transaction_Platform_Event__e fixBeneficiaryName(Transaction_Platform_Event__e tpe){

        String beneficiaryName = tpe.beneficiary_name__c;
        
        if(String.isNotEmpty(beneficiaryName) && String.isNotBlank(beneficiaryName)){ // may be we are overchecking here :P

            // If the name contains a dash (-), use specific fixes
            if(beneficiaryName.toUpperCase().contains('-') && !beneficiaryName.toUpperCase().contains('A/C LINKED TO')){
                List<String> allEntries = beneficiaryName.split('-');
                if(beneficiaryName.toUpperCase().contains('CONCENTRIX')){
                    beneficiaryName = 'Concentrix';
                }
                else if(beneficiaryName.toUpperCase().contains('YESB0000001')){
                    beneficiaryName = 'Transferwise';
                }
                else{
                    // take the last entry
                    beneficiaryName = allEntries[allEntries.size() - 1].trim();
                }
            }

            if(beneficiaryName.toUpperCase().contains('AMAZON')){
                beneficiaryName = 'Amazon.com';
            }

            // Some scenarios where we require to check by using contain and not having a direct match in names
            if(beneficiaryName.toUpperCase().contains('NFS*')){ // NFS = National Financial Switch (NFS), A Leading ATM Network
                beneficiaryName = 'ICICI ATM Withdrawal';
            }
            else if(beneficiaryName.toUpperCase().contains('INFOBIL')){
                // If the bill is paid in Aug month, the bill is generated for July month
                // So 1 month is deducted from Transaction_date__c during calculation below
                String timeFrame = Datetime.newInstance(tpe.Transaction_Date__c.addMonths(-1), Time.newInstance(0, 0, 0, 0)).format('MMM-yy'); // CC Bill 
                beneficiaryName = 'ICICI CC Bill for ' + timeFrame;
            }
            // Investment related beneficiary names
            // else if(beneficiaryName.toUpperCase().contains('CBDT')){
            //     sms.Related_To_Investment__c = true;
            //     sms.Investment_Type__c = 'Advance Tax';
            // }
            // else if(sms.beneficiary__c.toUpperCase().startsWith('INDIANCLEARINGCORP')){
            //     sms.Related_To_Investment__c = true;
            //     sms.Investment_Type__c = 'NPS';
            // }
            // Clean up VPA and A/c related beneficiary names
            else if(beneficiaryName.toUpperCase().contains('A/C LINKED TO VPA')){
                beneficiaryName = beneficiaryName.replace('a/c linked to VPA', '')?.trim();
            }
            else if(beneficiaryName.toUpperCase().startsWith('VPA')){
                beneficiaryName = beneficiaryName.replace('Vpa ', '').replace('VPA ', '')?.trim();
            }
            else if(beneficiaryName.toUpperCase().contains('A/C LINKED TO MOBILE NO')){
                beneficiaryName = beneficiaryName.replace('A/c Linked to mobile No', 'UPI @')?.trim();
            }

        }
        tpe.beneficiary_name__c = beneficiaryName;
        return tpe;

    }
}