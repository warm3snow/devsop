package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"math"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
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
	args := append([]string{"-json"}, files...)
	cmd := exec.Command("gocyclo", args...)
	output, err := cmd.Output()
	if err != nil {
		return err
	}

	var results []map[string]interface{}
	if err := json.Unmarshal(output, &results); err != nil {
		return err
	}

	var totalCC int
	var ccCount int
	maxCC := 0

	for _, r := range results {
		if cc, ok := r["complexity"].(float64); ok {
			totalCC += int(cc)
			ccCount++
			if int(cc) > maxCC {
				maxCC = int(cc)
			}
		}
	}

	if ccCount > 0 {
		mc.Metrics.AvgCC = float64(totalCC) / float64(ccCount)
		mc.Metrics.PeakCC = maxCC
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
		if cc, ok := r["complexity"].(float64); ok {
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

	var result struct {
		Languages []struct {
			Name      string `json:"name"`
			Blank     int    `json:"blank"`
			Comment   int    `json:"comment"`
			Code      int    `json:"code"`
			Count     int    `json:"count"`
			FileCount int    `json:"fileCount"`
		} `json:"languages"`
	}

	if err := json.Unmarshal(output, &result); err != nil {
		return err
	}

	// get Go language data
	for _, lang := range result.Languages {
		if lang.Name == "Go" {
			mc.Metrics.SLOC = lang.Code
			mc.Metrics.FunctionCount = lang.Count
			// estimate average function length (LOC / function count)
			if lang.Count > 0 {
				mc.Metrics.AvgFunctionLength = float64(lang.Code) / float64(lang.Count)
				// overlong function estimate (functions >80 lines)
				mc.Metrics.LongFunctions = int(float64(lang.Count) * 0.1) // assume 10% are overlong functions
			}
			break
		}
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

// Helper: parse an integer from command output
func parseInt(s string) int {
	re := regexp.MustCompile(`\d+`)
	matches := re.FindString(s)
	if matches == "" {
		return 0
	}
	val, _ := strconv.Atoi(matches)
	return val
}

// Helper: parse a float from command output
func parseFloat(s string) float64 {
	re := regexp.MustCompile(`\d+(\.\d+)?`)
	matches := re.FindString(s)
	if matches == "" {
		return 0
	}
	val, _ := strconv.ParseFloat(matches, 64)
	return val
}

// Helper: build a project path
func (mc *MetricsCollector) buildPath(elem ...string) string {
	return filepath.Join(append([]string{mc.ProjectPath}, elem...)...)
}
