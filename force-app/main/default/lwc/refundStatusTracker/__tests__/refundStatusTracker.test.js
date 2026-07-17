import { createElement } from '@lwc/engine-dom';
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import RefundStatusTracker from 'c/refundStatusTracker';
import getRefundStatus from '@salesforce/apex/CancellationService.getRefundStatus';

const getRefundStatusAdapter = registerApexTestWireAdapter(getRefundStatus);

const MOCK_REFUND = {
    Refund_Status__c: 'Processing',
    Refund_Amount__c: 199.5,
    Requested_Date__c: '2026-07-15',
    Completed_Date__c: null,
    Refund_Reference__c: 'RF-1001'
};

describe('c-refund-status-tracker', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('renders the refund detail card and progress indicator when a refund is returned', async () => {
        const element = createElement('c-refund-status-tracker', {
            is: RefundStatusTracker
        });
        element.bookingId = 'a02000000000001';
        document.body.appendChild(element);

        getRefundStatusAdapter.emit(MOCK_REFUND);
        await Promise.resolve();

        const progress = element.shadowRoot.querySelector('lightning-progress-indicator');
        expect(progress).not.toBeNull();
        expect(progress.currentStep).toBe('Processing');

        const statusValue = element.shadowRoot.querySelector('.rst-status-pill');
        expect(statusValue.textContent).toBe('Processing');

        const emptyState = element.shadowRoot.querySelector('.rst-empty-state');
        expect(emptyState).toBeNull();
    });

    it('shows the error message when the wire adapter returns an error', async () => {
        const element = createElement('c-refund-status-tracker', {
            is: RefundStatusTracker
        });
        element.bookingId = 'a02000000000002';
        document.body.appendChild(element);

        getRefundStatusAdapter.error({
            message: 'No refund found for this booking.'
        });
        await Promise.resolve();

        const errorBanner = element.shadowRoot.querySelector('.rst-error');
        expect(errorBanner).not.toBeNull();
        expect(errorBanner.textContent).toContain('No refund found for this booking.');

        const progress = element.shadowRoot.querySelector('lightning-progress-indicator');
        expect(progress).toBeNull();
    });
});