package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"math"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
)

// Test/mock filename/path match keywords (lowercase). Skip on any match:
// - _test.go: Go test files
// - mock/fake/stub: common mock-generated code
// - testdata/fixtures: Go's official test data/sample dirs
var skipKeywords = []string{"mock", "fake", "stub", "testdata", "fixtures"}

// Static ignore dirs (dependencies/build/VCS etc.)
var skipDirs = map[string]bool{
	".git": true, ".venv": true, "venv": true, "node_modules": true,
	"vendor": true, "__pycache__": true, "data": true, ".idea": true,
	".vscode": true, "dist": true, "build": true, ".codebuddy": true,
}

// isTestOrMockPath determines whether a .go file is test/mock code and should be excluded from quality scanning.
func isTestOrMockPath(projectRoot, path string) bool {
	rel, err := filepath.Rel(projectRoot, path)
	if err != nil {
		return true
	}
	rel = filepath.ToSlash(rel)
	name := strings.ToLower(filepath.Base(rel))
	if strings.HasSuffix(name, "_test.go") {
		return true
	}
	parts := strings.Split(filepath.Dir(rel), "/")
	for _, p := range parts {
		pl := strings.ToLower(p)
		if skipDirs[pl] {
			return true
		}
		for _, kw := range skipKeywords {
			if pl == kw {
				return true
			}
		}
	}
	for _, kw := range skipKeywords {
		if strings.Contains(name, kw) {
			return true
		}
	}
	return false
}

// collectGoFiles collects all .go files in the project that should participate in quality scoring (tests/mock/dependencies excluded).
func collectGoFiles(projectPath string) ([]string, error) {
	var files []string
	err := filepath.Walk(projectPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() {
			name := strings.ToLower(info.Name())
			if skipDirs[name] {
				return filepath.SkipDir
			}
			for _, kw := range skipKeywords {
				if name == kw {
					return filepath.SkipDir
				}
			}
			return nil
		}
		if !strings.HasSuffix(strings.ToLower(info.Name()), ".go") {
			return nil
		}
		if isTestOrMockPath(projectPath, path) {
			return nil
		}
		files = append(files, path)
		return nil
	})
	return files, err
}

// MetricsCollector collects code size and complexity metrics
type MetricsCollector struct {
	ProjectPath string
	Metrics     *Metrics
}

// Metrics data structure
type Metrics struct {
	AvgCC             float64 `json:"avg_cc"`
	PeakCC            int     `json:"peak_cc"`
	CognitiveCC       float64 `json:"cognitive_cc"`
	SLOC              int     `json:"sloc"`
	AvgFunctionLength float64 `json:"avg_function_length"`
	LongFunctions     int     `json:"long_functions"`
	MI                float64 `json:"mi"`
	FunctionCount     int     `json:"function_count"`
}

func main() {
	projectPath := flag.String("path", ".", "Project path to analyze")
	flag.Parse()

	collector := &MetricsCollector{
		ProjectPath: *projectPath,
		Metrics:     &Metrics{},
	}

	if err := collector.Collect(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}

	// Output JSON
	output, _ := json.MarshalIndent(collector.Metrics, "", "  ")
	fmt.Println(string(output))
}

// Collect performs the collection
func (mc *MetricsCollector) Collect() error {
	// Phase 1: gocyclo cyclomatic complexity
	if err := mc.collectGocyclo(); err != nil {
		return fmt.Errorf("gocyclo failed: %w", err)
	}

	// Phase 2: gocognit cognitive complexity
	if err := mc.collectGocognit(); err != nil {
		return fmt.Errorf("gocognit failed: %w", err)
	}

	// Phase 3: scc size statistics
	if err := mc.collectScc(); err != nil {
		return fmt.Errorf("scc failed: %w", err)
	}

	// Phase 4: calculate MI
	mc.calculateMI()

	return nil
}

// collectGocyclo collects cyclomatic complexity (skips test/mock files)
func (mc *MetricsCollector) collectGocyclo() error {
	files, err := collectGoFiles(mc.ProjectPath)
	if err != nil {
		return err
	}
	if len(files) == 0 {
		return nil
	}
	// gocyclo (fzipp) has no -json flag; parse its text output:
	//   <complexity> <package> <function> <file:line:column>
	cmd := exec.Command("gocyclo", files...)
	output, err := cmd.Output()
	if err != nil {
		return err
	}

	var totalCC int
	var ccCount int
	maxCC := 0

	for _, line := range strings.Split(string(output), "\n") {
		parts := strings.Fields(line)
		if len(parts) < 4 {
			continue
		}
		cc, err := strconv.Atoi(parts[0])
		if err != nil {
			continue
		}
		totalCC += cc
		ccCount++
		if cc > maxCC {
			maxCC = cc
		}
	}

	if ccCount > 0 {
		mc.Metrics.AvgCC = float64(totalCC) / float64(ccCount)
		mc.Metrics.PeakCC = maxCC
		// gocyclo emits one line per function → ccCount is the real function count
		mc.Metrics.FunctionCount = ccCount
	}

	return nil
}

// collectGocognit collects cognitive complexity (skips test/mock files)
func (mc *MetricsCollector) collectGocognit() error {
	files, err := collectGoFiles(mc.ProjectPath)
	if err != nil {
		return err
	}
	if len(files) == 0 {
		return nil
	}
	args := append([]string{"-json"}, files...)
	cmd := exec.Command("gocognit", args...)
	output, err := cmd.Output()
	if err != nil {
		return err
	}

	var results []map[string]interface{}
	if err := json.Unmarshal(output, &results); err != nil {
		return err
	}

	var totalCognitive float64
	var cogCount int

	for _, r := range results {
		// gocognit -json marshals the raw struct: keys are capitalized ("Complexity")
		if cc, ok := r["Complexity"].(float64); ok {
			totalCognitive += cc
			cogCount++
		}
	}

	if cogCount > 0 {
		mc.Metrics.CognitiveCC = totalCognitive / float64(cogCount)
	}

	return nil
}

// collectScc collects size statistics (skips test/mock files)
func (mc *MetricsCollector) collectScc() error {
	// scc natively supports --exclude-dir; test files are filtered with --not-match='_test\.go$'
	// scc v3 --format json outputs a top-level array with capitalized keys
	cmd := exec.Command(
		"scc", "--format", "json",
		"--exclude-dir", "mock,fake,stub,testdata,fixtures,vendor,node_modules,.git,.venv,venv,__pycache__,data,.idea,.vscode,dist,build,.codebuddy",
		"--not-match", "_test\\.go$",
		mc.ProjectPath,
	)
	output, err := cmd.Output()
	if err != nil {
		return err
	}

	var result []struct {
		Name  string `json:"Name"`
		Code  int    `json:"Code"`
		Count int    `json:"Count"`
	}

	if err := json.Unmarshal(output, &result); err != nil {
		return err
	}

	// get Go language data
	for _, lang := range result {
		if lang.Name == "Go" {
			mc.Metrics.SLOC = lang.Code
			break
		}
	}

	// average function length = total non-test SLOC / function count (from gocyclo),
	// which is more accurate than scc's Count field (scc counts files, not functions)
	if mc.Metrics.FunctionCount > 0 {
		mc.Metrics.AvgFunctionLength = float64(mc.Metrics.SLOC) / float64(mc.Metrics.FunctionCount)
		// overlong function estimate (functions >80 lines)
		mc.Metrics.LongFunctions = int(float64(mc.Metrics.FunctionCount) * 0.1) // assume 10% are overlong functions
	}

	return nil
}

// calculateMI calculates the Maintainability Index
// MI = MAX(0, (171 − 5.2·ln(V) − 0.23·CC − 16.2·ln(LOC)) × 100 / 171)
func (mc *MetricsCollector) calculateMI() {
	if mc.Metrics.SLOC == 0 || mc.Metrics.AvgCC == 0 {
		mc.Metrics.MI = 100 // default maximum score
		return
	}

	// Simplified calculation: heuristic formula using LOC and CC
	// Full Halstead volume requires lexical analysis; this is the simplified version
	linesLog := math.Log(float64(mc.Metrics.SLOC))
	if linesLog < 1 {
		linesLog = 1
	}

	// Formula simplification
	mi := 171.0 - (5.2 * linesLog) - (0.23 * mc.Metrics.AvgCC) - (16.2 * linesLog)
	mi = mi * 100 / 171

	if mi < 0 {
		mi = 0
	}
	if mi > 100 {
		mi = 100
	}

	mc.Metrics.MI = math.Round(mi*10) / 10
}
