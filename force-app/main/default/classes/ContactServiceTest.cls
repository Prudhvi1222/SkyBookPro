@IsTest
private class ContactServiceTest {

    @IsTest
    static void testCreatePassengerContact() {

        Test.startTest();

        Id contactId = ContactService.createPassengerContact(
            'John',
            'Doe',
            'john.doe@test.com',
            '9876543210'
        );

        Test.stopTest();

        System.assertNotEquals(
            null,
            contactId
        );

        Contact c = [
            SELECT Id,
                   FirstName,
                   LastName,
                   Email,
                   Phone
            FROM Contact
            WHERE Id = :contactId
        ];

        System.assertEquals(
            'John',
            c.FirstName
        );

        System.assertEquals(
            'Doe',
            c.LastName
        );

        System.assertEquals(
            'john.doe@test.com',
            c.Email
        );

        System.assertEquals(
            '9876543210',
            c.Phone
        );
    }

    @IsTest
    static void testFindOrCreatePassengerContactReusesExisting() {

        Contact existing = new Contact(
            FirstName = 'Jane',
            LastName = 'Roe',
            Email = 'jane.roe@test.com',
            Phone = '5551234567'
        );
        insert existing;

        Test.startTest();

        Id foundId = ContactService.findOrCreatePassengerContact(
            'Jane',
            'Roe',
            'jane.roe@test.com',
            '5551234567'
        );

        Test.stopTest();

        System.assertEquals(
            existing.Id,
            foundId
        );

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Contact WHERE Email = 'jane.roe@test.com']
        );
    }

    @IsTest
    static void testFindOrCreatePassengerContactCreatesNew() {

        Test.startTest();

        Id newId = ContactService.findOrCreatePassengerContact(
            'Alex',
            'Kim',
            'alex.kim@test.com',
            '5559876543'
        );

        Test.stopTest();

        System.assertNotEquals(
            null,
            newId
        );

        Contact c = [
            SELECT FirstName, LastName, Email, Phone
            FROM Contact
            WHERE Id = :newId
        ];

        System.assertEquals('Alex', c.FirstName);
        System.assertEquals('Kim', c.LastName);
        System.assertEquals('alex.kim@test.com', c.Email);
    }

    @IsTest
    static void testCreatePassengerContactWithNullValues() {

        Test.startTest();

        Id contactId = ContactService.createPassengerContact(
            null,
            'Smith',
            null,
            null
        );

        Test.stopTest();

        System.assertNotEquals(
            null,
            contactId
        );

        Contact c = [
            SELECT LastName
            FROM Contact
            WHERE Id = :contactId
        ];

        System.assertEquals(
            'Smith',
            c.LastName
        );
    }
}