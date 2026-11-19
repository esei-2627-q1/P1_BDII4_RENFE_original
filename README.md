# BDII4 :: RENFE — Práctica 1 (entrega original)

Bases de Datos II · ESEI (Universidade de Vigo) · Curso 2026/27
Equipo **BDII_4**: Alejandro Francisco Pérez Rodríguez, Mario Pérez González, Jacobo Montero Naranjo y Pablo Regueira Castaño.

> ⚠️ **Esta es la entrega original del 06/10/2026, que no se dio por buena.** Se guarda como histórico.
> La versión corregida es la **repesca del Entregable 1**, en el repositorio `bdii4-renfe-p1-repesca`, y es el esquema sobre el que se hacen la práctica de administración y la P3.

## Contenido

| Fichero | Qué es |
|---|---|
| `P1_EER_DDL_BDII_4_RENFE.pdf` | Memoria original (21 páginas): descripción, EER, paso a relacional, DDL y vistas |
| `RENFE.sql` | Script DDL original para Oracle (26 tablas, vistas y pruebas de restricciones) |

## Qué cambió en la repesca (resumen)

- Presentación de la memoria rehecha en LaTeX: el profesor criticó las tablas partidas, la falta de índice y la portada.
- Esquema revisado: se elimina la relación Pasajero–Viaje, que duplicaba la información del billete (la repesca tiene 28 tablas).
- Script reescrito para poder ejecutarse completo y repetido (`DROP ... IF EXISTS`), con las pruebas de restricciones al final.

Para el detalle, comparar con la memoria y el script de `bdii4-renfe-p1-repesca`.
