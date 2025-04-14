public with sharing class InvocableBeneficiaryAmountUpdateHandler {

    public static final String CLASS_NAME = 'InvocableBeneficiaryAmountUpdateHandler';

    // Invocable method that Flow or Process Builder can call
    @InvocableMethod(label='Update Beneficiary and Amount from SMS' description='Processes SMS records and delegates to SMSProcessor.')
    public static List<SMS__c> extractBeneficiaryAndAmountFromSMS(List<SMS__c> smsList) {
        List<SMS__c> output = Util.extractBeneficiaryAndAmountFromSMS(smsList);
        return output;
    }
    
}