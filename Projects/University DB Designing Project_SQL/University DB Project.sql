
use master

CREATE DATABASE University;

USE University;

--By using region ids instead of region names in tables, we preferred multiplexing of int expressions instead of string.


CREATE TABLE Region
(
RegionID INT IDENTITY(1, 1),
RegionName VARCHAR(25) CHECK (RegionName IN ('England', 'Scotland', 'Wales', 'Northern Ireland')) NOT NULL,
PRIMARY KEY (RegionID)
);


INSERT Region (RegionName)
VALUES('England'),
('Scotland'),
('Wales'),
('Northern Ireland');


CREATE TABLE Staff
(
StaffID INT IDENTITY(10, 1),
StaffName nVARCHAR(50) NOT NULL,
StaffSurname nVARCHAR(50) NOT NULL,
RegionID INT NOT NULL,
PRIMARY KEY (StaffID),
FOREIGN KEY (RegionID) REFERENCES Region(RegionID)
);


INSERT Staff (StaffName, StaffSurname,  RegionID)
VALUES('Selim', 'Aydin',  1),
('Semil', 'Acik', 1),
('Gungor', 'Salih', 1),
('Gulsum', 'Cicekci', 2),
('Hatice', 'Dogan', 2),
('Esra', 'Gamze', 3),
('Eda', 'Yucel', 4),
('Arslan', 'Celik', 3),
('Metin', 'Ozden', 4)

-- Since each student can only have one staff (as it cannot be a null value), there is no problem having the staff id in the student table.
-- So the consultancy relationship between staff and student is provided in the student table 

CREATE TABLE Student
(
StudentID INT IDENTITY(20, 1),
StudentName nVARCHAR(50) NOT NULL,
StudentSurname nVARCHAR(50) NOT NULL,
StaffID INT NOT NULL,
RegionID INT NOT NULL,
RegistrationDate Date NOT NULL DEFAULT '2020-05-12',
PRIMARY KEY (StudentID),
FOREIGN KEY (StaffID) REFERENCES Staff (StaffID),
FOREIGN KEY (RegionID) REFERENCES Region(RegionID)
);


INSERT INTO Student (StudentName, StudentSurname, StaffID, RegionID)
VALUES('Ali', 'Guzel', 10, 1),
('Osman', 'Yucel', 11, 1),
('Omer','Ilhan', 12, 1),
('Bekir', 'Gul', 13, 2),
('Ahmet', 'Cicek', 14, 2),
('Mehmet', 'Uyanik', 15, 3);


CREATE TABLE Course
(
CourseID INT IDENTITY(30, 1),
Title VARCHAR(50) NOT NULL,
Credit INT CHECK (Credit in (15,30)) NOT NULL,
Quota INT NULL,
PRIMARY KEY (CourseID)
);


INSERT Course (Title, Credit, Quota)
VALUES('Math', 30, 5),
('Physics', 30, 8),
('Chemistry', 30, 7),
('English', 30, null),
('Biology', 15, 10),
('Fine Arts', 15, null),
('German', 15, 17),
('Music', 30, 3),
('Psychology', 30 ,10);


CREATE TABLE Enrollment
(
StudentID INT  NOT NULL, 
CourseID INT NOT NULL, 
PRIMARY KEY (StudentID, CourseID),
FOREIGN KEY (StudentID) REFERENCES Student(StudentID),
FOREIGN KEY (CourseID) REFERENCES Course(CourseID)
);


---////////////////////////////


CREATE TABLE StaffCourse
(
StaffID INT NOT NULL,
CourseID INT NOT NULL, 
PRIMARY KEY (StaffID, CourseID),
FOREIGN KEY (StaffID) REFERENCES Staff(StaffID) --ON DELETE CASCADE
FOREIGN KEY (CourseID) REFERENCES Course(CourseID)
);


INSERT INTO StaffCourse (StaffID, CourseID)
VALUES(10, 30),
(12, 30),
(10, 31),
(11, 31),
(12, 38)


--///////////////////////////


CREATE TABLE Assignment
(
StudentID INT REFERENCES Student(StudentID) NOT NULL, 
CourseID INT REFERENCES Course(CourseID) NOT NULL, 
AssignmentID INT NOT NULL,
Grade INT Check(Grade BETWEEN 0 AND 100) NOT NULL,
PRIMARY KEY (StudentID, CourseID, AssignmentID),
FOREIGN KEY (StudentID, CourseID) REFERENCES Enrollment(StudentID, CourseID)
);


--////////////////////


--constraints

-- If a student's credit quota exceeds 180, we want the new insert to be rejected.
-- Function will return 1 if credit quota is exceeded, 0 if not


Create FUNCTION dbo.check_credit()
RETURNS INT
AS
BEGIN
	DECLARE @REJECT int

	IF EXISTS (
				SELECT 1
				FROM	(
						SELECT	B.StudentID, sum(Credit) sum_credit
						FROM	Course A 
						INNER JOIN Enrollment B 
						ON		A.CourseID = B.CourseID
						GROUP BY B.StudentID
						) A
				WHERE sum_credit > 180
			) 
		SET @REJECT = 1 
	ELSE
		SET @REJECT = 0

RETURN @REJECT
END;


ALTER TABLE Enrollment
ADD CONSTRAINT CK_check_credit CHECK(dbo.check_credit() = 0);


INSERT INTO Enrollment (StudentID, CourseID)
VALUES (21, 30),
(21, 31),
(21, 32),
(21, 33),
(21, 37),
(21, 38)


-- Let's test the constraint. Does not accept, it works 

INSERT Enrollment VALUES (21, 35)

--Some of the courses have student quotas.
--We need to define a constraint so that the number of students enrolled in the course is not more than the quota of the course.
-- Again, we define a function for this.

CREATE FUNCTION check_quota()
RETURNS INT
AS
BEGIN
	DECLARE @REJECT int
		IF EXISTS(
					SELECT 1
					FROM
					Course A
					INNER JOIN	(	
								SELECT CourseID, COUNT(DISTINCT StudentID) AS CNT_Student
								FROM Enrollment
								GROUP BY CourseID
								) B
					ON A.CourseID = B.CourseID
					WHERE A.Quota IS NOT NULL
					AND	  A.Quota < B.CNT_Student
				)
			SET @REJECT = 1 
		ELSE 
			SET @REJECT = 0

RETURN @REJECT
END;


ALTER TABLE Enrollment
ADD CONSTRAINT CK_check_quota CHECK(dbo.check_quota() = 0);


--- Let's try constraint The quota of course id 37 is 3

select * from course


INSERT INTO Enrollment
VALUES 
(22, 37),
(23, 37)
,

(24, 37); --A record has been added to the course with 37 id above, the quota restriction works here and does not allow the 3rd student.


--Is this quota applied to other courses?


-- 35 id courses with no quota
INSERT Enrollment
VALUES (22, 35),
(23, 35),
(24, 35),
(25, 35);


-- 36 id courses with a quota of 17
INSERT Enrollment
VALUES (22, 36),
(23, 36),
(24, 36),
(25, 36);


--No problem at all, it works!

-------------------

-- A 30 CREDIT COURSE CAN HAVE A MAXIMUM OF 5 ASSIGNMENTS


CREATE FUNCTION check_num_of_assignment()
RETURNS INT
AS
BEGIN
	DECLARE @REJECT int
		IF EXISTS(
					SELECT 1
					FROM (
							SELECT count(DISTINCT A.AssignmentID) CNT_assignment
							FROM Assignment A 
							INNER JOIN Course B 
							ON A.CourseID = B.CourseID 
							WHERE B.Credit = 30 
							GROUP BY A.CourseID
						) A
					WHERE CNT_assignment > 5
				)
			SET @REJECT =1
		ELSE 
			SET @REJECT = 0

RETURN @REJECT;
END;


ALTER TABLE Assignment
ADD CONSTRAINT CN_check_num_of_assignment CHECK(dbo.check_num_of_assignment() = 0);


-- Let's test the constraint


INSERT INTO Assignment (StudentID, CourseID, AssignmentID, Grade)
VALUES
(21, 30, 1, 90),
(21, 30, 2, 0),
(21, 30, 3, 85),
(21, 30, 4, 60),
(21, 30, 5, 100);


--6. either didn't allow it, the constraint is working
INSERT INTO Assignment (StudentID, CourseID, AssignmentID, Grade)
VALUES	(21, 30, 6, 90)



--/////////////////////////


-- A course of 15 credits can have a maximum of 3 assignments.


CREATE FUNCTION check_num_of_assignment2()
RETURNS INT
AS
BEGIN
	DECLARE @REJECT int
		IF EXISTS(
					SELECT 1
					FROM (
							SELECT count(DISTINCT A.AssignmentID) CNT_assignment
							FROM Assignment A 
							INNER JOIN Course B 
							ON A.CourseID = B.CourseID 
							WHERE B.Credit = 15 
							GROUP BY A.CourseID
						) A
					WHERE CNT_assignment > 3
				)
			SET @REJECT =1
		ELSE 
			SET @REJECT = 0

RETURN @REJECT;
END;



ALTER TABLE Assignment
ADD CONSTRAINT CK_check_num_of_assignment2 CHECK(dbo.check_num_of_assignment2() = 0);


--Let's check the constraint.


INSERT INTO Assignment (StudentID, CourseID, AssignmentID, Grade)
VALUES
(25, 35, 1, 90),
(25, 35, 2, 50),
(25, 35, 3, 85)


-- 4. did not allow recording, works fine

INSERT INTO Assignment (StudentID, CourseID, AssignmentID, Grade)
VALUES
(25, 35, 4, 100)


--////////////////////////////


-- The student's region and the teacher's region must be the same


CREATE FUNCTION check_region()
RETURNS INT
AS
BEGIN
	DECLARE @REJECT int
		IF EXISTS(
					SELECT 1
					FROM StaffCourse A 
					INNER JOIN Enrollment B ON A.CourseID = B.CourseID
					INNER JOIN Student C ON B.StudentID = C.StudentID
					INNER JOIN Staff D ON D.StaffID = A.StaffID
					WHERE C.RegionID != D.RegionID
				)
			SET @REJECT = 1
		ELSE 
			SET @REJECT = 0

RETURN @REJECT
END;


ALTER TABLE Enrollment
ADD CONSTRAINT CK_check_region CHECK(dbo.check_region() = 0);


-- Let's try the constraint. It didn't accept, so it works


-- The region of the student with id number 25 and the staff teaching the course with 38 id should not accept this match because their regions are different.

SELECT * FROM Student WHERE StudentID = 25


SELECT *
FROM StaffCourse A, Staff B
WHERE A.StaffID=B.StaffID
AND A.CourseID=38


INSERT INTO Enrollment
VALUES
(25, 38);


--------///////////////////


--The student's region and the advisor's region must be the same


CREATE FUNCTION check_region2()
RETURNS INT
AS
BEGIN
	DECLARE @REJECT int
		IF EXISTS(
					SELECT 1
					FROM Student A INNER JOIN Staff B ON A.StaffID = B.StaffID 
					WHERE A.RegionID != B.RegionID
				)
			SET @REJECT =1
		ELSE 
			SET @REJECT = 0

RETURN @REJECT
END;


ALTER TABLE Student
ADD CONSTRAINT CK_check_region2 CHECK(dbo.check_region2() = 0);


--Checking the constraint

-- The following students and their advisors' region id's are accepted because they match
INSERT INTO Student (StudentName, StudentSurname, StaffID, RegionID)
VALUES
('Ayse', 'Menekse', 16, 4),
('Mehmet', 'Keles', 15, 3),
('Ahsen', 'Cure', 15, 3);


-- But here the staff no. 16 does not accept this insert because its region is not 5, so constraint works.
INSERT INTO Student (StudentName, StudentSurname, StaffID, RegionID)
VALUES
('Leyla', 'Tok', 16, 5)


--///////////////////////////////


------INSTRUCTIONS


-- 1. Change a student's grade by creating a SQL script that updates a student's grade in the assignment table.

SELECT * FROM Assignment


UPDATE Assignment
SET Grade = 70
WHERE AssignmentID = 4
AND StudentID = 21
AND CourseID = 30


-- 2. Update the credit for a course.
SELECT * FROM Course


-- Course id 30 has 30 credits, when we try to make it 10 we get an error because we set a constraint, a course can have 15 or 30 credits.

UPDATE Course
SET Credit = 10
WHERE CourseID = 30


--//////////////////////////


-- 3. Swap the responsible staff of two students with each other in the student table.

SELECT * FROM Student

-- We cannot make changes as follows. Because after the first change has taken place, the second one has no meaning.

UPDATE Student
SET StaffID = (SELECT StaffID FROM Student WHERE StudentID=20) 
WHERE StudentID = 21;


UPDATE Student
SET StaffID = (SELECT StaffID FROM Student WHERE StudentID=21) 
WHERE StudentID = 20


-- We should do this as follows.
-- First, we assign the staff IDs of the students whose advisors we will change to a variable,
-- We specify these variables as the new value in the next update process.


DECLARE @FIRST_STAFF INT;
DECLARE @SECOND_STAFF INT;

SET @FIRST_STAFF = (SELECT StaffID FROM Student WHERE StudentID=23);
SET @SECOND_STAFF = (SELECT StaffID FROM Student WHERE StudentID=24);


UPDATE Student
SET StaffID = @FIRST_STAFF -- eski deðer 14
WHERE StudentID = 24;


UPDATE Student
SET StaffID = @SECOND_STAFF -- eski deðer 13
WHERE StudentID = 23


--///////////////////


-- 4. Remove a staff member who is not assigned to any student from the staff table.


-- It is possible that you will receive an error from the delete operation as it is. Read the error.
-- It will say that a foreign key constraint in the StaffCourse table does not allow it.
-- In other words, the error occurs due to the restrictions put on the foreign key operation by the ON DELETE/UPDATE conditions expressed as foreign key rules.
-- While defining the foreign key constraint for the staff id in the StaffCourse table (see above), we left the foreign key rule undefined with its default setting.
-- Since it is ON DELETE NO ACTION by default, it blocks the delete operation for the foreign key.
-- If you re-create the foreign key constraint defined for Staff id in the StaffCourse table as ON DELETE CASCADE, you can delete it.
-- You can drop and recreate the StaffCourse table, or you can just drop the foreign key constraint first and then add the new version to the table.


SELECT * FROM Staff


SELECT StaffID --top 1
FROM Staff 
WHERE STAFFID NOT IN (SELECT StaffID FROM Student)



DELETE FROM Staff 
WHERE StaffID = (
					SELECT Top 1 StaffID 
					FROM Staff 
					WHERE STAFFID NOT IN (SELECT StaffID FROM Student)
				);


-- 5. Add a student to the student table and enroll the student you added to any course.


-- You can be blocked by constraints with different values in the following new student additions.
-- You may tinker a bit and think about why it is stuck in which constraint.


INSERT INTO Student (StudentName, StudentSurname, StaffID, RegionID)
VALUES('Zeynep', 'Aktas', 13, 2);


SELECT * FROM Student


INSERT INTO Enrollment (StudentID, CourseID)
VALUES(30, 36);



SELECT * FROM Enrollment