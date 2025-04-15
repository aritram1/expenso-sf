public class FinPlanException extends Exception {

    static final String TAG = 'FinPlanException';

    public String className { get; set; }
    public String methodName { get; set; }
    public String objName { get; set; } 
    
}