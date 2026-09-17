# StudyBuddy

StudyBuddy is a responsive Flutter application for university students to organise coursework, manage deadlines, collaborate in study groups, share notes, and monitor progress. It implements the mobile proposal prepared for ICT725 Assessment 3 and provides the working front end required for Assessment 4.

## Implemented workflows

### 1. Task and deadline management

- Register or sign in
- Create, edit, prioritise, and delete assignments
- Choose a due date and add supporting notes
- Filter pending and completed tasks
- Mark work complete
- View deadlines chronologically
- See overall and per-course progress update immediately

### 2. Study-group collaboration

- Create a study group for a course
- Open a group discussion
- Send locally persisted messages
- Create and read shared notes
- View group activity counts

## Additional features

- Responsive bottom navigation on phones and NavigationRail on larger screens
- Material 3 design with consistent colour, spacing, and components
- Form validation, empty states, confirmation feedback, and accessible controls
- Offline persistence through SharedPreferences
- Seed demonstration data for a reliable emulator presentation
- Dashboard statistics and quick actions

## Run the application

Install the Flutter SDK, then run:

```bash
flutter create .
flutter pub get
flutter run
```

The `flutter create .` command generates platform folders such as `android/`, `ios/`, and `web/` without replacing the existing application source.

## Test and analyse

```bash
flutter analyze
flutter test
```

## Demonstration account

The sign-in form contains demonstration credentials:

- Email: `student@studybuddy.app`
- Password: `study123`

Authentication is intentionally implemented as a front-end prototype with local persistence. Production deployment would replace it with a secure service such as Firebase Authentication and a remote collaboration database.

## Suggested Assessment 4 demonstration

1. Sign in and explain the responsive dashboard.
2. Open Tasks and create a high-priority ICT725 assignment.
3. Edit it, then mark it complete.
4. Show the deadline calendar and updated progress.
5. Open the Mobile App Study Team.
6. Send a discussion message and share a note.
7. Restart the app to demonstrate local persistence.

## Project structure

- `lib/main.dart` — data models, local persistence, navigation, and application screens
- `test/widget_test.dart` — initial widget test
- `pubspec.yaml` — Flutter dependencies and application metadata
- `analysis_options.yaml` — static-analysis rules

## Scope and future work

The current submission is a functional front-end prototype. Future iterations can add Firebase authentication, cloud synchronisation, push notifications, file uploads, real-time messaging, calendar reminders, and automated accessibility tests.
