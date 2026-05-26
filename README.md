# RoadSOS AI 🛡️

RoadSOS AI is an AI-powered emergency assistance application built with Flutter. It helps users report road accidents, receive instant AI-driven severity assessments, and find nearby emergency services (hospitals and police stations) in seconds.

## 🚀 Key Features
*   **One-Tap Reporting:** A large, accessible SOS button for high-stress situations.
*   **AI Accident Analysis:** Uses **Gemini 1.5 Flash** to analyze accident photos and descriptions for injuries and severity.
*   **Live Emergency Map:** Integrates **Google Maps & Places API** to find the 10 nearest hospitals and police stations.
*   **Dynamic First Aid:** Provides tailored first-aid guidance based on the detected accident severity (Minor, Moderate, or Critical).
*   **Cross-Platform:** Runs on Android, iOS, and Web.

## 🛠️ Tech Stack
*   **Frontend:** Flutter (Dart)
*   **AI Engine:** Google Gemini AI (using `google_generative_ai` SDK)
*   **Maps/Location:** Google Maps SDK, Google Places API, Geolocator
*   **Environment:** `flutter_dotenv` for secure API key management

## 📋 Prerequisites
*   Flutter SDK (Stable channel)
*   Google Gemini API Key
*   Google Maps API Key (with Billing Enabled for Places API)

## ⚙️ Setup Instructions
1.  **Clone the project:**
    ```bash
    git clone <your-repo-url>
    cd roadsos_ai
    ```
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Configure API Keys:**
    Create a `.env` file in the root directory and add your keys:
    ```env
    GEMINI_API_KEY=your_gemini_key_here
    GOOGLE_MAPS_API_KEY=your_google_maps_key_here
    ```
4.  **Register Assets:**
    Ensure the `.env` file is listed under `assets` in `pubspec.yaml`.

## 🏃 Running the App
*   **Web (Chrome):**
    ```bash
    flutter run -d chrome
    ```
*   **Android/iOS:**
    ```bash
    flutter run
    ```

---
Built with ❤️ for Road Safety.
