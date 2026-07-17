import { createElement } from '@lwc/engine-dom';
import CancellationModal from 'c/cancellationModal';
import cancelBooking from '@salesforce/apex/CancellationService.cancelBooking';

jest.mock(
    '@salesforce/apex/CancellationService.cancelBooking',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

const MOCK_BOOKING = {
    Id: 'a01000000000001',
    Name: 'BK-0001',
    route: 'HYD → DEL',
    Booking_Status__c: 'Confirmed',
    Total_Amount__c: 4500
};

describe('c-cancellation-modal', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('dispatches a close event when "Keep Booking" is clicked', () => {
        const element = createElement('c-cancellation-modal', {
            is: CancellationModal
        });
        element.booking = MOCK_BOOKING;
        document.body.appendChild(element);

        const closeHandler = jest.fn();
        element.addEventListener('close', closeHandler);

        const closeButton = element.shadowRoot.querySelector('.cm-btn-close');
        closeButton.click();

        expect(closeHandler).toHaveBeenCalledTimes(1);
    });

    it('shows a validation error and does not call Apex when the reason is left blank', async () => {
        const element = createElement('c-cancellation-modal', {
            is: CancellationModal
        });
        element.booking = MOCK_BOOKING;
        document.body.appendChild(element);

        const toastHandler = jest.fn();
        element.addEventListener('lightning__showtoast', toastHandler);

        const confirmButton = element.shadowRoot.querySelector('.cm-btn-confirm');
        confirmButton.click();

        await Promise.resolve();

        expect(toastHandler).toHaveBeenCalledTimes(1);
        expect(toastHandler.mock.calls[0][0].detail.title).toBe('Reason Required');
        expect(cancelBooking).not.toHaveBeenCalled();
    });
});
