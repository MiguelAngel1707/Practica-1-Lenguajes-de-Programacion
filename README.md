#  Sistema de Registro Universitario - Práctica 1 

**ST0244 Lenguajes de Programación**

| Campo | Detalle |
|---|---|
| **Estudiante** | Miguelangel Calderón Figueredo |
| **Materia** | ST0244 — Lenguajes de Programación |
| **Profesor** | Alexander Narváez |
| **Universidad** | Universidad EAFIT |
| **Fecha** | Marzo 2026 |

---

## 📋 Descripción

Sistema interactivo de registro de entradas y salidas de estudiantes universitarios, implementado en **dos paradigmas de programación** distintos para contrastar sus enfoques y capacidades:

| Paradigma | Lenguaje | Archivo |
|---|---|---|
| Programación Lógica | Prolog | `reg_prolog.pl` |
| Programación Funcional | Haskell | `reg_haskell.hs` |

Ambas implementaciones comparten la misma base de datos (`University.txt`) y exponen exactamente las mismas funcionalidades, lo que permite una comparación directa entre paradigmas.

---

## 🗂️ Estructura del Proyecto

```
.
├── reg_prolog.pl       # Implementación en Prolog  (261 líneas)
├── reg_haskell.hs      # Implementación en Haskell (309 líneas)
└── University.txt      # Base de datos compartida
```

---

## ⚙️ Funcionalidades

Al iniciar, el sistema carga automáticamente los registros existentes de `University.txt` e informa cuántos fueron encontrados. Luego presenta el siguiente menú interactivo:

```
SISTEMA DE REGISTRO DE ENTRADA Y SALIDA DE ESTUDIANTES
  1. Registrar entrada
  2. Buscar estudiante por ID
  3. Calcular tiempo de permanencia
  4. Listar estudiantes
  5. Registrar salida
  6. Salir
```

### 1. Registrar Entrada
Registra el ingreso de un estudiante al campus.
- Si el ID ya existe en la base de datos, **reutiliza el nombre automáticamente** sin pedirlo de nuevo.
- Si el estudiante ya tiene una entrada activa (sin salida registrada), **bloquea el registro** y solicita registrar la salida primero.
- La hora puede ingresarse manualmente en formato `HH:MM` o presionar **Enter** para usar la **hora actual del sistema**.

### 2. Buscar por ID
Despliega el historial completo de un estudiante, mostrando por cada visita: hora de entrada, hora de salida (o estado *"Dentro de la universidad"* si aún no salió), y duración de la visita.

### 3. Calcular Tiempo de Permanencia
Para un estudiante específico calcula y muestra:
- Duración de **cada visita individual**.
- **Tiempo total acumulado** de todas sus visitas cerradas.

### 4. Listar Estudiantes
Muestra todos los estudiantes registrados agrupados por ID, con sus visitas detalladas. Al final reporta el total de registros y el total de estudiantes únicos.

### 5. Registrar Salida
Cierra la visita activa de un estudiante.
- Busca la entrada más reciente **sin salida** para ese ID.
- Al igual que la entrada, acepta hora manual (`HH:MM`) o **Enter** para hora actual del sistema.
- Si el estudiante no existe o ya registró salida, notifica sin modificar la base de datos.

---

## 🗃️ Formato de la Base de Datos

El archivo `University.txt` almacena los registros en texto plano CSV. Cada línea representa una visita:

```
<ID>,<Nombre>,<HoraEntrada>,<HoraSalida>
```

| Campo | Descripción | Ejemplo |
|---|---|---|
| `ID` | Identificador del estudiante | `123456` |
| `Nombre` | Nombre completo | `Juan Perez` |
| `HoraEntrada` | Hora en formato `HH:MM` | `08:30` |
| `HoraSalida` | Hora de salida, o `---` si aún está dentro | `10:45` / `---` |

**Ejemplo real del archivo:**
```
123456,Juan Perez,21:09,21:13
```

> Un mismo estudiante puede tener múltiples líneas (una por visita). El sistema las agrupa por ID al momento de consultar.

---

## 🚀 Cómo Ejecutar

### Prerrequisitos

| Herramienta | Versión recomendada | Descarga |
|---|---|---|
| SWI-Prolog | ≥ 8.x | [swi-prolog.org](https://www.swi-prolog.org/) |
| GHC (Haskell) | ≥ 9.x | [haskell.org/ghc](https://www.haskell.org/ghc/) |

Asegúrese de que `University.txt` esté en el mismo directorio que los archivos fuente. Puede estar vacío; el sistema lo lee sin problema.

---

### Prolog

```bash
# La directiva :- initialization(main, main) ejecuta el sistema automáticamente al cargar
swipl reg_prolog.pl
```

**Detalles de implementación:**
- Usa el predicado dinámico `estudiante/4` → `(ID, Nombre, EntradaMinutos, SalidaMinutos)`
- Representa "sin salida" con el valor centinela `-1`
- Persiste los cambios reescribiendo todo el archivo tras cada operación de escritura

---

### Haskell

```bash
# Compilar
ghc -o reg_haskell reg_haskell.hs

# Ejecutar
./reg_haskell
```

**Detalles de implementación:**
- Define el tipo `data Estudiante { idEstudiante, nombre, horaEntrada :: Int, horaSalida :: Maybe Int }`
- Representa "sin salida" con `Nothing` (tipo `Maybe Int`)
- El estado de la lista se propaga funcionalmente a través del bucle principal usando `>>=`
- Usa `Data.Time.Clock` y `Data.Time.LocalTime` para obtener la hora local del sistema

---

## 🧠 Comparativa de Paradigmas

| Aspecto | Prolog (Lógico) | Haskell (Funcional) |
|---|---|---|
| **Modelo de datos** | Hecho dinámico `estudiante/4` | `data Estudiante` con campos tipados |
| **"Sin salida"** | Valor centinela `-1` | `Maybe Int` → `Nothing` |
| **Estado** | Base de conocimiento con `assert`/`retract` | Lista inmutable pasada recursivamente |
| **I/O** | Predicados con efectos directos | Mónada `IO` explícita |
| **Bucle del menú** | Recursión de cola con `menu/0` | `bucle :: [Estudiante] -> IO ()` + `>>=` |
| **Persistencia** | `forall` sobre hechos → `format/3` | `map estudianteALinea` + `writeFile` |
| **Hora del sistema** | `get_time/1` + `stamp_date_time/3` | `getCurrentTime` + `utcToLocalZonedTime` |

---

## 📝 Notas

- Ambas implementaciones **reescriben `University.txt` completo** tras cada operación; no hacen append incremental.
- El tiempo se maneja internamente en **minutos desde medianoche** (entero) y se convierte a `HH:MM` solo para mostrarse y persistirse.
- Para limpiar la base de datos y empezar de cero, basta con vaciar `University.txt`.
