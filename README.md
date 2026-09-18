# StudyBuddy — Python Mobile Web App

Responsive, installable Flask mobile web app matching the supplied UI. It includes sign-in, task creation/filtering/completion/deletion, deadline calendar, study groups, and live progress.

## Development server

```bash
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\\Scripts\\activate
pip install -r requirements.txt
flask --app app run --debug --host 0.0.0.0
```

Open `http://127.0.0.1:5000`, or `http://<computer-ip>:5000` from a phone on the same network. Use the pre-filled demo login.

Run tests with `pytest -q`. Development data resets when the server restarts.
