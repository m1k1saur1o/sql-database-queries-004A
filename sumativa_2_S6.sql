--caso 1

SELECT
    ID,
    PROFESIONAL,
    SUM(NRO_ASESORIA_BANCA) AS NRO_ASESORIA_BANCA,
    TO_CHAR(SUM(MONTO_TOTAL_BANCA), '$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''' ) AS MONTO_TOTAL_BANCA,
    SUM(NRO_ASESORIA_RETAIL) AS NRO_ASESORIA_RETAIL,
    TO_CHAR(SUM(MONTO_TOTAL_RETAIL), '$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''' ) AS MONTO_TOTAL_RETAIL,
    SUM(NRO_ASESORIA_BANCA) + SUM(NRO_ASESORIA_RETAIL) AS TOTAL_ASESORIAS,
    TO_CHAR(SUM(MONTO_TOTAL_BANCA) + SUM(MONTO_TOTAL_RETAIL), '$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''') AS TOTAL_HONORARIOS
    
FROM (
    SELECT 
        p.id_profesional AS ID,
        p.appaterno ||' '|| p.apmaterno ||' '|| p.nombre AS PROFESIONAL,
        COUNT(*) AS NRO_ASESORIA_BANCA,
        SUM(a.honorario) AS MONTO_TOTAL_BANCA,
        0 AS NRO_ASESORIA_RETAIL,
        0 AS MONTO_TOTAL_RETAIL
    FROM profesional p 
        JOIN asesoria a ON p.id_profesional = a.id_profesional
        JOIN empresa e ON a.cod_empresa = e.cod_empresa
        JOIN sector s ON s.cod_sector = e.cod_sector
    WHERE s.cod_sector = 3
    GROUP BY 
        p.id_profesional, 
        p.appaterno ||' '|| p.apmaterno ||' '|| p.nombre

    UNION ALL

    SELECT 
        p.id_profesional AS ID,
        p.appaterno ||' '|| p.apmaterno ||' '|| p.nombre AS PROFESIONAL,
        0 AS NRO_ASESORIA_BANCA,
        0 AS MONTO_TOTAL_BANCA,
        COUNT(*) AS NRO_ASESORIA_RETAIL,
        SUM(a.honorario) AS MONTO_TOTAL_RETAIL
    FROM profesional p 
        JOIN asesoria a ON p.id_profesional = a.id_profesional
        JOIN empresa e ON a.cod_empresa = e.cod_empresa
        JOIN sector s ON s.cod_sector = e.cod_sector
    WHERE s.cod_sector = 4
    GROUP BY 
        p.id_profesional, 
        p.appaterno ||' '|| p.apmaterno ||' '|| p.nombre
)
GROUP BY
    ID,
    PROFESIONAL
ORDER BY ID ASC

-- caso 2
-- al ejecutar el este script lanza un error cuando la tabla no existe pero termina la ejecucion
-- correctamente, no se puede usar IF EXISTS.

DROP TABLE REPORTE_MES;
CREATE TABLE REPORTE_MES AS
SELECT 
    p.id_profesional AS ID_PROF,
    p.appaterno ||' '|| p.apmaterno ||' '|| p.nombre AS NOMBRE_COMPLETO,
    pp.nombre_profesion AS NOMBRE_PROFESION,
    c.nom_comuna AS NOM_COMUNA,
    COUNT(a.id_profesional) AS NRO_ASESORIAS,
    SUM(a.honorario) AS MONTO_TOTAL_HONORARIOS,
    ROUND(SUM(a.honorario) / COUNT(a.id_profesional)) AS PROMEDIO_HONORARIO,
    MIN(a.honorario) AS HONORARIO_MINIMO,
    MAX(a.honorario) AS HONORARIO_MAXIMO
    
FROM profesional p
    JOIN profesion pp ON p.cod_profesion = pp.cod_profesion
    JOIN comuna c ON p.cod_comuna = c.cod_comuna
    JOIN asesoria a ON a.id_profesional = p.id_profesional
WHERE   
    (EXTRACT(MONTH FROM a.fin_asesoria) = 4
    AND EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1)
GROUP BY
    p.id_profesional,
    p.appaterno ||' '|| p.apmaterno ||' '|| p.nombre,
    pp.nombre_profesion,
    c.nom_comuna
ORDER BY 
    ID_PROF ASC;
    
-- caso 3

SELECT
    SUM(a.honorario) AS HONORARIO,
    p.id_profesional AS ID_PROFESIONAL,
    p.numrun_prof AS NUMRUN_PROF,
    p.sueldo AS SUELDO
FROM profesional p
    JOIN asesoria a ON p.id_profesional = a.id_profesional
WHERE
    (EXTRACT(MONTH FROM a.fin_asesoria) = 3
    AND EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1)
GROUP BY
    p.id_profesional,
    p.numrun_prof,
    p.sueldo
ORDER BY ID_PROFESIONAL ASC;

UPDATE (
    SELECT 
        p.sueldo, 
        t.honorario_total
    FROM profesional p
    JOIN
    (
        SELECT 
            SUM(a.honorario) AS honorario_total,
            id_profesional
        FROM asesoria a
        WHERE
            (EXTRACT(MONTH FROM a.fin_asesoria) = 3
            AND EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1)
        GROUP BY
            id_profesional
    ) t
    ON t.id_profesional = p.id_profesional
)
SET sueldo =
    CASE
        WHEN honorario_total < 1000000 THEN sueldo * 1.10
        ELSE sueldo * 1.15
    END;

COMMIT;

SELECT
    SUM(a.honorario) AS HONORARIO,
    p.id_profesional AS ID_PROFESIONAL,
    p.numrun_prof AS NUMRUN_PROF,
    p.sueldo AS SUELDO
FROM profesional p
    JOIN asesoria a ON p.id_profesional = a.id_profesional
WHERE
    (EXTRACT(MONTH FROM a.fin_asesoria) = 3
    AND EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1)
GROUP BY
    p.id_profesional,
    p.numrun_prof,
    p.sueldo
ORDER BY ID_PROFESIONAL ASC;
