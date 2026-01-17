# Integratieproject J3
Kick-off
1. Inleiding
2. Project
4. Afspraken
3. Team indeling
1. Inleiding
Bij een IT bedrijf
Stage
In de hogeschool
Integratieprojecten
Waarom Integratieproject J3?
Volstond Integratieproject J2 niet?
IP J2 = Create-Read-Update-Delete in 1 deploy unit
IP J3 gaat verder
● Business logic - Complexe architectuur
● Frontend en backend geschieden
```
● AI service(s)
```
● Data analytics service
```
● Devops (CI/CD pipelines, K8s,...)
```
● Automated QA
● …
Volstond Integratieproject J2 niet?Team setup
Team
ISB
IAI
ISM
IAO
IAO
IP J2
Team
ISM
IAO
IAO
IAO
IAO
Team
ISB
ISB
ISB
ISB
Team
IAI
IAI
IAI
IAI
IP J3
2. Project
Project
```
https://docs.google.com/document/d/1qHuKcjlTNP4eakuRrsOnWSwBNREdd2ef79HySwW5Qik/edit?usp=sharing
```
Project
Het project omvat de ontwikkeling van een digitaal platform waarop
spelers diverse webgebaseerde bordspellen kunnen spelen. Het
platform is ontworpen met een sterke focus op
gebruiksvriendelijkheid en stimuleert sociale interactie tussen
spelers.
Een belangrijk uitgangspunt is de open architectuur, die het
eenvoudig maakt om nieuwe spellen efficiënt te integreren.
Daarnaast worden AI-gedreven functies geïntegreerd die NPCs
toevoegen en chatbot conversaties mogelijk maken.
Het platform wordt in de cloud gehost, met nadruk op
schaalbaarheid, beveiliging en betrouwbaarheid.
Voor het management biedt het systeem analysetools waarmee
gebruikspatronen inzichtelijk worden gemaakt.
Team setup
```
IAO(ISM)-team
```
IAO-studenten bouwen de gebruikersinterface, platform logica
```
(shop, lobby, achievements,...) en 2 voorbeeldspellen. Bovendien
```
integreren ze één extern spel dat niet door henzelf ontwikkeld
```
werd (dit wordt aangeleverd).
```
Sommige IAO-teams krijgen ondersteuning van een ISM-student,
die meewerkt aan het platform en zich bijkomend richt op
analytische inzichten via een ELK-stack.
```
Elk IAO(ISM)-team maakt via API’s gebruikt van de services van
```
een IAI-team.
```
Elk IAO(ISM)-team beheert zijn eigen CI/CD-pipeline(s) in GitLab.
```
```
Elk IAO(ISM)-team maakt zelf werkende Docker images die getest
```
zijn in een docker compose omgeving.
Team setup
IAI-team
AI-studenten ontwikkelen AI-functionaliteit voor het platform. Ze
werken onder andere aan AI-spelers die kunnen deelnemen aan de
spelletjes, een chatbot en een aanbevelingssysteem.
De services van het AI-team worden via API’s door meerdere
```
AO(SM)-teams gebruikt (geïndividualiseerd per AO(SM)-team waar
```
```
nodig).
```
```
Elk AI-team beheert zijn eigen CI/CD-pipeline(s) in GitLab.
```
Elk AI-team maakt zelf werkende Docker images die getest zijn in
een docker compose omgeving.
Team setup
ISB-team
ISB-studenten zorgen voor een stabiele, veilige en schaalbare
infrastructuur.
Ze voorzien een Kubernetes-cluster waarop containers die door
```
de IAO(ISM) en IAI teams worden aangemaakt kunnen draaien.
```
```
Elke ISB-team ondersteunt meerdere IAO(ISM) en IAI teams.
```
3. Team indeling
Teamsheet - IAO-ISM-IAI
Stel hier je team samen
Kies een naam voor je team
Indeling ISB teams gebeurt vrijdag
4. Afspraken
Collective ownership
● Je bent vertrouwd met de verschillende
aspecten van het project dat je team realiseert
● Je werkt mee aan diverse onderdelen
```
(bv. IAO: niet enkel back-end)
```
● Je doet aan kennisoverdracht in het team aan de
hand van de daily stand-up, merge request reviews,
pair-programming, …
Coaches
Wouter Deketelaere, Thomas Maxwell, Toni Mini, Jan Van
Overveldt, Jan Van Sas, Raoul Van den Berge, Bart Vochten
Check het permanentie rooster voor beschikbaarheid docenten
```
Gebruik voor vragen het juiste Teams kanaal (+ docent(en) taggen!)
```
Coaches vervullen een dubbele rol
- Elke coach heeft zijn technische expertise
Vragen, feedback, tech reviews
Wouter en Jan VS: IAI
```
Thomas en Raoul: IAO (backend)
```
```
Bart: IAO (frontend)
```
Jan VO: ISM
```
Toni: ISB
```
- Elk IAO(ISM) en IAI team krijgt een process coach
```
Opvolging project (status, teamwerking,...).
```
Toni Mini volgt de ISB-teams op
Sprints
sprint 1 sprint 2
1 2 3 4 5 6 Kerst Ex
sprint 3
```
Stel de deadlines (milestones in gitlab) aanvankelijk
```
in op
✓ Vrijdag week 3
✓ Vrijdag week 5
✓ Zondag voor eerste examenweek
In samenspraak met procescoach worden effectieve
deadlines i.f.v. sprint reviews vastgelegd
• Daily standup
```
• Agile board (open, refined, doing, review, closed) op
```
groepsniveau. Dit wordt permanent up-to-date
gehouden door elk teamlid
• Elk issue wordt op een aparte branch ontwikkeld
```
• Merge in de master via merge request (+ checklist)
```
```
door een ander teamlid dan de implementator(s)
```
• Elke merge request heeft een reviewer nodig
Daily work
⇒ zie infosessie Project management
ISB teams werken Kanban en volgend een wat ‘lichtere’ aanpak
Reviews
```
Sprint review/retrospective (week 3, 5, Ex)
```
- Buddy check
- Planning (agile board, burndown,…)
- Demo functionaliteit/deployment
- Retro: wat liep er goed/minder goed/verbeteracties
```
Technical review (week 4, Ex)
```
- Code/scripts/… review door technical coaches
```
Cross-team review (week 3, week 5)
```
- Feedback formulier over samenwerking IAO(SM) ↔ ISB ↔ ISM teams
```
Feedback/evaluatie via Rubrics (zie Canvas)
```
Werkafspraken
• Tijdens de geroosterde momenten ben je ALTIJD AANWEZIG
- Dinsdag online 08:15-12:15 - ISM-IAI-IAO-ISB
- Donderdag campus BC 13:45-17:45 - ISM-IAI-IAO
- Vrijdag campus PH 8:15-12:15 - ISM-IAI-IAO-ISB
```
• Tijdens online momenten werk je samen via MS Teams (er komt een kanaal per
```
```
team) of via een andere tool (discord,...)
```
```
(in geval je een andere tool gebruikt, ben je ook permanent bereikbaar als team
```
```
in het MS Teams kanaal)
```
```
• Bij gewettigde afwezigheid (ook online) verwittig je team en coach!
```
```
• Ook buiten deze uren dient er geregeld (samen) gewerkt te worden!
```
IAO-ISM-IAI
7 sp = ±25 * 7 ≈ 175 uren per student
ISB
3,5 sp = ±25 * 3,5 ≈ 87 uren per student
Evaluatie
De evaluatie gebeurt permanent door de coaches met focus op de 3 sprint
reviews en de 2 technical reviews. Zie Rubrics op Canvas voor de evaluatie
criteria.
```
De evaluatie wordt gecorrigeerd met peer assessments (buddycheck)
```
Een 2e zittijd is mogelijk en verloopt individueel indien een teamlid:
- onvoldoende bijdragen levert en/of
- onvoldoende kwaliteitsvolle bijdragen levert en/of
- onvoldoende inzicht heeft in de bijdragen van andere teamleden
```
(architectuur, setup, techs,...)
```
Een 2e zittijd is niet mogelijk indien teamgerichte leerdoelen niet werden
```
behaald: samenwerken, inzet, aanwezigheid, respect, deadlines
```
```
respecteren, git(lab) sanity,...
```
What’s next?
Infosessies
2 gastlezingen
The Beehive - Testing
Involved - Gebruik van Gen AI in de sector
Sprint planning
Sprint 1 = MVP
```
AO(SM)- team
```
- Frontend-Backend basis features (spel starten, …)
- Tic-tac-toe spel
- Basis communicatie met AI service(s) + API afspraken helder
- Basis communicatie met Analytics Service (SM only) + API afspraken helder
- Dockerisatie + afspraken helder
- …
AI-team
- Game state bepalen en interne AI-architectuur
- Afspraken over API’s en dataformaten (input/output, authenticatie)
- Prototype AI-speler Tic-Tac-Toe + Monitoring AI-prestaties
- Opzetten van de AI-service (basisstructuur, eerste endpoints,...)
- Dockerisatie + afspraken helder
- …
SB
- Werken Kanban, af te stemmen met Toni Mini
Sprint 2 en 3
Verdere afwerking
Jullie bepalen je sprintplanning zelf, in
samenspraak met de coaches
Eerstvolgende stappen
```
IAO(SM)-teams
```
- Wireframes gaming platform (en Analytics Dashboards voor teams met ISM student)
- Story Mapping → User stories → planning poker → story points → sprint planning
- Architectuur uittekenen, domain modelling
- Details techstack bepalen
- Setup (git, IDE, ...)
- Coding
- SB en AI-team contacteren en afspraken maken
IAI-teams
- User stories → planning poker → story points → sprint planning
- Architectuur uittekenen
- Details techstack bepalen
- Setup (git, IDE, ...)
- Coding
- AO-teams contacteren en afspraken maken
- SB-team contacteren en afspraken maken
ISB-teams
- Requirements checken
- Terraform/Google cloud/K8s bestuderen
- Architectuur uittekenen
- Setup (git, ...)
- Scripting
- AO en AI-teams contacteren en afspraken maken
- Al een eerste test-setup (proof of concept) voorzien voor een fictief team (gebruik test images)
Allen
Project document volledig doornemen
```
(ook de secties van de andere richtingen!)
```
…
Gen AI tools
Ons advies
- Gebruik ze spaarzaam
- Gebruik ze om bij te leren en om je werk te reviewen
- Schrijf zelf code
- Begrijp ELKE REGEL code/script die je commit
```
“Own your code (as a team)!”
```
32