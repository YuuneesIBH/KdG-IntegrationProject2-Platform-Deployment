# Groepscontract

**Integratieproject J3 -- 21/11/2025**

------------------------------------------------------------------------

Dit is een versie van het groepscontract geconvert naar Markdown formaat. Het volledig en beter opgemaakte groepscontract staat in pdf ook in deze repository, en is op die manier ook doorgestuurd naar alle developergroepen.

## Rollen

### **DevOps Team (OP)**

Younes, Rayan, Mateen, Matthias

**Verantwoordelijk voor:** - Kubernetes deployment
- Docker & containerregistries
- OpenTofu (IaC)
- CD pipelines
- Monitoring & logging
- Deployment documentatie
- Operationele stabiliteit

### **Dev Teams**

#### **Frontend Team**

-   React-frontend
-   API-calls

#### **Backend Services Team**

-   Domain logic
-   API endpoints
-   Database interacties

#### **AI Services Team**

-   Model serving
-   ML logic
-   Event flows

------------------------------------------------------------------------

## Deployment Agreement

### Wat DevOps uitvoert

-   Deployments naar test en productie
-   Opzetten & onderhouden van K8s-cluster
-   Schrijven & beheren van deployment YAML's
-   OpenTofu provisioning (cloud resources)
-   Monitoring dashboards & loggingconfiguratie
-   Technische ondersteuning bij integratie
-   Communicatie van services, poorten, protocollen en variabelen

### Wat Dev moet aanleveren

Voor elke service levert Dev correct en volledig: - Productieklare
Dockerfile
- Health endpoints
- Database requirements (migrations, schema's)
- API-documentatie / expected responses

### Deadline-afspraken

-   Er wordt enkel gewerkt met duidelijke, voorspelbare deadlines\
-   Geen last-minute werk
-   Geen nachtwerk
-   Geen "net op tijd"

### Documentatieplicht (GitLab + DevOps Discord)

Elke beslissing → documenteren in GitLab **en** melden in
DevOps-Discord
Elke wijziging → loggen in GitLab **en** aankondigen in DevOps-Discord
Elke blocker → GitLab-issue + melding in DevOps-Discord

**Geen enkele deploy wordt uitgevoerd zonder GitLab-issue +
Discord-melding.**

------------------------------------------------------------------------

## Aanleveringen en Verwachtingen

### Verplicht aan te leveren door Dev

-   **Test container image**
-   **Final container image**
-   **Volledig refined user stories**
-   **Service-informatie** (environment variables, protocollen)

### Wat DevOps levert

-   Kubernetes-YAML's en deploymentconfiguratie
-   Integratiedocumentatie
-   Validatie van images, health endpoints, logging en communicatie
-   Stabiele testomgeving
-   Poortconfiguraties & protocollen

------------------------------------------------------------------------

## Review & Feedback

Geen enkel onderdeel gaat live zonder: - Groene pipeline
- Finale bevestiging in DevOps-Discord

------------------------------------------------------------------------

## Conflicten & Escalaties

### **Stap 1: Intern oplossen**

Discordbespreking.

### **Stap 2: Dev--Ops overleg**

Behandeling in overleg + bevestiging in Discord.

### **Stap 3: Escalatie naar docent**

Enkel wanneer: - Bewijs van eerdere Discord-besprekingen\
- Procedure gevolgd

------------------------------------------------------------------------

## Handtekeningen

**DevOps Team 4:**
- Younes El Azzouzi
- Mateen Murtaza
- Matthias Adriaenssen
- Rayan Boufker

Gelezen en goedgekeurd op **21/11/2025**.
