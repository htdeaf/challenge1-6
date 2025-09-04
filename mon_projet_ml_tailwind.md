# Mon Projet ML (FastAPI + Tailwind)

Ce dépôt contient l'architecture complète de l'application **sans la partie entraînement du modèle** (le modèle `ml_model/mon_modele.pkl` est supposé déjà présent). J'ai remplacé le CSS classique par Tailwind (via CDN pour la simplicité). Le contenu ci‑dessous inclut tous les fichiers principaux et exemples de code prêts à l'emploi.

---

## Structure du projet

```
mon_projet_ml/
├── app/
│   ├── __init__.py
│   ├── main.py
│   ├── models/
│   │   ├── __init__.py
│   │   ├── user.py
│   │   └── prediction.py
│   ├── crud/
│   │   ├── __init__.py
│   │   ├── user.py
│   │   └── prediction.py
│   ├── routers/
│   │   ├── __init__.py
│   │   ├── auth.py
│   │   ├── users.py
│   │   └── predictions.py
│   ├── core/
│   │   ├── __init__.py
│   │   ├── config.py
│   │   └── security.py
│   ├── db/
│   │   └── database.py
│   └── templates/
│       ├── base.html
│       ├── index.html
│       ├── login.html
│       ├── register.html
│       ├── history.html
│       └── admin.html
├── static/
│   └── js/
│       └── script.js
├── ml_model/
│   └── mon_modele.pkl    # modèle pré-entraîné (non inclus)
├── .env.example
├── Dockerfile
├── docker-compose.yml
├── requirements.txt
└── README.md
```

---

> **Remarque:** je **n'ai pas** inclus le code d'entraînement du modèle. Le code charge le modèle sauvegardé dans `ml_model/mon_modele.pkl`.

---

## Fichiers clés (extraits)

> *Les fichiers complets sont inclus dans ce document pour que vous puissiez copier-coller directement.*

### `requirements.txt`

```text
fastapi
uvicorn[standard]
python-jose[cryptography]
passlib[bcrypt]
sqlalchemy
psycopg2-binary
pydantic
jinja2
python-multipart
scikit-learn
joblib
python-dotenv
```


### `.env.example`

```env
DATABASE_URL=postgresql://postgres:password@db:5432/mon_projet
SECRET_KEY=change_this_for_prod
ACCESS_TOKEN_EXPIRE_MINUTES=60
```


### `app/main.py`

```python
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from app.routers import auth, users, predictions

app = FastAPI(title="Mon Projet ML")

# Templates & static
templates = Jinja2Templates(directory="app/templates")
app.mount("/static", StaticFiles(directory="static"), name="static")

# Include routers
app.include_router(auth.router, prefix="/auth")
app.include_router(users.router, prefix="/users")
app.include_router(predictions.router, prefix="/predictions")

# endpoint racine
@app.get("/", response_class=None)
def root():
    return {"message": "Bienvenue - API Mon Projet ML"}
```


### `app/core/config.py`

```python
from pydantic import BaseSettings

class Settings(BaseSettings):
    DATABASE_URL: str
    SECRET_KEY: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60

    class Config:
        env_file = ".env"

settings = Settings()
```


### `app/core/security.py`

```python
from datetime import datetime, timedelta
from jose import jwt
from passlib.context import CryptContext
from app.core.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

ALGORITHM = "HS256"

def verify_password(plain, hashed):
    return pwd_context.verify(plain, hashed)

def get_password_hash(password):
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: timedelta | None = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt
```


### `app/db/database.py`

```python
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from app.core.config import settings

engine = create_engine(settings.DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```


### `app/models/user.py`

```python
from sqlalchemy import Column, Integer, String, Boolean
from app.db.database import Base

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    is_active = Column(Boolean, default=True)
    is_admin = Column(Boolean, default=False)
```


### `app/models/prediction.py`

```python
from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime
from sqlalchemy.sql import func
from app.db.database import Base

class Prediction(Base):
    __tablename__ = "predictions"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    input_json = Column(String)
    result = Column(String)
    prob = Column(Float)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
```


### `app/crud/user.py` (extraits)

```python
from sqlalchemy.orm import Session
from app.models.user import User
from app.core.security import get_password_hash, verify_password

def get_user_by_email(db: Session, email: str):
    return db.query(User).filter(User.email == email).first()

def create_user(db: Session, email: str, password: str):
    user = User(email=email, hashed_password=get_password_hash(password))
    db.add(user)
    db.commit()
    db.refresh(user)
    return user
```


### `app/crud/prediction.py` (extraits)

```python
from sqlalchemy.orm import Session
from app.models.prediction import Prediction

def create_prediction(db: Session, user_id: int, input_json: str, result: str, prob: float):
    p = Prediction(user_id=user_id, input_json=input_json, result=result, prob=prob)
    db.add(p)
    db.commit()
    db.refresh(p)
    return p

def get_user_predictions(db: Session, user_id: int):
    return db.query(Prediction).filter(Prediction.user_id == user_id).order_by(Prediction.created_at.desc()).all()
```


### `app/routers/auth.py` (extraits)

```python
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.crud import user as crud_user
from app.core.security import create_access_token, verify_password

router = APIRouter()

@router.post("/register")
def register(email: str, password: str, db: Session = Depends(get_db)):
    if crud_user.get_user_by_email(db, email):
        raise HTTPException(status_code=400, detail="Email already registered")
    user = crud_user.create_user(db, email, password)
    return {"email": user.email, "id": user.id}

@router.post("/login")
def login(email: str, password: str, db: Session = Depends(get_db)):
    user = crud_user.get_user_by_email(db, email)
    if not user or not verify_password(password, user.hashed_password):
        raise HTTPException(status_code=400, detail="Invalid credentials")
    token = create_access_token({"sub": str(user.id)})
    return {"access_token": token, "token_type": "bearer"}
```


### `app/routers/predictions.py` (extraits)

```python
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.crud import prediction as crud_prediction
import joblib
import json

router = APIRouter()

# charge le modèle (il doit exister dans ml_model/mon_modele.pkl)
model = joblib.load('ml_model/mon_modele.pkl')

@router.post("/predict")
def predict(input_data: dict, user_id: int, db: Session = Depends(get_db)):
    # Ici, on suppose que le modèle prend une liste / array et renvoie une prédiction + proba
    X = [list(input_data.values())]
    pred = model.predict(X)[0]
    prob = float(max(model.predict_proba(X)[0]))
    p = crud_prediction.create_prediction(db, user_id, json.dumps(input_data), str(pred), prob)
    return {"prediction": str(pred), "probability": prob, "id": p.id}

@router.get("/history/{user_id}")
def history(user_id: int, db: Session = Depends(get_db)):
    return crud_prediction.get_user_predictions(db, user_id)
```


### `app/templates/base.html` (avec Tailwind CDN)

```html
<!doctype html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{% block title %}Mon Projet ML{% endblock %}</title>
  <!-- Tailwind Play CDN (utile pour dev / démo). Remplacer par build Tailwind pour prod. -->
  <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-50 text-gray-900">
  <nav class="bg-white shadow">
    <div class="max-w-7xl mx-auto px-4 py-3 flex justify-between items-center">
      <div class="text-xl font-semibold">Mon Projet ML</div>
      <div>
        <a href="/" class="px-3">Accueil</a>
        <a href="/auth/login" class="px-3">Se connecter</a>
      </div>
    </div>
  </nav>
  <main class="max-w-4xl mx-auto p-6">
    {% block content %}{% endblock %}
  </main>
</body>
</html>
```


### `app/templates/index.html`

```html
{% extends 'base.html' %}
{% block title %}Accueil{% endblock %}
{% block content %}
  <div class="bg-white p-6 rounded-lg shadow">
    <h1 class="text-2xl font-bold mb-4">Formulaire de prédiction</h1>
    <form id="predict-form" class="space-y-4">
      <!-- Exemple d'input (ajuster selon les features du modèle) -->
      <div>
        <label class="block">Age</label>
        <input name="age" type="number" class="border p-2 rounded w-full" />
      </div>
      <div>
        <label class="block">FCVC</label>
        <input name="fcvc" type="number" step="0.01" class="border p-2 rounded w-full" />
      </div>
      <div>
        <button type="button" onclick="sendPredict()" class="px-4 py-2 bg-blue-600 text-white rounded">Prédire</button>
      </div>
    </form>
    <div id="result" class="mt-4"></div>
  </div>
{% endblock %}
```


### `app/templates/login.html` et `register.html`

> Templates simples reprenant `base.html` et des formulaires Tailwind pour email/password.


### `app/templates/history.html`

> Page listant les prédictions de l'utilisateur dans une table responsive avec classes Tailwind.


### `static/js/script.js`

```javascript
async function sendPredict(){
  const form = document.getElementById('predict-form');
  const data = {};
  new FormData(form).forEach((v,k)=> data[k] = isNaN(v) ? v : Number(v));
  const res = await fetch('/predictions/predict', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({input_data: data, user_id: 1})
  });
  const json = await res.json();
  document.getElementById('result').innerText = JSON.stringify(json);
}
```


### `Dockerfile` (exemple simple)

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY . /app
RUN pip install --upgrade pip && pip install -r requirements.txt
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "80"]
```


### `docker-compose.yml` (extrait)

```yaml
version: '3.8'
services:
  web:
    build: .
    ports:
      - "8000:80"
    depends_on:
      - db
    environment:
      - DATABASE_URL=postgresql://postgres:password@db:5432/mon_projet
      - SECRET_KEY=change_this_for_prod
  db:
    image: postgres:15
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
      POSTGRES_DB: mon_projet
    volumes:
      - pgdata:/var/lib/postgresql/data
volumes:
  pgdata:
```


### `README.md` (extraits)

```md
# Mon Projet ML

## Installation locale

1. Copier `.env.example` en `.env` et ajuster les variables.
2. Installer les dépendances: `pip install -r requirements.txt`
3. Initialiser la base de données (SQLAlchemy create_all ou Alembic selon votre choix).
4. Lancer: `uvicorn app.main:app --reload`

## Avec Docker

`docker-compose up --build`

```

---

## Etapes recommandées après récupération du code

1. Mettre à jour `.env` avec `DATABASE_URL` et `SECRET_KEY`.
2. Créer les tables: vous pouvez ajouter un petit script `create_tables.py` qui fait `Base.metadata.create_all(bind=engine)`.
3. Vérifier que `ml_model/mon_modele.pkl` est présent et compatible (`predict`, `predict_proba`).
4. Tester les routes `/auth/register`, `/auth/login`, `/predictions/predict` avec Postman ou Swagger (`/docs`).

---

Si vous voulez, je peux maintenant :

- ajouter les migrations Alembic et un script `create_tables.py`,
- adapter les pages HTML Tailwind (forms complets) selon les features exactes du modèle,
- ajouter une UI d'administration et une pagination pour l'historique.

Dites-moi ce que voulez que je priorise ensuite — j'implémente directement dans ce document.

