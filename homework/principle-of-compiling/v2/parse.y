%{
#include "common.h"

#define YYERROR_VERBOSE

#define NODE_IN_QUEUE(node, prev, return)  {\
            if((node) != NULL){   \
                if((prev) != NULL){  \
                    insque((node), (prev)); /* 解决 bug -- prev 可能为空 */ \
                } \
                else{    \
                    insque((node), (node)); \
                } \
                (return) = (node);  \
            }   \
            else{    \
                (return) = (prev); \
            } \
        }
#define NODE_INIT_QUEUE(node, return)   {\
            if((node) != NULL){    \
                insque((node), (node)); \
            } \
            (return) = (node); \
        }

int yylex(void);
void yyerror(const char *s);

char *database = NULL;
// yyval is global variable, can it be known the first use in some condition? Maybe yes.

%}

%union {
    int   numi;
    float numf;
    char *string;
    struct query_t *query;
    struct column_type_t *column_type;
    struct column_t *column;
    struct value_t *value;
    struct assign_expr_t *assign_expr;
    struct condition_expr_t *condition_expr;
    struct condition_expr_leaf_t *condition_expr_leaf;
}

%token CREATE DELETE DROP EXIT INSERT SELECT SHOW UPDATE
%token DATABASE DATABASES FROM INTO SET TABLE TABLES USE WHERE VALUES
%token <string> YY_GG YY_GE YY_LL YY_LE YY_IS YY_NE YY_AND YY_OR YY_NOT
%token <string> ID DATATYPE YY_STRING
%token <numi>   NUMI
%token <numf>   NUMF
%type  <query> lines create_stmt drop_stmt show_stmt use_stmt exit_stmt
%type  <query> select_stmt insert_stmt update_stmt delete_stmt
%type  <string> database_name table_name column name
%type  <numi> expr_int
%type  <numf> expr_float
%type  <string> expr_string
%type  <column_type> column_type_list
%type  <column>  column_list
%type  <value> value_list
%type  <assign_expr>  assign_expr_list
%type  <condition_expr>  condition_expr
%type  <condition_expr_leaf> condition_expr_leaf

%destructor { free($$); } DATATYPE YY_STRING YY_GG YY_GE YY_LL YY_LE YY_IS YY_NE YY_AND YY_OR YY_NOT
%destructor { free($$); } database_name table_name column

%left   ','
%right  '='
%left   YY_AND YY_OR
%left   YY_IS YY_NE
%left   YY_G YY_GE YY_L YY_LE
%left   '+' '-'
%left   '*' '/' '%'
%right  UMINUS
%right  '^'
%right  YY_NOT

%start start

%%

start
    : start lines ';' { hub($2); free_query($2); }
    | start ';' { fprintf(stderr, "ERROR: No query specified\n"); }
    | error ';' { yyerrok; } /* Error Recovery: On error, skip until ';' is read.  */
    | /* empty */
    ;

lines
    : create_stmt   { if($1 != NULL) $1->stmt = CREATE_STMT; $$ = $1; }
    | drop_stmt     { if($1 != NULL) $1->stmt = DROP_STMT;   $$ = $1; }
    | show_stmt     { if($1 != NULL) $1->stmt = SHOW_STMT;   $$ = $1; }
    | use_stmt      { if($1 != NULL) $1->stmt = USE_STMT;    $$ = $1; }
    | exit_stmt     { if($1 != NULL) $1->stmt = EXIT_STMT;   $$ = $1; }
    | select_stmt   { if($1 != NULL) $1->stmt = SELECT_STMT; $$ = $1; }
    | insert_stmt   { if($1 != NULL) $1->stmt = INSERT_STMT; $$ = $1; }
    | update_stmt   { if($1 != NULL) $1->stmt = UPDATE_STMT; $$ = $1; }
    | delete_stmt   { if($1 != NULL) $1->stmt = DELETE_STMT; $$ = $1; }
    ;

create_stmt
    : CREATE DATABASE database_name {
            $$ = create_query(ROOT);
            if($$ != NULL){
                assign_create_opt($$, DATABASE_OPT);
                assign_database_name($$, $3);
            }
        }
    | CREATE TABLE table_name '(' column_type_list')' { 
            $$ = create_query(database);
            if($$ != NULL){
                assign_create_opt($$, TABLE_OPT);
                assign_table_name($$, $3);
                assign_column_type_list($$, $5);
            }
        }
    | CREATE TABLE table_name {
            $$ = create_query(database);
            if($$ != NULL){
                assign_create_opt($$, TABLE_OPT);
                assign_table_name($$, $3);
                assign_column_type_list($$, NULL);
            }
        }
    ;

drop_stmt
    : DROP DATABASE database_name   {
            $$ = create_query(ROOT);
            if($$ != NULL)
                assign_database_name($$, $3);
        }
    | DROP TABLE table_name         {
            $$ = create_query(database);
            if($$ != NULL)
                assign_table_name($$, $3);
        }
    ;

show_stmt
    : SHOW DATABASES { $$ = create_query(ROOT); }
    | SHOW TABLES {
            $$ = create_query(database);
            if($$ != NULL)
                assign_database_name($$, database);
        }
    ;

use_stmt
    : USE database_name { 
            $$ = create_query(ROOT);
            if($$ != NULL)
                assign_database_name($$, $2);
        }
    ;

exit_stmt
    : EXIT  { $$ = create_query(ROOT); }
    ;

select_stmt
    : SELECT '*' FROM table_name    {
            $$ = create_query(database);
            if($$ != NULL){
                assign_table_name($$, $4);
            }
        }
    | SELECT column_list FROM table_name    {
            $$ = create_query(database);
            if($$ != NULL){
                assign_column_list($$, $2);
                assign_table_name($$, $4);
            }
        }
    | SELECT '*' FROM table_name WHERE condition_expr    {
            $$ = create_query(database);
            if($$ != NULL){
                assign_table_name($$, $4);
                assign_condition($$, $6);
            }
        }
    | SELECT column_list FROM table_name WHERE condition_expr    {
            $$ = create_query(database);
            if($$ != NULL){
                assign_column_list($$, $2);
                assign_table_name($$, $4);
                assign_condition($$, $6);
            }
        }
    ;

insert_stmt
    : INSERT INTO table_name VALUES '(' value_list ')' {
            $$ = create_query(database);
            if($$ != NULL){
                assign_table_name($$, $3);
                assign_column_list($$, NULL);
                assign_value_list($$, $6);
            }
        }
    | INSERT INTO table_name '(' column_list ')' VALUES '(' value_list ')' {
            $$ = create_query(database);
            if($$ != NULL){
                assign_table_name($$, $3);
                assign_column_list($$, $5);
                assign_value_list($$, $9);
            }
        }
    ;

update_stmt
    : UPDATE table_name SET assign_expr_list WHERE condition_expr {
            $$ = create_query(database);
            if($$ != NULL){
                assign_table_name($$, $2);
                assign_assign_expr_list($$, $4);
                assign_condition($$, $6);
            }
        }
    ;

delete_stmt
    : DELETE FROM table_name WHERE condition_expr {
            $$ = create_query(database);
            if($$ != NULL){
                assign_table_name($$, $3);
                assign_condition($$, $5);
            }
        }
    ;

column_type_list
    : column_type_list ',' column DATATYPE {
            struct column_type_t *node = NULL;
            node = create_column_type($3, $4);
            NODE_IN_QUEUE(node, $1, $$);
        }
    | column DATATYPE   {
            struct column_type_t *node = NULL;
            node = create_column_type($1, $2);
            NODE_INIT_QUEUE(node, $$);
        }
    ;

column_list
    : column_list ',' column  {
            struct column_t *node = NULL;
            node = create_column($3);
            NODE_IN_QUEUE(node, $1, $$);
        }
    | column  {
            struct column_t *node = NULL;
            node = create_column($1);
            NODE_INIT_QUEUE(node, $$);
        }
    ;

value_list
    : value_list ',' expr_int {
            struct value_t *node = NULL;
            node = create_value(&$3, INT);
            NODE_IN_QUEUE(node, $1, $$);
        }
    | value_list ',' expr_float {
            struct value_t *node = NULL;
            node = create_value(&$3, FLOAT);
            NODE_IN_QUEUE(node, $1, $$);
        }
    | value_list ',' expr_string  {
            struct value_t *node = NULL;
            node = create_value($3, STRING);
            NODE_IN_QUEUE(node, $1, $$);
        }
    | expr_int   {
            struct value_t *node = NULL;
            node = create_value(&$1, INT);
            NODE_INIT_QUEUE(node, $$);
        }
    | expr_float   {
            struct value_t *node = NULL;
            node = create_value(&$1, FLOAT);
            NODE_INIT_QUEUE(node, $$);
        }
    | expr_string   {
            struct value_t *node = NULL;
            node = create_value($1, STRING);
            NODE_INIT_QUEUE(node, $$);
        }
    ;

assign_expr_list
    : assign_expr_list ',' column '=' expr_float {
            struct assign_expr_t *node = NULL;
            node = create_assign_expr($3, &$5, FLOAT);
            NODE_IN_QUEUE(node, $1, $$);
        }
    | assign_expr_list ',' column '=' expr_int   {
            struct assign_expr_t *node = NULL;
            node = create_assign_expr($3, &$5, INT);
            NODE_IN_QUEUE(node, $1, $$);
        }
    | assign_expr_list ',' column '=' expr_string   {
            struct assign_expr_t *node = NULL;
            node = create_assign_expr($3, $5, STRING);
            NODE_IN_QUEUE(node, $1, $$);
        }
    | column '=' expr_float {
            struct assign_expr_t *node = NULL;
            node = create_assign_expr($1, &$3, FLOAT);
            NODE_INIT_QUEUE(node, $$);
        }
    | column '=' expr_int   {
            struct assign_expr_t *node = NULL;
            node = create_assign_expr($1, &$3, INT);
            NODE_INIT_QUEUE(node, $$);
        }
    | column '=' expr_string    {
            struct assign_expr_t *node = NULL;
            node = create_assign_expr($1, $3, STRING);
            NODE_INIT_QUEUE(node, $$);
        }
    ;

condition_expr
    : condition_expr YY_AND condition_expr {
            struct condition_expr_t *node = NULL;
            node = create_condition_expr($2, LOGIC);
            NODE_IN_QUEUE($3, $1, $3);
            NODE_IN_QUEUE(node, $3, $$);
        } 
    | condition_expr YY_OR  condition_expr {
            struct condition_expr_t *node = NULL;
            node = create_condition_expr($2, LOGIC);
            NODE_IN_QUEUE($3, $1, $3);
            NODE_IN_QUEUE(node, $3, $$);
        }
    | YY_NOT condition_expr                {
            struct condition_expr_t *node = NULL;
            node = create_condition_expr($1, LOGIC);
            NODE_IN_QUEUE(node, $2, $$);
        }
    | '(' condition_expr ')'    { $$ = $2; }
    | condition_expr_leaf   {
            struct condition_expr_t *node = NULL;
            node = create_condition_expr($1, CONDITION_LEAF);
            NODE_INIT_QUEUE(node, $$);
        }
    ;

condition_expr_leaf
    : column YY_GG expr_float    { $$ = create_condition_expr_leaf($1, $2, &$3, FLOAT); }
    | column YY_GE expr_float    { $$ = create_condition_expr_leaf($1, $2, &$3, FLOAT); }
    | column YY_IS expr_float    { $$ = create_condition_expr_leaf($1, $2, &$3, FLOAT); }
    | column YY_LL expr_float    { $$ = create_condition_expr_leaf($1, $2, &$3, FLOAT); }
    | column YY_LE expr_float    { $$ = create_condition_expr_leaf($1, $2, &$3, FLOAT); }
    | column YY_NE expr_float    { $$ = create_condition_expr_leaf($1, $2, &$3, FLOAT); }
    | column YY_GG expr_int      { $$ = create_condition_expr_leaf($1, $2, &$3, INT); }
    | column YY_GE expr_int      { $$ = create_condition_expr_leaf($1, $2, &$3, INT); }
    | column YY_IS expr_int      { $$ = create_condition_expr_leaf($1, $2, &$3, INT); }
    | column YY_LL expr_int      { $$ = create_condition_expr_leaf($1, $2, &$3, INT); }
    | column YY_LE expr_int      { $$ = create_condition_expr_leaf($1, $2, &$3, INT); }
    | column YY_NE expr_int      { $$ = create_condition_expr_leaf($1, $2, &$3, INT); }
    | column YY_GG expr_string   { $$ = create_condition_expr_leaf($1, $2, $3, STRING); }
    | column YY_GE expr_string   { $$ = create_condition_expr_leaf($1, $2, $3, STRING); }
    | column YY_IS expr_string   { $$ = create_condition_expr_leaf($1, $2, $3, STRING); }
    | column YY_LL expr_string   { $$ = create_condition_expr_leaf($1, $2, $3, STRING); }
    | column YY_LE expr_string   { $$ = create_condition_expr_leaf($1, $2, $3, STRING); }
    | column YY_NE expr_string   { $$ = create_condition_expr_leaf($1, $2, $3, STRING); }
    ;

expr_float
    : NUMF                        { $$ = $1; }
    | expr_float '+' expr_float   { $$ = $1 + $3; }
    | expr_float '+' expr_int     { $$ = $1 + (float)$3; }
    | expr_int   '+' expr_float   { $$ = (float)$1 - $3; }
    | expr_float '-' expr_float   { $$ = $1 - $3; }
    | expr_float '-' expr_int     { $$ = $1 + (float)$3; }
    | expr_int   '-' expr_float   { $$ = (float)$1 - $3; }
    | expr_float '*' expr_float   { $$ = $1 * $3; }
    | expr_float '*' expr_int     { $$ = $1 * (float)$3; }
    | expr_int   '*' expr_float   { $$ = (float)$1 * $3; } 
    | expr_float '/' expr_float   { 
            if($3)
                $$ = $1 / $3;
            else{
                $$ = 1.0f;
                fprintf(stderr, "ERROR: division by zero\n");
            }
        }
    | expr_float '/' expr_int     { 
            if($3)
                $$ = $1 / (float)$3;
            else{
                $$ = 1.0f;
                fprintf(stderr, "ERROR: division by zero\n");
            }
        }
    | expr_int '/' expr_float     { 
            if($3)
                $$ = (float)$1 / $3;
            else{
                $$ = 1.0f;
                fprintf(stderr, "ERROR: division by zero\n");
            }
        }
    | '(' expr_float ')'          { $$ = $2; }
    | '-' expr_float %prec UMINUS { $$ = -$2; }
    | '+' expr_float %prec UMINUS { $$ = $2; }
    | expr_float '^' expr_float   { $$ = powf($1,$3); }
    | expr_float '^' expr_int     { $$ = powf($1,(float)$3); }
    | expr_int   '^' expr_float   { $$ = powf((float)$1, $3); }
    | expr_int   '^' expr_int     { $$ = powf((float)$1, (float)$3); }
    ;

expr_int
    : NUMI
    | expr_int '+' expr_int   { $$ = $1 + $3; }
    | expr_int '-' expr_int   { $$ = $1 - $3; }
    | expr_int '*' expr_int   { $$ = $1 * $3; }
    | expr_int '/' expr_int   { 
            if($3)
                $$ = $1 / $3;
            else{
                $$ = 1;
                fprintf(stderr, "ERROR: division by zero\n");
            }
        }
    | expr_int '%' expr_int   { 
            if($3)
                $$ = $1 % $3;
            else{
                $$ = 1;
                fprintf(stderr, "ERROR: modulo by zero\n");
            }
        }
    | '(' expr_int ')'          { $$ = $2; }
    | '-' expr_int %prec UMINUS { $$ = -$2; }
    | '+' expr_int %prec UMINUS { $$ = $2; }
        /* 不允许 int 类型的指数运算 */
    ;

expr_string
    : YY_STRING   { $$ = $1; }
    ;

database_name
    : name  { $$ = $1; }
    ;

table_name
    : name  { $$ = $1; }
    ;

column
    : name  { $$ = $1; }
    ;

name
    : ID    { $$ = $1; }
    ;
%%

#include "lex.yy.c"

int main(int argc, char *argv[]){
    init();
    yyparse();
    return 0;
}

void yyerror(const char *s){
    fprintf(stderr, "Error: %s\n", s);
    return;
}

