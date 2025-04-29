# 🗳️ Online Voting App

This is a Flutter-based secure Online Voting App built as a demo for Aadhaar-based digital elections in India. It showcases a full-stack implementation of a voting system tailored for transparency and security, especially for government-scale deployments.

## 🔐 Key Features
Aadhaar-based role-based login system (Voter, Candidate, EC Employee/Admin)

Three-factor authentication for voting:

OTP verification (via Twilio)

Face recognition (Python + HuggingFace hosted server)

Local biometric authentication (e.g., fingerprint or face unlock)

Nomination system: Candidates can upload video and photo via GitHub integration

Admin panel (Election Commission Employee) to:

Create/manage elections

Approve or reject nominations

View and monitor voting activity

Firebase Firestore used for real-time data handling

No public registration – voters/candidates must be pre-registered manually via Aadhaar number in Firestore


> 🔐 **Note**: This project was developed for educational/demo purposes and cannot be run directly unless proper API keys and authentication services are configured.

---

## 🚀 Features

- Aadhaar-based user login (no new user registration allowed)
- Firebase authentication and Firestore database
- OTP service using **Twilio**
- Nomination submission (image and video upload to GitHub)
- Admin panel for managing elections and candidates
- Face authentication using a Python server
- Firebase hosting structure for data access

---

## ⚠️ Important Setup Notes

This project will **NOT run out-of-the-box** due to the following reasons:

### 🔑 Firebase Setup
- The app uses Firebase Authentication and Firestore.
- **No new user registration is allowed.**
- Only predefined users (added manually in Firebase Auth) can login using OTP.
- You must **create your own Firebase project** and replicate the **database structure** used in the app.
- Update the Firebase configuration in `main.dart` accordingly.

### 🔐 OTP Service - Twilio
- The OTP-based login requires **Twilio**.
- You must create a Twilio account and generate:
  - `AUTHKEY`
  - `API KEY`
  - Twilio phone number
- These should be configured in:
  - `relogin_screen.dart`
  - `otp_screen.dart`

### 🖼️ Nomination Uploads (Photo/Video)
- Nomination photos and videos are uploaded to a private GitHub repo using the GitHub API.
- You need to **generate a GitHub personal access token (PAT)** and replace it in the relevant section.
- The file upload functionality is handled in `nominati_screen.dart`.

### 🧠 Face Authentication (Optional)
- The app supports face verification using a Python-based backend (Flask server).
- I’ve deployed this backend on **Hugging Face Spaces (Free tier)** for demo purposes.
- If you want to use this feature:
  - Clone the Python backend (I can provide the repo on request)
  - Deploy it on your own server or Hugging Face Space
  - Update the backend URL in your app code.

---

## 🛠️ How to Run the App

1. Clone the repository:
   ```bash
   git clone https://github.com/jaikishore3130/voting.git
Setup your Firebase project and integrate the config in main.dart

Configure Twilio keys and GitHub token in the respective files

**Run the app using:**
  flutter pub get
  flutter run
##📸 Screenshots

![IMG-20250427-WA0003](https://github.com/user-attachments/assets/ea11d8f2-3aaf-4445-a6f6-4ab9e71e7d8c)

![IMG-20250427-WA0004](https://github.com/user-attachments/assets/6152de6a-4586-4b44-9412-687f9140f72d)
![IMG-20250427-WA0005](https://github.com/user-attachments/assets/de55360d-14a3-4c18-b05b-7162d4f6d448)
![IMG-20250427-WA0006](https://github.com/user-attachments/assets/495a1b29-ea64-4b52-9df7-398b0b7a550c)
![IMG-20250427-WA0007](https://github.com/user-attachments/assets/a7592d27-24a6-4b96-9d8e-31bb9ca07cd1)
![IMG-20250427-WA0008](https://github.com/user-attachments/assets/0d09bc9a-9c00-48de-b282-29c0101b5121)
![IMG-20250427-WA0009](https://github.com/user-attachments/assets/c5e780f9-1f57-4c27-9fc6-b79fdf230192)
![IMG-20250428-WA0001](https://github.com/user-attachments/assets/d430a828-b933-4604-a5f9-fee474b6f636)
![IMG-20250427-WA0014](https://github.com/user-attachments/assets/164b2cd4-1b13-4370-b354-7679b5136285)
![IMG-20250428-WA0002](https://github.com/user-attachments/assets/af54f4d6-3253-4df6-9787-535a51a9be52)![IMG-20250428-WA0012](https://github.com/user-attachments/assets/5fd2b0f0-5a90-45eb-ab50-716ec74b7d0b)![IMG-20250428-WA0013](https://github.com/user-attachments/assets/c8cf67cc-08d6-4f28-b389-49a98c67fd64)![IMG-20250428-WA0014](https://github.com/user-attachments/assets/c58dd983-89b2-4be5-95b3-ad267dda6d83)![IMG-20250428-WA0016](https://github.com/user-attachments/assets/6ec5afa3-b772-400c-826e-dd2adc77592e)![IMG-20250428-WA0017](https://github.com/user-attachments/assets/de704dae-1356-479e-a9ed-e533edc0b03a)![e](https://github.com/user-attachments/assets/1983bd5d-bce3-45c2-9ceb-72c2740a70ee)![IMG-20250428-WA0020](https://github.com/user-attachments/assets/bac1ef96-31bd-45f2-a111-d0a7a7411f17)
 etc....















🤝 Disclaimer
This project was built for demo purposes. It does not allow registration and is based on a closed Aadhaar-style structure. It’s not production-ready and is not authorized for actual Aadhaar integration. The source code is shared for learning and portfolio showcasing.

📫 Contact
If you have questions or want to understand the structure before replicating, feel free to reach out on [E-Mail-jaikishore.333.raju@gmail or Linkedin-https://www.linkedin.com/in/jai-kishore-raju31?utm_source=share&utm_campaign=share_via&utm_content=profile&utm_medium=android_app ].
📁 firebase_structure.md
markdown
Copy
Edit
# 🔥 Firebase Firestore Structure for Online Voting App

To make this app work, users must set up their **own Firebase project** and replicate the database structure outlined below. The app does **not allow new user registrations** — Aadhaar-based users must be manually added to Firestore. OTP, face authentication, and candidate nomination also rely on external services you must configure separately.

---

## 📂 Firestore Collections & Document Structure

### 1. `/voters/{aadhaar_number}`
- Stores voter details using Aadhaar as the document ID.

#### Example:
```json
{
  "name": "John Doe",
  "aadhaar": "644854219657",
  "phone": "+91XXXXXXXXXX",
  "dob": "1999-01-01",
  "hasVoted": false,
  "verified": true
}
```
2. /election_status/lok/lok_sabha_04-24-2025_12-09-26/party/list/BJP/candidates/{aadhaar_number}
Stores candidate nomination info under party-wise sub-collections.

Example:
```json

{
  "name": "Jane Smith",
  "aadhaar": "644854219657",
  "party": "BJP",
  "constituency": "XYZ",
  "photo_url": "GitHub image link",
  "video_url": "GitHub video link"
}
```
3. /election_status/lok_sabha/lok_sabha_04-19-2024/election_info
Contains information about a specific election session.

Example:
```json

{
  "status": "active",
  "start_date": "2024-04-19",
  "end_date": "2024-04-24",
  "type": "Lok Sabha"
}
```
4. /EC_EMPLOYEES/{employee_aadhaar}
Election Commission employee login data.

Example:
```json

{
  "name": "EC Officer",
  "aadhaar": "007054726553",
  "role": "ec",
  "verified": true
}
```
⚠️ Important Notes
You must manually add users and EC employees to Firestore. No new registration flow is provided in the app.

Make sure to match the structure exactly or the app will not function correctly.

🔧 Services & Tokens You Must Setup
✅ Firebase
Create your own Firebase project.

Replace google-services.json and reconfigure in your app.

✅ OTP (Twilio)
Used in relogin_screen.dart and otp_screen.dart

You must configure:

TWILIO_AUTH_TOKEN

TWILIO_API_KEY

TWILIO_PHONE_NUMBER

✅ GitHub Token (for nominee image/video uploads)
Required for uploading nominee photos/videos in nominate_screen.dart

✅ Face Authentication Server
Python-based server for face detection

Hosted by default on HuggingFace (Free Tier)

You may host your own using provided Python script.

📌 Deployment Tips
Clone the repo

Replace Firebase credentials

Setup Firestore as per the above structure

Configure Twilio and GitHub tokens

Optional: Deploy your own face authentication server

