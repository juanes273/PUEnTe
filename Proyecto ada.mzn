% Parámetros
int: J; % Número de utpee
int: K; % Longitud del horizonte de planificación
array[1..J] of int: Ej; % Costo de encender la utpee j
array[1..J] of float: Aj; % Costo de apagar la utpee j
array[1..J] of int: Gj; % Indicador de si la planta j terminó generando energía en el horizonte previo
array[1..J] of int: Fj; % Costo fijo de operación de la utpee j
array[1..J] of float: Vj; % Coeficiente para calcular el costo variable de encender la utpee j
array[1..J] of int: Pj_lower; % Límite inferior de generación de potencia de la utpee j si está generando
array[1..J] of int: Pj_upper; % Límite superior de generación de potencia de la utpee j si está generando
array[1..J] of int: Supj; % Límite superior de ampliación de potencia para la utpee j
array[1..J] of int: Infj; % Límite inferior de reducción de potencia para la utpee j
array[1..J] of int: P0j; % Potencia generada por la utpee j justo antes de iniciar el horizonte de planificación
array[1..K] of int: Dk; % Demanda global de energía para el período k
array[1..K] of int: Rk; % Reserva especificada de energía para el período k

% Variables
array[1..J, 1..K] of var 0..max(Pj_upper): pjk; % Potencia generada por la utpee j en el período k

%Restricciones
% Nuevas variables binarias para el estado de encendido y apagado
array[1..J, 1..K] of var 0..1: encendida;
array[1..J] of var 0..1: inicial_encendida;


% Restricción de límites de generación de potencia
constraint forall(j in 1..J, k in 1..K) (
  Pj_lower[j] * encendida[j, k] <= pjk[j, k] /\ pjk[j, k] <= Pj_upper[j] * encendida[j, k]
);

% Restricción de igualdad entre generación y demanda
constraint forall(k in 1..K) (
  sum(j in 1..J) (encendida[j, k] * pjk[j, k]) = Dk[k]
);

% Restricción de límites de ampliación o reducción de potencia
constraint forall(j in 1..J, k in 2..K) (
  (encendida[j, k] = 1 /\ encendida[j, k - 1] = 1) -> (
    (pjk[j, k] >= pjk[j, k - 1] /\ pjk[j, k] - pjk[j, k - 1] <= Supj[j]) \/
    (pjk[j, k] < pjk[j, k - 1] /\ pjk[j, k - 1] - pjk[j, k] <= Infj[j])
  )
);

% Restricción para el primer periodo
constraint forall(j in 1..J) (
  encendida[j, 1] = 1 -> (
    (pjk[j, 1] >= P0j[j] /\ pjk[j, 1] - P0j[j] <= Supj[j]) \/
    (pjk[j, 1] < P0j[j] /\ P0j[j] - pjk[j, 1] <= Infj[j])
  )
);


% Restricción de reserva
constraint forall(k in 1..K) (
  sum(j in 1..J) (encendida[j, k] * Pj_upper[j]) >= Dk[k] + Rk[k]
);


% Variable para representar el costo total
var float: costo_total;

constraint costo_total>=0;

% Definición de la función objetivo ajustada
constraint costo_total = sum(j in 1..J, k in 1..K) (
  (encendida[j, k] * (Fj[j] + Vj[j] * pjk[j, k])) +
  (if k > 1 /\ encendida[j, k] = 1 /\ encendida[j, k - 1] = 0 then Ej[j] else 0 endif) +
  (if k > 1 /\ encendida[j, k] = 0 /\ encendida[j, k - 1] = 1 then Aj[j] else 0 endif)
);


% Minimizar la función objetivo
solve minimize costo_total;






