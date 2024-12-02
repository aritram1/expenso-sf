public with sharing class InvocableSMSHandler {
    /**
     * Invocable method to call the enrichData method.
     */
    @InvocableMethod(label='Enrich the data' description='Enrich the data')
    public static List<SMS__c> enrichData(List<SMS__c> smsList) {   
        List<SMS__c> data = SMSHandler.enrichData(smsList);
        for(SMS__c sms : data){
            sms.status__c = 'Processed';
        }
        return data;
    }
}
