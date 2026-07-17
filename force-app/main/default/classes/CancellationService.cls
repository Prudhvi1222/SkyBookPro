public with sharing class CancellationService {

    // Called from cancellationModal LWC
    @AuraEnabled(cacheable=false)
    public static void cancelBooking(Id bookingId, String reason) {

        if (bookingId == null) {
            throw new AuraHandledException('Booking Id is required.');
        }

        if (String.isBlank(reason)) {
            throw new AuraHandledException(
                'Cancellation reason is required.'
            );
        }

        Booking__c booking = [
            SELECT Id,
                   Booking_Status__c,
                   Cancellation_Reason__c
            FROM Booking__c
            WHERE Id = :bookingId
            LIMIT 1
        ];

        if (booking.Booking_Status__c == 'Cancelled') {
            throw new AuraHandledException(
                'Booking is already cancelled.'
            );
        }

        // Trigger will create Refund, Case, and Email after this update
        booking.Booking_Status__c = 'Cancelled';
        booking.Cancellation_Reason__c = reason;

        try {
            update booking;
        } catch (DmlException e) {
            throw new AuraHandledException(
                'Cancellation failed: ' + e.getDmlMessage(0)
            );
        }
    }

    // Used by refundStatusTracker LWC
    @AuraEnabled(cacheable=true)
    public static Refund__c getRefundStatus(Id bookingId) {

        if (bookingId == null) {
            return null;
        }

        List<Refund__c> refunds = [
            SELECT Id,
                   Refund_Status__c,
                   Refund_Amount__c,
                   Requested_Date__c,
                   Completed_Date__c,
                   Refund_Reference__c
            FROM Refund__c
            WHERE Booking__c = :bookingId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        return refunds.isEmpty() ? null : refunds[0];
    }
}