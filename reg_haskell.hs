module Main where

import Data.List (find, intercalate, nub)
import System.IO (hFlush, stdout, hSetBuffering, BufferMode(..))
import Control.Exception (catch, IOException)
import Data.Time.Clock (getCurrentTime)
import Data.Time.LocalTime (utcToLocalZonedTime, zonedTimeToLocalTime, localTimeOfDay, todHour, todMin)


data Estudiante = Estudiante
  { idEstudiante :: String
  , nombre :: String
  , horaEntrada :: Int
  , horaSalida :: Maybe Int
  } deriving (Show)

archivoTxt :: FilePath
archivoTxt = "University.txt"

-- CONVERSIONES DE TIEMPO

horaAMinutos :: String -> Int
horaAMinutos hora =
  let (h, resto) = break (== ':') hora
      m = drop 1 resto
  in read h * 60 + read m

minutosAHora :: Int -> String
minutosAHora mins =
  let h = mins `div` 60
      m = mins `mod` 60
      dosDigitos n = (if n < 10 then "0" else "") ++ show n
  in dosDigitos h ++ ":" ++ dosDigitos m

-- OBTENER HORA

obtenerHora :: String -> IO (Int, String)
obtenerHora mensaje = do
  putStr mensaje
  hFlush stdout
  entradaStr <- getLine
  if null entradaStr
    then do
      tiempoUtc <- getCurrentTime
      zonaLocal <- utcToLocalZonedTime tiempoUtc
      let tiempoLocal = zonedTimeToLocalTime zonaLocal
          horaDelDia = localTimeOfDay tiempoLocal
          h = todHour horaDelDia
          m = todMin horaDelDia
          mins = h * 60 + m
      return (mins, minutosAHora mins)
    else return (horaAMinutos entradaStr, entradaStr)

-- PARSEO DE ARCHIVO

dividir :: Char -> String -> [String]
dividir _ "" = [""]
dividir sep str = foldr f [""] str
  where
    f c (x:xs)
      | c == sep  = "" : x : xs
      | otherwise = (c : x) : xs
    f _ [] = []

lineaAEstudiante :: String -> Maybe Estudiante
lineaAEstudiante linea =
  case dividir ',' linea of
    [id', nom, ent, sal] -> Just $ Estudiante
      { idEstudiante = id'
      , nombre       = nom
      , horaEntrada  = horaAMinutos ent
      , horaSalida   = if sal == "---"
                         then Nothing
                         else Just (horaAMinutos sal)
      }
    _ -> Nothing

estudianteALinea :: Estudiante -> String
estudianteALinea e =
  intercalate ","
    [ idEstudiante e
    , nombre e
    , minutosAHora (horaEntrada e)
    , case horaSalida e of
        Nothing -> "---"
        Just m  -> minutosAHora m
    ]

-- PERSISTENCIA

cargarEstudiantes :: IO [Estudiante]
cargarEstudiantes = do
  contenido <- readFile archivoTxt `catch` manejarError
  let lineas = filter (not . null) (lines contenido)
  return $ foldr agregarValido [] lineas
  where
    manejarError :: IOException -> IO String
    manejarError _ = return ""
    agregarValido linea acc =
      case lineaAEstudiante linea of
        Just e  -> e : acc
        Nothing -> acc

guardarEstudiantes :: [Estudiante] -> IO ()
guardarEstudiantes estudiantes =
  writeFile archivoTxt (unlines (map estudianteALinea estudiantes))

-- HELPERS

buscarTodos :: String -> [Estudiante] -> [Estudiante]
buscarTodos id' = filter (\e -> idEstudiante e == id')

buscarSinSalida :: String -> [Estudiante] -> Maybe Estudiante
buscarSinSalida id' = find (\e -> idEstudiante e == id' && horaSalida e == Nothing)

obtenerNombre :: String -> [Estudiante] -> Maybe String
obtenerNombre id' ests =
  case find (\e -> idEstudiante e == id') ests of
    Just e  -> Just (nombre e)
    Nothing -> Nothing

-- MENU

mostrarMenu :: IO ()
mostrarMenu = do
  putStrLn ""
  putStrLn "SISTEMA DE REGISTRO DE ENTRADA Y SALIDA DE ESTUDIANTES"
  putStrLn "  1. Registrar entrada"
  putStrLn "  2. Buscar estudiante por ID"
  putStrLn "  3. Calcular tiempo de permanencia"
  putStrLn "  4. Listar estudiantes"
  putStrLn "  5. Registrar salida"
  putStrLn "  6. Salir"
  putStr   "  Seleccione una opcion: "
  hFlush stdout

-- 1. REGISTRAR ENTRADA

registrarEntrada :: [Estudiante] -> IO [Estudiante]
registrarEntrada estudiantes = do
  putStr "  ID del estudiante: "; hFlush stdout; id' <- getLine
  case buscarSinSalida id' estudiantes of
    Just _ -> do
      putStrLn "    Este estudiante ya tiene una entrada sin salida."
      putStrLn "      Primero registre la salida antes de una nueva entrada."
      return estudiantes
    Nothing -> do
      nom <- case obtenerNombre id' estudiantes of
        Just n  -> do
          putStrLn $ "  Nombre (existente): " ++ n
          return n
        Nothing -> do
          putStr "  Nombre: "; hFlush stdout; getLine
      
      (mins, horaStr) <- obtenerHora "  Hora entrada (HH:MM) [Enter=Hora Actual]: "
      
      let nuevoEstudiante = Estudiante
            { idEstudiante = id'
            , nombre = nom
            , horaEntrada = mins
            , horaSalida = Nothing
            }
      let nuevaLista = estudiantes ++ [nuevoEstudiante]
      guardarEstudiantes nuevaLista
      putStrLn $ "    Entrada de " ++ nom ++ " registrada a las " ++ horaStr
      return nuevaLista

-- 2. BUSCAR POR ID

buscarPorId :: [Estudiante] -> IO ()
buscarPorId estudiantes = do
  putStr "  ID a buscar: "; hFlush stdout; id' <- getLine
  let registros = buscarTodos id' estudiantes
  case registros of
    [] -> putStrLn "    Estudiante no encontrado."
    (primer:_) -> do
      putStrLn "  =================================="
      putStrLn $ "  ID: " ++ id'
      putStrLn $ "  Nombre: " ++ nombre primer
      putStrLn $ "  Total de visitas: " ++ show (length registros)
      putStrLn "  ----------------------------------"
      mostrarVisitas registros 1
      putStrLn "  =================================="

mostrarVisitas :: [Estudiante] -> Int -> IO ()
mostrarVisitas [] _ = return ()
mostrarVisitas (e:resto) n = do
  putStrLn $ "  Visita #" ++ show n
  putStrLn $ "    Entrada: " ++ minutosAHora (horaEntrada e)
  case horaSalida e of
    Nothing -> putStrLn "    Estado: Dentro de la universidad"
    Just ms -> do
      putStrLn $ "    Salida: " ++ minutosAHora ms
      let diff = ms - horaEntrada e
          h    = diff `div` 60
          m    = diff `mod` 60
      putStrLn $ "    Tiempo: " ++ show h ++ " hora(s) y " ++ show m ++ " minuto(s)"
  mostrarVisitas resto (n + 1)


-- 3. CALCULAR TIEMPO DE PERMANENCIA 

calcularTiempo :: [Estudiante] -> IO ()
calcularTiempo estudiantes = do
  putStr "  ID del estudiante: "; hFlush stdout; id' <- getLine
  let registros = buscarTodos id' estudiantes
  case registros of
    [] -> putStrLn "    Estudiante no encontrado."
    (primer:_) -> do
      putStrLn $ "  Tiempo de permanencia de " ++ nombre primer ++ ":"
      putStrLn "  ----------------------------------"
      totalMin <- calcularCadaVisita registros 1 0
      putStrLn "  ----------------------------------"
      let th = totalMin `div` 60
          tm = totalMin `mod` 60
      putStrLn $ "  TOTAL ACUMULADO: " ++ show th ++ " hora(s) y " ++ show tm ++ " minuto(s)"

calcularCadaVisita :: [Estudiante] -> Int -> Int -> IO Int
calcularCadaVisita [] _ acum = return acum
calcularCadaVisita (e:resto) n acum = do
  let entStr = minutosAHora (horaEntrada e)
  case horaSalida e of
    Nothing -> do
      putStrLn $ "  Visita #" ++ show n ++ " (" ++ entStr ++ " -> ---): Aun dentro"
      calcularCadaVisita resto (n + 1) acum
    Just ms -> do
      let salStr = minutosAHora ms
          diff   = ms - horaEntrada e
          h      = diff `div` 60
          m      = diff `mod` 60
      putStrLn $ "  Visita #" ++ show n ++ " (" ++ entStr ++ " -> " ++ salStr ++ "): "
                 ++ show h ++ " hora(s) y " ++ show m ++ " minuto(s)"
      calcularCadaVisita resto (n + 1) (acum + diff)

-- 4. LISTAR ESTUDIANTES

listarEstudiantes :: IO ()
listarEstudiantes = do
  estudiantes <- cargarEstudiantes
  case estudiantes of
    [] -> putStrLn "    No hay estudiantes registrados en el archivo."
    _  -> do
      putStrLn "\n  --- Lista de Estudiantes ---"
      let idsUnicos = nub (map idEstudiante estudiantes)
      mapM_ (mostrarGrupo estudiantes) idsUnicos
      putStrLn $ "  Total de registros: " ++ show (length estudiantes)
      putStrLn $ "  Total de estudiantes unicos: " ++ show (length idsUnicos)

mostrarGrupo :: [Estudiante] -> String -> IO ()
mostrarGrupo estudiantes id' = do
  let visitas = buscarTodos id' estudiantes
  case visitas of
    [] -> return ()
    (primer:_) -> do
      putStrLn $ "  [" ++ id' ++ "] " ++ nombre primer
                 ++ " (" ++ show (length visitas) ++ " visita(s))"
      mapM_ mostrarVisitaSimple visitas

mostrarVisitaSimple :: Estudiante -> IO ()
mostrarVisitaSimple e = do
  let salStr = case horaSalida e of
                 Nothing -> "---"
                 Just m  -> minutosAHora m
  putStrLn $ "         Entrada: " ++ minutosAHora (horaEntrada e)
             ++ " | Salida: " ++ salStr

-- 5. REGISTRAR SALIDA

registrarSalida :: [Estudiante] -> IO [Estudiante]
registrarSalida estudiantes = do
  putStr "  ID del estudiante: "; hFlush stdout; id' <- getLine
  case buscarSinSalida id' estudiantes of
    Nothing -> do
      putStrLn "    Estudiante no encontrado o ya registro salida."
      return estudiantes
    Just _ -> do
      (mins, _) <- obtenerHora "  Hora salida  (HH:MM) [Enter=Hora Actual]: "
      let actualizada = map (\e ->
                if idEstudiante e == id' && horaSalida e == Nothing
                  then e { horaSalida = Just mins }
                  else e) estudiantes
      guardarEstudiantes actualizada
      putStrLn "    Salida registrada exitosamente."
      return actualizada

-- BUCLE PRINCIPAL

bucle :: [Estudiante] -> IO ()
bucle estudiantes = do
  mostrarMenu
  opcion <- getLine
  case opcion of
    "1" -> registrarEntrada estudiantes >>= bucle
    "2" -> buscarPorId estudiantes >> bucle estudiantes
    "3" -> calcularTiempo estudiantes >> bucle estudiantes
    "4" -> listarEstudiantes >> bucle estudiantes
    "5" -> registrarSalida estudiantes >>= bucle
    "6" -> putStrLn "  Nos vemos pronto"
    _   -> putStrLn "  Opcion no valida. Intenta nuevamente..." >> bucle estudiantes

-- MAIN 

main :: IO ()
main = do
  hSetBuffering stdout NoBuffering
  putStrLn "Cargando datos desde University.txt..."
  estudiantes <- cargarEstudiantes
  putStrLn $ "Se cargaron " ++ show (length estudiantes) ++ " registro(s)."
  bucle estudiantes
