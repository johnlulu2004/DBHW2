-- 1. List the name and age of the oldest student in every major. If there is a tie, list all
-- students tying
SELECT s.FName, s.LName, s.age
FROM Student s
WHERE s.age = (
    SELECT MAX(s2.age)
    FROM Student s2
    WHERE s2.major = s.major
);


-- 2. List the name, age and gender of all students who do not have a roommate.
SELECT s.FName, s.LName, s.age, s.sex
FROM Student s
WHERE NOT EXISTS (
    SELECT * FROM Lives_in a, Lives_in b
    WHERE a.StuID = s.StuID
        AND b.dormid = a.dormid
        AND b.room_number = a.room_number
        AND b.stuid != a.stuid);


-- 4. List the name and major (name not number) of all students who are enrolled in more
-- than 19 credits
SELECT s.Fname, s.Lname, d.DName
FROM Student s, Department d, Enrolled_in e, Course c
WHERE s.Major = d.DNO
  AND s.StuID = e.StuID
  AND e.CID = c.CID
GROUP BY s.StuID, s.Fname, s.Lname, d.DName
HAVING SUM(c.Credits) > 19;


-- 5. List the name of all faculty members who advise a student who is enrolled in a course
-- with a student who is a roomate of a student who majors or minors in the same
-- department that the faculty member is a member of.
SELECT f.Fname, f.LName
FROM Faculty f, Student a, Enrolled_in e1, Enrolled_in e2,
     Lives_in l1, Lives_in l2, Student c, Member_of m
WHERE a.Advisor = f.FacID
    AND e1.StuID = a.StuID
    AND e1.CID = e2.CID
    AND e1.StuID != e2.StuID
    AND l1.StuID = e2.StuID
    AND l2.dormid = l1.dormid
    AND l2.room_number = l1.room_number
    AND l2.stuid != l1.stuid
    AND c.stuid = l2.stuid
    AND m.facid = f.facid
    AND (c.major = m.dno
        OR EXISTS (SELECT *
                   FROM Minor_in mi
                   WHERE mi.stuid = c.stuid
                   AND mi.dno = m.dno));


-- 6. List the names of the students who like every other student who is in their major.
SELECT s.FName, s.LName
FROM Student s
WHERE NOT EXISTS (
  SELECT *
  FROM Student s2
  WHERE s2.major = s.major
    AND s2.stuid != s.stuid
    AND NOT EXISTS (
      SELECT *
      FROM Likes l
      WHERE l.wholikes = s.stuid
      AND l.whoisliked = s2.stuid));

-- we select the name of studnet when there doesn't exist another student in their major who they don't like?


-- 7. For each course with a total enrollment greater than 0, list the total number of grades
-- lower than B in the class, the total enrollment in the class, and the percentage of
-- grades in the class that are B or below (also include the course name and instructors
-- name). To simplify this query, you can make use of the GRADECONVERSION
-- relation and the fact that a B has a gradepoint of 3.0. Also, B- is lower than B.
SELECT c.cname,
      f.fname,
      f.lname,
      COUNT(*) AS total_enrollment,
      SUM(CASE WHEN g.gradepoint < 3.0 THEN 1 ELSE 0 END) AS total_below_b,
      100.0 * SUM(CASE WHEN g.gradepoint < 3.0 THEN 1 ELSE 0 END) / COUNT(*) AS pct_below_b
FROM Course c
JOIN Faculty f              ON c.instructor = f.facid
JOIN Enrolled_in e          ON c.cid = e.cid
LEFT JOIN Gradeconversion g ON e.grade = g.lettergrade
GROUP BY c.cid, c.cname, f.facid, f.fname, f.lname
HAVING COUNT(e.stuid) > 0;


-- 8. List the names and student ID numbers of all pairs of student who love each other.
-- (Do not list a pair more than once; list the student with the lowest ID number in the
-- pair first)
SELECT s1.stuid,
    s1.fname,
    s1.lname,
    s2.stuid,
    s2.fname,
    s2.lname
FROM Loves l1, Loves l2, Student s1, Student s2
WHERE s1.stuid < s2.stuid
      AND l1.wholoves = s1.stuid
      AND l1.whoisloved = s2.stuid
      AND l2.wholoves = s2.stuid
      AND l2.whoisloved = s1.stuid;


-- 9. List the names of all students who love someone who does not love them back
SELECT s.fname, s.lname
FROM Student s
WHERE EXISTS (SELECT *
  FROM Student s2, Loves l
  WHERE l.wholoves = s.stuid
        AND l.whoisloved = s2.stuid
        AND NOT EXISTS (SELECT *
        FROM Loves l2
        WHERE l2.wholoves = s2.stuid
          AND l2.whoisloved = s.stuid)
);


-- 10. List the the names of all pairs of roommates where there exists a third party who
-- loves them both. (Do not list a pair more than once; list the student with the lowest
-- ID number in the pair first)
SELECT s1.fname,
        s1.lname,
        s2.fname,
        s2.lname
FROM Student s1, Student s2, Lives_in a, Lives_in b
WHERE s1.stuid < s2.stuid
AND a.stuid = s1.stuid
AND b.stuid = s2.stuid
AND s1.stuid != s2.stuid
AND a.dormid = b.dormid
AND a.room_number = b.room_number
AND EXISTS (SELECT *
  FROM Student s3, Loves l1, Loves l2
  WHERE l1.wholoves = s3.stuid
  AND l1.whoisloved = s1.stuid
  AND l2.wholoves = s3.stuid
  AND l2.whoisloved = s2.stuid
  AND s3.stuid != s1.stuid
  AND s3.stuid != s2.stuid);


-- 11. List the name and gender of the student who is liked by the most other students,
-- including the total number of students who like him or her.
SELECT s.fname, s.lname, s.sex,
COUNT(*) AS num_students_like
FROM Student s, Likes l
WHERE s.stuid = l.whoisliked
GROUP BY s.stuid, s.fname, s.lname, s.sex
HAVING COUNT(*) >= ALL (SELECT COUNT(*)
                        FROM Likes l2
                        WHERE l2.wholikes != l2.whoisliked
                        GROUP BY l2.whoisliked);


-- 12. List the most common first name in the database (including first names of both
-- faculty and students), along with the number of times this first name appears in the
-- database.
SELECT fname, COUNT(*)
FROM (
  SELECT fname FROM Student UNION ALL SELECT fname FROM Faculty
) AS combined_names
GROUP BY combined_names.fname
HAVING COUNT(*) >= ALL (
    SELECT COUNT(*)
    FROM (
      SELECT fname FROM Student UNION ALL SELECT fname FROM Faculty
    ) AS combined_names2
    GROUP BY fname
);


-- 13. List the name, age and major of all students along with the total number of credits
-- they are enrolled in.
SELECT s.fname, s.lname, s.age, d.DName AS major, SUM(c.Credits) AS num_credits
FROM Student s
JOIN Department d ON s.major = d.DNO
LEFT JOIN Enrolled_in e ON s.stuid = e.stuid
LEFT JOIN Course c ON c.CID = e.CID
GROUP BY s.stuid, s.fname, s.lname, s.age, d.DName;


-- 14. List the names and genders of all pairs of student who love each other and are also
-- roommates of each other. (Don't list a pair more than once; list the student with the
-- lowest ID number in the pair first)
SELECT s1.fname, s1.lname, s1.sex, s2.fname, s2.lname, s2.sex
FROM Student s1, Student s2, Lives_in l1, Lives_in l2, Loves lo1, Loves lo2
WHERE s1.stuid < s2.stuid
    AND lo1.wholoves = s1.stuid
    AND lo1.whoisloved = s2.stuid
    AND lo2.wholoves = s2.stuid
    AND lo2.whoisloved = s1.stuid
    AND l1.dormid = l2.dormid
    AND l1.room_number = l2.room_number
    AND l1.stuid = s1.stuid
    AND l2.stuid = s2.stuid;


-- 16.
-- Assuming a course workload is 10 hours a week, which student(s) have the highest
-- workload across both sports and academics, and how many hours a week do they
-- spend on both these activities combined?
SELECT s.fname, s.lname, (COALESCE(c.course_hours, 0) + COALESCE(sp.sports_hours, 0)) AS total_workload
FROM Student s
LEFT JOIN (
    SELECT stuid, COUNT(CID) * 10 AS course_hours
    FROM Enrolled_in
    GROUP BY stuid
) c ON s.stuid = c.stuid
LEFT JOIN (
    SELECT stuid, SUM(hoursperweek) AS sports_hours
    FROM SportsInfo
    GROUP BY stuid
) sp ON s.stuid = sp.stuid
GROUP BY s.stuid, s.fname, s.lname, c.course_hours, sp.sports_hours
HAVING (COALESCE(c.course_hours, 0) + COALESCE(sp.sports_hours, 0)) >= ALL (
    SELECT (COALESCE(c1.course_hours, 0) + COALESCE(sp1.sports_hours, 0))
    FROM Student s2
    LEFT JOIN (SELECT stuid, COUNT(CID) * 10 AS course_hours FROM Enrolled_in GROUP BY stuid) c1 ON s2.stuid = c1.stuid
    LEFT JOIN (SELECT stuid, SUM(hoursperweek) AS sports_hours FROM SportsInfo GROUP BY stuid) sp1 ON s2.stuid = sp1.stuid
);


-- 17. List the name of the student liked by the greatest number of students. If a tie, list
-- all tied winners.
SELECT s.fname, s.lname
FROM Student s, Likes l
WHERE s.stuid = l.whoisliked
  AND l.whoisliked != l.wholikes
GROUP BY s.stuid, s.fname, s.lname
HAVING COUNT(*) >= ALL (SELECT COUNT(*)
                        FROM Student s1, Likes l1
                        WHERE s1.stuid = l1.whoisliked
                        AND l1.whoisliked != l1.wholikes
                        GROUP BY s1.stuid, s1.fname, s1.lname);


-- 19. List the dorm names of those that have at least 1 video game player and none of
-- whom have played the game "Call of Destiny"
SELECT d.dorm_name
FROM Dorm d
WHERE EXISTS (SELECT *
              FROM Lives_in l, Plays_Games p
              WHERE l.dormid = d.dormid
                AND p.stuid = l.stuid)
AND NOT EXISTS (SELECT *
                FROM Lives_in l, Plays_Games p, Video_Games g
                WHERE l.dormid = d.dormid
                  AND p.stuid = l.stuid
                  AND g.gameid = p.gameid
                  AND g.gname = 'Call of Destiny');


-- 20. List the names of students who do not play video games and have received an 'B' or
-- lower in a class offered by the Computer Science Department.
SELECT s.fname, s.lname
FROM Student s, Enrolled_in e, Course c, Department d, Gradeconversion g
WHERE e.stuid = s.stuid
AND c.cid = e.cid
AND d.dno = c.dno
AND d.dname = 'Computer Science'
AND g.lettergrade = e.grade
AND g.gradepoint <= 3.0
AND NOT EXISTS (SELECT * FROM Plays_Games p
                WHERE p.stuid = s.stuid);


-- 21. List the names and department names of all students who are a CA for
--  a course not offered by their department.
SELECT DISTINCT s.fname, s.lname, d.dname
FROM Student s, Course_CA ca, Course c, Department d
WHERE s.stuid = ca.stuid
  AND c.cid = ca.cid
  AND d.dno = s.major
  AND c.dno != s.major;


-- 22. List the name, age and major of students who like every pop musical artist in the
-- database, but does not like any rap artist with a rating of greater than 3.
SELECT s.fname, s.lname, s.age, d.dname
FROM Student s, Department d
WHERE d.dno = s.major
  AND NOT EXISTS (SELECT *
                  FROM MusicalArtist m
                  WHERE m.musicalgenre = 'Pop'
                    AND NOT EXISTS (SELECT *
                                    FROM LikesArtist la
                                    WHERE la.stuid = s.stuid
                                      AND la.artid = m.artid))
  AND NOT EXISTS (SELECT *
                  FROM LikesArtist la2, MusicalArtist m2
                  WHERE la2.stuid = s.stuid
                    AND m2.artid = la2.artid
                    AND m2.musicalgenre = 'Rap'
                    AND la2.rating > 3);


-- 23. List the name, age and major of all students who like at least one pop musical artist
-- that no one else in the database likes.
SELECT s.fname, s.lname, s.age, d.dname
FROM Student s, Department d, LikesArtist la, MusicalArtist m
WHERE d.dno = s.major
  AND la.stuid = s.stuid
  AND m.artid = la.artid
  AND m.musicalgenre = 'Pop'
  AND NOT EXISTS (SELECT *
                  FROM LikesArtist la2
                  WHERE la2.artid = la.artid
                    AND la2.stuid != s.stuid);


-- 24. List the name of all activities where number of faculty participating is greater than
-- the number of students particpating, also including the total number of participating
-- faculty and total number of participating students

--use left join as activities with no students wouldn't be accounted for faculty > student
SELECT
    a.activity_name,
    COALESCE(f.num_faculty, 0) AS num_faculty,
    COALESCE(s.num_students, 0) AS num_students
FROM Activity a
LEFT JOIN (
    SELECT actid, COUNT(*) AS num_students
    FROM Participates_in
    GROUP BY actid
) s ON a.actid = s.actid
LEFT JOIN (
    SELECT actid, COUNT(*) AS num_faculty
    FROM Faculty_Participates_in
    GROUP BY actid
) f ON a.actid = f.actid
WHERE COALESCE(f.num_faculty, 0) > COALESCE(s.num_students, 0);


-- 26. List the name of the Computer Science faculty member who has either advised or
-- taught at least 3 distinct students with at least 6 months of work experience each in
-- a company that focuses on finance.
SELECT f.fname, f.lname
FROM Faculty f, Member_of m, (SELECT advisor AS facid, stuid FROM Student
                              UNION
                              SELECT c.instructor, e.stuid
                              FROM Course c, Enrolled_in e
                              WHERE e.cid = c.cid) fs,
                              WorkExp w, Company co
WHERE m.facid = f.facid
AND m.dno = 601
AND fs.facid = f.facid
AND w.stuid = fs.stuid
AND w.number_months_worked >= 6
AND co.companyid = w.companyid
AND co.industry = 'Finance'
GROUP BY f.facid, f.fname, f.lname
HAVING COUNT(DISTINCT fs.stuid) >= 3;


-- 28. List the name and student capacity of all dorms along with their total number of female student atheletes in that dorm (including if 0) and the total number of computer
-- science majors (including if 0)
SELECT
    d.dorm_name,
    d.student_capacity,
    COUNT(DISTINCT CASE
        WHEN s.sex = 'F' AND si.stuid IS NOT NULL
        THEN s.stuid
    END) AS female_student_athletes,
    COUNT(DISTINCT CASE
        WHEN s.major = 601
        THEN s.stuid
    END) AS cs_majors
FROM Dorm d
LEFT JOIN Lives_in l
    ON d.dormid = l.dormid
LEFT JOIN Student s
    ON l.stuid = s.stuid
LEFT JOIN SportsInfo si
    ON s.stuid = si.stuid
GROUP BY d.dormid, d.dorm_name, d.student_capacity;


-- 30. List the name and student capacity of the dorm which has the greatest number of
-- female student athletes but no computer science majors. If there is a tie, report data
-- for all such dorms.
SELECT
    d.dorm_name,
    d.student_capacity,
    COUNT(DISTINCT CASE
        WHEN s.sex = 'F' AND si.stuid IS NOT NULL
        THEN s.stuid
    END) AS female_student_athletes
FROM Dorm d
LEFT JOIN Lives_in l ON d.dormid = l.dormid
LEFT JOIN Student s ON l.stuid = s.stuid
LEFT JOIN SportsInfo si ON s.stuid = si.stuid
WHERE NOT EXISTS (
    SELECT *
    FROM Student s1
    JOIN Lives_in l1 ON s1.stuid = l1.stuid
    WHERE l1.dormid = d.dormid
      AND s1.major = 601
)
GROUP BY d.dormid, d.dorm_name, d.student_capacity
HAVING COUNT(DISTINCT CASE
    WHEN s.sex = 'F' AND si.stuid IS NOT NULL
    THEN s.stuid
END) >= ALL (
    SELECT COUNT(DISTINCT CASE
        WHEN s2.sex = 'F' AND si1.stuid IS NOT NULL
        THEN s2.stuid
    END)
    FROM Dorm d1
    LEFT JOIN Lives_in l1 ON d1.dormid = l1.dormid
    LEFT JOIN Student s2 ON l1.stuid = s2.stuid
    LEFT JOIN SportsInfo si1 ON s2.stuid = si1.stuid
    WHERE NOT EXISTS (
        SELECT *
        FROM Student s3
        JOIN Lives_in l2 ON s3.stuid = l2.stuid
        WHERE l2.dormid = d1.dormid
          AND s3.major = 601
    )
    GROUP BY d1.dormid
);


-- 31. List the first name, last name, email and major of all the students who play at least
-- 1 video game and also have more than one A- or higher grade across all the classes
-- they are enrolled in.

--Email does not exist in either the table schema given or the actual database.txt.
--Who is writing these homeworks bruh
SELECT s.fname, s.lname, d.dname AS major
FROM Student s, Department d
WHERE d.dno = s.major
  AND EXISTS (SELECT * FROM Plays_Games p WHERE p.stuid = s.stuid)
  AND (SELECT COUNT(DISTINCT e.cid)
       FROM Enrolled_in e, Gradeconversion g
       WHERE e.stuid = s.stuid
         AND g.lettergrade = e.grade
         AND g.gradepoint >= 3.7) > 1;


-- 32. List the full name, rank and gender of all faculty members who both teach at least
-- one course in computer science or mechanical engineering and also coaches a sport.
SELECT f.fname, f.lname, f.rank, f.sex
FROM Faculty f, Course c, Department d, CoachedBy cb
WHERE c.instructor = f.facid
  AND d.dno = c.dno
  AND d.dname IN ('Computer Science', 'Mechanical Engineering')
  AND cb.facid = f.facid;


-- 47. List the ID and full name of each student who has at least Intermediate proficiency in
-- every language recorded for student 1001. Compare levels using Proficiency Numeric,
-- exclude student 1001, and require that student 1001 have at least one recorded language. The candidate's proficiency need not match student 1001's level; Intermediate
-- is the threshold for every required language
SELECT s.stuid, s.fname, s.lname
FROM Student s
WHERE s.stuid != 1001
  AND EXISTS (SELECT * FROM Student_Languages x WHERE x.stuid = 1001)
  AND NOT EXISTS (SELECT *
                  FROM Student_Languages l1
                  WHERE l1.stuid = 1001
                    AND NOT EXISTS (SELECT *
                                    FROM Student_Languages l2, Proficiency_Numeric p
                                    WHERE l2.stuid = s.stuid
                                      AND l2.language = l1.language
                                      AND p.proficiency_level = l2.proficiency_level
                                      AND p.proficiency_numeric >= 2));


-- 48. List the names of Computer Science faculty members who have taught more distinct
-- students with work experience at software companies than distinct students with work
-- experience at finance companies. Also list both totals for each such faculty member.
SELECT
    f.fname,
    f.lname,
    COUNT(DISTINCT CASE
        WHEN co.industry = 'Software'
        THEN e.stuid
    END) AS software_students,
    COUNT(DISTINCT CASE
        WHEN co.industry = 'Finance'
        THEN e.stuid
    END) AS finance_students
FROM Faculty f, Member_of m, Course c, Enrolled_in e, WorkExp w, Company co
WHERE f.facid = m.facid
    AND f.facid = c.instructor
    AND c.cid = e.cid
    AND e.stuid = w.stuid
    AND w.companyid = co.companyid
    AND m.dno = 601
GROUP BY f.facid, f.fname, f.lname
HAVING COUNT(DISTINCT CASE
    WHEN co.industry = 'Software'
    THEN e.stuid
END) >
COUNT(DISTINCT CASE
    WHEN co.industry = 'Finance'
    THEN e.stuid
END);


-- 49. List the name and student capacity of the dorm whose student athletes have the
-- highest average number of sports hours per week, considering only dorms with at
-- least two student athletes. If there is a tie, report all tied dorms, along with the
-- average number of sports hours per week.
SELECT d.dorm_name, d.student_capacity, AVG(a.hrs) AS avg_hours_per_week
FROM Dorm d, Lives_in l,
     (SELECT stuid, SUM(hoursperweek) AS hrs FROM SportsInfo GROUP BY stuid) a
WHERE l.dormid = d.dormid
  AND a.stuid = l.stuid
GROUP BY d.dormid, d.dorm_name, d.student_capacity
HAVING COUNT(*) >= 2
   AND AVG(a.hrs) >= ALL (SELECT AVG(a2.hrs)
                          FROM Lives_in l2,
                               (SELECT stuid, SUM(hoursperweek) AS hrs
                                FROM SportsInfo GROUP BY stuid) a2
                          WHERE a2.stuid = l2.stuid
                          GROUP BY l2.dormid
                          HAVING COUNT(*) >= 2);


-- 50. For each musical genre, list the artist or artists having the highest average student
-- rating within that genre. Also list the artist name, genre, average rating, and number
-- of students who rated the artist. If there is a tie within a genre, list all tied artists.
SELECT s.genre, s.artistname, s.avg_rating, s.num_raters
FROM (SELECT m.artid, m.artistname, m.musicalgenre AS genre,
             AVG(r.rating) AS avg_rating, COUNT(DISTINCT r.stuid) AS num_raters
      FROM MusicalArtist m,
           (SELECT DISTINCT stuid, artid, rating FROM LikesArtist) r
      WHERE r.artid = m.artid
      GROUP BY m.artid, m.artistname, m.musicalgenre) s
WHERE s.avg_rating = (SELECT MAX(s2.avg_rating)
                      FROM (SELECT m.artid, m.musicalgenre AS genre,
                                   AVG(r.rating) AS avg_rating
                            FROM MusicalArtist m,
                                 (SELECT DISTINCT stuid, artid, rating FROM LikesArtist) r
                            WHERE r.artid = m.artid
                            GROUP BY m.artid, m.musicalgenre) s2
                      WHERE s2.genre = s.genre);


-- 51. For each musical genre, list the artist or artists with the highest average rating among
-- artists rated by at least two distinct students. Include the genre, artist ID, artist name,
-- number of distinct raters, and average rating. Use the rating convention in Question
-- 1 and report all ties. Omit genres with no qualifying artist.
SELECT s.genre, s.artid, s.artistname, s.num_raters, s.avg_rating
FROM (SELECT m.artid, m.artistname, m.musicalgenre AS genre,
             AVG(r.rating) AS avg_rating, COUNT(DISTINCT r.stuid) AS num_raters
      FROM MusicalArtist m,
           (SELECT DISTINCT stuid, artid, rating FROM LikesArtist) r
      WHERE r.artid = m.artid
      GROUP BY m.artid, m.artistname, m.musicalgenre
      HAVING COUNT(DISTINCT r.stuid) >= 2) s
WHERE s.avg_rating = (SELECT MAX(s2.avg_rating)
                      FROM (SELECT m.artid, m.musicalgenre AS genre,
                                   AVG(r.rating) AS avg_rating
                            FROM MusicalArtist m,
                                 (SELECT DISTINCT stuid, artid, rating FROM LikesArtist) r
                            WHERE r.artid = m.artid
                            GROUP BY m.artid, m.musicalgenre
                            HAVING COUNT(DISTINCT r.stuid) >= 2) s2
                      WHERE s2.genre = s.genre);


-- 52. List the student ID and full name of each student who has applied for at least one job
-- and has accepted an offer for every distinct job they applied for. Match applications
-- to accepted offers using student ID, company, and position; disregard the application
-- date when identifying a distinct job. Additional accepted offers are irrelevant. List
-- each student once.
SELECT s.stuid, s.fname, s.lname
FROM Student s
WHERE EXISTS (SELECT * FROM JobsAppliedFor j WHERE j.stuid = s.stuid)
  AND NOT EXISTS (SELECT *
                  FROM JobsAppliedFor j
                  WHERE j.stuid = s.stuid
                    AND NOT EXISTS (SELECT *
                                    FROM OffersAccepted o
                                    WHERE o.stuid = j.stuid
                                      AND o.company = j.company
                                      AND o.position = j.position));


-- 53. For every department, list its department number and name, the number of distinct
-- faculty members with a primary appointment in the department, and the number of
-- distinct students enrolled in at least one course offered by the department. Determine
-- the offering department from Course.DNO, regardless of the instructor's appointment.
-- Include every department, reporting each missing count as zero. Count each faculty
-- member and student only once within a department, even if multiple appointment or
-- enrollment records match.
SELECT d.dno, d.dname,
       (SELECT COUNT(DISTINCT m.facid)
        FROM Member_of m
        WHERE m.dno = d.dno
          AND m.appt_type = 'Primary') AS num_primary_faculty,
       (SELECT COUNT(DISTINCT e.stuid)
        FROM Enrolled_in e, Course c
        WHERE c.cid = e.cid
          AND c.dno = d.dno) AS num_students
FROM Department d;


-- 54. List the full name, major name, and absence rate of students whose absence rate
-- exceeds the average rate among enrolled students in their major. Define a student's
-- absence rate as their total recorded absences in courses they are enrolled in divided
-- by their number of distinct enrolled courses. Compute each major's average as the
-- arithmetic mean of its enrolled students' individual absence rates. Include enrolled
-- students with zero absences when calculating this average, and exclude students with
-- no enrollments.
SELECT s.fname, s.lname, d.dname major, r.rate absence_rate
FROM (SELECT s1.stuid, s1.major,
             (SELECT COUNT(*)
              FROM Student_Absence a
              WHERE a.stuid = s1.stuid
                AND EXISTS (SELECT * FROM Enrolled_in e
                            WHERE e.stuid = a.stuid AND e.cid = a.cid))
             / (SELECT COUNT(DISTINCT e2.cid)
                FROM Enrolled_in e2
                WHERE e2.stuid = s1.stuid) rate
      FROM Student s1
      WHERE EXISTS (SELECT * FROM Enrolled_in e3 WHERE e3.stuid = s1.stuid)) r,
     Student s, Department d
WHERE s.stuid = r.stuid
  AND d.dno = s.major
  AND r.rate > (SELECT AVG(r2.rate)
                FROM (SELECT s2.stuid, s2.major,
                             (SELECT COUNT(*)
                              FROM Student_Absence a
                              WHERE a.stuid = s2.stuid
                                AND EXISTS (SELECT * FROM Enrolled_in e
                                            WHERE e.stuid = a.stuid AND e.cid = a.cid))
                             / (SELECT COUNT(DISTINCT e2.cid)
                                FROM Enrolled_in e2
                                WHERE e2.stuid = s2.stuid) rate
                      FROM Student s2
                      WHERE EXISTS (SELECT * FROM Enrolled_in e3 WHERE e3.stuid = s2.stuid)) r2
                WHERE r2.major = r.major);


-- 55. List the name and multilingual-resident percentage of the dorms with the highest
-- such percentage. Define a multilingual student as one with at least two distinct
-- languages recorded in Student Languages. Calculate each dorm's percentage as 100
-- times its number of distinct multilingual residents divided by its total number of
-- distinct residents. Include all ties and exclude dorms without residents.
SELECT d.dorm_name,
       100 * COUNT(DISTINCT m.stuid) / COUNT(DISTINCT l.stuid) AS multilingual_pct
FROM Dorm d
     JOIN Lives_in l ON l.dormid = d.dormid
     LEFT JOIN (SELECT stuid FROM Student_Languages
                GROUP BY stuid
                HAVING COUNT(DISTINCT language) >= 2) m ON m.stuid = l.stuid
GROUP BY d.dormid, d.dorm_name
HAVING 100 * COUNT(DISTINCT m.stuid) / COUNT(DISTINCT l.stuid) >=
       ALL (SELECT 100 * COUNT(DISTINCT m2.stuid) / COUNT(DISTINCT l2.stuid)
            FROM Lives_in l2
                 LEFT JOIN (SELECT stuid FROM Student_Languages
                            GROUP BY stuid
                            HAVING COUNT(DISTINCT language) >= 2) m2 ON m2.stuid = l2.stuid
            GROUP BY l2.dormid);


-- 56.
SELECT d.dname, e.eventname, c.cnt AS num_attending_students
FROM (SELECT s.major, a.eventid, COUNT(DISTINCT s.stuid) AS cnt
      FROM Attends_Student_Life_Event a, Student s
      WHERE s.stuid = a.stuid
      GROUP BY s.major, a.eventid) c,
     Department d, Student_Life_Event e
WHERE d.dno = c.major
  AND e.eventid = c.eventid
  AND c.cnt = (SELECT MAX(c2.cnt)
               FROM (SELECT s.major, a.eventid, COUNT(DISTINCT s.stuid) AS cnt
                     FROM Attends_Student_Life_Event a, Student s
                     WHERE s.stuid = a.stuid
                     GROUP BY s.major, a.eventid) c2
               WHERE c2.major = c.major);


-- 57.
SELECT s.fname, s.lname
FROM Student s
WHERE EXISTS (SELECT *
              FROM Member_of_club mc, Student_Life_Event e
              WHERE mc.stuid = s.stuid
                AND e.sponsorclubid = mc.clubid)
  AND NOT EXISTS (SELECT *
                  FROM Member_of_club mc, Student_Life_Event e
                  WHERE mc.stuid = s.stuid
                    AND e.sponsorclubid = mc.clubid
                    AND NOT EXISTS (SELECT *
                                    FROM Attends_Student_Life_Event a
                                    WHERE a.stuid = s.stuid
                                      AND a.eventid = e.eventid));


-- 58.
SELECT p.projectid, p.projecttitle, c.cname
FROM Course_Projects p, Course c
WHERE c.cid = p.cid
  AND EXISTS (SELECT * FROM Enrolled_in e WHERE e.cid = p.cid)
  AND NOT EXISTS (SELECT *
                  FROM Enrolled_in e, Student s
                  WHERE e.cid = p.cid
                    AND s.stuid = e.stuid
                    AND NOT EXISTS (SELECT *
                                    FROM Project_Members pm, Student s2
                                    WHERE pm.projectid = p.projectid
                                      AND s2.stuid = pm.stuid
                                      AND s2.major = s.major));


-- 59.
SELECT s.stuid, s.fname, s.lname
FROM Student s
WHERE EXISTS (SELECT *
              FROM Campus_Event ce, Department d
              WHERE d.dno = ce.dno
                AND d.dname = 'Computer Science')
  AND NOT EXISTS (SELECT *
                  FROM Campus_Event ce, Department d
                  WHERE d.dno = ce.dno
                    AND d.dname = 'Computer Science'
                    AND NOT EXISTS (SELECT *
                                    FROM Event_Registration er
                                    WHERE er.eventid = ce.eventid
                                      AND er.stuid = s.stuid));


-- 60.
SELECT p.cid, p.cname, p.session_id, p.session_date, p.tutor,
       FORMAT(p.pct, 2) AS attendance_pct
FROM (SELECT c.cid, c.cname, ts.session_id, ts.session_date,
             CONCAT(t.fname, ' ', t.lname) AS tutor,
             100.0 * (SELECT COUNT(DISTINCT ta.stuid)
                      FROM Tutoring_Attendance ta
                      WHERE ta.session_id = ts.session_id
                        AND ta.stuid != ts.tutor_stuid
                        AND EXISTS (SELECT * FROM Enrolled_in e
                                    WHERE e.stuid = ta.stuid AND e.cid = ts.cid))
             / (SELECT COUNT(DISTINCT e2.stuid)
                FROM Enrolled_in e2
                WHERE e2.cid = ts.cid) AS pct
      FROM Tutoring_Session ts, Course c, Student t
      WHERE c.cid = ts.cid
        AND t.stuid = ts.tutor_stuid
        AND EXISTS (SELECT * FROM Enrolled_in e3 WHERE e3.cid = ts.cid)) p
WHERE p.pct = (SELECT MAX(p2.pct)
               FROM (SELECT ts.cid,
                            100.0 * (SELECT COUNT(DISTINCT ta.stuid)
                                     FROM Tutoring_Attendance ta
                                     WHERE ta.session_id = ts.session_id
                                       AND ta.stuid != ts.tutor_stuid
                                       AND EXISTS (SELECT * FROM Enrolled_in e
                                                   WHERE e.stuid = ta.stuid AND e.cid = ts.cid))
                            / (SELECT COUNT(DISTINCT e2.stuid)
                               FROM Enrolled_in e2
                               WHERE e2.cid = ts.cid) AS pct
                     FROM Tutoring_Session ts
                     WHERE EXISTS (SELECT * FROM Enrolled_in e3 WHERE e3.cid = ts.cid)) p2
               WHERE p2.cid = p.cid);


-- 61. My own question: Let being loved by equal double the weight of being liked (whoisloved = 2 * whoisliked) so the total appreciation of someone
-- is: appreciation = 2 * whoisloved + whoisliked. Find the first and last names of the student(s) with the highest appreciation score among students who are course assistants
-- for courses offered by departments other than their own major department. Include all ties.
SELECT s.fname, s.lname
FROM Student s
WHERE EXISTS (
    SELECT *
    FROM Course_CA ca, Course c
    WHERE ca.stuid = s.stuid
      AND ca.cid = c.cid
      AND c.dno != s.major
)
AND (
    SELECT COUNT(DISTINCT l.wholikes)
    FROM Likes l
    WHERE l.whoisliked = s.stuid
) + 2 * (
    SELECT COUNT(DISTINCT lv.wholoves)
    FROM Loves lv
    WHERE lv.whoisloved = s.stuid
) >= ALL (
    SELECT
        (SELECT COUNT(DISTINCT l2.wholikes)
         FROM Likes l2
         WHERE l2.whoisliked = s1.stuid)
        + 2 * (
            SELECT COUNT(DISTINCT lv2.wholoves)
            FROM Loves lv2
            WHERE lv2.whoisloved = s1.stuid
        )
    FROM Student s1
    WHERE EXISTS (
        SELECT *
        FROM Course_CA ca1, Course c1
        WHERE ca1.stuid = s1.stuid
          AND ca1.cid = c1.cid
          AND c1.dno != s1.major
    )
);


-- 62. THIS IS IN QBE.TXT