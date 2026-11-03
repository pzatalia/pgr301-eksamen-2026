# PGR301 Eksamen 2026 Besvarelse — wishif.ai

Alle AWS-ressurser ligger i region *eu-west-1*.

## OPPGAVE 1A - Container og CI

Dockerfilen har to steg. Først bygges appen med Maven og JDK 21. Deretter lages et lite image bare med Java-runtime og JAR-filen, så byggverktøyene ikke blir med

*Kjøre containeren*

Bytt ut med egne AWS-nøkler:

    docker run -p 9999:8080 \
    -e AWS_ACCESS_KEY_ID=<din secret> \
    -e AWS_SECRET_ACCESS_KEY=<din secret> \
    -e AWS_REGION=eu-west-1 \
    <dockerhub-brukernavn>/wishifai:latest

Test:

    curl -F "image=@samples/sample_image.png" http://localhost:9999/api/analyze




## OPPGAVE 2 - ECS Express med Terraform 

## OPPGAVE 3 - Observability

## OPPGAVE 4 - Drøfteoppgave 



