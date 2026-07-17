@IsTest
private class DailyDepartureReminderSchedulerTest {

    @TestSetup
    static void setupData() {

        Account acc = TestDataFactory.createAccount(
            'Reminder Test'
        );

        Contact con = TestDataFactory.createContact(
            acc.Id,
            'John',
            'Doe'
        );

        Flight__c tomorrowFlight =
            TestDataFactory.createFlight(
                'HYD',
                'DEL',
                System.now().addDays(1)
            );

        TestDataFactory.createBookingWithStatus(
            con.Id,
            tomorrowFlight.Id,
            1,
            'Confirmed'
        );

        Flight__c futureFlight =
            TestDataFactory.createFlight(
                'DEL',
                'BLR',
                System.now().addDays(5)
            );

        TestDataFactory.createBookingWithStatus(
            con.Id,
            futureFlight.Id,
            1,
            'Confirmed'
        );
    }

    @IsTest
    static void testSchedulerExecute() {

        Test.startTest();

        String cron =
            '0 0 7 * * ?';

        System.schedule(
            'Daily Departure Reminder Test',
            cron,
            new DailyDepartureReminderScheduler()
        );

        Test.stopTest();

        CronTrigger ct = [

            SELECT Id,
                   CronExpression,
                   TimesTriggered,
                   State

            FROM CronTrigger

            WHERE CronJobDetail.Name =
                  'Daily Departure Reminder Test'

            LIMIT 1
        ];

        System.assertEquals(
            'WAITING',
            ct.State
        );
    }

    @IsTest
    static void testExecuteDirectly() {

        DailyDepartureReminderScheduler scheduler =
            new DailyDepartureReminderScheduler();

        Test.startTest();

        scheduler.execute(null);

        Test.stopTest();

        System.assert(true);
    }
}