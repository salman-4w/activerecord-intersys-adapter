#ifndef __cache_ruby
#define __cache_ruby

#include "ruby.h"

#ifdef RUBY_18
#  include "rubyio.h"
#  include "intern.h"
#else
#  include "ruby/io.h"
#  include "ruby/intern.h"
#endif

#include <time.h>
#include <c_api.h>

#ifdef _WIN32
#ifndef _WCHAR_T_DEFINED
typedef unsigned short wchar_t;
#define _WCHAR_T_DEFINED
#endif
#endif /* WIN32 */

struct rbDatabase {
	h_connection connection;
	h_database database;
	bool_t closed;
  const wchar_t connection_string[256];
  const wchar_t user[256];
  const wchar_t password[256];
  int timeout;
};

struct rbQuery {
	h_query query;
	bool_t empty;
	bool_t closed;
	bool_t executed;
	int offset;
	int limit;
};

struct rbObject {
	h_database database;
	int oref;
	VALUE class_name;
	bool_t closed;
};

struct rbDefinition {
	int type;
	h_database database;
  void *def;
  short cpp_type;
	h_class_def cl_def;
  const wchar_t* cache_type;
  const wchar_t* name;
	wchar_t* in_name;
	// Method definitions
	bool_t is_func;
	bool_t is_class_method;
	int num_args;
	int passed_args;
	void *args_info;
	int arg_counter;
	VALUE object;
	//Argument definitions
	bool_t is_by_ref;
	bool_t is_default;
	const char* default_value;
	long default_value_size;
	int arg_number;

	char* current_dlist;
	int current_dlist_size;
	VALUE class_name;
	//Property definitions
	int oref;
};

struct rbStatus {
	VALUE code;
	VALUE message;
};

struct rbGlobal {
	VALUE name;
};

enum { D_PROPERTY, D_METHOD, D_ARGUMENT};

enum {
	ERR_CONN_LINK_FAILURE = 461
};

extern VALUE mIntersys, cDatabase, cQuery, cObject, cDefinition, cProperty,
	cMethod, cArgument, cGlobal;
extern VALUE cTime, cDate;
extern VALUE cIntersysException, cObjectNotFound, cMarshallError, cUnMarshallError, cConnectionError;
extern VALUE cStatus;

/****** Common functions ******/
VALUE string_to_wchar(VALUE self);
int run(int error, char* file, int line);
VALUE string_from_wchar(VALUE self);
VALUE rb_wcstr_new(const wchar_t *w_str, const char_size_t len);
VALUE rb_wcstr_new2(const wchar_t *w_str);
VALUE wcstr_new(const wchar_t *w_str, const char_size_t len);
VALUE intersys_status_s_allocate(VALUE klass);
VALUE intersys_status_initialize(VALUE self, VALUE code, VALUE message);
VALUE intersys_status_code(VALUE self);
VALUE intersys_status_message(VALUE self);
VALUE intersys_status_to_s(VALUE self);

/******* Database functions *******/
VALUE intersys_base_s_allocate(VALUE klass);
VALUE intersys_base_initialize(VALUE self, VALUE options);
VALUE intersys_base_connect(VALUE self, VALUE options);
VALUE intersys_base_reconnect(VALUE self);
VALUE intersys_base_close(VALUE self);
VALUE intersys_base_start(VALUE self);
VALUE intersys_base_commit(VALUE self);
VALUE intersys_base_rollback(VALUE self);
VALUE intersys_base_level(VALUE self);

/******* Query functions *******/
VALUE intersys_query_s_allocate(VALUE klass);
VALUE intersys_query_initialize(VALUE self, VALUE database, VALUE sql_query);
VALUE intersys_query_bind_params(VALUE self, VALUE params);
VALUE intersys_query_execute(VALUE self);
VALUE intersys_query_column_count(VALUE self);
VALUE intersys_query_column_name(VALUE self, VALUE index);
VALUE intersys_query_get_data(VALUE self, VALUE index);
VALUE intersys_query_fetch(VALUE self);
VALUE intersys_query_each(VALUE self);
VALUE intersys_query_close(VALUE self);
VALUE intersys_query_set_limit(VALUE self, VALUE limit);
VALUE intersys_query_get_limit(VALUE self);
VALUE intersys_query_set_offset(VALUE self, VALUE limit);
VALUE intersys_query_get_offset(VALUE self);

/******* Object functions *******/
VALUE intersys_object_s_allocate(VALUE klass);
/*
 * Second parameter is an array that can contain additional parameter "do_no_call_intersys_new_method".
 * When Qtrue - initializer will create empty object, otherwise - valid Cache new object.
 */
VALUE intersys_object_initialize(VALUE self, VALUE args);
// second argument is a array with class_name, may be a null
VALUE intersys_object_open_by_id(int argc, VALUE *argv, VALUE self);

/******* Properties, definitions, arguments, methods functions *******/
VALUE intersys_definition_s_allocate(VALUE klass);
VALUE intersys_definition_initialize(VALUE self, VALUE r_database, VALUE class_name, VALUE name);
VALUE intersys_definition_cache_type(VALUE self);
VALUE intersys_definition_name(VALUE self);
VALUE intersys_definition_in_name(VALUE self);
VALUE intersys_property_initialize(VALUE self, VALUE r_database, VALUE class_name, VALUE name, VALUE object);
VALUE intersys_property_get(VALUE self);
VALUE intersys_property_set(VALUE self, VALUE value);
VALUE intersys_method_initialize(VALUE self, VALUE r_database, VALUE class_name, VALUE name, VALUE object);
VALUE intersys_method_is_func(VALUE self);
VALUE intersys_method_is_class_method(VALUE self);
VALUE intersys_method_num_args(VALUE self);
VALUE intersys_method_each_argument(VALUE self);
VALUE intersys_method_call(VALUE self, VALUE args);
VALUE intersys_argument_initialize(VALUE self, VALUE r_database, VALUE class_name, VALUE name, VALUE r_method);
VALUE intersys_argument_default_value(VALUE self);
VALUE intersys_argument_is_by_ref(VALUE self);
VALUE intersys_argument_marshall_dlist(VALUE self, VALUE list);
VALUE intersys_argument_marshall_dlist_elem(VALUE self, VALUE elem);

// Private declarations. Not for public use
VALUE intersys_argument_set(VALUE self, VALUE obj);
VALUE intersys_method_extract_retval(VALUE self);

/******* Globals *******/
VALUE intersys_global_s_allocate(VALUE klass);
VALUE intersys_global_initialize(VALUE self, VALUE name);
VALUE intersys_global_get(int argc, VALUE* argv, VALUE self);
VALUE intersys_global_set(int argc, VALUE* argv, VALUE self);
VALUE intersys_global_delete(int argc, VALUE* argv, VALUE self);
VALUE intersys_global_name(VALUE self);

#define RUN(x) run((x), __FILE__, __LINE__)
#define QUERY_RUN(x) {int sql_code = 0; (x); run(sql_code, __FILE__, __LINE__);}

#ifdef RUBY_18
#  define STR(x) (RSTRING(x)->ptr)
#  define LEN(x) (RSTRING(x)->len)
#  define SET_STR_LEN(x, i) (RSTRING(x)->len = i)

#  define FLOAT(f) (RFLOAT(f)->value)

#  define ARRAY_LEN(a) (RARRAY(a)->len)
#  define ARRAY(a) (RARRAY(a)->ptr)
#else
#  define STR(x) (RSTRING_PTR(x))
#  define LEN(x) (RSTRING_LEN(x))
#  define SET_STR_LEN(x, i) (rb_str_set_len(x, i))

#  define FLOAT(f) (RFLOAT_VALUE(f))

#  define ARRAY(a) (RARRAY_PTR(a))
#  define ARRAY_LEN(a) (RARRAY_LEN(a))
#endif

#define CALL(x, method) (rb_funcall((x), rb_intern(method), 0))

#define WCHARSTR(x) ((wchar_t *)STR(x))

#define FROMWCHAR(x) (rb_funcall((x), rb_intern("from_wchar"), 0))
#define TOWCHAR(x) (rb_funcall((x), rb_intern("to_wchar"), 0))

#define FROMWCSTR(x) (FROMWCHAR(rb_wcstr_new2(x))) // From wchar_t* -> VALUE with utf8
#define CLASS_NAME(x) WCHARSTR((x)->class_name)  // from object description -> wchar_t*

#endif /* __cache_ruby */
