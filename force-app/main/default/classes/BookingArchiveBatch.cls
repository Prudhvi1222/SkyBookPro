// BRD Section 10.3: Archives bookings older than 2 years
public class BookingArchiveBatch implements Database.Batchable<SObject> {

    // BRD: Query bookings older than 2 years
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, Booking_Status__c FROM Booking__c WHERE Booking_Date__c < LAST_N_YEARS:2'
        );
    }

    // BRD: Mark old bookings as Cancelled (archived)
public void execute(Database.BatchableContext bc, List<Booking__c> scope) {

    for (Booking__c b : scope) {
        b.Booking_Status__c = 'Cancelled';

        // Add cancellation reason
        b.Cancellation_Reason__c = 'Archived after 2 years';
    }

    update scope;
}

    // BRD: Send completion notification email to admin
    public void finish(Database.BatchableContext bc) {
        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors, TotalJobItems
            FROM AsyncApexJob
            WHERE Id = :bc.getJobId()
        ];

        // Send completion email to org admin
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{ UserInfo.getUserEmail() });
        email.setSubject('BookingArchiveBatch Completed');
        email.setPlainTextBody(
            'Batch job finished.\n' +
            'Status: ' + job.Status + '\n' +
            'Total Batches: ' + job.TotalJobItems + '\n' +
            'Errors: ' + job.NumberOfErrors
        );
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });

        System.debug('BookingArchiveBatch complete. Status: ' + job.Status);
    }
}