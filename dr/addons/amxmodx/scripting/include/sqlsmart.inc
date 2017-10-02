#pragma reqlib "SqlSmart"

/**
 * Reinitializeaza conexiunea SQL.
 *
 * @Param : Fara parametri.
 *
 * @Return : Nu returneaza nimic.
 */
native reconnectToSqlDataBase();

/**
 * Apelat dupa ce s-a realizat conexiunea SQL.
 *
 * @Param : Transmite un obiect de tip Handle, ce reprezinta Truple-ul conexiunii.
 *
 * @Nota : Daca conexiunea esueaza functia nu va fi apelata.
 *
 * @Return : Valorile de return sunt ignorate.
 */
forward onSqlConnection(Handle:SqlTruple);