:- dynamic estudiante/4.

archivo('University.txt').

:- initialization(main, main).

main :-
    writeln('Cargando datos desde University.txt...'),
    cargar_estudiantes,
    findall(_, estudiante(_, _, _, _), Lista),
    length(Lista, Total),
    format('Se cargaron ~w registro(s).~n', [Total]),
    menu.

menu :-
    nl,
    writeln('SISTEMA DE REGISTRO DE ENTRADA Y SALIDA DE ESTUDIANTES'),
    writeln('  1. Registrar entrada'),
    writeln('  2. Buscar estudiante por ID'),
    writeln('  3. Calcular tiempo de permanencia'),
    writeln('  4. Listar estudiantes'),
    writeln('  5. Registrar salida'),
    writeln('  6. Salir'),
    write('  Seleccione una opcion: '),
    read_line_to_string(user_input, Opcion),
    manejar_opcion(Opcion).

manejar_opcion("1") :- !, registrar_entrada,   menu.
manejar_opcion("2") :- !, buscar_por_id,        menu.
manejar_opcion("3") :- !, calcular_tiempo,      menu.
manejar_opcion("4") :- !, listar_estudiantes,   menu.
manejar_opcion("5") :- !, registrar_salida,     menu.
manejar_opcion("6") :- !, writeln('  Nos vemos pronto').
manejar_opcion(_)   :-    writeln('  Opcion no valida. Intenta nuevamente...'), menu.

hora_a_minutos(Hora, Minutos) :-
    split_string(Hora, ":", "", [H, M | _]),
    number_string(Horas, H),
    number_string(Mins,  M),
    Minutos is Horas * 60 + Mins.

minutos_a_hora(Minutos, Hora) :-
    H is Minutos // 60,
    M is Minutos mod 60,
    format(atom(Hora), '~`0t~d~2|:~`0t~d~2|', [H, M]).

% --- NUEVA FUNCION: Obtener hora actual en minutos o desde input ---

obtener_hora(Mensaje, MinutosRetorno, HoraStrRetorno) :-
    write(Mensaje), read_line_to_string(user_input, EntradaStr),
    (   EntradaStr == ""
    ->  get_time(Stamp),
        stamp_date_time(Stamp, DateTime, local),
        date_time_value(hour, DateTime, H),
        date_time_value(minute, DateTime, M),
        MinutosRetorno is H * 60 + M,
        minutos_a_hora(MinutosRetorno, HoraStrRetorno)
    ;   hora_a_minutos(EntradaStr, MinutosRetorno),
        HoraStrRetorno = EntradaStr
    ).

cargar_estudiantes :-
    archivo(Archivo),
    (   exists_file(Archivo)
    ->  setup_call_cleanup(
            open(Archivo, read, Stream),
            leer_estudiantes(Stream),
            close(Stream)
        )
    ;   true
    ).

leer_estudiantes(Stream) :-
    read_line_to_string(Stream, Linea),
    (   Linea == end_of_file
    ->  true
    ;   (   Linea \= ""
        ->  parsear_linea(Linea)
        ;   true
        ),
        leer_estudiantes(Stream)
    ).

parsear_linea(Linea) :-
    split_string(Linea, ",", "", [ID, Nombre, EntradaStr, SalidaStr]),
    hora_a_minutos(EntradaStr, Entrada),
    (   SalidaStr = "---"
    ->  Salida = -1
    ;   hora_a_minutos(SalidaStr, Salida)
    ),
    assertz(estudiante(ID, Nombre, Entrada, Salida)).

guardar_estudiantes :-
    archivo(Archivo),
    setup_call_cleanup(
        open(Archivo, write, Stream),
        escribir_estudiantes(Stream),
        close(Stream)
    ).

escribir_estudiantes(Stream) :-
    forall(
        estudiante(ID, Nombre, Entrada, Salida),
        (
            minutos_a_hora(Entrada, EntradaStr),
            (   Salida =:= -1
            ->  SalidaStr = '---'
            ;   minutos_a_hora(Salida, SalidaStr)
            ),
            format(Stream, '~w,~w,~w,~w~n', [ID, Nombre, EntradaStr, SalidaStr])
        )
    ).

% --- REGISTRAR ENTRADA (Maneja hora actual o manual) ---

registrar_entrada :-
    write('  ID del estudiante: '), read_line_to_string(user_input, ID),
    (   estudiante(ID, NombreExistente, _, _)
    ->  Nombre = NombreExistente,
        format('  Nombre (existente): ~w~n', [Nombre])
    ;   write('  Nombre: '), read_line_to_string(user_input, Nombre)
    ),
    (   estudiante(ID, _, _, -1)
    ->  writeln('    Este estudiante ya tiene una entrada sin salida.'),
        writeln('    Primero registre la salida antes de una nueva entrada.')
    ;   obtener_hora('  Hora entrada (HH:MM) [Enter=Hora Actual]: ', Minutos, HoraStr),
        assertz(estudiante(ID, Nombre, Minutos, -1)),
        guardar_estudiantes,
        format('     Entrada de ~w registrada a las ~w~n', [Nombre, HoraStr])
    ).

% --- BUSCAR POR ID ---

buscar_por_id :-
    write('  ID a buscar: '), read_line_to_string(user_input, ID),
    findall(
        registro(Nombre, Entrada, Salida),
        estudiante(ID, Nombre, Entrada, Salida),
        Registros
    ),
    (   Registros = []
    ->  writeln('    Estudiante no encontrado.')
    ;   Registros = [registro(NombreEst, _, _) | _],
        length(Registros, Total),
        writeln('  =================================='),
        format('  ID: ~w~n', [ID]),
        format('  Nombre: ~w~n', [NombreEst]),
        format('  Total de visitas: ~w~n', [Total]),
        writeln('  ----------------------------------'),
        mostrar_registros(Registros, 1),
        writeln('  ==================================')
    ).

mostrar_registros([], _).
mostrar_registros([registro(_, Entrada, Salida) | Resto], N) :-
    minutos_a_hora(Entrada, EntradaStr),
    format('  Visita #~w~n', [N]),
    format('    Entrada: ~w~n', [EntradaStr]),
    (   Salida =:= -1
    ->  writeln('    Estado: Dentro de la universidad')
    ;   minutos_a_hora(Salida, SalidaStr),
        format('    Salida: ~w~n', [SalidaStr]),
        Diff is Salida - Entrada,
        H is Diff // 60,
        M is Diff mod 60,
        format('    Tiempo: ~w hora(s) y ~w minuto(s)~n', [H, M])
    ),
    N1 is N + 1,
    mostrar_registros(Resto, N1).

% --- CALCULAR TIEMPO ---

calcular_tiempo :-
    write('  ID del estudiante: '), read_line_to_string(user_input, ID),
    findall(
        par(Entrada, Salida),
        estudiante(ID, _, Entrada, Salida),
        Registros
    ),
    (   Registros = []
    ->  writeln('    Estudiante no encontrado.')
    ;   estudiante(ID, Nombre, _, _),
        format('  Tiempo de permanencia de ~w:~n', [Nombre]),
        writeln('  ----------------------------------'),
        calcular_cada_visita(Registros, 1, 0, TotalMin),
        writeln('  ----------------------------------'),
        TH is TotalMin // 60,
        TM is TotalMin mod 60,
        format('  TOTAL ACUMULADO: ~w hora(s) y ~w minuto(s)~n', [TH, TM])
    ).

calcular_cada_visita([], _, Acum, Acum).
calcular_cada_visita([par(Entrada, Salida) | Resto], N, Acum, TotalMin) :-
    minutos_a_hora(Entrada, EntradaStr),
    (   Salida =:= -1
    ->  format('  Visita #~w (~w -> ---): Aun dentro~n', [N, EntradaStr]),
        NuevoAcum = Acum
    ;   minutos_a_hora(Salida, SalidaStr),
        Diff is Salida - Entrada,
        H is Diff // 60,
        M is Diff mod 60,
        format('  Visita #~w (~w -> ~w): ~w hora(s) y ~w minuto(s)~n',
               [N, EntradaStr, SalidaStr, H, M]),
        NuevoAcum is Acum + Diff
    ),
    N1 is N + 1,
    calcular_cada_visita(Resto, N1, NuevoAcum, TotalMin).

% --- LISTAR ESTUDIANTES ---

listar_estudiantes :-
    retractall(estudiante(_, _, _, _)),
    cargar_estudiantes,
    (   estudiante(_, _, _, _)
    ->  writeln('\n  --- Lista de Estudiantes ---'),
        findall(ID, estudiante(ID, _, _, _), IDsDup),
        sort(IDsDup, IDsUnicos),
        listar_por_id(IDsUnicos),
        findall(_, estudiante(_, _, _, _), Lista),
        length(Lista, Total),
        format('  Total de registros: ~w~n', [Total]),
        length(IDsUnicos, TotalEst),
        format('  Total de estudiantes unicos: ~w~n', [TotalEst])
    ;   writeln('  No hay estudiantes registrados.')
    ).

listar_por_id([]).
listar_por_id([ID | Resto]) :-
    estudiante(ID, Nombre, _, _), !,
    findall(
        par(Entrada, Salida),
        estudiante(ID, _, Entrada, Salida),
        Visitas
    ),
    length(Visitas, NumVisitas),
    format('  [~w] ~w (~w visita(s))~n', [ID, Nombre, NumVisitas]),
    forall(
        member(par(Entrada, Salida), Visitas),
        (
            minutos_a_hora(Entrada, EntradaStr),
            (   Salida =:= -1
            ->  SalidaStr = '---'
            ;   minutos_a_hora(Salida, SalidaStr)
            ),
            format('         Entrada: ~w | Salida: ~w~n', [EntradaStr, SalidaStr])
        )
    ),
    listar_por_id(Resto).

% --- REGISTRAR SALIDA (Maneja hora actual o manual) ---

registrar_salida :-
    write('  ID del estudiante: '), read_line_to_string(user_input, ID),
    (   estudiante(ID, Nombre, Entrada, -1)
    ->  obtener_hora('  Hora salida  (HH:MM) [Enter=Hora Actual]: ', Minutos, _),
        retract(estudiante(ID, Nombre, Entrada, -1)),
        assertz(estudiante(ID, Nombre, Entrada, Minutos)),
        guardar_estudiantes,
        writeln('     Salida registrada exitosamente.')
    ;   writeln('    Estudiante no encontrado o ya registro salida.')
    ).
