// Copyright 2025 The Accumulate Authors
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

package backends

import (
	_ "embed"
	"io"
	"strings"
	"text/template"
)

//go:embed templates/dart_client.dart.tmpl
var dartClientTemplate string

//go:embed templates/dart_types.dart.tmpl
var dartTypesTemplate string

//go:embed templates/pubspec.yaml.tmpl
var dartPubspecTemplate string

// DartBackend implements LanguageBackend for Dart
type DartBackend struct {
	clientTemplate  *template.Template
	typesTemplate   *template.Template
	pubspecTemplate *template.Template
}

// NewDartBackend creates a new Dart backend
func NewDartBackend() *DartBackend {
	funcMap := template.FuncMap{
		"dartType":      mapDartType,
		"camelCase":     camelCase,
		"snakeCase":     snakeCase,
		"dartClassName": dartClassName,
		"dartMethodName": dartMethodName,
	}

	clientTmpl := template.Must(template.New("dart_client").Funcs(funcMap).Parse(dartClientTemplate))
	typesTmpl := template.Must(template.New("dart_types").Funcs(funcMap).Parse(dartTypesTemplate))
	pubspecTmpl := template.Must(template.New("pubspec").Funcs(funcMap).Parse(dartPubspecTemplate))

	return &DartBackend{
		clientTemplate:  clientTmpl,
		typesTemplate:   typesTmpl,
		pubspecTemplate: pubspecTmpl,
	}
}

// EmitClient generates Dart client code
func (d *DartBackend) EmitClient(api *TApi, w io.Writer) error {
	return d.clientTemplate.Execute(w, api)
}

// EmitTypes generates Dart type definitions
func (d *DartBackend) EmitTypes(types *TTypes, w io.Writer) error {
	return d.typesTemplate.Execute(w, types)
}

// GetFileExtension returns the file extension for Dart files
func (d *DartBackend) GetFileExtension() string {
	return ".dart"
}

// GetClientFileName returns the filename for the Dart client
func (d *DartBackend) GetClientFileName() string {
	return "lib/accumulate_client.dart"
}

// GetTypesFileName returns the filename for Dart types
func (d *DartBackend) GetTypesFileName() string {
	return "lib/types.dart"
}

// GetAdditionalFiles returns additional files for Dart
func (d *DartBackend) GetAdditionalFiles() []AdditionalFile {
	return []AdditionalFile{
		{
			Path:     "pubspec.yaml",
			Template: dartPubspecTemplate,
		},
		{
			Path:     "lib/src/json_rpc_client.dart",
			Template: dartJsonRpcClientTemplate,
		},
	}
}

// GetOutputStructure returns the directory structure for Dart
func (d *DartBackend) GetOutputStructure() OutputStructure {
	return OutputStructure{
		ClientDir: "lib",
		TypesDir:  "lib",
		ExtraDir:  []string{"lib/src"},
	}
}

// Helper functions for Dart generation

func mapDartType(goType string) string {
	return MapType(goType, "dart")
}

func camelCase(s string) string {
	if s == "" {
		return s
	}
	return strings.ToLower(s[:1]) + s[1:]
}

func snakeCase(s string) string {
	var result strings.Builder
	for i, r := range s {
		if i > 0 && r >= 'A' && r <= 'Z' {
			result.WriteRune('_')
		}
		result.WriteRune(r)
	}
	return strings.ToLower(result.String())
}

func dartClassName(s string) string {
	return strings.Title(s)
}

func dartMethodName(s string) string {
	return camelCase(s)
}

//go:embed templates/dart_json_rpc_client.dart.tmpl
var dartJsonRpcClientTemplate string