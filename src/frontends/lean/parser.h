/*
Copyright (c) 2014 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Leonardo de Moura
*/
#pragma once
#include <string>
#include <utility>
#include <vector>
#include "util/script_state.h"
#include "util/name_map.h"
#include "util/exception.h"
#include "kernel/environment.h"
#include "kernel/expr_maps.h"
#include "library/io_state.h"
#include "library/io_state_stream.h"
#include "library/kernel_bindings.h"
#include "frontends/lean/scanner.h"
#include "frontends/lean/local_decls.h"
#include "frontends/lean/parser_config.h"
#include "frontends/lean/parser_pos_provider.h"

namespace lean {
struct parameter {
    pos_info    m_pos;
    expr        m_local;
    binder_info m_bi;
    parameter(pos_info const & p, expr const & l, binder_info const & bi):
        m_pos(p), m_local(l), m_bi(bi) {}
    parameter():m_pos(0, 0) {}
};

/** \brief Exception used to track parsing erros, it does not leak outside of this class. */
struct parser_error : public exception {
    pos_info m_pos;
    parser_error(char const * msg, pos_info const & p):exception(msg), m_pos(p) {}
    parser_error(sstream const & msg, pos_info const & p):exception(msg), m_pos(p) {}
    virtual exception * clone() const { return new parser_error(m_msg.c_str(), m_pos); }
    virtual void rethrow() const { throw *this; }
};

struct interrupt_parser {};
typedef local_decls<parameter> local_expr_decls;
typedef local_decls<level>     local_level_decls;
typedef environment            local_environment;
typedef std::unordered_map<unsigned, tactic> hint_table;

class parser {
    environment             m_env;
    io_state                m_ios;
    script_state *          m_ss;
    bool                    m_verbose;
    bool                    m_use_exceptions;
    bool                    m_show_errors;

    scanner                 m_scanner;
    scanner::token_kind     m_curr;
    local_level_decls       m_local_level_decls;
    local_expr_decls        m_local_decls;
    pos_info                m_last_cmd_pos;
    pos_info                m_last_script_pos;
    unsigned                m_next_tag_idx;
    bool                    m_found_errors;
    pos_info_table_ptr      m_pos_table;
    hint_table              m_hints;
    // If m_type_use_placeholder is true, then the token Type is parsed as Type.{_}.
    // if it is false, then it is parsed as Type.{l} where l is a fresh parameter,
    // and is automatically inserted into m_local_level_decls.
    bool                    m_type_use_placeholder;

    void display_error_pos(unsigned line, unsigned pos);
    void display_error_pos(pos_info p);
    void display_error(char const * msg, unsigned line, unsigned pos);
    void display_error(char const * msg, pos_info p);
    void display_error(exception const & ex);
    void throw_parser_exception(char const * msg, pos_info p);
    void throw_nested_exception(exception & ex, pos_info p);

    void sync_command();
    void protected_call(std::function<void()> && f, std::function<void()> && sync);
    template<typename F>
    typename std::result_of<F(lua_State * L)>::type using_script(F && f) {
        return m_ss->apply([&](lua_State * L) {
                set_io_state    set1(L, m_ios);
                set_environment set2(L, m_env);
                return f(L);
            });
    }

    tag get_tag(expr e);
    expr copy_with_new_pos(expr const & e, pos_info p);
    expr propagate_levels(expr const & e, levels const & ls);

    void updt_options();

    cmd_table const & cmds() const { return get_cmd_table(env()); }
    parse_table const & nud() const { return get_nud_table(env()); }
    parse_table const & led() const { return get_led_table(env()); }
    tactic_cmd_table const & tactic_cmds() const { return get_tactic_cmd_table(env()); }

    unsigned curr_level_lbp() const;
    level parse_max_imax(bool is_max);
    level parse_level_id();
    level parse_level_nud();
    level parse_level_led(level left);

    void parse_command();
    void parse_script(bool as_expr = false);
    bool parse_commands();
    unsigned curr_lbp() const;
    expr parse_notation(parse_table t, expr * left);
    expr parse_nud_notation();
    expr parse_led_notation(expr left);
    expr parse_nud();
    expr parse_led(expr left);
    expr parse_id();
    expr parse_numeral_expr();
    expr parse_decimal_expr();
    expr parse_string_expr();
    parameter parse_binder_core(binder_info const & bi);
    void parse_binder_block(buffer<parameter> & r, binder_info const & bi);
    void parse_binders_core(buffer<parameter> & r);
    expr mk_app(expr fn, expr arg, pos_info const & p);

    friend environment section_cmd(parser & p);
    friend environment end_scoped_cmd(parser & p);

    void push_local_scope();
    void pop_local_scope();

public:
    parser(environment const & env, io_state const & ios,
           std::istream & strm, char const * str_name,
           script_state * ss = nullptr, bool use_exceptions = false,
           local_level_decls const & lds = local_level_decls(),
           local_expr_decls const & eds = local_expr_decls(),
           unsigned line = 1);

    environment const & env() const { return m_env; }
    io_state const & ios() const { return m_ios; }
    script_state * ss() const { return m_ss; }
    local_level_decls const & get_local_level_decls() const { return m_local_level_decls; }
    local_expr_decls const & get_local_expr_decls() const { return m_local_decls; }

    /** \brief Return the current position information */
    pos_info pos() const { return pos_info(m_scanner.get_line(), m_scanner.get_pos()); }
    expr save_pos(expr e, pos_info p);
    expr rec_save_pos(expr const & e, pos_info p);
    pos_info pos_of(expr const & e, pos_info default_pos);
    pos_info pos_of(expr const & e) { return pos_of(e, pos()); }
    pos_info cmd_pos() const { return m_last_cmd_pos; }
    void set_line(unsigned p) { return m_scanner.set_line(p); }

    /** \brief Read the next token. */
    void scan() { m_curr = m_scanner.scan(m_env); }
    /** \brief Return the current token */
    scanner::token_kind curr() const { return m_curr; }
    /** \brief Return true iff the current token is an identifier */
    bool curr_is_identifier() const { return curr() == scanner::token_kind::Identifier; }
    /** \brief Return true iff the current token is a numeral */
    bool curr_is_numeral() const { return curr() == scanner::token_kind::Numeral; }
    /** \brief Return true iff the current token is a string */
    bool curr_is_string() const { return curr() == scanner::token_kind::String; }
    /** \brief Return true iff the current token is a keyword */
    bool curr_is_keyword() const { return curr() == scanner::token_kind::Keyword; }
    /** \brief Return true iff the current token is a keyword */
    bool curr_is_quoted_symbol() const { return curr() == scanner::token_kind::QuotedSymbol; }
    /** \brief Return true if the current token is a keyword named \c tk or an identifier named \c tk */
    bool curr_is_token_or_id(name const & tk) const;
    /** \brief Read the next token if the current one is not End-of-file. */
    void next() { if (m_curr != scanner::token_kind::Eof) scan(); }
    /** \brief Return true iff the current token is a keyword (or command keyword) named \c tk */
    bool curr_is_token(name const & tk) const;
    /** \brief Check current token, and move to next characther, throw exception if current token is not \c tk. */
    void check_token_next(name const & tk, char const * msg);
    /** \brief Check if the current token is an identifier, if it is return it and move to next token, otherwise throw an exception. */
    name check_id_next(char const * msg);

    mpq const & get_num_val() const { return m_scanner.get_num_val(); }
    name const & get_name_val() const { return m_scanner.get_name_val(); }
    std::string const & get_str_val() const { return m_scanner.get_str_val(); }
    token_info const & get_token_info() const { return m_scanner.get_token_info(); }
    std::string const & get_stream_name() const { return m_scanner.get_stream_name(); }

    regular regular_stream() const { return regular(env(), ios()); }
    diagnostic diagnostic_stream() const { return diagnostic(env(), ios()); }

    void parse_names(buffer<std::pair<pos_info, name>> & result);
    unsigned get_small_nat();
    unsigned parse_small_nat();

    bool parse_local_notation_decl();

    level parse_level(unsigned rbp = 0);

    parameter parse_binder();
    local_environment parse_binders(buffer<parameter> & r);

    expr parse_expr(unsigned rbp = 0);
    expr parse_scoped_expr(unsigned num_params, parameter const * ps, local_environment const & lenv, unsigned rbp = 0);
    expr parse_scoped_expr(buffer<parameter> & ps, local_environment const & lenv, unsigned rbp = 0) {
        return parse_scoped_expr(ps.size(), ps.data(), lenv, rbp);
    }
    expr parse_scoped_expr(unsigned num_params, parameter const * ps, unsigned rbp = 0) {
        return parse_scoped_expr(num_params, ps, local_environment(m_env), rbp);
    }
    expr parse_scoped_expr(buffer<parameter> & ps, unsigned rbp = 0) { return parse_scoped_expr(ps.size(), ps.data(), rbp); }
    expr abstract(unsigned num_params, parameter const * ps, expr const & e, bool lambda, pos_info const & p);
    expr abstract(buffer<parameter> const & ps, expr const & e, bool lambda, pos_info const & p) { return abstract(ps.size(), ps.data(), e, lambda, p); }
    expr lambda_abstract(buffer<parameter> const & ps, expr const & e, pos_info const & p) { return abstract(ps, e, true, p); }
    expr pi_abstract(buffer<parameter> const & ps, expr const & e, pos_info const & p) { return abstract(ps, e, false, p); }
    expr lambda_abstract(buffer<parameter> const & ps, expr const & e) { return lambda_abstract(ps, e, pos_of(e)); }
    expr pi_abstract(buffer<parameter> const & ps, expr const & e) { return pi_abstract(ps, e, pos_of(e)); }

    tactic parse_tactic(unsigned rbp = 0);

    struct local_scope { parser & m_p; environment m_env; local_scope(parser & p); ~local_scope(); };
    void add_local_level(name const & n, level const & l);
    void add_local_expr(name const & n, expr const & e, binder_info const & bi = binder_info());
    void add_local(expr const & t);
    /** \brief Position of the local level declaration named \c n in the sequence of local level decls. */
    unsigned get_local_level_index(name const & n) const;
    /** \brief Position of the local declaration named \c n in the sequence of local decls. */
    unsigned get_local_index(name const & n) const;
    /** \brief Return the local parameter named \c n */
    optional<parameter> get_local(name const & n) const;
    /**
        \brief By default, \c mk_Type returns <tt>Type.{_}</tt> where '_' is a new placeholder.
        This scope object allows us to temporarily change this behavior.
        In any scope containing this object, \c mk_Type returns <tt>Type.{l}</tt>, where
        \c l is a fresh universe level parameter.
        The new parameter is automatically added to \c m_local_level_decls.
    */
    struct param_universe_scope { parser & m_p; bool m_old; param_universe_scope(parser &); ~param_universe_scope(); };
    expr mk_Type();

    /** \brief Use tactic \c t for "synthesizing" the placeholder \c e. */
    void save_hint(expr const & e, tactic const & t);

    expr elaborate(expr const & e, level_param_names const &);
    std::pair<expr, expr> elaborate(expr const & t, expr const & v, level_param_names const &);

    /** parse all commands in the input stream */
    bool operator()() { return parse_commands(); }
};

bool parse_commands(environment & env, io_state & ios, std::istream & in, char const * strm_name,
                    script_state * S, bool use_exceptions);
bool parse_commands(environment & env, io_state & ios, char const * fname, script_state * S,
                    bool use_exceptions);
}