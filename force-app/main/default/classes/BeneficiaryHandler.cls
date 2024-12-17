public with sharing class BeneficiaryHandler {


    public static List<SMS__c> updateBeneficiary(List<SMS__c> inputList){
        
        List<Beneficiary__c> insertBeneficiaryList = new List<Beneficiary__c>();
        
        // Get all related beneficiaries and create a map
        List<String> allBeneficiaryNames = new List<String>();
        for(SMS__c sms : inputList){
            if(String.isNotEmpty(sms.Beneficiary_name__c) && String.isNotBlank(sms.Beneficiary_name__c)){
                allBeneficiaryNames.add(Util.toCamelCase(sms.beneficiary_name__c));            
            }
        }
        List<Beneficiary__c> allBeneficiaries = [SELECT Id, Name from Beneficiary__c where name in :allBeneficiaryNames];
        Map<String, Beneficiary__c> allBeneficiariesMap = new Map<String, Beneficiary__c>();
        for(Beneficiary__c b : allBeneficiaries){
            allBeneficiariesMap.put(b.name, b); // b.name is in camel case
        }

        // Populate Beneficiary__c info from Beneficiary_Name__c info
        for(SMS__c sms : inputList){
            if(String.isNotEmpty(sms.Beneficiary_name__c) && String.isNotBlank(sms.Beneficiary_name__c)){
                
                // convert to camel case to use for later
                String beneficiaryNameCameCase = Util.toCamelCase(sms.Beneficiary_name__c);
                
                if(allBeneficiariesMap.containsKey(beneficiaryNameCameCase)){
                    Beneficiary__c existing = allBeneficiariesMap.get(beneficiaryNameCameCase);
                    sms.beneficiary__c = existing.Id;
                }
                else{
                    Beneficiary__c newBeneficiary = new Beneficiary__c();
                    newBeneficiary.Name = beneficiaryNameCameCase;
                    
                    insert newBeneficiary; // TB done later - [Optimization - 1 : ensure the dml is outside loop]
                    insertBeneficiaryList.add(newBeneficiary);

                    // Part 1 : 
                    // Set the beneficiary Info at the sms level
                    sms.beneficiary__c = newBeneficiary.Id;
                    
                    // Part 2 : 
                    // Add the new beneficiary to the map `allBeneficiariesMap`, so the next sms can reuse latest data
                    allBeneficiariesMap.put(beneficiaryNameCameCase, newBeneficiary);
                    
                }
            }
        }

        return inputList; // return the updated list
    }

    // This method fixes if there is any typo in beneficiary name or some abbreviations are missed
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static SMS__c fixBeneficiaryName(SMS__c sms){

        String beneficiaryName = sms.beneficiary_name__c;
        
        if(String.isNotEmpty(beneficiaryName) && String.isNotBlank(beneficiaryName)){ // may be we are overchecking here :P

            if(beneficiaryName.toUpperCase().contains('CONCEN')){
                beneficiaryName = 'Concentrix';
            }
            
            if(beneficiaryName.toUpperCase().contains('YESB0000001')){
                beneficiaryName = 'Transferwise';
            }

            if(beneficiaryName.toUpperCase().contains('AMAZON') || beneficiaryName.toUpperCase().contains('AMAZ')){
                beneficiaryName = 'Amazon';
            }
            
            if(beneficiaryName.toUpperCase().contains('ZOMATO')){
                beneficiaryName = 'Zomato';
            }

            if(beneficiaryName.toUpperCase().contains('BLINKIT')){
                beneficiaryName = 'BlinkIt';
            }
            
            if(beneficiaryName.toUpperCase().contains('VODAFONE')){
                beneficiaryName = 'Vodafone';
            }

            if(beneficiaryName.toUpperCase().contains('HOUSING')){
                beneficiaryName = 'Housing.com';
            }

            if(beneficiaryName.toUpperCase().contains('BALAJI GRAND BA')){
                beneficiaryName = 'Balaji Grand Bazar';
            }

            if(beneficiaryName.toUpperCase().contains('MAKEMYTRIP')){
                beneficiaryName = 'Makemytrip';
            }

            if(beneficiaryName.toUpperCase().contains('UBER')){
                beneficiaryName = 'Uber';
            }

            // Some scenarios where we require to check by using contain and not having a direct match in names
            if(beneficiaryName.toUpperCase().contains('NFS*')){ // NFS = National Financial Switch (NFS), A Leading ATM Network
                beneficiaryName = 'ICICI ATM Withdrawal';
            }
            else if(beneficiaryName.toUpperCase().contains('INFOBIL')){
                // If the bill is paid in Aug month, the bill is generated for July month
                // So 1 month is deducted from Transaction_date__c during calculation below
                String timeFrame = Datetime.newInstance(sms.Transaction_Date__c.addMonths(-1), Time.newInstance(0, 0, 0, 0)).format('MMM-yy'); // CC Bill 
                beneficiaryName = 'ICICI CC Bill for ' + timeFrame;
            }
            else if(beneficiaryName.toUpperCase().contains('A/C LINKED TO VPA')){
                beneficiaryName = beneficiaryName.replace('a/c linked to VPA', '')?.trim();
            }
            else if(beneficiaryName.toUpperCase().startsWith('VPA')){
                beneficiaryName = beneficiaryName.replace('Vpa ', '').replace('VPA ', '')?.trim();
            }
            else if(beneficiaryName.toUpperCase().contains('A/C LINKED TO MOBILE NO')){
                beneficiaryName = beneficiaryName.replace('A/c Linked to mobile No', 'UPI @')?.trim();
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
        }
        sms.beneficiary_name__c = Util.toCamelCase(beneficiaryName);
        
        return sms;

    }
}