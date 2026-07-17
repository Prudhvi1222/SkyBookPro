# SkyBook Pro

SkyBook Pro is a Lightning Web Components app built on Salesforce for searching, booking, and managing flights. It features a custom dark "Aurora Night" theme with per-component display fonts, live airport autocomplete and flight search via the Duffel API, round-trip booking support, an agent dashboard with real-time booking stats, cancellation/refund tracking, and a full Jest test suite covering all 13 LWC components.

## Features

- Live airport autocomplete and flight search powered by the Duffel API
- Round-trip and one-way booking flows
- Passenger details capture and booking confirmation
- Agent dashboard with real-time booking statistics
- Cancellation and refund status tracking
- Custom dark "Aurora Night" theme
- Full Jest unit test coverage across all components

## Components

| Component | Purpose |
|---|---|
| `skyBookApp` | Top-level orchestrator |
| `flightSearchForm` | Flight search input and filters |
| `flightResultsList` / `flightResultCard` | Displays search results |
| `passengerDetailsForm` | Captures passenger information |
| `bookingConfirmation` | Confirms booking details before submission |
| `bookingSuccess` | Post-booking success screen |
| `myBookingsDashboard` | Customer's booking history and status |
| `agentDashboard` | Real-time booking stats for agents |
| `bookingDetailView` | Detailed view of a single booking |
| `cancellationModal` | Handles booking cancellations |
| `refundStatusTracker` | Tracks refund progress |
| `customDatatable` | Reusable data table component |

## Tech Stack

- Salesforce DX
- Lightning Web Components (LWC)
- Apex
- Lightning Message Service
- Duffel API (flight data)
- Jest (`sfdx-lwc-jest`) for unit testing

## Prerequisites

- [Salesforce CLI (sf)](https://developer.salesforce.com/tools/salesforcecli)
- Node.js and npm
- A Salesforce org (Developer Edition, sandbox, or scratch org)
- A Duffel API key

## Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/<your-username>/SkyBookPro-LWC.git
   cd SkyBookPro-LWC
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Authenticate with your Salesforce org:
   ```bash
   sf org login web --alias SkyBookOrg --instance-url https://login.salesforce.com
   ```

4. Deploy the source to your org:
   ```bash
   sf project deploy start --target-org SkyBookOrg
   ```

5. Assign any required permission sets (if applicable):
   ```bash
   sf org assign permset --name SkyBookPro_Permissions --target-org SkyBookOrg
   ```

6. Configure your Duffel API key in the appropriate Custom Metadata Type / Named Credential in Setup.

## Running Tests

Run the full Jest test suite:
```bash
npm run test:unit
```

Run tests in watch mode:
```bash
npm run test:unit:watch
```

Run tests with coverage:
```bash
npm run test:unit:coverage
```

## Project Structure

```
force-app/
└── main/
    └── default/
        ├── lwc/
        │   ├── skyBookApp/
        │   ├── flightSearchForm/
        │   ├── flightResultsList/
        │   ├── flightResultCard/
        │   ├── passengerDetailsForm/
        │   ├── bookingConfirmation/
        │   ├── bookingSuccess/
        │   ├── myBookingsDashboard/
        │   ├── agentDashboard/
        │   ├── bookingDetailView/
        │   ├── cancellationModal/
        │   ├── refundStatusTracker/
        │   └── customDatatable/
        └── classes/
```

## License

Add your chosen license here (e.g. MIT).
