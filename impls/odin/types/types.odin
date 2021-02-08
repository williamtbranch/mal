package types

symbol :: distinct string;
nil_type :: distinct bool;

// the zero value of a union is "nil"
// v: MalType = "hello"
// value := v.(string) // type assert that 'v' is a string
// Mal types are integer, symbol, nil, true, false, string
MalType :: union {
    int, symbol, bool, string, MalList, nil_type,
}

MalList :: [dynamic]MalType;