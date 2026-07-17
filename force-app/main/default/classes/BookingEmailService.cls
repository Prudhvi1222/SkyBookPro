public class BookingEmailService {

    @future
    public static void sendConfirmationEmail(Set<Id> bookingIds) {

        List<Booking__c> bookings = [
            SELECT Id,
                   Name,
                   Passenger__r.Email
            FROM Booking__c
            WHERE Id IN :bookingIds
        ];

        Id orgWideEmailId;

        List<OrgWideEmailAddress> oweList = [
            SELECT Id
            FROM OrgWideEmailAddress
            WHERE Address = 'iamprudhvigattu@gmail.com'
            LIMIT 1
        ];

        if (!oweList.isEmpty()) {
            orgWideEmailId = oweList[0].Id;
        }

        List<Messaging.SingleEmailMessage> emails =
            new List<Messaging.SingleEmailMessage>();

        for (Booking__c booking : bookings) {

            if (booking.Passenger__r == null ||
                String.isBlank(booking.Passenger__r.Email)) {
                continue;
            }

            Messaging.SingleEmailMessage email =
                new Messaging.SingleEmailMessage();

            if (orgWideEmailId != null) {
                email.setOrgWideEmailAddressId(orgWideEmailId);
            }

            email.setToAddresses(
                new List<String>{ booking.Passenger__r.Email }
            );

            email.setSubject(
                'Booking Confirmed: ' + booking.Name
            );

            email.setPlainTextBody(
                'Dear Customer,\n\n' +
                'Your booking ' + booking.Name +
                ' has been confirmed successfully.\n\n' +
                'Thank you for choosing SkyBook Pro.\n\n' +
                'Regards,\nSkyBook Pro Team'
            );

            emails.add(email);
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
}