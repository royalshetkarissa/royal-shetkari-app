# Royal Shetkari Backend API

Production-grade Node.js + Express API for the Royal Shetkari application.

## 🚀 Features
- **Clean Architecture**: Controller-Service-Repository pattern.
- **Security**: JWT Refresh Tokens, Rate Limiting, Helmet.js.
- **Validation**: Strict schema validation with Zod.
- **Logging**: Structured JSON logs with Winston.
- **Database**: PostgreSQL with connection pooling and retry logic.

## 🛠 Setup & Installation

### 1. Environment Configuration
Copy the example environment file and fill in your secrets:
```bash
cp .env.example .env
```

### 2. Install Dependencies
```bash
npm install
```

### 3. Database Migration
```bash
node ../database/migrate.js up
```

### 4. Run Development Server
```bash
npm run dev
```

## 🐳 Production Deployment (Docker)
Ensure your `.env` is configured, then run:
```bash
docker-compose -f docker-compose.prod.yml up -d
```

## 🧪 Testing
```bash
npm test
```
