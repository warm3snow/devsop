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

// 测试/mock 文件名/路径匹配关键词（小写）。命中任一即跳过：
// - _test.go：Go 测试文件
// - mock/fake/stub：常见 mock 生成代码
// - testdata/fixtures：Go 官方约定的测试数据/示例目录
var skipKeywords = []string{"mock", "fake", "stub", "testdata", "fixtures"}

// 静态忽略目录（依赖/构建/VCS 等）
var skipDirs = map[string]bool{
	".git": true, ".venv": true, "venv": true, "node_modules": true,
	"vendor": true, "__pycache__": true, "data": true, ".idea": true,
	".vscode": true, "dist": true, "build": true, ".codebuddy": true,
}

// isTestOrMockPath 判断 .go 文件是否属于测试/mock 代码，应从质量扫描中排除。
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

// collectGoFiles 收集项目内所有需参与质量评分的 .go 文件（已剔除测试/mock/依赖）。
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

// MetricsCollector 采集代码规模与复杂度指标
type MetricsCollector struct {
	ProjectPath string
	Metrics     *Metrics
}

// Metrics 数据结构
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

// Collect 执行采集
func (mc *MetricsCollector) Collect() error {
	// Phase 1: gocyclo 圈复杂度
	if err := mc.collectGocyclo(); err != nil {
		return fmt.Errorf("gocyclo failed: %w", err)
	}

	// Phase 2: gocognit 认知复杂度
	if err := mc.collectGocognit(); err != nil {
		return fmt.Errorf("gocognit failed: %w", err)
	}

	// Phase 3: scc 规模统计
	if err := mc.collectScc(); err != nil {
		return fmt.Errorf("scc failed: %w", err)
	}

	// Phase 4: 计算 MI
	mc.calculateMI()

	return nil
}

// collectGocyclo 采集圈复杂度（跳过测试/mock 文件）
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

// collectGocognit 采集认知复杂度（跳过测试/mock 文件）
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

// collectScc 采集规模统计（跳过测试/mock 文件）
func (mc *MetricsCollector) collectScc() error {
	// scc 原生支持 --exclude-dir；测试文件用 --not-match='_test\.go$' 过滤
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

	// 获取 Go 语言数据
	for _, lang := range result.Languages {
		if lang.Name == "Go" {
			mc.Metrics.SLOC = lang.Code
			mc.Metrics.FunctionCount = lang.Count
			// 估算平均函数长度（LOC / 函数数）
			if lang.Count > 0 {
				mc.Metrics.AvgFunctionLength = float64(lang.Code) / float64(lang.Count)
				// 超长函数估算（>80 行的函数）
				mc.Metrics.LongFunctions = int(float64(lang.Count) * 0.1) // 假设 10% 是超长函数
			}
			break
		}
	}

	return nil
}

// calculateMI 计算可维护性指数
// MI = MAX(0, (171 − 5.2·ln(V) − 0.23·CC − 16.2·ln(LOC)) × 100 / 171)
func (mc *MetricsCollector) calculateMI() {
	if mc.Metrics.SLOC == 0 || mc.Metrics.AvgCC == 0 {
		mc.Metrics.MI = 100 // 默认最高分
		return
	}

	// 简化计算：使用 LOC 和 CC 的启发式公式
	// 完整 Halstead 体积计算需要词法分析，这里用简化版
	linesLog := math.Log(float64(mc.Metrics.SLOC))
	if linesLog < 1 {
		linesLog = 1
	}

	// 公式简化
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

// Helper: 从命令输出中解析整数
func parseInt(s string) int {
	re := regexp.MustCompile(`\d+`)
	matches := re.FindString(s)
	if matches == "" {
		return 0
	}
	val, _ := strconv.Atoi(matches)
	return val
}

// Helper: 从命令输出中解析浮点数
func parseFloat(s string) float64 {
	re := regexp.MustCompile(`\d+(\.\d+)?`)
	matches := re.FindString(s)
	if matches == "" {
		return 0
	}
	val, _ := strconv.ParseFloat(matches, 64)
	return val
}

// Helper: 构建项目路径
func (mc *MetricsCollector) buildPath(elem ...string) string {
	return filepath.Join(append([]string{mc.ProjectPath}, elem...)...)
}
