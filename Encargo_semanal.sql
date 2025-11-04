
-- 1
SELECT 
    f.numfactura AS "N° FACTURA",
    TO_CHAR(f.fecha, 'DD/MM/YYYY') AS "FECHA EMISIÓN",
    LPAD(f.rutcliente, 10, '0') AS "RUT CLIENTE",
    f.neto AS "MONTO NETO",
    f.iva AS "MONTO IVA",
    f.total AS "TOTAL FACTURA",
    
    CASE
        WHEN f.total BETWEEN 0 AND 50000 THEN 'BAJO'
        WHEN f.total BETWEEN 50001 AND 100000 THEN 'MEDIO'
        WHEN f.total > 100000 THEN 'ALTO'
        ELSE 'SIN CATEGORÍA'
    END AS "CATEGORIA MONTO",
    
    CASE f.codpago
        WHEN 1 THEN 'EFECTIVO'
        WHEN 2 THEN 'TARJETA DÉBITO'
        WHEN 3 THEN 'TARJETA CRÉDITO'
        ELSE 'CHEQUE'
    END AS "FORMA DE PAGO"
    
FROM factura f
WHERE EXTRACT(YEAR FROM f.fecha) = 2024
ORDER BY f.fecha DESC;

-- 2

SELECT 
    '*' || c.rutcliente AS "RUT",
    c.nombre AS "CLIENTE",
    NVL(TO_CHAR(c.telefono), 'Sin teléfono') AS "TELÉFONO",
    NVL(TO_CHAR(c.codcomuna), 'Sin comuna') AS "COMUNA",
    c.estado AS "ESTADO",

    CASE 
        WHEN c.saldo < (c.credito * 0.5) 
            THEN 'Bueno ($' || TO_CHAR(c.credito - c.saldo) || ')'
        WHEN c.saldo BETWEEN (c.credito * 0.5) AND (c.credito * 0.8)
            THEN 'Regular ($' || TO_CHAR(c.saldo) || ')'
        WHEN c.saldo > (c.credito * 0.8)
            THEN 'Crítico'
        ELSE 'Sin evaluación'
    END AS "ESTADO CRÉDITO",

    CASE 
        WHEN c.mail IS NULL 
            THEN 'Correo no registrado'
        ELSE SUBSTR(c.mail, INSTR(c.mail, '@') + 1)
    END AS "DOMINIO CORREO"

FROM cliente c
WHERE c.estado = 'A'
  AND c.credito > 0
ORDER BY c.nombre ASC;

-- 3

-- Variables de sustitución
DEFINE TIPOCAMBIO_DOLAR = 950
DEFINE UMBRAL_BAJO = 20
DEFINE UMBRAL_ALTO = 60

SELECT 
    p.codproducto AS "ID",
    p.descripcion AS "DESCRIPCIÓN DE PRODUCTO",
    p.valorcompradolar AS "COMPRA EN USD",
    p.valorcompradolar * &TIPOCAMBIO_DOLAR AS "USD CONVERTIDO",
    p.totalstock AS "STOCK",

    CASE 
        WHEN p.totalstock IS NULL 
            THEN 'Sin datos'
        WHEN p.totalstock < &UMBRAL_BAJO 
            THEN '¡ALERTA stock muy bajo!'
        WHEN p.totalstock BETWEEN &UMBRAL_BAJO AND &UMBRAL_ALTO 
            THEN '¡Reabastecer pronto!'
        WHEN p.totalstock > &UMBRAL_ALTO 
            THEN 'OK'
    END AS "ALERTA STOCK",

    CASE 
        WHEN p.totalstock > 80 
            THEN ROUND(p.vunitario * 0.9, 0) 
        ELSE 'N/A'
    END AS "PRECIO OFERTA"

FROM producto p
ORDER BY p.codproducto DESC;