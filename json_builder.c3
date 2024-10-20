module json_builder;
import std::core::mem;
import libc;

fn usz strlen(char* s) 
{
    usz n = 0;

    while(s[n]) ++n;

    return n;
}

struct JsonBuilder {
    DString data;
    JsonContext ctx;
}

struct JsonContext {
    bool last_added_is_key;
    bool is_array_open;
    bool is_map_open;
    bool is_root;
    bool is_map_root;
    bool is_array_root;
}

fn JsonBuilder* new_json_builder() {
    JsonBuilder* json_builder = std::core::mem::new(JsonBuilder);
    json_builder.data = std::core::dstring::new();
    json_builder.ctx.is_root = true;
    json_builder.ctx.is_array_open = false;
    json_builder.ctx.is_map_open = false;
    json_builder.ctx.last_added_is_key = false;
    json_builder.ctx.is_array_root = false;
    json_builder.ctx.is_map_root = false;
    return json_builder;
}

fn JsonBuilder* JsonBuilder.add_key(&self, String data) {
    self.iadd_key(data);
    return self;
}

fn void JsonBuilder.add_dstring(&self, DString data) {
    if (!self.ctx.last_added_is_key) return;
    self.iadd_string(data.str_view());
}

fn void JsonBuilder.add_char(&self, char data) {
    if (!self.ctx.last_added_is_key) return;
    self.iadd_char(data);
}

fn void JsonBuilder.add_string(&self, String data) {
    if (!self.ctx.last_added_is_key) return;
    self.iadd_string(data);
}

fn void JsonBuilder.add_number(&self, double data) {
    if (!self.ctx.last_added_is_key) return;
    self.iadd_number(data);
}

fn void JsonBuilder.add_bool(&self, bool data) {
    if (!self.ctx.last_added_is_key) return;
    self.iadd_bool(data);
}

fn void JsonBuilder.add_null(&self, any* data) {
    if (!self.ctx.last_added_is_key) return;
    self.iadd_null();
}

fn void JsonBuilder.map_start(&self) {
    if (!self.ctx.last_added_is_key) {
        if (!self.ctx.is_array_open) {
            if (!self.ctx.is_root) {
                return;
            } else {
                self.ctx.is_root = false;
                self.ctx.is_map_root = true;
            }
        }
    }
    self.data.append('{');
    self.ctx.last_added_is_key = false;
    self.ctx.is_map_open = true;
}

fn void JsonBuilder.map_finish(&self) {
    if (self.ctx.last_added_is_key) return;
    if (!self.ctx.is_map_open) {
        if (!self.ctx.is_map_root) {
            return;   
        }
    }
    self.data.delete(self.data.len() - 1);
    self.data.append_chars("},");
    self.ctx.last_added_is_key = false;
    self.ctx.is_map_open = false;
}

fn void JsonBuilder.array_start(&self) {
    if (!self.ctx.is_root) {
        if (!self.ctx.last_added_is_key) {
            return;
        }
    } else {
        self.ctx.is_root = false;
        self.ctx.is_array_root = true;
    }
    self.ctx.is_array_open = true;
    self.data.append('[');
    self.ctx.last_added_is_key = false;
}

fn void JsonBuilder.array_finish(&self) {
    if (!self.ctx.is_array_open) {
        if (!self.ctx.is_array_root) {
            return;   
        }
    }
    self.data.delete(self.data.len() - 1);
    self.data.append_chars("],");
    self.ctx.last_added_is_key = false;
    self.ctx.is_array_open = false;
}

fn void JsonBuilder.iadd_key(&self, String data) {
    self.data.append_char('"');
    self.data.append_chars(data);
    self.data.append_char('"');
    self.data.append_char(':');
    self.ctx.last_added_is_key = true;
}

fn void JsonBuilder.iadd_number(&self, double data) {
    char[32] number_str;
    libc::sprintf(&number_str, "%g", data);
    self.data.write_bytes((String)&(number_str), strlen((ZString)&(number_str)));
    self.data.append_char(',');
    self.ctx.last_added_is_key = false;
}

fn void JsonBuilder.iadd_string(&self, String data) {
    self.data.append_char('"');
    self.data.append_chars(data);
    self.data.append_char('"');
    self.data.append(',');
    self.ctx.last_added_is_key = false;
}

fn void JsonBuilder.iadd_char(&self, char data) {
    self.data.append_char('"');
    self.data.append_char(data);
    self.data.append_char('"');
    self.data.append_char(',');
    self.ctx.last_added_is_key = false;
}

fn void JsonBuilder.iadd_null(&self) {
    self.data.append_chars("null");
    self.data.append_char(',');
    self.ctx.last_added_is_key = false;
}

fn void JsonBuilder.iadd_bool(&self, bool data) {
    if (data) {
        self.data.append_chars("true");
    } else {
        self.data.append_chars("false");
    }
    self.data.append_char(',');
    self.ctx.last_added_is_key = false;
}

fn String JsonBuilder.to_string(&self) {
    self.data.delete(self.data.len() - 1);
    if (!self.data.str_view().ends_with("}") && !self.data.str_view().ends_with("]") && self.data.str_view()[self.data.str_view().len-1] != '"') {
        // invalid json
        return "";
    }
    return self.data.str_view();
}

fn void DString.write_bytes(&self, char[] buffer, usz size) {
    for(usz i = 0; i < size; i++) {
        self.write_byte(buffer[i])!!;
    }
}