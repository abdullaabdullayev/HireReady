<div align="center">

# 🎯 HireReady

### AI-powered interview preparation — practice, get instant feedback, get hired.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.x-6DB33F?logo=springboot&logoColor=white)](https://spring.io/projects/spring-boot)
[![Java](https://img.shields.io/badge/Java-21-orange?logo=openjdk&logoColor=white)](https://openjdk.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Database-4169E1?logo=postgresql&logoColor=white)](https://www.postgresql.org)

*Practice. Improve. Get hired.*

</div>

---

## 📖 Overview

**HireReady** is a full-stack mobile app that helps job seekers prepare for interviews.
Pick a role and level, answer real interview questions **by text or voice**, and get
**instant AI-graded feedback** with a score, actionable notes, and a model answer.

The app tracks your progress over time — daily streaks, weekly activity, and a
per-category skills breakdown — so you can see exactly where you're improving.

## ✨ Features

- 🔐 **Secure auth** — register/login with JWT access + refresh tokens (auto-refresh)
- 🧑‍💼 **Role & level selection** — tailored question sets per role and seniority
- 📄 **Optional uploads** — drop in your resume, reference docs, or your own questions file
- ✍️ **Answer by text or 🎙️ voice** — real on-device speech-to-text transcription
- 🤖 **AI evaluation** — answers graded by an LLM with score + specific feedback
- 📊 **Progress analytics** — sessions, questions, average score, day streak, weekly chart, skills breakdown
- ☁️ **Cloud file storage** — uploaded documents stored on Cloudflare R2

## 🏗️ Architecture

A clean **client–server** design: the Flutter app is purely the UI; all logic —
question selection, AI grading, analytics — lives in the Spring Boot backend.

```
┌─────────────────┐        REST / JWT        ┌──────────────────────┐
│   Flutter app   │  ───────────────────────▶│   Spring Boot API     │
│  (Android/iOS)  │ ◀─────────────────────── │                       │
└─────────────────┘                          │  ├─ Auth (JWT)        │
                                             │  ├─ Sessions          │
                                             │  ├─ AI Evaluation ────┼──▶ Groq (LLM)
                                             │  ├─ Documents ────────┼──▶ Cloudflare R2
                                             │  └─ Analytics         │
                                             └──────────┬───────────┘
                                                        │
                                                  ┌─────▼─────┐
                                                  │ PostgreSQL│
                                                  └───────────┘
```

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Flutter (Dart) |
| **Backend** | Java 21, Spring Boot, Spring Security |
| **Database** | PostgreSQL |
| **Auth** | JWT (access + refresh), BCrypt |
| **AI** | Groq (Llama) for answer evaluation |
| **Voice** | Device speech-to-text |
| **Storage** | Cloudflare R2 (S3-compatible) |

## 📂 Project Structure

```
HireReady/
├── frontend/          # Flutter mobile app
│   └── lib/
│       ├── screens/   # UI screens (auth, dashboard, practice, progress…)
│       ├── services/  # API clients (auth, session, document, analytics…)
│       ├── state/     # App state
│       └── widgets/   # Reusable widgets
└── backend/           # Spring Boot API
    └── src/main/java/com/hireready/
        ├── auth/        # Registration, login, JWT
        ├── user/        # User profile
        ├── job/         # Job-role catalog
        ├── document/    # File upload (R2) + text extraction
        ├── question/    # System question bank
        ├── session/     # Practice sessions + evaluation
        ├── answer/      # Answer records
        ├── analytics/   # Progress statistics
        └── ai/          # LLM client
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK
- Java 21 + Gradle
- PostgreSQL
- A Groq API key and Cloudflare R2 bucket

### Backend
```bash
cd backend
# Create a .env with: JWT_SECRET, DB_USERNAME, DB_PASSWORD,
#                     GROQ_API_KEY, R2_ACCOUNT_ID, R2_ACCESS_KEY,
#                     R2_SECRET_KEY, R2_BUCKET
./gradlew bootRun
```

### Frontend
```bash
cd frontend
flutter pub get
flutter run
```

> **Device note:** Android emulator reaches the backend at `10.0.2.2:8080`.
> A USB-connected phone uses `adb reverse tcp:8080 tcp:8080` with `127.0.0.1:8080`.

## 🔑 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/auth/register` | Create account |
| `POST` | `/api/auth/login` | Log in → tokens |
| `POST` | `/api/auth/refresh` | Refresh access token |
| `GET`  | `/api/roles` | Job-role catalog |
| `POST` | `/api/documents` | Upload a file |
| `POST` | `/api/sessions` | Start a session → questions |
| `POST` | `/api/sessions/{id}/answers` | Submit & grade an answer |
| `POST` | `/api/sessions/{id}/complete` | Finish → summary |
| `GET`  | `/api/analytics` | Progress statistics |
| `GET`  | `/api/users/me` | Current profile |

## 👤 Author

**Abdulla Abdullayev**
[GitHub](https://github.com/abdullaabdullayev)

---

<div align="center">
<sub>Built with Flutter & Spring Boot</sub>
</div>
