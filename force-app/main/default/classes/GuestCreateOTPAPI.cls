@RestResource(urlMapping='/api/login/otp/create')
global with sharing class GuestCreateOTPAPI {

    global final static String CLASS_NAME = 'GuestOTPLoginAPI';

    /**
     * POST method to generate and send OTP
     * This method generates a 6-digit OTP, stores it in the OTP__c object, 
     * and sends it to the provided email.
     */
    @HttpPost
    global static void createOTP() {
        try {
            // Parse the incoming request body
            String requestBody = RestContext.request.requestBody.toString();
            Map<String, Object> requestData = (Map<String, Object>) JSON.deserializeUntyped(requestBody);

            // Validate the email field in the request
            if (!requestData.containsKey('email') || String.isEmpty((String) requestData.get('email'))) {
                throw new FinPlanException('Email is required in the request body');
            }
            else{
                String email = (String) requestData.get('email');
                // Generate the OTP
                String otp = Util.generateOTP(email);
                
                // Send the OTP to the provided email
                Util.sendEmail(email, otp);

                // Set a successful response
                RestContext.response.statusCode = 201; // Created
                RestContext.response.responseBody = Blob.valueOf('OTP sent successfully to ' + email);
            }
        } 
        catch (Exception e) {
            // Handle general exceptions
            FinPlanLogger.logError(CLASS_NAME, 'createOTP', e, null); // the last parameter is the entity Id, which is not available outside the loop
            RestContext.response.statusCode = 500; // Internal Server Error
            RestContext.response.responseBody = Blob.valueOf('Error processing request: ' + e.getMessage() + '||' + e.getStackTraceString());
        }
    }

}