public class FinPlanException extends Exception {

    static final String TAG = 'FinPlanException';

    // Fields
    public String className { get; set; }
    public String methodName { get; set; }
    public String objName { get; set; }
    public String errorCode { get; set; }
    public String errorMessage { get; set; }
    public String stackTrace { get; set; }
    public DateTime timestamp { get; set; }
    public Map<String, Object> additionalContext { get; set; }

    // Constructor with parameters
    public FinPlanException(String className, String methodName, String objName, String errorCode, String errorMessage) {
        this.className = className;
        this.methodName = methodName;
        this.objName = objName;
        this.errorCode = errorCode;
        this.errorMessage = errorMessage;
        this.stackTrace = this.getStackTraceString();
        this.timestamp = DateTime.now();
    }

    // Constructor with additional context
    public FinPlanException(String className, String methodName, String objName, String errorCode, String errorMessage, Map<String, Object> additionalContext) {
        this(className, methodName, objName, errorCode, errorMessage);
        this.additionalContext = additionalContext;
    }

    // Method to format exception details
    public String formatExceptionDetails() {
        return 'Exception Occurred: ' +
               '\nClass: ' + className +
               '\nMethod: ' + methodName +
               '\nObject: ' + objName +
               '\nError Code: ' + errorCode +
               '\nError Message: ' + errorMessage +
               '\nStack Trace: ' + stackTrace +
               '\nTimestamp: ' + timestamp +
               '\nAdditional Context: ' + (additionalContext != null ? JSON.serialize(additionalContext) : 'None');
    }

    // Method to log the exception
    // public void logException() {
    //     System_Log__c log = new System_Log__c();
    //     log.Type__c = 'Error';
    //     log.Category__c = TAG;
    //     log.Message__c = this.formatExceptionDetails();
    //     log.Timestamp__c = this.timestamp;
    //     try {
    //         insert log;
    //     } catch (Exception e) {
    //         System.debug('Failed to log exception: ' + e.getMessage());
    //     }
    // }
}