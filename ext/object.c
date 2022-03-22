#include "intersys.h"

static void intersys_object_free(struct rbObject* object) {
	if (object->oref > 0) {
		RUN(cbind_object_release(object->database, object->oref));
	}
	xfree(object);
}

static void intersys_object_mark(struct rbObject* object) {
	rb_gc_mark(object->class_name);
}


VALUE intersys_object_s_allocate(VALUE klass) {
	struct rbObject* object = ALLOC(struct rbObject);
	memset(object, 0, sizeof(struct rbObject));
	return Data_Wrap_Struct(klass, intersys_object_mark, intersys_object_free, object);
}

VALUE intersys_object_initialize(VALUE self, VALUE args) {
  struct rbObject* object;
	Data_Get_Struct(self, struct rbObject, object);

	VALUE database = rb_funcall(rb_obj_class(self), rb_intern("database"), 0);
	VALUE class_name;
  if( ARRAY_LEN(args) < 2 ) {
    class_name = rb_funcall(rb_obj_class(self), rb_intern("class_name"), 0);
  } else {
    class_name = rb_ary_entry(args, 1);
  }

  VALUE readonly;

  if( ARRAY_LEN(args) == 0 || rb_ary_entry(args, 0) == Qfalse ) {
    readonly = Qfalse;

    // =========================
    // TODO: call Intersys::Object.register_name! here
    /* VALUE intersys_module_klass = rb_const_get(rb_cObject, rb_intern("Intersys")); */
    /* VALUE object_klass = rb_const_get(intersys_module_klass, rb_intern("Object")); */

    /* rb_funcall(object_klass, rb_intern("register_name!"), 2, class_name, rb_funcall(self, rb_intern("class"), 0)); */
    // =========================

		VALUE method_new;
    method_new = rb_obj_alloc(cMethod);
    rb_funcall(method_new, rb_intern("initialize"), 4, database, class_name, rb_str_new2("%New"), object);
    VALUE result = rb_funcall(method_new, rb_intern("call!"), 1, rb_ary_new2(0));
    struct rbObject* result_object;
		Data_Get_Struct(result, struct rbObject, result_object);

		MEMCPY(object, result_object, struct rbObject, 1);
	} else {
    readonly = Qtrue;

		struct rbDatabase* base;

		Data_Get_Struct(database, struct rbDatabase, base);

		object->database = base->database;
	}

  object->class_name = TOWCHAR(class_name);
  rb_iv_set(self, "@class_name", class_name);
  rb_iv_set(self, "@readonly", readonly);
  return self;
}

VALUE intersys_object_open_by_id(int argc, VALUE *argv, VALUE self) {
  if( argc == 0 ) {
    rb_raise(rb_eArgError, "Object ID required");
  }

  int concurrency = NUM2INT(rb_funcall(self, rb_intern("concurrency"), 0));
	int timeout = NUM2INT(rb_funcall(self, rb_intern("timeout"), 0));
	int error;
  VALUE id = rb_funcall(argv[0], rb_intern("to_s"), 0);
	struct rbObject* object;

  VALUE class_name;
  VALUE r_object;

  if( argc == 1 ) {
    r_object = rb_funcall(self, rb_intern("new"), 1, Qfalse);
    Data_Get_Struct(r_object, struct rbObject, object);
    class_name = CLASS_NAME(object);
  } else {
    r_object = rb_funcall(self, rb_intern("new"), 2, Qfalse, argv[1]);
    Data_Get_Struct(r_object, struct rbObject, object);
    class_name = WCHARSTR(TOWCHAR(argv[1]));
  }

	error = cbind_openid(object->database, class_name, WCHARSTR(TOWCHAR(id)), concurrency, timeout, &object->oref);
	switch(error) {
    case 0: {
      return r_object;
    } case -9: {
      rb_raise(cObjectNotFound, "Object with id %s not found", STR(id));
      return Qnil;
    } default: {
      RUN(error);
      return Qnil;
    }
	}
	return r_object;
}
