public with sharing class FinPlanLogger {

    static final String TAG = 'FinPlanLogger';
    
    // The following methods/overloaded methods serve the purpose of logging info/success/errors scenarios
    public static void logError(Exception e){
        logError(e, 'Related Info Not Provided', 'SMS Content Not Provided');
    }
    
    public static void logError(Exception e, String relatedTo){
        logError(e, relatedTo, 'SMS Content Not Provided');
    }
    
    public static void logError(Exception e, String relatedTo, String content){
        
        System_Log__c log = new System_Log__c();
        
        log.Exception_Type__c = e.getTypeName();
        log.Message__c = Util.clipTo255char(e.getMessage());
        log.Stack_Trace__c = Util.clipTo255char(e.getStackTraceString());
        // log.Content__c = Util.clipTo255char(content);
        log.Related_To__c = Util.clipTo255char(relatedto);
        insert log;
    }

    // creates Error Message in case of error
    public static String getDetailedErrorMessage(Exception e){
        String errorMessage = '';
        if(e.getTypeName().contains('DMLException')){
            for (Integer i = 0; i < e.getNumDml(); i++) {
                // Process exception here
                errorMessage += e.getDMLType(i) + ' : ' + e.getDmlMessage(i) + ' : ' + e.getDmlFields(i) + '|'; 
            }
        }
        else{
            errorMessage = e.getMessage();
        }
        return errorMessage;
    }

}