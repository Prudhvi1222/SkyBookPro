@isTest
public class FlightOfferWrapperTest {

    @isTest
    static void testEmptyConstructor() {

        FlightOfferWrapper w = new FlightOfferWrapper();

        w.offerId = 'off_123';
        w.airline = 'Test Air';
        w.flightNumber = 'FL-001';
        w.origin = 'DEL';
        w.destination = 'BOM';
        w.departureTime = '2026-09-01T10:00:00';
        w.arrivalTime = '2026-09-01T12:00:00';
        w.durationMinutes = 120;
        w.price = 5000.00;
        w.currency_x = 'INR';
        w.cabinClass = 'Economy';
        w.numberOfStops = 0;
        w.seatsAvailable = 50;

        System.assertEquals('off_123', w.offerId);
        System.assertEquals('DEL', w.origin);
        System.assertEquals(Decimal.valueOf(5000), w.price);
        System.assertEquals(120, w.durationMinutes);
        System.assertEquals(0, w.numberOfStops);
        System.assertEquals(50, w.seatsAvailable);
    }

    @isTest
    static void testParameterizedConstructor() {

        FlightOfferWrapper w = new FlightOfferWrapper(
            'off_456',
            'Air India',
            'AI-101',
            'HYD',
            'DEL',
            '2026-09-01T08:00:00',
            '2026-09-01T10:00:00',
            120,
            Decimal.valueOf(4500),
            'INR',
            'Business',
            0,
            30
        );

        System.assertEquals('off_456', w.offerId);
        System.assertEquals('Air India', w.airline);
        System.assertEquals('HYD', w.origin);
        System.assertEquals('DEL', w.destination);
        System.assertEquals(Decimal.valueOf(4500), w.price);
        System.assertEquals('Business', w.cabinClass);
        System.assertEquals(0, w.numberOfStops);
        System.assertEquals(30, w.seatsAvailable);
    }
}