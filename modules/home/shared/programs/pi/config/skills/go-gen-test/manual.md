# Stub Generation — Manual Mode

Generate stubs in the same format that `go-gen-test-all` produces.
Write the stubs directly into `<filename>_test.go`.

## Template: function

```go
func TestXxx(t *testing.T) {
    type args struct {
        // one field per parameter
    }
    tests := []struct {
        name    string
        args    args
        want    ReturnType
    }{
        // TODO: Add test cases.
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            if got := Xxx(tt.args.param); !reflect.DeepEqual(got, tt.want) {
                t.Errorf("Xxx() = %v, want %v", got, tt.want)
            }
        })
    }
}
```

## Template: method

```go
func TestType_Method(t *testing.T) {
    type fields struct {
        // one field per struct field
    }
    type args struct {
        // one field per parameter
    }
    tests := []struct {
        name    string
        fields  fields
        args    args
        wantErr bool
    }{
        // TODO: Add test cases.
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            x := &Type{
                field: tt.fields.field,
            }
            if err := x.Method(tt.args.ctx); (err != nil) != tt.wantErr {
                t.Errorf("Type.Method() error = %v, wantErr %v", err, tt.wantErr)
            }
        })
    }
}
```

## Notes

- Use `file-outline` (or read the source file) to enumerate exported functions and their signatures before writing stubs.
- Omit `reflect` import if not needed — replace `reflect.DeepEqual` with `assert.Equal` when `testify` is available.
- After writing all stubs, return to **Step 2** in `SKILL.md` to fill in the test cases.