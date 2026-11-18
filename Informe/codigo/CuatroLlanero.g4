grammar CuatroLlanero;

ejecucion
    : golpe EOF
    ;

golpe
    : gaban
    | pajarillo
    | seisPorDerecho
    | zumbeYZumbe
    | tonada
    | contrapunteo
    ;

gaban
    : TONICA DOMINANTE DOMINANTE TONICA FRENAO
    ;

pajarillo
    : MENOR SUBDOM DOMINANTE MENOR FRENAO
    ;

seisPorDerecho
    : TONICA SUBDOM DOMINANTE TONICA FRENAO
    ;

zumbeYZumbe
    : SUBDOM DOMINANTE SUBDOM DOMINANTE FRENAO
    ;

tonada
    : TONICA MENOR SUBDOM TONICA FRENAO
    ;

contrapunteo
    : TONICA DOMINANTE bordoneo FRENAO
    ;

bordoneo
    : SUBDOM DOMINANTE TONICA
    | SUBDOM DOMINANTE TONICA bordoneo
    ;

TONICA    : 'T' ;
SUBDOM    : 'S' ;
DOMINANTE : 'D' ;
MENOR     : 'M' ;
FRENAO    : 'F' ;
WS        : [ \t\r\n]+ -> skip ;
