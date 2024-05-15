package main

import (
	"context"
	"fastack/docker"
	"flag"
	"fmt"
	"os"
	"path/filepath"

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

func RunDocker(stackConfig StackConfig) {
	ctx := context.Background()
	d := docker.New(ctx)
	msg := fmt.Sprintf("Now runnning %s", stackConfig.Name)
	fmt.Println(msg)
	d.CreateAndRun(
		stackConfig.Config.ImageName,
		stackConfig.Config.ExposedPort,
		stackConfig.Config.HostPort,
		stackConfig.Config.AppName,
	)
}

func main() {
	stackName := flag.String("stack", "", "Stack name to run")
	flag.Parse()

	if *stackName == "" {
		fmt.Println("Please provide a stack to run.")
		flag.Usage()
		return
	}

	fileLocation := fmt.Sprintf("%s/%s/stack.yml", stackFolder, *stackName)
	filename, _ := filepath.Abs(fileLocation)
	yamlFile, err := os.ReadFile(filename)
	if err != nil {
		panic(err)
	}
	var stackConfig StackConfig
	err = yaml.Unmarshal(yamlFile, &stackConfig)

	if err != nil {
		panic(err)
	}

	switch stackConfig.Mode {
	case "docker":
		RunDocker(stackConfig)
	default:
		msg := fmt.Sprintf("Unknown mode found: %s", stackConfig.Mode)
		fmt.Println(msg)
	}

}
