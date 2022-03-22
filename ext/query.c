#include "intersys.h"

#ifdef __CYGWIN__
#include <windef.h>
#endif
#include <sql.h>
#include <sqlext.h>
#include <sqlucode.h>

static void query_close(struct rbQuery* query) {
  if(!query->closed) {
		RUN(cbind_query_close(query->query));
		query->closed = 1;
  }
}

void intersys_query_free(struct rbQuery* query) {
	if(!query->closed) {
		query_close(query);
    if(query->executed) {
      RUN(cbind_free_query(query->query));
    }
  }
  xfree(query);
}

VALUE intersys_query_s_allocate(VALUE klass) {
	struct rbQuery* query = ALLOC(struct rbQuery);
	bzero(query, sizeof(struct rbQuery));
	return Data_Wrap_Struct(klass, 0, intersys_query_free, query);
}

VALUE intersys_query_initialize(VALUE self, VALUE database, VALUE sql_query) {
	struct rbQuery* query;
	struct rbDatabase* base;
	int sql_code;
	Data_Get_Struct(self, struct rbQuery, query);
	Data_Get_Struct(database, struct rbDatabase, base);
	query->limit = -1;
  query->closed = 0;
  query->executed = 0;

  int result = cbind_alloc_query(base->database, &query->query);

  // sometimes query allocation return 460 error that mean just "regular error"
  // I don't know why this happening (almost after ~500 queries) so here is a dirty hack for this
  // try to reconnect if get an 460 and allocate query once again
  if( result == 460 ) {
    rb_funcall(database, rb_intern("reconnect!"), 0);

    RUN(cbind_query_close(query->query));
    RUN(cbind_alloc_query(base->database, &query->query));
  } else {
    // just raise an exception if we have an error
    run(result, __FILE__, __LINE__);
  }
  rb_iv_set(self, "@database", database);
  RUN(cbind_prepare_gen_query(query->query, WCHARSTR(TOWCHAR(sql_query)), &sql_code));
	return self;
}

static void query_bind_one_param(h_query query, int index, VALUE obj) {
	int sql_type;
  RUN(cbind_query_get_par_sql_type(query, index, &sql_type));

  switch (sql_type) {
    case SQL_CHAR:
    case SQL_VARCHAR:
    case SQL_LONGVARCHAR: {
      VALUE str = rb_funcall(obj, rb_intern("to_s"), 0);
      RUN(cbind_query_set_mb_str_par(query, index, STR(str), LEN(str)));
      break;
    }
    case SQL_BINARY:
    case SQL_LONGVARBINARY:
    case SQL_VARBINARY: {
      VALUE str = rb_funcall(obj, rb_intern("to_s"), 0);
      RUN(cbind_query_set_bin_par(query, index, STR(str), LEN(str)));
      break;
    }
    case SQL_TINYINT:
    case SQL_SMALLINT:
    case SQL_INTEGER:
    case SQL_BIGINT:
    case SQL_BIT: { // TODO: implment SQL_BIT convert to boolean when need
      VALUE num = rb_funcall(obj, rb_intern("to_i"), 0);
      RUN(cbind_query_set_int_par(query, index, NUM2INT(num)));
      break;
    }
    case SQL_FLOAT:
    case SQL_DOUBLE:
    case SQL_REAL:
    case SQL_NUMERIC:
    case SQL_DECIMAL: {
      VALUE f = rb_funcall(obj, rb_intern("to_f"), 0);
      RUN(cbind_query_set_double_par(query, index, FLOAT(f)));
      break;
    }
    case SQL_TIME: { // TODO: i don't know where this function can be used, so check this when need
      int hour = NUM2INT(CALL(obj, "hour"));
      int minute = NUM2INT(CALL(obj, "min"));
      int second = NUM2INT(CALL(obj, "sec"));
      RUN(cbind_query_set_time_par(query, index, hour, minute, second));
      break;
    }
    case SQL_DATE: {
      int year = NUM2INT(CALL(obj, "year"));
      int month = NUM2INT(CALL(obj, "month"));
      int day = NUM2INT(CALL(obj, "day"));
      RUN(cbind_query_set_date_par(query, index, year, month, day));
      break;
    }
    case SQL_TIMESTAMP: {
      int year = NUM2INT(CALL(obj, "year"));
      int month = NUM2INT(CALL(obj, "month"));
      int day = NUM2INT(CALL(obj, "day"));
      int hour = NUM2INT(CALL(obj, "hour"));
      int minute = NUM2INT(CALL(obj, "min"));
      int second = NUM2INT(CALL(obj, "sec"));
      int fraction = 0;
      RUN(cbind_query_set_timestamp_par(query, index,
                                        year, month, day, hour, minute, second, fraction));
      break;
    }
    default: {
      rb_raise(cMarshallError, "unknown sql type %d for parameter N %d", sql_type, index);
    }
  }
}


VALUE intersys_query_bind_params(VALUE self, VALUE params) {
	int i;
	struct rbQuery* query;
	Check_Type(params, T_ARRAY);
	Data_Get_Struct(self, struct rbQuery, query);

	for(i = 0; i < ARRAY_LEN(params); i++) {
		query_bind_one_param(query->query, i+1, ARRAY(params)[i]);
	}
	return self;
}

VALUE intersys_query_execute(VALUE self) {
	struct rbQuery* query;
	int sql_code;
	int res;
	Data_Get_Struct(self, struct rbQuery, query);
	RUN(cbind_query_execute(query->query, &sql_code));
  RUN(cbind_query_get_num_pars(query->query, &res));
	query->executed = 1;
	return self;
}


VALUE intersys_query_get_data(VALUE self, VALUE index) {
	struct rbQuery* query;
	int type = 0;
	bool_t is_null;
	Data_Get_Struct(self, struct rbQuery, query);

	RUN(cbind_query_get_col_sql_type(query->query, FIX2INT(index), &type));

	switch(type) {
    case SQL_CHAR:
    case SQL_VARCHAR:
    case SQL_LONGVARCHAR:
    case SQL_WCHAR:
    case SQL_WVARCHAR:
    case SQL_WLONGVARCHAR: {
      wchar_t buf[32767];
      int size;

      RUN(cbind_query_get_uni_str_data(query->query, buf, sizeof(buf), &size, &is_null));

      if (is_null || size < 0) {
        return Qnil;
      }

      return FROMWCSTR(buf);
    }
    case SQL_BINARY:
    case SQL_LONGVARBINARY:
    case SQL_VARBINARY: {
      char buf[32767];
      int size;

      RUN(cbind_query_get_bin_data(query->query, buf, sizeof(buf), &size, &is_null));

      if (is_null || size < 0) {
        return Qnil;
      }

      return rb_str_new(buf, size);
    }
    case SQL_BIT: {
      int res;

      RUN(cbind_query_get_int_data(query->query, &res, &is_null));

      if (is_null) {
        return Qnil;
      }

      return res ? Qtrue : Qfalse;
    }
    case SQL_TINYINT:
    case SQL_SMALLINT:
    case SQL_INTEGER:
    case SQL_BIGINT: {
      int res;

      RUN(cbind_query_get_int_data(query->query, &res, &is_null));

      if (is_null) {
        return Qnil;
      }

      return INT2NUM(res);
    }
    case SQL_FLOAT:
    case SQL_DOUBLE:
    case SQL_REAL:
    case SQL_NUMERIC:
    case SQL_DECIMAL: {
      double res;

      RUN(cbind_query_get_double_data(query->query, &res, &is_null));

      if (is_null) {
        return Qnil;
      }

      return rb_float_new(res);
    }
    case SQL_DATE: { // CHECK: check converting to Ruby
      int year, month, day;

      RUN(cbind_query_get_date_data(query->query, &year, &month, &day, &is_null));

      if (is_null) {
        return Qnil;
      }

      return rb_funcall(cDate, rb_intern("civil"), 3, INT2FIX(year), INT2FIX(month), INT2FIX(day));
    }
    case SQL_TIME: {
      int hour, minute, second;

      RUN(cbind_query_get_time_data(query->query, &hour, &minute, &second, &is_null));

      return is_null ? Qnil : time_to_string(hour, minute, second);
    }
    case SQL_TIMESTAMP: {
      int year, month, day, hour, minute, second, fraction;

      RUN(cbind_query_get_timestamp_data(query->query, &year, &month, &day, &hour, &minute, &second, &fraction, &is_null));

      if (is_null) {
        return Qnil;
      }

      return rb_funcall(rb_cTime, rb_intern("local"), 7,
                        INT2FIX(year), INT2FIX(month), INT2FIX(day), INT2FIX(hour), INT2FIX(minute), INT2FIX(second), INT2FIX(fraction));
    }
    default: {
      rb_warn("UNKNOW SQL TYPE %d. Replaced with Nil", type);
      return Qnil;
    }
	}
}

VALUE intersys_query_column_count(VALUE self) {
  struct rbQuery* query;
  Data_Get_Struct(self, struct rbQuery, query);
  int num_cols;
  RUN(cbind_query_get_num_cols(query->query, &num_cols));
  return INT2FIX(num_cols);
}

VALUE intersys_query_column_name(VALUE self, VALUE i) {
	struct rbQuery* query;
	Data_Get_Struct(self, struct rbQuery, query);
	int len;
	const wchar_t *res;
	RUN(cbind_query_get_col_name_len(query->query, FIX2INT(i), &len));
	RUN(cbind_query_get_col_name(query->query, FIX2INT(i), &res));
	return FROMWCSTR(res);
}

VALUE intersys_query_fetch(VALUE self) {
	struct rbQuery* query;
	VALUE data = Qnil;
	Data_Get_Struct(self, struct rbQuery, query);
	int num_cols = 0;
	int i = 0;
	int sql_code;

	RUN(cbind_query_fetch(query->query, &sql_code));

	data = rb_ary_new();

	if(sql_code == 100) {
		query_close(query);
		return Qnil;
	}
	if(sql_code) {
		return Qnil;
    //	rb_raise(rb_eStandardError, "Error in SQL: %d", sql_code);
	}

	RUN(cbind_query_get_num_cols(query->query, &num_cols));
	for(i = 0; i < num_cols; i++) {
		rb_ary_push(data, rb_funcall(self, rb_intern("get_data"), 1, INT2FIX(i+1)));
	}
	return data;
}


VALUE intersys_query_each(VALUE self) {
	struct rbQuery* query;
	Data_Get_Struct(self, struct rbQuery, query);

  int i;
	// skip offset records
  // TODO: optimize rows skiping
	if(query->offset > 0) {
		for(i = 0; i < query->offset; i++) {
			if(intersys_query_fetch(self) == Qnil) {
				break;
			}
		}
	}

	int row_count = 0;
	int limit = query->limit > 0 ? query->limit : -1;
	while(1) {
		VALUE row = intersys_query_fetch(self);
		if(row == Qnil || row_count == limit) {
			break;
		}
		rb_yield(row);
		row_count++;
	}

	query_close(query);
	return self;
}

VALUE intersys_query_close(VALUE self) {
	struct rbQuery* query;
	Data_Get_Struct(self, struct rbQuery, query);
	query_close(query);
	return self;
}


VALUE intersys_query_set_limit(VALUE self, VALUE limit) {
	struct rbQuery* query;
	Data_Get_Struct(self, struct rbQuery, query);
	query->limit = NUM2INT(rb_funcall(limit, rb_intern("to_i"), 0));
	return limit;
}
VALUE intersys_query_get_limit(VALUE self) {
	struct rbQuery* query;
	Data_Get_Struct(self, struct rbQuery, query);
	return INT2FIX(query->limit);
}

VALUE intersys_query_set_offset(VALUE self, VALUE offset) {
	struct rbQuery* query;
	Data_Get_Struct(self, struct rbQuery, query);
	query->offset = NUM2INT(rb_funcall(offset, rb_intern("to_i"), 0));
	return offset;
}

VALUE intersys_query_get_offset(VALUE self) {
	struct rbQuery* query;
	Data_Get_Struct(self, struct rbQuery, query);
	return INT2FIX(query->offset);
}
