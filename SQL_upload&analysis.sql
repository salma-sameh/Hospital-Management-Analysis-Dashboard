-- final data analysis project 
USE [Hospital Management];
GO
---------------------------------------------------------------------------check imported data
select * 
from appointments

select * 
from billing

select * 
from doctors

select * 
from patients

select * 
from treatments
---------------------------------------------------------------------------adding  relations between tables
-- 1. Patients (1) -> Appointments (*)
ALTER TABLE dbo.appointments
ADD CONSTRAINT FK_appointments_patients
FOREIGN KEY (patient_id)
REFERENCES dbo.patients (patient_id);
GO

-- 2. Doctors (1) -> Appointments (*)
ALTER TABLE dbo.appointments
ADD CONSTRAINT FK_appointments_doctors
FOREIGN KEY (doctor_id)
REFERENCES dbo.doctors (doctor_id);
GO

-- 3. Appointments (1) -> Treatments (1)
ALTER TABLE dbo.treatments
ADD CONSTRAINT FK_treatments_appointments
FOREIGN KEY (appointment_id)
REFERENCES dbo.appointments (appointment_id);
GO

-- Enforce one treatment per appointment
ALTER TABLE dbo.treatments
ADD CONSTRAINT UQ_treatments_appointment_id
UNIQUE (appointment_id);
GO

-- 4. Treatments (1) -> Billing (1)
ALTER TABLE dbo.billing
ADD CONSTRAINT FK_billing_treatments
FOREIGN KEY (treatment_id)
REFERENCES dbo.treatments (treatment_id);
GO

-- Enforce one bill per treatment
ALTER TABLE dbo.billing
ADD CONSTRAINT UQ_billing_treatment_id
UNIQUE (treatment_id);
GO

-- 5. Patients (1) -> Billing (*)
ALTER TABLE dbo.billing
ADD CONSTRAINT FK_billing_patients
FOREIGN KEY (patient_id)
REFERENCES dbo.patients (patient_id);
GO
----------------------------------------------------------------------------------------------data analysis(quires)
--1. QUESTION:How many patients are registered in the hospital?
SELECT
    COUNT(*) AS total_patients
FROM dbo.patients;

--2. QUESTION:What is the gender distribution of registered patients?
SELECT
    gender,
    COUNT(*) AS total_patients,
    CAST(
        COUNT(*) * 100.0 / NULLIF(
            (SELECT COUNT(*) FROM dbo.patients), 0 ------ avoid divide by zero
        ) AS DECIMAL(5,2)
    ) AS percentage_of_patients
FROM dbo.patients
GROUP BY gender
ORDER BY total_patients DESC;

--3. QUESTION: What are the hospital's key operational and financial KPIs?
SELECT
    (SELECT COUNT(*)
     FROM dbo.patients) AS total_patients,

    (SELECT COUNT(*)
     FROM dbo.doctors) AS total_doctors,

    (SELECT COUNT(*)
     FROM dbo.appointments) AS total_appointments,

    (SELECT COUNT(*)
     FROM dbo.treatments) AS total_treatments,

    (SELECT ROUND(COALESCE(SUM(amount), 0), 2)
     FROM dbo.billing) AS total_billed_amount,

    (SELECT ROUND(COALESCE(SUM(amount), 0), 2)
     FROM dbo.billing
     WHERE LOWER(LTRIM(RTRIM(payment_status))) = 'paid')
        AS collected_revenue,

    (SELECT ROUND(COALESCE(SUM(amount), 0), 2)
     FROM dbo.billing
     WHERE LOWER(LTRIM(RTRIM(payment_status))) <> 'paid'
        OR payment_status IS NULL)
        AS outstanding_billed_amount;
GO

--4. QUESTION: Which hospital branches have the most doctors?
SELECT
    hospital_branch,
    COUNT(*) AS total_doctors
FROM dbo.doctors
GROUP BY hospital_branch
ORDER BY total_doctors DESC;


--5. QUESTION: Which medical specializations have the most doctors, and what is their average experience?
SELECT
    specialization,
    COUNT(*) AS total_doctors,
    AVG(CAST(years_experience AS DECIMAL(10,2)))
        AS average_years_experience
FROM dbo.doctors
GROUP BY specialization
ORDER BY total_doctors DESC;


--6. QUESTION: Which doctors handle the highest number of appointments?
SELECT
    d.doctor_id,
    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
    d.specialization,
    d.hospital_branch,
    COUNT(a.appointment_id) AS total_appointments
FROM dbo.doctors AS d
LEFT JOIN dbo.appointments AS a
    ON d.doctor_id = a.doctor_id
GROUP BY
    d.doctor_id,
    d.first_name,
    d.last_name,
    d.specialization,
    d.hospital_branch
ORDER BY total_appointments DESC;


--7. QUESTION: What is the distribution of appointments by status?
SELECT
    status,
    COUNT(*) AS total_appointments,
    CAST(
        COUNT(*) * 100.0 / NULLIF(
            (SELECT COUNT(*) FROM dbo.appointments), 0  ---- avoid divide by zero 
        ) AS DECIMAL(5,2)
    ) AS percentage_of_appointments
FROM dbo.appointments
GROUP BY status
ORDER BY total_appointments DESC;


--8. QUESTION: How many appointments are scheduled each month?
SELECT
    YEAR(appointment_date) AS appointment_year,
    MONTH(appointment_date) AS appointment_month,
    COUNT(*) AS total_appointments
FROM dbo.appointments
WHERE appointment_date IS NOT NULL
GROUP BY
    YEAR(appointment_date),
    MONTH(appointment_date)
ORDER BY
    appointment_year,
    appointment_month;


--9. QUESTION: What are the most common reasons for visiting the hospital?
SELECT TOP (10)
    reason_for_visit,
    COUNT(*) AS total_appointments
FROM dbo.appointments
WHERE reason_for_visit IS NOT NULL
GROUP BY reason_for_visit
ORDER BY total_appointments DESC;


--10. QUESTION: Which patients have the highest number of appointments?
SELECT TOP (10)
    p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    COUNT(a.appointment_id) AS total_appointments
FROM dbo.patients AS p
INNER JOIN dbo.appointments AS a
    ON p.patient_id = a.patient_id
GROUP BY
    p.patient_id,
    p.first_name,
    p.last_name
ORDER BY total_appointments DESC;


--11. QUESTION: What are the total and average treatment costs by treatment type?
SELECT
    treatment_type,
    COUNT(*) AS total_treatments,
    SUM(cost) AS total_treatment_cost,
    AVG(CAST(cost AS DECIMAL(18,2))) AS average_treatment_cost
FROM dbo.treatments
GROUP BY treatment_type
ORDER BY total_treatments DESC;


--12. QUESTION: Which treatment types have the highest total treatment costs?
SELECT TOP (10)
    treatment_type,
    SUM(cost) AS total_treatment_cost,
    COUNT(*) AS treatment_count
FROM dbo.treatments
GROUP BY treatment_type
ORDER BY total_treatment_cost DESC;


--13. QUESTION: How do treatment costs change each month?
SELECT
    YEAR(treatment_date) AS treatment_year,
    MONTH(treatment_date) AS treatment_month,
    COUNT(*) AS total_treatments,
    SUM(cost) AS monthly_treatment_cost,
    AVG(CAST(cost AS DECIMAL(18,2))) AS average_cost
FROM dbo.treatments
WHERE treatment_date IS NOT NULL
GROUP BY
    YEAR(treatment_date),
    MONTH(treatment_date)
ORDER BY
    treatment_year,
    treatment_month;


--14. QUESTION: What are the total, average, minimum, and maximum bill amounts?
SELECT
    COUNT(*) AS total_bills,
    SUM(amount) AS total_billed_amount,
    AVG(CAST(amount AS DECIMAL(18,2))) AS average_bill_amount,
    MIN(amount) AS minimum_bill_amount,
    MAX(amount) AS maximum_bill_amount
FROM dbo.billing;


--15. QUESTION: What is the total billed amount and number of bills by payment status?
SELECT
    payment_status,
    COUNT(*) AS total_bills,
    SUM(amount) AS total_billed_amount,
    AVG(CAST(amount AS DECIMAL(18,2))) AS average_bill_amount
FROM dbo.billing
GROUP BY payment_status
ORDER BY total_billed_amount DESC;


--16. QUESTION: Which payment methods are most frequently used?
SELECT
    payment_method,
    COUNT(*) AS total_transactions,
    SUM(amount) AS total_billed_amount,
    AVG(CAST(amount AS DECIMAL(18,2))) AS average_transaction_amount
FROM dbo.billing
GROUP BY payment_method
ORDER BY total_transactions DESC;


--17. QUESTION: How much revenue has been collected compared with outstanding billed amounts?
SELECT
    round(SUM(
        CASE
            WHEN LOWER(LTRIM(RTRIM(payment_status))) = 'paid'
            THEN amount
            ELSE 0
        END
    ),2) AS collected_revenue,
    round(SUM(
        CASE
            WHEN LOWER(LTRIM(RTRIM(payment_status))) <> 'paid'
                 OR payment_status IS NULL
            THEN amount
            ELSE 0
        END
    ),2) AS outstanding_billed_amount,
    COUNT(
        CASE
            WHEN LOWER(LTRIM(RTRIM(payment_status))) = 'paid'
            THEN 1
        END
    ) AS paid_bills,
    COUNT(
        CASE
            WHEN LOWER(LTRIM(RTRIM(payment_status))) <> 'paid'
                 OR payment_status IS NULL
            THEN 1
        END
    ) AS unpaid_or_other_status_bills
FROM dbo.billing;


--18. QUESTION: Which patients have the highest total billed amounts?
SELECT TOP (10)
    p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    COUNT(b.bill_id) AS total_bills,
    SUM(b.amount) AS total_billed_amount
FROM dbo.patients AS p
INNER JOIN dbo.billing AS b
    ON p.patient_id = b.patient_id
GROUP BY
    p.patient_id,
    p.first_name,
    p.last_name
ORDER BY total_billed_amount DESC;


--19. QUESTION: Which doctors generate the highest total treatment costs?
SELECT
    d.doctor_id,
    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
    d.specialization,
    COUNT(DISTINCT a.appointment_id) AS total_appointments,
    COUNT(t.treatment_id) AS total_treatments,
    SUM(t.cost) AS total_treatment_cost,
    AVG(CAST(t.cost AS DECIMAL(18,2))) AS average_treatment_cost
FROM dbo.doctors AS d
INNER JOIN dbo.appointments AS a
    ON d.doctor_id = a.doctor_id
INNER JOIN dbo.treatments AS t
    ON a.appointment_id = t.appointment_id
GROUP BY
    d.doctor_id,
    d.first_name,
    d.last_name,
    d.specialization
ORDER BY total_treatment_cost DESC;
