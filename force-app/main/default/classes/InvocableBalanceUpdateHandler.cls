public with sharing class InvocableBalanceUpdateHandler {

    // Invocable method that Flow or Process Builder can call
    @InvocableMethod(label='Extracts Balance Information' description='Processes SMS record and extracts balance')
    public static List<SMS__c> extractBalanceInfo(List<SMS__c> smsList) {
        List<SMS__c> output = Util.extractBalanceInfo(smsList);
        return output;
    }
}