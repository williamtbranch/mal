@io.sql
@types.sql
@reader.sql
@printer.sql
@env.sql
@core.sql

CREATE OR REPLACE PACKAGE mal_pkg IS

FUNCTION MAIN(pwd varchar) RETURN integer;

END mal_pkg;
/

CREATE OR REPLACE PACKAGE BODY mal_pkg IS

FUNCTION MAIN(pwd varchar) RETURN integer IS
    env_mem   env_mem_type;
    atom_mem  atom_mem_type;
    repl_env  integer;
    line      varchar2(4000);
    x         mal_type;
    core_ns   core_ns_type;
    cidx      integer;

    -- read
    FUNCTION READ(line varchar) RETURN mal_type IS
    BEGIN
        RETURN reader_pkg.read_str(line);
    END;

    -- eval

    -- forward declarations
    FUNCTION EVAL(ast mal_type, env integer) RETURN mal_type;
    FUNCTION do_builtin(fn mal_type, args mal_seq_type) RETURN mal_type;

    FUNCTION eval_ast(ast mal_type, env integer) RETURN mal_type IS
        i        integer;
        old_seq  mal_seq_items_type;
        new_seq  mal_seq_items_type;
        f        mal_type;
    BEGIN
        IF ast.type_id = 7 THEN
            RETURN env_pkg.env_get(env_mem, env, ast);
        ELSIF ast.type_id IN (8,9) THEN
            old_seq := TREAT(ast AS mal_seq_type).val_seq;
            new_seq := mal_seq_items_type();
            new_seq.EXTEND(old_seq.COUNT);
            FOR i IN 1..old_seq.COUNT LOOP
                new_seq(i) := EVAL(old_seq(i), env);
            END LOOP;
            RETURN mal_seq_type(ast.type_id, new_seq);
        ELSE
            RETURN ast;
        END IF;
    END;

    FUNCTION EVAL(ast mal_type, env integer) RETURN mal_type IS
        el       mal_type;
        a0       mal_type;
        a0sym    varchar2(4000);
        seq      mal_seq_items_type;
        let_env  integer;
        fn_env   integer;
        i        integer;
        cond     mal_type;
        f        mal_type;
        malfn    malfunc_type;
        args     mal_seq_type;
    BEGIN
        IF ast.type_id <> 8 THEN
            RETURN eval_ast(ast, env);
        END IF;

        -- apply
        a0 := types_pkg.first(ast);
        if a0.type_id = 7 THEN -- symbol
            a0sym := TREAT(a0 AS mal_str_type).val_str;
        ELSE
            a0sym := '__<*fn*>__';
        END IF;

        CASE
        WHEN a0sym = 'def!' THEN
            RETURN env_pkg.env_set(env_mem, env,
                types_pkg.nth(ast, 1), EVAL(types_pkg.nth(ast, 2), env));
        WHEN a0sym = 'let*' THEN
            let_env := env_pkg.env_new(env_mem, env);
            seq := TREAT(types_pkg.nth(ast, 1) AS mal_seq_type).val_seq;
            i := 1;
            WHILE i <= seq.COUNT LOOP
                x := env_pkg.env_set(env_mem, let_env,
                    seq(i), EVAL(seq(i+1), let_env));
                i := i + 2;
            END LOOP;
            RETURN EVAL(types_pkg.nth(ast, 2), let_env);
        WHEN a0sym = 'do' THEN
            el := eval_ast(types_pkg.slice(ast, 1), env);
            RETURN types_pkg.nth(el, types_pkg.count(el)-1);
        WHEN a0sym = 'if' THEN
            cond := EVAL(types_pkg.nth(ast, 1), env);
            IF cond.type_id = 0 OR cond.type_id = 1 THEN
                IF types_pkg.count(ast) > 3 THEN
                    RETURN EVAL(types_pkg.nth(ast, 3), env);
                ELSE
                    RETURN mal_type(0);
                END IF;
            ELSE
                RETURN EVAL(types_pkg.nth(ast, 2), env);
            END IF;
        WHEN a0sym = 'fn*' THEN
            RETURN malfunc_type(12, types_pkg.nth(ast, 2),
                                    types_pkg.nth(ast, 1),
                                    env);
        ELSE
            el := eval_ast(ast, env);
            f := types_pkg.first(el);
            args := TREAT(types_pkg.slice(el, 1) AS mal_seq_type);
            IF f.type_id = 12 THEN
                malfn := TREAT(f AS malfunc_type);
                fn_env := env_pkg.env_new(env_mem, malfn.env,
                                          malfn.params, args);
                RETURN EVAL(malfn.ast, fn_env);
            ELSE
                RETURN do_builtin(f, args);
            END IF;
        END CASE;

    END;

    -- hack to get around lack of function references
    -- functions that require special access to repl_env of atom_mem
    -- are implemented directly here, otherwise, core_pkg.do_core_fn
    -- is called.
    FUNCTION do_builtin(fn mal_type, args mal_seq_type) RETURN mal_type IS
        fname   varchar2(100);
        sargs   mal_seq_items_type := args.val_seq;
        aidx    integer;
        f       mal_type;
        malfn   malfunc_type;
        fargs   mal_seq_items_type;
        fn_env  integer;
    BEGIN
        fname := TREAT(fn AS mal_str_type).val_str;
        CASE
        WHEN fname = 'do_eval' THEN
            RETURN EVAL(sargs(1), repl_env);
        WHEN fname = 'atom' THEN
            RETURN types_pkg.atom_new(atom_mem, sargs(1));
        WHEN fname = 'atom?' THEN
            RETURN types_pkg.wraptf(sargs(1).type_id = 13);
        WHEN fname = 'deref' THEN
            aidx := TREAT(sargs(1) AS atom_type).val;
            RETURN atom_mem(aidx);
        WHEN fname = 'reset!' THEN
            aidx := TREAT(sargs(1) AS atom_type).val;
            atom_mem(aidx) := sargs(2);
            RETURN sargs(2);
        WHEN fname = 'swap!' THEN
            aidx := TREAT(sargs(1) AS atom_type).val;
            f := sargs(2);
            -- slice one extra at the beginning that will be changed
            -- to the value of the atom
            fargs := TREAT(types_pkg.slice(sargs, 1) AS mal_seq_type).val_seq;
            fargs(1) := atom_mem(aidx);
            IF f.type_id = 12 THEN
                malfn := TREAT(f AS malfunc_type);
                fn_env := env_pkg.env_new(env_mem, malfn.env,
                                          malfn.params,
                                          mal_seq_type(8, fargs));
                atom_mem(aidx) := EVAL(malfn.ast, fn_env);
                RETURN atom_mem(aidx);
            ELSE
                atom_mem(aidx) := do_builtin(f, mal_seq_type(8, fargs));
                RETURN atom_mem(aidx);
            END IF;
        ELSE
            RETURN core_pkg.do_core_func(fn, sargs);
        END CASE;
    END;


    -- print
    FUNCTION PRINT(exp mal_type) RETURN varchar IS
    BEGIN
        if exp.type_id = 13 THEN
            -- hack to get around fact that atom_mem is not visible
            -- from printer_pkg
            RETURN '(atom ' || printer_pkg.pr_str(
                    atom_mem(TREAT(exp AS atom_type).val), TRUE) || ')';
        ELSE
            RETURN printer_pkg.pr_str(exp);
        END IF;
    END;

    -- repl
    FUNCTION REP(line varchar) RETURN varchar IS
    BEGIN
        RETURN PRINT(EVAL(READ(line), repl_env));
    END;

BEGIN
    env_mem := env_mem_type();
    atom_mem := atom_mem_type();
    repl_env := env_pkg.env_new(env_mem, NULL);

    -- core.EXT: defined using PL/SQL
    core_ns := core_pkg.get_core_ns();
    FOR cidx IN 1..core_ns.COUNT LOOP
        x := env_pkg.env_set(env_mem, repl_env,
            types_pkg.symbol(core_ns(cidx)),
            mal_str_type(11, core_ns(cidx)));
    END LOOP;
    x := env_pkg.env_set(env_mem, repl_env,
        types_pkg.symbol('eval'),
        mal_str_type(11, 'do_eval'));
    x := env_pkg.env_set(env_mem, repl_env,
        types_pkg.symbol('*ARGV*'),
        mal_seq_type(8, mal_seq_items_type()));

    -- core.mal: defined using the language itself
    line := REP('(def! not (fn* (a) (if a false true)))');
    line := REP('(def! load-file (fn* (f) (eval (read-string (str "(do " (slurp f) ")")))))');

    WHILE true LOOP
        BEGIN
            line := stream_readline('user> ', 0);
            -- stream_writeline('line: [' || line || ']', 1);
            IF line IS NULL THEN RETURN 0; END IF;
            IF line IS NOT NULL THEN
                stream_writeline(REP(line));
            END IF;

            EXCEPTION WHEN OTHERS THEN
                IF SQLCODE = -20000 THEN
                    RETURN 0;
                END IF;
                stream_writeline('Error: ' || SQLERRM);
                stream_writeline(dbms_utility.format_error_backtrace);
        END;
    END LOOP;
END;

END mal_pkg;
/
show errors;

quit;