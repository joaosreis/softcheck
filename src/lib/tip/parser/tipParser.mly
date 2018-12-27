
%{
  open Tip.Ast

  (*open Lexing*)

  (*let func_num = ref 0*)

  (*let new_func _ = func_num := !func_num + 1*)

  (*let var x = x ^ "_" ^ string_of_int(!func_num)*)

  (*let position_to_string (s,e) =
    Printf.sprintf "%s:%d:%d-%d" s.pos_fname s.pos_lnum (s.pos_cnum - s.pos_bol + 1) (e.pos_cnum - e.pos_bol + 1)*)

  (*let print_error msg pos =
    Printf.fprintf stderr "%s: %s\n" (position_to_string pos) msg; exit(-1)*)
    let i = ref 0
    let label_function = label_function i
%}

%token <Tip.Ast.constant> NUM
%token <Tip.Ast.ident> IDENT
%token IF ELSE WHILE
%token INPUT OUTPUT RETURN VAR
%token MALLOC NULL REF
%token LB RB LP RP COMMA SEMICOLON
%token EOF
%token PLUS MINUS TIMES DIV EQQ GT EQ

%left EQQ GT
%left PLUS MINUS
%left TIMES DIV

%nonassoc IF_PREC
%nonassoc ELSE

%start <Tip.Ast.program> program

%%

program:
  funcs=func* EOF { funcs }

func:
  id=IDENT LP args=separated_list(COMMA, IDENT) RP LB vars=declaration body=stmts RETURN e=expr SEMICOLON RB
  { { func_id=id; func_args=args; func_vars=vars; func_body=label_function body; func_return=e } }

stmt:
    s=block
  | s=output
  | s=assignment
  | s=whileb
  | s=ifb         { s }

output:
    OUTPUT e=expr SEMICOLON { SUoutput(e) }

assignment:
    e1=ident EQ e2=expr SEMICOLON       { SUassign(e1,e2) }
  | TIMES e1=ident EQ e2=expr SEMICOLON { SUassign(Eunop(Uderef,e1),e2) }

declaration:
                                                              { [] }
  | VAR decls=separated_nonempty_list(COMMA, IDENT) SEMICOLON { decls }

stmts:
  s=stmt+ { SUblock s }

block:
    LB b=stmts RB { b }

whileb:
    WHILE LP e=expr RP b=stmt { SUwhile(e,b) }

ifb:
    IF LP e=expr RP bi=stmt %prec IF_PREC { SUif(e,bi) }
  | IF LP e=expr RP bi=stmt ELSE be=stmt  { SUifelse(e,bi,be) }

expr:
    e1=expr o=binop e2=expr { Ebinop(o,e1,e2) }
  | a=atom                  { a }

atom:
    a=funapp    { a }
  | a=constant  { Ecst(a) }
  | a=parens    { a }
  | a=ident     { a }
  | INPUT       { Einput }
  | a=ptrexp    { a }

constant:
  n=NUM       { n }
| MINUS n=NUM { -n }

funapp:
    f=parens args=funargs { Ecallfptr(f,args) }
  | f=IDENT args=funargs { Ecallf(f,args) }

funargs:
    LP args=separated_list(COMMA, expr) RP  { args }

parens:
    LP e=expr RP  { e }

ident:
    i=IDENT { Eident(i) }

ptrexp:
    MALLOC        { Emalloc }
  | NULL          { Enull }
  | o=unop e=atom { Eunop(o,e) }

%inline unop:
    REF   { Uref }
  | TIMES { Uderef }

%inline binop:
    PLUS  { Badd }
  | MINUS { Bsub }
  | TIMES { Bmul }
  | DIV   { Bdiv }
  | EQQ   { Beq }
  | GT    { Bgt }
