// Copyright 2025 The Accumulate Authors
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

package backends

import (
	"io"
	"path/filepath"

	"gitlab.com/accumulatenetwork/accumulate/tools/internal/typegen"
)

// LanguageBackend defines the interface for generating client code in different languages
type LanguageBackend interface {
	// EmitClient generates the main client code for the API
	EmitClient(api *TApi, w io.Writer) error

	// EmitTypes generates type definitions if needed by the language
	EmitTypes(types *TTypes, w io.Writer) error

	// GetFileExtension returns the file extension for generated files
	GetFileExtension() string

	// GetClientFileName returns the filename for the main client file
	GetClientFileName() string

	// GetTypesFileName returns the filename for the types file
	GetTypesFileName() string

	// GetAdditionalFiles returns any additional files that need to be generated
	// (e.g., package.json, Cargo.toml, pubspec.yaml)
	GetAdditionalFiles() []AdditionalFile

	// GetOutputStructure returns the recommended directory structure
	GetOutputStructure() OutputStructure
}

// AdditionalFile represents a non-source file that needs to be generated
type AdditionalFile struct {
	Path     string // Relative path from output directory
	Template string // Template content
	Data     interface{} // Data to pass to template
}

// OutputStructure describes the directory layout for generated code
type OutputStructure struct {
	ClientDir string   // Directory for client source files
	TypesDir  string   // Directory for type definitions
	ExtraDir  []string // Additional directories to create
}

// TApi represents the API model for template generation
type TApi struct {
	Package     string
	ApiPath     string
	Methods     []*TMethod
	APIVersion  string // "v2", "v3", or "both"
	PackageName string // Language-specific package name
	ModuleName  string // Language-specific module name
}

// TMethod represents an API method for template generation
type TMethod struct {
	typegen.Method
	Name       string
	SubPackage string
	Version    string // "v2", "v3", or empty for legacy
}

// TTypes represents the type system for template generation
type TTypes struct {
	Package string
	Types   []*TType
	Enums   []*TEnum
}

// TType represents a type definition
type TType struct {
	Name   string
	Fields []*TField
}

// TField represents a field in a type
type TField struct {
	Name     string
	Type     string
	Optional bool
	List     bool
}

// TEnum represents an enumeration
type TEnum struct {
	Name   string
	Values []TEnumValue
}

// TEnumValue represents an enum value
type TEnumValue struct {
	Name  string
	Value interface{}
}

// BackendRegistry manages available language backends
type BackendRegistry struct {
	backends map[string]LanguageBackend
}

// NewBackendRegistry creates a new backend registry with all available backends
func NewBackendRegistry() *BackendRegistry {
	registry := &BackendRegistry{
		backends: make(map[string]LanguageBackend),
	}

	// Register all available backends
	registry.Register("dart", NewDartBackend())
	registry.Register("python", NewPythonBackend())
	registry.Register("rust", NewRustBackend())
	registry.Register("go", NewGoBackend()) // Keep existing Go support

	return registry
}

// Register adds a new backend to the registry
func (r *BackendRegistry) Register(name string, backend LanguageBackend) {
	r.backends[name] = backend
}

// Get retrieves a backend by name
func (r *BackendRegistry) Get(name string) (LanguageBackend, bool) {
	backend, exists := r.backends[name]
	return backend, exists
}

// List returns all available backend names
func (r *BackendRegistry) List() []string {
	names := make([]string, 0, len(r.backends))
	for name := range r.backends {
		names = append(names, name)
	}
	return names
}

// Helper functions for common operations

// SafeFileName converts a string to a safe filename
func SafeFileName(name string) string {
	return filepath.Base(name)
}

// TypeMappings provides common type mappings between Go and target languages
var TypeMappings = map[string]map[string]string{
	"dart": {
		"string":    "String",
		"int":       "int",
		"uint":      "int",
		"uint32":    "int",
		"uint64":    "int",
		"int32":     "int",
		"int64":     "int",
		"bool":      "bool",
		"float64":   "double",
		"float32":   "double",
		"[]byte":    "Uint8List",
		"time.Time": "DateTime",
	},
	"python": {
		"string":    "str",
		"int":       "int",
		"uint":      "int",
		"uint32":    "int",
		"uint64":    "int",
		"int32":     "int",
		"int64":     "int",
		"bool":      "bool",
		"float64":   "float",
		"float32":   "float",
		"[]byte":    "bytes",
		"time.Time": "datetime.datetime",
	},
	"rust": {
		"string":    "String",
		"int":       "i64",
		"uint":      "u64",
		"uint32":    "u32",
		"uint64":    "u64",
		"int32":     "i32",
		"int64":     "i64",
		"bool":      "bool",
		"float64":   "f64",
		"float32":   "f32",
		"[]byte":    "Vec<u8>",
		"time.Time": "chrono::DateTime<chrono::Utc>",
	},
}

// MapType maps a Go type to the target language equivalent
func MapType(goType, targetLang string) string {
	if mappings, exists := TypeMappings[targetLang]; exists {
		if mapped, found := mappings[goType]; found {
			return mapped
		}
	}
	return goType // Default to original type if no mapping found
}