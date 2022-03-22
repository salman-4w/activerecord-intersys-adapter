#include "intersys.h"

static void intersys_base_real_close(struct rbDatabase* base) {
	if(base->closed) return;
	base->closed = 1;
	RUN(cbind_free_db(base->database));
	RUN(cbind_free_conn(base->connection));
}

void intersys_base_free(struct rbDatabase* base) {
	intersys_base_real_close(base);
	xfree(base);
}

VALUE intersys_base_s_allocate(VALUE klass) {
	struct rbDatabase* intersys_base = ALLOC(struct rbDatabase);
	memset(intersys_base, 0, sizeof(struct rbDatabase));
	return Data_Wrap_Struct(klass, 0, intersys_base_free, intersys_base);
}

VALUE intersys_base_initialize(VALUE self, VALUE options) {
	rb_iv_set(self, "@options", options);
	
	VALUE initialize_time = rb_funcall(rb_cTime, rb_intern("now"), 0);
	rb_cv_set(CLASS_OF(self), "@@last_query_at", rb_funcall(initialize_time, rb_intern("to_i"), 0));

	return rb_funcall(self, rb_intern("connect"), 1, options);
}

static VALUE connect_get_options(VALUE options, char *opt_name, char *opt_default, int convert) {
	VALUE res = rb_hash_aref(options, ID2SYM(rb_intern(opt_name)));
	if(res == Qnil) {
		res = rb_str_new2(opt_default);
	}
	if(convert) {
		return rb_funcall(res, rb_intern("to_wchar"), 0);	
	}
	return res;
}

VALUE intersys_base_connect(VALUE self, VALUE options) {
	struct rbDatabase* base;
	char conn_str[256];
	wchar_t w_conn_str[256];
	int size;
	
	VALUE host, port, user, password, cache_namespace, timeout;

	host = connect_get_options(options, "host", "localhost", 0);
	port = connect_get_options(options, "port", "1972", 0);
	cache_namespace = connect_get_options(options, "namespace", "User", 0);
	
	user = connect_get_options(options, "user", "_SYSTEM", 1);
	password = connect_get_options(options, "password", "SYS", 1);
	timeout = rb_hash_aref(options, ID2SYM(rb_intern("timeout")));
	if (timeout == Qnil) {
		timeout = INT2FIX(30);
	}

	Data_Get_Struct(self, struct rbDatabase, base);

	snprintf(conn_str, sizeof(conn_str), "%s[%s]:%s", STR(host), STR(port), STR(cache_namespace));

	RUN(cbind_utf8_to_uni(conn_str, (byte_size_t)strlen(conn_str), w_conn_str, (char_size_t)sizeof(w_conn_str),&size));
	w_conn_str[size] = 0;

  wcscpy(base->connection_string, w_conn_str);
  wcscpy(base->user, WCHARSTR(user));
  wcscpy(base->password, WCHARSTR(password));
  base->timeout = FIX2INT(timeout);
  
  RUN(cbind_alloc_conn(base->connection_string, base->user, base->password, base->timeout, &base->connection));

  RUN(cbind_alloc_db(base->connection, &base->database));
	
	return self;
}

VALUE intersys_base_reconnect(VALUE self) {
  struct rbDatabase* base;
  Data_Get_Struct(self, struct rbDatabase, base);

  RUN(cbind_free_db(base->database));
  RUN(cbind_free_conn(base->connection));

  RUN(cbind_alloc_conn(base->connection_string, base->user, base->password, base->timeout, &base->connection));
  RUN(cbind_alloc_db(base->connection, &base->database));

  // update last_query_at value to keep connection alive
  VALUE reconnect_time = rb_funcall(rb_cTime, rb_intern("now"), 0);
  rb_cv_set(CLASS_OF(self), "@@last_query_at", rb_funcall(reconnect_time, rb_intern("to_i"), 0));

  // mark current database connection is alive
  rb_funcall(self, rb_intern("connection_restored!"), 0);

  // update Intersys::Object#database property to new actual value
  VALUE intersys_module_klass = rb_const_get(rb_cObject, rb_intern("Intersys"));
  VALUE object_klass = rb_const_get(intersys_module_klass, rb_intern("Object"));

  rb_iv_set(object_klass, "@database", self);
  
  // mark cached data dirty to reload cached objects, because oref is not valid anymore
  rb_funcall(object_klass, rb_intern("metadata_cache_was_dirty!"), 0);
  
  // check IntersysPreloaded existence and call "load_models!" method when defined
  // this method reread cache metadata for all models in Rails application
  if( rb_const_defined(rb_cObject, rb_intern("IntersysPreloader")) ) {
    VALUE intersys_preloader = rb_const_get(rb_cObject, rb_intern("IntersysPreloader"));
    rb_funcall(intersys_preloader, rb_intern("load_models!"), 0);
  }
  return self;
}

VALUE intersys_base_close(VALUE self) {
	struct rbDatabase* base;
	Data_Get_Struct(self, struct rbDatabase, base);
	intersys_base_real_close(base);
	return Qtrue;
}


VALUE intersys_base_start(VALUE self) {
	struct rbDatabase* base;
	Data_Get_Struct(self, struct rbDatabase, base);
	RUN(cbind_tstart(base->database));
	return self;
}

VALUE intersys_base_commit(VALUE self) {
	struct rbDatabase* base;
	Data_Get_Struct(self, struct rbDatabase, base);
	RUN(cbind_tcommit(base->database));
	return self;
}

VALUE intersys_base_rollback(VALUE self) {
	struct rbDatabase* base;
	Data_Get_Struct(self, struct rbDatabase, base);
	RUN(cbind_trollback(base->database));
	return self;
}

VALUE intersys_base_level(VALUE self) {
	struct rbDatabase* base;
	int level;
	Data_Get_Struct(self, struct rbDatabase, base);
	RUN(cbind_tlevel(base->database, &level));
	return INT2FIX(level);
}
