# 🗳️ Online Voting App

This is a Flutter-based secure **Online Voting App** built as a demo for Aadhaar-based voting. It includes features like OTP-based login, nomination uploads (photo and video), admin panel, and optional face verification (using a Python-based backend).

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

Run the app using:

bash
Copy
Edit
flutter pub get
flutter run
📸 Screenshots
![IMG-20250427-WA0003](https://github.com/user-attachments/assets/ea11d8f2-3aaf-4445-a6f6-4ab9e71e7d8c)


🤝 Disclaimer
This project was built for demo purposes. It does not allow registration and is based on a closed Aadhaar-style structure. It’s not production-ready and is not authorized for actual Aadhaar integration. The source code is shared for learning and portfolio showcasing.

📫 Contact
If you have questions or want to understand the structure before replicating, feel free to reach out on [your email or LinkedIn].
