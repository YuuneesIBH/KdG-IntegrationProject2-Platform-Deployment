# Deployment Handover Document (Voor ISB)

## Services Overview
Dit project bestaat uit de volgende containers die gedeployed moeten worden. De images worden gebouwd via onze CI/CD pipelines en staan in de GitLab Container Registry.

| Service Naam          | Registry Image Path (Voorbeeld)       | Poort (Intern) | Afhankelijkheden             |
|:----------------------|:--------------------------------------|:---------------|:-----------------------------|
| **Backend Platform**  | `.../backend-platform-service:latest` | 8000           | Postgres, RabbitMQ, Keycloak |
| **Backend Game**      | `.../backend-game-service:latest`     | 8080           | Postgres, RabbitMQ           |
| **Frontend Platform** | `.../frontend-platform:latest`        | 80             | Backend Platform             |
| **Frontend Blokus**   | `.../frontend-blokus:latest`          | 80             | Backend Game                 |

## Environment Variables Configuration
De volgende variabelen moeten als *Secrets* of *ConfigMaps* in Kubernetes worden ingesteld.

### Backend Platform Service
- `DATABASE_URL`: `jdbc:postgresql://<db-host>:5432/<db-name>`
- `DATABASE_USER`: Gebruikersnaam
- `DATABASE_PASSWORD`: Wachtwoord
- `RABBITMQ_HOST`: Hostname van RabbitMQ
- `KEYCLOAK_AUTH_SERVER_URL`: URL naar Keycloak (bijv. `http://auth.k8s.cluster/`)

### Backend Game Service
- `DATASOURCE_URL`: JDBC url
- `RABBIT_HOST`: Hostname van RabbitMQ

## Ingress Rules
Het verkeer moet als volgt binnenkomen via de Ingress Controller:
- `domein.com/` -> Frontend Platform
- `domein.com/api/platform` -> Backend Platform Service
- `domein.com/api/games` -> Backend Game Service


# AI Integration Guide

## Overzicht
AI-spelers (Bots) communiceren met het platform via REST API's voor het ophalen van de spelstatus en via RabbitMQ (optioneel) of REST voor het doen van zetten.

## Authenticatie
Elke AI-speler moet een geldig JWT-token hebben van Keycloak.
1. Vraag credentials (client_id, client_secret) aan bij het team.
2. Haal token op via: `POST /realms/boardgame-platform/protocol/openid-connect/token`

## Spel Integratie (TicTacToe / Blokus)

### 1. Game State Ophalen
**GET** `/api/games/{gameType}/{gameId}`
**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "id": "uuid",
  "board": [[...], [...]],
  "currentTurn": "PLAYER_X",
  "status": "ONGOING"
}
```

### 2. Een zet doen
**POST** `/api/games/{gameType}/{gameId}/move`
**Body:**
```json
{
  "row": 1,
  "col": 1,
  "playerId": "ai-uuid"
}
```

### 3. Events (RabbitMQ)
Luister naar de exchange `dampf-exchange` voor real-time updates.
- **Topic:** `game.updated.{gameId}`
- **Payload:** Bevat de nieuwe Game State na elke zet.


# External Game Developer Guide

Welkom! Wil je je eigen spel toevoegen aan ons platform? Volg deze stappen.

## Architectuur
Je spel bestaat uit twee delen:
1. **Frontend:** Een webinterface (React, Vue, etc.) die in een iframe of apart tabblad draait.
2. **Backend:** Een service die de spellogica beheert.

## Stap 1: Registratie
Je spel moet zich bij het opstarten aanmelden bij het platform via een API call of configuratie (zie Anti-Corruption Layer in architectuur).

## Stap 2: API Contract
Jouw backend moet de volgende endpoints aanbieden zodat het platform ermee kan praten:

- `POST /api/match/create`: Start een nieuwe match
- `GET /api/match/{id}`: Geef huidige status

## Stap 3: Events
Jouw backend moet events sturen naar RabbitMQ wanneer een spel eindigt, zodat wij statistieken kunnen bijwerken.

**Exchange:** `dampf-exchange`
**Routing Key:** `game.result`
**Format:**
```json
{
  "gameId": "uuid",
  "winnerId": "uuid",
  "scores": { "uuid-p1": 10, "uuid-p2": 5 }
}
```