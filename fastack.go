package main

import (
	"context"
	"fastack/docker"
	"flag"
	"fmt"
	"os"
	"path/filepath"

	"github.com/joho/godotenv"
	"gopkg.in/yaml.v3"
)

var stackFolder = "./stacks"

type StackConfig struct {
	Name   string `yaml:"name"`
	Mode   string `yaml:"mode"`
	Config struct {
		ImageName   string `yaml:"image_name"`
		ExposedPort string `yaml:"container_port"`
		HostPort    string `yaml:"host_port"`
		AppName     string `yaml:"app_name"`
	} `yaml:"config"`
}

func RunDocker(stackConfig StackConfig, envValues []string) {
	ctx := context.Background()
	d := docker.New(ctx)
	msg := fmt.Sprintf("Now runnning %s", stackConfig.Name)
	fmt.Println(msg)
	d.CreateAndRun(
		stackConfig.Config.ImageName,
		stackConfig.Config.ExposedPort,
		stackConfig.Config.HostPort,
		stackConfig.Config.AppName,
		envValues,
	)
}

func LoadEnv(stackName *string) []string {
	envFileLocation := fmt.Sprintf("%s/%s/.env", stackFolder, *stackName)
	envFilename, _ := filepath.Abs(envFileLocation)
	var envFile map[string]string
	envFile, err := godotenv.Read(envFilename)
	if err != nil {
		fmt.Println("No local .env file configured")
		return []string{}
	}
	env := []string{}
	for key, value := range envFile {
		env = append(env, fmt.Sprintf("%s=%s", key, value))
	}
	return env
}

func LoadStackConfig(stackName *string) StackConfig {
	stackFileLocation := fmt.Sprintf("%s/%s/stack.yml", stackFolder, *stackName)
	stackFilename, _ := filepath.Abs(stackFileLocation)
	yamlFile, err := os.ReadFile(stackFilename)
	var stackConfig StackConfig
	err = yaml.Unmarshal(yamlFile, &stackConfig)

	if err != nil {
		panic(err)
	}
	return stackConfig
}

func main() {
	stackName := flag.String("stack", "", "Stack name to run")
	flag.Parse()

	if *stackName == "" {
		fmt.Println("Please provide a stack to run.")
		flag.Usage()
		return
	}

	envValues := LoadEnv(stackName)
	stackConfig := LoadStackConfig(stackName)

	switch stackConfig.Mode {
	case "docker":
		RunDocker(stackConfig, envValues)
	default:
		msg := fmt.Sprintf("Unknown mode found: %s", stackConfig.Mode)
		fmt.Println(msg)
	}

}
