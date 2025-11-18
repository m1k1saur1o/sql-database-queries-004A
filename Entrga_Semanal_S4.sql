-- caso 1

SELECT 
    t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno AS "Nombre Completo Trabajador",
    CASE
        WHEN LENGTH(t.numrut) = 7 THEN TO_CHAR(t.numrut, '9G999G999', 'NLS_NUMERIC_CHARACTERS='',.''' ) || '-' || t.dvrut
        WHEN LENGTH(t.numrut) = 8 THEN TO_CHAR(t.numrut, '99G999G999', 'NLS_NUMERIC_CHARACTERS='',.''' ) || '-' || t.dvrut
        WHEN LENGTH(t.numrut) = 9 THEN TO_CHAR(t.numrut, '999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''' ) || '-' || t.dvrut
    END AS "RUT Trabajador",
    tp.desc_categoria AS "Tipo Trabajador",
    cc.nombre_ciudad AS "Ciudad Trabajador",
    TO_CHAR(t.sueldo_base, '$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''' ) AS "Sueldo Base"  
FROM trabajador t 
    LEFT JOIN tipo_trabajador tp ON t.id_categoria_t = tp.id_categoria
    LEFT JOIN comuna_ciudad cc  ON t.id_ciudad = cc.id_ciudad
WHERE t.sueldo_base BETWEEN 650000 AND 3000000
ORDER BY "Ciudad Trabajador" DESC, "Sueldo Base" ASC

-- caso 2

SELECT
    CASE
        WHEN LENGTH(t.numrut) = 7 THEN TO_CHAR(t.numrut, '9G999G999', 'NLS_NUMERIC_CHARACTERS='',.''' ) || '-' || t.dvrut
        WHEN LENGTH(t.numrut) = 8 THEN TO_CHAR(t.numrut, '99G999G999', 'NLS_NUMERIC_CHARACTERS='',.''' ) || '-' || t.dvrut
        WHEN LENGTH(t.numrut) = 9 THEN TO_CHAR(t.numrut, '999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''' ) || '-' || t.dvrut
    END AS "RUT Trabajador",
    INITCAP(t.nombre) || ' ' || t.appaterno AS "Nombre Trabajador",
    COUNT(tc.nro_ticket) AS "Total Tickets",
    TO_CHAR(SUM(tc.monto_ticket), '$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''' ) AS "Total Vendido",
    TO_CHAR(SUM(ct.valor_comision), '$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''' ) AS "Comisión Total",
    tt.desc_categoria AS "Tipo Trabajador",
    UPPER(cc.nombre_ciudad) AS "Ciudad Trabajador"
FROM trabajador t
    LEFT JOIN tipo_trabajador tt ON t.id_categoria_t = tt.id_categoria
    LEFT JOIN comuna_ciudad cc ON t.id_ciudad = cc.id_ciudad
    LEFT JOIN tickets_concierto tc ON t.numrut = tc.numrut_t
    LEFT JOIN comisiones_ticket ct ON tc.nro_ticket = ct.nro_ticket
WHERE tt.desc_categoria = 'CAJERO'
GROUP BY 
    CASE
        WHEN LENGTH(t.numrut) = 7 THEN TO_CHAR(t.numrut, '9G999G999', 'NLS_NUMERIC_CHARACTERS='',.''' ) || '-' || t.dvrut
        WHEN LENGTH(t.numrut) = 8 THEN TO_CHAR(t.numrut, '99G999G999', 'NLS_NUMERIC_CHARACTERS='',.''' ) || '-' || t.dvrut
        WHEN LENGTH(t.numrut) = 9 THEN TO_CHAR(t.numrut, '999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''' ) || '-' || t.dvrut
    END,
    INITCAP(t.nombre) || ' ' || t.appaterno,
    tt.desc_categoria,
    cc.nombre_ciudad
HAVING COUNT(tc.nro_ticket) > 0
ORDER BY "Total Vendido" DESC

-- caso 3

SELECT
    CASE
        WHEN LENGTH(t.numrut) = 7 
            THEN TO_CHAR(t.numrut, '9G999G999', 'NLS_NUMERIC_CHARACTERS='',.''' ) || '-' || t.dvrut
        WHEN LENGTH(t.numrut) = 8 
            THEN TO_CHAR(t.numrut, '99G999G999', 'NLS_NUMERIC_CHARACTERS='',.''' ) || '-' || t.dvrut
        WHEN LENGTH(t.numrut) = 9 
            THEN TO_CHAR(t.numrut, '999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''' ) || '-' || t.dvrut
    END AS "RUT Trabajador",
    INITCAP(t.nombre) || ' ' || INITCAP(t.appaterno) AS "Trabajador Nombre",
    EXTRACT(YEAR FROM t.fecing) AS "Año Ingreso",
    FLOOR(MONTHS_BETWEEN(SYSDATE, t.fecing) / 12) AS "Años Antigüedad",
    COUNT(af.numrut_t) AS "Num. Cargas Familiares",
    LPAD(INITCAP(isa.nombre_isapre), 15) AS "Nombre Isapre",
    TO_CHAR(t.sueldo_base, '$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''' ) AS "Sueldo Base",
    CASE 
        WHEN isa.nombre_isapre = 'FONASA' 
            THEN TO_CHAR(t.sueldo_base * 0.01, '$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''' )
        ELSE TO_CHAR(0, '999G999G999')
    END AS "Bono Fonasa",
    CASE
        WHEN (MONTHS_BETWEEN(SYSDATE, t.fecing) / 12) < 11 
            THEN TO_CHAR(t.sueldo_base * 0.1, '$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''' )
        WHEN (MONTHS_BETWEEN(SYSDATE, t.fecing) / 12) > 10
            THEN TO_CHAR(t.sueldo_base * 0.15, '$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''' )
    END AS "Bono Antigüedad",
    LPAD(INITCAP(afp.nombre_afp), 15) AS "Nombre AFP",
    LPAD(UPPER(ecd.desc_estcivil), 15) AS "Estado Civil"
FROM trabajador t
    LEFT JOIN asignacion_familiar af ON t.numrut = af.numrut_t
    LEFT JOIN isapre isa ON t.cod_isapre = isa.cod_isapre
    LEFT JOIN afp ON t.cod_afp = afp.cod_afp
    LEFT JOIN est_civil ec ON t.numrut = ec.numrut_t
    LEFT JOIN estado_civil ecd ON ec.id_estcivil_est = ecd.id_estcivil
WHERE ec.fecter_estcivil IS NULL OR ec.fecter_estcivil > TRUNC(SYSDATE)
GROUP BY
    CASE
        WHEN LENGTH(t.numrut) = 7 THEN TO_CHAR(t.numrut, '9G999G999', 'NLS_NUMERIC_CHARACTERS='',.''' ) || '-' || t.dvrut
        WHEN LENGTH(t.numrut) = 8 THEN TO_CHAR(t.numrut, '99G999G999', 'NLS_NUMERIC_CHARACTERS='',.''' ) || '-' || t.dvrut
        WHEN LENGTH(t.numrut) = 9 THEN TO_CHAR(t.numrut, '999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''' ) || '-' || t.dvrut
    END,
    INITCAP(t.nombre) || ' ' || INITCAP(t.appaterno),
    t.fecing,
    isa.nombre_isapre,
    t.sueldo_base,
    afp.nombre_afp,
    ecd.desc_estcivil
ORDER BY "RUT Trabajador" ASC
