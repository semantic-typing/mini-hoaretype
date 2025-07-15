exception ParseError of string
val parse_core : string -> Core_lang.program Core_lang.result
val parse_core_file : string -> Core_lang.program Core_lang.result
val parse_program : string -> Core_lang.program Core_lang.result
