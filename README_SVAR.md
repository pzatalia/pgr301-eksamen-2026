# PGR301 Eksamen 2026 Besvarelse — wishif.ai

Alle AWS-ressurser ligger i region *eu-west-1*.


## OPPGAVE 1A - Container og CI

Dockerfile: [Dockerfile](Dockerfile)

Dockerfilen har to steg. Først bygges appen med Maven og JDK 21. Deretter lages et lite image bare med Java-runtime og JAR-filen, så byggverktøyene ikke blir med

*Kjøre containeren*

Bytt ut med egne AWS-nøkler:

    docker run -p 9999:8080 \
    -e AWS_ACCESS_KEY_ID=<din secret> \
    -e AWS_SECRET_ACCESS_KEY=<din secret> \
    -e AWS_REGION=eu-west-1 \
    pzataliaa/wishifai:latest

Test:

    curl -F "image=@samples/sample_image.png" http://localhost:9999/api/analyze


## OPPGAVE 1B - CI-pipeline

Workflow-fil: [.github/workflows/docker.yml](.github/workflows/docker.yml)

Grønn kjøring: https://github.com/pzatalia/pgr301-eksamen-2026/actions/runs/41654004404 

Workflowen kjører ved push til "main". Den bygger imaget og pusher det til ECR (wishifai-0501) og Docker Hub (pzataliaa/wishifai). Nøklene ligger som Github Secrets.

Tagging-strategi:

- Commit-SHA: gir sporbarhet. Taggen kobler imaget til en bestemt commit, så vi vet hvilken kode som kjører, og vi kan rulle tilbake til en tidligere versjon. Jeg valgte å bruke SHA fordi den lages automatisk ved hver commit, mens versjonsnummer må settes manuelt hver gang, og dette er lett å glemme. 
- latest: flyttes til nyeste bygg hver gang. Den er fin å ha for lokal testing, men sier ikke hvilken versjon som kjører, derfor har jeg implementert en Commit-SHA i tillegg.


## OPPGAVE 2 - ECS Express med Terraform 

## OPPGAVE 3 - Observability

## OPPGAVE 4 - Drøfteoppgave 



