import { LightningElement, track } from 'lwc';
import searchFlights from '@salesforce/apex/DuffelFlightSearchService.searchFlights';
import findOrCreatePassengerContact from '@salesforce/apex/ContactService.findOrCreatePassengerContact';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const GOOGLE_FONTS_HREF =
    'https://fonts.googleapis.com/css2' +
    '?family=Fraunces:opsz,wght@9..144,600;9..144,700;9..144,800' +
    '&family=Space+Grotesk:wght@600;700' +
    '&family=Lexend:wght@600;700' +
    '&family=Sora:wght@600;700' +
    '&family=Unbounded:wght@700;800' +
    '&family=Syne:wght@700;800' +
    '&family=Outfit:wght@600;700' +
    '&family=DM+Sans:wght@600;700' +
    '&family=Urbanist:wght@600;700' +
    '&family=Work+Sans:wght@600;700' +
    '&family=Figtree:wght@600;700' +
    '&family=Manrope:wght@700;800' +
    '&family=Inter:wght@400;500;600;700' +
    '&display=swap';
const GOOGLE_FONTS_LINK_ID = 'skybook-aurora-night-fonts';

export default class SkyBookApp extends LightningElement {
    @track flightOffers = [];
    @track selectedOffer;
    @track passengers = [];
    @track createdBooking;

    isLoading = false;
    hasSearched = false;
    currentStep = 'search';

    @track contactId;

    connectedCallback() {
        this.loadAuroraNightFonts();
    }

    // LWC's CSS compiler does not support @import, so the "Aurora Night" theme
    // fonts (Plus Jakarta Sans / Inter) are loaded once here instead. This only
    // touches the document head for a <link> tag - no Apex/backend involved.
    loadAuroraNightFonts() {
        if (typeof document === 'undefined') {
            return;
        }
        if (document.getElementById(GOOGLE_FONTS_LINK_ID)) {
            return;
        }
        const link = document.createElement('link');
        link.id = GOOGLE_FONTS_LINK_ID;
        link.rel = 'stylesheet';
        link.href = GOOGLE_FONTS_HREF;
        document.head.appendChild(link);
    }

    get passengerCount() {
        return this.selectedOffer?.seatsRequested || 1;
    }

    get isSearchStep() {
        return this.currentStep === 'search';
    }

    get isSelectedFlightStep() {
        return this.currentStep === 'selectedFlight';
    }

    get isPassengerStep() {
        return this.currentStep === 'passenger';
    }

    get isConfirmationStep() {
        return this.currentStep === 'confirmation';
    }

    get isSuccessStep() {
        return this.currentStep === 'success';
    }

    get isMyBookingsStep() {
        return this.currentStep === 'myBookings';
    }

    get hasResults() {
        return this.flightOffers && this.flightOffers.length > 0;
    }

    get hasSearchedWithoutResults() {
        return this.hasSearched && !this.isLoading && !this.hasResults;
    }

    // ---- Nav bar link styling ----
    get searchNavClass() {
        return this.isSearchStep
            ? 'skybook-nav-link skybook-nav-active'
            : 'skybook-nav-link';
    }

    get bookingsNavClass() {
        return this.isMyBookingsStep
            ? 'skybook-nav-link skybook-nav-active'
            : 'skybook-nav-link';
    }

    // ---- Step tab bar styling (steps 2-5) ----
    get flightTabClass() {
        return this.isSelectedFlightStep
            ? 'skybook-step-tab skybook-step-tab-active'
            : 'skybook-step-tab';
    }

    get passengerTabClass() {
        return this.isPassengerStep
            ? 'skybook-step-tab skybook-step-tab-active'
            : 'skybook-step-tab';
    }

    get confirmTabClass() {
        return this.isConfirmationStep
            ? 'skybook-step-tab skybook-step-tab-active'
            : 'skybook-step-tab';
    }

    get successTabClass() {
        return this.isSuccessStep
            ? 'skybook-step-tab skybook-step-tab-active'
            : 'skybook-step-tab';
    }

    // ---- Nav bar actions ----
    goToSearchNav() {
        this.currentStep = 'search';
        this.hasSearched = false;
        this.flightOffers = [];
        this.selectedOffer = null;
    }

    goToBookingsNav() {
        this.currentStep = 'myBookings';
    }

    // ---- Search flow ----
    async handleFlightSearch(event) {
        const criteria = event.detail;

        this.isLoading = true;
        this.hasSearched = true;
        this.flightOffers = [];
        this.selectedOffer = null;

        try {
            const results = await searchFlights({
                origin: criteria.origin,
                destination: criteria.destination,
                departureDate: criteria.departureDate,
                returnDate: criteria.tripType === 'roundtrip' ? criteria.returnDate : null,
                tripType: criteria.tripType,
                cabinClass: criteria.cabinClass,
                adults: criteria.adults
            });

            this.flightOffers = (results || []).map((offer) => {
                return {
                    ...offer,
                    seatsRequested: criteria.adults,
                    cabinClass: offer.cabinClass || criteria.cabinClass || 'Economy'
                };
            });

            if (this.flightOffers.length === 0) {
                this.showToast(
                    'No Flights Found',
                    'No available flights found for the selected criteria.',
                    'warning'
                );
            }
        } catch (error) {
            this.showToast(
                'Flight Search Failed',
                this.reduceError(error),
                'error'
            );
        } finally {
            this.isLoading = false;
        }
    }

    handleOfferSelected(event) {
        this.selectedOffer = event.detail;

        if (!this.selectedOffer || !this.selectedOffer.flightId) {
            this.showToast(
                'Invalid Flight Selection',
                'Selected offer does not have a Flight Id. Please search again.',
                'error'
            );
            return;
        }

        this.currentStep = 'selectedFlight';
    }

    goToPassengerStep() {
        this.currentStep = 'passenger';
    }

    async handlePassengersReady(event) {
        this.passengers = event.detail.passengers;

        const primaryPassenger = this.passengers[0];

        if (!primaryPassenger?.email || !primaryPassenger?.phone) {
            this.showToast(
                'Contact Details Required',
                'Please provide an email and phone number for the primary passenger.',
                'error'
            );
            return;
        }

        this.isLoading = true;

        try {
            this.contactId = await findOrCreatePassengerContact({
                firstName: primaryPassenger.firstName,
                lastName: primaryPassenger.lastName,
                email: primaryPassenger.email,
                phone: primaryPassenger.phone
            });

            this.currentStep = 'confirmation';
        } catch (error) {
            this.showToast(
                'Contact Setup Failed',
                this.reduceError(error),
                'error'
            );
        } finally {
            this.isLoading = false;
        }
    }

    handleBookingCreated(event) {
        this.createdBooking = event.detail.booking;
        this.currentStep = 'success';
    }

    goBackToSearch() {
        this.currentStep = 'search';
    }

    goBackToSelectedFlight() {
        this.currentStep = 'selectedFlight';
    }

    goBackToPassengerStep() {
        this.currentStep = 'passenger';
    }

    handleSearchAgain() {
        this.flightOffers = [];
        this.selectedOffer = null;
        this.passengers = [];
        this.createdBooking = null;
        this.hasSearched = false;
        this.currentStep = 'search';
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map((e) => e.message).join(', ');
        }

        if (typeof error?.body?.message === 'string') {
            return error.body.message;
        }

        if (typeof error?.message === 'string') {
            return error.message;
        }

        return 'Unknown error occurred.';
    }
}