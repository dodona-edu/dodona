Database Layout Draft (gebaseerd op spoj)
=========================================

Tabellen
---------
   - User
   - Exercise
   - Submission (Submission)
   - Course
   - Course_User (verbind studenten met contest/cursus)
   - Course_Exercise (verplicte oefeningen voor die cursus)
   - Series
   - Punten (resultaten voor evaluatie)
   - Plagiaat
   - Rankings (speciaal voor Niels)

Kolommen per tabel
------------------
#####User:
   - id
   - studentennummer
   - familienaam
   - voornaam
   - emailadres
   - username
   - type (student/teacher/zeus)

#####Exercise:
   - id
   - name
   - visibility (public/evaluation/hidden/private)

#####Submission:
   - id
   - exercise_id
   - user_id
   - evaluation (true/false)
   - result
   - timestamp

#####Deadline
   - id
   - series_id
   - end
   - harddeadline (true/false)
   
#####Course:
   - id
   - name
   - description

#####Series:
   - id
   - name
   - course_id
   - visibility (public/evaluation/private)
   - code
