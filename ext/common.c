#include "intersys.h"

VALUE string_to_wchar(VALUE self) {
	VALUE result;
	int size;
	result = rb_str_buf_new((LEN(self)+1)*sizeof(wchar_t));
	memset(STR(result), 0, (LEN(self)+1)*sizeof(wchar_t) + 1);
	RUN(cbind_utf8_to_uni(STR(self), (byte_size_t)LEN(self), WCHARSTR(result), (char_size_t)sizeof(wchar_t)*LEN(self), &size));
	WCHARSTR(result)[size] = 0;

	SET_STR_LEN(result, (size + 1) * sizeof(wchar_t));

	OBJ_FREEZE(result);
	return result;
}

VALUE string_from_wchar(VALUE self) {
	VALUE result;
	int size;
	if(LEN(self) == 0 || !STR(self)) {
		return rb_str_new2("");
	}
	result = rb_str_buf_new(LEN(self));
	memset(STR(result), 0, LEN(self) + 1);
	RUN(cbind_uni_to_utf8(WCHARSTR(self), (char_size_t)wcslen(WCHARSTR(self)), STR(result), LEN(self), &size));

	SET_STR_LEN(result, size);

	return result;
}

int run(int err, char *file, int line) {
	if (err > 0) {
		VALUE errorType;
		if( err == 12104 || err == 461 ) {
			errorType = cConnectionError;
		} else {
			errorType = cIntersysException;
		}
		
		rb_raise(errorType, "Intersystems Cache error %d: %s in file %s: %d", err, cbind_get_last_err_msg(), file, line);
	}
	return err;
}

VALUE wcstr_new(const wchar_t *w_str, const char_size_t len) {
	VALUE result;
	int size, capa;
	if(!w_str) {
		return rb_funcall(rb_str_new2(""), rb_intern("to_wchar"), 0);
	}
	size = (int)(len)*sizeof(wchar_t);
	capa = (int)(len + 1)*sizeof(wchar_t);
	
  result = rb_str_buf_new(capa);
	memset(STR(result) + size, 0, capa-size);
	rb_str_buf_cat(result, (char *)w_str, size);

	rb_str_freeze(result);
	return result;
}

VALUE rb_wcstr_new(const wchar_t *w_str, const char_size_t len) {
	return wcstr_new(w_str, len);
}

VALUE rb_wcstr_new2(const wchar_t *w_str) {
	return wcstr_new(w_str, w_str ? wcslen(w_str) : -1);
}

static void intersys_status_mark(struct rbStatus* status) {
	rb_gc_mark(status->message);
}

VALUE intersys_status_s_allocate(VALUE klass) {
	struct rbStatus* status = ALLOC(struct rbStatus);
	memset(status, 0, sizeof(struct rbStatus));
	return Data_Wrap_Struct(klass, intersys_status_mark, 0, status);
}

VALUE intersys_status_initialize(VALUE self, VALUE code, VALUE message) {
	struct rbStatus* status;
	Data_Get_Struct(self, struct rbStatus, status);
	status->code = code;
	status->message = message;
	rb_call_super(1, &message);
	return self;
}

VALUE intersys_status_code(VALUE self) {
	struct rbStatus* status;
	Data_Get_Struct(self, struct rbStatus, status);
	return status->code;
}

VALUE intersys_status_message(VALUE self) {
	struct rbStatus* status;
	Data_Get_Struct(self, struct rbStatus, status);
	return status->message;
}

VALUE intersys_status_to_s(VALUE self) {
	struct rbStatus* status;
	Data_Get_Struct(self, struct rbStatus, status);
	return status->message;
}

VALUE time_to_string(int hours, int minutes, int seconds) {
	char buf[9];
	sprintf(buf, "%2u:%2u:%2u", hours, minutes, seconds);

	// string should be in format "00:00:00"
	if (' ' == buf[0]) {
		buf[0] = '0';
	}
	if (' ' == buf[3]) {
		buf[3] = '0';
	}
	if (' ' == buf[6]) {
		buf[6] = '0';
	}

	return rb_str_new2(buf);
}
