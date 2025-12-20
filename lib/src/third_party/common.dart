import 'common.g.dart' as native;

typedef LogLevel = int; // Fallback if enum is missing, or fix ffigen?
// Actually, check common.g.dart first.
typedef Error = native.Error;
typedef Result = native.Result;
typedef Type = native.Type;
typedef ResultUnion = native.ResultUnion;
typedef LogCallback = void Function(String msg);
