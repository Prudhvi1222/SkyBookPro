public with sharing class BookingQueryService {

    // Confirmed bookings by agent
    public static List<Booking__c> getConfirmedBookingsByAgent(Id userId) {

        return [
            SELECT Id,
                   Name,
                   Total_Amount__c
            FROM Booking__c
            WHERE Agent__c = :userId
            AND Booking_Status__c = 'Confirmed'
        ];
    }

    // Tomorrow departures
    public static List<Booking__c> getTomorrowDepartures() {

        return [
            SELECT Id,
                   Name
            FROM Booking__c
            WHERE Flight__r.Departure_DateTime__c = TOMORROW
            AND Booking_Status__c = 'Confirmed'
        ];
    }
    

    // Revenue by month
    public static List<AggregateResult> getRevenueByMonth() {

        return [

            SELECT
                CALENDAR_YEAR(Booking_Date__c) Year,
                CALENDAR_MONTH(Booking_Date__c) Month,
                SUM(Total_Amount__c) Revenue

            FROM Booking__c

            GROUP BY
                CALENDAR_YEAR(Booking_Date__c),
                CALENDAR_MONTH(Booking_Date__c)

            ORDER BY
                CALENDAR_YEAR(Booking_Date__c),
                CALENDAR_MONTH(Booking_Date__c)
        ];
    }
}