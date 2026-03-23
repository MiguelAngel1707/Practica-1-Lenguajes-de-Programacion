# Sistema de Registro Universitario (Prolog y Haskell) - Practica 1

**Estudiante:** Miguelangel Calderón Figueredo 
**Materia:** ST0244 - Lenguajes de programación
**Profesor:** Alexander Narváez 
**Universidad:** Eafit
**Fecha:** Marzo 2026

## Descripción del Proyecto
Este proyecto consiste en un sistema interactivo de registro de entradas y salidas de estudiantes universitarios, implementado en dos paradigmas de programación distintos:
1. **Programación Lógica:** Usando prolog (`reg_prolog.pl`).
2. **Programación Funcional:** Usando Haskell (`reg_haskell.hs`).

Ambos sistemas leen y escriben sobre una misma base de datos (`University.txt`) y ofrecen las mismas funcionalidades.

## Funcionalidades Principales
- **Registrar entrada:** Permite registrar un estudiante. Si el ID ya existe, reutiliza su nombre de manera inteligente. Soporta uso del reloj del sistema o ingreso manual (HH:MM).
- **Buscar por ID:** Despliega el historial completo de visitas de un estudiante específico.
- **Calcular tiempo de permanencia:** Calcula el tiempo total por visita y el tiempo total acumulado de todas las visitas del estudiante.
- **Listar estudiantes:** Muestra una lista por estudiante con sus respectivas visitas y contabiliza los registros únicos de estos.
- **Registrar salida:** Registra la salida calculando el fin del periodo de permanencia. Igual que en el registro de entrada, soporta tiempo automático del sistema o manual.
