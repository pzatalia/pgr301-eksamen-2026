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


## OPPGAVE 2A - Infrastruktur

Terraform kode: [infra/](infra/)

Offentlig URL: https://wi-64f67926b4134b2da634890cd32df18a.ecs.eu-west-1.on.aws

Valg:

- CPU og minne: Tjenesten har 1 vCPU og 2 GB. Dette er samme standarden som i ecs express, men jeg har satt det i koden slik at man ser hva tjenesten får, og at de. ikke endrer seg jvis AWS endrer standarden.

- Helsesjekk: For at ECS skal vite om appen kjører, peker helsesjekken på /actuator/health.

- Variabler: region, kandidatnummer og image_tag er variabler, så de kan endres uten å endre koden. image_tag er *latest* som default, men pipelinen i oppgave 2C sender inn commit-SHA.

- Outputs: viser URL-en, bucketnavn, imaget som kjører og task-rollen. Gjør at det er lett å se hva som ble deploeyt.

- IAM-roller: Execution role og infrastructure role er eksisterende roller i kontoen. Jeg laget en egen task-rolle *wishifai-task-role-19*, som gir appen lov til 3 ting. 1. lese og skrive i egen bucket. 2. Bruke rekognition til å finne objekter i bildet. 3. Kalle Claude modellen i Bedrock for å lage gavelisten. 

- S3_bucket: I ecs.tf settes S3_BUCKET til navnet på bucketen Terraform lager. Da kan ikke appen og bucketen få forskjellige navn ved en feil, og man trenger ikke å oppdatere verdien manuelt. 

## OPPGAVE 2B - Remote state

Backend: [infra/backend.tf](infra/backend.tf)

Nøkkel: wishifai/19/terraform.tfstate

State lages i den delete bucketen *pgr301-terraform-state*. Kandidatnummeret i nøkkelen gjør at min state ikke kolliderer med andre studeneter i samme bucket. 







## OPPGAVE 3 - Observability

## OPPGAVE 4 - Drøfteoppgave 



