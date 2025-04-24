// This script is executed after the package installation.
// It is used to assign permission sets to the current user and the guest user.


assignPermissionSets();


/**
 * This method performs an operation. 
 * Add a detailed description of its functionality here.
 * 
 * Note: Replace this comment with specific details about what the method does.
 */
public static void assignPermissionSets() {
    // Get the current user
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

    // Assign the 'Guest_User_PS' permission set to the current user
    PermissionSetAssignment currentUserAssignment = new PermissionSetAssignment(
        AssigneeId = currentUser.Id,
        PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Guest_User_PS' LIMIT 1].Id
    );
    insert currentUserAssignment;

    // Assign the 'Guest_User_PS' permission set to the guest user
    User guestUser = [SELECT Id FROM User WHERE Profile.Name = 'Guest User' LIMIT 1];
    PermissionSetAssignment guestUserAssignment = new PermissionSetAssignment(
        AssigneeId = guestUser.Id,
        PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Guest_User_PS' LIMIT 1].Id
    );
    insert guestUserAssignment;
}