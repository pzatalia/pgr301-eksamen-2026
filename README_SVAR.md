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
    -e S3_BUCKET=wishifai-images-19 \
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

- IAM-roller: Execution role og infrastructure role er eksisterende roller i kontoen. Jeg laget en egen task-rolle *wishifai-task-role-19*, som gir appen lov til 4 ting. 1. lese og skrive i egen bucket. 2. Bruke rekognition til å finne objekter i bildet. 3. Kalle Claude modellen i Bedrock for å lage gavelisten. 4. Sende metrikker til CloudWatch (lagt til i oppgave 3A).

- S3_bucket: I ecs.tf settes S3_BUCKET til navnet på bucketen Terraform lager. Da kan ikke appen og bucketen få forskjellige navn ved en feil, og man trenger ikke å oppdatere verdien manuelt. 

## OPPGAVE 2B - Remote state

Backend: [infra/backend.tf](infra/backend.tf)

Nøkkel: wishifai/19/terraform.tfstate

State lages i den delete bucketen *pgr301-terraform-state*. Kandidatnummeret i nøkkelen gjør at min state ikke kolliderer med andre studeneter i samme bucket. 

## OPPGAVE 2C - GitHub Actions-job for Terraform

Workflow-fil: [.github/workflows/docker.yml](.github/workflows/docker.yml)

Grønn kjøring: https://github.com/pzatalia/pgr301-eksamen-2026/actions/runs/41859998869

Hvorfor Terraform kjører etter container-build:

- Terraform sier til ECS hvilket image som skal kjøres, derfor må imaget finnes i ECR først.
- Hvis terraform kjører før eller smatidig som vi bygger så kan imaget mangle og da vil deployen feile.
- Commit-SHA lages i build-steget (oppgave 1B), terraform får den inn som variabel image_tag (oppgave 2A), og bruker denne til å velge hvilket image ECS skal kjøre. Derfor må byggingen være ferdig først. 


## OPPGAVE 3A - Metrikker i applikasjonen

Metrikker:

- Rekognition og Bedrock (Timer): *wishifai.rekognition.latency* og *wishifai.bedrock.latency* måler hvor lang tid hvert kall tar. Gjør det mulig for oss å se hvilket steg som tar mest tid slik at vi slipper å gjette oss fram til det. 

- Antall gaveforslag per bilde (DistributionSummary) som buisness-metrikk. Metrikken sier noe om hvilken verdi brukeren får og ikke bare at tjenesten kjører. Denne metrikken viser hvor mange bilder som analyseres, hvor mange forslag som lages totalt og snittet per bilde. Prompten ber om inntil 5 forlag, så hvis snittet faller, får brukeren dårligere svar selv om appen virker. 

- Ugyldige AI svar (counter): *wishifai.bedrock.invalid.responses*. Noen ganger svarer AI i feil format, og da får brukeren ingen gaveforslag, uansett svarer appen HTTP 200 OK, så ingen metrikker merker feilen. Telleren fanger gangene appen sier alt gikk bra, men brukeren ikke fikk gaveforslag. Normalt skal verdien være 0. Øker dette tallet kan AI-modellen eller prompten ha endret seg, og da bør vi finne ut av hvorfor den svarer i feil format.

Oppsett:

- Namespace: Brukte *wishifai-19* siden namespace var tomt, ellers hadde cloudwatch avvist metrikkene mine. Navnet gjør det også enklere for meg å finne mine metrikker siden kontoen er delt. 

- IAM: task-rolen fikk tillatelse til *cloudwatch:PutMetricData*, som gir lov å sende metrikker. Uten denne ville appen fått *access denied*, og ingen metrikker ville kommet fram. 

- Timer.builder i stedet for @Timed: I labben ble @Timed brukt, men @Timed krever avhengigenten AOP, som ikke finnes i wishifai-prosjektet. Derfor lagde jeg klokken selv med *Timer.builder()* og *Timer.record()*. Klokken virker uten AOP fordi jeg skriver direkte i koden hvor målingen starter og stopper (bare rekognition og bedrock blir målt, ikke hele koden).


## OPPGAVE 3B - Dashboard og alarm

Terraform-kode: [infra/dashboard.tf](infra/dashboard.tf) & [infra/alarm_module/](infra/alarm_module/)

Dashboard: *wishifai-19*

Screenshot av dashboard: [Dashboard](media/dashboard.png)

Metrikker på dashboard:

- Buisness: bilder analysert : viser hvor mange bilder brukeren sender inn 
- Buisness: snitt gaveforslag per bilde : viser kvaliteten brukerne får. Cloudwatch har ikke snittet ferdig utregnet, så det regnes ut som sum/antall. Fra screenshottet kan vi se at snittet ligger stabilt på 5, som er maks antall prompten ber om. 

- Infrastruktur: CPU og minne fra ECS : Viser om container har nok ressurser. CPU ligger mesteparten av tiden under 1 til 2 % og minne rundt 11 %. Det betyr at verdiene jeg satte i oppgave 2A, 1 vCPU og 2 GB, er mer enn nok, noe som betyren at det ikke er serveren som er treig. 

- Applikasjon: svartid for POST /api/analyze fra Actuator : Viser hvor lenge brukeren venter. Dashboardet viser rundt 17 sekunder. 

- Jeg regnet selv ut hvor mye av ventetiden Bedrock står for. Fra metrikken wishifai.bedrock.latency hentet jeg totalt tid og antall kall som ble 46 449 ms ÷ 3 kall = ca. 15,5 sekunder per kall. Det betyr at bedrock tar mesteparten av tiden, ca. 90% (15,5 / 17). Som nevnt over så er CPU og minne nesten ubrukt, så tregheten kan ikke komme fra serveren. For at tjenesten skal være raskere må vi se på bedrock f.eks. en kortere prompt.

Alarm: *wishifai-19-bedrock-latency*

- Varsler: når bedrock kallet i snitt tar mer enn 20 sekunder over 5 minutter utløser alarmen.

- Grunn: Bedrock tar mesteparten av ventetiden. Hvis tjenesten blir enda tregere, er det stor sjanse for at bedrock er årsaken. Et vanlig kall tar ca. 15,5 sekunder, derfor satte jeg grensen til 20 sekunder. Da går ikke alarmen av ved små svingninger, kun når bedrock er mye tregere enn vanlig.

- Ingen trafikk: når tjenesten ikke brukes, finnes det ingen tid å måle derfor regnes det som ok *treat_missing_data = "notBreaching"*, dette gjør at alarmen ikke går uten grunn. 

- Varslingsform: Alarmen sendr til et SNS-topic som sender e-post, som i labben. Jeg testet alarmen med *aws cloudwatch set-alarm-state*, og jeg fikk en epost. [Alarm](media/test_alarm.png)


## OPPGAVE 4 - Drøfteoppgave 

Når en vanlig app har en feil, krasjer den eller gir en feilmelding. En AI-app som Wishifai mangler sunn fornuft. Den kan foreslå en upassende gave, men appen vil fortsatt svare HTTP 200 som om alt gikk bra. Testene blir godkjent, men innholdet blir aldri testet. Dette betyr at testing, leveranse og overvåkning i DevOps må tilpasses fordi de er laget for å finne tekniske feil og ikke feil i innholdet. 

I Wishifai kan samme bilde gi forskjellige gaveforslag hver gang. En vanlig test som forventer ett bestemt svar hadde derfor feilet selv om svarene var gode. I stedet kan man bruke et eval-set, der man sender inn faste testbilder og sjekker om svaret er godt nok, f.eks. at det har 5 forslag og ingen farlige gaver for barn. Svaret trenger ikke å være ordrett med fasiten, det må bare være riktig. Dette kunne vært en gate i pipelinen min mellom bygg og deploy. Med LLM-as-judge kan en annen AI vurdere svarene automatisk, men da igjen kan den AI-en ta feil, så jeg vil si at automatiske tester alene ikke er nok. Vi mennesker må fortsatt ta stikkprøver. 

I en AI-app er det ikke bare koden som bestemner svarene, men også prompten og modellen. I pipelinen min tagges imaget med en commit-SHA. Prompten ligger i koden og følger taggen, men modellen settes med en miljøvariabel og kan byttes uten ny commit. Da kan appen gi helt andre svar med samme tag. Derfor bør modellvalget også ligge i Git, slik at det kan spores og rulles tilbake. Ved bytte av modell kan man bruke canary, der noen få brukere får den nye modellen først. Er den dårligere, rammes bare de. Dette er nok unødvendig for Wishifai, men nødvendig i en bank.

Overvåkningen min fra oppgave 3 måler tid og format. Hvis Wishifai foreslår en kniv til et barn, vil ingen av metrikkene mine reagere. Derfor trenger vi andre signaler enn latency og feilrater. Business-metrikken min viser f.eks. endringer i svarene over tid: hvis snittet av gaveforslag faller fra 5 til 2 etter et modellbytte, har kvaliteten antagelig blitt dårligere. Slike signaler kan likevel bare vise at noe har endret seg, ikke om svarene er trygge. Det er noe vi mennesker må vurdere. 

Hvor mye kontroll man trenger, avhenger av hvor alvorlig det er om AI-en tar feil. En dårlig gaveliste er irriterende, men ikke farlig. Noen feil kan oppdages i produksjon, så lenge eval-set og stikkprøver fanger det mest alvorlige. I en bank kan AI-en anbefale et risikabelt fond til en pensjonist som ikke har råd til å tape penger. Der bør eval-settet være en gate som stopper deploy, og et menneske bør godkjenne hver gang prompten eller modellen endres. Kunderådgiveren bør også sjekke rådet før kunden får det. AI gjør at DevOps ikke bare må spørre om appen virker, men også om svaret er riktig og trygt. For en gaveliste holder automatikk, men når mye står på spill, som i en bank eller i helsevesenet, må mennesker ha kontrollen.



