package types

symbol :: distinct string;

// the zero value of a union is "nil"
// v: MalType = "hello"
// value := v.(string) // type assert that 'v' is a string
// Mal types are integer, symbol, nil, true, false, string
MalType :: union {
    int, symbol, bool, string, MalList,
}

MalList :: [dynamic]MalType;