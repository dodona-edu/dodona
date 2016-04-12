Database Layout Draft (gebaseerd op spoj)
=========================================

Tabellen
---------
   - Cursus
   - CursusContest (voor het geval er meerdere contests bij dezelfde cursus horen COMPBIO <-> PYTHIA15)
   - Studenten
   - StudentContest (verbind studenten met contest/cursus)
   - Richtingen (verbind student met zijn richting - kan veranderen!)
   - spojAccount
   - Oefening
   - Cursus_Oefening (verplicte oefeningen voor die cursus)
   - Indiening (Submission)
   - Evaluatie (bevat gegevens over een evaluatiemoment)
   - EvaluatieContest (verbinding evaluatie met spoj contest en indianio project)
   - EvaluatieOefening (verbind de evaluatie met zijn oefeningen)
   - EvaluatieStudenten (verbind studenten met de evaluatie waaraan ze hebben deelgenomen)
   - Punten (resultaten voor evaluatie)
   - Plagiaat
   - Rankings (speciaal voor Niels)

Kolommen per tabel
------------------

#####Cursus:
   - cursus_id
   - beschrijving
   - start
   - stop

#####CursusContest:
   - cursus_id
   - contestCode
   - minerva_code

#####Studenten:
   - studentennummer
   - familienaam
   - voornaam
   - emailadres
   - nickname

#####StudentContest:
   - contest_id
   - studentennummer

#####Richtingen:
   - studentennummer
   - opleiding
   - datum

#####SpojAccount:
   - studentennummer
   - spojAccount
   - datum

#####Oefening:
   - progcode
   - reeks
   - directorynaam
   - titel_nl
   - titel_en
   - moeilijkheid

#####Cursus_Oefening:
   - cursus_id
   - progcode
   - deadline

#####Indiening:
   - submission_id
   - studentennummer
   - progcode
   - resultaat
   - tijdstip

#####Evaluatie:
   - evaluatie_id
   - beschrijving
   - cursus_id
   - tijdstip
   - type (1/2, EX)
   - groep

#####EvaluatieContest:
   - evaluatie_id
   - contestCode
   - indianio_code

#####Evaluatie_Oefening:
   - evaluatie_id
   - progcode

#####Evaluatie_Studenten:
   - evaluatie_id
   - studentennummer

#####Plagiaat:
   - progcode
   - cluster
   - submission_id

#####Rankings:
   - cursus_id
   - studentennummer
   - type
   - value

#####Punten:
   - evaluatie_id
   - studentennummer
   - vraag
   - punten
