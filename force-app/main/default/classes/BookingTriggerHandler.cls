public class BookingTriggerHandler {

    // Your verified Org-Wide Email Address
    private static final String ORG_WIDE_EMAIL =
        'iamprudhvigattu@gmail.com';

    // Prevents cancellation processing more than once
    // within the same transaction
    private static Boolean isCancellationProcessing = false;


    // BEFORE INSERT
    public static void beforeInsert(List<Booking__c> newList) {

        for (Booking__c booking : newList) {

            if (booking.Booking_Date__c == null) {
                booking.Booking_Date__c = Date.today();
            }

            if (booking.Agent__c == null) {
                booking.Agent__c = UserInfo.getUserId();
            }

            if (String.isBlank(booking.Booking_Status__c)) {
                booking.Booking_Status__c = 'Draft';
            }
        }
    }


    // BEFORE UPDATE
    public static void beforeUpdate(
        List<Booking__c> newList,
        Map<Id, Booking__c> oldMap
    ) {
        for (Booking__c booking : newList) {

            Booking__c oldBooking = oldMap.get(booking.Id);

            // Cannot change Cancelled booking back to Confirmed
            if (
                oldBooking.Booking_Status__c == 'Cancelled' &&
                booking.Booking_Status__c == 'Confirmed'
            ) {
                booking.addError(
                    'Cancelled booking cannot be reconfirmed.'
                );
            }

            // Cancellation reason is mandatory
            if (
                oldBooking.Booking_Status__c != 'Cancelled' &&
                booking.Booking_Status__c == 'Cancelled' &&
                String.isBlank(booking.Cancellation_Reason__c)
            ) {
                booking.addError(
                    'Cancellation reason is required.'
                );
            }
        }
    }


    // BEFORE DELETE
    public static void beforeDelete(List<Booking__c> oldList) {

        for (Booking__c booking : oldList) {
            if (booking.Booking_Status__c == 'Confirmed') {
                booking.addError(
                    'Cannot delete confirmed booking.'
                );
            }
        }
    }


    // AFTER INSERT
   /* public static void afterInsert(List<Booking__c> newList) {
        System.debug('Bookings inserted: ' + newList.size());
    }*/
    public static void afterInsert(List<Booking__c> newList) {

    Set<Id> confirmedIds = new Set<Id>();

    for(Booking__c b : newList){

        if(b.Booking_Status__c == 'Confirmed'){
            confirmedIds.add(b.Id);
        }

    }

    if(!confirmedIds.isEmpty()){
        BookingEmailService.sendConfirmationEmail(confirmedIds);
    }

}


    // AFTER UPDATE
    public static void afterUpdate(
        List<Booking__c> newList,
        Map<Id, Booking__c> oldMap
    ) {
        if (isCancellationProcessing) {
            return;
        }

        Set<Id> cancelledBookingIds = new Set<Id>();

        for (Booking__c booking : newList) {

            Booking__c oldBooking = oldMap.get(booking.Id);

            // Run only when Booking Status changes to Cancelled
            if (
                oldBooking.Booking_Status__c != 'Cancelled' &&
                booking.Booking_Status__c == 'Cancelled'
            ) {
                cancelledBookingIds.add(booking.Id);
            }
        }

        if (cancelledBookingIds.isEmpty()) {
            return;
        }

        isCancellationProcessing = true;

        try {
            processCancelledBookings(cancelledBookingIds);
        } finally {
            isCancellationProcessing = false;
        }
    }


    // Creates Refund, Case, and sends cancellation email
    private static void processCancelledBookings(
        Set<Id> bookingIds
    ) {

        List<Booking__c> cancelledBookings = [
            SELECT Id,
                   Name,
                   Booking_Status__c,
                   Total_Amount__c,
                   Cancellation_Reason__c,
                   Passenger__c,
                   Passenger__r.FirstName,
                   Passenger__r.Email,
                   Passenger__r.AccountId,
                   Account__c
            FROM Booking__c
            WHERE Id IN :bookingIds
        ];

        // Find bookings that already have a Refund
        Set<Id> bookingsWithRefund = new Set<Id>();

        for (Refund__c refund : [
            SELECT Id, Booking__c
            FROM Refund__c
            WHERE Booking__c IN :bookingIds
        ]) {
            bookingsWithRefund.add(refund.Booking__c);
        }

        List< Refund__c> refundsToInsert = new List< Refund__c>();
        List<Case> casesToInsert = new List<Case>();
        List<Messaging.SingleEmailMessage> emailsToSend =
            new List<Messaging.SingleEmailMessage>();

        // Query Org-Wide Email Address once
        Id orgWideEmailId;

        List<OrgWideEmailAddress> orgWideEmails = [
            SELECT Id
            FROM OrgWideEmailAddress
            WHERE Address = :ORG_WIDE_EMAIL
            LIMIT 1
        ];

        if (!orgWideEmails.isEmpty()) {
            orgWideEmailId = orgWideEmails[0].Id;
        }

        for (Booking__c booking : cancelledBookings) {

            // 1. Create Refund only if one does not already exist
            if (!bookingsWithRefund.contains(booking.Id)) {
                refundsToInsert.add(
                    new Refund__c(
                        Booking__c = booking.Id,
                        Refund_Amount__c = booking.Total_Amount__c,
                        Refund_Status__c = 'Initiated',
                        Requested_Date__c = Date.today()
                    )
                );
            }

            // 2. Create Case
           // Case refundCase = new Case();

            // Link Account from Booking first
          //  if (booking.Account__c != null) {
             //   refundCase.AccountId = booking.Account__c;
           // }
            // Otherwise use Passenger Contact Account
          /*  else if (
                booking.Passenger__r != null &&
                booking.Passenger__r.AccountId != null
            ) {
                refundCase.AccountId =
                    booking.Passenger__r.AccountId;
            }*/
            // 2. Create Case
Case refundCase = new Case();

// Relate the Case to the current Booking record
refundCase.Booking__c = booking.Id;

// Link Account from Booking first
    if (booking.Account__c != null) {
        refundCase.AccountId = booking.Account__c; //New by dileep
    }
    else if (booking.Passenger__r != null && booking.Passenger__r.AccountId != null) {
        refundCase.AccountId = booking.Passenger__r.AccountId;
    }
    // Link Passenger Contact
    if (booking.Passenger__c != null) {
        refundCase.ContactId = booking.Passenger__c;
    }

    refundCase.Subject = 'Refund Request - Booking ' + booking.Name;

    refundCase.Description = 'Booking cancelled: ' + booking.Name + '\n\n' + 'Cancellation Reason: ' + booking.Cancellation_Reason__c + '\n' + 'Refund Amount: Rs. ' + booking.Total_Amount__c;
    refundCase.Type = 'Refund Request';
    refundCase.Status = 'New';
    refundCase.Origin = 'Web';

    casesToInsert.add(refundCase);

    // 3. Prepare cancellation email
    if (booking.Passenger__r != null && !String.isBlank(booking.Passenger__r.Email)) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        // Send from Org-Wide Email Address
        if (orgWideEmailId != null) {
            email.setOrgWideEmailAddressId(orgWideEmailId);
        }

        email.setToAddresses(new String[] { booking.Passenger__r.Email });

        email.setSubject('Booking Cancelled - ' + booking.Name);

        email.setPlainTextBody(
            'Dear ' + booking.Passenger__r.FirstName + ',\n\n' +
            'Your booking ' + booking.Name +
            ' has been cancelled successfully.\n\n' +
            'Cancellation Reason: ' +
            booking.Cancellation_Reason__c + '\n' +
            'Refund Amount: Rs. ' +
            booking.Total_Amount__c + '\n' +
            'Refund Status: Initiated\n\n' +
            'A refund request Case has been created.\n\n' +
            'Regards,\n' +
            'SkyBook Pro Team'
        );

        emailsToSend.add(email);
    }
        

        // Insert Refund records
        if (!refundsToInsert.isEmpty()) {
            insert refundsToInsert;
        }

        // Insert Case records
        if (!casesToInsert.isEmpty()) {
            insert casesToInsert;
        }

        // Send emails
        if (!emailsToSend.isEmpty()) {
            Messaging.SendEmailResult[] emailResults =
                Messaging.sendEmail(emailsToSend);

            for (Messaging.SendEmailResult result : emailResults) {
                if (!result.isSuccess()) {
                    System.debug(
                        'Cancellation email failed: ' +
                        result.getErrors()[0].getMessage()
                    );
                }
            }
        }
    }
}}