public class DraftBookingExpiryJob implements Queueable {

    private List<Id> bookingIds;

    public DraftBookingExpiryJob(List<Id> bookingIds) {

        this.bookingIds = bookingIds;
    }

    public void execute(QueueableContext context) {

        List<Booking__c> bookings = [

            SELECT Id,
                   Booking_Status__c,
                   Cancellation_Reason__c

            FROM Booking__c

            WHERE Id IN :bookingIds
        ];

        for (Booking__c b : bookings) {

            if (b.Booking_Status__c == 'Draft') {

                b.Booking_Status__c = 'Cancelled';

                b.Cancellation_Reason__c =
                    'Auto-expired by system';
            }
        }

        update bookings;

        System.debug(
            'DraftBookingExpiryJob completed'
        );
    }
}